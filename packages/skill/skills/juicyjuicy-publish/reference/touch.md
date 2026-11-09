# Upgrade: mobile optimization

The game plays well on phones and tablets: controls, screen, sound and speed. Read this when the user asks for mobile optimization or touch controls (the JuicyJuicy Upgrades panel's prompt names this file), then follow "Add a JuicyJuicy upgrade" in SKILL.md to publish it.

## Why
Many players open a shared link on their phone. JuicyJuicy shows the game there in a frame that fills the screen below a slim bar. Players without a keyboard or mouse can only watch unless the game takes touches, and a game laid out for a desktop window ends up cut off or tiny. Games with touch also get the **Touch controls** chip and filter on JuicyJuicy.

## What to change
Go through every part, also when the game already takes touches: fix what falls short and leave what's already right. Keyboard and mouse players keep the game as it was.

### Controls
1. **Pick the controls that fit the game**, and say which to the user before building, in a sentence:
   - **Taps and drags** for games already played with the mouse (clicks, aiming, dragging pieces): make the pointer code work for touch. Use Pointer Events (`pointerdown`, `pointermove`, `pointerup`) instead of mouse events, so one handler takes both; for multi-touch, track each `pointerId`.
   - **Swipes** for games with four directions (snake, 2048, tile puzzles): a swipe longer than about 30 CSS pixels in its main direction is the arrow key.
   - **On-screen buttons** for games with keys held down (platformers, shooters, racing): a d-pad or a virtual stick on the left, action buttons on the right. Each button is at least 44×44 CSS pixels with space between, semi-transparent over the game, and holding it acts like holding the key (press on `pointerdown`, release on `pointerup`, `pointercancel` and `pointerleave`). Moving and jumping at once must work: track each `pointerId`.
   Engines: Phaser has `this.input.on("pointerdown", …)` and `this.input.addPointer()` for more fingers; Godot has `InputEventScreenTouch`/`ScreenDrag` and a `TouchScreenButton` node that triggers an input action; Unity uses its Input System's on-screen controls.
2. **Show on-screen buttons only on touch screens**: when `matchMedia("(pointer: coarse)").matches`, or from the first `touchstart`/`pointerdown` with `pointerType === "touch"`.
3. **Stop the browser taking the gestures.** On the game's canvas or container, set the CSS `touch-action: none` and `user-select: none; -webkit-user-select: none; -webkit-touch-callout: none`, so drags don't scroll or zoom the page and a long press doesn't select or open a menu. On `html, body` set `overscroll-behavior: none; overflow: hidden`, unless the game is a page meant to scroll. Keep `<meta name="viewport" content="width=device-width, initial-scale=1">`.
4. **Menus and dialogs work by tap**: every key-only action ("press Enter to start", "Space to restart") gets a tap target too, and the help text says "tap" on touch screens. Anything shown only on hover also needs a tap.

### Screen
5. **Fit the frame.** Size the game from the frame (`innerWidth` and `innerHeight`, or CSS `100%`): no fixed 1280×720 page with scrollbars, and nothing important cut off at a narrow width.
6. **Survive every resize.** Rotating the phone, the browser's address bar sliding away and the on-screen keyboard all resize the frame. Listen for `resize`, lay the game out again and keep playing: never restart the level or lose the score because of it.
7. **Stay readable.** Size text and buttons in CSS pixels from the frame, not from the game's internal resolution, so a 1920-wide canvas shrunk to a phone doesn't shrink its text with it: body text at least 14 CSS pixels, tap targets at least 44.
8. **Work both ways round if you can**, with a layout for tall and for wide frames, as the shapes are very different. If the game only works one way, set `orientation` in `juicy.json` (`landscape` or `portrait`) and, when the frame is the other way round, pause and show "Rotate your phone" over the game until a `resize` puts it right. Nothing rotates the game for you: `screen.orientation.lock()` doesn't work on iPhones.
9. **Keep controls clear.** On-screen controls sit at least 16 CSS pixels from the frame's edges, under the thumbs, and don't cover the player or the action. In a tall frame, put them below the play area when there's room.
10. **Never need fullscreen.** iPhone Safari can't put a game in fullscreen: hide the game's own fullscreen button when `document.fullscreenEnabled` is false.

### Phone browsers
11. **Sound starts on a tap.** Phones keep audio silent until the player touches the game: create or `resume()` the `AudioContext` in a `pointerup` or `click` handler (iPhones don't accept `pointerdown`), and `resume()` again when the page becomes visible, since a call or switching apps suspends it.
12. **Nothing depends on the mouse or keyboard being there.** Phones have no Pointer Lock: when `requestPointerLock` is missing or fails, aim by dragging or with a stick. Only a real `<input>` brings up the on-screen keyboard: focus it inside the tap's handler and give it `font-size: 16px`, or iPhones zoom the page.
13. **Run smoothly.** Cap the drawing resolution on touch screens at `Math.min(devicePixelRatio, 2)`, and use fewer particles or effects there if a round drops frames. Desktop keeps its full quality.
14. **Stop when hidden.** Phones switch apps often: on `visibilitychange` to hidden, pause a real-time game and stop its sound.

## Check it
Run the game in the browser's device mode (a phone size, touch on), upright and on its side (about 390×844 and 844×390), and play a full round with touch only: start, play, pause, game over, restart. Rotate in the middle of a round and check it carries on. Check the page never scrolls or zooms and nothing is cut off. Then check the keyboard and mouse still work as before.

Device mode can't show everything, sound on iPhones above all: tell the user, in a sentence, to try the game on a real phone after publishing.

## When it doesn't fit
Some games can't work on a phone, such as one that needs a full keyboard all the time. Tell the user why, do what still helps (screen fit, readable text) if they want it, and don't declare it.

## Declare it
Add `"touch"` to `input` in `juicy.json` (`"input": ["keyboard", "touch"]`, keeping what's there), and `"touch"` to `features` (`"features": ["touch"]`, adding to the list). JuicyJuicy can't detect this one from the files: `input` is what the site's chip reads and `features` is what ends the Upgrades panel's offer, so only add them once a full round plays by touch.
