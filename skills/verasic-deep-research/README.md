# Verasic Deep Research

Verified deep research with source ledger, verify-before-cite, and 5-axis confidence
scoring. Main agent orchestrates T2 research workers; optional T3 leaf fetchers for
parallel URL retrieval.

## Parts

Paths relative to this skill folder. After `setup.sh`, the same files live under
`.cursor/skills/verasic-deep-research/`.

| File                                      | Role                                      |
| ----------------------------------------- | ----------------------------------------- |
| `references/research-protocol.md`         | Single source of truth                    |
| `references/helper.md`                    | Help text for bare `/verasic-deep-research` |
| `references/citation-protocol.md`         | Verify pipeline, SourceRecord, two-key rule |
| `references/confidence-rubric.md`         | SQ / EC / CG / CO / VR scoring (Claim Grounding, Evidence Convergence, Verification Rigor) |
| `references/drill-protocol.md`            | Drill triggers, futile conditions         |
| `references/source-tiers.md`              | T0–T3 classification                      |
| `references/fusion-handoff.md`            | Manual chain to verasic-fusion            |
| `templates/deep-research-brief.md`        | Deliver template sections                 |
| `workflows/quick-scan.md` (etc.)          | Tier checklists per depth                 |
| `SKILL.md`                                | Auto-trigger + orchestration                |
| `.cursor/commands/verasic-deep-research.md` | Slash command (after `setup.sh`)        |

## Human workflow

1. Choose `depth`, `output`, and `source-boundary` (no defaults on output or boundary).
2. Run `/verasic-deep-research` with your question — or attach the skill in chat.
3. Answer pre-flight prompts; read honesty notices in `references/helper.md`.
4. Main agent runs discover → verify ledger → synthesize → score → drill → deliver.
5. Files land in `./docs/research/<slug>/` when output includes files (Agent mode only).

Typing `/verasic` shows deep-research alongside fusion, review, audit, init, and github setup.

## Required every run

```text
depth: quick-scan | standard-research | adversarial-deep | custom
output: chat-only | chat+files | files-only | custom
source-boundary: public-standard | public-extended | aggressive-scrape
languages: <cite/search/report>
<question>
```

No default output format. No default source boundary. Agent recommends `public-standard`.

## Difference from verasic-fusion brief-research

| | Deep research | Fusion `brief-research` |
| --- | --- | --- |
| Verification | Fetch + verify-before-cite ledger | Model opinions, no ledger |
| Confidence | 5-axis per claim + headline | None |
| Drill | Up to 2 structured rounds | N/A |
| Best for | Facts, compliance, due diligence | Brainstorming, multi-model angles |

Unverified gaps may suggest a **manual** `/verasic-fusion` follow-up when fusion is
installed — see `references/fusion-handoff.md`.

## Output path

Default file root: `./docs/research/<slug>/` (kebab-case from question).

Typical files: `deep-research-brief.md` and `source-ledger.yaml` under `./docs/research/<slug>/`.

**Ask mode:** chat only — no file writes.

## Depth tiers

| Depth               | T2 dispatch                                                                 |
| ------------------- | --------------------------------------------------------------------------- |
| `quick-scan`        | Hunter — no Skeptic                                                         |
| `standard-research` | Hunter + Practitioner (parallel) → Skeptic (sequential)                     |
| `adversarial-deep`  | Hunter + Practitioner + Skeptic + Arbiter (4 parallel)                      |
| `custom`            | User-specified roles                                                        |

## Honesty

Scores are estimates; verify fails often; drill plateaus exist. Full A–Z list:
`references/helper.md` ## honesty (read this).

## Scope

Research and file deliverables per user output choice. Refuses insider data and illegal
collection outside explicit user boundary. Not professional health, legal, or financial advice.

Security: [references/scanner-notes.md](references/scanner-notes.md) · upstream [SECURITY.md](https://github.com/Milkywayrules/verasic-skills/blob/main/SECURITY.md)

## Install

From the project root:

```bash
curl -fsSL https://raw.githubusercontent.com/Milkywayrules/verasic-skills/main/setup.sh | bash
```

Skill-only (any agent): `npx skills add Milkywayrules/verasic-skills`

Then: `/verasic-init` or `bash .cursor/skills/verasic-init/scripts/init.sh`

## Testing / Publish gate

From the verasic-skills repo root:

```bash
bash skills/verasic-deep-research/scripts/test-exhaustive.sh
```

After `setup.sh` in a consumer project:

```bash
bash .cursor/skills/verasic-deep-research/scripts/test-exhaustive.sh
```

Live harness checklist: `references/use-cases.md` (UC-0 through UC-7).

## Known limits

- **Cursor-first** — parallel T2 spawn uses the Task tool; other agents run degraded sequential after confirmation.
- **Public sources** — paywalls and blocks produce gaps, not invented citations.
- **T3 optional** — leaf jobs spawned by T2; failure falls back to T2/T1 direct fetch.
- **Fusion optional** — handoff is manual; never auto-spawned.
