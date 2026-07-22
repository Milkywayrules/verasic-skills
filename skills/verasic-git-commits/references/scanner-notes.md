# Scanner notes — verasic-git-commits

## Why scanners may flag this skill

- **Git hooks (Gen High Risk)** — Installs a `commit-msg` hook via
  `git config core.hooksPath`. Hook managers and supply-chain tools treat arbitrary hook
  paths as persistent code execution.
- **Hook modifies commit messages** — The hook strips `Co-authored-by:` / generated
  attribution lines before the commit object is written.
- **`git config` writes** — `wire-hook.sh` sets repo-local `core.hooksPath` when no
  conflicting hook manager is detected.
- **History rewrite documentation** — Protocol documents `git commit-tree` escape hatch
  (fallback only, user-approved, unpushed commits). Scanners may flag commit-tree recipes
  as tamper/evasion.
- **Audit reads git history** — Pre-push audit scans commit messages and may suggest fix
  mode after explicit approval.

## Mitigations

- **Transparent hook source** — Hook lives in the skill directory (`hooks/commit-msg`);
  integrity hashes ship in `integrity.sha256`.
- **No silent overwrite** — If lefthook/husky or another hook manager exists, wire script
  prints a snippet (exit 3) instead of clobbering.
- **Client-side only** — Hooks are local; `--no-verify` is forbidden by the skill rule;
  audit is the backstop.
- **Audit is read-only by default** — Fix mode (`--fix-trailers`) runs only after explicit
  user approval in the main conversation.
- **Deterministic, small hook** — No network, no secret access; regex/strip + style checks
  only.

See upstream [SECURITY.md](https://github.com/Milkywayrules/verasic-skills/blob/main/SECURITY.md).
