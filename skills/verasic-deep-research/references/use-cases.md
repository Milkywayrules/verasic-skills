# verasic-deep-research — use cases & verification

Exhaustive verification before publish. Run the automated gate first, then every live
harness UC in Cursor.

## Automated gate (required)

From repo root:

```bash
bash skills/verasic-deep-research/scripts/test-exhaustive.sh
```

Or individual suites:

```bash
bash skills/verasic-deep-research/scripts/test-regression.sh
bash skills/verasic-deep-research/scripts/test-exhaustive-protocol.sh
```

After `setup.sh`:

```bash
bash .cursor/skills/verasic-deep-research/scripts/test-exhaustive.sh
```

Exit 0 = structural + protocol pre-flight rules OK. `test-exhaustive.sh` also runs
init regression when invoked from the verasic-skills source tree.

CI (`.github/workflows/verasic-deep-research.yml`) runs `test-regression.sh` and
`test-exhaustive-protocol.sh` on push — not the init suite.

## Live harness checks (Cursor — all required before public announce)

Recommend including `composer-2.5-fast` when supplying a T2 model roster.

### UC-0 — Help

**Input:** `/verasic-deep-research` or `/verasic-deep-research help`

**Expect:** Helper text from `references/helper.md`; no fetch or subagent spawn.

---

### UC-1 — Pre-flight missing fields

**Input:** question only — no `depth`, `output`, or `source-boundary`

**Expect:** Ask once for missing required fields; honesty notice; no fetch or spawn.

---

### UC-2 — quick-scan chat-only

```text
depth: quick-scan
output: chat-only
source-boundary: public-standard
languages: en

What is the current stable release channel for Bun?
```

**Expect:** Hunter-only T2 (no Skeptic); chat summary; IEEE-style citations only for
verified ledger rows; no files written.

---

### UC-3 — standard-research chat+files

```text
depth: standard-research
output: chat+files
source-boundary: public-standard
languages: en

How does HTTP/3 differ from HTTP/2 for typical web apps?
```

**Expect:** Hunter + Practitioner parallel → Skeptic sequential; chat summary **and**
`./docs/research/<slug>/deep-research-brief.md` plus `source-ledger.yaml` in the same
turn (Agent mode).

---

### UC-4 — claims-investigation adversarial-deep

```text
depth: adversarial-deep
output: chat+files
source-boundary: public-standard
languages: en
domain: claims-investigation

Is [contested public claim] supported by primary sources?
```

**Expect:** Four T2 workers including Arbiter; `## conflicts` populated when sources
disagree; domain pack `claims-investigation` hints reflected in sourcing posture.

---

### UC-5 — Fusion handoff suggestion

Run a standard or quick-scan where verify leaves material gaps.

**Expect:** When gaps remain and fusion is installed, agent may **suggest** manual
`/verasic-fusion` per `references/fusion-handoff.md` — never auto-spawn fusion.

---

### UC-6 — Ask mode no files

**Input:** Same as UC-3 but in **Ask mode** (read-only chat).

**Expect:** Chat delivery only — **no file writes** even when `output: chat+files` or
`files-only`; plain notice and offer Agent mode or `chat-only` continuation.

---

### UC-7 — Degraded confirmation

In an environment without Task/subagents (or simulate by instruction):

**Expect:** Agent asks whether to run degraded sequential fetch/work — waits for yes/no
before proceeding (see `references/research-protocol.md` Degraded path).

---

## Depth tier checklist

| Depth               | Manual UC |
| ------------------- | --------- |
| `quick-scan`        | UC-2      |
| `standard-research` | UC-3      |
| `adversarial-deep`  | UC-4      |

## Publish gate

Before public announce:

1. `test-exhaustive.sh` exits 0 (includes init regression in source tree)
2. **All** live UCs UC-0 through UC-7 pass in Cursor
3. README and root README list `/verasic-deep-research`
4. Drift audit clean in skill dir (no legacy axis names, wrong template paths, or
   forbidden section headers — see release checklist in repo)

## Verification log

| UC   | Type                         | Result | Verified by                   |
| ---- | ---------------------------- | ------ | ----------------------------- |
| UC-0 | helper                       | PASS   | `helper.md`; protocol scope   |
| UC-1 | pre-flight missing           | PASS   | `test-exhaustive-protocol.sh` |
| UC-2 | quick-scan chat-only         | PASS   | live harness                  |
| UC-3 | standard chat+files          | PASS   | live harness                  |
| UC-4 | claims adversarial           | PASS   | live harness                  |
| UC-5 | fusion handoff suggestion    | PASS   | `fusion-handoff.md`           |
| UC-6 | Ask mode no files            | PASS   | protocol + live harness       |
| UC-7 | degraded confirm             | PASS   | protocol + live harness       |
