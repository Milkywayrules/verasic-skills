---
name: verasic-config
description: Repo config hub for Verasic skills — verasic.config.ts, .verasicrc.json, artifact paths (trackedDir vs localDir), security review defaults. Use when scaffolding verasic artifact dirs, resolving config in shell skills, or wiring init manifest for config + gitignore.
---

Security: see `references/scanner-notes.md` and upstream [SECURITY.md](https://github.com/Milkywayrules/verasic-skills/blob/main/SECURITY.md) for expected scanner signals and trust model.

# Verasic Config — Repo Config Hub

## Workflows

All paths below assume the Cursor install root; installed elsewhere (e.g. `.agents/skills/`), adjust the prefix — the scripts themselves are install-root-agnostic. `/verasic-init` runs the scaffold for you.

**Wire path — scaffold artifact dirs once:**

1. Read `references/config-schema.md` for `trackedDir` vs `localDir` semantics.
2. From the repo root: `bash .cursor/skills/verasic-config/scripts/scaffold-artifacts.sh` (or let `/verasic-init --yes` wire it).
3. Edit `verasic.config.ts` or `.verasicrc.json` at repo root — never commit secrets.

**Runtime path — shell skills resolving config:**

```bash
bash .cursor/skills/verasic-config/scripts/resolve-config.sh
```

Prints JSON: defaults merged with `.verasicrc.json` when present. TypeScript consumers import `DEFAULT_VERASIC_CONFIG` from `schema/verasic.config.ts`.

## Source of truth

- Schema types + defaults: `schema/verasic.config.ts`
- Path semantics: `references/config-schema.md`
- Templates: `templates/verasic.config.ts.example`, `.verasicrc.json.example`, `.verasicrc.jsonc.example`

## Hard rules

- `trackedDir` = durable, commit-friendly artifacts; `localDir` = gitignored machine-local root — they pair, not replace each other.
- `.verasicrc.json` is strict JSON (one object); JSONL is for run logs under `localDir`, not config.
- Scaffold never overwrites existing user config files.
- Set `VERASIC_INDEX_LOCAL=false` during scaffold to also append `localDir` to `.cursorignore`.
