#!/usr/bin/env bash
# The action's publish step (action.yml): runs `juicyjuicy publish` in the current folder and turns
# its JSON result into step outputs, a job summary, warning annotations and, on failure, an error
# annotation.
# Reads JUICY_TOKEN, JUICY_API_URL, JUICY_MESSAGE, JUICY_CLI_VERSION, COMMIT_MESSAGE, GITHUB_SHA,
# GITHUB_OUTPUT, GITHUB_STEP_SUMMARY and RUNNER_TEMP, like a GitHub runner sets them.
set -uo pipefail

if [ -z "${JUICY_TOKEN:-}" ]; then
  echo "::error title=JuicyJuicy::The token input is empty. Add a JuicyJuicy token as a repository secret and pass it as token."
  exit 2
fi

message="${JUICY_MESSAGE:-}"
if [ -z "$message" ]; then
  commit="${COMMIT_MESSAGE:-}"
  first_line="${commit%%$'\n'*}"
  sha="${GITHUB_SHA:-}"
  message="${sha:0:7}${first_line:+: $first_line}"
fi
message="${message:0:200}"

log="${RUNNER_TEMP:-/tmp}/juicyjuicy-publish.jsonl"
# GITHUB_ACTIONS=true makes the CLI mark the version as published from GitHub.
npx -y "juicyjuicy@${JUICY_CLI_VERSION:-0}" publish --yes --json --message "$message" | tee "$log"
status=${PIPESTATUS[0]}
result=$(tail -n 1 "$log")

LOG="$log" RESULT="$result" STATUS="$status" node <<'NODE'
const fs = require("node:fs");
const append = (file, text) => file && fs.appendFileSync(file, text);
// Warnings (e.g. no browser for the auto-thumbnail, so the tile is a gradient) as annotations.
for (const line of fs.readFileSync(process.env.LOG, "utf8").split("\n")) {
  try {
    const event = JSON.parse(line);
    if (event.event === "warning") {
      console.log(`::warning title=JuicyJuicy::${String(event.message).replace(/\r?\n/g, " ")}`);
    }
  } catch {}
}
let result;
try {
  result = JSON.parse(process.env.RESULT || "");
} catch {
  result = { ok: false, error: { message: "juicyjuicy printed no result" } };
}
if (result.ok) {
  append(
    process.env.GITHUB_OUTPUT,
    `game-url=${result.gameUrl}\nplay-url=${result.playUrl}\nversion=${result.version}\n`,
  );
  append(
    process.env.GITHUB_STEP_SUMMARY,
    `### 🧃 ${result.slug} v${result.version} is live\n\n${result.gameUrl}\n`,
  );
} else {
  const { code, message, hint } = result.error || {};
  const text = [message, hint].filter(Boolean).join(" ").replace(/\r?\n/g, " ");
  console.log(`::error title=JuicyJuicy${code ? ` ${code}` : ""}::${text || `exit ${process.env.STATUS}`}`);
}
NODE
exit "$status"
