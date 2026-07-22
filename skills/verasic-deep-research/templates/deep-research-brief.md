# Deep research brief — deliver template

Human-readable output shape for `verasic-deep-research`. Main agent fills every section;
use `none` when empty. Read `references/research-protocol.md` for pipeline rules.

**Machine companion:** `source-ledger.yaml` in the same output directory when files are written.

## Sections (required order)

### ## answer

Direct response to the user question in plain language. Lead with the headline conclusion.
Use IEEE inline citations `[Sn]` only for verified ledger rows.

### ## reasoning

Step-by-step evidence chain linking claims to sources. Every material statement cites `[Sn]`.
Flag assumptions and inference steps explicitly.

### ## confidence

- **Headline:** 0–100 weighted score (pack-adjusted weights from domain pack).
- **Per claim:** full 5-axis table — SQ, EC, CG, CO, VR — plus computed headline per claim.
- Call out the **weakest axis** for each material claim.
- Note when sensitive-domain floor 60 applies.

**Axis legend** (mandatory in every brief — chat and files):

| Code | Axis | What it measures |
| ---- | ---- | ---------------- |
| SQ | Source Quality | Authority and tier of sources (T0–T3) |
| EC | Evidence Convergence | Independent sources agreeing |
| CG | Claim Grounding | How well excerpts support the claim |
| CO | Coverage | Scope, geography, time, alternatives explored |
| VR | Verification Rigor | Fetch success, ledger quality, recency |

Scores are structured estimates, not statistical certainty.

See `references/confidence-rubric.md` for axis definitions and scoring bands.

### ## conflicts

Contradictions between sources or interpretations. Never silently flatten. Include both
sides with `[Sn]` where verified. Use `none` if no material conflicts.

### ## claim ledger

**Conditional:** include only when domain pack is `claims-investigation` or user supplied
an explicit claim list.

| Claim | Verdict | Confidence | Sources | Notes |
| ----- | ------- | ---------- | ------- | ----- |

Verdict values: `supported` | `partially-supported` | `unsupported` | `contested` | `unverified`

### ## unverified

Claims, URLs, or angles that could not reach verify-before-cite. Candidate manual
follow-up via `references/fusion-handoff.md` when `verasic-fusion` is installed — never auto-run.

### ## references

IEEE numbered bibliography matching every `[Sn]` used in prose:

```text
[S1] Author or Org, "Title," Publisher/Site, Date, URL (accessed YYYY-MM-DD).
```

Omit failed or unverified rows.

### ## recommendation

Actionable next steps for the user: decisions, drill acceptance, boundary changes, or
Agent-mode file persistence. Separate facts (above) from judgment (here).

## Chat vs files

| Output mode   | Chat                         | Files                                      |
| ------------- | ---------------------------- | ------------------------------------------ |
| `chat-only`   | All sections (abbrev ok)     | none                                       |
| `chat+files`  | Summary + headline + axes    | full brief + `source-ledger.yaml`          |
| `files-only`  | pointer to path              | full brief + `source-ledger.yaml`          |

**Ask mode:** chat sections only; state files were not written.

## Fusion mapping

Not used by fusion subagents. For manual handoff, user may paste `## unverified` into
`verasic-fusion` with `template: brief-research` — opinions only, not ledger verification.
