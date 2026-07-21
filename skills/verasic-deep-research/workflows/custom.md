# Workflow: custom

Depth preset: `custom`. Read `references/research-protocol.md` first.

User defines T2 roster, parallelism, and T3 batch size at pre-flight. No silent defaults
for worker selection.

## Steps

1. **Pre-flight — custom block** — collect required fields plus:
   - `t2-workers:` subset of `Hunter`, `Practitioner`, `Skeptic`, `Arbiter` (minimum 1)
   - `t2-parallel:` yes | no (default parallel when multiple workers unless user says no)
   - `t3-max:` integer or `0` to skip T3
   - `skeptic-after:` list of workers whose output Skeptic receives (when Skeptic included)
2. **Validate** — Arbiter without Skeptic → warn; Skeptic-only without Hunter/Practitioner → warn unless claims list provided.
3. **Load domain pack** — as standard workflow.
4. **Dispatch T2** — per user roster; respect parallel/sequential and skeptic-after dependency.
5. **T3** — up to `t3-max` parallel fetches when >0.
6. **Verify → synthesize → score → drill → deliver** — same gates as `references/research-protocol.md` pipeline.
7. **Document** — state custom topology in deliverable header: `depth: custom (workers: …)`.

## Examples

```text
depth: custom
t2-workers: Hunter, Practitioner, Skeptic
t2-parallel: yes
t3-max: 8
skeptic-after: Hunter, Practitioner
```

## When to recommend

- Power users with explicit research topology needs.
- Partial re-runs (e.g. Skeptic-only pass on existing ledger — user provides prior extracts).
