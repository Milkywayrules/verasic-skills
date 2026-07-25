# Verasic Git Commits Audit

Pre-push commit history audit against the Verasic commit convention. Read-only by default; fix mode only after explicit user approval.

## Parts

| File       | Role                              |
| ---------- | --------------------------------- |
| `SKILL.md` | Audit orchestration               |

Protocol and checks live in the sibling **verasic-git-commits-convention** skill (`references/audit-protocol.md`).

## Usage

- `/verasic-git-commits-audit` — audit branch commits vs default base
- `/verasic-git-commits-audit --unpushed-only` — only commits not yet pushed
- `/verasic-git-commits-audit --help` — usage table, no audit
