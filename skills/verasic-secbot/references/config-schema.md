# Config schema — verasic-secbot

Secbot-local defaults for security review runs. Canonical until a future centralized Verasic config kit ships (TBD — does not exist today).

## Resolution order

1. Invoke phrase (scope, `strict` / `assertive`, `no file`, `save tracked`, scanner override)
2. Inlined defaults below (no repo config file required)

## Keys used by this skill

```typescript
// Illustrative — secbot-local defaults
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
};
```

Report subdir is fixed: `{localDir}/security-reviews/` and `{trackedDir}/security-reviews/`.

## Defaults

| Key | Default |
| --- | --- |
| `scanner` | `off` |
| `strictness` | `strict` |
| `report.write` | `true` |
| `report.promote` | `both` |
| `trackedDir` | `verasic` |
| `localDir` | `.verasic` |
| `indexLocal` | `false` |

## Artifact dirs

On first report write, ensure `verasic/security-reviews/` and `.verasic/security-reviews/` exist (`mkdir -p`).
