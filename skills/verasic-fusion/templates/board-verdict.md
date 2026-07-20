# Template: board-verdict

BOD / leadership binary decision on a proposal.

## Subagent answer shape

```markdown
**YES / NO / YES_WITH_NOTES / NO_WITH_NOTES**:

**Reasoning**:

- ...

**Additional from me**:

<freeform — any format>
```

## Fusion mapping

| Subagent section     | Core skeleton                                       |
| -------------------- | --------------------------------------------------- |
| Verdict line         | `## answer` (fused verdict or split if no majority) |
| Reasoning bullets    | `## reasoning`                                      |
| Disagreements        | `## conflicts`                                      |
| Additional from me   | `## by model` (per-model freeform preserved)        |
| Main agent synthesis | `## recommendation`                                 |

## Fusion notes

- If verdicts split (e.g. 2 YES, 2 NO), `## answer` states the split; do not fake unanimity.
- `YES_WITH_NOTES` and `NO_WITH_NOTES` count as YES/NO with conditions — list conditions in
  `## conflicts` when they differ across models.
