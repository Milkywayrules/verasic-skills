# Template: compare-to-status-quo

Evaluate whether to change anything when doing nothing is a valid outcome.

## Subagent answer shape

```markdown
**Status quo OK?** YES | NO | PARTIALLY

**Cost of change vs cost of inaction:**

**Minimum viable change:**

<smallest change worth making, or "none">
```

## Fusion mapping

| Subagent section                          | Core skeleton       |
| ----------------------------------------- | ------------------- |
| Fused status-quo assessment               | `## answer`         |
| Cost comparison detail                    | `## reasoning`      |
| YES vs NO vs PARTIALLY split              | `## conflicts`      |
| Each model's status-quo line              | `## by model`       |
| Main agent: change, wait, or minimal step | `## recommendation` |

## Fusion notes

- Resist action bias — `## recommendation` may legitimately be "maintain status quo."
- PARTIALLY counts as conditional; list conditions in `## conflicts`.
