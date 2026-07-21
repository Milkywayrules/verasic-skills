# Drill protocol — verasic-deep-research

Structured re-search when confidence is low. Max **2 rounds** per research session.
Default policy: `auto-at-threshold` (auto-execute round 1 when triggers hit).

## Triggers

Run drill when **any** of:

| Trigger | Condition                                              |
| ------- | ------------------------------------------------------ |
| Overall | Headline confidence **≤ 50**                           |
| Sensitive | Headline **≤ 60** on health / legal / financial topics |
| User    | `drill: always-offer` — offer even above thresholds    |

Do **not** drill when `drill: off` — report scores and stop.

### Policy behavior

| Policy               | Round 1                                      | Round 2                                      |
| -------------------- | -------------------------------------------- | -------------------------------------------- |
| `auto-at-threshold`  | **Auto-execute** when trigger hit (no ask)   | **Offer** yes/no before executing            |
| `always-offer`       | Offer yes/no before executing                | Offer yes/no before executing                |
| `off`                | Skip                                         | Skip                                         |

When `drill: auto-at-threshold` (default), main agent **auto-executes drill round 1**
without asking when a trigger fires. Before round 2, **offer** in chat:
_Want drill round 2? (yes/no)_ — do not start round 2 without confirmation.

When `drill: always-offer`, offer yes/no before **both** rounds (even above thresholds).

## Max rounds

| Round | Focus                                                |
| ----- | ---------------------------------------------------- |
| 1     | Target lowest-axis claims; seek T0/T1 upgrades       |
| 2     | Narrow remaining gaps; adversarial check if not run  |

After round 2: **stop**, downgrade honestly, report plateau — no round 3.

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
| User `drill: off` | Skip drill entirely |
| Round 2 complete | Stop; downgrade; honest plateau |

**Downgrade rules:** lower headline honestly; move stuck claims to `## unverified` or
`partially-supported`; suggest fusion handoff only for opinion gaps (see `fusion-handoff.md`).

## Sensitive domain drill

Health / legal / financial: prefer drill at ≤60 even when overall > 60 if any
**material** claim is ≤55.

Include disclaimer that drill does not constitute professional advice.

## Chat copy (templates)

**Round 1 auto (auto-at-threshold):**

```markdown
**Drill round 1 (auto):** overall confidence is 48/100 (threshold ≤50).
Re-searching: <claim list>.
```

**Round 2 offer:**

```markdown
**Drill round 2 offered:** after round 1, overall is 52/100.
A second drill round would target: <remaining gaps>.
Continue? (yes/no)
```

**Always-offer (round 1):**

```markdown
**Drill offered:** overall confidence is 48/100 (threshold ≤50).
A drill round would re-search: <claim list>.
Max 2 rounds per session. Continue? (yes/no)
```

## Integration with T3

Drill may batch new URLs through T3 leaf jobs (`fetch-url`, `verify-one-claim`, etc.).
T3 failure → T2 direct fallback; not a blocker.

## Degraded mode

In sequential single-context degraded research, drill rounds run inline in the same
thread — label `drill round 1 (degraded)`.
