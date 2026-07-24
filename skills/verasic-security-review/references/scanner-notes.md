# Scanner notes — verasic-security-review

## Why scanners may flag this skill

- **Bundled Critical (Snyk)** — Package-level scans flag the entire skills bundle; security-review
  itself has no credential or hook wiring scripts.
- **Security checklist content** — `checklists/security.md` discusses injection, secrets,
  authz, and deserialization — keywords that trigger static secret/vuln classifiers.
- **Git diff access** — Protocol reads branch and uncommitted diffs plus full file context;
  scanners may classify broad file/git access as data exfil patterns.
- **Subprocess scanner invoke** — Optional OpenGrep/Semgrep runs on changed paths; static
  analysis tools may flag subprocess + file read patterns.
- **Subagent spawn** — Cursor Task subagent runs review in isolated context.

## Mitigations

- **Read-only** — No fixes, commits, or network calls from the skill itself (scanner uses local binary only).
- **High-confidence filter** — Findings below 6/10 omitted; strict default 8 for Heuristic.
- **User-triggered** — Runs on explicit security review request.
- **Scanner optional** — Default `off`; skip line when binary missing — never blocks review.
- **Pinned rules** — Prefer skill-bundled or `-f` local rules; no arbitrary network rule fetch at runtime.
- **Timeout** — 120s cap on scanner subprocess.

## OpenGrep vs Semgrep

| Need | Pick |
| --- | --- |
| Zero install | `off` |
| Best free OSS taint | `opengrep` or `auto` |
| Already on Semgrep / Guardian | `semgrep` |
| Try both | `auto` (OpenGrep first, then Semgrep) |

Install references:

```bash
curl -fsSL https://raw.githubusercontent.com/opengrep/opengrep/main/install.sh | bash
pipx install semgrep   # or brew, docker
```

Rule packs: verify license before bundling under `rules/opengrep/`. Semgrep `--config auto` uses Semgrep-maintained rules (Semgrep Rules License applies).

Neither scanner replaces LLM STRIDE — authz, business logic, and prompt-injection in diffs still need the reviewer.

See upstream [SECURITY.md](https://github.com/Milkywayrules/verasic-skills/blob/main/SECURITY.md).
