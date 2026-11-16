# Publish to JuicyJuicy (GitHub Action)

Publishes a browser game to [juicyjuicy.games](https://juicyjuicy.games) on every push. The game
needs a `juicy.json` (make one with `npx juicyjuicy init`). See ARCHITECTURE §13.

1. Make a token at https://juicyjuicy.games/settings/tokens. Pick **Publish only, for CI**: it
   can publish and list your games and nothing else, so a leaked secret can't do more.
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

Every game needs a cover and 3 to 5 screenshots: commit the ones `juicyjuicy cover` and
`juicyjuicy capture` made and named in `juicy.json`, or upload them on the game's dashboard page.
A push without them in `juicy.json` keeps the dashboard's; one with them replaces them.

The Action runs `juicyjuicy@0` from npm (the newest 0.x release on a fresh runner; a self-hosted runner that keeps its npm cache keeps the 0.x it first ran, so set `cli-version` there). Set `cli-version` to an exact
version such as `0.4.0` to choose when your builds move to a new one; `npm audit signatures` checks
the package's registry signature.

`publish.sh` is the publish step; run it locally with the same environment variables to test it.
