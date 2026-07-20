# Template: premortem

Assume the initiative failed at a future date; work backward to causes and prevention.

## Subagent answer shape

```markdown
**Failure scenario:**

<one paragraph — assume failure at T+12 months unless user specifies>

**Root causes:**

- ...

**Early warning signs:**

- ...

**Preventive actions:**

- ...
```

## Fusion mapping

| Subagent section                         | Core skeleton       |
| ---------------------------------------- | ------------------- |
| Fused failure scenario + top root causes | `## answer`         |
| Warning signs + preventive actions       | `## reasoning`      |
| Different root cause rankings            | `## conflicts`      |
| Each model's #1 root cause               | `## by model`       |
| Main agent prevention priority           | `## recommendation` |

## Fusion notes

- Prefer actionable preventive actions in `## recommendation` over repeating scenarios.
