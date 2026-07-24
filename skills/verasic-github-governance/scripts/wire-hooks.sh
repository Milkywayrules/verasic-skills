#!/usr/bin/env bash
set -euo pipefail

# Wire verasic-github-governance hooks into this repository.
# Exit codes: 0 = wired (or already wired), 3 = manual step required, 1 = error

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "wire-hooks: must run inside a git repository" >&2
  exit 1
fi
REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

REPO_GOV_HOOKS=".github/verasic-governance/hooks"

for h in pre-push pre-commit; do
  if [[ ! -f "$REPO_GOV_HOOKS/$h" ]]; then
    echo "wire-hooks: $REPO_GOV_HOOKS/$h missing — run bootstrap-repo.sh" >&2
    exit 3
  fi
  chmod +x "$REPO_GOV_HOOKS/$h" 2>/dev/null || true
done

find_git_commits_hook() {
  local roots=(
    "$REPO_ROOT/.agents/skills/verasic-git-commits/hooks/commit-msg"
    "$REPO_ROOT/.cursor/skills/verasic-git-commits/hooks/commit-msg"
  )
  local p
  for p in "${roots[@]}"; do
    [[ -f "$p" ]] && { echo "$p"; return 0; }
  done
  return 1
}

relative_from_repo() {
  local abs="$1"
  if [[ "$abs" == "$REPO_ROOT/"* ]]; then
    echo "${abs#"$REPO_ROOT"/}"
  else
    echo "$abs"
  fi
}

ensure_commit_msg_in_lefthook() {
  local lefthook_file="$1"
  local hook_rel="$2"
  local run_cmd="      run: bash ${hook_rel} {1}"

  if grep -q 'verasic-git-commits/hooks/commit-msg' "$lefthook_file"; then
    sed -i "s|run: bash .*verasic-git-commits/hooks/commit-msg {1}|run: bash ${hook_rel} {1}|g" "$lefthook_file"
    echo "wire-hooks: updated commit-msg path in $lefthook_file"
    return 0
  fi

  if grep -q '^commit-msg:' "$lefthook_file"; then
    if grep -q '    verasic:' "$lefthook_file"; then
      sed -i "/    verasic:/,/      run:/ s|      run:.*|${run_cmd}|" "$lefthook_file"
    else
      sed -i "/^commit-msg:/a\\
  commands:\\
    verasic:\\
${run_cmd}" "$lefthook_file"
    fi
  else
    cat >> "$lefthook_file" <<EOF

commit-msg:
  commands:
    verasic:
${run_cmd}
EOF
  fi
  echo "wire-hooks: wired commit-msg in $lefthook_file → $hook_rel"
}

lefthook_file=""
for f in lefthook.yml .lefthook.yml lefthook.yaml .lefthook.yaml; do
  [[ -f "$f" ]] && lefthook_file="$f" && break
done

if [[ -n "$lefthook_file" ]]; then
  gov_ok=1
  grep -q '\.github/verasic-governance/hooks/pre-push' "$lefthook_file" || gov_ok=0
  grep -q '\.github/verasic-governance/hooks/pre-commit' "$lefthook_file" || gov_ok=0

  if [[ "$gov_ok" -eq 0 ]]; then
    if grep -q 'verasic-github-governance/hooks/' "$lefthook_file"; then
      cat <<EOF
wire-hooks: lefthook still references skill-local governance hooks — re-run bootstrap-repo.sh --force
wire-hooks: or update $lefthook_file to use:
  .github/verasic-governance/hooks/pre-commit
  .github/verasic-governance/hooks/pre-push
EOF
      exit 3
    fi
    cat <<EOF
wire-hooks: lefthook detected but missing repo-local governance hook commands ($lefthook_file)
wire-hooks: run bootstrap-repo.sh, then lefthook install
EOF
    exit 3
  fi

  commit_hook="$(find_git_commits_hook || true)"
  if [[ -n "$commit_hook" ]]; then
    commit_rel="$(relative_from_repo "$commit_hook")"
    chmod +x "$commit_hook" 2>/dev/null || true
    ensure_commit_msg_in_lefthook "$lefthook_file" "$commit_rel"
  else
    echo "wire-hooks: verasic-git-commits not in repo — commit-msg skipped (install skill + re-run wire-hooks.sh)"
  fi

  echo "wire-hooks: lefthook uses repo-local governance hooks ($lefthook_file)"
  if command -v lefthook >/dev/null 2>&1; then
    lefthook install >/dev/null 2>&1 || true
  else
    echo "wire-hooks: run 'lefthook install' when lefthook is available"
  fi
  exit 0
fi

# No lefthook — prefer bootstrap template
if [[ -f "$REPO_ROOT/lefthook.yml" ]]; then
  echo "wire-hooks: lefthook.yml present but not detected above — run bootstrap-repo.sh"
  exit 3
fi

# core.hooksPath fallback (governance hooks only — commit-msg needs separate wiring)
target="$REPO_GOV_HOOKS"

current="$(git config core.hooksPath 2>/dev/null || true)"
if [[ -n "$current" ]]; then
  if [[ "$current" == "$target" || "$current" == "$REPO_ROOT/$target" ]]; then
    echo "wire-hooks: already wired — core.hooksPath = $current"
    exit 0
  fi
  if [[ "$current" == *verasic-governance/hooks* || "$current" == *verasic-github-governance/hooks* ]]; then
    echo "wire-hooks: already wired via hooksPath — core.hooksPath = $current"
    exit 0
  fi
  scope="$(git config --show-scope core.hooksPath 2>/dev/null | awk '{print $1; exit}')"
  cat <<EOF
wire-hooks: core.hooksPath already set to '$current' (scope: ${scope:-unknown})
wire-hooks: prefer lefthook — run bootstrap-repo.sh and add lefthook.yml, then lefthook install
wire-hooks: or chain manually from existing hooks
EOF
  exit 3
fi

git_hooks_dir="$(git rev-parse --git-path hooks)"
existing=()
if [[ -d "$git_hooks_dir" ]]; then
  for h in "$git_hooks_dir"/*; do
    [[ -f "$h" && -x "$h" && "$h" != *.sample ]] && existing+=("$(basename "$h")")
  done
fi
if ((${#existing[@]} > 0)); then
  cat <<EOF
wire-hooks: existing git hooks (${existing[*]}) — use lefthook (bootstrap-repo.sh) instead of core.hooksPath
EOF
  exit 3
fi

cat <<EOF
wire-hooks: no lefthook.yml — run bootstrap-repo.sh first (recommended)
wire-hooks: fallback: git config core.hooksPath "$target"  (governance hooks only; wire commit-msg separately)
EOF
exit 3
