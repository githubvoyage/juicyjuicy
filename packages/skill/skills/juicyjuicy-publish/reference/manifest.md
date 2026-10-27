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
  "tags": ["arcade", "space"],
  "input": ["keyboard", "touch"],
  "orientation": "landscape",
  "aspectRatio": "16:9",
  "thumbnail": "thumbnail.png",
  "howItWasMade": "HOW_I_MADE_IT.md",
  "remixable": true,
  "sourceUrl": "https://github.com/someone/space-goose"
}
```

| Field | Required | Rules | `init` flag |
|---|---|---|---|
| `slug` | yes | 3–40 chars, lowercase letters, digits, single dashes. The game's URL: `/g/<slug>`. Owned by whoever publishes it first. | `--slug` |
| `title` | yes | Up to 60 characters. | `--title` |
| `description` | | Up to 500 characters. One or two sentences: what you do, how you control it. | `--description` |
| `buildDir` | | Folder that gets uploaded, relative to the project. Default `.`. | `--build-dir` |
| `entry` | | HTML file inside `buildDir`. Default `index.html`. | `--entry` |
| `engine` | | `vanilla`, `phaser`, `threejs`, `pixi`, `godot`, `unity` or `other`. | `--engine` |
| `madeWith` | | Up to 5 models/tools, e.g. `["Claude Opus 5.5", "Claude Code"]`. | `--made-with "a, b"` |
| `tags` | | Up to 5 lowercase words or `word-word`, e.g. `puzzle`, `tower-defense`. | `--tags a,b` |
| `input` | | Any of `keyboard`, `mouse`, `touch`, `gamepad`. | `--input a,b` |
| `orientation` | | `landscape`, `portrait` or `any` (default). | `--orientation` |
| `aspectRatio` | | `"W:H"` like `"16:9"` or `"4:3"`, or `"fill"` to fill the player. Default `16:9`. | `--aspect-ratio` |
| `thumbnail` | | png/jpg/webp in the project folder (not the build folder), up to 2 MB and 4096×4096 pixels. Without one, `check` and `publish` screenshot the game in a local Chrome or Edge (`--no-auto-thumbnail` turns that off). | `--thumbnail` |
| `howItWasMade` | | A `.md` file in the project folder, up to 20 KB, shown on the game page. | (detected: `HOW_I_MADE_IT.md`) |
| `remixable` | | `true` grants the JuicyJuicy remix license: other members may remix the game on JuicyJuicy only (see SKILL.md, "Remix a game"). Default `false`. | `--remixable` |
| `sourceUrl` | | Plain `https://` link to the source, e.g. a GitHub repo (no `?`, `#`, spaces or quotes; at most 300 characters). | `--source-url` |
| `remixedFrom` | | Set by `juicyjuicy remix`; don't edit. | |

Publishing replaces the game's title, description, tags and the rest with what `juicy.json` says, so keep it up to date.
