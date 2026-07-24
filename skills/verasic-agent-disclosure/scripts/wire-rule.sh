#!/usr/bin/env bash
set -euo pipefail

# Copy verasic-agent-disclosure rule into this repository's .cursor/rules/.
# Exit codes: 0 = wired (or already wired), 1 = error

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "wire-rule: must run inside a git repository" >&2
  exit 1
fi
REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCE="$SKILL_ROOT/assets/verasic-agent-disclosure.mdc"
TARGET="$REPO_ROOT/.cursor/rules/verasic-agent-disclosure.mdc"
LEGACY="$REPO_ROOT/.cursor/rules/no-expose-agent-internals.mdc"

if [[ ! -f "$SOURCE" ]]; then
  echo "wire-rule: assets/verasic-agent-disclosure.mdc not found — broken install" >&2
  exit 1
fi

mkdir -p "$REPO_ROOT/.cursor/rules"

if [[ -f "$TARGET" ]] && cmp -s "$SOURCE" "$TARGET"; then
  echo "wire-rule: already wired — $TARGET matches skill asset"
else
  cp "$SOURCE" "$TARGET"
  echo "wire-rule: copied → $TARGET"
fi

if [[ -f "$LEGACY" ]]; then
  rm "$LEGACY"
  echo "wire-rule: removed legacy no-expose-agent-internals.mdc (migrate to verasic-agent-disclosure)"
fi

exit 0
