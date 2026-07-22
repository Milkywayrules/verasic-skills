# Changelog

All notable releases of the [verasic-skills](https://github.com/Milkywayrules/verasic-skills)
monorepo. Per-skill semver lives in `skills/<name>/VERSION`; this file is the human bundle
summary. Git tags (`vX.Y.Z`) pin install snapshots.

Format: bundle tag → which skills changed. See [references/release-protocol.md](references/release-protocol.md).

## Unreleased

### Infrastructure

- strict version manifest: `check-versions.sh`, `refresh-integrity.sh`, CI `verasic-versions`
- release full gate on tags: `verasic-release.yml` + `scripts/test-all.sh`
- CI for `verasic-init`, `verasic-git-commits`
- install docs: Cursor + skills CLI hybrid path
- `verasic-deep-research` VERSION aligned to `0.1.3`

## v0.1.3

- **verasic-deep-research** — initial public release (ledger-backed research, domain packs, slash command)

## v0.1.2

- bundle baseline for fusion, init, git-commits, github-env, bugbot

## v0.1.1 / v0.1.0

- early harness skills and security docs
