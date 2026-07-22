#!/usr/bin/env bash
set -euo pipefail

# Regression for scripts/check-versions.sh — temp drift only, never mutates source tree.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHECK="$REPO_ROOT/scripts/check-versions.sh"
REFRESH="$REPO_ROOT/scripts/refresh-integrity.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pass=0
fail=0

ok()  { echo "PASS: $1"; pass=$((pass + 1)); }
bad() { echo "FAIL: $1"; fail=$((fail + 1)); }

if bash "$CHECK" >/dev/null 2>&1; then
  ok 'check-versions passes on source tree'
else
  bad 'check-versions passes on source tree'
fi

# drift: lock mismatch against VERSION
DRIFT="$TMP/drift"
mkdir -p "$DRIFT/scripts" "$DRIFT/skills"
cp "$CHECK" "$REFRESH" "$DRIFT/scripts/"
cp -r "$REPO_ROOT/skills/." "$DRIFT/skills/"
cp "$REPO_ROOT/versions.lock" "$DRIFT/versions.lock"
printf '9.9.9\n' > "$DRIFT/skills/verasic-deep-research/VERSION"

if VERASIC_REPO_ROOT="$DRIFT" bash "$DRIFT/scripts/check-versions.sh" >/dev/null 2>&1; then
  bad 'check-versions fails on lock drift'
else
  ok 'check-versions fails on lock drift'
fi

# refresh-integrity updates hash after VERSION bump
REF_TMP="$TMP/refresh"
mkdir -p "$REF_TMP/scripts" "$REF_TMP/skills"
cp "$REFRESH" "$REF_TMP/scripts/"
cp -r "$REPO_ROOT/skills/verasic-bugbot" "$REF_TMP/skills/"
OLD_HASH="$(cat "$REF_TMP/skills/verasic-bugbot/integrity.sha256")"
printf '0.1.99\n' > "$REF_TMP/skills/verasic-bugbot/VERSION"
VERASIC_REPO_ROOT="$REF_TMP" bash "$REF_TMP/scripts/refresh-integrity.sh" verasic-bugbot >/dev/null
NEW_HASH="$(cat "$REF_TMP/skills/verasic-bugbot/integrity.sha256")"
if [[ "$OLD_HASH" != "$NEW_HASH" ]]; then
  ok 'refresh-integrity changes hash when VERSION bumps'
else
  bad 'refresh-integrity changes hash when VERSION bumps'
fi

echo "---"
echo "test-versions-regression: $pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
