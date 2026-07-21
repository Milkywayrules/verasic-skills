---
name: verasic-deep-research
description: Verified deep research with source ledger and confidence scoring. Use when the user asks to "deep research", "verify sources", "research with citations", runs /verasic-deep-research, wants ledger-backed claims, confidence scores, drill-down on weak evidence, or claims-investigation with a claim ledger.
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
2. **Pre-flight gate** — require question, `depth`, and `output`. No defaults on output format
   or source boundary. Collect path when files are requested. Apply honesty notices per protocol
   (see `references/helper.md` ## honesty).
3. **Read protocol** — read `references/research-protocol.md`, active `workflows/<depth>.md`, and supporting references before
   any fetch or spawn.
4. **Dispatch T2/T3 per tier** — T1 main orchestrates; spawn T2 workers (Hunter, Practitioner,
   Skeptic, Arbiter per tier preset) via Task in parallel; optional T3 leaf fetchers (no Task).
   T2 direct fallback when T3 fails — not a blocker.
5. **Verify ledger** — every citation must pass verify-before-cite; no cite without a ledger row
   (see `references/citation-protocol.md`).
6. **Score** — apply 5-axis confidence per `references/confidence-rubric.md`; sensitive domains
   enforce floor 60.
7. **Drill** — offer drill per `references/drill-protocol.md` when thresholds hit; max 2 rounds.
8. **Deliver** — chat per output format; write files to `./docs/research/<slug>/` when chosen.
   Use `templates/deep-research-brief.md` sections. **Ask mode = no file writes.**

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
