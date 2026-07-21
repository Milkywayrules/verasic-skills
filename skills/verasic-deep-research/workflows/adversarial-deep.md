# Workflow: adversarial-deep

Depth preset: `adversarial-deep`. Read `references/research-protocol.md` first.

**Target:** ~30+ minutes soft budget. Hunter + Practitioner + Skeptic + Arbiter (4 parallel).

## Steps

1. **Pre-flight** — complete gate; confirm user accepts latency/cost; honesty notices.
2. **Load domain pack** — prefer `claims-investigation` or `health-fitness` packs when applicable; enable `## claim ledger` when investigating explicit claims.
3. **Dispatch T2 parallel (4)** — spawn Hunter, Practitioner, Skeptic, and Arbiter Task subagents in parallel with same packaged prompt (richest tier).
4. **T3 fetch batch** — T2 spawns T3 leaf jobs in parallel; degraded note if T3 fails; T2 direct fallback.
5. **Verify ledger** — all roles feed main-agent merge; conflicts stay in ledger.
6. **Synthesize** — full `templates/deep-research-brief.md` including `## conflicts` and conditional `## claim ledger`.
7. **Score** — 5-axis with pack weights; sensitive floor 60; chat shows headline + per-claim axes + weakest axis callout.
8. **Drill** — max 2 rounds; auto round 1 when triggered; apply futile conditions (same sources, no T0/T1, contested, paywall).
9. **Deliver** — chat + files; optional fusion handoff block on `## unverified` if `verasic-fusion` detected.

## When to recommend

- High-stakes decisions, contested topics, or explicit claims investigation.
- User requests devil's-advocate depth or multiple independent challenges.
- Prior `standard-research` run left material conflicts or low EC/VR scores.
