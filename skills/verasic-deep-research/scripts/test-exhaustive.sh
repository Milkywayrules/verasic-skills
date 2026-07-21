#!/usr/bin/env bash
set -euo pipefail

# Full non-AI verification gate for verasic-deep-research.
# Live Cursor harness UCs (UC-0–UC-7) are documented in references/use-cases.md
# and must be run separately in Cursor.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "== verasic-deep-research exhaustive (automated) =="
bash "$ROOT/scripts/test-regression.sh"
bash "$ROOT/scripts/test-exhaustive-protocol.sh"

REPO_ROOT="$(cd "$ROOT/../.." && pwd)"
if [[ -f "$REPO_ROOT/skills/verasic-init/scripts/test-regression.sh" ]]; then
  echo "== verasic-init regression (deep-research in manifest) =="
  bash "$REPO_ROOT/skills/verasic-init/scripts/test-regression.sh"
fi

echo "== automated gate: PASS =="
echo "Next: run live harness UCs UC-0 through UC-7 in Cursor (see references/use-cases.md)"
