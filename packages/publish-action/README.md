# Publish to JuicyJuicy (GitHub Action)

Publishes a browser game to [juicyjuicy.games](https://juicyjuicy.games) on every push. The game
needs a `juicy.json` (make one with `npx juicyjuicy init`). See ARCHITECTURE §13.

1. Make a token at https://juicyjuicy.games/settings/tokens.
2. In your repository: **Settings → Secrets and variables → Actions → New repository secret**,
   name `JUICY_TOKEN`, value the token.
3. Add `.github/workflows/juicyjuicy.yml`:

```yaml
name: Publish to JuicyJuicy
on:
  push:
    branches: [main]
jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - uses: githubvoyage/juicyjuicy/packages/publish-action@v1
        with:
          token: ${{ secrets.JUICY_TOKEN }}
          build-command: npm ci && npm run build # leave out for plain HTML games
          path: . # the folder with juicy.json
```

Each push becomes a new version (`source: github` in the version history), with the short commit
SHA and the commit's first line as its note. Outputs: `game-url`, `play-url`, `version`.

No `thumbnail` in `juicy.json`? The CLI screenshots the built game with the runner's Chrome
(`ubuntu-latest`, `windows-latest` and `macos-latest` ship one) and uses that. On a runner without
Chrome, Edge, Chromium or Brave it publishes anyway, with the title-on-a-gradient tile and a
warning on the job; set `JUICY_BROWSER` in the step's `env` to a browser's path if yours is
somewhere else. To keep a thumbnail you uploaded on the dashboard, commit it as `thumbnail.png`
and set `"thumbnail"` in `juicy.json`: otherwise each push replaces it with a new screenshot.

The Action runs `juicyjuicy@0` from npm (the newest 0.x release). Set `cli-version` to an exact
version such as `0.4.0` to choose when your builds move to a new one; `npm audit signatures` checks
the package's registry signature.

`publish.sh` is the publish step; run it locally with the same environment variables to test it.
