#!/usr/bin/env bash
set -euo pipefail

# Propagate root bundle.tag to all generated @vX.Y.Z pin sites (maintainers + release-bump.sh).

REPO_ROOT="${VERASIC_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
BUNDLE_FILE="$REPO_ROOT/bundle.tag"

if [[ ! -f "$BUNDLE_FILE" ]]; then
  echo "sync-bundle-tag: missing $BUNDLE_FILE" >&2
  exit 1
fi

tag="$(tr -d '[:space:]' < "$BUNDLE_FILE")"
[[ -n "$tag" ]] || { echo "sync-bundle-tag: empty $BUNDLE_FILE" >&2; exit 1; }
[[ "$tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || {
  echo "sync-bundle-tag: expected vX.Y.Z in $BUNDLE_FILE, got: $tag" >&2
  exit 1
}

pin="@${tag}"

PIN_FILES=(
  "$REPO_ROOT/skills/verasic-github-governance/SKILL.md"
  "$REPO_ROOT/skills/verasic-github-governance-init/SKILL.md"
  "$REPO_ROOT/cursor/rules/verasic-github-governance.mdc"
)

for file in "${PIN_FILES[@]}"; do
  if [[ ! -f "$file" ]]; then
    echo "sync-bundle-tag: missing ${file#"$REPO_ROOT"/}" >&2
    exit 1
  fi
  sed -i "s/@v[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*/${pin}/g" "$file"
done

MAP="$REPO_ROOT/references/verasic-cursor-map.md"
if [[ -f "$MAP" ]]; then
  sed -i "s/Bundle \*\*v[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\*\*/Bundle **${tag}**/" "$MAP"
  sed -i "s|CHANGELOG.md) v[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*|CHANGELOG.md) ${tag#v}|" "$MAP"
fi

echo "sync-bundle-tag: ${tag} → ${#PIN_FILES[@]} pin files + verasic-cursor-map.md"
