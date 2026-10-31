# CLI errors and fixes

With `--json`, a failed command's last line is `{"ok": false, "error": {"code", "message", "details"?, "hint"?}}`. `details` is usually a list of `{path, message}`, one per problem. The exit code tells the class of error.

## Exit 2: log in

| Code | Meaning | Fix |
|---|---|---|
| `UNAUTHORIZED` | No saved login, or the token was revoked. | `npx -y juicyjuicy@0 login --json` (the user approves in the browser). In CI, set `JUICY_TOKEN`. |
| `EXPIRED_TOKEN` | The login code expired (10 minutes) or was used. | Run `login` again. |
| `ACCESS_DENIED` | The user clicked Deny. | Ask them, then run `login` again. |

## Exit 1: fix the game or `juicy.json`

| Code | Meaning | Fix |
|---|---|---|
| `INVALID_MANIFEST` | `juicy.json` is missing, isn't JSON, or a field breaks a rule (`details` says which). | No file: run `init`. Otherwise fix the listed fields (see manifest.md). |
| `ENTRY_MISSING` | The build folder doesn't exist, or has no entry file. | Run the build. Check `buildDir` and `entry`. |
| `INVALID_PATH` | A file name is unsafe (backslash, control character, too long, …). | Rename the file (POSIX names, under 256 characters). |
| `TOO_LARGE` | A file is over 100 MB, the whole build over 150 MB, or the thumbnail over 2 MB or 4096 pixels wide or high. Or the user's games together take up more than their 2 GB of storage (the message says "your games already take up"). | Compress or remove assets; resize the thumbnail. For storage: the user deletes a game they don't need on the site; only the newest 5 versions of each game are kept, and old ones are cleaned up daily. |
| `TOO_MANY_FILES` | More than 3,000 files. | Bundle or pack assets (sprite sheets, atlases). |
| `VALIDATION_FAILED` | Something else is malformed, e.g. a thumbnail that isn't png/jpg/webp or a file that's missing. | Follow the message. |
| `SLUG_TAKEN` | Another creator owns this slug. | Choose a new slug: `init --slug <new-slug>`. |
| `GAME_LIMIT_REACHED` | The user has 25 games already. | They delete one on the site, or update an existing game instead. |
| `FORBIDDEN` | The game was removed by an admin, or isn't theirs. | Publish under a new slug; ask an admin if unsure. |
| `UPLOAD_INCOMPLETE` | Files changed or went missing during the upload, or an upload link expired. With `remix`: a downloaded file didn't match its published SHA-256. | Wait for builds to finish and publish again; for `remix`, run it again into a new folder. |
| `NOT_REMIXABLE` | `remix` on a game whose creator hasn't allowed remixes. | Tell the user; there's no way around it. |
| `UNSAFE_CONTENT` | A game check found something that can't be published: an API key or token (`secret-key`), a program or installer (`executable`) crypto-mining code (`crypto-miner`), or a threaded Godot export (`godot-threads`). Each item in `details` has its `rule` and `path`. The server runs the same checks, so there's no way around them. | Explain each one. A key: remove it from the game and tell the user to revoke it, since anyone could have copied it; move the call behind their own server if the game needs it. An executable: remove it. A threaded Godot export: export again with Thread Support off in the Web preset. Then `check` again. |

## Exit 3: network or server

| Code | Meaning | Fix |
|---|---|---|
| `NETWORK_ERROR` | The server or storage couldn't be reached. | Retry. If the hint mentions certificates (a company network or antivirus that inspects HTTPS), run with `NODE_OPTIONS=--use-system-ca` (Node 22.15+). |
| `NETWORK_BLOCKED` | Something that isn't JuicyJuicy refused the request: a sandbox's domain allowlist (Claude Cowork, claude.ai and other chat apps), a proxy or a firewall. It answered 403 without JuicyJuicy's error, or the host had no DNS or refused the connection. `details.host` is the blocked host, `details.allow` the hosts to allow. | Don't retry. Tell the user to allow `juicyjuicy.games` and `*.r2.cloudflarestorage.com` (the upload storage) in the app's network or domain settings, and to make a token at https://juicyjuicy.games/settings/tokens, since a login saved in a sandbox may not last. Run again with `JUICY_TOKEN=<token>`. Outside a sandbox: their network or a proxy blocks it. |
| `PUBLISHING_PAUSED` | JuicyJuicy's admins paused publishing for a while (maintenance or an incident). Games already published keep playing. | Tell the user and try again later; don't retry in a loop. |
| `RATE_LIMITED` | Too many requests (e.g. more than 30 publishes in an hour). | Wait for `details.retryAfterSeconds` (the message says how long), then retry. Don't loop. |
| `INTERNAL_ERROR` | A bug on JuicyJuicy's side. | Retry once; if it persists, tell the user it's a server problem. |

## Things that publish fine but look wrong

- **Blank page or 404s for scripts:** a bundler project published from its root instead of `dist/`, or a Vite `base` other than `/` or `./`.
- **Assets load locally but not online:** file names differ only in letter case (`Player.png` vs `player.png`); the server is case-sensitive.
- **Godot shows "SharedArrayBuffer" errors:** re-export with thread support off.
- **The tile has no picture:** without a `thumbnail` in `juicy.json` the CLI screenshots the game, which needs Chrome, Edge, Chromium or Brave installed (or `JUICY_BROWSER` set to one); the warning says why it couldn't. A remix isn't screenshotted without `--auto-thumbnail` (it runs the other creator's code), and the screenshot runs offline, so a game that loads its engine from a CDN comes out blank. Add `thumbnail.png` and set `"thumbnail"` in `juicy.json`, then publish again.
- **The tile shows a loading or "click to start" screen:** that's the automatic screenshot. Save a gameplay screenshot as `thumbnail.png` and set `"thumbnail"` in `juicy.json`. Or upload one on the game's dashboard page: later publishes keep it, and only a `thumbnail` in `juicy.json` replaces it.
