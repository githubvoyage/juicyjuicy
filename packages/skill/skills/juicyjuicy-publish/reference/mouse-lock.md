# Upgrade: mouse lock

Aiming or steering with the mouse keeps the cursor in the game. Read this when the user asks for mouse lock (the JuicyJuicy Upgrades panel's prompt names this file), then follow "Add a JuicyJuicy upgrade" in SKILL.md to publish it.

## Why
In a game that turns a camera or aims with the mouse, turning fast drags the cursor out of the game's frame, onto the page or another screen, and the game stops getting the movement. Pointer Lock hides the cursor and keeps sending movement however far the mouse goes. JuicyJuicy's frame allows it.

**Only for games that aim or steer with mouse movement** (first-person, twin-stick, flight, top-down aiming that turns the view). A game played by clicking things on screen (puzzles, cards, strategy) needs the cursor: tell the user mouse lock doesn't fit it, and stop.

## What to change
1. **Lock on a click in the game**, never on load: browsers only allow it after a user gesture. On the canvas's `click` (or a "Click to play" overlay), call `canvas.requestPointerLock()`. Where supported, `requestPointerLock({ unadjustedMovement: true })` gives raw movement; fall back to the plain call if it rejects.
2. **Read movement, not position**: while locked, use `event.movementX` and `movementY` from `mousemove` (the cursor position doesn't change). Keep the game's sensitivity setting, or add one.
3. **Follow the lock state**: on `document`'s `pointerlockchange`, `document.pointerLockElement === canvas` says whether it's locked. When the lock ends (the player pressed Esc, switched tabs, or the browser took it back), **pause** and show "Click to play"; clicking locks again. Handle `pointerlockerror` with the same screen.
4. **Menus unlock**: opening the pause menu or any screen with buttons calls `document.exitPointerLock()`, so the player can click them; going back to play locks again on the next click.
5. **Esc belongs to the browser**: in a locked or fullscreen game, Esc only gives the mouse back. Pause on the lock ending (step 3), not on the Esc key, and give pause a key other than Esc (like P), as [browser-menu.md](browser-menu.md) explains.
   Engines: Phaser has `this.input.mouse.requestPointerLock()` and `this.input.mouse.locked`; Godot sets `Input.mouse_mode = Input.MOUSE_MODE_CAPTURED` from an input event and reads `InputEventMouseMotion.relative`; Unity sets `Cursor.lockState = CursorLockMode.Locked` after a click.

## Check it
Run the game: a click locks the cursor and turning works far past the frame's edges; Esc gives the mouse back and the game pauses with "Click to play"; a click resumes; menus can be clicked.

## Declare it
Add `"mouse-lock"` to `features` in `juicy.json` (create the list if it isn't there, adding to what's listed). JuicyJuicy can't detect this one from the files, so the declaration is what turns it On in the panel; only add it once the lock works this way.
