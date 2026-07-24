# Verasic Config

Shared repo config hub for Verasic skills — artifact paths, security review
defaults, and shell-friendly JSON resolution. One place for `verasic.config.ts`,
`.verasicrc.json`, and optional `.verasicrc.jsonc`.

## Parts

Paths relative to this skill folder unless noted. After `setup.sh`, skill files
live under `.cursor/skills/verasic-config/`.

| File | Role |
| --- | --- |
| `schema/verasic.config.ts` | Exported `VerasicConfig` type + `DEFAULT_VERASIC_CONFIG` |
| `references/config-schema.md` | `trackedDir` vs `localDir`, scanner keys, promote modes |
| `templates/verasic.config.ts.example` | Commented TypeScript scaffold for repo root |
| `templates/.verasicrc.json.example` | Strict JSON alias (one root object) |
| `templates/.verasicrc.jsonc.example` | Optional JSONC alias with comments |
| `scripts/scaffold-artifacts.sh` | Wire dirs, `.gitignore`, optional config copy |
| `scripts/resolve-config.sh` | Print merged JSON for shell skills |
| `scripts/test-regression.sh` | Regression tests (local; no CI) |
| `SKILL.md` | Auto-trigger + orchestration |

## Config files (repo root)

| File | Format |
| --- | --- |
| `verasic.config.ts` | TypeScript — primary; `export default { ... }` |
| `.verasicrc.json` | **Strict JSON** — one root object; not JSONL |
| `.verasicrc.jsonc` | JSON with comments — optional human-friendly alias |

JSONL is for append-only run logs under `.verasic/`, not config.

## Install into a project

```bash
curl -fsSL https://raw.githubusercontent.com/Milkywayrules/verasic-skills/main/setup.sh | bash
```

Skill-only (any agent):

```bash
npx skills add Milkywayrules/verasic-skills
```

Installed under a different root (e.g. `.agents/skills/`)? Adjust the `.cursor/skills/` prefix in commands below.

## Wire one repo

```bash
bash .cursor/skills/verasic-config/scripts/scaffold-artifacts.sh
```

Or in Cursor: `/verasic-init --yes` (manifest wires `scaffold-artifacts.sh`).

Scaffold (idempotent):

1. Appends `.verasic/` to `.gitignore`
2. Creates `verasic/.gitkeep` and `verasic/security-reviews/.gitkeep`
3. Copies `verasic.config.ts.example` → `verasic.config.ts` only when no config exists
4. Optionally appends `.verasic/` to `.cursorignore` when `VERASIC_INDEX_LOCAL=false`

## Resolve config (shell)

```bash
bash .cursor/skills/verasic-config/scripts/resolve-config.sh
```

Defaults merge with `.verasicrc.json` when present. Full resolution in app code:
invoke overrides → `verasic.config.ts` → `.verasicrc.json` → defaults.

## Schema defaults

```typescript
artifacts: {
  trackedDir: 'verasic',   // durable, commit-friendly
  localDir: '.verasic',      // gitignored local runs
  indexLocal: false,
},
securityReview: {
  scanner: 'off',            // off | semgrep | opengrep | auto
  strictness: 'strict',      // strict | assertive
  report: {
    write: true,
    promote: 'both',         // both | local | tracked
  },
},
```

See `references/config-schema.md` for semantics.

## Regression

```bash
bash .cursor/skills/verasic-config/scripts/test-regression.sh
```

Security: [references/scanner-notes.md](references/scanner-notes.md) · upstream [SECURITY.md](https://github.com/Milkywayrules/verasic-skills/blob/main/SECURITY.md)

## Extend per repo

After scaffold, commit `verasic.config.ts` (or `.verasicrc.json`) and selectively
commit under `verasic/` when you want team-visible artifacts indexed. Keep
ephemeral runs under `.verasic/` — gitignored by default.
