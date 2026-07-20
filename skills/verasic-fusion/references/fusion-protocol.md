# verasic-fusion — protocol

Single source of truth for multi-model fusion orchestration. Agents read this file
and follow it exactly — never duplicate the protocol elsewhere.

## Purpose

Exploration and decision support only. Fusion runs the same question across
models the user names, under a mode the user picks, with an optional output
template. The main agent orchestrates; subagents may readonly-explore before
answering.

**Out of scope:** file edits, commits, deploys, installs, or any mutation. Refuse
those requests — tell the user to switch to Agent mode or the appropriate Verasic
skill.

## Architecture

| Role       | Responsibility                                                                                                                                                |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Main agent | Pre-flight, prompt packaging, parallel dispatch, curation, delivery, conflict surfacing, provenance, refuse when all inputs unusable, confirm before degraded |
| Subagents  | Answer the packaged prompt; readonly tools allowed; one model per subagent                                                                                    |
| Protocol   | This file                                                                                                                                                     |
| Templates  | `templates/*.md` — shape overlays for `## answer` and template-specific blocks                                                                                |

No dedicated subagent definition files. Spawn generic Task subagents with the
user-specified model slug (Cursor) or simulate sequentially when subagents are
unavailable (see Degraded path).

## Pre-flight gate

Do **not** spawn subagents until all required fields are present.

| Field           | Required    | Rule                                                                   |
| --------------- | ----------- | ---------------------------------------------------------------------- |
| Question        | yes         | The decision or exploration prompt                                     |
| `models`        | yes         | Comma-separated roster; **≥ 2** or it is not fusion                    |
| `mode`          | yes         | One of: `verbatim`, `fusion`, `verbatim+fusion`                        |
| `template`      | no          | Slug from Templates registry; omit for generic core skeleton only      |
| Template extras | conditional | See per-template requirements (e.g. `lens-map` for `stakeholder-lens`) |

If any required field is missing → ask once, stop. **No default models. No default mode.**

### Roster rules

- The named list **is** the count. There is no separate count parameter.
- `"use 6 models"` with no list → ask for all six names.
- List of 4 names → spawn exactly four.
- Contradiction (`6 models: a, b, c, d`) → ask which is intended.
- One model named → not fusion; say so and ask for ≥ 1 more or solo answer.

### Roster caps

| Guardrail      | Behavior                                                                                 |
| -------------- | ---------------------------------------------------------------------------------------- |
| Soft cap **4** | Warn about cost, latency, diminishing returns — still spawn if the user keeps the roster |
| Hard cap **6** | Refuse to spawn until roster ≤ 6 **or** the user explicitly bypasses                     |

**Bypass:** user includes `acknowledge: proceed with N models` (or equivalent explicit
acknowledgment over the hard cap). Note in output: _proceeding above hard cap per your
acknowledgment._

### Model validation

Before spawn, validate each slug against `references/models.md` (known slugs) and
platform availability when the harness exposes model lists.

- Unknown slug → fail before spawn; list offenders; ask user to fix roster.
- Unavailable slug → fail before spawn; list unavailable slugs; suggest substitutes
  from `references/models.md`. **No silent substitution.**

## Output modes

| Mode              | Deliver                                                      |
| ----------------- | ------------------------------------------------------------ |
| `verbatim`        | Each subagent answer unchanged, in separate blocks per model |
| `fusion`          | Core skeleton (below) with `## recommendation`               |
| `verbatim+fusion` | Full verbatim blocks **first**, then the fused core skeleton |

### Core skeleton (fusion and verbatim+fusion fused section)

Always include every section. Use `none` when empty.

```markdown
## answer

## reasoning

## conflicts

## by model

## recommendation
```

- `## recommendation` — main agent's fused voice; required in `fusion`; same section in
  `verbatim+fusion` after verbatim blocks.
- Conflicts must never be silently flattened. If models disagree, say so in
  `## conflicts` even when the fused `## answer` picks a side.

### Curation rules

| Mode                         | Curation                                                                                                                                                |
| ---------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `verbatim`                   | Drop only: empty response, error/timeout, substance-free refusal. **Never rewrite** surviving subagent prose.                                           |
| `fusion` / `verbatim+fusion` | Weak but substantive answers stay; label weak inputs in `## by model`. Drop empty/error/refusal-only same as verbatim for inclusion in verbatim blocks. |

If **all** inputs are unusable after curation → refuse fusion; report why plainly. Do
not invent a synthesized answer.

## Main agent workflow

1. **Pre-flight** — validate question, models, mode, template extras; apply roster caps.
2. **Package prompt** — combine: user question, user attachments, main-agent framing/analysis
   (scope, constraints, readonly facts already gathered). Subagents do **not** see each
   other's answers.
3. **Parallel dispatch** — same verbatim core prompt to every model; spawn all subagents in
   parallel unless the user explicitly requests sequential.
4. **Collect** — wait for all subagents (or record failures).
5. **Curate** — apply curation rules; never rewrite in `verbatim`.
6. **Deliver** — format per mode and active template.
7. **Provenance** — `## by model`: one attribution block per model (short summary of stance).
8. **Degraded** — only if subagents unavailable (see below).

### Subagent prompt shape

Each subagent receives:

```text
Follow references/fusion-protocol.md readonly rules and the active template at templates/<slug>.md.

<packaged prompt from main agent>

Answer using the template shape. Readonly tools allowed when facts are needed.
Do not mutate the repository.
```

When a template is active, include its file path. When none, use the core skeleton only.

### Readonly tool boundary (subagents)

**Allowed:** read, grep, glob, list dirs, git read-only (`log`, `diff`, `show`, `status`),
HTTP fetch for public facts.

**Forbidden:** write, edit, delete, commit, push, install, deploy, env/secret access,
any mutation.

## Degraded path

When the harness cannot spawn subagents (non-Cursor agent, Task unavailable, etc.):

1. Ask upfront: _Subagents unavailable — run degraded sequential fusion in this single
   context? (yes/no)_
2. Do **not** start until the user confirms.
3. If yes: read this protocol and each needed template; simulate models **sequentially**
   in one context with header: `degraded: sequential single-context, not parallel`.
4. Deliver per mode with the same output rules.

## Templates registry

Templates live in `templates/<slug>.md`. The slug is what the user passes as
`template: <slug>`.

| Slug                    | Purpose                              |
| ----------------------- | ------------------------------------ |
| `board-verdict`         | BOD / leadership yes-no vote         |
| `rfc-review`            | Spec / ADR / proposal review         |
| `tradeoff-matrix`       | Architecture / option comparison     |
| `research-brief`        | Landscape / exploration              |
| `risk-register`         | Launch / security / compliance risks |
| `devils-advocate`       | Stress-test by arguing against       |
| `premortem`             | Assume failure, work backward        |
| `stakeholder-lens`      | Explicit per-model stakeholder map   |
| `compare-to-status-quo` | Change vs doing nothing              |

Read the matching template file before dispatch. Template overlays `## answer` (and
sometimes subagent instructions). Core skeleton sections still apply in fusion modes.

### Template invocation extras

| Template           | Optional invocation fields                                |
| ------------------ | --------------------------------------------------------- |
| `tradeoff-matrix`  | `options:`, `criteria-weights:`, `must-haves:`            |
| `stakeholder-lens` | `lenses:`, `lens-map:` (**required** — see template file) |

## Conflict surfacing

Hard rule: disagreements stay visible.

- In `fusion` / `verbatim+fusion`: populate `## conflicts` with explicit tensions
  (different picks, weights, verdicts, must-have pass/fail).
- In `verbatim`: each model's dissent stays inside its own verbatim block.
- In `## by model`: one line or short block per model summarizing their stance.

## Attribution (`## by model`)

One block per surviving model:

```markdown
### <model slug>

<short attribution — stance, pick, or unique angle>
```

Do not merge models into anonymous prose in fusion modes.

## Help text

When the user invokes fusion with no question, asks for help, or passes `help`, relay
the contents of `references/helper.md` verbatim (adjust paths if the skill is installed
under a non-`.cursor` root).

## Cross-agent installs

Skill path may be `.cursor/skills/verasic-fusion/`, `.agents/skills/verasic-fusion/`,
or another prefix. Resolve `references/` and `templates/` relative to the skill root.
Behavior is identical; only subagent spawn mechanism differs (Task vs sequential degraded).
