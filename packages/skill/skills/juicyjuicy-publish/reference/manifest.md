# `juicy.json`

The manifest in the project folder. `juicyjuicy init` writes it; edit it by hand or with `init` flags. Unknown keys are errors (typos fail loudly). JSON Schema: `https://juicyjuicy.games/schema/juicy.json`.

```json
{
  "$schema": "https://juicyjuicy.games/schema/juicy.json",
  "slug": "space-goose",
  "title": "Space Goose",
  "description": "Honk through an asteroid field and grab the stars.",
  "buildDir": "dist",
  "entry": "index.html",
  "engine": "phaser",
  "madeWith": ["Claude Opus 5.5", "Claude Code"],
  "genres": ["arcade", "shooter"],
  "tags": ["space"],
  "ageRating": "everyone",
  "languages": ["en", "pl"],
  "features": ["cloud-saves"],
  "input": ["keyboard", "touch"],
  "orientation": "landscape",
  "aspectRatio": "16:9",
  "thumbnail": "thumbnail.png",
  "remixable": true,
  "sourceUrl": "https://github.com/someone/space-goose"
}
```

| Field | Required | Rules | `init` flag |
|---|---|---|---|
| `slug` | yes | 3–40 chars, lowercase letters, digits, single dashes. The game's URL: `/g/<slug>`. Owned by whoever publishes it first. Don't change it once published: a new slug is a new game (renaming a game means a new `title`). | `--slug` |
| `id` | | Written by `publish` (and `pull`): the game this folder publishes to. Don't edit. A publish whose `slug` names another game is refused with `SLUG_CHANGED`; remove `id` only to publish a copy of the folder as a separate new game. | |
| `title` | yes | Up to 60 characters. | `--title` |
| `description` | | Up to 500 characters. One or two sentences: what you do, how you control it. | `--description` |
| `buildDir` | | Folder that gets uploaded, relative to the project. Default `.`. | `--build-dir` |
| `entry` | | HTML file inside `buildDir`. Default `index.html`. | `--entry` |
| `engine` | | `vanilla`, `phaser`, `threejs`, `pixi`, `godot`, `unity` or `other`. | `--engine` |
| `madeWith` | | Up to 5 models/tools, e.g. `["Claude Opus 5.5", "Claude Code"]`. | `--made-with "a, b"` |
| `genres` | yes | 1 to 3 ids from the genre list in SKILL.md step 3, e.g. `["puzzle"]`, the main one first. `check` and `publish` stop without them, or with an id that isn't on the list. | `--genres a,b` |
| `tags` | | Themes: up to 3 lowercase words or `word-word` for the setting or subject, e.g. `space`, `pirates`, `blackjack`. Not genres or features (touch, remixable: JuicyJuicy shows those by itself), except `multiplayer`, not counted among the 3, for a game players play together without JuicyJuicy's rooms (its own netcode, or one screen). JuicyJuicy cleans them up when saving (spellings fixed, `co-op`, `pvp` and the like saved as `multiplayer`, genre and other feature words moved out, at most 3 themes kept; `check` warns with what it will save). | `--tags a,b` |
| `ageRating` | | Who the game is for: `everyone`, `12+` or `16+`, from its content (SKILL.md step 3 says how to pick). Rate every game you publish. Left out, a publish keeps the game's rating; a rating set by JuicyJuicy's moderators wins over this one, and `publish` writes it here. | `--age-rating` |
| `languages` | | Up to 10 language codes a player can switch between, English first, e.g. `["en", "pl"]`. Default `["en"]`. Shown as a language filter on JuicyJuicy. | `--languages a,b` |
| `features` | yes | The JuicyJuicy upgrades the game has, by id: `auto-pause`, `browser-menu`, `cloud-saves`, `gamepad`, `highscores`, `multiplayer`, `touch`; `[]` for none. Required: `check` and `publish` stop without it, and `init` adds `[]`. Add an id only once the game has the feature (see SKILL.md, "Add a JuicyJuicy upgrade"); `check` warns when one is listed but missing. Multi-language is `languages`, not a feature id; `touch` and `gamepad` go in `input` too. | |
| `input` | | Any of `keyboard`, `mouse`, `touch`, `gamepad`. | `--input a,b` |
| `orientation` | | `landscape`, `portrait` or `any` (default). | `--orientation` |
| `aspectRatio` | | `"W:H"` like `"16:9"` or `"4:3"`, or `"fill"` to fill the player. Default `16:9`. | `--aspect-ratio` |
| `thumbnail` | | png/jpg/webp in the project folder (not the build folder), up to 2 MB and 4096×4096 pixels. Without one, `check` and `publish` screenshot the game in a local Chrome or Edge, offline (`--no-auto-thumbnail` turns that off; a remix only with `--auto-thumbnail`). | `--thumbnail` |
| `howItWasMade` | | No longer used; `check` warns about it and `init` removes it. | |
| `remixable` | | `true` grants the JuicyJuicy remix license: other members may remix the game on JuicyJuicy only (see SKILL.md, "Remix a game"). Default `false`. | `--remixable` |
| `sourceUrl` | | Plain `https://` link to the source, e.g. a GitHub repo (no `?`, `#`, spaces or quotes; at most 300 characters). | `--source-url` |
| `remixedFrom` | | Set by `juicyjuicy remix`; don't edit. | |

Publishing replaces the game's title, description, tags and the rest with what `juicy.json` says, so keep it up to date. (`ageRating` only when it's there, and not over a moderator's rating.)
