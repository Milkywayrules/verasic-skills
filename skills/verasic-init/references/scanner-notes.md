# Scanner notes — verasic-init

## Why scanners may flag this skill

- **Network (`curl`)** — `--check-updates` fetches upstream `VERSION` files from
  `raw.githubusercontent.com` (read-only, 5–10 s timeout). No POST, no auth.
- **Orchestration of sensitive wiring** — Init invokes `bootstrap.sh` and `wire-hook.sh`,
  which touch credentials templates and git hooks. Static analysis often treats
  "calls script that touches secrets/hooks" as high risk.
- **Integrity hashing** — Reads and compares SHA-256 of skill files; some tools classify
  hash verification loops as tamper/evasion patterns.
- **Git repository required** — Runs `git rev-parse` and operates from repo root.

## Mitigations

- **Detect-only integrity** — Hash mismatch reports `modified:` / `broken install`; never
  auto-restores or overwrites local files.
- **Repo-local skills only** — Never wires from an external invoker checkout.
- **Read-only update check** — `--check-updates` and `--list` modify nothing.
- **No secret output** — Wire scripts must not print token values; init relays their stdout
  verbatim but does not read `.github-agent.local`.
- **Idempotent** — Safe to re-run; cherry-pick with `--skills`.

See upstream [SECURITY.md](https://github.com/Milkywayrules/verasic-skills/blob/v0.1.2/SECURITY.md).
