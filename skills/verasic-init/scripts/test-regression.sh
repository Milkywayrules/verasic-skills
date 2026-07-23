#!/usr/bin/env bash
set -euo pipefail

# Disposable regression tests for verasic-init. Creates temp repos in mktemp
# dirs, never touches the source tree, cleans up on exit.

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
  local roots=("$@")
  local s root
  mkdir -p "$dir/.cursor/skills" "$dir/.agents/skills"
  for s in "${roots[@]}"; do
    cp -r "$SKILLS_SRC/$s" "$dir/.cursor/skills/"
  done
  git -C "$dir" init -q -b main
  git -C "$dir" -c user.email=t@t -c user.name=t commit -q --allow-empty -m "chore: seed"
  git -C "$dir" remote add origin git@github.com:Milkywayrules/usecharator.git
}

INIT_REL=".cursor/skills/verasic-init/scripts/init.sh"

row() { grep -qE "$1 +$2" <<<"$3"; }

refresh_skill_hashes() {
  local skill_dir="$1"
  local integrity_file="$skill_dir/integrity.txt"
  local hash_file="$skill_dir/integrity.sha256"
  local line stripped
  > "$hash_file"
  while IFS= read -r line || [[ -n "$line" ]]; do
    stripped="${line%%#*}"
    stripped="${stripped//[[:space:]]/}"
    [[ -z "$stripped" ]] && continue
    [[ "$stripped" == "integrity.sha256" ]] && continue
    (cd "$skill_dir" && sha256sum "$stripped") >> "$hash_file"
  done < "$integrity_file"
}

MOCK_REPO="$TMP/mock-upstream-repo"
mkdir -p "$MOCK_REPO/cursor"
cp -r "$SKILLS_SRC/../cursor/." "$MOCK_REPO/cursor/"

init_yes() {
  local dir="$1"; shift
  (cd "$dir" && VERASIC_INIT_REMOTE_REPO_BASE="$MOCK_REPO" bash "$INIT_REL" "$@")
}

# --- plan mode: no mutations by default ---
R0="$TMP/plan"
make_repo "$R0" verasic-init verasic-github-env verasic-git-commits
out0="$(cd "$R0" && bash "$INIT_REL")"
grep -q 'setup plan (no changes made)' <<<"$out0" && ok "default is plan mode" || bad "default is plan mode"
grep -q 'install profile' <<<"$out0" && ok "plan shows install profile" || bad "plan shows install profile"
grep -q 'profile checklist' <<<"$out0" && ok "plan shows profile checklist" || bad "plan shows profile checklist"
grep -q 'pass --yes to apply' <<<"$out0" && ok "plan asks for confirmation" || bad "plan asks for confirmation"
grep -qE 'would fetch [0-9]+ Cursor UX file\(s\) for scope' <<<"$out0" && ok "plan mentions scoped upstream fetch" || bad "plan mentions scoped upstream fetch"
grep -q 'ux upstream' <<<"$out0" && grep -q 'v0.1.6' <<<"$out0" && ok "plan pins ux upstream to skill version" || bad "plan pins ux upstream to skill version"
grep -q ' scope' <<<"$out0" && grep -q 'source:' <<<"$out0" && ok "plan shows scope section" || bad "plan shows scope section"
[[ ! -f "$R0/.envrc" ]] && ok "plan does not wire .envrc" || bad "plan does not wire .envrc"

# --- full wire on a fresh repo ---
R="$TMP/full"
make_repo "$R" verasic-init verasic-github-env verasic-git-commits verasic-bugbot verasic-fusion
out="$(init_yes "$R" --yes --profile cursor)"
row 'verasic-github-env' 'wired' "$out" && ok "github-env wired" || bad "github-env wired"
row 'verasic-git-commits' 'wired' "$out" && ok "git-commits wired" || bad "git-commits wired"
row 'verasic-bugbot' 'ready' "$out" && ok "bugbot ready" || bad "bugbot ready"
row 'verasic-fusion' 'ready' "$out" && ok "fusion ready" || bad "fusion ready"
grep -q 'skill roots' <<<"$out" && ok "skill roots section" || bad "skill roots section"
grep -q 'versions' <<<"$out" && ok "versions section" || bad "versions section"
grep -qE 'verasic-init[[:space:]]+0\.1\.6' <<<"$out" && ok "versions row for verasic-init" || bad "versions row for verasic-init"
grep -q 'actions' <<<"$out" && ok "actions section" || bad "actions section"
[[ -f "$R/.envrc" ]] && ok ".envrc created" || bad ".envrc created"
[[ -f "$R/.github-agent.local" ]] && ok ".github-agent.local scaffolded" || bad ".github-agent.local scaffolded"
hooks_path="$(git -C "$R" config core.hooksPath || true)"
[[ "$hooks_path" == ".cursor/skills/verasic-git-commits/hooks" ]] && ok "hooksPath set" || bad "hooksPath set ($hooks_path)"
[[ -f "$R/.cursor/commands/verasic-init.md" ]] && ok "cursor --yes fetches commands" || bad "cursor --yes fetches commands"

( cd "$R" && echo x > f.txt && git add f.txt && \
  git -c user.email=t@t -c user.name=t commit -q -m $'test: probe hook\n\nCo-authored-by: Bot <b@b.co>' )
if git -C "$R" log -1 --format=%B | grep -qiE '^co-authored-by:'; then
  bad "hook strips trailer"
else
  ok "hook strips trailer"
fi

# --- idempotency ---
out2="$(init_yes "$R" --yes --profile cursor)"
grep -q '0 failed' <<<"$out2" && ok "re-run clean" || bad "re-run clean"
row 'verasic-git-commits' 'wired' "$out2" && ok "re-run hook already wired" || bad "re-run hook already wired"

# --- cherry-pick ---
out3="$(init_yes "$R" --yes --profile agent --skills verasic-bugbot)"
row 'verasic-github-env' 'not selected' "$out3" && ok "cherry-pick skips github-env" || bad "cherry-pick skips github-env"
row 'verasic-bugbot' 'ready' "$out3" && ok "cherry-pick keeps bugbot" || bad "cherry-pick keeps bugbot"

out3b="$(init_yes "$R" --yes --profile agent --skills ' verasic-bugbot , verasic-git-commits ')"
row 'verasic-bugbot' 'ready' "$out3b" && ok "whitespace --skills selects" || bad "whitespace --skills selects"
grep -q '0 unknown' <<<"$out3b" && ok "whitespace --skills no ghost rows" || bad "whitespace --skills no ghost rows"

rc=0
(cd "$R" && bash "$INIT_REL" --skills= >/dev/null 2>&1) || rc=$?
[[ "$rc" -eq 2 ]] && ok "empty --skills rejected" || bad "empty --skills rejected (rc=$rc)"

rc=0
out4="$(cd "$R" && bash "$INIT_REL" --skills nope)" || rc=$?
row 'nope' 'unknown' "$out4" && ok "unknown skill reported" || bad "unknown skill reported"
grep -q '1 unknown' <<<"$out4" && ok "unknown counted in tally" || bad "unknown counted in tally"
[[ "$rc" -eq 2 ]] && ok "all-unknown selection exits 2" || bad "all-unknown selection exits 2 (rc=$rc)"

rc=0
out4b="$(cd "$R" && bash "$INIT_REL" --skills verasic-bugbot,nope)" || rc=$?
[[ "$rc" -eq 0 ]] && ok "mixed selection exits 0" || bad "mixed selection exits 0 (rc=$rc)"
row 'verasic-bugbot' 'ready' "$out4b" && ok "mixed selection wires real skill" || bad "mixed selection wires real skill"

out4c="$(init_yes "$R" --yes --profile agent --skills verasic-init)"
row 'verasic-init' 'ready' "$out4c" && ok "verasic-init selectable in manifest" || bad "verasic-init selectable in manifest"

R1b="$TMP/tokened"
make_repo "$R1b" verasic-init verasic-bugbot
git -C "$R1b" remote set-url origin https://x-access-token:ghp_FAKESECRET@github.com/acme/w.git
outT="$(init_yes "$R1b" --yes --profile cursor)"
grep -q 'ghp_FAKESECRET' <<<"$outT" && bad "origin credentials stripped" || ok "origin credentials stripped"
grep -q 'https://github.com/acme/w.git' <<<"$outT" && ok "origin still shown" || bad "origin still shown"

R2="$TMP/partial"
make_repo "$R2" verasic-init verasic-bugbot
out5="$(init_yes "$R2" --yes --profile agent)"
row 'verasic-github-env' 'not installed' "$out5" && ok "missing skill reported" || bad "missing skill reported"

# --- gut missing file -> broken install ---
R2a="$TMP/gut"
make_repo "$R2a" verasic-init verasic-github-env
rm "$R2a/.cursor/skills/verasic-github-env/SKILL.md"
rc=0
out5a="$(init_yes "$R2a" --yes --profile agent 2>/dev/null)" || rc=$?
[[ "$rc" -eq 1 ]] && ok "gut missing file exits 1" || bad "gut missing file exits 1 (rc=$rc)"
row 'verasic-github-env' 'broken install' "$out5a" && ok "gut missing file broken install row" || bad "gut missing file broken install row"

# --- installed skill with missing wire script -> broken install ---
R2b="$TMP/broken"
make_repo "$R2b" verasic-init verasic-github-env
rm "$R2b/.cursor/skills/verasic-github-env/scripts/bootstrap.sh"
rc=0
out5b="$(init_yes "$R2b" --yes --profile agent 2>/dev/null)" || rc=$?
[[ "$rc" -eq 1 ]] && ok "broken install exits 1" || bad "broken install exits 1 (rc=$rc)"
row 'verasic-github-env' 'broken install' "$out5b" && ok "broken install row" || bad "broken install row"

R2c="$TMP/notrail"
make_repo "$R2c" verasic-init verasic-bugbot
printf '%s' 'verasic-bugbot|-|local review' > "$R2c/.cursor/skills/verasic-init/manifest.txt"
out5c="$(init_yes "$R2c" --yes --profile agent)"
row 'verasic-bugbot' 'ready' "$out5c" && ok "manifest last line without newline kept" || bad "manifest last line without newline kept"

R3="$TMP/lefthook"
make_repo "$R3" verasic-init verasic-git-commits
printf 'pre-commit:\n  commands:\n    lint:\n      run: true\n' > "$R3/lefthook.yml"
rc=0
out6="$(init_yes "$R3" --yes --profile cursor)" || rc=$?
[[ "$rc" -eq 0 ]] && ok "lefthook run exits 0" || bad "lefthook run exits 0 (rc=$rc)"
row 'verasic-git-commits' 'action needed' "$out6" && ok "lefthook action needed" || bad "lefthook action needed"
grep -q 'lefthook detected' <<<"$out6" && ok "lefthook snippet shown" || bad "lefthook snippet shown"
[[ -z "$(git -C "$R3" config core.hooksPath || true)" ]] && ok "lefthook hooksPath untouched" || bad "lefthook hooksPath untouched"

R3b="$TMP/globalhooks"
make_repo "$R3b" verasic-init verasic-git-commits
mkdir -p "$TMP/managed-hooks" "$TMP/fakehome"
rc=0
out6b="$(cd "$R3b" && HOME="$TMP/fakehome" git config --global core.hooksPath "$TMP/managed-hooks" && \
         HOME="$TMP/fakehome" VERASIC_INIT_REMOTE_REPO_BASE="$MOCK_REPO" bash "$INIT_REL" --yes --profile cursor)" || rc=$?
[[ "$rc" -eq 0 ]] && ok "global hooksPath run exits 0" || bad "global hooksPath run exits 0 (rc=$rc)"
row 'verasic-git-commits' 'action needed' "$out6b" && ok "global hooksPath action needed" || bad "global hooksPath action needed"
[[ -z "$(git -C "$R3b" config --local core.hooksPath || true)" ]] && ok "global hooksPath not overridden locally" || bad "global hooksPath not overridden locally"

# --- list mode: integrity ok ---
R4="$TMP/list"
make_repo "$R4" verasic-init verasic-github-env
out7="$(cd "$R4" && bash "$INIT_REL" --list)"
grep -q 'no changes made' <<<"$out7" && ok "list banner" || bad "list banner"
row 'verasic-github-env' 'ok' "$out7" && ok "list shows ok when integrity passes" || bad "list shows ok when integrity passes"
grep -q 'wired' <<<"$out7" && bad "list tally has no wired" || ok "list tally has no wired"
[[ ! -f "$R4/.envrc" ]] && ok "list changes nothing" || bad "list changes nothing"

# --- list mode: integrity failure ---
R4b="$TMP/list-broken"
make_repo "$R4b" verasic-init verasic-github-env
rm "$R4b/.cursor/skills/verasic-github-env/scripts/check-gh.sh"
rc=0
out7b="$(cd "$R4b" && bash "$INIT_REL" --list 2>&1)" || rc=$?
row 'verasic-github-env' 'broken install' "$out7b" && ok "list shows broken install" || bad "list shows broken install"
[[ "$rc" -eq 1 ]] && ok "list broken install exits 1" || bad "list broken install exits 1 (rc=$rc)"

# --- dual roots discovery ---
R5d="$TMP/dual"
mkdir -p "$R5d/.cursor/skills" "$R5d/.agents/skills"
cp -r "$SKILLS_SRC/verasic-init" "$R5d/.agents/skills/"
cp -r "$SKILLS_SRC/verasic-bugbot" "$R5d/.cursor/skills/"
git -C "$R5d" init -q -b main
git -C "$R5d" -c user.email=t@t -c user.name=t commit -q --allow-empty -m "chore: seed"
git -C "$R5d" remote add origin git@github.com:Milkywayrules/usecharator.git
outDual="$(cd "$R5d" && bash .agents/skills/verasic-init/scripts/init.sh --list)"
grep -q '.agents/skills' <<<"$outDual" && ok "dual roots lists .agents/skills" || bad "dual roots lists .agents/skills"
grep -q '.cursor/skills' <<<"$outDual" && ok "dual roots lists .cursor/skills" || bad "dual roots lists .cursor/skills"

# --- external invoker + repo local skills ---
R5e="$TMP/external"
make_repo "$R5e" verasic-init verasic-bugbot
EXTERNAL_INIT="$SKILLS_SRC/verasic-init/scripts/init.sh"
outExt="$(cd "$R5e" && bash "$EXTERNAL_INIT" --list)"
grep -q 'invoked from outside repo' <<<"$outExt" && ok "external invoker warning" || bad "external invoker warning"
row 'verasic-bugbot' 'ready' "$outExt" && ok "external invoker uses repo skills" || bad "external invoker uses repo skills"
grep -q 'skills root' <<<"$outExt" && grep -q '.cursor/skills' <<<"$outExt" && ok "external invoker repo-local root" || bad "external invoker repo-local root"

# --- external invoker, no local init -> exit 1 ---
R5f="$TMP/no-local"
mkdir -p "$R5f/.cursor/skills"
cp -r "$SKILLS_SRC/verasic-bugbot" "$R5f/.cursor/skills/"
git -C "$R5f" init -q -b main
git -C "$R5f" -c user.email=t@t -c user.name=t commit -q --allow-empty -m "chore: seed"
rc=0
(cd "$R5f" && bash "$EXTERNAL_INIT" >/dev/null 2>&1) || rc=$?
[[ "$rc" -eq 1 ]] && ok "no local init rejected" || bad "no local init rejected (rc=$rc)"

# --- not a git repo ---
R5="$TMP/nogit"
mkdir -p "$R5/.cursor/skills"
cp -r "$SKILLS_SRC/verasic-init" "$R5/.cursor/skills/"
rc=0
(cd "$R5" && bash "$INIT_REL" >/dev/null 2>&1) || rc=$?
[[ "$rc" -eq 1 ]] && ok "non-git repo rejected" || bad "non-git repo rejected (rc=$rc)"

# --- legacy 3-field manifest backward compat ---
R6="$TMP/legacy-manifest"
make_repo "$R6" verasic-init verasic-bugbot
printf '%s\n' 'verasic-bugbot|-|local review skill' > "$R6/.cursor/skills/verasic-init/manifest.txt"
out6="$(init_yes "$R6" --yes --profile agent)"
row 'verasic-bugbot' 'ready' "$out6" && ok "3-field manifest backward compat" || bad "3-field manifest backward compat"

# --- 4-field manifest verify column present ---
grep -q 'scripts/check-gh.sh' "$SKILLS_SRC/verasic-init/manifest.txt" && ok "4-field manifest has verify column" || bad "4-field manifest has verify column"

# --- --verify runs manifest verify script (mock check-gh) ---
R7="$TMP/verify-flag"
make_repo "$R7" verasic-init verasic-github-env
mkdir -p "$R7/.cursor/skills/verasic-github-env/scripts"
cat > "$R7/.cursor/skills/verasic-github-env/scripts/check-gh.sh" <<'MOCK'
#!/usr/bin/env bash
echo "check-gh: ok — mock verify"
MOCK
chmod +x "$R7/.cursor/skills/verasic-github-env/scripts/check-gh.sh"
refresh_skill_hashes "$R7/.cursor/skills/verasic-github-env"
out7v="$(init_yes "$R7" --yes --verify --profile cursor)"
grep -q 'verify: ok' <<<"$out7v" && ok "--verify runs check-gh" || bad "--verify runs check-gh"
grep -q 'manifest verify' <<<"$out7v" && ok "--verify logs manifest verify output" || bad "--verify logs manifest verify output"

# --- --verify failure exits 3 ---
R7b="$TMP/verify-fail"
make_repo "$R7b" verasic-init verasic-github-env
cat > "$R7b/.cursor/skills/verasic-github-env/scripts/check-gh.sh" <<'MOCK'
#!/usr/bin/env bash
echo "check-gh: mock failure" >&2
exit 1
MOCK
chmod +x "$R7b/.cursor/skills/verasic-github-env/scripts/check-gh.sh"
refresh_skill_hashes "$R7b/.cursor/skills/verasic-github-env"
rc=0
out7f="$(init_yes "$R7b" --yes --verify --profile cursor 2>&1)" || rc=$?
grep -q 'verify: failed' <<<"$out7f" && ok "--verify reports verify failed" || bad "--verify reports verify failed"
[[ "$rc" -eq 3 ]] && ok "--verify failure exits 3" || bad "--verify failure exits 3 (rc=$rc)"

# --- default hash integrity detects modified file ---
R8="$TMP/strict"
make_repo "$R8" verasic-init verasic-bugbot
echo "# tampered" >> "$R8/.cursor/skills/verasic-bugbot/SKILL.md"
rc=0
out8="$(init_yes "$R8" --yes --profile agent 2>&1)" || rc=$?
row 'verasic-bugbot' 'broken install' "$out8" && ok "default hash broken install row" || bad "default hash broken install row"
grep -q 'local patch detected' <<<"$out8" && ok "default hash reports local patch warning" || bad "default hash reports local patch warning"
[[ "$rc" -eq 1 ]] && ok "default hash mismatch exits 1" || bad "default hash mismatch exits 1 (rc=$rc)"

# --- --strict-integrity backward compat (no-op) ---
rc=0
out8b="$(init_yes "$R8" --yes --profile agent --strict-integrity 2>&1)" || rc=$?
row 'verasic-bugbot' 'broken install' "$out8b" && ok "--strict-integrity alias still detects mismatch" || bad "--strict-integrity alias still detects mismatch"
[[ "$rc" -eq 1 ]] && ok "--strict-integrity alias exits 1" || bad "--strict-integrity alias exits 1 (rc=$rc)"

# --- --no-strict-integrity skips hash failure ---
R8c="$TMP/loose"
make_repo "$R8c" verasic-init verasic-bugbot
echo "# tampered" >> "$R8c/.cursor/skills/verasic-bugbot/SKILL.md"
rc=0
out8c="$(init_yes "$R8c" --yes --profile agent --no-strict-integrity 2>&1)" || rc=$?
row 'verasic-bugbot' 'ready' "$out8c" && ok "--no-strict-integrity skips hash failure" || bad "--no-strict-integrity skips hash failure"
grep -q 'presence-only (--no-strict-integrity)' <<<"$out8c" && ok "--no-strict-integrity notes presence-only" || bad "--no-strict-integrity notes presence-only"
[[ "$rc" -eq 0 ]] && ok "--no-strict-integrity exits 0" || bad "--no-strict-integrity exits 0 (rc=$rc)"

# --- --check-updates with mocked upstream ---
R9="$TMP/updates"
make_repo "$R9" verasic-init verasic-bugbot
MOCK_BASE="$TMP/mock-upstream/skills"
mkdir -p "$MOCK_BASE/verasic-bugbot" "$MOCK_BASE/verasic-init"
printf '9.9.9\n' > "$MOCK_BASE/verasic-bugbot/VERSION"
printf '0.1.6\n' > "$MOCK_BASE/verasic-init/VERSION"
out9="$(cd "$R9" && VERASIC_INIT_REMOTE_VERSION_BASE="$MOCK_BASE" bash "$INIT_REL" --check-updates)"
grep -q '9.9.9 available' <<<"$out9" && ok "--check-updates shows available version" || bad "--check-updates shows available version"
grep -q 'up to date' <<<"$out9" && ok "--check-updates shows up to date row" || bad "--check-updates shows up to date row"

# --- cursor-hybrid fetches Cursor UX from upstream (mock local repo base) ---
R10="$TMP/hybrid"
mkdir -p "$R10/.agents/skills"
cp -r "$SKILLS_SRC/verasic-init" "$R10/.agents/skills/"
cp -r "$SKILLS_SRC/verasic-github-env" "$R10/.agents/skills/"
git -C "$R10" init -q -b main
git -C "$R10" -c user.email=t@t -c user.name=t commit -q --allow-empty -m "chore: seed"
git -C "$R10" remote add origin git@github.com:Milkywayrules/usecharator.git
out10="$(cd "$R10" && VERASIC_INIT_REMOTE_REPO_BASE="$MOCK_REPO" bash .agents/skills/verasic-init/scripts/init.sh --yes --profile cursor-hybrid)"
[[ -f "$R10/.cursor/commands/verasic-init.md" ]] && ok "hybrid --yes fetches cursor commands" || bad "hybrid --yes fetches cursor commands"
[[ -f "$R10/.cursor/rules/verasic-github-env.mdc" ]] && ok "hybrid --yes fetches scoped cursor rules" || bad "hybrid --yes fetches scoped cursor rules"
[[ ! -f "$R10/.cursor/rules/verasic-git-commits.mdc" ]] && ok "hybrid scoped skips uninstalled git-commits rule" || bad "hybrid scoped skips uninstalled git-commits rule"
grep -q 'installed Cursor UX from upstream' <<<"$out10" && ok "hybrid reports upstream fetch" || bad "hybrid reports upstream fetch"
grep -q 'cursor-hybrid' <<<"$out10" && ok "hybrid report names profile" || bad "hybrid report names profile"
row 'verasic-github-env' 'wired' "$out10" && ok "hybrid wires github-env from .agents/skills" || bad "hybrid wires github-env from .agents/skills"

# --- agent profile plan for skills.sh layout ---
R11="$TMP/agent-plan"
mkdir -p "$R11/.agents/skills"
cp -r "$SKILLS_SRC/verasic-init" "$R11/.agents/skills/"
cp -r "$SKILLS_SRC/verasic-bugbot" "$R11/.agents/skills/"
git -C "$R11" init -q -b main
git -C "$R11" -c user.email=t@t -c user.name=t commit -q --allow-empty -m "chore: seed"
out11="$(cd "$R11" && bash .agents/skills/verasic-init/scripts/init.sh --profile agent)"
grep -q 'profile.*agent' <<<"$out11" && ok "agent profile in plan" || bad "agent profile in plan"
grep -q 'Claude Code' <<<"$out11" && ok "agent usage mentions other hosts" || bad "agent usage mentions other hosts"
grep -q 'setup plan' <<<"$out11" && ok "agent plan makes no changes" || bad "agent plan makes no changes"

# --- cursor UX fetch failure exits 1 ---
R12="$TMP/ux-fail"
make_repo "$R12" verasic-init verasic-github-env
mkdir -p "$TMP/dead-upstream"
rc=0
out12="$(cd "$R12" && VERASIC_INIT_REMOTE_REPO_BASE="$TMP/dead-upstream" bash "$INIT_REL" --yes --profile cursor 2>&1)" || rc=$?
[[ "$rc" -eq 1 ]] && ok "ux fetch failure exits 1" || bad "ux fetch failure exits 1 (rc=$rc)"
row 'cursor-ux' 'FAILED' "$out12" && ok "ux fetch failure FAILED row" || bad "ux fetch failure FAILED row"
grep -q 'profile actions' <<<"$out12" && ok "ux fetch failure logs profile actions" || bad "ux fetch failure logs profile actions"

# --- T-partial-cursor: scoped UX fetch only ---
R13="$TMP/partial-cursor"
make_repo "$R13" verasic-bugbot verasic-fusion verasic-init
out13="$(init_yes "$R13" --yes --profile cursor --skills verasic-bugbot,verasic-fusion,verasic-init)"
[[ -f "$R13/.cursor/commands/verasic-init.md" ]] && ok "T-partial-cursor fetches init command" || bad "T-partial-cursor fetches init command"
[[ -f "$R13/.cursor/commands/verasic-fusion.md" ]] && ok "T-partial-cursor fetches fusion command" || bad "T-partial-cursor fetches fusion command"
[[ -f "$R13/.cursor/commands/verasic-review.md" ]] && ok "T-partial-cursor fetches review command" || bad "T-partial-cursor fetches review command"
[[ -f "$R13/.cursor/agents/verasic-bugbot.md" ]] && ok "T-partial-cursor fetches bugbot agent" || bad "T-partial-cursor fetches bugbot agent"
[[ ! -f "$R13/.cursor/rules/verasic-git-commits.mdc" ]] && ok "T-partial-cursor skips git-commits rule" || bad "T-partial-cursor skips git-commits rule"
[[ ! -f "$R13/.cursor/commands/verasic-setup-github.md" ]] && ok "T-partial-cursor skips setup-github" || bad "T-partial-cursor skips setup-github"
grep -q 'no Cursor UX files for effective scope' <<<"$out13" && bad "T-partial-cursor should fetch some UX" || ok "T-partial-cursor fetched scoped UX"

# --- T-partial-plan: scoped checklist and usage ---
R14="$TMP/partial-plan"
make_repo "$R14" verasic-bugbot verasic-fusion verasic-init
out14="$(cd "$R14" && bash "$INIT_REL" --profile cursor --skills verasic-bugbot,verasic-fusion,verasic-init)"
grep -q 'miss:.*verasic-git-commits.mdc' <<<"$out14" && bad "T-partial-plan checklist miss git-commits" || ok "T-partial-plan checklist no miss for git-commits"
grep -q '/verasic-audit-commits' <<<"$out14" && bad "T-partial-plan usage mentions audit-commits" || ok "T-partial-plan usage omits excluded commands"
grep -q '/verasic-fusion' <<<"$out14" && ok "T-partial-plan usage includes fusion" || bad "T-partial-plan usage includes fusion"
grep -q 'would fetch 4 Cursor UX file(s) for scope' <<<"$out14" && ok "T-partial-plan scoped fetch count" || bad "T-partial-plan scoped fetch count"

# --- T-partial-agent: skill-only scope, no .cursor files ---
R15="$TMP/partial-agent"
make_repo "$R15" verasic-bugbot verasic-fusion verasic-init
out15="$(init_yes "$R15" --yes --profile agent --skills verasic-bugbot,verasic-fusion,verasic-init)"
[[ ! -f "$R15/.cursor/commands/verasic-init.md" ]] && ok "T-partial-agent no cursor commands" || bad "T-partial-agent no cursor commands"
grep -q 'scope has no repo wiring' <<<"$out15" && ok "T-partial-agent honest no-wiring banner" || bad "T-partial-agent honest no-wiring banner"

# --- T-github-only: scoped github UX ---
R16="$TMP/github-only"
make_repo "$R16" verasic-init verasic-github-env
out16="$(init_yes "$R16" --yes --profile cursor --skills verasic-github-env)"
[[ -f "$R16/.cursor/commands/verasic-setup-github.md" ]] && ok "T-github-only fetches setup-github" || bad "T-github-only fetches setup-github"
[[ -f "$R16/.cursor/rules/verasic-github-env.mdc" ]] && ok "T-github-only fetches github rule" || bad "T-github-only fetches github rule"
[[ ! -f "$R16/.cursor/commands/verasic-init.md" ]] && ok "T-github-only skips init command" || bad "T-github-only skips init command"
row 'verasic-github-env' 'wired' "$out16" && ok "T-github-only wires github-env" || bad "T-github-only wires github-env"

# --- T-map-sync: skill-ux-map covers cursor-ux-manifest ---
map_ok=true
while IFS= read -r mpath; do
  [[ -z "$mpath" || "$mpath" == \#* ]] && continue
  grep -qF "|${mpath}|" "$SKILLS_SRC/verasic-init/references/skill-ux-map.txt" || { map_ok=false; break; }
done < "$SKILLS_SRC/verasic-init/references/cursor-ux-manifest.txt"
$map_ok && ok "T-map-sync manifest paths in skill-ux-map" || bad "T-map-sync manifest paths in skill-ux-map"

# --- T-scope-banner: report contains scope section ---
R17="$TMP/scope-banner"
make_repo "$R17" verasic-init verasic-bugbot
out17="$(cd "$R17" && bash "$INIT_REL" --skills verasic-bugbot,verasic-init)"
grep -q '^ scope$' <<<"$out17" && ok "T-scope-banner scope heading" || bad "T-scope-banner scope heading"
grep -q 'source: --skills' <<<"$out17" && ok "T-scope-banner scope source" || bad "T-scope-banner scope source"
grep -q '• verasic-bugbot' <<<"$out17" && ok "T-scope-banner lists scoped skills" || bad "T-scope-banner lists scoped skills"

echo "---"
echo "regression: $pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
