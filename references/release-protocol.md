# verasic-skills — release protocol

Monorepo git tags track bundle releases; each skill versions independently. `versions.lock`
is the strict release manifest. `integrity.sha256` hashes `VERSION` — they move together.

## Three layers

| Layer            | Location                             | Role                                                      |
| ---------------- | ------------------------------------ | --------------------------------------------------------- |
| Per-skill semver | `skills/<name>/VERSION`              | What changed in that skill                                |
| Release manifest | `versions.lock`                      | Must match every manifest skill `VERSION`                 |
| Bundle tag       | root `bundle.tag` + git tag `vX.Y.Z` | Canonical bundle version; drives generated `@vX.Y.Z` pins |

Users verify installs with `verasic-init` (integrity hash check) and read the **versions**
section. `--check-updates` compares local `VERSION` to upstream per skill.

## Release checklist (required)

1. Finish skill changes + skill regression / protocol tests + live harness if applicable.
2. Bump **only changed** skills: `skills/<name>/VERSION` (semver `X.Y.Z`).
3. Update `versions.lock` for those skills — leave unchanged skills as-is.
4. Regenerate integrity for bumped skills:

   ```bash
   bash scripts/refresh-integrity.sh <skill-name>
   # or: bash scripts/refresh-integrity.sh --all
   ```

5. Run the repo version gate:

   ```bash
   bash scripts/check-versions.sh
   bash scripts/test-versions-regression.sh
   bash scripts/check-bundle-pins.sh
   bash scripts/check-manifest-claims.sh
   bash scripts/test-all.sh   # full local router before tag (includes gates above)
   ```

6. Run affected skill exhaustive gates when the skill ships protocol tests.
7. Update [CHANGELOG.md](../CHANGELOG.md); draft GitHub Release from [release-notes-template.md](release-notes-template.md). Bump bundle version:

   ```bash
   bash scripts/release-bump.sh vX.Y.Z
   ```

   This sets root `bundle.tag`, runs `sync-bundle-tag.sh` (governance `@vX.Y.Z` pins), and runs `check-bundle-pins.sh`.

8. Commit, push `main`, tag `vX.Y.Z`, push tag — **`verasic-release` CI runs `test-all.sh`**.
9. Apply [repo-meta.md](repo-meta.md) (branch protection, GitHub Release).

**Never** tag without passing `check-versions.sh`. **Never** bump `VERSION` without
refreshing `integrity.sha256`. **`versions.lock` entry order must match `manifest.txt`.**

## Semver guidance

| Change                     | Bump                                                                        |
| -------------------------- | --------------------------------------------------------------------------- |
| New skill                  | Add to `manifest.txt`, `versions.lock`, tag minor or patch per team cadence |
| Protocol / behavior change | Patch (or minor if breaking contract) for that skill only                   |
| Docs-only inside skill     | Patch optional — prefer patch when integrity-listed files change            |

Repo tag patch (`v0.1.4`) is fine when only one skill patches. Tag does **not** have to equal
every skill version.

## Pin installs

```bash
# floating latest
npx skills add Milkywayrules/verasic-skills

# pin bundle
npx skills add Milkywayrules/verasic-skills@vX.Y.Z
```

After install, `bash .cursor/skills/verasic-init/scripts/init.sh --list` shows local
`VERSION` per skill. Strict integrity (default) fails on tampered or mismatched hashes.

## CI enforcement

`.github/workflows/verasic-versions.yml` runs on every push/PR touching `versions.lock`,
`skills/**/VERSION`, `skills/**/integrity.sha256`, or version scripts. It runs
`check-versions.sh`, `test-versions-regression.sh`, and `check-references.sh`.
Tag pushes run `verasic-release` → `test-all.sh` (bundle pins, manifest claims, skill regressions).
Failing `check-versions.sh` blocks merge.
