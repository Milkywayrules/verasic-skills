# verasic-skills — repo meta (maintainers)

Settings and conventions that live outside the codebase. Apply in GitHub repo settings.

## Branch protection (`main`)

Recommended required status checks before merge:

| Check | Workflow | Why |
| ----- | -------- | --- |
| version manifest | `verasic-versions` | lock ↔ VERSION ↔ integrity on every PR |
| skill regressions | path-filtered workflows | fast feedback per touched skill |

Optional after first green run: require `verasic-release` indirectly by only tagging
commits that passed `main` checks.

**Require:** pull request before merge, dismiss stale reviews (if team > 1).

## Tag releases

1. Merge to `main` with green CI.
2. Run locally: `bash scripts/test-all.sh`
3. Tag: `git tag -a vX.Y.Z -m "…"` and push tag.
4. `verasic-release` workflow runs `test-all.sh` on the tag — must pass.
5. Create GitHub Release using [release-notes-template.md](release-notes-template.md).

Never move or force-push release tags.

## Security tab

Enable **Security policy** → point to [SECURITY.md](../SECURITY.md).

## Dependabot (optional)

- GitHub Actions: pin major versions or SHA for `actions/checkout`
- Not applicable to skill content (no npm/pip deploy from this repo)

## skills.sh listing

After tag: verify [skills.sh](https://skills.sh/milkywayrules/verasic-skills) shows expected
scanner notes. Critical/Snyk on harness skills is expected — see SECURITY.md.

## Skill evolution policy

Newer skills (fusion, deep-research) ship exhaustive protocol tests and richer publish gates.
Older skills stay on regression-only CI until touched — then bring up to the current bar
incrementally, not big-bang retrofits.
