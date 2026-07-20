# Template: stakeholder-lens

Same question through assigned stakeholder perspectives. **Explicit map required.**

## Required invocation fields

```text
template: stakeholder-lens
lens-map:
  <model-slug>: <lens>
  <model-slug>: <lens>
```

Rules:

- Every model in `models` must appear **exactly once** in `lens-map`.
- Missing, extra, or duplicate entries → pre-flight fail; ask user to fix.
- No round-robin. No auto-assignment.

Optional: `lenses: ceo, cto, customer` as human-readable reference only — `lens-map`
remains authoritative.

## Subagent answer shape

Each subagent receives their assigned lens in the packaged prompt.

```markdown
**Lens:** <assigned lens>

**Care about most:**

**Dealbreakers:**

**What we'd need to see:**
```

## Fusion mapping

| Subagent section                             | Core skeleton       |
| -------------------------------------------- | ------------------- |
| Alignment summary (who blocks, who supports) | `## answer`         |
| Per-lens needs and dealbreakers              | `## reasoning`      |
| Conflicting dealbreakers across lenses       | `## conflicts`      |
| Full per-model/lens block                    | `## by model`       |
| Path to align stakeholders                   | `## recommendation` |

## Fusion notes

- Use lens names from `lens-map` in headings: `### composer-2.5-fast (ceo)`.
