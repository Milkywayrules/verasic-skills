---
name: verasic-deep-research
description: Verified deep research with source ledger and confidence scoring. Use when the user asks to "deep research", "verify sources", "research with citations", runs /verasic-deep-research, wants ledger-backed claims, confidence scores, drill-down on weak evidence, or claims-investigation with a claim ledger.
disable-model-invocation: true
---

Security: see `references/scanner-notes.md` and upstream [SECURITY.md](https://github.com/Milkywayrules/verasic-skills/blob/main/SECURITY.md) for expected scanner signals and trust model.

# Verasic Deep Research — Ledger-Backed Research

## Source of truth

| File                                  | Role                                           |
| ------------------------------------- | ---------------------------------------------- |
| `references/research-protocol.md`     | Full protocol — read first                     |
| `references/helper.md`                | Help text for bare `/verasic-deep-research` or `help` |
| `references/citation-protocol.md`     | Verify pipeline, SourceRecord, two-key rule    |
| `references/confidence-rubric.md`     | 5-axis scoring                                 |
| `references/drill-protocol.md`        | Drill triggers and futile conditions           |
| `references/source-tiers.md`          | T0–T3 source classification                    |
| `references/fusion-handoff.md`        | Optional manual chain to verasic-fusion        |
| `templates/deep-research-brief.md`    | Deliver template sections                      |
| `workflows/<depth>.md`                | Tier checklist (quick-scan, standard-research, …) |

Never duplicate the protocol in chat — follow it.

## Workflow

1. **Help path** — if the user invokes deep research with no question or asks for help, relay
   `references/helper.md` (adjust path prefix for install root).
2. **Pre-flight gate** — require **all** pre-flight fields before any fetch or spawn:
   **question**, `depth`, `output`, `source-boundary`, `languages`. **No defaults** on `output` or
   `source-boundary` (recommend `public-standard` only after asking). Collect output path when
   `output` includes files. Apply honesty notices per protocol (see `references/helper.md` ## honesty).
3. **Read protocol** — read `references/research-protocol.md`, active `workflows/<depth>.md`, and supporting references before
   any fetch or spawn.
4. **Dispatch T2/T3 per tier** — T1 main orchestrates; spawn T2 workers per depth preset via
   Task. T3 leaf jobs (`fetch-url`, `extract-excerpt`, `single-query-search`, `verify-one-claim`)
   are spawned by T2 (grandchild, no Task). T1 batches WebFetch when T2 unavailable.
   `standard-research`: Hunter + Practitioner parallel → Skeptic sequential (mandatory).
   T2 direct fallback when T3 fails — not a blocker.
5. **Verify ledger** — every citation must pass verify-before-cite; no cite without a ledger row
   (see `references/citation-protocol.md`).
6. **Score** — apply 5-axis confidence per `references/confidence-rubric.md`; sensitive domains
   enforce floor 60.
7. **Drill** — per `references/drill-protocol.md` when thresholds hit; max 2 rounds
   (`auto-at-threshold` auto-executes round 1; offers round 2).
8. **Deliver** — chat per output format; write files to `./docs/research/<slug>/` when chosen.
   Use `templates/deep-research-brief.md` sections. **Ask mode = no file writes.**

## Orchestration (Cursor)

Read `.cursor/skills/verasic-deep-research/references/research-protocol.md` first and follow it exactly.

### Help

If the user sent no question, only `help`, or an empty invocation — relay
`.cursor/skills/verasic-deep-research/references/helper.md` verbatim (adjust the path prefix if
this skill is installed elsewhere).

### Required from the user's message

Parse or ask for:

- `depth:` one of `quick-scan`, `standard-research`, `adversarial-deep`, `custom`
- `output:` one of `chat-only`, `chat+files`, `files-only`, `custom` — **no default**
- `source-boundary:` one of `public-standard`, `public-extended`, `aggressive-scrape` (+ optional free text)
- `languages:` cite / search / report languages
- The question body

Optional: `models:`, `domain:`, `drill:` (`auto-at-threshold` | `off` | `always-offer`), `claims:` list, output path, `custom-roles:` when `depth: custom`

**No default output format. No default source boundary.** Recommend `public-standard`.
If required fields missing, ask before any fetch or spawn. Include honesty notices from helper ## honesty at each pre-flight step.

### Ask mode

If the user is in Ask (read-only) mode — **no file writes**. Deliver chat only even if they chose
`chat+files` or `files-only`. Say so and offer Agent mode or `chat-only`.

### Steps

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

### T2 subagent task prompt (one per role)

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

### T3 leaf jobs (spawned by T2, no Task)

| Job | Returns |
| --- | ------- |
| `fetch-url` | HTTP status + raw body/metadata |
| `extract-excerpt` | ≤40-word supporting excerpt |
| `single-query-search` | Candidate URLs/snippets (no synthesis) |
| `verify-one-claim` | Two-key pass/fail + excerpt |

T3 must not synthesize, merge ledger, spawn subagents, or score confidence.

### Deliver

- **chat-only** — full brief sections in chat; headline + per-claim 5-axis in `## confidence`.
- **chat+files** — chat summary + write `./docs/research/<slug>/deep-research-brief.md` and ledger files in the **same turn** (Agent mode). Do not end with chat-only and write files later unless the user explicitly asks for staged delivery.
- **files-only** — write files; chat gets short pointer only.

Hard rules: verify-before-cite; no cite without ledger row; refuse insider/illegal sources.

Recommend `composer-2.5-fast` in optional model rosters when suggesting models.

## Without subagents

Read `references/research-protocol.md` and execute the full pipeline yourself, including
degraded confirmation when Task is unavailable.

## Hard rules

- **Verify-before-cite** — no citation without a verified ledger row.
- **No default output format** — user must pick `chat-only`, `chat+files`, `files-only`, or `custom`.
- **No default source boundary** — user must pick; agent recommends `public-standard`.
- **Ask mode = no file writes** — deliver in chat only.
- **composer-2.5-fast** should appear in suggested model rosters when optional roster is offered.
- **Fusion handoff** — suggest manually on `## unverified` only if `verasic-fusion` is installed;
  never assume it is present.

## Refuse

Insider or non-public proprietary data, illegal collection without an explicit user-stated
boundary, and research that requires violating the chosen source boundary.
