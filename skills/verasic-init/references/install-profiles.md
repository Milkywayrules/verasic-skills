# verasic-init — install profiles

Init is **confirm-first**: without `--yes`, it prints a setup plan and changes nothing.
Pass `--yes` (and usually `--profile …`) to apply repo wiring and optional Cursor UX fetch.

## Profiles

| Profile | Who | Skills root (wiring) | Cursor UX on `--yes` |
| ------- | --- | -------------------- | -------------------- |
| `cursor` | Cursor via `setup.sh` or skills under `.cursor/skills/` | `.cursor/skills/` | Fetches scoped `cursor/` UX from upstream (see effective scope) |
| `agent` | skills.sh, Claude Code, Codex, Kiro, Windsurf, or any agent using `*/skills/` | `.agents/skills/` (else first discovered root) | none |
| `cursor-hybrid` | Cursor editor + `npx skills add` (skills in `.agents/skills/`) | `.agents/skills/` | same scoped upstream fetch as `cursor` |

Aliases: `--cursor`, `--agent`, `--cursor-hybrid`.

`--profile auto` (default) detects from the repo layout and prints the recommendation in the plan.

## Confirm-first flow

```bash
# 1) Plan only — safe default, no mutations
bash .cursor/skills/verasic-init/scripts/init.sh
bash .cursor/skills/verasic-init/scripts/init.sh --profile agent

# 2) Apply after you agree (network required for cursor / cursor-hybrid UX fetch)
bash .cursor/skills/verasic-init/scripts/init.sh --yes --profile agent
bash .cursor/skills/verasic-init/scripts/init.sh --yes --profile cursor
bash .cursor/skills/verasic-init/scripts/init.sh --yes --profile cursor-hybrid --verify
```

`--list` remains a pure integrity/install inspect (no profile plan, no mutations).

## Upstream fetch (cursor / cursor-hybrid)

On `--yes`, init downloads files from `references/skill-ux-map.txt` filtered to the **effective scope** (see `references/init-protocol.md`):

- With `--skills a,b`: scope is exactly those skills.
- Without `--skills`: scope is manifest skills physically installed in the repo.

Files are fetched from the installed skill's release tag by default:

```text
https://raw.githubusercontent.com/Milkywayrules/verasic-skills/v<VERSION>/cursor/<path>
```

(`<VERSION>` comes from `skills/.../verasic-init/VERSION`.) If the tag is not yet on GitHub,
init retries once from `main`. Override for tests or mirrors:

```bash
export VERASIC_INIT_REMOTE_REPO_BASE=https://raw.githubusercontent.com/Milkywayrules/verasic-skills/main
# or a local directory: VERASIC_INIT_REMOTE_REPO_BASE=/path/to/mock-upstream
```

Fetch failure adds a `cursor-ux` **FAILED** row in the report and init exits **1** (repo wiring may still have completed).

Repo-root `cursor/` is the **single source of truth** — no bundled copy inside the skill.

## Usage after init

When you cherry-pick with `--skills` or install a subset via skills.sh, the init report **usage** section lists only what is in **effective scope** — treat that as authoritative. The lists below describe a **full suite** install.

### cursor

- Slash commands: `/verasic-init`, `/verasic-review`, `/verasic-fusion`, `/verasic-deep-research`, `/verasic-audit-commits`, `/verasic-setup-github`
- Always-on rules: commit convention + GitHub env (under `.cursor/rules/`)
- Subagents: `verasic-bugbot`, `verasic-commit-auditor` (under `.cursor/agents/`)

### cursor-hybrid

- Same slash commands and rules as `cursor`
- Skills live under `.agents/skills/` — command files say to adjust the `.cursor/skills/` path prefix when needed
- Wiring (hooks, `.envrc`, credentials) uses `.agents/skills/`

### agent

- No slash commands or Cursor rules — invoke by skill name or attach `SKILL.md`
- Read each skill's `references/` for protocols; paths use your install root (e.g. `.agents/skills/verasic-bugbot/`)
- Repo wiring (commit hook, GitHub env files) still applies after `--yes`

## Profile gaps init does not auto-fix

Init does **not** move skills between `.agents/skills/` and `.cursor/skills/`.
If the profile and skills location mismatch, the plan lists the gap — pick another profile or re-run `setup.sh`.
