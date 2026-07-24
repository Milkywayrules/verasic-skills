Bootstrap Verasic GitHub governance into this repo (plan-first factory).

Read `.cursor/skills/verasic-github-governance-init/SKILL.md` and `references/factory-protocol.md` on the governance skill, then run from the repository root:

```bash
bash .cursor/skills/verasic-github-governance-init/scripts/factory.sh
```

**Plan first** — relay the full stdout verbatim and ask me to confirm before applying.

After I confirm:

```bash
bash .cursor/skills/verasic-github-governance-init/scripts/factory.sh --yes
```

If the repo already has foreign CI workflows, bootstrap may exit 2 — explain `references/existing-repo-conflicts.md` and ask which `--ci-strategy` (`skip`, `merge`, or `replace`) I want.

Optional after bootstrap proof:

```bash
bash .cursor/skills/verasic-github-governance-init/scripts/factory.sh --yes --open-pr
```

Requires **verasic-github-governance**, **verasic-github-env**, and (recommended) **verasic-git-commits** installed. Load github-env before any `gh` command. Never commit tokens.

Verify: `bash .cursor/skills/verasic-github-governance/scripts/doctor.sh` — required CI job name **`ci`**.
