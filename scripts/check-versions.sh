#!/usr/bin/env bash
set -euo pipefail

# Strict release manifest gate: versions.lock must match every manifest skill VERSION.
# VERSION is hashed in integrity.sha256 — bumping version requires refresh-integrity.sh.

REPO_ROOT="${VERASIC_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
MANIFEST="$REPO_ROOT/skills/verasic-init/manifest.txt"
LOCK_FILE="$REPO_ROOT/versions.lock"
SKILLS_DIR="$REPO_ROOT/skills"

pass=0
fail=0

ok()  { echo "PASS: $1"; pass=$((pass + 1)); }
bad() { echo "FAIL: $1"; fail=$((fail + 1)); }

semver_ok() {
  [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

read_skill_version() {
  local skill_dir="$1"
  local vfile="$skill_dir/VERSION"
  if [[ ! -f "$vfile" ]]; then
    echo ""
    return 1
  fi
  tr -d '[:space:]' < "$vfile"
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

parse_lock() {
  local line key val
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"
    line="${line//$'\r'/}"
    [[ -z "${line//[[:space:]]/}" ]] && continue
    key="${line%%=*}"
    val="${line#*=}"
    key="${key//[[:space:]]/}"
    val="${val//[[:space:]]/}"
    printf '%s=%s\n' "$key" "$val"
  done < "$LOCK_FILE"
}

assert_integrity_current() {
  local skill_dir="$1" name="$2"
  local integrity_file="$skill_dir/integrity.txt"
  local hash_file="$skill_dir/integrity.sha256"
  local line stripped hash_tmp

  [[ -f "$integrity_file" ]] || { bad "$name integrity.txt missing"; return; }
  [[ -f "$hash_file" ]] || { bad "$name integrity.sha256 missing"; return; }

  hash_tmp="$(mktemp)"
  while IFS= read -r line || [[ -n "$line" ]]; do
    stripped="${line%%#*}"
    stripped="${stripped//[[:space:]]/}"
    [[ -z "$stripped" ]] && continue
    [[ "$stripped" == "integrity.sha256" ]] && continue
    if [[ ! -f "$skill_dir/$stripped" ]]; then
      bad "$name integrity path missing: $stripped"
      rm -f "$hash_tmp"
      return
    fi
    (cd "$skill_dir" && sha256sum "$stripped") >> "$hash_tmp"
  done < "$integrity_file"

  if cmp -s "$hash_tmp" "$hash_file"; then
    ok "$name integrity.sha256 current (includes VERSION hash)"
  else
    bad "$name integrity.sha256 stale — run: bash scripts/refresh-integrity.sh $name"
  fi
  rm -f "$hash_tmp"
}

# --- manifest + lock presence ---
if [[ -f "$MANIFEST" ]]; then ok 'manifest.txt exists'; else bad 'manifest.txt missing'; fi
if [[ -f "$LOCK_FILE" ]]; then ok 'versions.lock exists'; else bad 'versions.lock missing'; fi

declare -A LOCK=()
if [[ -f "$LOCK_FILE" ]]; then
  while IFS= read -r entry; do
    key="${entry%%=*}"
    val="${entry#*=}"
    LOCK["$key"]="$val"
  done < <(parse_lock)
fi

declare -A SEEN_LOCK=()
mapfile -t MANIFEST_LIST < <(manifest_skills | sort)

for name in "${MANIFEST_LIST[@]}"; do
  skill_dir="$SKILLS_DIR/$name"
  if [[ ! -d "$skill_dir" ]]; then
    bad "manifest skill directory missing: $name"
    continue
  fi
  ok "manifest skill exists: $name"

  ver="$(read_skill_version "$skill_dir" || true)"
  if [[ -z "$ver" ]]; then
    bad "$name VERSION missing"
    continue
  fi
  if semver_ok "$ver"; then
    ok "$name VERSION semver ($ver)"
  else
    bad "$name VERSION not semver: $ver"
  fi

  if [[ -n "${LOCK[$name]+x}" ]]; then
    SEEN_LOCK["$name"]=1
    if [[ "${LOCK[$name]}" == "$ver" ]]; then
      ok "$name versions.lock matches VERSION ($ver)"
    else
      bad "$name versions.lock drift: lock=${LOCK[$name]} VERSION=$ver"
    fi
  else
    bad "$name missing from versions.lock"
  fi

  assert_integrity_current "$skill_dir" "$name"
done

# lock entries not in manifest
for key in "${!LOCK[@]}"; do
  if [[ -z "${SEEN_LOCK[$key]+x}" ]]; then
    bad "versions.lock orphan entry (not in manifest): $key"
  fi
done

# lock file order must match manifest order (stable release manifest)
mapfile -t MANIFEST_ORDER < <(manifest_skills)
mapfile -t LOCK_ORDER < <(parse_lock | while IFS= read -r entry; do echo "${entry%%=*}"; done)
if [[ "${#LOCK_ORDER[@]}" -eq "${#MANIFEST_ORDER[@]}" ]]; then
  order_ok=true
  for i in "${!MANIFEST_ORDER[@]}"; do
    if [[ "${LOCK_ORDER[$i]}" != "${MANIFEST_ORDER[$i]}" ]]; then
      order_ok=false
      break
    fi
  done
  if $order_ok; then
    ok 'versions.lock order matches manifest.txt'
  else
    bad 'versions.lock order drift — reorder to match manifest.txt'
  fi
else
  bad "versions.lock count (${#LOCK_ORDER[@]}) != manifest (${#MANIFEST_ORDER[@]})"
fi

echo "---"
echo "check-versions: $pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
