#!/usr/bin/env bash
set -euo pipefail

REPO="https://github.com/Milkywayrules/verasic-skills"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

git clone --quiet --depth 1 "$REPO" "$TMP"

mkdir -p .cursor/agents .cursor/commands .cursor/skills
cp -r "$TMP/cursor/agents/."           .cursor/agents/
cp -r "$TMP/cursor/commands/."         .cursor/commands/
cp -r "$TMP/skills/verasic-bugbot"     .cursor/skills/

echo "✅ verasic-bugbot installed into .cursor/ — try /verasic-review"
