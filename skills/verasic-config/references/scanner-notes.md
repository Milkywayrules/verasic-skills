# Scanner notes — verasic-config

## Why scanners may flag this skill

- **Config paths and gitignore mutation** — `scaffold-artifacts.sh` appends
  `.verasic/` to `.gitignore` and optionally `.cursorignore`. Heuristics flag
  scripts that modify ignore files.
- **JSON merge / env handling** — `resolve-config.sh` reads `.verasicrc.json`
  and prints merged JSON to stdout; looks like credential or config exfil to
  some engines.
- **Security scanner keys** — Schema documents `semgrep`, `opengrep`, and
  `auto` scanner modes; static analysis tools may classify as offensive tooling.
- **Artifact directories** — Creates `verasic/` and gitignored `.verasic/`
  trees; may resemble staging or exfil paths.

## Mitigations

- **No secrets in config** — Templates and docs state config holds paths and
  tool preferences only; PATs and tokens stay in tier-separated credential files.
- **Gitignored local root** — `localDir` defaults to `.verasic/`; scaffold
  ensures repo `.gitignore` covers it idempotently.
- **Idempotent wire** — Scaffold never overwrites existing `verasic.config.ts`,
  `.verasicrc.json`, or `.verasicrc.jsonc`.
- **Safe JSON parse** — `resolve-config.sh` uses `python3` `json.load`; no
  shell `eval` of config files.
- **Strict JSON contract** — `.verasicrc.json` is one JSON object; JSONL is
  reserved for append-only run logs under `localDir`, not config.

See upstream [SECURITY.md](https://github.com/Milkywayrules/verasic-skills/blob/main/SECURITY.md).
