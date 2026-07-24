#!/usr/bin/env bash
set -euo pipefail

# Copy Verasic governance templates into the current repo (idempotent).
# Exit codes: 0 = ok, 1 = error, 2 = CI conflict (existing workflows without marker), 3 = manual step printed

FORCE=0
CI_STRATEGY=""
GOV_MARKER='verasic-governance-ci: managed'
AGENTS_START='<!-- verasic-governance:start -->'
AGENTS_END='<!-- verasic-governance:end -->'

usage() {
  cat <<'EOF'
bootstrap-repo — copy governance templates into the current repo

Usage:
  bootstrap-repo.sh [--force] [--ci-strategy=skip|merge|replace]

CI strategy (when .github/workflows/*.yml exists without our marker):
  (default)  exit 2 — stop and report conflict
  skip       leave existing workflows untouched
  merge      update only workflows that already contain our marker
  replace    overwrite with the governance CI template (standard or turborepo)
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force) FORCE=1; shift ;;
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
      echo "bootstrap-repo: unknown arg: $1" >&2
      exit 1
      ;;
  esac
done

case "$CI_STRATEGY" in
  ''|skip|merge|replace) ;;
  *)
    echo "bootstrap-repo: invalid --ci-strategy: $CI_STRATEGY (use skip|merge|replace)" >&2
    exit 1
    ;;
esac

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "bootstrap-repo: must run inside a git repository" >&2
  exit 1
fi
REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATES="$SKILL_ROOT/templates"

if [[ ! -d "$TEMPLATES" ]]; then
  echo "bootstrap-repo: templates/ not found — broken install" >&2
  exit 1
fi

copy_if_missing() {
  local src="$1" dest="$2"
  if [[ -f "$dest" && "$FORCE" -eq 0 ]]; then
    echo "bootstrap-repo: skip (exists) $dest"
    return 0
  fi
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  echo "bootstrap-repo: wrote $dest"
}

has_managed_workflow() {
  local f
  shopt -s nullglob
  local files=(.github/workflows/*.yml .github/workflows/*.yaml)
  shopt -u nullglob
  for f in "${files[@]}"; do
    [[ -f "$f" ]] || continue
    grep -qF "$GOV_MARKER" "$f" && return 0
  done
  return 1
}

has_any_workflow() {
  shopt -s nullglob
  local files=(.github/workflows/*.yml .github/workflows/*.yaml)
  shopt -u nullglob
  ((${#files[@]} > 0))
}

select_ci_template() {
  if [[ -f "$REPO_ROOT/turbo.json" ]]; then
    echo "$TEMPLATES/.github/workflows/ci-turborepo.yml"
  else
    echo "$TEMPLATES/.github/workflows/ci.yml"
  fi
}

resolve_ci_conflict() {
  if ! has_any_workflow; then
    return 0
  fi
  if has_managed_workflow; then
    return 0
  fi
  if [[ -z "$CI_STRATEGY" ]]; then
    echo "bootstrap-repo: CONFLICT — existing GitHub workflow(s) without marker '$GOV_MARKER'" >&2
    echo "bootstrap-repo: re-run with --ci-strategy=skip|merge|replace (see references/existing-repo-conflicts.md)" >&2
    exit 2
  fi
}

install_ci_workflow() {
  local src dest
  src="$(select_ci_template)"
  dest="$REPO_ROOT/.github/workflows/ci.yml"

  if [[ "$CI_STRATEGY" == "skip" ]]; then
    echo "bootstrap-repo: skip CI (--ci-strategy=skip)"
    return 0
  fi

  if [[ "$CI_STRATEGY" == "merge" ]]; then
    if [[ -f "$dest" ]] && grep -qF "$GOV_MARKER" "$dest"; then
      cp "$src" "$dest"
      echo "bootstrap-repo: merged (updated managed) $dest"
      return 0
    fi
    if has_managed_workflow; then
      local f
      shopt -s nullglob
      local files=(.github/workflows/*.yml .github/workflows/*.yaml)
      shopt -u nullglob
      for f in "${files[@]}"; do
        grep -qF "$GOV_MARKER" "$f" || continue
        cp "$src" "$f"
        echo "bootstrap-repo: merged (updated managed) $f"
      done
      return 0
    fi
    echo "bootstrap-repo: merge requires an existing managed workflow (marker '$GOV_MARKER')" >&2
    exit 2
  fi

  if [[ -f "$dest" && "$FORCE" -eq 0 && "$CI_STRATEGY" != "replace" ]]; then
    if grep -qF "$GOV_MARKER" "$dest"; then
      cp "$src" "$dest"
      echo "bootstrap-repo: updated managed $dest"
      return 0
    fi
    echo "bootstrap-repo: skip (exists) $dest"
    return 0
  fi

  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  echo "bootstrap-repo: wrote $dest"
}

merge_agents_md() {
  local template="$TEMPLATES/AGENTS.md"
  local dest="$REPO_ROOT/AGENTS.md"
  if [[ ! -f "$template" ]]; then
    echo "bootstrap-repo: skip AGENTS.md (template missing)" >&2
    return 0
  fi

  local block
  block="$(sed -n "/$AGENTS_START/,/$AGENTS_END/p" "$template")"
  if [[ -z "$block" ]]; then
    echo "bootstrap-repo: AGENTS.md template missing governance markers" >&2
    exit 1
  fi

  if [[ ! -f "$dest" ]]; then
    cp "$template" "$dest"
    echo "bootstrap-repo: wrote $dest"
    return 0
  fi

  if grep -qF "$AGENTS_START" "$dest" && grep -qF "$AGENTS_END" "$dest"; then
    if [[ "$FORCE" -eq 1 ]]; then
      local tmp
      tmp="$(mktemp)"
      sed "/$AGENTS_START/,/$AGENTS_END/d" "$dest" > "$tmp"
      printf '%s\n' "$block" >> "$tmp"
      mv "$tmp" "$dest"
      echo "bootstrap-repo: refreshed governance block in $dest"
    else
      echo "bootstrap-repo: skip (governance block present) $dest"
    fi
    return 0
  fi

  {
    cat "$dest"
    echo
    echo "$block"
  } > "${dest}.tmp"
  mv "${dest}.tmp" "$dest"
  echo "bootstrap-repo: merged governance block into $dest"
}

resolve_ci_conflict
install_ci_workflow

copy_if_missing "$TEMPLATES/CONTRIBUTING.md" "$REPO_ROOT/CONTRIBUTING.md"
copy_if_missing "$TEMPLATES/lefthook.yml" "$REPO_ROOT/lefthook.yml"
copy_if_missing "$TEMPLATES/.github/pull_request_template.md" "$REPO_ROOT/.github/pull_request_template.md"

merge_agents_md

GOV_HOOKS_DIR="$REPO_ROOT/.github/verasic-governance/hooks"
copy_hook() {
  local src="$1" name="$2"
  local dest="$GOV_HOOKS_DIR/$name"
  if [[ -f "$dest" && "$FORCE" -eq 0 ]]; then
    echo "bootstrap-repo: skip (exists) $dest"
    return 0
  fi
  mkdir -p "$GOV_HOOKS_DIR"
  cp "$src" "$dest"
  chmod +x "$dest"
  echo "bootstrap-repo: wrote $dest"
}

for hook in pre-push pre-commit; do
  if [[ ! -f "$SKILL_ROOT/hooks/$hook" ]]; then
    echo "bootstrap-repo: hooks/$hook not found — broken install" >&2
    exit 1
  fi
  copy_hook "$SKILL_ROOT/hooks/$hook" "$hook"
done

if [[ ! -f "$REPO_ROOT/.gitignore" ]]; then
  printf '%s\n' '# local' '.lefthook-local.yml' > "$REPO_ROOT/.gitignore"
  echo "bootstrap-repo: wrote .gitignore (minimal)"
fi

echo "bootstrap-repo: done — run wire-hooks.sh && lefthook install"
