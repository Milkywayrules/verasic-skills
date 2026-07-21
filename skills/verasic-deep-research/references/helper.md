# verasic-deep-research — helper

Ledger-backed deep research with verify-before-cite, source ledger, and 5-axis
confidence scoring. Every citation maps to a verified row — or it does not ship.

## Required every run

```text
depth: quick-scan | standard-research | adversarial-deep | custom
output: chat-only | chat+files | files-only | custom
source-boundary: public-standard | public-extended | aggressive-scrape
languages: <cite/search/report — default prompt language if omitted in prose>
<your question>
```

**No default output format. No default source boundary.** Missing fields → the agent asks
before any fetch or spawn.

When `output` includes files, provide or accept path `./docs/research/<slug>/`.

## Optional

```text
models: composer-2.5-fast, gemini-3-flash, ...
domain: health | legal | financial | tech | general | ...
drill: auto-at-threshold | off | always-offer
  # auto-at-threshold: auto round 1 when triggered; offer round 2
  # off: no drill
  # always-offer: offer yes/no before both rounds
custom-roles: hunter, practitioner, skeptic   # when depth: custom
claims:
  - <claim one>
  - <claim two>
```

Recommend including `composer-2.5-fast` when suggesting a model roster.

## Depth tiers

| Depth               | Workers                         | Use                                      |
| ------------------- | ------------------------------- | ---------------------------------------- |
| `quick-scan`        | Hunter (1 T2) — no Skeptic      | Fast landscape, fewer sources            |
| `standard-research` | Hunter + Practitioner (parallel) → Skeptic (sequential) | Balanced depth with challenge pass |
| `adversarial-deep`  | Hunter + Practitioner + Skeptic + Arbiter (4 parallel) | Contested topics, conflict resolution |
| `custom`            | You specify T2 roles            | Non-standard scope                       |

Optional T3 leaf jobs (`fetch-url`, `extract-excerpt`, `single-query-search`,
`verify-one-claim`) spawned by T2 — failure is not a blocker.

## Output formats

| Output        | Chat | Files under `./docs/research/<slug>/` |
| ------------- | ---- | ------------------------------------- |
| `chat-only`   | yes  | no                                    |
| `chat+files`  | yes  | yes (`deep-research-brief.md`, ledger, etc.) |
| `files-only`  | brief pointer in chat | yes                          |
| `custom`      | per your spec | per your spec                  |

**Ask mode:** no file writes — chat delivery only, even if you chose file output.

## Source boundaries

| Boundary              | Includes                                      | Warning                          |
| --------------------- | --------------------------------------------- | -------------------------------- |
| `public-standard`     | Official docs, standards, reputable news, academic, vendor docs | **Recommended default** |
| `public-extended`     | Above + forums, blogs, social                 | Lower source tiers; more skepticism |
| `aggressive-scrape`   | Wider fetch tolerance                         | Blocks, rate limits, ToS risk — you accept |

Add free-text qualifiers (jurisdiction, date floor, excluded domains).

Agent recommends `public-standard` unless you document a reason to widen.

## Templates and deliverables

File deliverables follow `templates/deep-research-brief.md` sections. Typical files under `./docs/research/<slug>/`:

- `deep-research-brief.md` — full narrative (all template sections)
- `source-ledger.yaml` — machine companion ledger (`templates/source-ledger.yaml` shape)

## Example — standard research

```text
/verasic-deep-research
depth: standard-research
output: chat+files
source-boundary: public-standard
languages: en

What are the current EU AI Act enforcement timelines for GPAI providers?
```

## Example — claims investigation

```text
depth: adversarial-deep
output: chat-only
source-boundary: public-standard
languages: en

claims:
  - Cloudflare Workers cold start is under 5ms globally
  - EU AI Act fines can reach 7% of global turnover

Verify each claim with ledger-backed citations.
```

## Difference from verasic-fusion brief-research

| | `verasic-deep-research` | `verasic-fusion` + `brief-research` |
| --- | --- | --- |
| Sources | Verified ledger, fetch + verify | Model opinions, may cite without verify |
| Confidence | 5-axis scored per claim | No scoring |
| Drill | Structured re-search rounds | N/A |
| Best for | Facts, compliance, due diligence | Multi-model exploration, brainstorming |

For unverified gaps after deep research, you may **manually** chain to fusion if installed —
see `references/fusion-handoff.md`.

## Honesty (read this)

Read these notices at pre-flight and echo them when relevant during delivery.

**Scores are estimates.** 5-axis confidence is structured judgment, not a statistical guarantee.
Treat headline numbers as guidance, not proof.

**Verify fails often.** Pages move, paywall, block bots, or contradict snippets. Failed verify
→ no `[Sn]` cite. Expect gaps.

**Drill plateau.** Drill rounds (max 2) may not improve score — same sources, no new T0/T1,
contested official positions, and paywalls are futile triggers. `auto-at-threshold` runs
round 1 automatically; round 2 requires confirmation. Downgrade honestly after round 2.

**Sensitive disclaimers.** Health, legal, and financial topics get a confidence display floor of
60 and explicit not-professional-advice language. Deep research is not a lawyer, doctor, or
financial advisor.

**Health training plans.** Under `health-fitness`, headline ≥75 with T0/T1 backing allows structured plans in `## recommendation` with **not medical advice — consult a professional** disclaimer.

**Ask mode.** Read-only chat cannot write files. Choose Agent mode or `chat-only` for file output.

**Fusion optional.** Unverified items may suggest a manual `verasic-fusion` follow-up only when
that skill is installed — never automatic.

**T3 fallback.** T3 leaf jobs are best-effort. T2 or main agent direct fetch replaces T3
without blocking delivery.

**Source boundary is your contract.** Widen only when you accept tier downgrade and ToS/rate-limit
risk. Insider or illegal sources are refused.

**No cite without ledger row.** If it is not in the ledger as verified or snippet-only, it does
not appear as `[Sn]` in prose.

**Language mismatch.** Search/cite/report language differences can miss local-primary sources —
state languages up front.

**Model roster optional.** When omitted, the main agent runs the pipeline. T2 spawn uses your
roster when provided.

**Custom output.** Describe chat vs file split explicitly when using `output: custom`.

**Contested claims.** Adversarial tier surfaces disagreement in `## conflicts` — not hidden
in a single narrative line.

**Snippet-only rows.** Live page may differ; max 40 words stored; claim headline hard cap 40
for scoring (separate from word limit).

**Verification rigor (VR axis).** Fetch quality and recency — old docs may be formally
correct but operationally stale.

**composer-2.5-fast.** Recommended in optional rosters as the user's primary Cursor model — not
a default spawn requirement.
