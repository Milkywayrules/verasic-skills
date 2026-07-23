# GitHub release notes template

Copy into a GitHub Release when tagging `vX.Y.Z`. Generate skill deltas from `versions.lock`
vs the previous tag (or `git diff` on `versions.lock`).

```markdown
## verasic-skills vX.Y.Z

Bundle snapshot. Per-skill versions:

| Skill | Version | Notes |
| ----- | ------- | ----- |
| verasic-deep-research | X.Y.Z | … |
| verasic-fusion | X.Y.Z | unchanged |
| … | … | … |

### Highlights

- …

### Install

```bash
# Cursor full
curl -fsSL https://raw.githubusercontent.com/Milkywayrules/verasic-skills/main/setup.sh | bash

# skills CLI (pin this release)
npx skills add Milkywayrules/verasic-skills@vX.Y.Z

# Agent-only (no Cursor UX) — after skills install
bash .agents/skills/verasic-init/scripts/init.sh --yes --profile agent
```

Then: `/verasic-init` (plan first), then apply:

```bash
bash .cursor/skills/verasic-init/scripts/init.sh --yes --profile cursor
# or hybrid: bash .agents/skills/verasic-init/scripts/init.sh --yes --profile cursor-hybrid
```

### Verify

Automated gate passed: `bash scripts/test-all.sh` on tag CI.

After install: `bash .cursor/skills/verasic-init/scripts/init.sh --list` — check **versions**
and integrity rows.
```

## Generate skill table quickly

```bash
# from repo root, after updating versions.lock
grep -v '^#' versions.lock | grep -v '^$' | while IFS='=' read -r name ver; do
  printf '| %s | %s | |\n' "$name" "$ver"
done
```

Keep notes short — link to skill READMEs for depth. Monorepo releases do not need
essay-length notes unless a skill had a breaking protocol change.
