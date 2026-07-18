#!/usr/bin/env bash
set -euo pipefail

REPO="https://github.com/Milkywayrules/verasic-skills"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

git clone --quiet --depth 1 "$REPO" "$TMP"

mkdir -p .cursor/agents .cursor/commands .cursor/rules .cursor/skills
cp -r "$TMP/cursor/agents/."   .cursor/agents/
cp -r "$TMP/cursor/commands/." .cursor/commands/
cp -r "$TMP/cursor/rules/."    .cursor/rules/
cp -r "$TMP/skills/."          .cursor/skills/

echo "✅ verasic skills installed into .cursor/ — try /verasic-review or /verasic-audit-commits"
echo "ℹ️  optional: wire the deterministic commit-msg hook (lefthook or core.hooksPath) — see .cursor/skills/verasic-git-commits/README.md"
