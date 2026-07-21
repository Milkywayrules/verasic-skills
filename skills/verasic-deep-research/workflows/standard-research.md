# Workflow: standard-research

Depth preset: `standard-research`. Read `references/research-protocol.md` first.

**Target:** ~15 minutes soft budget. Hunter + Practitioner in parallel; mandatory Skeptic
sequential pass (7a); T3 leaf jobs for fetch batches.

## Steps

1. **Pre-flight** — complete gate; honesty notices at each step.
2. **Load domain pack** — primary + secondary hints for multi-domain questions.
3. **Dispatch T2 parallel** — spawn Hunter and Practitioner Task subagents with same packaged prompt (no cross-visibility).
4. **T3 fetch batch** — T2 (or T1) spawns T3 leaf jobs on Hunter URLs (`fetch-url`, etc.); merge raw bodies for verify pass; T2 direct fallback on failure.
5. **Merge Hunter + Practitioner** — main agent collects structured findings.
6. **Skeptic pass (7a, mandatory)** — spawn Skeptic Task subagent **sequentially** with Hunter + Practitioner summaries in packaged prompt; no Skeptic skip at this tier.
7. **Verify ledger** — two-key rule; snippet-only headline hard cap 40 per `references/citation-protocol.md` and `references/confidence-rubric.md`.
8. **Synthesize** — `templates/deep-research-brief.md`; IEEE `[Sn]` only for verified rows.
9. **Score** — headline + full 5-axis per claim in `## confidence`.
10. **Drill** — up to 2 rounds per `references/drill-protocol.md` (auto round 1 when triggered); honest stop on futile conditions.
11. **Deliver** — chat + files per output format; fusion handoff suggestion on `## unverified` only if fusion installed.

## When to recommend

- Default for most research questions.
- Balanced evidence depth with mandatory challenge pass.
- Upgrade to `adversarial-deep` when conflicts remain or claims-investigation pack applies.
