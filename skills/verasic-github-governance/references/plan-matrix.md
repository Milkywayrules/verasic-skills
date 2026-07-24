# Plan matrix — GitHub branch protection eligibility

Verasic default: **private + Free**. Branch protection for private repos requires a paid plan or public visibility rules.

**Primary source:** [GitHub Plans — Compare features](https://docs.github.com/en/get-started/learning-about-github/githubs-plans) (branch protection, required reviewers, status checks).

## Summary matrix

| Plan | Visibility | Classic branch protection | Required status checks | Required reviewers | Verasic default action |
| --- | --- | --- | --- | --- | --- |
| **Free** | Private | ❌ Not available | ❌ | ❌ | Soft only — hooks + CI + doctor |
| **Free** | Public | ✅ Available | ✅ | ✅ (limited) | Hard apply optional via OpenTofu |
| **Team** | Private | ✅ Available | ✅ | ✅ | Hard apply when `enable_hard_protection=true` |
| **Team** | Public | ✅ Available | ✅ | ✅ | Hard apply when enabled |
| **Enterprise** | Any | ✅ + rulesets | ✅ | ✅ | Same; prefer rulesets when org mandates |

## Feature notes

### Private repos on Free

GitHub does not expose branch protection rules for **private** repositories on the **Free** plan. Verasic treats this as a hard platform limit — do not attempt UI workarounds. Enforcement:

- `hooks/pre-push` blocks local push to default branch
- CONTRIBUTING + PR template culture
- CI job **`ci`** ready for the day plan upgrades
- OpenTofu module `branch_protection` with `enabled = false` documents intent

### Public repos on Free

Public repositories on Free **can** use branch protection. Verasic still defaults new repos to **private**; hard apply is opt-in when a repo is intentionally public.

### Team / Pro

Upgrade **verasic-lab** when client contracts or org policy require:

- Enforced PR reviews on private repos
- Required status checks that cannot be bypassed via hook bypass alone
- Organization rulesets

### Rulesets vs classic protection

This harness v1 uses **classic branch protection** via the GitHub Terraform provider (`github_branch_protection`). Organization **rulesets** are out of scope for v1; evaluate at Team upgrade.

## OpenTofu gating variable

```hcl
variable "enable_hard_protection" {
  type        = bool
  default     = false
  description = "Set true only when plan-matrix allows branch protection for this repo."
}
```

| `enable_hard_protection` | Plan eligible | Result |
| --- | --- | --- |
| `false` | any | Repo baseline only (settings, delete branch on merge) |
| `true` | Free private | **Apply will fail** — do not enable |
| `true` | Team private / public Free+ | Branch protection applied |

## Doctor plan-gated reporting

`doctor.sh` prints informational lines when:

- Repo is private and `gh` indicates Free plan (best-effort)
- OpenTofu hard protection not detected
- Required check `ci` not yet observed on default branch

These do **not** fail soft governance (exit `2`) unless CI/CONTRIBUTING/hooks are missing.
