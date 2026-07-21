# Drill protocol — verasic-deep-research

Structured re-search when confidence is low. Max **2 rounds** per research session.
Default policy: `auto-at-threshold` (offer drill when triggers hit).

## Triggers

Offer drill when **any** of:

| Trigger | Condition                                              |
| ------- | ------------------------------------------------------ |
| Overall | Headline confidence **≤ 50**                           |
| Sensitive | Headline **≤ 60** on health / legal / financial topics |
| User    | `drill: always-offer` — offer even above thresholds    |

Do **not** auto-drill when `drill: off` — report scores and stop.

When `drill: auto-at-threshold` (default), main agent **offers** drill in chat:
_Want a drill round? (yes/no)_ — do not start round 2 without confirmation unless
user pre-authorized in the question.

## Max rounds

| Round | Focus                                                |
| ----- | ---------------------------------------------------- |
| 1     | Target lowest-axis claims; seek T0/T1 upgrades       |
| 2     | Narrow remaining gaps; adversarial check if not run  |

After round 2, stop — report plateau honestly.

## Drill execution

1. Identify claims below threshold or with `## gaps` entries.
2. Re-dispatch Hunter (and Practitioner if not yet run) with **narrowed queries**.
3. Re-run verify pipeline — append new ledger rows; never reuse failed rows as verified.
4. Re-score all affected claims; update overall headline.
5. If improvement < 5 points overall, note diminishing returns.

Optional: spawn Skeptic on round 2 for adversarial tier or when conflicts remain.

## Futile conditions (downgrade instead of drill)

Do **not** offer another drill round when:

| Condition | Action |
| --------- | ------ |
| Same sources re-found | Report plateau; suggest question reframing |
| No T0/T1 exists publicly | State evidentiary ceiling; list `## unverified` |
| Official contested position | Keep `## conflicts`; no drill inflation |
| Paywall blocks primary | Mark gap; no pretend verify |
| User `drill: off` | Skip offer |
| Round 2 complete | Stop |

**Downgrade rules:** lower headline honestly; move stuck claims to `## unverified` or
`partially-supported`; suggest fusion handoff only for opinion gaps (see `fusion-handoff.md`).

## Sensitive domain drill

Health / legal / financial: prefer drill offer at ≤60 even when overall > 60 if any
**material** claim is ≤55.

Include disclaimer that drill does not constitute professional advice.

## Chat copy (offer template)

```markdown
**Drill offered:** overall confidence is 48/100 (threshold ≤50).
A drill round would re-search: <claim list>.
Max 2 rounds per session. Continue? (yes/no)
```

## Integration with T3

Drill may batch new URLs through T3 leaf fetchers. T3 failure → T2 direct fetch;
not a blocker.

## Degraded mode

In sequential single-context degraded research, drill rounds run inline in the same
thread — label `drill round 1 (degraded)`.
