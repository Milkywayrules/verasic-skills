# Scanner notes — verasic-bugbot

## Why scanners may flag this skill

- **Bundled Critical (Snyk)** — Package-level scans flag the entire skills bundle; bugbot
  itself has no credential or hook wiring scripts.
- **Security checklist content** — `checklists/security.md` discusses injection, secrets,
  authz, and deserialization — keywords that trigger static secret/vuln classifiers.
- **Git diff access** — Review protocol reads branch and uncommitted diffs plus full file
  context; scanners may classify broad file/git access as data exfil patterns.
- **Subagent spawn** — Cursor Task subagent runs review in isolated context.

## Mitigations

- **Review only** — No writes, commits, or network calls from the skill itself.
- **Real bugs only** — Style nitpicks are explicitly excluded; reduces noise and scope.
- **Full-file reads required** — Protocol mandates reading complete files, not hunks alone
  (quality control, not stealth scanning).
- **User-triggered** — Runs on explicit review request or after significant local changes.
- **Zero findings is valid** — No incentive to invent issues.

See upstream [SECURITY.md](https://github.com/Milkywayrules/verasic-skills/blob/main/SECURITY.md).
