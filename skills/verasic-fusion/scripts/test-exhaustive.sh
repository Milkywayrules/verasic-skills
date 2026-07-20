#!/usr/bin/env bash
set -euo pipefail

# Full non-AI verification gate for verasic-fusion.
# Live Cursor harness UCs (UC-0–UC-14 with subagents) are documented in
# references/use-cases.md and must be run separately in Cursor.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "== verasic-fusion exhaustive (automated) =="
bash "$ROOT/scripts/test-regression.sh"
bash "$ROOT/scripts/test-exhaustive-protocol.sh"

REPO_ROOT="$(cd "$ROOT/../.." && pwd)"
if [[ -f "$REPO_ROOT/skills/verasic-init/scripts/test-regression.sh" ]]; then
  echo "== verasic-init regression (fusion in manifest) =="
  bash "$REPO_ROOT/skills/verasic-init/scripts/test-regression.sh"
fi

echo "== automated gate: PASS =="
echo "Next: run live harness UCs UC-0 through UC-14 in Cursor (see references/use-cases.md)"
