# Verasic Init

One command to wire every installed Verasic skill into a repository. Detects
which `verasic-*` skills are present next to it, runs each skill's own wiring
script idempotently, and prints a single setup report. Built for the
skills.sh install path where `setup.sh` never runs, and equally useful after
a Cursor `setup.sh` install.

## Parts

| File | Role |
| --- | --- |
| `scripts/init.sh` | Orchestrator — detect, wire, report |
| `manifest.txt` | Registry: skill → wiring script → description |
| `references/init-protocol.md` | Spec — wire contract, statuses, extension guide |
| `scripts/test-regression.sh` | Disposable regression tests |

## Usage

From the target repository's root:

```bash
bash .cursor/skills/verasic-init/scripts/init.sh              # wire everything installed
bash .cursor/skills/verasic-init/scripts/init.sh --skills verasic-bugbot,verasic-git-commits
bash .cursor/skills/verasic-init/scripts/init.sh --list       # inspect only, change nothing
```

Or in Cursor: `/verasic-init`

Installed under a different root (skills.sh, Claude Code, …)? The script
derives its paths from its own location — run it from wherever the skill
landed; no configuration needed.

## What gets wired

| Skill | Wiring |
| --- | --- |
| `verasic-github-env` | `.envrc`, `.env.example` GH block, `.gitignore`, credential template |
| `verasic-git-commits` | `core.hooksPath` → deterministic commit-msg hook (or prints a lefthook/chaining snippet if hooks already exist) |
| `verasic-bugbot` | nothing — skill-only |

Skills that are not installed are reported as `not installed` and skipped —
cherry-picked installs just work.

## Report

The full output of `init.sh` is the report: status table, per-skill details,
result tally, and a `next:` line. Agents are instructed to relay it verbatim.
Re-running is always safe — every wiring script is idempotent.

## Install into a project

```bash
curl -fsSL https://raw.githubusercontent.com/Milkywayrules/verasic-skills/main/setup.sh | bash
```

Skill-only (any agent):

```bash
npx skills add Milkywayrules/verasic-skills
```

## Regression tests

```bash
bash .cursor/skills/verasic-init/scripts/test-regression.sh
```
