#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INIT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILLS_SRC="$(cd "$INIT_ROOT/.." && pwd)"
GOV_SRC="$SKILLS_SRC/verasic-github-governance"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pass=0
fail=0
ok()  { echo "PASS: $1"; pass=$((pass + 1)); }
bad() { echo "FAIL: $1"; fail=$((fail + 1)); }

make_repo() {
  local dir="$1"
  mkdir -p "$dir/.cursor/skills"
  cp -r "$GOV_SRC" "$dir/.cursor/skills/"
  cp -r "$INIT_ROOT" "$dir/.cursor/skills/verasic-github-governance-init"
  cp -r "$SKILLS_SRC/verasic-git-commits" "$dir/.cursor/skills/" 2>/dev/null || true
  cp -r "$SKILLS_SRC/verasic-github-env" "$dir/.cursor/skills/" 2>/dev/null || true
  git -C "$dir" init -q -b main
  git -C "$dir" -c user.email=t@t -c user.name=t commit -q --allow-empty -m "chore: seed"
  git -C "$dir" remote add origin git@github.com:Milkywayrules/governance-test.git
}

FACTORY=".cursor/skills/verasic-github-governance-init/scripts/factory.sh"
chmod +x "$INIT_ROOT/scripts/factory.sh"
chmod +x "$GOV_SRC/scripts/"*.sh

R="$TMP/factory"
make_repo "$R"
out="$(cd "$R" && bash "$FACTORY")"
grep -q 'plan only' <<<"$out" && ok "default is plan mode" || bad "default is plan mode"
grep -q 'bootstrap-repo.sh' <<<"$out" && ok "plan lists bootstrap" || bad "plan lists bootstrap"
[[ ! -f "$R/CONTRIBUTING.md" ]] && ok "plan does not mutate" || bad "plan does not mutate"

out2="$(cd "$R" && bash "$FACTORY" --yes)"
grep -q 'factory: PASS' <<<"$out2" && ok "--yes applies" || bad "--yes applies"
[[ -f "$R/CONTRIBUTING.md" ]] && ok "--yes creates CONTRIBUTING" || bad "--yes creates CONTRIBUTING"
[[ -f "$R/.github/workflows/ci.yml" ]] && ok "--yes creates ci workflow" || bad "--yes creates ci workflow"

R2="$TMP/nogov"
mkdir -p "$R2/.cursor/skills"
cp -r "$INIT_ROOT" "$R2/.cursor/skills/verasic-github-governance-init"
git -C "$R2" init -q -b main
git -C "$R2" -c user.email=t@t -c user.name=t commit -q --allow-empty -m "chore: seed"
rc=0
(cd "$R2" && bash "$FACTORY" --yes >/dev/null 2>&1) || rc=$?
[[ "$rc" -eq 1 ]] && ok "missing governance skill exits 1" || bad "missing governance skill exits 1 (rc=$rc)"

echo "---"
echo "regression: $pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
