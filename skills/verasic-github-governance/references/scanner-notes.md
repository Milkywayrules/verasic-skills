# Scanner notes — verasic-github-governance

## Why scanners may flag this skill

- **Git / push blocking** — `hooks/pre-push` rejects pushes to protected default branches; bypass env var `VERASIC_GOVERNANCE_BYPASS` may look like a security escape hatch to heuristics.
- **GitHub API / IaC** — OpenTofu scaffold references `github_token`, branch protection, and repository settings.
- **Shell hook wiring** — Scripts modify `core.hooksPath`, `lefthook.yml`, and git hook directories.
- **CI workflow templates** — `.github/workflows/ci.yml` template under `templates/`.

## Mitigations

- **Soft-first model** — Default path is local hooks + CI culture; GitHub-side protection is plan-gated and documented in `plan-matrix.md`.
- **Explicit bypass** — `VERASIC_GOVERNANCE_BYPASS=1` is documented, auditable, and intended for break-glass only.
- **No secrets in skill** — OpenTofu uses `var.github_token` at apply time; skill ships templates only.
- **Idempotent bootstrap** — `bootstrap-repo.sh` copies templates; does not call GitHub APIs.
- **Doctor is read-only** — `doctor.sh` inspects local files and optional `gh` plan hints; no mutations.

See upstream [SECURITY.md](https://github.com/Milkywayrules/verasic-skills/blob/main/SECURITY.md).
