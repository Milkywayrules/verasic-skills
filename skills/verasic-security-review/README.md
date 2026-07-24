# Verasic Security Review

STRIDE security review on git diffs — optional deterministic scanner (OpenGrep / Semgrep),
high-confidence filtering, and markdown artifacts under `verasic/` and `.verasic/`.
Read-only: reports findings, never applies fixes.

## Parts

Paths relative to this skill folder unless noted. After `setup.sh`, skill files
live under `.cursor/skills/verasic-security-review/`.

| File                                      | Role                                             |
| ----------------------------------------- | ------------------------------------------------ |
| `references/security-review-protocol.md`  | The brain — single source of truth               |
| `references/confidence-rubric.md`         | 0–10 confidence scale and floors                 |
| `references/scanner-adapter.md`           | OpenGrep / Semgrep / auto / off                  |
| `references/config-schema.md`             | Config keys — see `verasic-config` skill         |
| `checklists/security.md`                  | Shared security checklist (with verasic-bugbot)  |
| `SKILL.md`                                | Auto-trigger + orchestration                     |
| `.cursor/agents/verasic-security-reviewer.md` | Cursor subagent (after `setup.sh`)         |
| `.cursor/commands/verasic-security-review.md` | `/verasic-security-review` slash command   |

## Human workflow (which slash entry do I use?)

Typing `/verasic` in Cursor chat shows multiple entries — they are different types
sharing one system:

- **`/verasic-security-review`** (command) — the one you normally use. Kicks off a STRIDE
  security review of your branch changes. Add "uncommitted only" to review staged + unstaged.
- **`/verasic-security-review`** (skill) — attaches the orchestration instructions to your
  message and runs in your current conversation. Useful for custom phrasing, e.g.
  "/verasic-security-review assertive mode on auth changes".
- **`/verasic-security-reviewer`** (agent) — talks to the security review subagent directly.
  It runs in its own isolated context, so the (long) review work doesn't clutter your
  chat — only the report comes back. Rarely needed; the command and skill both launch it.

Naming rationale: the agent is `verasic-security-reviewer` (role); the skill and command
share `verasic-security-review` (the product surface). The command is a verb phrase because
it is the action a human runs.

Day-to-day loop:

1. Finish auth, API, webhook, or crypto changes.
2. Run `/verasic-security-review` (or say "security review my changes").
3. Fix CRITICAL/HIGH findings, re-run until `✅ No security issues found`.
4. Optionally run `/verasic-review` for general bug hunting (sibling skill — not auto-chained).
5. Commit / open PR; promote artifacts to `verasic/security-reviews/` when team-visible.

## Output

Legend (severity + confidence bands), summary table, then expanded finding blocks with
Category, Exploit, Reachability, and Remediation. Artifacts written per config `promote`.

Security: [references/scanner-notes.md](references/scanner-notes.md) · upstream [SECURITY.md](https://github.com/Milkywayrules/verasic-skills/blob/main/SECURITY.md)

## Config

Optional `verasic.config.ts` or `.verasicrc.json` at repo root — see `references/config-schema.md`.
Defaults: scanner `off`, strictness `strict`, artifacts to both `localDir` and `trackedDir`.

## Install into a new project

From the project root:

```bash
curl -fsSL https://raw.githubusercontent.com/Milkywayrules/verasic-skills/main/setup.sh | bash
```

or skill-only (any agent, not just Cursor): `npx skills add Milkywayrules/verasic-skills`
