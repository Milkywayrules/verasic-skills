#!/usr/bin/env bash
set -euo pipefail

# Local + release router — runs every automated gate in manifest order.
# CI tag releases call this; per-skill workflows stay path-filtered for fast PR feedback.

REPO_ROOT="${VERASIC_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
MANIFEST="$REPO_ROOT/skills/verasic-init/manifest.txt"

manifest_skills() {
  local line name
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"
    line="${line//$'\r'/}"
    [[ -z "${line//[[:space:]]/}" ]] && continue
    name="${line%%|*}"
    name="${name//[[:space:]]/}"
    printf '%s\n' "$name"
  done < "$MANIFEST"
}

run_if() {
  local label="$1" script="$2"
  if [[ -f "$script" ]]; then
    echo "== $label =="
    bash "$script"
  else
    echo "== $label (skip — no script) =="
  fi
}

echo "== verasic-skills test-all =="
echo "repo: $REPO_ROOT"
echo

run_if 'version manifest gate' "$REPO_ROOT/scripts/check-versions.sh"
run_if 'version regression' "$REPO_ROOT/scripts/test-versions-regression.sh"
run_if 'internal reference check' "$REPO_ROOT/scripts/check-references.sh"

while IFS= read -r skill; do
  run_if "$skill regression" "$REPO_ROOT/skills/$skill/scripts/test-regression.sh"
done < <(manifest_skills)

run_if 'verasic-fusion protocol exhaustive' "$REPO_ROOT/skills/verasic-fusion/scripts/test-exhaustive-protocol.sh"
run_if 'verasic-deep-research protocol exhaustive' "$REPO_ROOT/skills/verasic-deep-research/scripts/test-exhaustive-protocol.sh"

echo
echo "== test-all: PASS =="
