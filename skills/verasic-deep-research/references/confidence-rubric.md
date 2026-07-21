# Confidence rubric — verasic-deep-research

Five-axis confidence scoring for per-claim and overall headline scores. Weights
come from the active **domain pack** (`references/domain-packs/*.yaml`); scores are
estimates — see helper ## honesty.

## Axes

| Code | Axis                   | Question answered                                      | Range |
| ---- | ---------------------- | ------------------------------------------------------ | ----- |
| **SQ** | Source Quality       | How authoritative are the best sources for this claim? | 0–100 |
| **EC** | Evidence Corroboration | How many independent sources agree?                    | 0–100 |
| **CG** | Claim Granularity      | How specific vs vague is the claim?                    | 0–100 |
| **CO** | Coverage             | How well do sources cover scope, geography, time?        | 0–100 |
| **VR** | Verification Recency | How fresh is the evidence vs claim time-sensitivity?   | 0–100 |

### Axis guidance

**SQ** — tier-weighted: T0-heavy claims score higher; T3-only caps SQ ≤ 40 unless
snippet-only with explicit penalty already applied.

**EC** — independent origins count; same press release syndicated does not multiply EC.

**CG** — "AI Act exists" scores high granularity for a boolean; "soon" scores low unless dated.

**CO** — penalize US-only sources for EU-only questions; penalize 2019 docs for 2026 ops claims.

**VR** — use `accessed` date and document publication date; fast-moving tech/regulatory topics
decay VR faster (domain pack multiplier).

## Domain packs (default weights)

Load from `references/domain-packs/<id>.yaml`. Each pack defines `axis_weights`
(SQ, EC, CG, CO, VR — normalize to sum 1.0), optional `floor`, `ceiling`, `recency_months`,
and `source_hints`. Override with `domain:` when user specifies a pack id.

Built-in table when YAML unavailable (fallback only):

| Pack       | SQ   | EC   | CG   | CO   | VR   | Notes                          |
| ---------- | ---- | ---- | ---- | ---- | ---- | ------------------------------ |
| `general`  | 0.25 | 0.25 | 0.15 | 0.20 | 0.15 | Default when auto-infer         |
| `health`   | 0.30 | 0.25 | 0.15 | 0.15 | 0.15 | Sensitive floor 60              |
| `legal`    | 0.30 | 0.20 | 0.20 | 0.15 | 0.15 | Sensitive floor 60              |
| `financial`| 0.28 | 0.22 | 0.15 | 0.15 | 0.20 | Sensitive floor 60              |
| `tech`     | 0.22 | 0.22 | 0.18 | 0.18 | 0.20 | VR elevated for fast-moving stack |

Multi-domain: use primary pack weights; note secondary in `## confidence` footnote.

## Per-claim score

```text
claim_score = round( SQ*w_SQ + EC*w_EC + CG*w_CG + CO*w_CO + VR*w_VR )
```

Show all five axes in chat for every material claim in `## confidence`:

```markdown
### Claim: <text>

| Axis | Score | Rationale (one line) |
| ---- | ----- | -------------------- |
| SQ   | 85    | T0 regulator text [1] |
| EC   | 70    | Two independent T1 outlets [1][3] |
| CG   | 90    | Dated enforcement milestone |
| CO   | 65    | EU-wide; no member-state detail |
| VR   | 80    | 2025 doc, accessed 2026 |
| **Headline** | **78** | weighted |
```

### Adjustments

| Condition              | Adjustment                                    |
| ---------------------- | --------------------------------------------- |
| `snippet-only` only    | SQ −15; headline note                         |
| Single T3 source       | EC cap 40; headline cap 50                     |
| `contested`            | headline cap 55 unless T0 majority            |
| Sensitive domain floor | display headline = max(computed, 60) with note  |

Sensitive floor applies to **display headline** for health/legal/financial — always show
true computed score in axis table.

## Overall headline

```text
overall = round( weighted mean of claim headlines, weighting material claims 2x peripheral )
```

Material vs peripheral: main agent labels in deliverable; default all claims-investigation
rows are material.

Chat deliverable **always** includes:

```markdown
## confidence

**Overall headline: 72/100** (general pack)

<sensitive-domain floor note if applicable>

### Per-claim breakdown
...
```

## Confidence bands

| Band   | Range  | Label              | Delivery tone                          |
| ------ | ------ | ------------------ | -------------------------------------- |
| High   | 80–100 | strong evidence    | Suitable for operational decisions with normal caveats |
| Medium | 60–79  | moderate evidence  | Useful; note gaps explicitly           |
| Low    | 40–59  | weak evidence      | Recommend drill or fusion on gaps      |
| Poor   | 0–39   | insufficient       | Do not imply factual certainty         |

## Headline formula (summary)

```text
headline = weighted_sum(axes, domain_pack_weights)
apply caps (contested, T3-only, snippet-only)
apply sensitive display floor if health|legal|financial
round to integer
```

Drill trigger cross-reference: see `drill-protocol.md` (≤50 overall or ≤60 on sensitive).
