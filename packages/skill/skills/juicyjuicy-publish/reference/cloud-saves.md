# Cloud saves: `window.juicy`

On JuicyJuicy a signed-in player's progress can follow them to any browser. The game asks the page around its frame with a small snippet; JuicyJuicy keeps one save per player and game. Players who aren't signed in keep the save in the game's own `localStorage`, and it moves to their account the first time they play signed in. Outside JuicyJuicy (opened on its own, a local server, the automatic screenshot) the snippet just uses `localStorage`.

## The snippet
Paste it as is, before the game's own code: an inline `<script>` in `index.html`, or the top of the main script. Don't change it; it only posts messages to the page around the frame.

```js
// JuicyJuicy cloud saves: https://juicyjuicy.games/docs/publish#saves
window.juicy = window.juicy || (function () {
  var KEY = "juicyjuicy:save";
  var framed = window.parent !== window;
  var onSite = false;
  var next = 0;
  var waiting = {};
  window.addEventListener("message", function (event) {
    var m = event.data;
    if (event.source !== window.parent || !m || typeof m.id !== "string") return;
    if (m.type !== "juicyjuicy:loaded" && m.type !== "juicyjuicy:saved") return;
    var done = waiting[m.id];
    if (!done) return;
    delete waiting[m.id];
    onSite = true;
    done(m);
  });
  // The player's answer, or null when nothing answered (not on JuicyJuicy).
  function ask(message) {
    return new Promise(function (resolve) {
      if (!framed) return resolve(null);
      var id = "juicy-" + ++next;
      var timer = setTimeout(function () {
        delete waiting[id];
        resolve(null);
      }, onSite ? 30000 : 10000);
      waiting[id] = function (m) {
        clearTimeout(timer);
        resolve(m);
      };
      message.id = id;
      window.parent.postMessage(message, "*");
    });
  }
  function failed(m) {
    var error = new Error(m ? m.error.message : "JuicyJuicy didn't answer");
    error.code = m ? m.error.code : "TIMEOUT";
    return error;
  }
  function readLocal() {
    try {
      var text = localStorage.getItem(KEY);
      return text === null ? null : JSON.parse(text);
    } catch (e) {
      return null;
    }
  }
  function writeLocal(data) {
    if (data === null) localStorage.removeItem(KEY);
    else localStorage.setItem(KEY, JSON.stringify(data));
    return { cloud: false };
  }
  function dropLocal() {
    try {
      localStorage.removeItem(KEY);
    } catch (e) {}
  }
  var juicy = {
    // Resolves to the saved data, or null when there's none.
    load: function () {
      return ask({ type: "juicyjuicy:load" }).then(function (m) {
        if (!m) {
          if (onSite) throw failed(null);
          return readLocal();
        }
        if (!m.ok) throw failed(m);
        if (!m.signedIn) return readLocal();
        var mine = readLocal();
        if (m.data !== null || mine === null) {
          dropLocal();
          return m.data;
        }
        // Played signed out, then joined: the progress moves to the cloud.
        return juicy.save(mine).then(
          function () { return mine; },
          function () { return mine; }
        );
      });
    },
    // Saves any JSON value (null deletes the save). Resolves to { cloud: true, savedAt } or
    // { cloud: false } (kept in this browser); rejects with an error that has a code.
    save: function (data) {
      return ask({ type: "juicyjuicy:save", data: data }).then(function (m) {
        if (!m) {
          if (onSite) throw failed(null);
          return writeLocal(data);
        }
        if (m.ok) {
          dropLocal();
          return { cloud: true, savedAt: m.savedAt };
        }
        if (m.error.code === "SIGNED_OUT") return writeLocal(data);
        throw failed(m);
      });
    }
  };
  return juicy;
})();
```

## Using it
```js
const saved = await juicy.load(); // null the first time
if (saved) restoreGame(saved);

// Whenever something worth keeping happens (a level done, a checkpoint, the settings changed):
juicy.save({ level, score, settings }).catch(() => {});
```

- **One save per game:** any JSON value (an object with everything the game needs), at most 256 KB as JSON. A game with several slots keeps them inside that one object. `juicy.save(null)` deletes the save.
- **Load once at the start and wait for it** before showing "New game" or "Continue", so a new game never saves over a player's progress. If `load()` rejects, don't save over the cloud save: start without it and try `load()` again later.
- **Save as often as the game likes:** JuicyJuicy writes at most once every 10 seconds and keeps only the latest save, and writes it straight away when the player quits or leaves the page.
- `save()` resolves to `{ cloud: true, savedAt }` or `{ cloud: false }` (kept in this browser) and rejects with an `Error` whose `code` is `TOO_LARGE`, `INVALID` (not JSON), `RATE_LIMITED`, `PAUSED` (cloud saves paused for a while), `FAILED` or `TIMEOUT`. The game keeps running either way: the next save carries the progress.
- **A game that already saves to `localStorage`:** switch its save and load to `juicy.save`/`juicy.load` (offer it to the user). What it kept under its own keys stays in this browser only; JuicyJuicy can't read it, but the game can: on the first `juicy.load()` that returns null, load the old key and `juicy.save()` it.
- **Godot, Unity and other engines** call the same functions from JavaScript: Godot's `JavaScriptBridge.eval`, a Unity `.jslib` plugin. Put the snippet in the exported `index.html` (Godot: the HTML shell's head include; Unity: the WebGL template).
