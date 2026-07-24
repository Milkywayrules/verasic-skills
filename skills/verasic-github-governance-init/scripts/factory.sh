#!/usr/bin/env bash
set -euo pipefail

# Plan-first governance factory — wraps bootstrap-repo, wire-hooks, lefthook install, doctor.
# Exit codes: 0 = ok/plan, 1 = error, 2 = bootstrap CI conflict, 3 = doctor gaps

YES=0
FORCE=0
OPEN_PR=0
CI_STRATEGY=""

usage() {
  cat <<'EOF'
factory — bootstrap Verasic GitHub governance into the current repo

Usage:
  factory.sh [options]

Options:
  --yes                 apply (default is plan-only)
  --force               pass --force to bootstrap-repo.sh
  --ci-strategy=MODE    skip|merge|replace (see existing-repo-conflicts.md)
  --open-pr             after apply: branch, commit, push, gh pr create
  -h, --help

Requires installed skills: verasic-github-governance, verasic-github-env (for --open-pr).
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --yes) YES=1; shift ;;
    --force) FORCE=1; shift ;;
    --open-pr) OPEN_PR=1; shift ;;
    --ci-strategy=*)
      CI_STRATEGY="${1#*=}"
      shift
      ;;
    --ci-strategy)
      CI_STRATEGY="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "factory: unknown arg: $1" >&2
      exit 1
      ;;
  esac
done

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "factory: must run inside a git repository" >&2
  exit 1
fi
REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INIT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

find_skill_root() {
  local name="$1"
  local roots=(
    "$REPO_ROOT/.agents/skills/$name"
    "$REPO_ROOT/.cursor/skills/$name"
  )
  local r
  for r in "${roots[@]}"; do
    if [[ -f "$r/SKILL.md" ]]; then
      echo "$r"
      return 0
    fi
  done
  return 1
}

GOV_ROOT="$(find_skill_root verasic-github-governance || true)"
if [[ -z "$GOV_ROOT" ]]; then
  echo "factory: verasic-github-governance not installed (.agents/skills or .cursor/skills)" >&2
  exit 1
fi

ENV_ROOT="$(find_skill_root verasic-github-env || true)"
if [[ -z "$ENV_ROOT" ]]; then
  echo "factory: WARN — verasic-github-env not installed (--open-pr needs it)" >&2
fi

bootstrap_args=()
[[ "$FORCE" -eq 1 ]] && bootstrap_args+=(--force)
[[ -n "$CI_STRATEGY" ]] && bootstrap_args+=(--ci-strategy="$CI_STRATEGY")

plan_line() {
  printf '  • %s\n' "$1"
}

echo "governance factory plan"
echo "repo: $REPO_ROOT"
echo "governance skill: $GOV_ROOT"
[[ -n "$ENV_ROOT" ]] && echo "github-env skill: $ENV_ROOT"
echo
echo " steps:"
plan_line "bootstrap-repo.sh ${bootstrap_args[*]:-(default)}"
plan_line "wire-hooks.sh"
plan_line "lefthook install (when lefthook available)"
plan_line "doctor.sh"
[[ "$OPEN_PR" -eq 1 ]] && plan_line "open PR on chore/governance-bootstrap"
echo
if [[ "$YES" -eq 0 ]]; then
  echo "plan only — pass --yes to apply"
  exit 0
fi

echo "== apply =="
set +e
bash "$GOV_ROOT/scripts/bootstrap-repo.sh" "${bootstrap_args[@]}"
rc=$?
set -e
if [[ "$rc" -eq 2 ]]; then
  echo "factory: bootstrap stopped on CI conflict (exit 2)" >&2
  exit 2
elif [[ "$rc" -ne 0 ]]; then
  echo "factory: bootstrap failed (exit $rc)" >&2
  exit 1
fi

bash "$GOV_ROOT/scripts/wire-hooks.sh"
if command -v lefthook >/dev/null 2>&1; then
  lefthook install
  echo "factory: lefthook install ok"
else
  echo "factory: WARN — lefthook not installed; run 'lefthook install' when available"
fi

set +e
bash "$GOV_ROOT/scripts/doctor.sh"
doc_rc=$?
set -e
if [[ "$doc_rc" -ne 0 ]]; then
  echo "factory: doctor exit $doc_rc" >&2
  exit 3
fi

if [[ "$OPEN_PR" -eq 1 ]]; then
  if [[ -z "$ENV_ROOT" ]]; then
    echo "factory: --open-pr requires verasic-github-env" >&2
    exit 1
  fi
  if [[ -f "$ENV_ROOT/scripts/load-gh-env.sh" ]]; then
    # shellcheck source=/dev/null
    source "$ENV_ROOT/scripts/load-gh-env.sh"
  fi
  branch="chore/governance-bootstrap"
  git checkout -B "$branch"
  git add -A
  if git diff --cached --quiet; then
    echo "factory: nothing to commit for PR"
  else
    git commit -m "$(cat <<'EOF'
chore: bootstrap verasic governance templates

wire soft governance hooks and CI stub for first merge proof.
EOF
)"
  fi
  git push -u origin "$branch"
  gh pr create --title "chore: bootstrap governance" --body "$(cat <<'EOF'
## Summary
- bootstrap verasic governance templates (CI, hooks, CONTRIBUTING)
- proves Actions + merge path; required check name `ci`

## Test plan
- [ ] Actions green
- [ ] job `ci` passes
EOF
)"
  echo "factory: PR opened"
fi

echo "factory: PASS"
