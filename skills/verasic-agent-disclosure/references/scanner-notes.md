# Scanner notes — verasic-agent-disclosure

## Why scanners may flag this skill

- **Cursor Agent CLI invocation** — `scripts/run-red-team.sh` runs `cursor agent --print --mode ask` in a loop. Supply-chain tools may treat subprocess agent calls as dynamic code execution or credential-adjacent automation.
- **Rule copy to `.cursor/rules/`** — `scripts/wire-rule.sh` writes `verasic-agent-disclosure.mdc` into the target repo and removes legacy `no-expose-agent-internals.mdc`.
- **Adversarial prompt catalog** — `references/red-team-prompts.md` documents extraction and bypass attempts (expected for security regression, not live attack tooling).

## Mitigations

- **Read-only ask mode** — Red-team uses `--mode ask`; no file edits or tool side effects from the CLI harness.
- **No network in wire script** — `wire-rule.sh` only copies a local asset; idempotent `cmp` skip when unchanged.
- **User-initiated red-team** — Not wired into CI by default; operator runs explicitly from repo root.
- **Transparent sources** — Policy asset and hashes ship in `integrity.sha256`; canonical spec in `references/disclosure-policy.md`.

See upstream [SECURITY.md](https://github.com/Milkywayrules/verasic-skills/blob/main/SECURITY.md).
