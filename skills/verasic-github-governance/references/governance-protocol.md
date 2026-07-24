# Governance protocol — Verasic GitHub

## Governance model

Verasic uses a **two-layer** model:

| Layer | When active | What it enforces |
| --- | --- | --- |
| **Soft** | Always (default) | Lefthook/git hooks, CONTRIBUTING culture, stub CI job `ci`, doctor checks |
| **Hard** | Plan allows + `enable_hard_protection=true` | GitHub branch protection via OpenTofu: no direct push, PR + 1 review, required check `ci`, delete branch on merge |

### Default posture

- **Private + GitHub Free** → branch protection APIs are **not available** for private repos on Free. Enforcement = skill + hooks + CI culture + doctor.
- **OpenTofu** holds **intended** hard rules in dogfood registry repos at `infra/github-governance/` ([public-free](https://github.com/Milkywayrules/verasic-github-governance-public-free), [private-free](https://github.com/Milkywayrules/verasic-github-governance-private-free)); `branch_protection` module stays disabled until explicitly enabled. Product repos do not copy IaC.

### Repo topology (case-by-case)

| Org / context | Notes |
| --- | --- |
| **Milkywayrules** | WIP / personal / skill dumps — soft governance unless promoted |
| **verasic-lab** | Client delivery repos (e.g. siakad) — same factory; hard apply when contract or org upgrade warrants Team |

### Upgrade trigger

Stay on **Free** until:

1. Client contract requires org-level controls, **or**
2. GitHub **rulesets** / Team features justify cost, **or**
3. Ad hoc need → upgrade **verasic-lab** org to Team

See `plan-matrix.md` for plan-specific capabilities.

## Factory order (new repos)

1. Create **private** repo
2. Bootstrap multi-step stub CI (job name **`ci`**, green day one) + lefthook hooks
3. First PR proves CI / merge / Actions
4. Soft governance active immediately
5. OpenTofu hard apply when plan allows (`enable_hard_protection=true`)

## Standard floor (when hard protection enforced)

- No direct push to default branch (`main` or `master`)
- Pull request required
- At least **1** approving review
- Required status check: **`ci`**
- Delete branch on merge
- **No signed commits** in v1

## Enforcement layers

```
┌─────────────────────────────────────────────────────────┐
│  Culture: CONTRIBUTING.md + PR template + first PR proof │
├─────────────────────────────────────────────────────────┤
│  Local: lefthook pre-push (block default branch push)   │
│         pre-commit (default-branch reminder)             │
├─────────────────────────────────────────────────────────┤
│  CI: .github/workflows/ci.yml — job name must be `ci`   │
├─────────────────────────────────────────────────────────┤
│  Hard (plan-gated): OpenTofu branch_protection module     │
└─────────────────────────────────────────────────────────┘
```

## Mutation routing

Agents must load **verasic-github-governance** before any **mutating** GitHub operation:

| Operation | Route |
| --- | --- |
| Create repo | Factory protocol → private default → bootstrap → first PR |
| Repo settings (visibility, merge options, delete branch) | OpenTofu `repo_baseline` or documented `gh` with skill loaded |
| Branch protection / rulesets | OpenTofu only; `enable_hard_protection=true` after plan check |
| CI bootstrap | `bootstrap-repo.sh` templates; never hand-roll a differently named check |
| Transfer prep | Factory + doctor green; document target org plan |
| Read-only `gh` (view, log, status, pr view) | No skill required |

### Companion skills

| Skill | When |
| --- | --- |
| **verasic-github-env** | Before any `gh` command needing auth |
| **verasic-git-commits** | Commit-msg hook chained in lefthook template |
| **verasic-init** | One-shot wiring via manifest |

## Doctor exit codes

| Code | Meaning |
| --- | --- |
| `0` | Soft governance ready — CI template, CONTRIBUTING, hooks wired |
| `2` | Missing soft-governance items (see doctor output) |
| `1` | Script error (not inside git repo, broken install) |

Hard apply blockers (informational when plan lacks protection):

- GitHub plan does not support branch protection for this repo visibility
- `enable_hard_protection` not applied via OpenTofu
- Required check `ci` never succeeded on default branch (first PR not merged)

## Break-glass

Local hook bypass (audited, not for routine use):

```bash
VERASIC_GOVERNANCE_BYPASS=1 git push origin main
```

Document why in the PR or incident note when used.
