# Bring all my JuicyJuicy games up to date

For "bring my JuicyJuicy games up to date", "fix the required updates", a **Needs update** badge on My games, or a `check` that warns `requirement-missing`. Sometimes JuicyJuicy makes a rule every game must follow (say, `juicy.json` listing its `features`). A game that doesn't follow it, or that JuicyJuicy hasn't checked yet, leaves the public lists after the deadline; its link keeps working.

1. **Check every game at once.** Log in first (SKILL.md step 1), then run:

   ```bash
   npx -y juicyjuicy@0.7.0 check-games --json
   ```

   JuicyJuicy checks the live version of each of the user's games on its side. It records which features each one has and, for a game whose `juicy.json` never listed its `features`, declares what it finds in the files (like cloud saves). Nothing is uploaded and no new version is made. The result has one entry per game in `games` (`features` with `on`/`off`/`unknown`, `requirements` with `passed`), `toFix` (the games that still need a code change, each with its `prompts`), `notReached` and `next`.

2. **If `notReached` isn't empty**, run `check-games` again: it had no time for those games.

3. **For each game in `toFix`**, one at a time:
   - Find its project, or download the live version with `npx -y juicyjuicy@0.7.0 pull <slug> --json` (SKILL.md, "Add a JuicyJuicy upgrade", step 1).
   - Do what each prompt says, with the recipe it names when it names one.
   - Make sure `juicy.json` has `features` (`[]` if the game has none of the upgrades).
   - Check and publish an update as SKILL.md steps 5–7 say, with `--message "Required update: <what>"`.

4. **Tell the user** which games were already fine, which `check-games` settled by itself, which you updated, and any left (with why). A game they don't want to change keeps its link but stays out of the lists after the deadline; an admin can exempt a classic that can't be updated, if the user asks JuicyJuicy.
