#!/usr/bin/env bash
set -euo pipefail

REPO="https://github.com/Milkywayrules/verasic-skills"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

git clone --quiet --depth 1 "$REPO" "$TMP"

mkdir -p .cursor/agents .cursor/rules .cursor/skills
cp -r "$TMP/cursor/agents/." .cursor/agents/
cp -r "$TMP/cursor/rules/."    .cursor/rules/
cp -r "$TMP/skills/."          .cursor/skills/

echo "✅ verasic skills installed into .cursor/ — try /verasic-bugbot, /verasic-secbot, /verasic-fusion, /verasic-deep-research, /verasic-git-commits-audit, /verasic-agent-disclosure, /verasic-github-cli-init, or /verasic-github-governance-init"
echo "➡️  next: run /verasic-init — it shows a plan first; confirm, then apply with --yes"
