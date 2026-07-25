#!/usr/bin/env bash
set -euo pipefail

# Set bundle.tag, sync generated pins, run bundle gates. Does not commit or git tag.

REPO_ROOT="${VERASIC_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

usage() {
  echo "usage: bash scripts/release-bump.sh vX.Y.Z" >&2
  exit 2
}

[[ $# -eq 1 ]] || usage

tag="$1"
tag="${tag#v}"
tag="v${tag}"
[[ "$tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || usage

printf '%s\n' "$tag" > "$REPO_ROOT/bundle.tag"
bash "$REPO_ROOT/scripts/sync-bundle-tag.sh"
bash "$REPO_ROOT/scripts/check-bundle-pins.sh"

echo
echo "release-bump: $tag written — bump changed skill VERSION files, refresh integrity, test-all, then commit and git tag $tag"
