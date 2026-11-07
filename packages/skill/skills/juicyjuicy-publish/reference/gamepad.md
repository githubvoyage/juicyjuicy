# Upgrade: gamepad support

The game plays with a controller. Read this when the user asks for gamepad support (the JuicyJuicy Upgrades panel's prompt names this file), then follow "Add a JuicyJuicy upgrade" in SKILL.md to publish it.

## Why
Some games feel better on a controller, and players with one plugged in expect it to work. Browsers support controllers through the Gamepad API, inside JuicyJuicy's frame too.

## What to change
1. **Read the pads every frame.** Browsers don't send events for buttons: in the game loop, call `navigator.getGamepads()` and read each connected pad's `buttons[i].pressed` and `axes`. Compare with the last frame to get "just pressed" for menus and jumps. A pad only shows up after the player presses a button on it (a browser rule), so don't wait for `gamepadconnected` to start reading.
2. **Use the standard layout** (`pad.mapping === "standard"`, what most pads report): button 0 is A/Cross (confirm, jump), 1 is B/Circle (back), 2 X/Square, 3 Y/Triangle, 4–5 the bumpers, 6–7 the triggers (`value` from 0 to 1), 8 Back/Select, 9 Start (pause and menu), 12–15 the d-pad up, down, left, right; axes 0–1 the left stick (x, y; down is +1), 2–3 the right stick.
3. **Dead zone**: treat a stick below about 0.2 from the centre as centred, so a worn stick doesn't drift. Let the d-pad and the left stick both move.
4. **Map pads onto the game's actions, not its keys.** If the game reads keys directly, add an input layer (`isDown("jump")` = Space or button 0) rather than faking keyboard events. Keep the keyboard working exactly as before.
5. **Menus work with a pad**: move the selection with the d-pad or stick, A confirms, B goes back, Start pauses. Show which button does what when a pad is in use ("A: jump"), keyboard hints otherwise.
6. **Local multiplayer** (if the game has it): one pad per player, by its `index`; a newly connected pad can join.
   Engines: Phaser has `this.input.gamepad` (set `input: { gamepad: true }` in the game config); Godot maps joypad buttons in the Input Map (`JOY_BUTTON_A`…) and works in the web export; Unity's Input System supports gamepads in WebGL.

## Check it
Plug in a controller (or pair one), press a button, then play a full round with the pad only: menus, play, pause, game over, restart. Check the keyboard still works.

## Declare it
Add `"gamepad"` to `input` in `juicy.json` (`"input": ["keyboard", "gamepad"]`, keeping what's there), and `"gamepad"` to `features` (adding to the list). JuicyJuicy can't detect this one from the files, so the declaration is what turns it On in the panel; only add it once a full round plays with the pad.
