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
3. **How players join:** through the default menu (see "The menu"): **Multiplayer** → **Search lobby** (a list of public lobbies, plus a code box) or **Host lobby** (a lobby the host switches between Public and Private, with an Invite link). Say you'll build that unless they want something else. Can someone join a game that has started, or only in the lobby?
4. **When someone leaves:** does the game go on without them? When the host leaves, the next player takes over (see "When the host changes"); is that right for this game?
5. **Phones:** should it play on phones (touch controls)?
6. **Anything else:** teams, rounds, a winner screen, what each player sees of the others.

Then write the design back in a few lines: the screens (the default menu's, then game and results), what the host runs, what each player sends and what the host sends back. **Build it only once the user agrees**, then follow "The menu", "Using it" and "How to build it".

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
    if (event.source !== window.parent || !m) return;
    if (m.type !== "juicyjuicy:room-ticket" && m.type !== "juicyjuicy:room-list") return;
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
  // The player's answer to a message, or null when not on JuicyJuicy.
  function ask(message) {
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
        if (m.inviteUrl) inviteUrl = m.inviteUrl;
        resolve(m);
      };
      message.id = id;
      window.parent.postMessage(message, "*");
    });
  }
  // The invite code, and a ticket when asked.
  function askTicket(ticket) {
    return ask({ type: "juicyjuicy:room", ticket: ticket });
  }

  function Room(code) {
    this.code = code;
    this.me = null;
    this.host = null;
    this.max = 0;
    this.locked = false;
    this.public = false;
    this.label = null;
    this.players = [];
    this.handlers = {};
    this.link = null;
    this.opened = false;
    this.closed = false;
  }
  // Events: "message" (data, fromId), "join" (player), "leave" (player), "host" (id),
  // "lock" (locked), "public" (isPublic), "error" (error), "close" (reason).
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
  // The host only: list the room in the game's public rooms (false: invite only).
  Room.prototype.setPublic = function (on) {
    if (this.link) this.link.send({ t: "public", public: on !== false });
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
      room.public = m.public === true;
      room.label = m.label || null;
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
    } else if (m.t === "public") {
      room.public = m.public;
      room.emit("public", m.public);
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
    return askTicket(true).then(function (m) {
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
      else if (e.to === "list") bus().postMessage({ to: e.from, id: e.id, rooms: localRooms(e.from, e.label) });
      else if (e.to === tab && e.rooms) { if (lists[e.id]) lists[e.id].push.apply(lists[e.id], e.rooms); }
      else if (e.to === tab && mine[e.code]) mine[e.code].receive(e.m);
    };
    window.addEventListener("pagehide", function () {
      Object.keys(mine).forEach(function (code) { mine[code].leave(); });
    });
    return channel;
  }
  function LocalRelay(code, max, options) {
    this.code = code;
    this.max = max;
    this.public = options.public;
    this.label = options.label;
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
  // How the room shows in list() to the tab "from", or null when it isn't listed.
  LocalRelay.prototype.entry = function (from) {
    var relay = this;
    var host = null;
    relay.players.forEach(function (p) { if (p.id === relay.host) host = p; });
    if (!relay.public || relay.locked || !host || relay.kicked[from]) return null;
    if (relay.players.length >= relay.max) return null;
    return { code: relay.code, host: host.name, players: relay.players.length, max: relay.max,
      label: relay.label };
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
        max: relay.max, locked: relay.locked, public: relay.public, label: relay.label,
        players: relay.list() });
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
    } else if (m.t === "public") {
      relay.public = m.public;
      relay.everyone({ t: "public", public: m.public });
    } else if (m.t === "kick") {
      relay.players.slice().forEach(function (p) {
        if (p.id !== m.id || p === player) return;
        relay.kicked[p.tab] = true;
        relay.deliver(p.tab, { t: "closed", reason: "KICKED" });
        relay.remove(p);
      });
    }
  };
  function joinLocal(room, max, options) {
    return new Promise(function (resolve, reject) {
      var code = room.code;
      if (max) relays[code] = new LocalRelay(code, max, options);
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
  // The public rooms of this origin's tabs, as list() shows them: other tabs answer within 300 ms.
  var lists = {};
  function localRooms(from, label) {
    var found = [];
    Object.keys(relays).forEach(function (code) {
      var entry = relays[code].entry(from);
      if (entry && (!label || entry.label === label)) found.push(entry);
    });
    return found;
  }
  function listLocal(label) {
    return new Promise(function (resolve) {
      var id = "list-" + ++next;
      var found = lists[id] = localRooms(tab, label);
      bus().postMessage({ to: "list", from: tab, id: id, label: label });
      setTimeout(function () {
        delete lists[id];
        resolve(found);
      }, 300);
    });
  }
  function newCode() {
    var letters = "ABCDEFGHJKMNPQRSTUVWXYZ23456789";
    var code = "";
    for (var i = 0; i < 6; i++) code += letters[Math.floor(Math.random() * letters.length)];
    return code;
  }
  // A label is the game's own id for a kind of room, never text a player typed.
  function checkLabel(label) {
    if (label != null && !/^[a-z0-9-]{1,24}$/.test(label)) {
      throw fail("INVALID", "A room label is 1 to 24 of a-z, 0-9 and -");
    }
    return label || null;
  }

  juicy.rooms = {
    // Opens a new room with this player as its host. options.max: most players, 2 to 10.
    // options.public: true lists it in list() for anyone to join; options.label: the game's id for
    // the kind of room (a mode, a map), shown in the list.
    create: function (options) {
      options = options || {};
      var max = Math.max(2, Math.min(10, options.max || 10));
      var label;
      try {
        label = checkLabel(options.label);
      } catch (e) {
        return Promise.reject(e);
      }
      var listed = options.public === true;
      return askTicket(true).then(function (m) {
        var room = new Room(null);
        if (m) {
          return connect(room, "&create=1&max=" + max + (listed ? "&public=1" : "") +
            (label ? "&label=" + label : ""));
        }
        room.code = newCode();
        return joinLocal(room, max, { public: listed, label: label });
      });
    },
    // Joins the room with this code (from invited(), list(), or typed in by the player).
    join: function (code) {
      code = String(code || "").trim().toUpperCase();
      return askTicket(true).then(function (m) {
        var room = new Room(code);
        return m ? connect(room, "&room=" + encodeURIComponent(code)) : joinLocal(room, 0);
      });
    },
    // The game's public rooms that can be joined now (not full or locked), newest first:
    // [{ code, host, players, max, label }]. options.label: only rooms with that label.
    list: function (options) {
      var label;
      try {
        label = checkLabel(options && options.label);
      } catch (e) {
        return Promise.reject(e);
      }
      return ask({ type: "juicyjuicy:list-rooms", label: label }).then(function (m) {
        return m ? m.rooms : listLocal(label);
      });
    },
    // The room code of the invite link that opened the game, or null.
    invited: function () {
      return askTicket(false).then(function (m) {
        if (m) return m.invite;
        var found = /[?&]room=([A-Za-z0-9]{6})/.exec(location.search);
        return found ? found[1].toUpperCase() : null;
      });
    }
  };
})(window.juicy);
```

## The menu
Every game gets this multiplayer menu unless the user asks for another. Build it as the game's own screens, in its own look (fonts, colors, button style), and make every screen work at phone width and by keyboard.

1. **Main menu:** a **Multiplayer** button next to the game's own buttons (Play, Settings…).
2. **Multiplayer:** two buttons, **Search lobby** and **Host lobby**, and **Back**.
3. **Search lobby:**
   - A small framed box listing the public lobbies from `juicy.rooms.list()`: on each row the host's login (with `textContent`), the players (`2/4`), the label in the game's own words if the game uses labels, and a **Join** button. The box keeps its size and scrolls inside when the list is long.
   - A **refresh icon button** (↻, with `aria-label="Refresh"`) at the box's top right. The list loads once when the screen opens and again only when the player presses it (each read counts against the player's limit; never more often than every 5 seconds).
   - Under the box, a line "Private lobby? Enter its code", a **code box** (6 letters, upper case, `maxlength="6"`) and a **Join** button; Enter in the box joins too.
   - An empty list says so in the box ("No open lobbies. Host one!") and keeps the code box working.
   - **Back**.
4. **Host lobby** opens a room with `create({ max, public: true })` and goes straight to the lobby screen. **Join** from Search or the code box goes there too.
5. **The lobby:**
   - The **lobby code** big and spaced out (`K7QX2M`), so it can be read out.
   - For the host only, a **Public / Private** switch: Public is listed in Search lobby; Private is only for people with the code or invite link (`room.setPublic(false)`, `room.setPublic()`), with that line under it. It starts on Public; a game meant only for friends (or a user who asks) starts on Private instead. Everyone else sees which it is as text, without the switch.
   - The players, the host marked (a crown or "(host)"), with empty "Waiting…" slots up to `room.max` (`2/4`).
   - **Invite** (`room.invite()`: JuicyJuicy's share sheet), **Start** for the host only (the others see "Waiting for the host"), and **Leave**.
6. **Opened from an invite link** (`juicy.rooms.invited()`): skip the menu and join that room's lobby.

Errors (a wrong code, a full room, signed out) show as a short line on the screen the player is on, which stays open. A closed room goes back to the Multiplayer screen with the reason.

## Using it
```js
// Opened from an invite link: join that lobby straight away.
const code = await juicy.rooms.invited();
if (code) enter(() => juicy.rooms.join(code));

multiplayerButton.onclick = () => showScreen("multiplayer"); // Search lobby, Host lobby, Back
hostButton.onclick = () => enter(() => juicy.rooms.create({ max: 4, public: true }));
searchButton.onclick = () => { showScreen("search"); refresh(); };
refreshButton.onclick = refresh; // the ↻ icon at the list's top right
joinCodeButton.onclick = () => enter(() => juicy.rooms.join(codeInput.value));

async function refresh() {
  const rooms = await juicy.rooms.list(); // [{ code, host, players, max, label }]
  // One row per room: host login and players (textContent), and a Join button that runs
  // enter(() => juicy.rooms.join(room.code)). None: "No open lobbies. Host one!"
  showRooms(rooms);
}

async function enter(open) {
  try {
    start(await open());
  } catch (error) {
    showError(error.code); // a short line on this screen: wrong code, full, signed out…
  }
}

function start(room) {
  showScreen("lobby");
  showLobby(room); // room.code, room.players ([{ id: "p1", name: "luk" }, …], with textContent), room.max
  publicSwitch.hidden = !room.isHost();
  publicSwitch.onchange = () => room.setPublic(publicSwitch.checked); // Public / Private
  inviteButton.onclick = () => room.invite(); // JuicyJuicy's share sheet, with Copy link
  startButton.hidden = !room.isHost();
  startButton.onclick = () => { room.send({ k: "start" }); room.lock(); beginGame(room); };
  leaveButton.onclick = () => room.leave();
  room.on("join", () => showLobby(room));
  room.on("leave", () => showLobby(room));
  room.on("host", () => showLobby(room)); // the new host gets the switch and Start
  room.on("public", (isPublic) => showPublic(isPublic));
  room.on("message", (data, from) => (data.k === "start" ? beginGame(room) : handle(data, from)));
  room.on("close", (reason) => { showScreen("multiplayer"); showError(reason); });
}
```

- `juicy.rooms.create({ max })` opens a room (2 to 10 players; 10 by default) with this player as host; `join(code)` joins one (any case, spaces ignored). Both resolve to the room once it's open, and reject with an `Error` whose `code` says why: `SIGNED_OUT` (JuicyJuicy has offered to sign in), `ROOM_NOT_FOUND`, `ROOM_FULL`, `ROOM_LOCKED`, `KICKED`, `RATE_LIMITED`, `PAUSED` (multiplayer paused for a while), `OFF`, `GAME_GONE`, `TIMEOUT`, `DISCONNECTED` or `FAILED`. Show the player a short message and go back to the menu.
- `juicy.rooms.invited()` resolves to the code of the invite link that opened the game, or null.
- `juicy.rooms.create({ max, public: true, label })` opens a **public** room: other players of this game see it in `juicy.rooms.list()` and can join it without an invite. `label` is optional: an id the game picks from its own fixed set (`"duel"`, `"team-4"`; 1 to 24 of `a-z`, `0-9` and `-`), for a mode or map. A label that isn't one rejects with `INVALID`.
- `juicy.rooms.list({ label })` resolves to the public rooms that can be joined now, newest first, at most 50: `[{ code, host, players, max, label }]` (`host` is the host's login). Full and locked rooms aren't in it. With `label`, only rooms with that label. It rejects like `create()` (`SIGNED_OUT`, `RATE_LIMITED`, `PAUSED`, `OFF`, `FAILED`, `TIMEOUT`). Join one with `join(room.code)`.
- The room: `room.code`, `room.me` (this player's id, like `"p2"`), `room.host` (the host's id), `room.isHost()`, `room.players` (`{ id, name }`, name being the member's JuicyJuicy login), `room.player(id)`, `room.locked`, `room.max`, `room.public` and `room.label`.
- `room.send(data)` sends any JSON value to everyone else; `room.send(data, id)` only to that player. A player never gets their own messages.
- `room.on(event, handler)`: `"message"` (data, fromId), `"join"` (player), `"leave"` (player), `"host"` (the new host's id), `"lock"` (locked), `"public"` (whether it's listed), `"error"` (an `Error` with a `code`: `RATE_LIMITED`, `TOO_LARGE`, `NOT_HOST`, `NO_PLAYER`, `INVALID`; the room goes on), `"close"` (reason: `LEFT`, `KICKED`, `REPLACED` (the same player joined from another tab), `ROOM_NOT_FOUND`, `TOO_FAST`, `GAME_GONE`, `OFF` or `DISCONNECTED`).
- The host only: `room.lock()` stops new players joining (players who were in can come back) and takes a public room off the list, `room.lock(false)` opens it again; `room.kick(id)` removes a player for good (they don't see the room in the list either); `room.setPublic(false)` makes a public room invite-only, `room.setPublic()` lists it.
- `room.invite()` shows JuicyJuicy's share sheet over the game and returns the link (`https://juicyjuicy.games/g/<slug>/play?room=CODE`).
- `room.leave()` leaves the room.

## How to build it
- **The host runs the game.** Players send their input (`{ k: "input", left: true }`, a move, a card played); the host applies it to the one true game state and sends the state, or what changed, to everyone. Players draw what the host sent and never decide outcomes themselves. For a real-time game, send state 10 to 20 times a second and smooth movement between updates; send input when it changes, not every frame.
- **Small messages with a kind:** `{ k: "state", … }`, `{ k: "input", … }`. Each message is at most 16 KB as JSON, and each player may send at most 60 messages and 64 KB a second (one `send` to everyone counts once). Over that, messages are dropped (`RATE_LIMITED`), and far over it the player is disconnected (`TOO_FAST`).
- **The lobby** is the screen in "The menu". When the game starts, the host sends `{ k: "start", … }` and calls `room.lock()` if nobody may join mid-game. If players may drop in, the host sends `{ k: "start" }` to each player who joins (`room.send(data, player.id)`) so they go straight into the game.
- **Public and private lobbies:** Host lobby opens a public room, which Search lobby lists; the host's switch makes it private (`room.setPublic(false)`: only the code and the invite link get in) and public again (`room.setPublic()`). The `"public"` event tells everyone, so the lobby can show which it is.
  - Lock the room (`room.lock()`) when the round starts unless players may drop in: that takes it off the list. Unlock it after the round to let the next players in.
  - **Labels** are optional, for a game with modes or maps in Search lobby (`create({ public: true, label: "duel" })`, `list({ label })`). A label is only the game's own id, from a fixed set in the code. **Never** put text a player typed into a label: no lobby names (there's no moderation; the security review treats it like free-text chat).
- **When the host changes** (the host left or dropped): every player keeps the last state the host sent, so on `"host"` the new host (`room.isHost()`) carries on from it and starts sending state. A turn-based game resends whose turn it is.
- **When a player leaves**, the host decides: remove their character, let the round finish, or end the game if too few are left.
- **Dropped connections:** phones drop them when the game goes to the background. The snippet reconnects by itself (three tries) and keeps the player's id; during that time `send` does nothing. When the host comes back, it asks for nothing: players resend what they need on `"join"` or `"host"`.
- **Player names are text from other people:** show them with `textContent`, never `innerHTML` (the security review checks it).
- **No free-text chat.** JuicyJuicy can't moderate it yet. Quick messages or emotes from a fixed list are fine.
- **No other server, no keys:** everything goes through the room.

## Try it
Outside JuicyJuicy, on a local server, the snippet runs rooms **between tabs of the same address**: open the game in two tabs, open a room in one and join it from the other with its code (or open the link `room.invite()` returns). Players are called "Player 1", "Player 2"…, and the room ends when the tab that opened it closes (on JuicyJuicy the host moves to the next player instead). Try every screen with two or three tabs, including leaving and rejoining, before publishing. `list()` shows the public rooms of the other tabs.

On JuicyJuicy, two people (or two browsers signed in as two members) can play it from an invite link once the update is live.

## Declare it
Add `"multiplayer"` to `features` in `juicy.json`: `"features": ["multiplayer"]`. JuicyJuicy also finds the snippet's `juicyjuicy:room` in the files; `check` warns when `features` lists multiplayer and the files don't have it.
