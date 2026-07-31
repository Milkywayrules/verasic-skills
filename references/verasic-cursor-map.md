# Verasic Cursor slash map (canonical)

**Single source of truth** for slash entries, skill folders, subagents, and always-applied rules.
README and skill docs link here — they do not duplicate this table.

Bundle **v0.2.5** — skills-first; no `cursor/commands/`.

## Skills (slash = folder name)

| Slash                             | Skill folder                     | Subagent                     | Always-applied rule        | Notes                            |
| --------------------------------- | -------------------------------- | ---------------------------- | -------------------------- | -------------------------------- |
| `/verasic-bugbot`                 | `verasic-bugbot`                 | `verasic-bugbot-reviewer`    | —                          | Code review on git diff          |
| `/verasic-secbot`                 | `verasic-secbot`                 | `verasic-secbot-reviewer`    | —                          | STRIDE security review           |
| `/verasic-fusion`                 | `verasic-fusion`                 | —                            | —                          | Multi-model fusion               |
| `/verasic-deep-research`          | `verasic-deep-research`          | —                            | —                          | Ledger-backed research           |
| `/verasic-git-commits-audit`      | `verasic-git-commits-audit`      | `verasic-git-commit-auditor` | —                          | Pre-push commit audit            |
| `/verasic-agent-disclosure`       | `verasic-agent-disclosure`       | —                            | `verasic-agent-disclosure` | Red-team via SKILL orchestration |
| `/verasic-github-cli-init`        | `verasic-github-cli-init`        | —                            | `verasic-github-cli-env`   | GitHub CLI bootstrap             |
| `/verasic-github-governance-init` | `verasic-github-governance-init` | —                            | —                          | Governance factory (plan-first)  |
| `/verasic-init`                   | `verasic-init`                   | —                            | —                          | Repo wiring orchestrator         |

## Convention skill (no slash workflow)

| Skill folder                     | Rule                             | Notes                                       |
| -------------------------------- | -------------------------------- | ------------------------------------------- |
| `verasic-git-commits-convention` | `verasic-git-commits-convention` | Hook + message spec; audit is sibling skill |

## Governance skill (protocol + doctor)

| Skill folder                | Subagent                  | Rule                        | Notes                                     |
| --------------------------- | ------------------------- | --------------------------- | ----------------------------------------- |
| `verasic-github-governance` | `verasic-github-governor` | `verasic-github-governance` | Factory invoked via governance-init skill |

## Subagent slugs (direct invoke, optional)

| Slash / spawn name           | Agent file                                    | Skill                       |
| ---------------------------- | --------------------------------------------- | --------------------------- |
| `verasic-bugbot-reviewer`    | `cursor/agents/verasic-bugbot-reviewer.md`    | `verasic-bugbot`            |
| `verasic-secbot-reviewer`    | `cursor/agents/verasic-secbot-reviewer.md`    | `verasic-secbot`            |
| `verasic-git-commit-auditor` | `cursor/agents/verasic-git-commit-auditor.md` | `verasic-git-commits-audit` |
| `verasic-github-governor`    | `cursor/agents/verasic-github-governor.md`    | `verasic-github-governance` |

## Install layouts

| Profile             | Skills path                        | Cursor UX path                                |
| ------------------- | ---------------------------------- | --------------------------------------------- |
| `cursor` (setup.sh) | `.cursor/skills/`                  | `.cursor/agents/`, `.cursor/rules/`           |
| `cursor-hybrid`     | `.agents/skills/`                  | `.cursor/agents/`, `.cursor/rules/` (fetched) |
| `agent`             | `.agents/skills/` or agent default | none                                          |

See [cursor-skills-ux.md](cursor-skills-ux.md) and [skills/verasic-init/references/install-profiles.md](../skills/verasic-init/references/install-profiles.md).

## Retired v0.1.x slugs (do not use)

| Retired                        | Replacement                                          |
| ------------------------------ | ---------------------------------------------------- |
| `/verasic-review`              | `/verasic-bugbot`                                    |
| `/verasic-security-review`     | `/verasic-secbot`                                    |
| `/verasic-audit-commits`       | `/verasic-git-commits-audit`                         |
| `/verasic-setup-github`        | `/verasic-github-cli-init`                           |
| `/verasic-governance-factory`  | `/verasic-github-governance-init`                    |
| `/verasic-disclosure-red-team` | `/verasic-agent-disclosure` (orchestration in SKILL) |

Full migration notes: [CHANGELOG.md](../CHANGELOG.md) 0.2.4.
