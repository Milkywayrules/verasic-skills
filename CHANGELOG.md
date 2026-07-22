# Changelog

All notable releases of the [verasic-skills](https://github.com/Milkywayrules/verasic-skills)
monorepo. Per-skill semver lives in `skills/<name>/VERSION`; this file is the human bundle
summary. Git tags (`vX.Y.Z`) pin install snapshots.

Format: bundle tag → which skills changed. See [references/release-protocol.md](references/release-protocol.md).

## Unreleased

## v0.1.4

### Skills

- **verasic-github-env**, **verasic-git-commits**, **verasic-bugbot**, **verasic-fusion**, **verasic-init** — upstream SECURITY.md links point at `blob/main` (was pinned `v0.1.2`); patch bump to `0.1.3`
- **verasic-bugbot** — structural regression script; integrity manifest adds `checklists/performance.md` and `checklists/infra.md`; CI workflow `verasic-bugbot.yml`

### Infrastructure

- `scripts/check-references.sh` — validates concrete internal path refs in markdown; wired into `test-all.sh` and `verasic-versions` CI
- cursor rules: bare skill paths → full `.cursor/skills/<name>/…` references
- strict version manifest: `check-versions.sh`, `refresh-integrity.sh`, CI `verasic-versions`
- release full gate on tags: `verasic-release.yml` + `scripts/test-all.sh`
- CI for `verasic-init`, `verasic-git-commits`, `verasic-bugbot`
- install docs: Cursor + skills CLI hybrid path
- `verasic-deep-research` SECURITY.md links already on `blob/main` (VERSION `0.1.3`)

## v0.1.3

- **verasic-deep-research** — initial public release (ledger-backed research, domain packs, slash command)

## v0.1.2

- bundle baseline for fusion, init, git-commits, github-env, bugbot

## v0.1.1 / v0.1.0

- early harness skills and security docs
