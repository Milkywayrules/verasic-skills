# Config schema — verasic-security-review

Security review reads the **shared Verasic config hub**. Canonical types, defaults, and resolution order live in the **`verasic-config`** skill — do not duplicate the full schema here.

## Resolution order

1. Invoke phrase (scope, `strict` / `assertive`, `no file`, `save tracked`, scanner override)
2. `verasic.config.ts` at repo root
3. `.verasicrc.json` or `.verasicrc.jsonc` at repo root (**standard JSON object, not JSONL**)
4. `DEFAULT_VERASIC_CONFIG` from `verasic-config/schema/verasic.config.ts`

Shell fallback: `verasic-config/scripts/resolve-config.sh` merges defaults with the first present repo config file (`verasic.config.ts`, `.verasicrc.jsonc`, or `.verasicrc.json`).

## Keys used by this skill

```typescript
// Illustrative — see verasic-config for VerasicConfig type
export default {
  artifacts: {
    trackedDir: 'verasic',
    localDir: '.verasic',
    indexLocal: false,
  },
  securityReview: {
    scanner: 'off', // 'off' | 'semgrep' | 'opengrep' | 'auto'
    strictness: 'strict', // 'strict' | 'assertive'
    report: {
      write: true,
      promote: 'both', // 'tracked' | 'local' | 'both'
    },
  },
} satisfies VerasicConfig;
```

Report subdir is fixed: `{localDir}/security-reviews/` and `{trackedDir}/security-reviews/`.

## Defaults when no config file exists

| Key | Default |
| --- | --- |
| `scanner` | `off` |
| `strictness` | `strict` |
| `report.write` | `true` |
| `report.promote` | `both` |
| `trackedDir` | `verasic` |
| `localDir` | `.verasic` |
| `indexLocal` | `false` |

## Init scaffold

`verasic-init --yes` should ensure `.verasic/` in `.gitignore`, optional `verasic/.gitkeep`, and a commented `verasic.config.ts` example — only when neither config file exists.

## Pointer

For full `VerasicConfig`, merge helpers, and cross-skill keys, read:

- `.agents/skills/verasic-config/SKILL.md` (when installed)
- `verasic-config/references/config-schema.md`
