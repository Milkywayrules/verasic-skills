# Verasic Fusion

Multi-model fusion for exploration and decision support. Run the same question across
models you name, under a mode you pick, with optional output templates. Main agent
orchestrates; frontier models stay disposable and focused.

## Parts

Paths relative to this skill folder. After `setup.sh`, the same files live under
`.cursor/skills/verasic-fusion/`.

| File                                      | Role                                                               |
| ----------------------------------------- | ------------------------------------------------------------------ |
| `references/fusion-protocol.md`           | Single source of truth                                             |
| `references/helper.md`                    | Help text for bare `/verasic-fusion`                               |
| `references/models.md`                    | Known model slugs                                                  |
| `templates/`                              | Output templates (9 presets)                                       |
| `SKILL.md`                                | Auto-trigger + orchestration                                       |
| `../../cursor/commands/verasic-fusion.md` | `/verasic-fusion` slash command (installed to `.cursor/commands/`) |

## Human workflow

1. Choose `mode`, `models` (≥ 2), and optional `template`.
2. Run `/verasic-fusion` with your question — or attach `/verasic-fusion` skill in chat.
3. Main agent spawns parallel subagents (Cursor Task) or asks before degraded sequential.
4. Receive `verbatim`, fused synthesis, or both per mode.

Typing `/verasic` shows fusion alongside review, audit, init, and github setup.

## Required every run

```text
mode: verbatim | fusion | verbatim+fusion
models: composer-2.5-fast, gemini-3-flash, ...
<question>
```

No default models. No default mode.

## Roster caps

- **4+ models** — warning
- **6+ models** — blocked unless `acknowledge: proceed with N models`

## Templates

| Slug                    | Use                          |
| ----------------------- | ---------------------------- |
| `board-verdict`         | BOD yes/no                   |
| `rfc-review`            | Spec / proposal review       |
| `tradeoff-matrix`       | Option matrix                |
| `research-brief`        | Landscape research           |
| `risk-register`         | Risk table                   |
| `devils-advocate`       | Argue against                |
| `premortem`             | Assume failure               |
| `stakeholder-lens`      | Explicit `lens-map` required |
| `compare-to-status-quo` | Change vs inaction           |

## Output modes

| Mode              | Deliver                        |
| ----------------- | ------------------------------ |
| `verbatim`        | Each model unchanged           |
| `fusion`          | Core skeleton + recommendation |
| `verbatim+fusion` | Verbatim first, then synthesis |

## Scope

Readonly decision support — no edits, commits, or deploys.

## Extend

Add templates as new files in `templates/` and one row in the protocol registry. Custom
templates survive `setup.sh` re-runs if you only add files (shipped files overwrite).

## Install

From the project root:

```bash
curl -fsSL https://raw.githubusercontent.com/Milkywayrules/verasic-skills/main/setup.sh | bash
```

Skill-only (any agent): `npx skills add Milkywayrules/verasic-skills`

Then: `/verasic-init` or `bash .cursor/skills/verasic-init/scripts/init.sh`

## Verify

```bash
bash skills/verasic-fusion/scripts/test-exhaustive.sh   # from verasic-skills repo root
# after setup.sh in a consumer project:
bash .cursor/skills/verasic-fusion/scripts/test-exhaustive.sh
```

See `references/use-cases.md` for the full live harness checklist (UC-0 through UC-14).

## Known limits

- **Cursor-first** — parallel subagent spawn uses the Task tool; other agents read the
  protocol and may run degraded sequential fusion after user confirmation.
- **Models are user-supplied** — no default roster; validate slugs against
  `references/models.md` (includes `composer-2.5-fast`, `glm-5.2-high`, and others).
- **Readonly only** — decision support; no file edits, commits, or deploys.
- **Harness availability** — model API limits or missing slugs fail before spawn; use
  substitutes listed in `references/models.md`.
