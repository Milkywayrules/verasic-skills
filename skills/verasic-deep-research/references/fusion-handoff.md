# Fusion handoff — verasic-deep-research

Manual optional chain from deep research to multi-model fusion. **No auto-bridge.**

## When to suggest

Suggest fusion **only** when:

1. Deliverable includes **`## unverified`** items or persistent **`## gaps`** after drill plateau, and
2. User would benefit from multi-model exploration (opinions, framing, next steps — not facts), and
3. **`verasic-fusion` is installed** — detect `.cursor/skills/verasic-fusion/` or
   `.agents/skills/verasic-fusion/`, or user confirms installation.

If fusion is **not** installed → mention it as an optional install; do not invent fusion output.

## What fusion is not

- Not a substitute for verify-before-cite
- Not a way to upgrade `[Sn]` ledger rows without fetch
- Not automatic — user must run `/verasic-fusion` separately

Use **`brief-research`** template only — not board-verdict or other templates unless
user explicitly asks.

## Check fusion installed

```text
1. Glob skill root for verasic-fusion/SKILL.md under known prefixes
2. If missing → "Install verasic-fusion for multi-model gap exploration" + stop
3. If present → offer copy-paste block below
```

Never spawn fusion subagents from deep-research main agent.

## Copy-paste example (user runs manually)

```text
/verasic-fusion
mode: fusion
models: composer-2.5-fast, gemini-3-flash, claude-sonnet-5-thinking-high
template: brief-research

Context: Deep research completed on "<topic>" with verified ledger.
Unverified gaps:
- <gap one from ## unverified>
- <gap two>

Question: What are plausible interpretations and next research directions for these gaps?
Do not treat this as verified fact — opinion brief only.
```

Adjust models per user roster preferences; recommend including `composer-2.5-fast`.

## What to pass from deep research

Include in the fusion question body:

- Original research question
- Overall confidence headline
- Bullet list from `## unverified` and material `## gaps`
- Explicit instruction: fusion output is **not** ledger-verified

Do **not** paste full source ledger unless user wants it — summary is enough.

## After fusion

User may return to deep research with new concrete claims to verify. Deep research
does not read fusion outputs as verified automatically — re-run verify pipeline.

## Claims-investigation linkage

For claims stuck at `unverified` in `## claim ledger`, fusion can explore **why**
sources might disagree or what to search next — label fusion sections clearly as
_non-verified exploration_.
