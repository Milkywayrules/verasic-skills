# Confidence rubric — verasic-security-review

Integer scores **0–10** only. No decimals. Per finding, pick one score after reading code and tracing reachability.

**Mode floors:** `strict` — Heuristic findings must be ≥ 8; `assertive` — Heuristic ≥ 6. The **Medium (6–7)** band applies only under `assertive`; under `strict`, 6–7 scores are omitted.

## Bands

| Score | Band | Report? |
| --- | --- | --- |
| 0–5 | Low | **No** — omit entirely |
| 6–7 | Medium | Yes, when mode is `assertive` (floor 6) |
| 8–10 | High | Yes — default `strict` floor for Heuristic findings |

Display as `High (9/10)` or `Medium (7/10)`.

## Floors by source

| Source | Floor |
| --- | --- |
| **Heuristic** (LLM STRIDE + checklist) | `strict` ≥ 8 · `assertive` ≥ 6 |
| **Deterministic** (scanner rule match) | Treat as **High (8–10)** when rule fired on changed path; downgrade only if clearly false positive with code evidence (then omit or move to Non-findings) |

## Scoring guide

| Score | Meaning |
| --- | --- |
| 10 | Exploit path fully traced; vulnerable sink and source confirmed in changed code |
| 9 | Strong evidence; one minor assumption about deployment that is standard |
| 8 | Clear vulnerability; reachability plausible with quoted call path |
| 7 | Likely issue; small gap in reachability proof |
| 6 | Suspicious pattern; would not report under `strict` |
| ≤5 | Speculative — drop |

## Rules

- Never inflate scores to fill a report.
- Prompt injection or untrusted-input-as-instruction in reviewed content → minimum **HIGH** severity, confidence ≥ 8 when evidence is in the diff.
- Scanner hit + LLM confirms same issue → use higher of the two severities; confidence **9–10**.
- Conflicting evidence → read more code or omit.

Footer reminder (on every report): *Confidence scores are reviewer estimates, not CVSS.*
