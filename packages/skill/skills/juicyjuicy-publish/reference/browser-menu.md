# Upgrade: browser-friendly menu

The game's menu works the way a browser lets it. Read this when the user asks for a browser-friendly menu (the JuicyJuicy Upgrades panel's prompt names this file), then follow "Add a JuicyJuicy upgrade" in SKILL.md to publish it.

## Why
- **Esc belongs to the browser.** In fullscreen, Esc leaves fullscreen (and gives back a locked mouse) before the game sees the key. A menu or pause that opens only on Esc throws the player out of fullscreen instead. `navigator.keyboard.lock()` can't change that inside JuicyJuicy's frame.
- **There's nothing to quit to.** A browser game can't close its tab (`window.close()` does nothing in a frame), so a Quit button that does nothing looks broken.

## What to change
1. **Menu and pause open without Esc.** Find where the game opens its menu or pauses (search for `Escape`, `Esc`, `keyCode === 27`, `pause`). Add **P** as a key for it (keep Esc too: it still works outside fullscreen), and an **on-screen button** for it: a small pause or menu icon in a corner of the game, big enough to tap (at least 44×44 CSS pixels), that works with a mouse click and a touch. Show the key in the game's help or controls text ("P: pause").
2. **No Quit, or a Quit that says what happens.** Prefer removing Quit and Exit from the menus. If the user wants to keep it:
   - on JuicyJuicy it sends the quit message, which closes the game and leaves fullscreen: `window.parent.postMessage({ type: "juicyjuicy:quit" }, "*")`;
   - when the game runs on its own (`window.parent === window`), it shows a screen saying the progress is saved and the tab can be closed, instead of calling `window.close()`.
   Make sure progress really is saved by then (with cloud saves, call `juicy.save(...)` first).
3. **Nothing else in the game uses Esc alone** for something the player needs (closing a dialog is fine: there's always another way, like a button).

## Check it
Run the game: P and the on-screen button open and close the menu, the button works by tap in a narrow window, and Esc in fullscreen only leaves fullscreen without breaking the game.

## Declare it
Add `"browser-menu"` to `features` in `juicy.json` (create the list if it isn't there): `"features": ["browser-menu"]`. JuicyJuicy can't detect this one from the files, so the declaration is what turns it On in the panel; only add it once the menu works this way.
