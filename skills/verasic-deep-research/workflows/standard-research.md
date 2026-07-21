# Workflow: standard-research

Depth preset: `standard-research`. Read `references/research-protocol.md` first.

**Target:** ~15 minutes soft budget. Hunter + Practitioner in parallel; T3 for fetch batches.

## Steps

1. **Pre-flight** — complete gate; honesty notices at each step.
2. **Load domain pack** — primary + secondary hints for multi-domain questions.
3. **Dispatch T2 parallel** — spawn Hunter and Practitioner Task subagents with same packaged prompt (no cross-visibility).
4. **T3 fetch batch** — optional parallel leaf fetch on Hunter URLs; merge raw bodies for Practitioner verify pass.
5. **Verify ledger** — two-key rule; snippet-only cap per `references/citation-protocol.md`.
6. **Synthesize** — `templates/deep-research-brief.md`; IEEE `[Sn]` only for verified rows.
7. **Score** — headline + full 5-axis per claim in `## confidence`.
8. **Drill** — up to 2 rounds per `references/drill-protocol.md`; honest stop on futile conditions.
9. **Deliver** — chat + files per output format; fusion handoff suggestion on `## unverified` only if fusion installed.

## When to recommend

- Default for most research questions.
- Balanced evidence depth without full adversarial cost.
- Upgrade to `adversarial-deep` when conflicts remain or claims-investigation pack applies.
