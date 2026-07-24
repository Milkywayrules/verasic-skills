#!/usr/bin/env bash
set -euo pipefail

SKILL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pass=0
fail=0

assert() {
  local name="$1" path="$2"
  if [[ -f "$SKILL_ROOT/$path" ]]; then
    echo "PASS: $name"
    pass=$((pass + 1))
  else
    echo "FAIL: $name (missing $path)"
    fail=$((fail + 1))
  fi
}

assert_exec() {
  local name="$1" path="$2"
  if [[ -x "$SKILL_ROOT/$path" ]]; then
    echo "PASS: $name"
    pass=$((pass + 1))
  else
    echo "FAIL: $name (not executable: $path)"
    fail=$((fail + 1))
  fi
}

# --- integrity manifest files exist ---
while IFS= read -r line || [[ -n "$line" ]]; do
  stripped="${line%%#*}"
  stripped="${stripped//[[:space:]]/}"
  [[ -z "$stripped" ]] && continue
  assert "integrity: $stripped" "$stripped"
done < "$SKILL_ROOT/integrity.txt"

assert "VERSION readable" "VERSION"
assert_exec "scaffold-artifacts.sh executable" "scripts/scaffold-artifacts.sh"
assert_exec "resolve-config.sh executable" "scripts/resolve-config.sh"

# --- resolve-config defaults ---
defaults_out="$(bash "$SKILL_ROOT/scripts/resolve-config.sh")"
echo "$defaults_out" | python3 -c "
import json, sys
d = json.load(sys.stdin)
assert d['artifacts']['trackedDir'] == 'verasic'
assert d['artifacts']['localDir'] == '.verasic'
assert d['artifacts']['indexLocal'] is False
assert d['securityReview']['scanner'] == 'off'
assert d['securityReview']['strictness'] == 'strict'
assert d['securityReview']['report']['write'] is True
assert d['securityReview']['report']['promote'] == 'both'
" && { echo "PASS: resolve-config defaults"; pass=$((pass + 1)); } \
  || { echo "FAIL: resolve-config defaults"; fail=$((fail + 1)); }

# --- resolve-config merge ---
mkdir -p "$TMP/repo"
cd "$TMP/repo"
git init -q -b main
printf '%s\n' '{"artifacts":{"localDir":"custom-local"},"securityReview":{"scanner":"opengrep"}}' > .verasicrc.json
merged="$(VERASIC_REPO_ROOT="$TMP/repo" bash "$SKILL_ROOT/scripts/resolve-config.sh")"
echo "$merged" | python3 -c "
import json, sys
d = json.load(sys.stdin)
assert d['artifacts']['localDir'] == 'custom-local'
assert d['artifacts']['trackedDir'] == 'verasic'
assert d['securityReview']['scanner'] == 'opengrep'
assert d['securityReview']['report']['promote'] == 'both'
" && { echo "PASS: resolve-config merge"; pass=$((pass + 1)); } \
  || { echo "FAIL: resolve-config merge"; fail=$((fail + 1)); }

# --- scaffold idempotent ---
mkdir -p "$TMP/scaffold/.cursor/skills"
cp -r "$SKILL_ROOT" "$TMP/scaffold/.cursor/skills/verasic-config"
cd "$TMP/scaffold"
git init -q -b main
git -c user.email=t@t -c user.name=t commit -q --allow-empty -m "chore: seed"
bash .cursor/skills/verasic-config/scripts/scaffold-artifacts.sh >/dev/null
[[ -f verasic.config.ts && -f verasic/.gitkeep && -f verasic/security-reviews/.gitkeep ]] \
  && { echo "PASS: scaffold creates dirs and config"; pass=$((pass + 1)); } \
  || { echo "FAIL: scaffold creates dirs and config"; fail=$((fail + 1)); }
[[ -f .verasic/security-reviews/.gitkeep ]] \
  && { echo "PASS: scaffold creates local security-reviews"; pass=$((pass + 1)); } \
  || { echo "FAIL: scaffold creates local security-reviews"; fail=$((fail + 1)); }
grep -q '.verasic/' .gitignore \
  && { echo "PASS: scaffold gitignores .verasic/"; pass=$((pass + 1)); } \
  || { echo "FAIL: scaffold gitignores .verasic/"; fail=$((fail + 1)); }
grep -q '.verasic/' .cursorignore \
  && { echo "PASS: scaffold cursorignores .verasic/ by default"; pass=$((pass + 1)); } \
  || { echo "FAIL: scaffold cursorignores .verasic/ by default"; fail=$((fail + 1)); }

bash .cursor/skills/verasic-config/scripts/scaffold-artifacts.sh >/dev/null
ignore_count="$(grep -c '^\.verasic/$' .gitignore || true)"
[[ "$ignore_count" -le 1 && -f verasic.config.ts ]] \
  && { echo "PASS: scaffold idempotent"; pass=$((pass + 1)); } \
  || { echo "FAIL: scaffold idempotent (ignore_count=$ignore_count)"; fail=$((fail + 1)); }

# scaffold skips config when .verasicrc.json exists
mkdir -p "$TMP/rc-only/.cursor/skills"
cp -r "$SKILL_ROOT" "$TMP/rc-only/.cursor/skills/verasic-config"
cd "$TMP/rc-only"
git init -q -b main
printf '{}\n' > .verasicrc.json
bash .cursor/skills/verasic-config/scripts/scaffold-artifacts.sh >/dev/null
[[ ! -f verasic.config.ts ]] \
  && { echo "PASS: scaffold skips config when .verasicrc.json exists"; pass=$((pass + 1)); } \
  || { echo "FAIL: scaffold should not create verasic.config.ts"; fail=$((fail + 1)); }

# VERASIC_INDEX_LOCAL=false adds .cursorignore
mkdir -p "$TMP/cursorignore/.cursor/skills"
cp -r "$SKILL_ROOT" "$TMP/cursorignore/.cursor/skills/verasic-config"
cd "$TMP/cursorignore"
git init -q -b main
VERASIC_INDEX_LOCAL=false bash .cursor/skills/verasic-config/scripts/scaffold-artifacts.sh >/dev/null
grep -q '.verasic/' .cursorignore \
  && { echo "PASS: scaffold cursorignore on VERASIC_INDEX_LOCAL=false"; pass=$((pass + 1)); } \
  || { echo "FAIL: scaffold cursorignore"; fail=$((fail + 1)); }

# indexLocal false from .verasicrc.json adds .cursorignore without env var
mkdir -p "$TMP/index-local/.cursor/skills"
cp -r "$SKILL_ROOT" "$TMP/index-local/.cursor/skills/verasic-config"
cd "$TMP/index-local"
git init -q -b main
printf '%s\n' '{"artifacts":{"indexLocal":false}}' > .verasicrc.json
bash .cursor/skills/verasic-config/scripts/scaffold-artifacts.sh >/dev/null
grep -q '.verasic/' .cursorignore \
  && { echo "PASS: scaffold cursorignore on indexLocal false"; pass=$((pass + 1)); } \
  || { echo "FAIL: scaffold cursorignore on indexLocal false"; fail=$((fail + 1)); }

# resolve-config reads verasic.config.ts
mkdir -p "$TMP/ts-config"
cd "$TMP/ts-config"
cp "$SKILL_ROOT/templates/verasic.config.ts.example" verasic.config.ts
ts_out="$(VERASIC_REPO_ROOT="$TMP/ts-config" bash "$SKILL_ROOT/scripts/resolve-config.sh")"
echo "$ts_out" | python3 -c "
import json, sys
d = json.load(sys.stdin)
assert d['artifacts']['trackedDir'] == 'verasic'
assert d['securityReview']['scanner'] == 'off'
" && { echo "PASS: resolve-config reads verasic.config.ts"; pass=$((pass + 1)); } \
  || { echo "FAIL: resolve-config reads verasic.config.ts"; fail=$((fail + 1)); }

# resolve-config reads .verasicrc.jsonc
mkdir -p "$TMP/jsonc-config"
cd "$TMP/jsonc-config"
printf '%s\n' $'{\n  // comment\n  "securityReview": { "scanner": "auto" }\n}\n' > .verasicrc.jsonc
jsonc_out="$(VERASIC_REPO_ROOT="$TMP/jsonc-config" bash "$SKILL_ROOT/scripts/resolve-config.sh")"
echo "$jsonc_out" | python3 -c "
import json, sys
d = json.load(sys.stdin)
assert d['securityReview']['scanner'] == 'auto'
" && { echo "PASS: resolve-config reads .verasicrc.jsonc"; pass=$((pass + 1)); } \
  || { echo "FAIL: resolve-config reads .verasicrc.jsonc"; fail=$((fail + 1)); }

hash_tmp="$(mktemp)"
while IFS= read -r line || [[ -n "$line" ]]; do
  stripped="${line%%#*}"
  stripped="${stripped//[[:space:]]/}"
  [[ -z "$stripped" ]] && continue
  [[ "$stripped" == "integrity.sha256" ]] && continue
  (cd "$SKILL_ROOT" && sha256sum "$stripped") >> "$hash_tmp"
done < "$SKILL_ROOT/integrity.txt"
if cmp -s "$hash_tmp" "$SKILL_ROOT/integrity.sha256"; then
  echo "PASS: integrity.sha256 matches integrity.txt entries"
  pass=$((pass + 1))
else
  echo "FAIL: integrity.sha256 matches integrity.txt entries"
  fail=$((fail + 1))
fi
rm -f "$hash_tmp"

echo "---"
echo "regression: $pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
