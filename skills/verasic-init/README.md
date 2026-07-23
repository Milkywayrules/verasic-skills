# Verasic Init

Confirm-first setup for every installed Verasic skill in a repository. Default run
prints an **install profile**, **checklist**, **usage guide**, and would-wire preview —
then waits for `--yes`. Built for skills.sh users who never see the GitHub README,
and equally useful after Cursor `setup.sh`.

## Parts

| File                              | Role                                              |
| --------------------------------- | ------------------------------------------------- |
| `scripts/init.sh`                 | Orchestrator — plan, wire, report                 |
| `scripts/profile.sh`                | Profile detect, checklist, upstream Cursor UX fetch |
| `references/cursor-ux-manifest.txt` | Full upstream Cursor UX file list |
| `references/skill-ux-map.txt`       | Skill → Cursor UX path mapping (scope filter) |
| `references/install-profiles.md`    | Profile spec (cursor / agent / cursor-hybrid)       |
| `manifest.txt`                      | Registry: skill → wiring → verify → description     |
| `references/init-protocol.md`       | Wire contract, statuses, extension guide            |
| `scripts/test-regression.sh`      | Disposable regression tests                       |

## Usage

From the target repository's root:

```bash
# 1) Plan — safe default
bash .cursor/skills/verasic-init/scripts/init.sh
bash .cursor/skills/verasic-init/scripts/init.sh --profile agent

# 2) Apply after you confirm
bash .cursor/skills/verasic-init/scripts/init.sh --yes --profile cursor
bash .cursor/skills/verasic-init/scripts/init.sh --yes --profile agent
bash .cursor/skills/verasic-init/scripts/init.sh --yes --profile cursor-hybrid

# Inspect / cherry-pick
bash .cursor/skills/verasic-init/scripts/init.sh --list
bash .cursor/skills/verasic-init/scripts/init.sh --yes --skills verasic-bugbot,verasic-git-commits
bash .cursor/skills/verasic-init/scripts/init.sh --yes --verify --profile cursor
```

Or in Cursor: `/verasic-init` (agent runs plan first, asks you, then `--yes`).

## Profiles

| Profile         | Typical user                         | `--yes` adds                                    |
| --------------- | ------------------------------------ | ----------------------------------------------- |
| `cursor`        | Cursor + `setup.sh`                  | fetches Cursor UX from upstream + repo wiring              |
| `agent`         | skills.sh, Claude Code, Codex, Kiro  | repo wiring only; usage guide for skill invoke  |
| `cursor-hybrid` | Cursor + `npx skills add`            | fetches Cursor UX from upstream + repo wiring from `.agents/skills/`  |

Full spec: [references/install-profiles.md](references/install-profiles.md)

## What `--yes` wires (repo-level)

| Skill                 | Wiring                                                                                                          |
| --------------------- | --------------------------------------------------------------------------------------------------------------- |
| `verasic-github-env`  | `.envrc`, `.env.example` GH block, `.gitignore`, credential template                                            |
| `verasic-git-commits` | `core.hooksPath` → commit-msg hook (or manual snippet if lefthook/husky exists)                                 |
| `verasic-bugbot`      | nothing — skill-only                                                                                            |

Skills not installed are reported as `not installed` and skipped.

## Report

Plan and apply reports include scope, profile checklist, usage, versions, status table, details, actions, and a `next:` line. With `--skills`, checklist/usage/UX fetch/versions reflect that subset only. Agents relay verbatim. Re-running `--yes` is idempotent.

## Install into a project

```bash
curl -fsSL https://raw.githubusercontent.com/Milkywayrules/verasic-skills/main/setup.sh | bash
```

Skill-only (any agent):

```bash
npx skills add Milkywayrules/verasic-skills
# then: bash .agents/skills/verasic-init/scripts/init.sh --yes --profile agent
# or:   bash .agents/skills/verasic-init/scripts/init.sh --yes --profile cursor-hybrid
```

Security: [references/scanner-notes.md](references/scanner-notes.md) · upstream [SECURITY.md](https://github.com/Milkywayrules/verasic-skills/blob/main/SECURITY.md)

## Regression tests

```bash
bash skills/verasic-init/scripts/test-regression.sh   # from verasic-skills repo root
bash .cursor/skills/verasic-init/scripts/test-regression.sh
```
