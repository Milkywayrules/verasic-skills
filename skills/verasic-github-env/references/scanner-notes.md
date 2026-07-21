# Scanner notes — verasic-github-env

## Why scanners may flag this skill

- **Secrets / credentials (Gen High Risk)** — Documents and loads `GH_TOKEN` from
  gitignored `.github-agent.local`. Scanners flag any skill that mentions PATs, tokens, or
  credential file paths.
- **Environment file handling** — `bootstrap.sh` writes `.envrc`, templates, and
  `.gitignore` entries. `load-gh-env.sh` reads `GH_*` key/value lines.
- **Shell patterns** — Bash scripts that parse env files and invoke `gh` look like
  secret-exfil or credential-stuffing to heuristic engines.
- **Git config (tests only)** — Regression tests may set `core.excludesFile` in disposable
  temp repos.

## Mitigations

- **Tier separation** — Local agents use `.github-agent.local` only; CI and production
  use their own tiers (never mixed in docs or scripts).
- **Scoped PAT** — One fine-grained PAT per repo, minimum permissions documented in
  `setup-protocol.md`.
- **Safe loader** — `load-gh-env.sh` parses lines; does not `eval` or `source` the
  credential file as shell.
- **Verify without logging** — `check-gh.sh` confirms auth; agents are instructed not to
  run bare `gh auth status` in chat logs.
- **Gitignored by default** — Bootstrap adds `.github-agent.local` to `.gitignore`.
- **No device-flow loops** — Skill forbids `gh auth login` polling for harness setup.

See root [SECURITY.md](../../../SECURITY.md).
