# verasic-deep-research — protocol

Single source of truth for ledger-backed deep research. Agents read this file
and follow it exactly — never duplicate the protocol elsewhere.

## Purpose

Verified, ledger-backed research with 5-axis confidence scoring. Every cited
claim maps to a row in the source ledger that passed verify-before-cite. The
main agent orchestrates discovery, verification, synthesis, scoring, optional
drill, and delivery.

**In scope:** public-source research, claims investigation, adversarial review,
file deliverables when the user chooses a file output format.

**Out of scope:** insider data, paywalled content without user-provided access,
illegal scraping beyond an explicit user-stated boundary, and silent invention
of sources or confidence.

## Architecture

| Tier | Role            | Task spawn | Responsibility                                                                 |
| ---- | --------------- | ---------- | ------------------------------------------------------------------------------ |
| T1   | Main agent      | yes        | Pre-flight, orchestration, ledger merge, verify gate, score, drill, deliver    |
| T2   | Hunter          | yes        | Broad discovery — candidates, URLs, leads, domain packs                        |
| T2   | Practitioner    | yes        | Deep read — extract claims, snippets, methodology, primary sources             |
| T2   | Skeptic         | yes        | Challenge claims — conflicts, weak evidence, missing primary sources      |
| T2   | Arbiter         | yes        | Resolve conflicts — rank sources, flag contested claims (adversarial tier)     |
| T3   | Leaf worker     | no         | Grandchild jobs spawned **by T2** — bounded fetch/extract/search/verify only |

T3 workers are leaf jobs spawned by T2 (grandchild tier — **no Task tool**). When T3
fails or is unavailable, T2 (or T1 in degraded mode) performs the same work directly —
**not a blocker**.

No dedicated subagent definition files. Spawn generic Task subagents with
role instructions from this protocol and absolute paths to reference files.

### Skill path resolution

Resolve the skill root as the directory that contains `references/research-protocol.md`
(for example `.cursor/skills/verasic-deep-research/` or `.agents/skills/verasic-deep-research/`).
Pass **absolute paths** to subagents:

- Protocol: `<skill-root>/references/research-protocol.md`
- Citation: `<skill-root>/references/citation-protocol.md`
- Confidence: `<skill-root>/references/confidence-rubric.md`
- Source tiers: `<skill-root>/references/source-tiers.md`
- Deliver template: `<skill-root>/templates/deep-research-brief.md`

## Pre-flight gate

Do **not** fetch sources or spawn workers until all required fields are present.

| Field              | Required | Rule                                                                                      |
| ------------------ | -------- | ----------------------------------------------------------------------------------------- |
| Question           | yes      | The research question or claims to investigate                                            |
| `depth`            | yes      | One of: `quick-scan`, `standard-research`, `adversarial-deep`, `custom`                   |
| `output`           | yes      | One of: `chat-only`, `chat+files`, `files-only`, `custom` — **no default**                |
| Output path        | cond.    | Required when `output` includes files; default convention `./docs/research/<slug>/`       |
| `source-boundary`  | yes      | One of: `public-standard`, `public-extended`, `aggressive-scrape` + optional free text  |
| Languages          | yes      | Cite / search / report languages (default: prompt language unless user overrides)         |
| `models`           | no       | Optional T2 model roster; recommend including `composer-2.5-fast`                         |
| `domain`           | no       | Optional domain pack override; auto-infer when omitted                                    |
| `drill`            | no       | Optional; default `auto-at-threshold` (see `references/drill-protocol.md`)                |
| Custom depth roles | cond.    | Required when `depth: custom` — which T2 workers to spawn                                 |

If any required field is missing → ask once, stop. **No default output format. No default source boundary.**

### Honesty at pre-flight

At each pre-flight step, include a **1–2 line honesty notice** from
`references/helper.md` ## honesty (read this). Do not skip these notices when
collecting fields.

| Step              | Notice focus                                      |
| ----------------- | ------------------------------------------------- |
| Question          | Scores are estimates; verify fails often          |
| Depth tier        | Drill plateau; tier cost/latency                  |
| Output format     | Ask mode = no file writes                         |
| Source boundary   | Boundary warnings; agent recommends public-standard |
| Languages         | Search/cite language mismatch risk                |
| Optional roster   | T3 fallback; model availability                     |

### Source boundary

| Boundary              | Meaning                                                                 |
| --------------------- | ----------------------------------------------------------------------- |
| `public-standard`     | Official docs, standards bodies, reputable news, academic preprints, vendor docs |
| `public-extended`     | Above plus forums, blogs, social posts — lower default tier             |
| `aggressive-scrape`   | User accepts higher block/rate-limit risk; still no paywall bypass      |

Agent **recommends** `public-standard` unless the user has a documented reason
to widen. Free-text qualifiers append to the boundary (e.g. jurisdiction, date floor).

**Refuse:** insider data, credentials-required proprietary databases without
user-supplied access, and illegal collection outside an explicit user-stated boundary.

### Output format and Ask mode

| Output          | Chat | Files |
| --------------- | ---- | ----- |
| `chat-only`     | yes  | no    |
| `chat+files`    | yes  | yes   |
| `files-only`    | no   | yes   |
| `custom`        | per user spec | per user spec |

**Ask mode (read-only chat):** deliver in chat only — **never write files**, even when
the user chose `chat+files` or `files-only`. Say so plainly and offer Agent mode or
`chat-only` continuation.

When files are allowed, write under `./docs/research/<slug>/` unless the user gives
another path. `<slug>` is a kebab-case short name derived from the question.

**Agent mode + `chat+files`:** in the same turn before ending the response, deliver the chat summary
**and** write the research files under the output path. Do not deliver chat-only first and defer file
writes to a later turn unless the user explicitly asks for staged delivery.

## Pipeline

```text
pre-flight → discover → verify ledger → synthesize → score → drill → deliver
```

1. **Pre-flight** — collect required fields; honesty notices; infer domain pack if needed.
2. **Discover** — dispatch T2 (and optional T3) per depth tier; collect candidate sources
   and raw extracts.
3. **Verify ledger** — run verify-before-cite for every candidate claim; build ledger rows
   per `references/citation-protocol.md`. Drop or downgrade unverified claims.
4. **Synthesize** — merge verified claims into narrative; flag conflicts; populate
   deliver sections per `templates/deep-research-brief.md`.
5. **Score** — 5-axis confidence per claim and overall headline per
   `references/confidence-rubric.md`; apply sensitive-domain floor 60.
6. **Drill** — when thresholds hit and drill policy allows, run up to 2 drill rounds per
   `references/drill-protocol.md` (`auto-at-threshold` auto-executes round 1).
7. **Deliver** — chat summary + files per output format; IEEE `[Sn]` citations throughout.

## Depth tiers and T2 dispatch

Read the matching tier checklist: `workflows/<depth>.md` (e.g. `workflows/quick-scan.md`).

| Depth                 | T2 dispatch                                                                 |
| --------------------- | --------------------------------------------------------------------------- |
| `quick-scan`          | Hunter (1) — no Skeptic                                                     |
| `standard-research`   | Hunter + Practitioner (parallel) → Skeptic (sequential, packaged prompt)  |
| `adversarial-deep`    | Hunter + Practitioner + Skeptic + Arbiter (4, parallel)                     |
| `custom`              | User-specified subset of Hunter, Practitioner, Skeptic, Arbiter             |

T2 spawns T3 leaf jobs via Task (T2 has Task). When T2 is unavailable, T1 batches
WebFetch (or equivalent readonly fetch) for the same job types.

### T2 subagent contract

Each T2 task:

```text
Readonly deep-research T2 (<role>). Follow <absolute research-protocol path>.

Supporting refs (readonly):
- <absolute citation-protocol path>
- <absolute source-tiers path>

Role: <Hunter|Practitioner|Skeptic|Arbiter>
Source boundary: <user boundary + free text>
Search/report languages: <languages>
Domain pack: <primary + secondary hints>

## Packaged prompt
<user question + pre-flight context — no other T2 answers>

Return structured findings for main-agent ledger merge. Do not mutate the repository.
Do not cite URLs not returned by readonly fetch. Flag paywalls and blocks.
```

**Arbiter** runs only in `adversarial-deep` (or custom when explicitly included).
**Skeptic** challenges Practitioner/Hunter outputs — main agent passes merged summaries
in the packaged prompt. At `standard-research`, Skeptic is **mandatory** and runs
**sequentially after** Hunter + Practitioner parallel merge (step 7a). At
`adversarial-deep`, Skeptic runs in parallel with the other three T2 workers.

### T3 leaf worker contract

T3 = leaf workers spawned **by T2** (grandchild tier). T3 has **no Task tool** — one
leaf per job; parallel jobs OK.

| Job                  | Input                                      | Output                                              |
| -------------------- | ------------------------------------------ | --------------------------------------------------- |
| `fetch-url`          | URL                                        | HTTP status + raw body/metadata                     |
| `extract-excerpt`    | URL or raw body + claim text               | ≤40-word supporting excerpt                         |
| `single-query-search`| One bounded web search query               | Candidate URLs/snippets (no synthesis)              |
| `verify-one-claim`   | Claim + URL                                | Two-key pass/fail + excerpt                         |

T3 **must not**: synthesize, merge ledger, spawn subagents, or score confidence.

T2 spawns T3 leaves via Task. When T2 is unavailable, T1 batches WebFetch (or
equivalent readonly fetch) for the same job types.

On T3 failure → T2 direct fallback (same job); note degraded fetch in ledger — not a blocker.

## Citation and ledger

Hard rules (details in `references/citation-protocol.md`):

- **Verify-before-cite** — fetch or re-fetch; confirm snippet/support exists at URL.
- **No cite without ledger row** — every `[Sn]` maps to exactly one ledger row.
- **Snippet fallback** — max 40 words per claim when live page differs; mark `snippet-only`;
  claim headline hard cap 40 (see `confidence-rubric.md` — separate from the 40-word text limit).
- **IEEE style** — inline `[Sn]`; numbered source list at end.
- **Two-key rule** — claim appears in ledger only when URL key + support key both pass.

### Source ledger shape (chat deliverable)

Always include in chat deliverables (and in `source-ledger.yaml` when writing files):

```markdown
## source ledger

| Sn | URL | Title | Tier | Verified | Snippet (≤40w) | Notes |
| -- | --- | ----- | ---- | -------- | -------------- | ----- |
```

`Verified`: `yes` | `snippet-only` | `failed` | `contested`

Failed rows **must not** appear as `[Sn]` citations in prose.

## Multi-domain research

When the question spans domains:

1. Select a **primary domain pack** from `references/domain-packs/*.yaml` (weights for
   confidence axes — see `references/confidence-rubric.md`).
2. Add **secondary hints** for cross-domain sources (e.g. primary `health-fitness`, secondary `legal` regulatory).
3. Tag each ledger row with domain tags when tier or authority differs by domain.

Auto-infer domain from the question when `domain:` is omitted; load the best-matching
pack or fall back to `generic.yaml`; state the inferred pack in pre-flight recap.

Persona files in `references/personas/` define T2 role behavior — pass absolute paths
when spawning Hunter, Practitioner, or Skeptic subagents.

## Sensitive domains

For **health**, **legal**, and **financial** topics (auto-detected or user-declared):

- Per-claim and overall confidence **floor display 60** unless evidence clearly exceeds —
  still show true computed score in axis breakdown; headline uses `max(computed, 60)` display rule
  with explicit _sensitive-domain floor applied_ note.
- Prominent disclaimer in deliverable (see helper ## honesty).
- Prefer T0/T1 sources; Skeptic strongly recommended even at `standard-research`.
- **Health-fitness (6a–6b):** When pack `health-fitness` applies and a claim headline is **≥75** with **T0/T1** backing, structured training plans in `## recommendation` are permitted — include explicit **not medical advice — consult a professional** disclaimer.

## Claims investigation mode

When the user asks to investigate specific claims (explicit list or `claims-investigation`):

- Add section **`## claim ledger`** mapping each user claim → evidence → verdict.
- Verdict per claim: `supported` | `partially-supported` | `unsupported` | `contested` | `unverified`
- Unverified claims go to **`## unverified`** — candidate fusion handoff (see below).

Template row:

```markdown
| Claim | Verdict | Confidence | Sources | Notes |
| ----- | ------- | ---------- | ------- | ----- |
```

## Deliver template

Use sections from `templates/deep-research-brief.md` (required order):

- `## answer`
- `## reasoning`
- `## confidence` — mandatory **Axis legend** table (SQ, EC, CG, CO, VR) plus note that scores are structured estimates; headline + full 5-axis per claim
- `## conflicts`
- `## claim ledger` (claims-investigation or explicit claim list only)
- `## unverified`
- `## references` — IEEE numbered list matching `[Sn]`
- `## recommendation`

Chat deliverable: always include the **Axis legend** and show **headline confidence** +
**full 5-axis per claim** in `## confidence` (see rubric and `templates/deep-research-brief.md`).
When `chat+files`, chat contains summary + headline + legend; files hold full brief.

**Same-turn delivery (Agent mode):** when `output` is `chat+files` and file writes are allowed, finish
the turn with both the chat summary and the written files — not chat-only now with files promised later.

## Degraded path

When Task/subagents are unavailable:

1. Ask upfront: _Subagents unavailable — run degraded single-context research in this
   thread? (yes/no)_
2. Do **not** start until the user confirms.
3. If yes: T1 performs Hunter → Practitioner → (Skeptic/Arbiter if tier requires)
   **sequentially** in one context with header: `degraded: sequential single-context, not parallel`.
4. Same verify, score, drill, and deliver rules apply.

## Fusion handoff

When deliverable includes **`## unverified`** items:

- **Only if** `verasic-fusion` is installed (detect skill root or user confirms),
  suggest a **manual** follow-up using `references/fusion-handoff.md`.
- Use `brief-research` template for multi-model opinion on gaps — **not** a substitute
  for ledger verification.
- **Never assume** fusion is installed; **never** auto-bridge or spawn fusion silently.

## Help text

When the user invokes deep research with no question, asks for help, or passes `help`, relay
the contents of `references/helper.md` verbatim (adjust paths if the skill is installed
under a non-`.cursor` root).

## Cross-agent installs

Skill path may be `.cursor/skills/verasic-deep-research/`, `.agents/skills/verasic-deep-research/`,
or another prefix. Resolve `references/` and `workflows/` relative to the skill root.
Behavior is identical; only Task spawn mechanism differs.
