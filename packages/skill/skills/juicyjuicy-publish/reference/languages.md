# Upgrade: multi-language

The game plays in English by default, with a switch to other languages. Read this when the user asks for more languages (the JuicyJuicy Upgrades panel's prompt names this file and the languages to add), then follow "Add a JuicyJuicy upgrade" in SKILL.md to publish it.

JuicyJuicy offers English, French, Italian, German, Spanish and Polish (`en`, `fr`, `it`, `de`, `es`, `pl`). Add the ones the user asked for; keep the ones the game already has.

## What to change
1. **One text table per language.** Move every piece of player-facing text (menus, buttons, help, dialogue, messages, text drawn on the canvas) into one object per language with the same keys, and look text up through one function, e.g. `t("start")`. A game that already has tables gets new ones with the same keys.
2. **English is the default** every time the game starts for the first time, whatever the browser's language. The player's choice is remembered: keep it with the game's save (with cloud saves, in the object passed to `juicy.save`), else in `localStorage`.
3. **A visible switch** on the title screen and in the menu, each language in its own name and short: `EN | FR | IT | DE | ES | PL`, or a list with English, Français, Italiano, Deutsch, Español, Polski. Switching takes effect right away, without restarting the level.
4. **Translate well.** Natural, short game text, written for players, not word for word. Keep names (of the game, characters, places) as they are unless the user says otherwise. German and French run longer: check that every label still fits its button and screen, and shrink or wrap where it doesn't.
5. **Fonts and images.** Check the game's font has the letters each language needs (Polish ą ć ę ł ń ó ś ź ż, French é è à ç, German ä ö ü ß, Spanish ñ á ¿ ¡); a bitmap or subset font usually doesn't, so switch to one that does or fall back to a system font for those. Text baked into images gets an image per language, or becomes drawn text.
6. **Title, description and thumbnail stay in English** (`juicy.json` and the tile are shared by everyone).

## Check it
Run the game, switch to each language and go through the menus and the first minute of play: no missing keys (an untranslated key shows up as the key's name), no clipped text, and the choice is still there after a reload.

## Declare it
Set `languages` in `juicy.json` to every language the game now has, English first, e.g. `"languages": ["en", "fr", "pl"]` (or `npx -y juicyjuicy@0.14.0 init --yes --json --languages en,fr,pl`). Don't add it to `features`: JuicyJuicy reads `languages`, and shows the game in each language's filter.
