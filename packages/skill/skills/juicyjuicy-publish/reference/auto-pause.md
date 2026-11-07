# Upgrade: auto-pause

The game pauses by itself when its tab is hidden or the window loses focus. Read this when the user asks for auto-pause (the JuicyJuicy Upgrades panel's prompt names this file), then follow "Add a JuicyJuicy upgrade" in SKILL.md to publish it.

## Why
Players switch tabs, answer a message or click another window for a moment. A game that keeps running loses their run; one that only stops its loop because the browser slows hidden tabs comes back with a huge time step and jumps. Pausing on its own and waiting for them is what players expect.

**Only for games where time matters.** A game that waits for the player anyway (turn-based, puzzles without a timer, idle games that count time away on purpose) doesn't need it: say so to the user, and stop unless they want it.

## What to change
1. **Pause when the game can't be seen or played**: on `document`'s `visibilitychange` when `document.hidden` is true, and on `window`'s `blur` (the window, or the page around JuicyJuicy's frame, took the focus). Use the game's own pause, the same one its pause key or button opens, so the menu shows.
2. **Don't resume by itself.** When the tab comes back (`visibilitychange` with `document.hidden` false, or `focus`), leave the pause screen up; the player resumes with a click, a tap, the pause key or the Start button. Coming back into a running game is what this upgrade avoids.
3. **Only during play**: don't pause on the title screen, a menu, game over, or a multiplayer game other players depend on (there, keep it running and just mute, or follow the game's own rule).
4. **Stop what runs on its own**: the game's clock and timers count only playing time (pause the timer, or measure with the loop's capped `dt`), music and sounds pause or mute, and the loop's time step is capped (say 1/30 s) so a long frame after a pause can't jump the game.
5. **Save on hide** if the game saves: hiding is often the last chance before the tab closes (with cloud saves, call `juicy.save(...)` there).
   Engines: Phaser pauses its loop on hidden tabs by itself but not on `blur`, and resumes by itself: add the game's pause scene on both, so the player resumes; Godot gets `NOTIFICATION_APPLICATION_FOCUS_OUT` and can set `get_tree().paused = true`; Unity has `OnApplicationFocus(false)` and `OnApplicationPause(true)`.

## Check it
Run the game, start playing, then switch tabs for ten seconds and come back: it's paused where it was, the clock didn't run, and it resumes when the player asks. Do the same by clicking outside the window. The title screen and menus don't pause.

## Declare it
Add `"auto-pause"` to `features` in `juicy.json` (create the list if it isn't there, adding to what's listed). JuicyJuicy can't detect this one from the files, so the declaration is what turns it On in the panel; only add it once the game pauses this way.
