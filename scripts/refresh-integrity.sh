#!/usr/bin/env bash
set -euo pipefail

# Regenerate integrity.sha256 for one skill or all manifest skills.
# Run after any change to files listed in integrity.txt (including VERSION).

usage() {
  cat <<'EOF'
refresh-integrity — regenerate per-skill integrity.sha256

Usage:
  refresh-integrity.sh <skill-name>   one manifest skill
  refresh-integrity.sh --all          every skill in manifest.txt
  refresh-integrity.sh --help

Example:
  bash scripts/refresh-integrity.sh verasic-deep-research
EOF
}

REPO_ROOT="${VERASIC_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
MANIFEST="$REPO_ROOT/skills/verasic-init/manifest.txt"

refresh_one() {
  local name="$1"
  local skill_dir="$REPO_ROOT/skills/$name"
  local integrity_file="$skill_dir/integrity.txt"
  local hash_file="$skill_dir/integrity.sha256"

  if [[ ! -d "$skill_dir" ]]; then
    echo "refresh-integrity: skill not found: $name" >&2
    return 1
  fi
  if [[ ! -f "$integrity_file" ]]; then
    echo "refresh-integrity: missing integrity.txt for $name" >&2
    return 1
  fi

  local line stripped
  > "$hash_file"
  while IFS= read -r line || [[ -n "$line" ]]; do
    stripped="${line%%#*}"
    stripped="${stripped//[[:space:]]/}"
    [[ -z "$stripped" ]] && continue
    [[ "$stripped" == "integrity.sha256" ]] && continue
    if [[ ! -f "$skill_dir/$stripped" ]]; then
      echo "refresh-integrity: missing path in integrity.txt: $name/$stripped" >&2
      return 1
    fi
    (cd "$skill_dir" && sha256sum "$stripped") >> "$hash_file"
  done < "$integrity_file"

  echo "refreshed: skills/$name/integrity.sha256"
}

manifest_skills() {
  local line name
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"
    line="${line//$'\r'/}"
    [[ -z "${line//[[:space:]]/}" ]] && continue
    name="${line%%|*}"
    name="${name//[[:space:]]/}"
    printf '%s\n' "$name"
  done < "$MANIFEST"
}

TARGET="${1:-}"
case "$TARGET" in
  --help|-h|'')
    usage
    exit 0
    ;;
  --all)
    while IFS= read -r skill; do
      refresh_one "$skill"
    done < <(manifest_skills)
    ;;
  *)
    refresh_one "$TARGET"
    ;;
esac
