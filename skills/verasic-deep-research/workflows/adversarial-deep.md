# Workflow: adversarial-deep

Depth preset: `adversarial-deep`. Read `references/research-protocol.md` first.

**Target:** ~30+ minutes soft budget. Hunter + Practitioner + Skeptic + Arbiter; richest tier.

## Steps

1. **Pre-flight** — complete gate; confirm user accepts latency/cost; honesty notices.
2. **Load domain pack** — prefer `claims-investigation` or `health-fitness` packs when applicable; enable `## claim ledger` when investigating explicit claims.
3. **Round A — parallel discovery** — spawn Hunter + Practitioner Task subagents in parallel.
4. **T3 fetch batch** — parallel leaf fetch; degraded note if T3 fails.
5. **Round B — adversarial** — spawn Skeptic with Practitioner/Hunter summaries in packaged prompt (sequential dependency, same research round).
6. **Round C — arbiter** — spawn Arbiter Task subagent to rank sources and flag contested claims.
7. **Verify ledger** — all roles feed main-agent merge; conflicts stay in ledger.
8. **Synthesize** — full `templates/deep-research-brief.md` including `## conflicts` and conditional `## claim ledger`.
9. **Score** — 5-axis with pack weights; sensitive floor 60; chat shows headline + per-claim axes + weakest axis callout.
10. **Drill** — max 2 rounds; apply futile conditions (same sources, no T0/T1, contested, paywall).
11. **Deliver** — chat + files; optional fusion handoff block on `## unverified` if `verasic-fusion` detected.

## When to recommend

- High-stakes decisions, contested topics, or explicit claims investigation.
- User requests devil's-advocate depth or multiple independent challenges.
- Prior `standard-research` run left material conflicts or low EC/VR scores.
