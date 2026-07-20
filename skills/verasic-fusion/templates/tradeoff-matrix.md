# Template: tradeoff-matrix

Architecture, stack choice, build-vs-buy, or any named-option comparison.

## Optional invocation fields

```text
options: option A, option B, status quo
criteria-weights: cost 30, time 25, risk 25, flexibility 20
must-haves: SOC2, ship under 6 months
```

If omitted, each model proposes options/criteria/weights — fusion surfaces weight
disagreement explicitly.

## Subagent answer shape

```markdown
**Options considered:** A · B · C · (status quo)

**Must-haves**

| Criterion | A         | B   | C   |
| --------- | --------- | --- | --- |
| ...       | pass/fail |     |     |

**Scored criteria** (weight in parentheses)

| Criterion (weight) | A   | B   | C   |
| ------------------ | --- | --- | --- |
| cost (30%)         | 1–5 |     |     |
| ...                |     |     |     |

**Weighted totals:** A: X · B: Y · C: Z

**Pick:** A | B | C

**Sensitivity:** if <criterion/weight changed>, pick flips from X to Y

**Non-comparables:** <options that cannot share a row, or "none">
```

## Fusion mapping

| Subagent section                              | Core skeleton       |
| --------------------------------------------- | ------------------- |
| Pick + weighted totals + must-have summary    | `## answer`         |
| Matrix highlights, sensitivity                | `## reasoning`      |
| Different picks, weights, must-have pass/fail | `## conflicts`      |
| Each model's pick one line                    | `## by model`       |
| Robust vs fragile decision                    | `## recommendation` |

## Fusion notes

- State whether the fused decision is **robust** or **fragile** (sensitivity-driven).
- Non-comparables belong in `## reasoning`, not hidden.
