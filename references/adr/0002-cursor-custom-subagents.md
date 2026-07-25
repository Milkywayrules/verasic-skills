# ADR 0002: Standalone custom subagents

**Status:** Accepted  
**Date:** 2026-07-25  
**Cursor:** 3.12.29

## Context

Maintainers need **model-pinned generic subagents** (spawn by exact `subagent_type` slug) for multi-model orchestration (fusion, parallel research, PoC workflows). Empirical Task-tool behavior differs from official docs in places; mechanics are documented in [cursor-custom-subagents.md](../cursor-custom-subagents.md).

Verasic **product** subagents live in `cursor/agents/` (`verasic-*`), wired by init. Generic `subagent-*` files are **personal tooling**, not skills.sh product surface — no verasic-init manifest, no generator scripts in v1.

## Decision

1. **Canonical source:** `etc/cursor/agents/subagent-<profile>.md` — tracked in repo.
2. **Runtime:** `.cursor/agents/` — Cursor reads this for Task dispatch; maintainer copies manually (`cp etc/cursor/agents/*.md .cursor/agents/`). No gitignore or repo policy on `.cursor/agents/` beyond “act as Cursor’s folder.”
3. **Model frontmatter:** flat slug from `cursor agent --list-models` for Phase 1 roster; bracket syntax documented as advanced/future in Layer A only.
4. **Spawn hints:** `description:` includes spawn constraints where empirical behavior differs; full matrix in [snapshot](../snapshots/cursor-custom-subagents-2026-07-25.md).
5. **Gemini 3.6 Flash low/medium:** spawn via **`subagent_type` only** — Task inline `model` hard-rejects these slugs (observed T21/T42/T59).
6. **New agent files:** Task `subagent_type` enum is frozen at **session start** — start a **new chat** after adding files to `.cursor/agents/`.
7. **Cleanup:** remove exploration stubs (`subagent-asdasd`, `subagent-qwe`, invalid filenames, global copies) when shipping roster — boy-scout rule.
8. **Cross-links only:** one line in [cursor-skills-ux.md](../cursor-skills-ux.md) + row in [AGENTS.md](../../AGENTS.md); no matrix duplication in README.

## Consequences

### Positive

- Clear separation: `cursor/agents/` (product) vs `etc/cursor/agents/` (standalone).
- Reproducible 16-agent roster with empirical spawn rules.
- Layer A + snapshot preserve trial-and-error evidence.

### Negative / deferred

- Manual copy step (no init wiring).
- Task inline allowlist is incomplete in error messages; maintainers rely on snapshot pass/fail matrix.
- Bracket frontmatter not used in Phase 1; future roster expansion may need ADR amend.

## Related

- [cursor-custom-subagents.md](../cursor-custom-subagents.md)
- [snapshots/cursor-custom-subagents-2026-07-25.md](../snapshots/cursor-custom-subagents-2026-07-25.md)
- [0001-cursor-ux-skills-first.md](0001-cursor-ux-skills-first.md)
- Official: https://cursor.com/docs/subagents.md
