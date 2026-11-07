# Upgrade: touch controls

The game plays on phones and tablets. Read this when the user asks for touch controls (the JuicyJuicy Upgrades panel's prompt names this file), then follow "Add a JuicyJuicy upgrade" in SKILL.md to publish it.

## Why
Many players open a shared link on their phone. JuicyJuicy shows the game there full width, and players without a keyboard or mouse can only watch unless the game takes touches. Games with touch also get the **Touch controls** chip and filter on JuicyJuicy.

## What to change
1. **Pick the controls that fit the game**, and say which to the user before building, in a sentence:
   - **Taps and drags** for games already played with the mouse (clicks, aiming, dragging pieces): make the pointer code work for touch. Use Pointer Events (`pointerdown`, `pointermove`, `pointerup`) instead of mouse events, so one handler takes both; for multi-touch, track each `pointerId`.
   - **Swipes** for games with four directions (snake, 2048, tile puzzles): a swipe longer than about 30 CSS pixels in its main direction is the arrow key.
   - **On-screen buttons** for games with keys held down (platformers, shooters, racing): a d-pad or a virtual stick on the left, action buttons on the right. Each button is at least 44×44 CSS pixels with space between, semi-transparent over the game, and holding it acts like holding the key (press on `pointerdown`, release on `pointerup`, `pointercancel` and `pointerleave`).
   Engines: Phaser has `this.input.on("pointerdown", …)` and `this.input.addPointer()` for more fingers; Godot has `InputEventScreenTouch`/`ScreenDrag` and a `TouchScreenButton` node that triggers an input action; Unity uses its Input System's on-screen controls.
2. **Show on-screen buttons only on touch screens**: when `matchMedia("(pointer: coarse)").matches`, or from the first `touchstart`/`pointerdown` with `pointerType === "touch"`. Keyboard players keep the screen as it was.
3. **Stop the browser taking the gestures.** On the game's canvas or container, set the CSS `touch-action: none` and `user-select: none; -webkit-user-select: none; -webkit-touch-callout: none`, so drags don't scroll or zoom the page and a long press doesn't select or open a menu. Keep `<meta name="viewport" content="width=device-width, initial-scale=1">`.
4. **Fit a phone screen.** The game scales to its frame (no fixed 1280×720 page with scrollbars); text and buttons stay readable in a narrow window. If the game only works one way round, set `orientation` in `juicy.json` (`landscape` or `portrait`).
5. **Menus and dialogs work by tap**: every key-only action ("press Enter to start", "Space to restart") gets a tap target too, and the help text says "tap" on touch screens.

## Check it
Run the game in the browser's device mode (a phone size, touch on) and play a full round with touch only: start, play, pause, game over, restart. Then check the keyboard and mouse still work as before.

## Declare it
Add `"touch"` to `input` in `juicy.json` (`"input": ["keyboard", "touch"]`, keeping what's there), and `"touch"` to `features` (`"features": ["touch"]`, adding to the list). JuicyJuicy can't detect this one from the files: `input` is what the site's chip and the Upgrades panel read, so only add it once a full round plays by touch.
