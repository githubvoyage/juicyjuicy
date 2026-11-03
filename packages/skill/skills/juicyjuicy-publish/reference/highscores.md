# Global highscores: `juicy.scores`

On JuicyJuicy a game can have a **leaderboard** shared by every player: each signed-in player's best score (or time), kept by JuicyJuicy, shown in the game and on the game's page. The game sends a finished run's score and reads the top of the board with a small snippet. Players who aren't signed in keep their best in the game's own `localStorage` (it doesn't move to their account later). Outside JuicyJuicy (opened on its own, a local server, the automatic screenshot) the snippet uses that local best alone.

## Adding it to a published game
When the user asks for global highscores (the JuicyJuicy Upgrades panel's prompt names this file), follow "Add a JuicyJuicy upgrade" in SKILL.md, and in the game:
1. **Decide what's ranked**, from the game, and say it in your summary: a score where more is better (`order: "high"`, the default), or a time or count where less is better (`order: "low"`); points (`format: "points"`) or milliseconds (`format: "time"`, shown as `1:23.45`). **Use one board.** A game with several modes, levels or difficulties ranks one thing on it: the main mode, or a total. If separate boards would suit the game (one per level, mode or difficulty), you may suggest it in your summary, and add them only when the user wants them ("Boards per level or mode" below). If what's ranked isn't clear, ask the user in one short question.
2. Paste the snippet below and use it as "Using it" says: send the score when a run ends, and show the leaderboard on the game-over screen (and in the menu if there's room).
3. Add `"highscores"` to `features` in `juicy.json`: `"features": ["highscores"]`. JuicyJuicy also finds the snippet's `juicyjuicy:score` in the files; `check` warns when `features` lists highscores and the files don't have it, and its result's `features.detected` includes `highscores` once they do.

## The snippet
Paste it as is, before the game's own code: an inline `<script>` in `index.html`, or the top of the main script. Don't change it; it only posts messages to the page around the frame. It works next to the cloud-saves and multiplayer snippets, in any order (an older copy of the cloud-saves snippet, without `window.juicy.save ||` near its top, must come first).

```js
// JuicyJuicy highscores: https://juicyjuicy.games/docs/publish#highscores
window.juicy = window.juicy || {};
window.juicy.scores || (function (juicy) {
  var KEY = "juicyjuicy:best";
  var framed = window.parent !== window;
  var onSite = false;
  var next = 0;
  var waiting = {};
  window.addEventListener("message", function (event) {
    var m = event.data;
    if (event.source !== window.parent || !m || typeof m.id !== "string") return;
    if (m.type !== "juicyjuicy:scored" && m.type !== "juicyjuicy:leaderboard") return;
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
      var id = "scores-" + ++next;
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
  // Each board's local best; "main" keeps the key it had before boards.
  function key(board) {
    return board && board !== "main" ? KEY + ":" + board : KEY;
  }
  function readLocal(board) {
    try {
      var best = JSON.parse(localStorage.getItem(key(board)));
      return best && typeof best.score === "number" ? best : null;
    } catch (e) {
      return null;
    }
  }
  function keepLocal(board, score, order, format) {
    var best = readLocal(board);
    var improved = !best || (order === "low" ? score < best.score : score > best.score);
    if (improved) {
      best = { score: score, order: order, format: format };
      try {
        localStorage.setItem(key(board), JSON.stringify(best));
      } catch (e) {}
    }
    return { cloud: false, best: best.score, rank: null, improved: improved };
  }
  juicy.scores = {
    // Sends a finished run's score: a whole number, or milliseconds for a time. Options (pass the
    // same ones every time for a board): order "high" (more is better, the default) or "low",
    // format "points" (the default) or "time", board (only for a game with several, such as
    // "hard": an id of lowercase letters, digits, - and _; "main" by default). Resolves to
    // { cloud: true, best, rank, improved } or { cloud: false, best, rank: null, improved }
    // (signed out: kept in this browser); rejects with an error that has a code.
    submit: function (score, options) {
      var order = (options && options.order) || "high";
      var format = (options && options.format) || "points";
      var board = options && options.board;
      var message = { type: "juicyjuicy:score", score: score, order: order, format: format };
      if (board) message.board = board;
      return ask(message).then(function (m) {
        if (!m) {
          if (onSite) throw failed(null);
          return keepLocal(board, score, order, format);
        }
        if (m.ok) return { cloud: true, best: m.best, rank: m.rank, improved: m.improved };
        if (m.error.code === "SIGNED_OUT") return keepLocal(board, score, order, format);
        throw failed(m);
      });
    },
    // The leaderboard's top "limit" (10 by default, at most 100): { cloud, signedIn, order,
    // format, entries: [{ rank, name, score, me }], me: { rank, score } or null }. Options: board
    // (as for submit).
    top: function (limit, options) {
      var board = options && options.board;
      var message = { type: "juicyjuicy:scores", limit: limit || 10 };
      if (board) message.board = board;
      return ask(message).then(function (m) {
        if (!m) {
          if (onSite) throw failed(null);
          var best = readLocal(board);
          return {
            cloud: false,
            signedIn: false,
            order: best ? best.order : null,
            format: best ? best.format : null,
            entries: best ? [{ rank: 1, name: "You", score: best.score, me: true }] : [],
            me: best ? { rank: 1, score: best.score } : null
          };
        }
        if (!m.ok) throw failed(m);
        return {
          cloud: true,
          signedIn: m.signedIn,
          order: m.order,
          format: m.format,
          entries: m.entries,
          me: m.me
        };
      });
    }
  };
})(window.juicy);
```

## Using it
```js
const BOARD = { order: "high", format: "points" }; // or { order: "low", format: "time" } for times in ms

// When a run ends (game over, level cleared, race finished):
juicy.scores.submit(score, BOARD).then((result) => {
  // result: { cloud, best, rank, improved }; rank is null when the best is only kept in this browser
  if (result.improved) showNewBest(result.best, result.rank);
}).catch(() => {});

// On the game-over screen:
const board = await juicy.scores.top(10);
// board: { cloud, signedIn, order, format, entries: [{ rank, name, score, me }], me: { rank, score } or null }
```

- **Send every finished run**, not just new bests, and don't wait for the answer before showing the game-over screen. Only a player's best counts; JuicyJuicy sends at most one score every 5 seconds, keeping the best.
- **Scores are whole numbers** (`Math.round` first); times are milliseconds and can't be negative. Pass **the same `BOARD` options every time**: the first score sets how the board ranks, and a score sent another way is refused (`INVALID`) until the creator resets the board on the game's page.
- **Show the board** with each entry's `rank`, `name` (the player's JuicyJuicy username) and `score`, highlight `me`, and when `board.me` isn't among the entries show it under them ("You: #42"). Format times as `m:ss.cc`. Put names on screen with `textContent` or the engine's text object, **never `innerHTML`** (anyone picks their own username). When `board.signedIn` is false, add a line like "Sign in on JuicyJuicy to get on the leaderboard".
- **An empty board** (`entries` is `[]`) says "No scores yet: be the first!".
- `submit()` resolves to `{ cloud: true, best, rank, improved }`, or `{ cloud: false, best, rank: null, improved }` when the player isn't signed in (kept in this browser), and rejects with an `Error` whose `code` is `INVALID`, `RATE_LIMITED`, `PAUSED` (highscores paused for a while), `FAILED` or `TIMEOUT`. `top()` rejects with the same codes. The game keeps running either way; just leave the board out.
- **A game that already keeps a local high score** keeps showing it as "your best" if it likes; the leaderboard is what `top()` returns. Don't send old local high scores to `submit()`: a board is about runs played on JuicyJuicy.
- **Scores are what the game sends.** Don't add anti-cheat code; JuicyJuicy's creator and admins remove scores that look wrong.
- **Boards per level or mode**, only when the user asks for them: pass `board` to both calls, `juicy.scores.submit(score, { ...BOARD, board: "hard" })` and `juicy.scores.top(10, { board: "hard" })`. A board's id is lowercase letters, digits, `-` and `_` (at most 32 characters, starting with a letter or digit), and the game page labels it from the id (`hard-mode` shows as "Hard mode"), so pick ids that read well. Without `board` a score goes to `main`, the game's first board. Each board ranks its own way (its first score sets it), a game has at most 10 boards (a score for an 11th is refused, `INVALID`), and the game page shows one tab per board. Keep the set fixed (levels, modes): never make a board id from something a player types.
- **Godot, Unity and other engines** call the same functions from JavaScript: Godot's `JavaScriptBridge.eval`, a Unity `.jslib` plugin. Put the snippet in the exported `index.html` (Godot: the HTML shell's head include; Unity: the WebGL template).
