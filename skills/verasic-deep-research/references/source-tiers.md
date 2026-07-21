# Source tiers — verasic-deep-research

Classification for ledger rows and confidence scoring. Assign tier at verify time
using best judgment — when borderline, pick the lower tier.

## Tier table

| Tier | Label              | Examples                                              | Default axis weight bias |
| ---- | ------------------ | ----------------------------------------------------- | ------------------------ |
| **T0** | Primary authority  | Statute/regulation text, standards body (ISO, IETF, W3C), peer-reviewed paper, official vendor docs/API reference, court ruling (public) | Highest SQ, CG |
| **T1** | Credible secondary | Reputable news (Reuters, AP), established industry analyst with methodology, university press release linking to paper, official blog with primary link | High SQ |
| **T2** | Tertiary / opinion | General news commentary, reputable blog without primary data, conference talk slides without paper, Stack Overflow accepted answer | Moderate SQ; EC matters more |
| **T3** | Weak / social      | Forums, social posts, anonymous wiki edits, SEO aggregators, unverified mirrors | Low SQ; cap claim confidence |

## Assignment rules

1. **Prefer primary** — if T0 full text is available, do not cite T2 summary instead.
2. **Vendor claims** — marketing page alone is T2; docs/API spec is T0/T1.
3. **Translations** — tier the source actually fetched; note language in `notes`.
4. **Aggregators** — tier of aggregator max T2 unless linking to T0 primary verified.
5. **Extended boundary** — `public-extended` may include T3; must label tier honestly.

## Domain-specific T0 hints

| Domain     | T0 examples                                      |
| ---------- | ------------------------------------------------ |
| Health     | WHO, CDC, FDA, EMA, Cochrane, PubMed primary     |
| Legal      | Official gazette, court docket, regulator text   |
| Financial  | SEC EDGAR, central bank publications, IFRS body  |
| Tech       | Spec RFC, vendor API docs, CVE database          |

## Tier and drill

Drill rounds prioritize upgrading claim support from T2/T3 → T0/T1 when futile
conditions (see `drill-protocol.md`) are not met.

## Tier downgrade triggers

| Signal                         | Action                          |
| ------------------------------ | ------------------------------- |
| Redirect to different domain   | Re-verify; often downgrade      |
| Undated / deprecated doc       | Note in ledger; VR axis penalty |
| Conflicting T0 sources         | `contested`; no tier inflation  |
