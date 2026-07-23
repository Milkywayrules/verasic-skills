#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="$REPO_ROOT/skills/verasic-init/references/cursor-ux-manifest.txt"
CURSOR_ROOT="$REPO_ROOT/cursor"

pass=0
fail=0
ok()  { echo "PASS: $1"; pass=$((pass + 1)); }
bad() { echo "FAIL: $1"; fail=$((fail + 1)); }

[[ -f "$MANIFEST" ]] && ok "cursor-ux-manifest.txt exists" || bad "cursor-ux-manifest.txt exists"
[[ -d "$CURSOR_ROOT" ]] && ok "cursor/ exists" || bad "cursor/ exists"
[[ ! -d "$REPO_ROOT/skills/verasic-init/assets" ]] && ok "no bundled assets/ duplicate" || bad "skills/verasic-init/assets/ must not exist (use upstream fetch)"

mapfile -t listed < <(grep -v '^#' "$MANIFEST" | grep -v '^[[:space:]]*$' | sort)
mapfile -t actual < <(find "$CURSOR_ROOT" -type f | sed "s|^$CURSOR_ROOT/||" | sort)

if [[ "${#listed[@]}" -eq 0 ]]; then
  bad "manifest lists no files"
else
  ok "manifest lists ${#listed[@]} files"
fi

missing=()
extra=()
for f in "${listed[@]}"; do
  [[ -f "$CURSOR_ROOT/$f" ]] || missing+=("$f")
done
for f in "${actual[@]}"; do
  seen=false
  for m in "${listed[@]}"; do
    [[ "$m" == "$f" ]] && seen=true && break
  done
  $seen || extra+=("$f")
done

((${#missing[@]} == 0)) && ok "manifest paths exist under cursor/" || bad "manifest paths exist under cursor/ (${#missing[@]} missing)"
((${#extra[@]} == 0)) && ok "cursor/ has no unlisted files" || bad "cursor/ has no unlisted files (${#extra[@]} extra: ${extra[*]})"

echo "---"
echo "check-cursor-ux-manifest: $pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
