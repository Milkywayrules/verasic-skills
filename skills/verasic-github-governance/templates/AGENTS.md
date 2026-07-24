# AGENTS

<!-- verasic-governance:start -->
## GitHub agent harness

- Load `GH_TOKEN` before any `gh` mutation: `source .cursor/skills/verasic-github-env/scripts/load-gh-env.sh` (or `.agents/skills/` equivalent).
- Verify with `bash .cursor/skills/verasic-github-env/scripts/check-gh.sh` — never bare `gh auth status` in chat.
- Prefer HTTPS remotes with PAT for agent pushes when SSH is unavailable.

## Governance routing

Mutating GitHub operations (repo create, settings, branch protection, CI bootstrap, transfer prep) require the **verasic-github-governance** skill — read `references/governance-protocol.md` and follow `references/factory-protocol.md`.

Soft enforcement (hooks + CI culture + doctor) is the default on private Free plans. OpenTofu hard protection applies only when plan allows and `enable_hard_protection=true`.

Required CI status check name: **`ci`**.

Full spec: install **verasic-github-governance** from [verasic-skills](https://github.com/Milkywayrules/verasic-skills) (`skills/verasic-github-governance/SKILL.md`).
<!-- verasic-governance:end -->
