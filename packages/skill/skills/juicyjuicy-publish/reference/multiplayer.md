# Multiplayer: `juicy.rooms`

On JuicyJuicy, friends play a game together in a **room**. A player opens one, invites friends with a link (or reads out its 6-letter code), and everyone in the room can send messages to everyone else or to one player. JuicyJuicy relays the room; there's no server to write or run. **One player's browser runs the game** (the host, who opened the room): the others send it their input and draw what it sends back. That suits party, co-op, turn-based, racing and Bomberman-style games; it doesn't suit competitive shooters, where the host would have an edge.

Rooms are for signed-in JuicyJuicy members: a visitor who tries to open or join one is offered Sign in by JuicyJuicy. A room holds up to 10 players.

## Adding it to a published game
When the user asks for multiplayer (the JuicyJuicy Upgrades panel's prompt names this file), follow "Add a JuicyJuicy upgrade" in SKILL.md. First read the game's code and see which case it is.

### The game already has multiplayer
Signs: `new WebSocket(`, socket.io, PeerJS or `RTCPeerConnection`, Firebase or Supabase realtime, Colyseus, Photon, PlayFab, a `wss://` URL of the creator's own server.

1. Find its parts: how a match is made or joined (lobby, codes, matchmaking), what each player sends, what comes back, and where the game's rules run.
2. Move them onto rooms: making or joining a match becomes `juicy.rooms.create()` and `juicy.rooms.join(code)` (and `invited()` for invite links), sending becomes `room.send()`, receiving becomes `room.on("message")`, and the player list becomes `room.players` with the `join` and `leave` events.
3. If the rules ran on the creator's server and that code is in the project, move them into the host's browser (`room.isHost()`). If the server's code isn't there, tell the user what the server did and ask before rebuilding it in the game.
4. Remove the outside service: its client library, URLs, keys and config. Keep how the game plays, its screens and its controls.
5. Tell the user what moved, and that their old server or service account can be switched off once the update is live.

### The game has no multiplayer
Don't build anything yet. **Ask the user how multiplayer should work in this game**, in one short message, suggesting an answer for each from what the game is:

1. **What kind of play:** together against the game (co-op), against each other (versus), taking turns, or a race or party round?
2. **How many players:** 2 to 10.
3. **How friends join:** an **Invite** button that shares a link, a code shown on screen to type in, or both. Can someone join a game that has started, or only in the lobby?
4. **When someone leaves:** does the game go on without them? When the host leaves, the next player takes over (see "When the host changes"); is that right for this game?
5. **Phones:** should it play on phones (touch controls)?
6. **Anything else:** teams, rounds, a winner screen, what each player sees of the others.

Then write the design back in a few lines: the screens (menu, lobby, game, results), what the host runs, what each player sends and what the host sends back. **Build it only once the user agrees**, then follow "Using it" and "How to build it".

## The snippet
Paste it as is, before the game's own code: an inline `<script>` in `index.html`, or the top of the main script. Don't change it. It works next to the cloud-saves snippet, in either order (an older copy of the cloud-saves snippet, without `window.juicy.save ||` near its top, must come first).

```js
// JuicyJuicy multiplayer: https://juicyjuicy.games/docs/publish#multiplayer
window.juicy = window.juicy || {};
window.juicy.rooms || (function (juicy) {
  var CLOSED = { 4001: "TICKET", 4004: "ROOM_NOT_FOUND", 4009: "ROOM_FULL", 4010: "ROOM_LOCKED",
    4011: "KICKED", 4012: "REPLACED", 4029: "TOO_FAST", 4040: "GAME_GONE", 4503: "OFF" };
  var onSite = window.parent !== window ? null : false;
  var inviteUrl = null;
  var next = 0;
  var waiting = {};
  window.addEventListener("message", function (event) {
    var m = event.data;
    if (event.source !== window.parent || !m || m.type !== "juicyjuicy:room-ticket") return;
    var done = waiting[m.id];
    if (!done) return;
    delete waiting[m.id];
    onSite = true;
    done(m);
  });
  function fail(code, message) {
    var error = new Error(message || code);
    error.code = code;
    return error;
  }
  // The player's answer (with a ticket when asked), or null when not on JuicyJuicy.
  function ask(ticket) {
    return new Promise(function (resolve, reject) {
      if (onSite === false) return resolve(null);
      var id = "juicy-room-" + ++next;
      var timer = setTimeout(function () {
        delete waiting[id];
        if (onSite) return reject(fail("TIMEOUT", "JuicyJuicy didn't answer"));
        onSite = false;
        resolve(null);
      }, onSite ? 30000 : 5000);
      waiting[id] = function (m) {
        clearTimeout(timer);
        if (!m.ok) return reject(fail(m.error.code, m.error.message));
        inviteUrl = m.inviteUrl;
        resolve(m);
      };
      window.parent.postMessage({ type: "juicyjuicy:room", id: id, ticket: ticket }, "*");
    });
  }

  function Room(code) {
    this.code = code;
    this.me = null;
    this.host = null;
    this.max = 0;
    this.locked = false;
    this.players = [];
    this.handlers = {};
    this.link = null;
    this.opened = false;
    this.closed = false;
  }
  // Events: "message" (data, fromId), "join" (player), "leave" (player), "host" (id),
  // "lock" (locked), "error" (error), "close" (reason).
  Room.prototype.on = function (event, handler) {
    (this.handlers[event] = this.handlers[event] || []).push(handler);
    return this;
  };
  Room.prototype.emit = function (event, a, b) {
    (this.handlers[event] || []).slice().forEach(function (handler) {
      try {
        handler(a, b);
      } catch (e) {
        setTimeout(function () { throw e; });
      }
    });
  };
  Room.prototype.isHost = function () {
    return this.me !== null && this.me === this.host;
  };
  Room.prototype.player = function (id) {
    for (var i = 0; i < this.players.length; i++) if (this.players[i].id === id) return this.players[i];
    return null;
  };
  // Sends any JSON value to everyone else in the room, or only to the player whose id is "to".
  Room.prototype.send = function (data, to) {
    if (this.link) this.link.send({ t: "send", d: data, to: to });
  };
  // The host only: stop new players joining (false lets them in again).
  Room.prototype.lock = function (locked) {
    if (this.link) this.link.send({ t: "lock", locked: locked !== false });
  };
  // The host only: remove a player, who can't come back to this room.
  Room.prototype.kick = function (id) {
    if (this.link) this.link.send({ t: "kick", id: id });
  };
  // Shows JuicyJuicy's share sheet for the room's invite link, and returns the link.
  Room.prototype.invite = function () {
    if (onSite) {
      window.parent.postMessage({ type: "juicyjuicy:invite", code: this.code }, "*");
      return inviteUrl + this.code;
    }
    return location.origin + location.pathname + "?room=" + this.code;
  };
  Room.prototype.leave = function () {
    this.end("LEFT");
  };
  Room.prototype.end = function (reason) {
    if (this.closed) return;
    this.closed = true;
    var link = this.link;
    this.link = null;
    if (link) link.close();
    this.emit("close", reason);
  };
  Room.prototype.receive = function (m) {
    var room = this;
    if (m.t === "welcome") {
      var before = room.players;
      var host = room.host;
      room.code = m.room;
      room.me = m.me;
      room.host = m.host;
      room.max = m.max;
      room.locked = m.locked;
      room.players = m.players;
      if (!room.opened) {
        room.opened = true;
        return room.emit("welcomed", room);
      }
      // Back after a dropped connection: who came and went meanwhile.
      before.forEach(function (p) { if (!room.player(p.id)) room.emit("leave", p); });
      m.players.forEach(function (p) {
        if (!before.some(function (q) { return q.id === p.id; })) room.emit("join", p);
      });
      if (host !== m.host) room.emit("host", m.host);
    } else if (m.t === "join") {
      room.players.push(m.player);
      room.emit("join", m.player);
    } else if (m.t === "leave") {
      var gone = room.player(m.id);
      if (!gone) return;
      room.players.splice(room.players.indexOf(gone), 1);
      room.emit("leave", gone);
    } else if (m.t === "host") {
      room.host = m.id;
      room.emit("host", m.id);
    } else if (m.t === "lock") {
      room.locked = m.locked;
      room.emit("lock", m.locked);
    } else if (m.t === "msg") {
      room.emit("message", m.d, m.from);
    } else if (m.t === "error") {
      room.emit("error", fail(m.code, m.message));
    } else if (m.t === "closed") {
      room.end(m.reason);
    }
  };

  // JuicyJuicy's relay: resolves once it has welcomed this player.
  function connect(room, query) {
    return ask(true).then(function (m) {
      return new Promise(function (resolve, reject) {
        var socket = new WebSocket(m.url + "?ticket=" + encodeURIComponent(m.ticket) + query);
        var welcomed = false;
        var link = {
          send: function (message) {
            if (socket.readyState === 1) socket.send(JSON.stringify(message));
          },
          close: function () {
            socket.close(1000);
          }
        };
        socket.onmessage = function (event) {
          var message;
          try {
            message = JSON.parse(event.data);
          } catch (e) {
            return;
          }
          if (message.t === "welcome" && !welcomed) {
            welcomed = true;
            room.link = link;
            room.receive(message);
            return resolve(room);
          }
          if (room.link === link) room.receive(message);
        };
        socket.onclose = function (event) {
          var reason = CLOSED[event.code];
          if (!welcomed) return reject(fail(reason || "DISCONNECTED", "Couldn't join the room"));
          if (room.link !== link) return;
          room.link = null;
          if (reason) room.end(reason);
          else reconnect(room, 0);
        };
      });
    });
  }
  // Phones drop connections when the game is in the background: three tries to come back.
  function reconnect(room, attempt) {
    if (room.closed) return;
    if (attempt === 3) return room.end("DISCONNECTED");
    setTimeout(function () {
      if (room.closed) return;
      connect(room, "&room=" + room.code).catch(function (e) {
        if (e.code === "DISCONNECTED" || e.code === "TIMEOUT" || e.code === "FAILED") {
          reconnect(room, attempt + 1);
        } else {
          room.end(e.code);
        }
      });
    }, 1000 * Math.pow(2, attempt));
  }

  // Outside JuicyJuicy: rooms between this origin's tabs. The tab that creates a room relays it,
  // and the room ends when that tab leaves.
  var tab = Math.random().toString(36).slice(2);
  var channel = null;
  var relays = {};
  var mine = {};
  function bus() {
    if (channel) return channel;
    channel = new BroadcastChannel("juicyjuicy:rooms");
    channel.onmessage = function (event) {
      var e = event.data;
      if (e.to === "relay" && relays[e.code]) relays[e.code].handle(e.from, e.m);
      else if (e.to === tab && mine[e.code]) mine[e.code].receive(e.m);
    };
    window.addEventListener("pagehide", function () {
      Object.keys(mine).forEach(function (code) { mine[code].leave(); });
    });
    return channel;
  }
  function LocalRelay(code, max) {
    this.code = code;
    this.max = max;
    this.locked = false;
    this.players = [];
    this.host = null;
    this.next = 0;
    this.kicked = {};
  }
  LocalRelay.prototype.deliver = function (to, m) {
    var room = to === tab && mine[this.code];
    if (room) setTimeout(function () { room.receive(m); });
    else if (to !== tab) bus().postMessage({ to: to, code: this.code, m: m });
  };
  LocalRelay.prototype.everyone = function (m, except) {
    var relay = this;
    relay.players.forEach(function (p) { if (p !== except) relay.deliver(p.tab, m); });
  };
  LocalRelay.prototype.list = function () {
    return this.players.map(function (p) { return { id: p.id, name: p.name }; });
  };
  LocalRelay.prototype.remove = function (player) {
    this.players.splice(this.players.indexOf(player), 1);
    this.everyone({ t: "leave", id: player.id });
    if (this.host !== player.id || !this.players.length) return;
    this.host = this.players[0].id;
    this.everyone({ t: "host", id: this.host });
  };
  LocalRelay.prototype.handle = function (from, m) {
    var relay = this;
    var player = null;
    relay.players.forEach(function (p) { if (p.tab === from) player = p; });
    if (m.t === "join") {
      if (player) return;
      var refused = relay.kicked[from] ? "KICKED" : relay.locked ? "ROOM_LOCKED"
        : relay.players.length >= relay.max ? "ROOM_FULL" : null;
      if (refused) return relay.deliver(from, { t: "closed", reason: refused });
      player = { id: "p" + ++relay.next, name: "Player " + relay.next, tab: from };
      relay.players.push(player);
      if (!relay.host) relay.host = player.id;
      relay.deliver(from, { t: "welcome", room: relay.code, me: player.id, host: relay.host,
        max: relay.max, locked: relay.locked, players: relay.list() });
      relay.everyone({ t: "join", player: { id: player.id, name: player.name } }, player);
    } else if (!player) {
      return;
    } else if (m.t === "send") {
      relay.players.forEach(function (p) {
        if (p !== player && (m.to == null || m.to === p.id)) {
          relay.deliver(p.tab, { t: "msg", from: player.id, d: m.d });
        }
      });
    } else if (m.t === "leave") {
      relay.remove(player);
    } else if (player.id !== relay.host) {
      relay.deliver(from, { t: "error", code: "NOT_HOST", message: "Only the host can do that" });
    } else if (m.t === "lock") {
      relay.locked = m.locked;
      relay.everyone({ t: "lock", locked: m.locked });
    } else if (m.t === "kick") {
      relay.players.slice().forEach(function (p) {
        if (p.id !== m.id || p === player) return;
        relay.kicked[p.tab] = true;
        relay.deliver(p.tab, { t: "closed", reason: "KICKED" });
        relay.remove(p);
      });
    }
  };
  function joinLocal(room, max) {
    return new Promise(function (resolve, reject) {
      var code = room.code;
      if (max) relays[code] = new LocalRelay(code, max);
      mine[code] = room;
      room.link = {
        send: function (m) {
          var relay = relays[code];
          if (relay) setTimeout(function () { relay.handle(tab, m); });
          else bus().postMessage({ to: "relay", code: code, from: tab, m: m });
        },
        close: function () {
          delete mine[code];
          var relay = relays[code];
          if (!relay) return bus().postMessage({ to: "relay", code: code, from: tab, m: { t: "leave" } });
          delete relays[code];
          relay.players.forEach(function (p) {
            if (p.tab !== tab) relay.deliver(p.tab, { t: "closed", reason: "DISCONNECTED" });
          });
        }
      };
      room.on("close", function (reason) {
        if (!room.opened) reject(fail(reason, "Couldn't join the room"));
      });
      room.on("welcomed", resolve);
      bus();
      room.link.send({ t: "join" });
      setTimeout(function () {
        if (!room.opened) room.end("ROOM_NOT_FOUND");
      }, 2000);
    });
  }
  function newCode() {
    var letters = "ABCDEFGHJKMNPQRSTUVWXYZ23456789";
    var code = "";
    for (var i = 0; i < 6; i++) code += letters[Math.floor(Math.random() * letters.length)];
    return code;
  }

  juicy.rooms = {
    // Opens a new room with this player as its host. options.max: most players, 2 to 10.
    create: function (options) {
      var max = Math.max(2, Math.min(10, (options && options.max) || 10));
      return ask(true).then(function (m) {
        var room = new Room(null);
        if (m) return connect(room, "&create=1&max=" + max);
        room.code = newCode();
        return joinLocal(room, max);
      });
    },
    // Joins the room with this code (from invited(), or typed in by the player).
    join: function (code) {
      code = String(code || "").trim().toUpperCase();
      return ask(true).then(function (m) {
        var room = new Room(code);
        return m ? connect(room, "&room=" + encodeURIComponent(code)) : joinLocal(room, 0);
      });
    },
    // The room code of the invite link that opened the game, or null.
    invited: function () {
      return ask(false).then(function (m) {
        if (m) return m.invite;
        var found = /[?&]room=([A-Za-z0-9]{6})/.exec(location.search);
        return found ? found[1].toUpperCase() : null;
      });
    }
  };
})(window.juicy);
```

## Using it
```js
// Opened from an invite link: join that room straight away.
const code = await juicy.rooms.invited();
if (code) start(await juicy.rooms.join(code));

// The menu's "Play with friends" opens a room; "Join" takes a code the player types.
playButton.onclick = async () => start(await juicy.rooms.create({ max: 4 }));
joinButton.onclick = async () => start(await juicy.rooms.join(codeInput.value));

function start(room) {
  showLobby(room.code, room.players); // [{ id: "p1", name: "luk" }, …], with textContent
  inviteButton.onclick = () => room.invite(); // JuicyJuicy's share sheet, with Copy link
  room.on("join", (player) => addToLobby(player));
  room.on("leave", (player) => removeFromLobby(player));
  room.on("message", (data, from) => handle(data, from));
  room.on("close", (reason) => backToMenu(reason));
}
```

- `juicy.rooms.create({ max })` opens a room (2 to 10 players; 10 by default) with this player as host; `join(code)` joins one (any case, spaces ignored). Both resolve to the room once it's open, and reject with an `Error` whose `code` says why: `SIGNED_OUT` (JuicyJuicy has offered to sign in), `ROOM_NOT_FOUND`, `ROOM_FULL`, `ROOM_LOCKED`, `KICKED`, `RATE_LIMITED`, `PAUSED` (multiplayer paused for a while), `OFF`, `GAME_GONE`, `TIMEOUT`, `DISCONNECTED` or `FAILED`. Show the player a short message and go back to the menu.
- `juicy.rooms.invited()` resolves to the code of the invite link that opened the game, or null.
- The room: `room.code`, `room.me` (this player's id, like `"p2"`), `room.host` (the host's id), `room.isHost()`, `room.players` (`{ id, name }`, name being the member's JuicyJuicy login), `room.player(id)`, `room.locked` and `room.max`.
- `room.send(data)` sends any JSON value to everyone else; `room.send(data, id)` only to that player. A player never gets their own messages.
- `room.on(event, handler)`: `"message"` (data, fromId), `"join"` (player), `"leave"` (player), `"host"` (the new host's id), `"lock"` (locked), `"error"` (an `Error` with a `code`: `RATE_LIMITED`, `TOO_LARGE`, `NOT_HOST`, `NO_PLAYER`, `INVALID`; the room goes on), `"close"` (reason: `LEFT`, `KICKED`, `REPLACED` (the same player joined from another tab), `ROOM_NOT_FOUND`, `TOO_FAST`, `GAME_GONE`, `OFF` or `DISCONNECTED`).
- The host only: `room.lock()` stops new players joining (players who were in can come back), `room.lock(false)` opens it again; `room.kick(id)` removes a player for good.
- `room.invite()` shows JuicyJuicy's share sheet over the game and returns the link (`https://juicyjuicy.games/g/<slug>/play?room=CODE`).
- `room.leave()` leaves the room.

## How to build it
- **The host runs the game.** Players send their input (`{ k: "input", left: true }`, a move, a card played); the host applies it to the one true game state and sends the state, or what changed, to everyone. Players draw what the host sent and never decide outcomes themselves. For a real-time game, send state 10 to 20 times a second and smooth movement between updates; send input when it changes, not every frame.
- **Small messages with a kind:** `{ k: "state", … }`, `{ k: "input", … }`. Each message is at most 16 KB as JSON, and each player may send at most 60 messages and 64 KB a second (one `send` to everyone counts once). Over that, messages are dropped (`RATE_LIMITED`), and far over it the player is disconnected (`TOO_FAST`).
- **The lobby:** show the code and the players, an **Invite** button (`room.invite()`) and, for the host, **Start**. When the game starts, the host sends `{ k: "start", … }` and calls `room.lock()` if nobody may join mid-game.
- **When the host changes** (the host left or dropped): every player keeps the last state the host sent, so on `"host"` the new host (`room.isHost()`) carries on from it and starts sending state. A turn-based game resends whose turn it is.
- **When a player leaves**, the host decides: remove their character, let the round finish, or end the game if too few are left.
- **Dropped connections:** phones drop them when the game goes to the background. The snippet reconnects by itself (three tries) and keeps the player's id; during that time `send` does nothing. When the host comes back, it asks for nothing: players resend what they need on `"join"` or `"host"`.
- **Player names are text from other people:** show them with `textContent`, never `innerHTML` (the security review checks it).
- **No free-text chat.** JuicyJuicy can't moderate it yet. Quick messages or emotes from a fixed list are fine.
- **No other server, no keys:** everything goes through the room.

## Try it
Outside JuicyJuicy, on a local server, the snippet runs rooms **between tabs of the same address**: open the game in two tabs, open a room in one and join it from the other with its code (or open the link `room.invite()` returns). Players are called "Player 1", "Player 2"…, and the room ends when the tab that opened it closes (on JuicyJuicy the host moves to the next player instead). Try every screen with two or three tabs, including leaving and rejoining, before publishing.

On JuicyJuicy, two people (or two browsers signed in as two members) can play it from an invite link once the update is live.

## Declare it
Add `"multiplayer"` to `features` in `juicy.json`: `"features": ["multiplayer"]`. JuicyJuicy also finds the snippet's `juicyjuicy:room` in the files; `check` warns when `features` lists multiplayer and the files don't have it.
