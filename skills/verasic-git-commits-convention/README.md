# Verasic Git Commits Convention

Hard commit convention for AI-assisted workflows. Every commit — human or
agent — follows one message style, carries no co-authored/AI trailers, and
reads like a teammate explaining why, never like a session log.

Battle-tested daily on Verasic and Autopedia repos for months before being
packaged here. Pre-push history audit lives in the sibling **verasic-git-commits-audit** skill.

## Parts

Paths relative to this skill folder unless noted. After `setup.sh`, skill files
live under `.cursor/skills/verasic-git-commits-convention/`.

| File                                             | Role                                                  |
| ------------------------------------------------ | ----------------------------------------------------- |
| `references/`                                    | The spec + both protocols — single source of truth    |
| `hooks/commit-msg`                               | Deterministic git hook layer                          |
| `scripts/test-regression.sh`                     | Hook regression suite                                 |
| `SKILL.md`                                       | Write-path orchestration                          |
| `.cursor/rules/verasic-git-commits-convention.mdc` | Always-applied digest (after `setup.sh`)        |

## Three enforcement layers

| Layer             | What                                | Catches                                                                                          | Cost                     |
| ----------------- | ----------------------------------- | ------------------------------------------------------------------------------------------------ | ------------------------ |
| 0 — deterministic | `hooks/commit-msg` git hook         | trailer/attribution strip (any casing, pre-write), bad prefix, casing, period, emoji, blank line | zero tokens, can't drift |
| 1 — write time    | always-applied rule digest          | message _quality_: why-not-what body, backticks, AI voice avoidance                              | ~35 lines per context    |
| 2 — judgment      | `/verasic-git-commits-audit` (sibling skill) | AI-session language in history, artifact files, anything regex can't judge                       | one run before push/PR   |

Wire the hook per repo (once) — `/verasic-init` does this automatically via
`scripts/wire-hook.sh`, or manually:

```yaml
# lefthook.yml (repos already on lefthook)
commit-msg:
  commands:
    verasic:
      run: bash .cursor/skills/verasic-git-commits-convention/hooks/commit-msg {1}
```

```bash
# raw git (repo without a hook manager)
git config core.hooksPath .cursor/skills/verasic-git-commits-convention/hooks
```

With the hook wired, injected trailers (Cursor, Claude Code, …) are stripped
before the commit object exists — the `commit-tree` escape hatch is only
needed in unwired repos.

Caveats: hooks are client-side (`--no-verify` skips them — forbidden by the
rule; the audit stays the backstop), and the emoji check needs GNU grep, so
macOS/BSD grep silently skips that one check.

## How the pieces relate

- The **rule** is always in context (Cursor `alwaysApply`), so every commit an
  agent makes follows the digest without being asked. It points into
  `references/` for the full spec and recipes.
- **Pre-push audit:** use `/verasic-git-commits-audit` (sibling skill).

Non-Cursor always-on enforcement: add one row to the repo's `AGENTS.md` (or
`CLAUDE.md`):

```markdown
| Git commits (style + no trailer) | [references/commit-protocol.md](references/commit-protocol.md) — prefix with your install root in AGENTS.md (e.g. `.cursor/skills/verasic-git-commits-convention/` or `.agents/skills/verasic-git-commits-convention/`) |
```

## Usage

- Committing: nothing to invoke — the rule applies automatically; agents verify the trailer after every commit.
- Pre-push audit: `/verasic-git-commits-audit` (sibling skill)

Security: [references/scanner-notes.md](references/scanner-notes.md) · upstream [SECURITY.md](https://github.com/Milkywayrules/verasic-skills/blob/main/SECURITY.md)

## Extend per repo

Initiative docs may add constraints on top (e.g. a RUNBOOK requiring ticket
scopes on every subject). Keep overlays in the initiative doc — never fork the
casing or trailer rules per repo unless the team changes Verasic defaults.

## Install into a new project

From the project root:

```bash
curl -fsSL https://raw.githubusercontent.com/Milkywayrules/verasic-skills/main/setup.sh | bash
```

or skill-only (any agent, not just Cursor): `npx skills add Milkywayrules/verasic-skills`
