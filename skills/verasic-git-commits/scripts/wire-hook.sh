#!/usr/bin/env bash
set -euo pipefail

# Wire the deterministic verasic commit-msg hook into this repository.
# Exit codes: 0 = wired (or already wired), 3 = manual step required, 1 = error.

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "wire-hook: must run inside a git repository" >&2
  exit 1
fi
REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOKS_DIR="$SKILL_ROOT/hooks"

if [[ ! -f "$HOOKS_DIR/commit-msg" ]]; then
  echo "wire-hook: hooks/commit-msg not found in skill — broken install" >&2
  exit 1
fi
chmod +x "$HOOKS_DIR/commit-msg" 2>/dev/null || true

target="$HOOKS_DIR"
if [[ "$HOOKS_DIR" == "$REPO_ROOT/"* ]]; then
  target="${HOOKS_DIR#"$REPO_ROOT"/}"
fi

# Lefthook manages git hooks itself — never override it, hand the user the snippet.
lefthook_file=""
for f in lefthook.yml .lefthook.yml lefthook.yaml .lefthook.yaml lefthook.json lefthook.toml; do
  [[ -f "$f" ]] && lefthook_file="$f" && break
done
if [[ -n "$lefthook_file" ]]; then
  if grep -q 'verasic-git-commits/hooks/commit-msg' "$lefthook_file"; then
    echo "wire-hook: lefthook already runs the verasic commit-msg hook ($lefthook_file)"
    exit 0
  fi
  cat <<EOF
wire-hook: lefthook detected — add this commit-msg command to $lefthook_file (YAML shown; adapt for json/toml), then run 'lefthook install':

commit-msg:
  commands:
    verasic:
      run: bash "$target/commit-msg" {1}
EOF
  exit 3
fi

# check every scope — overriding a global/system hooksPath locally would
# silently disable whatever hook manager set it
current="$(git config core.hooksPath 2>/dev/null || true)"
if [[ -n "$current" ]]; then
  if [[ "$current" == "$target" || "$current" == "$HOOKS_DIR" ]]; then
    echo "wire-hook: already wired — core.hooksPath = $current"
    exit 0
  fi
  if [[ "$current" == *verasic-git-commits/hooks ]]; then
    if [[ -f "$current/commit-msg" || -f "$REPO_ROOT/$current/commit-msg" ]]; then
      echo "wire-hook: already wired via a different install root — core.hooksPath = $current"
      exit 0
    fi
    cat <<EOF
wire-hook: core.hooksPath points at a stale verasic install ('$current' has no commit-msg)
wire-hook: re-point it — git config core.hooksPath "$target"
EOF
    exit 3
  fi
  scope="$(git config --show-scope core.hooksPath 2>/dev/null | awk '{print $1; exit}')"
  cat <<EOF
wire-hook: core.hooksPath already set to '$current' (scope: ${scope:-unknown} — husky or custom hooks?)
wire-hook: chain manually — call 'bash "$target/commit-msg" "\$1"' from that directory's commit-msg hook
EOF
  exit 3
fi

# Raw hooks in the git hooks dir would be silently disabled by core.hooksPath.
git_hooks_dir="$(git rev-parse --git-path hooks)"
existing=()
if [[ -d "$git_hooks_dir" ]]; then
  for h in "$git_hooks_dir"/*; do
    [[ -f "$h" && -x "$h" && "$h" != *.sample ]] && existing+=("$(basename "$h")")
  done
fi
if ((${#existing[@]} > 0)); then
  cat <<EOF
wire-hook: existing git hooks found (${existing[*]}) — setting core.hooksPath would disable them
wire-hook: chain manually — call 'bash "$target/commit-msg" "\$1"' from $git_hooks_dir/commit-msg
EOF
  exit 3
fi

git config core.hooksPath "$target"
echo "wire-hook: core.hooksPath → $target"
echo "wire-hook: commit-msg hook active — strips co-authored/AI trailers, rejects style breaks"
echo "wire-hook: note — a relative hooksPath does not follow into 'git worktree' checkouts; re-run init inside a worktree if you commit from one"
