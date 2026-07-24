#!/usr/bin/env bash
set -euo pipefail

# Print merged Verasic config as JSON.
# Resolution (first file found wins as primary; merged over defaults):
#   verasic.config.ts → .verasicrc.jsonc → .verasicrc.json → defaults
# Invoke-phrase overrides are applied by orchestrators, not this script.

ROOT="${VERASIC_REPO_ROOT:-}"
if [[ -z "$ROOT" ]]; then
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    ROOT="$(git rev-parse --show-toplevel)"
  else
    ROOT="$(pwd)"
  fi
fi

python3 - "$ROOT" <<'PY'
import json
import re
import sys
from pathlib import Path

root = Path(sys.argv[1])

defaults = {
    "artifacts": {
        "trackedDir": "verasic",
        "localDir": ".verasic",
        "indexLocal": False,
    },
    "securityReview": {
        "scanner": "off",
        "strictness": "strict",
        "report": {
            "write": True,
            "promote": "both",
        },
    },
}


def deep_merge(base, overlay):
    if not isinstance(overlay, dict):
        return overlay
    out = dict(base)
    for key, value in overlay.items():
        if key in out and isinstance(out[key], dict) and isinstance(value, dict):
            out[key] = deep_merge(out[key], value)
        else:
            out[key] = value
    return out


def strip_jsonc(text: str) -> str:
    out = []
    i = 0
    in_str = False
    esc = False
    while i < len(text):
        ch = text[i]
        if in_str:
            out.append(ch)
            if esc:
                esc = False
            elif ch == "\\":
                esc = True
            elif ch == '"':
                in_str = False
            i += 1
            continue
        if ch == '"':
            in_str = True
            out.append(ch)
            i += 1
            continue
        if ch == "/" and i + 1 < len(text):
            nxt = text[i + 1]
            if nxt == "/":
                i += 2
                while i < len(text) and text[i] not in "\n\r":
                    i += 1
                continue
            if nxt == "*":
                i += 2
                while i + 1 < len(text) and text[i : i + 2] != "*/":
                    i += 1
                i = min(i + 2, len(text))
                continue
        out.append(ch)
        i += 1
    return "".join(out)


def ts_object_to_json(obj_text: str) -> dict:
    text = strip_jsonc(obj_text)
    text = re.sub(r"'([^'\\]*(?:\\.[^'\\]*)*)'", r'"\1"', text)
    text = re.sub(r"(\{|,|\s)([A-Za-z_][A-Za-z0-9_]*)\s*:", r'\1"\2":', text)
    text = re.sub(r",(\s*[}\]])", r"\1", text)
    text = re.sub(r"\btrue\b", "true", text, flags=re.I)
    text = re.sub(r"\bfalse\b", "false", text, flags=re.I)
    return json.loads(text)


def parse_verasic_ts(path: Path):
    text = path.read_text(encoding="utf-8")
    patterns = [
        r"const\s+config\s*:\s*[^=]+=\s*(\{.*?\})\s*;",
        r"export\s+default\s+(\{.*?\})\s*;",
    ]
    for pat in patterns:
        m = re.search(pat, text, re.DOTALL)
        if m:
            return ts_object_to_json(m.group(1))
    raise ValueError("could not find config object in verasic.config.ts")


def load_json_file(path: Path):
    raw = path.read_text(encoding="utf-8")
    if path.suffix == ".jsonc":
        raw = strip_jsonc(raw)
    data = json.loads(raw)
    if not isinstance(data, dict):
        raise ValueError(f"{path.name} must be a JSON object")
    return data


config = dict(defaults)
source = "defaults"

ts = root / "verasic.config.ts"
jsonc = root / ".verasicrc.jsonc"
jsonf = root / ".verasicrc.json"

try:
    if ts.is_file():
        try:
            config = deep_merge(defaults, parse_verasic_ts(ts))
            source = "verasic.config.ts"
        except ValueError:
            pass
    if source == "defaults" and jsonc.is_file():
        config = deep_merge(defaults, load_json_file(jsonc))
        source = ".verasicrc.jsonc"
    elif source == "defaults" and jsonf.is_file():
        config = deep_merge(defaults, load_json_file(jsonf))
        source = ".verasicrc.json"
except json.JSONDecodeError as exc:
    print(f"resolve-config: invalid config — {exc}", file=sys.stderr)
    sys.exit(1)

print(json.dumps(config, indent=2, sort_keys=True))
PY
