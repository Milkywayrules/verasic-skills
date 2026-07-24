# Contributing

Verasic repos use **feature branches + pull requests**. Do not push directly to `main` (or the repo default branch).

## Workflow

1. Branch from `main`: `git checkout -b feat/my-change`
2. Commit with [Conventional Commits](https://www.conventionalcommits.org/) style (see verasic-git-commits skill)
3. Push the branch and open a PR
4. Wait for the **`ci`** check to pass
5. Merge after review

## Local hooks

This repo uses [lefthook](https://github.com/evilmartians/lefthook) to block direct pushes to the default branch. Break-glass only:

```bash
VERASIC_GOVERNANCE_BYPASS=1 git push origin main
```

## CI

The required status check name is **`ci`**. Do not rename the job without updating governance docs and OpenTofu.

## Hard protection

GitHub branch protection applies when the org plan allows and OpenTofu `enable_hard_protection=true` is applied. Until then, hooks + culture enforce the same floor.
