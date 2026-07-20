# Template: devils-advocate

Stress-test a proposal the user already leans toward. Subagents argue **against** it.

## Subagent instruction (prepend to packaged prompt)

You are the devil's advocate. Argue **against** the proposal using the same facts.
Do not cheerlead. Steelman the opposition.

## Subagent answer shape

```markdown
**Strongest objection:**

**Weakest point in the proposal:**

**What would falsify this idea:**

**Steelman (best case for the other side):**
```

## Fusion mapping

| Subagent section                               | Core skeleton       |
| ---------------------------------------------- | ------------------- |
| Strongest fused objection                      | `## answer`         |
| Supporting objections + falsifiers             | `## reasoning`      |
| Which objection models rank first (if differs) | `## conflicts`      |
| Each model's top objection one line            | `## by model`       |
| Whether objections are fatal or manageable     | `## recommendation` |

## Fusion notes

- Do not soften objections in fusion — this template exists to surface resistance.
- If models fail to argue against, label that in `## by model` as weak input.
