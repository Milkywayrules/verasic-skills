# Template: brief-research

Multi-model opinion brief — landscape scan, competitor/tool/pattern exploration with
evidence from each model's perspective.

**Not** `verasic-deep-research` — this template does not produce a verified source
ledger or confidence scoring. For ledger-backed research use `/verasic-deep-research`
(when installed).

## Subagent answer shape

```markdown
**Key findings:**

- ...

**Sources / evidence:**

- ...

**Gaps:**

- ...

**Suggested next steps:**

- ...

**Unique angle (this model only):**

- ...
```

## Fusion mapping

| Subagent section                   | Core skeleton       |
| ---------------------------------- | ------------------- |
| Deduped findings + next steps      | `## answer`         |
| Evidence trail, gaps               | `## reasoning`      |
| Contradictory facts between models | `## conflicts`      |
| Unique angle per model             | `## by model`       |
| Main agent prioritized next steps  | `## recommendation` |

## Fusion notes

- Dedupe findings in fusion but keep source attribution in `## reasoning`.
- Factual conflicts (not opinion) must appear in `## conflicts` with both sides cited.
