# Scanner notes — verasic-fusion

## Why scanners may flag this skill

- **Bundled with high-risk harness skills** — Snyk and similar often score the whole
  `verasic-skills` package; fusion inherits bundle-level Critical alerts even though it
  is mostly markdown protocols and templates.
- **Subagent / Task dispatch** — Protocol instructs spawning parallel model subagents.
  Scanners may classify multi-agent orchestration as elevated execution surface.
- **Bash test scripts** — `test-regression.sh`, `test-exhaustive*.sh` use shell patterns
  common in CI gates.
- **External model APIs (runtime)** — When invoked, the host agent calls model providers;
  that traffic is outside this repo's scripts.

## Mitigations

- **Read-only by design** — Hard rule: decision support only; no file edits, commits, or
  deploys.
- **No default models** — User must name `mode` and `models`; no silent substitution.
- **No secrets in skill** — Templates and protocols contain no tokens or env loaders.
- **Provenance preserved** — Conflicts between models are surfaced, not flattened.
- **Degraded mode requires consent** — Sequential simulation only after user confirms when
  parallel subagents are unavailable.

See upstream [SECURITY.md](https://github.com/Milkywayrules/verasic-skills/blob/main/SECURITY.md).
