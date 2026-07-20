#!/usr/bin/env bash
set -euo pipefail

# Disposable regression tests for verasic-init. Creates temp repos in mktemp
# dirs, never touches the source tree, cleans up on exit.

# hermetic: ignore credentials inherited from the calling shell
unset GH_TOKEN GH_REPO GITHUB_TOKEN 2>/dev/null || true

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pass=0
fail=0

ok()  { echo "PASS: $1"; pass=$((pass + 1)); }
bad() { echo "FAIL: $1"; fail=$((fail + 1)); }

make_repo() {
  local dir="$1"; shift
  mkdir -p "$dir/.cursor/skills"
  for s in "$@"; do
    cp -r "$SKILLS_SRC/$s" "$dir/.cursor/skills/"
  done
  git -C "$dir" init -q -b main
  git -C "$dir" -c user.email=t@t -c user.name=t commit -q --allow-empty -m "chore: seed"
  git -C "$dir" remote add origin git@github.com:Milkywayrules/usecharator.git
}

INIT_REL=".cursor/skills/verasic-init/scripts/init.sh"

row() { grep -qE "$1 +$2" <<<"$3"; }

# --- full wire on a fresh repo ---
R="$TMP/full"
make_repo "$R" verasic-init verasic-github-env verasic-git-commits verasic-bugbot
out="$(cd "$R" && bash "$INIT_REL")"
row 'verasic-github-env' 'wired' "$out" && ok "github-env wired" || bad "github-env wired"
row 'verasic-git-commits' 'wired' "$out" && ok "git-commits wired" || bad "git-commits wired"
row 'verasic-bugbot' 'ready' "$out" && ok "bugbot ready" || bad "bugbot ready"
[[ -f "$R/.envrc" ]] && ok ".envrc created" || bad ".envrc created"
hooks_path="$(git -C "$R" config core.hooksPath || true)"
[[ "$hooks_path" == ".cursor/skills/verasic-git-commits/hooks" ]] && ok "hooksPath set" || bad "hooksPath set ($hooks_path)"

# hook actually strips a trailer end-to-end
( cd "$R" && echo x > f.txt && git add f.txt && \
  git -c user.email=t@t -c user.name=t commit -q -m $'test: probe hook\n\nCo-authored-by: Bot <b@b.co>' )
if git -C "$R" log -1 --format=%B | grep -qiE '^co-authored-by:'; then
  bad "hook strips trailer"
else
  ok "hook strips trailer"
fi

# --- idempotency ---
out2="$(cd "$R" && bash "$INIT_REL")"
grep -q '0 failed' <<<"$out2" && ok "re-run clean" || bad "re-run clean"
row 'verasic-git-commits' 'wired' "$out2" && ok "re-run hook already wired" || bad "re-run hook already wired"

# --- cherry-pick ---
out3="$(cd "$R" && bash "$INIT_REL" --skills verasic-bugbot)"
row 'verasic-github-env' 'not selected' "$out3" && ok "cherry-pick skips github-env" || bad "cherry-pick skips github-env"
row 'verasic-bugbot' 'ready' "$out3" && ok "cherry-pick keeps bugbot" || bad "cherry-pick keeps bugbot"

# --- cherry-pick tolerates whitespace in --skills ---
out3b="$(cd "$R" && bash "$INIT_REL" --skills ' verasic-bugbot , verasic-git-commits ')"
row 'verasic-bugbot' 'ready' "$out3b" && ok "whitespace --skills selects" || bad "whitespace --skills selects"
grep -q '0 unknown' <<<"$out3b" && ok "whitespace --skills no ghost rows" || bad "whitespace --skills no ghost rows"

# --- empty --skills rejected ---
rc=0
(cd "$R" && bash "$INIT_REL" --skills= >/dev/null 2>&1) || rc=$?
[[ "$rc" -eq 2 ]] && ok "empty --skills rejected" || bad "empty --skills rejected (rc=$rc)"

# --- unknown skill name ---
out4="$(cd "$R" && bash "$INIT_REL" --skills nope)"
row 'nope' 'unknown' "$out4" && ok "unknown skill reported" || bad "unknown skill reported"
grep -q '1 unknown' <<<"$out4" && ok "unknown counted in tally" || bad "unknown counted in tally"

# --- tokened origin URL never printed ---
R1b="$TMP/tokened"
make_repo "$R1b" verasic-init verasic-bugbot
git -C "$R1b" remote set-url origin https://x-access-token:ghp_FAKESECRET@github.com/acme/w.git
outT="$(cd "$R1b" && bash "$INIT_REL")"
grep -q 'ghp_FAKESECRET' <<<"$outT" && bad "origin credentials stripped" || ok "origin credentials stripped"
grep -q 'https://github.com/acme/w.git' <<<"$outT" && ok "origin still shown" || bad "origin still shown"

# --- partial install (github-env missing) ---
R2="$TMP/partial"
make_repo "$R2" verasic-init verasic-bugbot
out5="$(cd "$R2" && bash "$INIT_REL")"
row 'verasic-github-env' 'not installed' "$out5" && ok "missing skill reported" || bad "missing skill reported"

# --- installed skill with missing wire script → FAILED, exit 1 ---
R2b="$TMP/broken"
make_repo "$R2b" verasic-init verasic-github-env
rm "$R2b/.cursor/skills/verasic-github-env/scripts/bootstrap.sh"
rc=0
out5b="$(cd "$R2b" && bash "$INIT_REL" 2>/dev/null)" || rc=$?
[[ "$rc" -eq 1 ]] && ok "broken install exits 1" || bad "broken install exits 1 (rc=$rc)"
row 'verasic-github-env' 'FAILED' "$out5b" && ok "broken install FAILED row" || bad "broken install FAILED row"

# --- manifest without trailing newline keeps its last entry ---
R2c="$TMP/notrail"
make_repo "$R2c" verasic-init verasic-bugbot
printf '%s' 'verasic-bugbot|-|local review' > "$R2c/.cursor/skills/verasic-init/manifest.txt"
out5c="$(cd "$R2c" && bash "$INIT_REL")"
row 'verasic-bugbot' 'ready' "$out5c" && ok "manifest last line without newline kept" || bad "manifest last line without newline kept"

# --- lefthook repo → action needed, exit 0 ---
R3="$TMP/lefthook"
make_repo "$R3" verasic-init verasic-git-commits
printf 'pre-commit:\n  commands:\n    lint:\n      run: true\n' > "$R3/lefthook.yml"
rc=0
out6="$(cd "$R3" && bash "$INIT_REL")" || rc=$?
[[ "$rc" -eq 0 ]] && ok "lefthook run exits 0" || bad "lefthook run exits 0 (rc=$rc)"
row 'verasic-git-commits' 'action needed' "$out6" && ok "lefthook action needed" || bad "lefthook action needed"
grep -q 'lefthook detected' <<<"$out6" && ok "lefthook snippet shown" || bad "lefthook snippet shown"
[[ -z "$(git -C "$R3" config core.hooksPath || true)" ]] && ok "lefthook hooksPath untouched" || bad "lefthook hooksPath untouched"

# --- pre-existing global hooksPath is respected, not overridden ---
R3b="$TMP/globalhooks"
make_repo "$R3b" verasic-init verasic-git-commits
mkdir -p "$TMP/managed-hooks" "$TMP/fakehome"
rc=0
out6b="$(cd "$R3b" && HOME="$TMP/fakehome" git config --global core.hooksPath "$TMP/managed-hooks" && \
         HOME="$TMP/fakehome" bash "$INIT_REL")" || rc=$?
[[ "$rc" -eq 0 ]] && ok "global hooksPath run exits 0" || bad "global hooksPath run exits 0 (rc=$rc)"
row 'verasic-git-commits' 'action needed' "$out6b" && ok "global hooksPath action needed" || bad "global hooksPath action needed"
[[ -z "$(git -C "$R3b" config --local core.hooksPath || true)" ]] && ok "global hooksPath not overridden locally" || bad "global hooksPath not overridden locally"

# --- list mode changes nothing ---
R4="$TMP/list"
make_repo "$R4" verasic-init verasic-github-env
out7="$(cd "$R4" && bash "$INIT_REL" --list)"
grep -q 'no changes made' <<<"$out7" && ok "list banner" || bad "list banner"
row 'verasic-github-env' 'installed' "$out7" && ok "list shows installed" || bad "list shows installed"
grep -q 'wired' <<<"$out7" && bad "list tally has no wired" || ok "list tally has no wired"
[[ ! -f "$R4/.envrc" ]] && ok "list changes nothing" || bad "list changes nothing"

# --- not a git repo ---
R5="$TMP/nogit"
mkdir -p "$R5/.cursor/skills"
cp -r "$SKILLS_SRC/verasic-init" "$R5/.cursor/skills/"
rc=0
(cd "$R5" && bash "$INIT_REL" >/dev/null 2>&1) || rc=$?
[[ "$rc" -eq 1 ]] && ok "non-git repo rejected" || bad "non-git repo rejected (rc=$rc)"

echo "---"
echo "regression: $pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
