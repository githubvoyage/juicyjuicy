# Upgrade: mobile optimization

The game plays well on phones and tablets: controls, screen, sound and speed. Read this when the user asks for mobile optimization or touch controls (the JuicyJuicy Upgrades panel's prompt names this file), then follow "Add a JuicyJuicy upgrade" in SKILL.md to publish it. Read it too when you **make a new game for phones**: build it this way from the start (see "Made for phones first").

## Why
Many players open a shared link on their phone. JuicyJuicy has a **Computer** and a **Phone** tab, phones open on Phone, and only games whose `platforms` list `mobile` show there. On a phone the player gives the game the whole screen: the only thing over it is a small round pill (back, home, fullscreen) in the **top-left corner**. Players without a keyboard or mouse can only watch unless the game takes touches, and a game laid out for a desktop window ends up cut off or tiny. Games with touch also get the **Touch controls** chip and filter on JuicyJuicy.

## Made for phones first
For a new game meant for phones, decide the shape before anything else and build for it:
- **Portrait** suits one-thumb games (puzzles, tapping, cards): `orientation: "portrait"`, `aspectRatio: "9:16"`. Landscape suits games with two thumbs on buttons (racing, platformers): `"landscape"`, `"16:9"`. `any` only when both layouts are really built.
- **Lay it out for about 390×844 CSS pixels** (a phone held upright; 844×390 sideways) and scale up from there, not down from a desktop 1280×720. Size the play area from `innerWidth`/`innerHeight` with `Math.min(width / designWidth, height / designHeight)` so it fits whole, and fill the space left over with background, never with black bars or scrollbars.
- **Plan for less height than the phone has.** The browser's own bars take a lot: a 390×844 phone often leaves about 390×660 to the page, a small one (375×667) about 375×550, and Android's 360×640 less. Lay the play area out to fit the shortest of these, and add a compact layout for short frames (`@media (max-height: 700px)`: smaller top bar, buttons and gaps) rather than letting the bottom row fall off.
- **Fill the whole screen, edge to edge.** Put `viewport-fit=cover` in the viewport meta (`width=device-width, initial-scale=1, viewport-fit=cover`), draw the canvas `position: fixed; inset: 0`, give `html, body` the game's background colour, and pad the HUD with `env(safe-area-inset-top)`, `-bottom`, `-left` and `-right` so nothing sits under a notch, rounded corner or home bar.
- **Draw sharp.** Size the canvas's pixels as its CSS size × `devicePixelRatio` (capped at 3, and lower only if a round drops frames), then `ctx.scale(dpr, dpr)`: a canvas at CSS size looks blurry next to the page's crisp buttons on a phone's 3× screen. Keep big screens in budget with `Math.min(devicePixelRatio, 3, Math.sqrt(12e6 / (width * height)))`. Text and buttons read best as HTML over the canvas.
- **Keep the top-left corner clear**: about 140×52 CSS pixels (plus `env(safe-area-inset-left)`) is where JuicyJuicy's pill sits. Put the score, pause and menu buttons top-right, along the top centre or at the bottom.
- **Put the main actions under the thumbs**: the bottom third of the screen, targets at least 44×44 CSS pixels. Buttons get `touch-action: manipulation` (no double-tap zoom or tap delay) and `-webkit-tap-highlight-color: transparent`; a list that scrolls inside the game (levels, a shop) gets `overflow-y: auto; touch-action: pan-y` on that list alone.
- **Feel it**: a short `navigator.vibrate(10)` on taps and a pattern on win or loss (Android; iPhones ignore it), inside `try`, and never as the only feedback.
- Declare `"platforms": ["mobile"]` (add `"desktop"` too only if it also plays well with a mouse on a big screen; a phone-only game still plays on a computer by link, in a phone-shaped box), `"input": ["touch", …]` and `"features": ["touch"]`.

Then go through "What to change" below as a checklist.

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
8. **Work both ways round if you can**, with a layout for tall and for wide frames, as the shapes are very different. If the game only works one way, set `orientation` in `juicy.json` (`landscape` or `portrait`): JuicyJuicy then shows "Rotate your phone" over it when the phone is held the other way, and on Android it plays in fullscreen turned the right way. The player can still choose to play anyway, so pause while the frame is the wrong shape and lay out sensibly until a `resize` puts it right. iPhones can't lock the orientation.
9. **Keep controls clear.** On-screen controls sit at least 16 CSS pixels from the frame's edges, under the thumbs, and don't cover the player or the action. In a tall frame, put them below the play area when there's room. Leave the top-left corner (about 140×52 CSS pixels) to JuicyJuicy's pill: nothing to tap there, and nothing the player must read.
10. **Never need fullscreen.** iPhone Safari can't put a game in fullscreen: hide the game's own fullscreen button when `document.fullscreenEnabled` is false.

### Phone browsers
11. **Sound starts on a tap.** Phones keep audio silent until the player touches the game: create or `resume()` the `AudioContext` in a `pointerup` or `click` handler (iPhones don't accept `pointerdown`), and `resume()` again when the page becomes visible, since a call or switching apps suspends it.
12. **Nothing depends on the mouse or keyboard being there.** Phones have no Pointer Lock: when `requestPointerLock` is missing or fails, aim by dragging or with a stick. Only a real `<input>` brings up the on-screen keyboard: focus it inside the tap's handler and give it `font-size: 16px`, or iPhones zoom the page.
13. **Run smoothly, and sharp.** Draw at `Math.min(devicePixelRatio, 3)` so the game is as crisp as the page around it, and only go lower (2) or use fewer particles or effects if a round drops frames. Desktop keeps its full quality.
14. **Stop when hidden.** Phones switch apps often: on `visibilitychange` to hidden, pause a real-time game and stop its sound.

## Check it
Run the game in the browser's device mode (touch on) and play a full round with touch only: start, play, pause, game over, restart. Do it at a big phone (390×844), a big phone with the browser's bars (390×660), a small one (375×667, and 375×550 with bars) and on its side (844×390) if it turns. Rotate in the middle of a round and check it carries on. Check the page never scrolls or zooms, nothing is cut off at the shortest size, text is readable without zooming, the art is sharp, the HUD clears the notch and home bar, and nothing you need is in the top-left corner. Then check the keyboard and mouse still work as before. `check` warns (`mobile-basics`) when a game listed for `mobile` has no viewport meta, no touch input, no `touch-action`, no resize handling, or text that says "press Space" and never "tap".

Before you declare `mobile`, tell the user in a few lines what you checked and at which sizes, and what only a real phone can show.

Device mode can't show everything, sound on iPhones above all: before publishing, tell the user, in a sentence, how to try the game on a real phone, e.g. by serving the build on the local network (`npx serve dist -l 5173`, or Vite's `--host`) and opening the address it prints on a phone on the same Wi-Fi.

## When it doesn't fit
Some games can't work on a phone, such as one that needs a full keyboard all the time. Tell the user why, do what still helps (screen fit, readable text) if they want it, and don't declare it: the game stays on the Computer tab only, and phone players who open its link are told it's made for a computer.

## Declare it
Add `"touch"` to `input` in `juicy.json` (`"input": ["keyboard", "touch"]`, keeping what's there), `"touch"` to `features` (`"features": ["touch"]`, adding to the list) and `"mobile"` to `platforms` (`"platforms": ["desktop", "mobile"]`). JuicyJuicy can't detect this one from the files: `input` is what the site's chip reads, `features` is what ends the Upgrades panel's offer and `platforms` puts the game on the Phone tab, so only add them once a full round plays well by touch at phone size. Tell the user the game will now show on the Phone tab.
