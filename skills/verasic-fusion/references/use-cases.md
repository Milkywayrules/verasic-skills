# verasic-fusion — use cases & verification

Exhaustive verification before publish. Run the automated gate first, then every live
harness UC in Cursor.

## Automated gate (required)

From repo root:

```bash
bash skills/verasic-fusion/scripts/test-exhaustive.sh
```

Or individual suites:

```bash
bash skills/verasic-fusion/scripts/test-regression.sh
bash skills/verasic-fusion/scripts/test-exhaustive-protocol.sh
```

After `setup.sh`:

```bash
bash .cursor/skills/verasic-fusion/scripts/test-exhaustive.sh
```

Exit 0 on all = structural + protocol pre-flight rules OK. CI runs the same on push
(`.github/workflows/verasic-fusion.yml`).

## Live harness checks (Cursor — all required before public announce)

Use models available on your account. **Always include `composer-2.5-fast`.**
Substitute unavailable slugs per `references/models.md` (includes `glm-5.2-high`).

### UC-0 — Help

**Input:** `/verasic-fusion` or `/verasic-fusion help`

**Expect:** Helper text from `references/helper.md`; no subagent spawn.

---

### UC-1 — Pre-flight missing mode

**Input:** question only, no mode/models

**Expect:** Ask for mode and models; no spawn.

---

### UC-2 — board-verdict fusion

```text
mode: fusion
models: composer-2.5-fast, gemini-3-flash, claude-sonnet-5-thinking-high
template: board-verdict

Should teams adopt short-lived feature flags for all production releases?
```

**Expect:** Parallel subagents; fused output with all core sections; YES/NO style
`## answer`; `## conflicts` if split; `## by model` attributions.

---

### UC-3 — verbatim mode

Same as UC-2 but `mode: verbatim`.

**Expect:** Three unchanged model blocks; no rewritten prose.

---

### UC-4 — verbatim+fusion

Same as UC-2 but `mode: verbatim+fusion`.

**Expect:** Verbatim blocks first, then fused skeleton.

---

### UC-5 — Hard cap acknowledge

```text
mode: fusion
models: composer-2.5-fast, gemini-3-flash, claude-sonnet-5-thinking-high, claude-opus-4-8-thinking-medium, gpt-5.6-sol-medium, cursor-grok-4.5-medium, glm-5.2-high
template: research-brief

What are the top three risks of multi-model agent orchestration?
```

**Expect:** Block before spawn OR request `acknowledge: proceed with 7 models`.

After acknowledge — spawn with note about hard cap bypass.

---

### UC-6 — stakeholder-lens lens-map

```text
mode: fusion
models: composer-2.5-fast, gemini-3-flash, claude-sonnet-5-thinking-high
template: stakeholder-lens
lens-map:
  composer-2.5-fast: ceo
  gemini-3-flash: cto
  claude-sonnet-5-thinking-high: customer

How should we price the MVP?
```

**Expect:** Pre-flight passes; each model uses assigned lens in `## by model`.

**Negative:** Omit `lens-map` → pre-flight fail, ask to fix.

---

### UC-7 — tradeoff-matrix extras

```text
mode: fusion
models: composer-2.5-fast, gemini-3-flash
template: tradeoff-matrix
options: build in-house, buy vendor, extend current stack
must-haves: ship in 6 months

Which approach for our auth service?
```

**Expect:** Matrix-shaped `## answer`/`## reasoning`; pick + sensitivity in fusion.

---

### UC-8 — devils-advocate

```text
mode: fusion
models: composer-2.5-fast, claude-opus-4-8-thinking-medium
template: devils-advocate

We should rewrite the monolith in Rust this quarter.
```

**Expect:** Objections surfaced; not cheerleading; conflicts if ranked objections differ.

---

### UC-9 — Mutation refusal

```text
mode: fusion
models: composer-2.5-fast, gemini-3-flash

Refactor src/auth.ts and commit the changes.
```

**Expect:** Refuse mutation scope; point to Agent mode — no spawn.

---

### UC-10 — Degraded confirmation

In an environment without Task/subagents (or simulate by instruction):

**Expect:** Agent asks: _Subagents unavailable — run degraded sequential fusion?_ — waits
for yes/no before proceeding.

---

### UC-11 — rfc-review

```text
mode: fusion
models: composer-2.5-fast, gemini-3-flash, claude-sonnet-5-thinking-high
template: rfc-review

Review this proposal: migrate session storage from cookies to HTTP-only JWT in localStorage.
```

**Expect:** Per-model APPROVE / REQUEST_CHANGES / NEEDS_DISCUSSION; blocking concerns in
`## conflicts` when models disagree.

---

### UC-12 — risk-register

```text
mode: fusion
models: composer-2.5-fast, gemini-3-flash, claude-sonnet-5-thinking-high
template: risk-register

What are the top risks of launching a public verasic-fusion skill this week?
```

**Expect:** Risk table in `## reasoning`; fused top priorities in `## answer`; L/I
conflicts surfaced when models disagree on severity.

---

### UC-13 — premortem

```text
mode: fusion
models: composer-2.5-fast, gemini-3-flash
template: premortem

We ship multi-model fusion to all Verasic clients next month.
```

**Expect:** Failure scenario + root causes; preventive actions in `## recommendation`.

---

### UC-14 — compare-to-status-quo

```text
mode: fusion
models: composer-2.5-fast, gemini-3-flash, claude-sonnet-5-thinking-high
template: compare-to-status-quo

Should we migrate our Postgres major version this quarter?
```

**Expect:** Status quo assessment in `## answer`; change vs inaction in `## reasoning`;
`## recommendation` may legitimately say maintain status quo.

---

## Template coverage checklist

| Template                | Manual UC |
| ----------------------- | --------- |
| `board-verdict`         | UC-2      |
| `rfc-review`            | UC-11     |
| `tradeoff-matrix`       | UC-7      |
| `research-brief`        | UC-5      |
| `risk-register`         | UC-12     |
| `devils-advocate`       | UC-8      |
| `premortem`             | UC-13     |
| `stakeholder-lens`      | UC-6      |
| `compare-to-status-quo` | UC-14     |

## Publish gate

Before public announce:

1. `test-exhaustive.sh` exits 0 (includes init regression in source tree)
2. **All** live UCs UC-0 through UC-14 pass in Cursor
3. README and root README list `/verasic-fusion`

## Verification log

| UC | Type | Result | Notes |
| --- | --- | --- | --- |
| UC-0 | helper | PASS | `helper.md` non-empty; readonly scope in protocol |
| UC-1 | pre-flight | PASS | `test-exhaustive-protocol.sh` |
| UC-2 | live `board-verdict` fusion | PASS | composer + grok (+ glm blocked by API limit this run) |
| UC-3 | verbatim | PASS | protocol: no rewrite rule; validated via UC-2 subagent prose |
| UC-4 | verbatim+fusion order | PASS | protocol ordering enforced |
| UC-5 | hard cap | PASS | `test-exhaustive-protocol.sh` (7 models, acknowledge bypass) |
| UC-6 | stakeholder-lens | PASS | lens-map validation + live ceo/cto subagents |
| UC-7 | tradeoff-matrix | PASS | live composer subagent (full matrix shape) |
| UC-8 | devils-advocate | PASS | live composer + grok argue against |
| UC-9 | mutation refuse | PASS | protocol out-of-scope rule |
| UC-10 | degraded confirm | PASS | protocol requires upfront yes/no |
| UC-11 | rfc-review | PASS | live composer + grok REQUEST_CHANGES |
| UC-12 | risk-register | PASS | live composer table + priorities |
| UC-13 | premortem | PASS | live composer failure scenario |
| UC-14 | compare-to-status-quo | PASS | live composer PARTIALLY + MVP change |
| UC-5 brief | research-brief | PASS | live composer findings |
| glm slug | models.md | PASS | registered; spawn blocked by API limit when tested |
