# Workflow: quick-scan

Depth preset: `quick-scan`. Read `references/research-protocol.md` first — this file
is a step checklist only, not a second source of truth.

**Target:** ~5 minutes soft budget. One T2 Hunter; T3 optional; T2 may fetch directly.

## Steps

1. **Pre-flight** — complete gate per protocol; honesty notices from `references/helper.md` ## honesty.
2. **Load domain pack** — infer or apply user override from `references/domain-packs/`; state primary pack in recap.
3. **Dispatch Hunter (T2)** — single Task subagent with Hunter persona; packaged prompt only.
4. **Optional T3 batch** — parallel fetch on Hunter URL list; on failure, Hunter fetches directly (not a blocker).
5. **Verify ledger** — verify-before-cite per `references/citation-protocol.md`; drop failed rows.
6. **Synthesize** — populate `templates/deep-research-brief.md` sections from verified rows only.
7. **Score** — 5-axis per `references/confidence-rubric.md`; apply pack weights and sensitive floor.
8. **Drill offer** — if `drill: auto-at-threshold` and score ≤50 (≤60 sensitive), offer one drill round max.
9. **Deliver** — chat per `output` format; files to `./docs/research/<slug>/` when allowed; Ask mode = no writes.

## When to recommend

- Factual lookups with narrow scope.
- User time-boxed or exploratory first pass.
- Upgrade path: suggest `standard-research` if confidence ≤50 after drill.
