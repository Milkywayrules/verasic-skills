# Scanner notes — verasic-deep-research

## Why scanners may flag this skill

- **Bundled with high-risk harness skills** — Snyk and similar often score the whole
  `verasic-skills` package; deep-research inherits bundle-level alerts even though it
  is mostly markdown protocols and workflows.
- **Subagent / Task dispatch** — Protocol instructs spawning parallel T2 research workers
  (Hunter, Practitioner, Skeptic, Arbiter). Scanners may classify multi-agent orchestration
  as elevated execution surface.
- **HTTP fetch instructions** — Verify-before-cite requires readonly web fetch; scanners
  may flag outbound network guidance, especially under `aggressive-scrape` boundary docs.
- **External model APIs (runtime)** — When invoked, the host agent calls model providers
  and web sources; that traffic is outside this repo's scripts.

## Mitigations

- **Verify-before-cite** — No citation without ledger row; reduces hallucinated source risk.
- **Source boundary contract** — User must explicitly choose boundary; agent recommends
  `public-standard`; refuses insider/illegal collection.
- **No secrets in skill** — Protocols contain no tokens, env loaders, or credential files.
- **Ask mode guard** — No file writes in read-only chat mode.
- **Fusion handoff manual only** — No automatic cross-skill spawn or hidden bridges.
- **Degraded mode requires consent** — Sequential single-context research only after user confirms.
- **Sensitive domain disclaimers** — Health/legal/financial floor and not-professional-advice language.

See upstream [SECURITY.md](https://github.com/Milkywayrules/verasic-skills/blob/main/SECURITY.md).
