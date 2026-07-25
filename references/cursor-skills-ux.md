# Cursor skills-first UX

How Verasic harness skills expose slash entries in Cursor v0.2.0+.

## Slash ≠ command file

In v0.1.x, workflow lived in `cursor/commands/*.md` with verb slugs like `/verasic-review`.
In **v0.2.0**, those bodies merged into `skills/*/SKILL.md`. Cursor resolves `/verasic-<skill-folder>` from the skill name.

| Before (v0.1.x) | After (v0.2.0) |
| --- | --- |
| cursor/commands/verasic-review.md (deleted) | skills/verasic-bugbot/SKILL.md → `/verasic-bugbot` |
| cursor/commands/verasic-security-review.md (deleted) | skills/verasic-secbot/SKILL.md → `/verasic-secbot` |
| 9 command files | 0 command files |

Canonical map: [verasic-cursor-map.md](verasic-cursor-map.md).

## Three UX layers

| Layer | Location | User experience |
| --- | --- | --- |
| **Skills** | `skills/*/SKILL.md` | Slash by folder name; orchestration + spawn blocks |
| **Subagents** | `cursor/agents/*.md` | Optional direct subagent invoke; spawned by skills |
| **Rules** | `cursor/rules/*.mdc` | Always-applied; `@mention` in chat; no slash required |

Workflow skills (except git-commits-convention) set:

```yaml
disable-model-invocation: true
```

So the model does not auto-attach the skill — the user (or explicit orchestration) invokes the slash.

## Install profiles

| Profile | Skills | Cursor UX |
| --- | --- | --- |
| **cursor** | `.cursor/skills/` via `setup.sh` | agents + rules copied to `.cursor/` |
| **cursor-hybrid** | `.agents/skills/` via skills CLI | agents + rules fetched to `.cursor/` |
| **agent** | agent-native skills path | no Cursor UX fetch |

`verasic-init --yes --profile …` wires repo scripts and optionally fetches upstream `cursor/` UX (no commands).

## Config kit — future, not built

v0.2.0 **removed** the `verasic-config` skill. Secbot uses **inlined defaults** in `skills/verasic-secbot/references/config-schema.md` (invoke-phrase overrides + defaults table).

Centralized repo config may return later as **TBD** package-oriented tooling, for example:

- a dedicated npm package
- Verasic Kit / Verasic Harness Kit
- another CLI distribution

**That tooling does not exist today.** Do not document or scaffold `verasic.config.ts` / `.verasicrc` as shipped product surface until a kit ships.

Artifact directories (`verasic/security-reviews/`, `.verasic/security-reviews/`) are created on first secbot report write — no config file scaffold.

## Maintainer checks

- `bash scripts/check-cursor-ux-manifest.sh` — `cursor/` has exactly 8 files; no `skills/verasic-init/assets/`
- `skill-ux-map.txt` ⊆ `cursor-ux-manifest.txt`
- Grep retired slugs — zero except CHANGELOG / ADR retired lists

ADR: [0001-cursor-ux-skills-first.md](adr/0001-cursor-ux-skills-first.md).

Standalone model-pinned subagents (outside product `cursor/agents/`): [cursor-custom-subagents.md](cursor-custom-subagents.md).
