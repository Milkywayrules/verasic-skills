# Bundled scanner rules (optional)

Ship licensed rule packs here for offline deterministic scans:

- `opengrep/` — OpenGrep rules (used when `scanner` is `opengrep` or `auto`)
- `semgrep/` — Semgrep rules (required when `scanner` is `semgrep`)

**Until bundled packs ship in a future release**, `semgrep` and `opengrep` modes expect **user-supplied rules** under `rules/semgrep/` or `rules/opengrep/`. Without them:

- **Semgrep** — `run-scanner.sh` emits `Scanner: skipped (semgrep failed)` on stderr; the LLM review continues (not a silent no-op).
- **OpenGrep** — falls back to `-f p/default`, which may fetch registry rules (network); prefer shipping `rules/opengrep/` for offline use.

Default config keeps `scanner: 'off'`.
