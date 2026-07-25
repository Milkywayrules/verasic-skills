# Verasic naming conventions

Grammar for skill folders, Cursor UX files, and slash entries. Locked for v0.2.0.

## Principles

1. **Skill folder name = primary slash** — `/verasic-bugbot` maps to `skills/verasic-bugbot/`.
2. **Subagent suffix `-reviewer`, `-auditor`, `-governor`** — distinct from the workflow skill name.
3. **Split by concern** — convention vs audit, bugbot vs secbot, governance vs governance-init.
4. **No verb-only command files** — retired in v0.2.0; verbs live in skill descriptions, not separate command paths.

## Worked examples

### Bugbot vs secbot

| Name | Kind | Why |
| --- | --- | --- |
| `verasic-bugbot` | skill | Product name; general bug hunting |
| `verasic-bugbot-reviewer` | subagent | Isolated review context |
| `verasic-secbot` | skill | Security depth (STRIDE); shorter than `security-review` |
| `verasic-secbot-reviewer` | subagent | Paired with secbot, not bugbot |

Cross-tip: bugbot may suggest `/verasic-secbot` for auth/crypto/webhook/input diffs; secbot may suggest `/verasic-bugbot` when no security surface.

### Git commits: convention vs audit

| Name | Kind | Why |
| --- | --- | --- |
| `verasic-git-commits-convention` | skill + rule | Write path: message style + hook |
| `verasic-git-commits-audit` | skill | Read path: history audit before push/PR |
| `verasic-git-commit-auditor` | subagent | Spawn target for audit skill |

The convention skill keeps protocols (`conventions.md`, `commit-protocol.md`, `audit-protocol.md`). The audit skill is thin orchestration only.

### GitHub: cli-init vs governance vs governor

| Name | Kind | Why |
| --- | --- | --- |
| `verasic-github-cli-init` | skill | Bootstrap `gh` auth (was `verasic-github-env`) |
| `verasic-github-cli-env` | rule | Always-applied digest before `gh` mutations |
| `verasic-github-governance` | skill | CI, hooks, doctor, protocols |
| `verasic-github-governance-init` | skill | Plan-first factory orchestrator |
| `verasic-github-governor` | subagent | Governance mutations via subagent |

### Init

| Name | Kind | Why |
| --- | --- | --- |
| `verasic-init` | skill | Repo wiring orchestrator; slash matches folder |

## File naming under `cursor/`

```
cursor/agents/verasic-<role>.md     # subagent pointers
cursor/rules/verasic-<topic>.mdc    # always-applied rules
```

Agents and rules referenced from `skills/verasic-init/references/skill-ux-map.txt`.

## Standalone model-pinned subagents (`etc/cursor/agents/`)

Separate from product `cursor/agents/`. Maintainer tooling only — not in skills.sh, not wired by `verasic-init`.

```
etc/cursor/agents/subagent-<family>-<reasoning>-<fast|notfast>.md
```

Examples: `subagent-gpt-5.6-terra-reasoning-medium-fast`, `subagent-opus-4-8-low-nonthinking-fast`. Uses a `subagent-` **prefix**, not the `-reviewer` / `-auditor` / `-governor` suffixes above. Roster and spawn mechanics: [cursor-custom-subagents.md](cursor-custom-subagents.md) (catalog snapshot is single source of truth).

Documented exception: `subagent-inherit` (`model: inherit`) has no family or speed axis.

## Retired folder names (v0.2.0)

| Old | New |
| --- | --- |
| `verasic-security-review` | `verasic-secbot` |
| `verasic-github-env` | `verasic-github-cli-init` |
| `verasic-git-commits` | `verasic-git-commits-convention` (+ audit split) |
| `verasic-config` | removed — inlined secbot defaults |

See [verasic-cursor-map.md](verasic-cursor-map.md) for slash mapping.
