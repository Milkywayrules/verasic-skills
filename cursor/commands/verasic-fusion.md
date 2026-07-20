Run multi-model fusion for exploration and decision support.

Read `.cursor/skills/verasic-fusion/references/fusion-protocol.md` first and follow it exactly.

## Help

If I sent no question, only `help`, or an empty invocation — relay
`.cursor/skills/verasic-fusion/references/helper.md` verbatim (adjust the path prefix if
this skill is installed elsewhere).

## Required from my message

Parse or ask for:

- `mode:` one of `verbatim`, `fusion`, `verbatim+fusion`
- `models:` comma-separated slugs (minimum 2) — validate against
  `.cursor/skills/verasic-fusion/references/models.md`
- The question body

Optional: `template:`, `acknowledge:`, template extras (`options:`, `lens-map:`, etc.)

**No default models. No default mode.** If either is missing, ask before spawning.

## Orchestration (Cursor)

1. Pre-flight per protocol (roster caps: warn at 4, hard cap 6 unless acknowledged).
2. Package prompt: my question + attachments + your framing — append to each subagent task.
3. Spawn Task subagents **in parallel**, one per model, foreground, with each model slug.
   Pass the active template path under `.cursor/skills/verasic-fusion/templates/<slug>.md`.
4. Subagents: readonly tools only; no mutations.
5. Curate and deliver per `mode`. Never rewrite subagent prose in `verbatim`.
6. Surface conflicts; attribute in `## by model`.
7. If all subagent outputs unusable — refuse fusion; say why.
8. If Task/subagents unavailable — ask me before degraded sequential fusion.

## Subagent task prompt (one per model)

```text
Read and follow .cursor/skills/verasic-fusion/references/fusion-protocol.md readonly rules.

Template (if set): .cursor/skills/verasic-fusion/templates/<slug>.md

<packaged prompt from main agent>

Answer in the template shape. Readonly exploration allowed. Do not mutate the repo.
```

## Deliver

Format output per protocol and active template. Include every core skeleton section in
fusion modes (`## answer`, `## reasoning`, `## conflicts`, `## by model`,
`## recommendation`).
