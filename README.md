# JuicyJuicy

Tools for publishing AI-made browser games to [juicyjuicy.games](https://juicyjuicy.games): an agent skill (also a Claude Code plugin) and a GitHub Action. How to publish, start to finish: [juicyjuicy.games/docs/publish](https://juicyjuicy.games/docs/publish).

## Agent skill

`juicyjuicy-publish` teaches an AI coding agent (Claude Code, Codex, GitHub Copilot, Cursor, Gemini CLI, Antigravity, …) to build, check and publish a game. The easiest install, for any agent:

```bash
npx juicyjuicy setup
```

In Claude Code you can install it as a plugin instead, which keeps it updated:

```
/plugin marketplace add githubvoyage/juicyjuicy
/plugin install juicyjuicy@juicyjuicy
```

The skill is in [`packages/skill`](packages/skill).

## GitHub Action

Publishes a game on every push. Setup and inputs: [`packages/publish-action`](packages/publish-action).

```yaml
- uses: githubvoyage/juicyjuicy/packages/publish-action@v1
  with:
    token: ${{ secrets.JUICY_TOKEN }}
```

## CLI

The skill and the Action run the [`juicyjuicy`](https://www.npmjs.com/package/juicyjuicy) CLI from npm.

## About this repository

JuicyJuicy is developed in a private repository, and this one is a published copy of its creator-facing parts, updated with each release. Issues are welcome here; pull requests can't be merged directly, but a good one will be carried over.

Found a security problem? See [SECURITY.md](SECURITY.md).
