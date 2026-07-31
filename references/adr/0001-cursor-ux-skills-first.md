# ADR 0001: Cursor UX skills-first

**Status:** Accepted  
**Date:** 2026-07  
**Bundle:** v0.2.0

## Context

Verasic harness skills shipped with nine `cursor/commands/*.md` files plus overlapping orchestration in `SKILL.md`. Users saw duplicate slash entries (command vs skill), and maintainers duplicated spawn blocks across commands and skills.

Skill folders also used inconsistent names (`verasic-security-review`, `verasic-github-env`, monolithic `verasic-git-commits`).

A repo config skill (`verasic-config`) scaffolded shared paths but added install complexity before a stable kit existed.

## Decision

1. **Delete all `cursor/commands/`** — merge orchestration into target `SKILL.md` files.
2. **Slash = skill folder name** — canonical map in [verasic-cursor-map.md](../verasic-cursor-map.md).
3. **Rename skills** — secbot, github-cli-init, git-commits-convention + git-commits-audit split.
4. **Rename subagents and rules** — `-reviewer`, `-auditor`, `-governor`; convention/cli-env rule names.
5. **Remove `verasic-config`** — secbot inlines defaults; artifact dirs mkdir on first write.
6. **`disable-model-invocation: true`** on workflow skills (except convention rule skill).

## Consequences

### Positive

- Single orchestration source per workflow (`SKILL.md`).
- Clear naming: bugbot/secbot, convention/audit, cli-init/governor.
- Init manifest and CI simplify (8 cursor files, no command fetch).

### Negative / deferred

- **No user config file** until a future kit ships (npm package / Verasic Kit / Harness Kit — **TBD, not built**).
- Breaking change for every retired slash (see CHANGELOG v0.2.2).
- Runtime Cursor slash menu behavior is not CI-testable; regressions cover file parity only.

## Retired names (reference only)

| Retired                            | Replacement                      |
| ---------------------------------- | -------------------------------- |
| `/verasic-review`                  | `/verasic-bugbot`                |
| `/verasic-security-review`         | `/verasic-secbot`                |
| `verasic-security-review` (folder) | `verasic-secbot`                 |
| `verasic-github-env`               | `verasic-github-cli-init`        |
| `verasic-git-commits`              | `verasic-git-commits-convention` |
| `verasic-config`                   | removed                          |
| `cursor/commands/`                 | removed                          |

## Related

- [cursor-skills-ux.md](../cursor-skills-ux.md)
- [verasic-naming.md](../verasic-naming.md)
- [CHANGELOG.md](../../CHANGELOG.md) v0.2.2
