---
name: verasic-fusion
description: Multi-model fusion for exploration and decision support. Use when the user asks to "fuse", "fusion", "multi-model", "ask several models", runs /verasic-fusion, or wants board-verdict, rfc-review, tradeoff-matrix, brief-research, risk-register, devils-advocate, premortem, stakeholder-lens, or compare-to-status-quo templates across named models (e.g. composer-2.5-fast, glm-5.2-high, gemini-3-flash).
disable-model-invocation: true
---

Security: see `references/scanner-notes.md` and upstream [SECURITY.md](https://github.com/Milkywayrules/verasic-skills/blob/main/SECURITY.md) for expected scanner signals and trust model.

# Verasic Fusion — Multi-Model Orchestration

## Source of truth

| File                            | Role                                           |
| ------------------------------- | ---------------------------------------------- |
| `references/fusion-protocol.md` | Full protocol — read first                     |
| `references/helper.md`          | Help text for bare `/verasic-fusion` or `help` |
| `references/models.md`          | Known model slugs and substitutes              |
| `templates/<slug>.md`           | Output shape per template                      |

Never duplicate the protocol in chat — follow it.

## Workflow

1. **Help path** — if the user invokes fusion with no question or asks for help, relay
   `references/helper.md` (adjust path prefix for install root).
2. **Pre-flight** — require question, `mode`, and `models` (≥ 2). No defaults. Validate
   slugs via `references/models.md`. Apply soft cap 4 (warn) and hard cap 6 (block unless
   `acknowledge: proceed with N models`). Validate template extras (e.g. `lens-map` for
   `stakeholder-lens`).
3. **Read template** — when `template:` is set, read `templates/<slug>.md` before dispatch.
   Resolve absolute skill-root paths for subagent tasks (see protocol).
4. **Package prompt** — user question + attachments + your framing/analysis. Subagents must
   not see each other's answers.
5. **Dispatch** — in Cursor: spawn Task subagents **in parallel**, one per model, with
   the model slug from the roster. Each subagent gets absolute protocol + template paths;
   subagent **must read** the template file. Do **not** paste the full template inline.
   Optional fallback: extracted `## Subagent instruction` + `## Subagent answer shape` only.
6. **Curate & deliver** — per `mode` (`verbatim`, `fusion`, `verbatim+fusion`). Never
   rewrite subagent prose in `verbatim`. Surface conflicts. Attribute in `## by model`.
7. **Refuse** — if all subagent outputs are unusable, say so; do not invent fusion.
8. **Degraded** — if Task/subagents unavailable, ask upfront before sequential
   single-context simulation.

## Orchestration (Cursor)

Read `.cursor/skills/verasic-fusion/references/fusion-protocol.md` first and follow it exactly.

### Help

If the user sent no question, only `help`, or an empty invocation — relay
`.cursor/skills/verasic-fusion/references/helper.md` verbatim (adjust the path prefix if
this skill is installed elsewhere).

### Required from the user's message

Parse or ask for:

- `mode:` one of `verbatim`, `fusion`, `verbatim+fusion`
- `models:` comma-separated slugs (minimum 2) — validate against
  `.cursor/skills/verasic-fusion/references/models.md`
- The question body

Optional: `template:`, `acknowledge:`, template extras (`options:`, `lens-map:`, etc.)

**No default models. No default mode.** If either is missing, ask before spawning.

### Steps

1. Pre-flight per protocol (roster caps: warn at 4, hard cap 6 unless acknowledged).
2. Resolve skill root and **read** the active template file when `template:` is set.
3. Package prompt: user question + attachments + your framing — no other subagent answers.
4. Spawn Task subagents **in parallel**, one per model, foreground, with each model slug.
5. Subagent tasks: **absolute paths** to protocol + template; subagent **must read** the
   template file. Do **not** paste the full template inline. Optional: append extracted
   `## Subagent instruction` + `## Subagent answer shape` as fallback only (see protocol).
6. Subagents: readonly tools only; no mutations.
7. Curate and deliver per `mode`. Never rewrite subagent prose in `verbatim`.
8. Surface conflicts; attribute in `## by model`.
9. If all subagent outputs unusable — refuse fusion; say why.
10. If Task/subagents unavailable — ask before degraded sequential fusion.

### Subagent task prompt (one per model)

Replace `<skill-root>` with the absolute skill directory (contains `references/fusion-protocol.md`).

```text
Readonly fusion subagent. Follow <skill-root>/references/fusion-protocol.md readonly rules.

Template: <skill-root>/templates/<slug>.md
You MUST read this file before answering. Use ## Subagent instruction and
## Subagent answer shape only. Ignore Fusion mapping / Fusion notes.

<optional fallback: Subagent instruction + answer shape — only if needed>

## Packaged prompt
<packaged prompt from main agent>

Answer in the template shape. Do not mutate the repo.
```

### Deliver

Format output per protocol and active template. Include every core skeleton section in
fusion modes (`## answer`, `## reasoning`, `## conflicts`, `## by model`,
`## recommendation`).

## Without subagents

Read `references/fusion-protocol.md` and execute the full workflow yourself, including
degraded confirmation when parallel spawn is impossible.

## Hard rules

- Decision support only — no mutations.
- No default models or mode.
- No silent model substitution.
- Conflicts never silently flattened.
- `composer-2.5-fast` should appear in suggested rosters (user's primary model).

## Templates

Read `templates/<slug>.md` before dispatch when `template:` is set. All nine ship with this
skill — see `references/fusion-protocol.md` registry.
