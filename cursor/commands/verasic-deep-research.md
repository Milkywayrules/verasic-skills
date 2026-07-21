Run ledger-backed deep research with verify-before-cite and confidence scoring.

Read `.cursor/skills/verasic-deep-research/references/research-protocol.md` first and follow it exactly.

## Help

If I sent no question, only `help`, or an empty invocation — relay
`.cursor/skills/verasic-deep-research/references/helper.md` verbatim (adjust the path prefix if
this skill is installed elsewhere).

## Required from my message

Parse or ask for:

- `depth:` one of `quick-scan`, `standard-research`, `adversarial-deep`, `custom`
- `output:` one of `chat-only`, `chat+files`, `files-only`, `custom` — **no default**
- `source-boundary:` one of `public-standard`, `public-extended`, `aggressive-scrape` (+ optional free text)
- `languages:` cite / search / report languages
- The question body

Optional: `models:`, `domain:`, `drill:` (`auto-at-threshold` | `off` | `always-offer`), `claims:` list, output path, `custom-roles:` when `depth: custom`

**No default output format. No default source boundary.** Recommend `public-standard`.
If required fields missing, ask before any fetch or spawn. Include honesty notices from helper ## honesty at each pre-flight step.

## Ask mode

If I am in Ask (read-only) mode — **no file writes**. Deliver chat only even if I chose
`chat+files` or `files-only`. Say so and offer Agent mode or `chat-only`.

## Orchestration (Cursor)

1. Pre-flight per protocol — all required fields; path `./docs/research/<slug>/` when files requested.
2. Read supporting refs: citation-protocol, confidence-rubric, source-tiers, drill-protocol, `workflows/<depth>.md`, deliver template.
3. Dispatch T2 workers via Task per depth tier:
   - `quick-scan`: Hunter only (no Skeptic)
   - `standard-research`: Hunter + Practitioner parallel → Skeptic sequential (mandatory 7a)
   - `adversarial-deep`: Hunter + Practitioner + Skeptic + Arbiter (4 parallel)
4. T3 leaf jobs spawned by T2 (grandchild, no Task): `fetch-url`, `extract-excerpt`, `single-query-search`, `verify-one-claim`. T1 batches WebFetch when T2 unavailable. T2 direct fallback on failure.
5. Verify ledger — verify-before-cite; no `[Sn]` without ledger row; IEEE citations; snippet-only headline hard cap 40.
6. Score — 5-axis per claim (SQ, EC, CG, CO, VR); sensitive domain floor 60; chat shows headline + full axes.
7. Drill when thresholds hit — `auto-at-threshold` auto-executes round 1; offer round 2; max 2 rounds (`drill-protocol.md`).
8. Deliver per `output` — use `templates/deep-research-brief.md` sections.
9. `## unverified` → suggest manual fusion only if `verasic-fusion` installed (`fusion-handoff.md`).
10. If Task unavailable — ask before degraded sequential single-context research.

## T2 subagent task prompt (one per role)

Replace `<skill-root>` with the absolute skill directory (contains `references/research-protocol.md`).

```text
Readonly deep-research T2 (<role>). Follow <skill-root>/references/research-protocol.md.

Supporting refs (readonly):
- <skill-root>/references/citation-protocol.md
- <skill-root>/references/source-tiers.md

Role: <Hunter|Practitioner|Skeptic|Arbiter>
Source boundary: <boundary>
Languages: <languages>
Domain pack: <inferred or user domain>

## Packaged prompt
<question + pre-flight context>

Return candidate sources for main-agent verify. Do not mutate the repo.
```

## T3 leaf jobs (spawned by T2, no Task)

| Job | Returns |
| --- | ------- |
| `fetch-url` | HTTP status + raw body/metadata |
| `extract-excerpt` | ≤40-word supporting excerpt |
| `single-query-search` | Candidate URLs/snippets (no synthesis) |
| `verify-one-claim` | Two-key pass/fail + excerpt |

T3 must not synthesize, merge ledger, spawn subagents, or score confidence.

## Deliver

- **chat-only** — full brief sections in chat; headline + per-claim 5-axis in `## confidence`.
- **chat+files** — chat summary + write `./docs/research/<slug>/deep-research-brief.md` and ledger files in the **same turn** (Agent mode). Do not end with chat-only and write files later unless I explicitly ask for staged delivery.
- **files-only** — write files; chat gets short pointer only.

Hard rules: verify-before-cite; no cite without ledger row; refuse insider/illegal sources.

Recommend `composer-2.5-fast` in optional model rosters when suggesting models.
