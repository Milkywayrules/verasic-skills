# Template: risk-register

Launch, security, compliance, infra cutover — what could go wrong.

## Subagent answer shape

```markdown
| Risk | Likelihood | Impact | Mitigation |
| ---- | ---------- | ------ | ---------- |
| ...  | L/M/H      | L/M/H  | ...        |

**Top 3 priorities (this model):**

1. ...
```

## Fusion mapping

| Subagent section                | Core skeleton       |
| ------------------------------- | ------------------- |
| Fused top 3–5 risks             | `## answer`         |
| Full merged table (deduped)     | `## reasoning`      |
| Same risk, different L/I rating | `## conflicts`      |
| Each model's top 3 one-liner    | `## by model`       |
| Main agent mitigation priority  | `## recommendation` |

## Fusion notes

- Merge similar risks by name; keep severity conflicts in `## conflicts`.
- L×H disagreements on the same risk are always conflicts, never averaged silently.
