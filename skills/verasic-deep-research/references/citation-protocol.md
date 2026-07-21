# Citation protocol — verasic-deep-research

Verify-before-cite pipeline, SourceRecord fields, two-key rule, and conflict
handling. Read alongside `research-protocol.md`.

## Verify pipeline

Every candidate citation runs this pipeline before receiving a ledger `[Sn]` number.

```text
discover URL → fetch (T3 or T2/T1) → extract support → two-key check → tier classify → ledger row
```

| Step    | Action                                                                 |
| ------- | ---------------------------------------------------------------------- |
| Fetch   | Readonly HTTP or browser fetch per source boundary                     |
| Extract | Locate passage supporting the claim; max 40 words for snippet fallback |
| Two-key | URL key + support key must both pass (below)                           |
| Tier    | Assign T0–T3 per `source-tiers.md`                                     |
| Ledger  | Append row; assign `[Sn]` only on `yes` or `snippet-only`              |

**Failed verify** → row may exist with `Verified: failed` for audit, but **must not** cite in prose.

## SourceRecord fields

Each ledger row (chat table or `source-ledger.yaml`) uses these fields:

| Field           | Required | Description                                              |
| --------------- | -------- | -------------------------------------------------------- |
| `Sn`            | yes      | IEEE citation number `[Sn]`                              |
| `url`           | yes      | Canonical URL fetched                                    |
| `title`         | yes      | Page or document title                                   |
| `tier`          | yes      | T0, T1, T2, or T3                                        |
| `verified`      | yes      | `yes` \| `snippet-only` \| `failed` \| `contested`       |
| `snippet`       | cond.    | ≤40 words supporting text; required for `snippet-only`   |
| `accessed`      | yes      | ISO date of fetch (UTC)                                  |
| `domain_tags`   | no       | e.g. `health`, `legal`, `financial`                      |
| `notes`         | no       | Paywall, redirect, conflict flags, fetch errors     |
| `claim_ids`     | no       | Links row to claims in `## claim ledger`                 |

### Snippet fallback

When live page content differs from search preview or memory:

1. Store ≤40 words in `snippet` from the best available readonly capture.
2. Set `verified: snippet-only`.
3. Note mismatch in `notes`.
4. Score with tier penalty per `confidence-rubric.md`.

Never expand snippet post-hoc beyond 40 words.

## Two-key rule

A claim earns a citable `[Sn]` only when **both** keys pass:

| Key          | Pass condition                                                        |
| ------------ | --------------------------------------------------------------------- |
| **URL key**  | Fetch succeeded (HTTP 200 or equivalent); URL matches intended source |
| **Support key** | Extracted snippet directly supports the specific claim wording   |

If URL key passes but support key fails → `failed` or omit claim; do not cite.

If support exists only in secondary summary (no primary fetch) → not citable unless
primary fetch confirms.

## IEEE citation format

**In prose:** claim statement `[1]` or `[1], [3]`.

**In ## sources:**

```text
[1] A. Author, "Title," Publisher, Year. [Online]. Available: URL. Accessed: YYYY-MM-DD.
```

Adapt to available metadata — use organization name when author unknown. Consistency
within a deliverable matters more than perfect bibliographic completeness.

## Contradiction flag

When two verified sources disagree on a material fact:

1. Set both ledger rows `verified: contested` **or** keep `yes` with linked `notes`.
2. Populate `## conflicts` with both `[Sn]` sides.
3. Do not pick a winner silently — Arbiter (adversarial tier) or main agent states
   conditional recommendation.
4. Confidence for contested claims: cap headline per rubric contested rule.

## Paywall and block handling

| Condition              | Ledger action                          | Cite in prose? |
| ---------------------- | -------------------------------------- | -------------- |
| Full fetch + support   | `verified: yes`                        | yes            |
| Partial / preview only | `snippet-only` if support key passes   | yes, with note |
| Hard paywall, no text  | `verified: failed`, note paywall       | no             |
| robots/block           | retry once; then failed or T3 fallback  | no             |

## No cite without ledger row

Hard gate for main agent and all T2 workers:

- Draft prose without `[Sn]` until ledger merge completes.
- Strip orphan `[Sn]` that lack rows before deliver.
- Chat summary lists ledger row count vs citation count — must match.

## Worker return shape (for T2 merge)

T2 workers return candidate SourceRecords — main agent re-runs verify pipeline;
worker assertions alone are never sufficient for `verified: yes`.

```markdown
## candidate sources

| url | tier_hint | snippet | supports_claim | fetch_status |
| --- | --------- | ------- | -------------- | ------------ |
```

Main agent promotes candidates to ledger after independent verify.
