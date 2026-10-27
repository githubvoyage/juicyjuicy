# JuicyJuicy skill

The `juicyjuicy-publish` skill teaches an AI coding agent (Claude Code, Codex, GitHub Copilot, Cursor, Gemini CLI, Antigravity, …) to publish a browser game to [juicyjuicy.games](https://juicyjuicy.games) with the `juicyjuicy` CLI (ARCHITECTURE §12). It's a plain [Agent Skills](https://agentskills.io) folder, and this package is also a Claude Code plugin.

```
.claude-plugin/plugin.json                     plugin manifest (listed in /.claude-plugin/marketplace.json)
skills/juicyjuicy-publish/SKILL.md             when to use it + the publish procedure
skills/juicyjuicy-publish/reference/*.md       manifest fields, engine builds, error codes
```

Install it either way:

- `npx juicyjuicy skill install` (or `setup`) copies the skill to `~/.agents/skills`, the shared folder most agents read, plus the own folders of agents that don't (Claude Code, Antigravity CLI) when they're on the machine. The CLI ships a copy, built from this folder.
- In Claude Code: `/plugin marketplace add githubvoyage/juicyjuicy`, then `/plugin install juicyjuicy@juicyjuicy`.

Chat apps without a shell (claude.ai, ChatGPT, Gemini) can load the zipped `skills/juicyjuicy-publish` folder, but can't publish: that needs `npx`.

Keep `reference/troubleshooting.md` in sync with the error codes in `packages/shared/src/errors.ts`.
