# Template: rfc-review

Spec, ADR, pitch doc, or build proposal review before implementation.

## Subagent answer shape

```markdown
**Verdict:** APPROVE | REQUEST_CHANGES | NEEDS_DISCUSSION

**Summary:**

<one paragraph>

**Blocking concerns:**

- ... (or "none")

**Non-blocking suggestions:**

- ...

**Questions for the author:**

- ...
```

## Fusion mapping

| Subagent section                       | Core skeleton       |
| -------------------------------------- | ------------------- |
| Verdict + summary                      | `## answer`         |
| Blocking + non-blocking + questions    | `## reasoning`      |
| Verdict splits, blocking disagreements | `## conflicts`      |
| Per-model verdict one-liner            | `## by model`       |
| Main agent synthesis                   | `## recommendation` |

## Fusion notes

- Blocking concerns from any model appear in `## conflicts` even if fused verdict is APPROVE.
- `NEEDS_DISCUSSION` is not APPROVE — count separately in `## answer`.
