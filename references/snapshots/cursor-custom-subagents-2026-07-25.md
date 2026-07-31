# Snapshot: Cursor custom subagents

**Date:** 2026-07-25  
**Cursor:** 3.12.29 (`cd1c87ff…`)  
**Account catalog:** `cursor agent --list-models` → **190** slugs (raw output includes 2 non-slug lines: title + tip)  
**Evidence:** orchestrator [bc578ce3](bc578ce3-28bb-405e-aded-85fb66dfd954) T01–T70 — short IDs are Cursor chat-transcript handles, not repo paths

See [cursor-custom-subagents.md](../cursor-custom-subagents.md) and [ADR 0002](../adr/0002-cursor-custom-subagents.md).

---

## Author selection roster (Phase 1)

| `name:`                                              | `model:`                      | Spawn path (observed)                    |
| ---------------------------------------------------- | ----------------------------- | ---------------------------------------- |
| `subagent-opus-5-low-nonthinking-fast`               | `claude-opus-5-low-fast`      | `subagent_type`; inline override OK      |
| `subagent-opus-5-medium-nonthinking-fast`            | `claude-opus-5-medium-fast`   | `subagent_type`; inline override OK      |
| `subagent-opus-4-8-low-nonthinking-fast`             | `claude-opus-4-8-low-fast`    | `subagent_type`; inline override OK      |
| `subagent-opus-4-8-medium-nonthinking-fast`          | `claude-opus-4-8-medium-fast` | `subagent_type`; inline override OK      |
| `subagent-gpt-5.6-sol-reasoning-low-fast`            | `gpt-5.6-sol-low-fast`        | `subagent_type`; inline override OK      |
| `subagent-gpt-5.6-sol-reasoning-medium-fast`         | `gpt-5.6-sol-medium-fast`     | `subagent_type`; inline override OK      |
| `subagent-gpt-5.6-terra-reasoning-low-fast`          | `gpt-5.6-terra-low-fast`      | `subagent_type`; inline override OK      |
| `subagent-gpt-5.6-terra-reasoning-medium-fast`       | `gpt-5.6-terra-medium-fast`   | `subagent_type`; inline override OK      |
| `subagent-composer-default-nonthinking-fast`         | `composer-2.5-fast`           | `subagent_type`; inline override OK      |
| `subagent-grok-reasoning-high-fast`                  | `cursor-grok-4.5-high-fast`   | `subagent_type`; inline override OK      |
| `subagent-grok-reasoning-medium-fast`                | `cursor-grok-4.5-medium-fast` | `subagent_type`; inline override OK      |
| `subagent-kimi-default-nonthinking-notfast`          | `kimi-k2.7-code`              | `subagent_type`; inline override OK      |
| `subagent-gemini-3.6-flash-reasoning-low-notfast`    | `gemini-3.6-flash-low`        | **`subagent_type` only** — inline reject |
| `subagent-gemini-3.6-flash-reasoning-medium-notfast` | `gemini-3.6-flash-medium`     | **`subagent_type` only** — inline reject |
| `subagent-gemini-3.1-pro-default-notfast`            | `gemini-3.1-pro`              | `subagent_type`; inline override OK      |
| `subagent-inherit`                                   | `inherit`                     | `subagent_type` (inherits parent model)  |

Source files: `etc/cursor/agents/`.

---

## Task inline `model` — observed pass/fail (T01–T70)

Error messages list ~30 slugs; **many more pass** inline. Do not treat error allowlist as exhaustive.

### Hard reject (inline)

| Slug / pattern                                        | Test     |
| ----------------------------------------------------- | -------- |
| `composer-2.5`                                        | T44      |
| `gemini-3.6-flash-low`                                | T42      |
| `gemini-3.6-flash-medium`                             | T21, T59 |
| `gpt-5.6-terra[context=272k,reasoning=low,fast=true]` | T34      |
| Invalid `subagent_type`                               | T66      |

### Pass inline (sample — includes slugs omitted from error allowlist)

| Slug                          | Test     |
| ----------------------------- | -------- |
| `composer-2.5-fast`           | T04, T58 |
| `claude-opus-5-low-fast`      | T19b     |
| `claude-opus-5-medium-fast`   | T43      |
| `claude-opus-4-8-low-fast`    | T54      |
| `claude-opus-4-8-medium-fast` | T68      |
| `cursor-grok-4.5-high-fast`   | T20b     |
| `cursor-grok-4.5-medium-fast` | T60      |
| `gpt-5.6-terra-low-fast`      | T15      |
| `gpt-5.6-terra-medium-fast`   | T40      |
| `gpt-5.6-sol-low-fast`        | T53      |
| `gpt-5.6-sol-medium-fast`     | T69      |
| `gpt-5.5-medium`              | T17      |
| `gpt-5.4-medium`              | T18      |
| `gpt-5.6-luna-medium`         | T26      |
| `gemini-3.1-pro`              | T37      |
| `gemini-3.6-flash-high`       | T13      |
| `gemini-3.5-flash`            | T25      |
| `glm-5.2-high`                | T36      |
| `kimi-k2.7-code`              | T11      |
| `claude-opus-5-thinking-high` | T14      |

### Error-message allowlist (partial dump, T21/T59)

`claude-4-sonnet`, `claude-4.5-haiku-thinking`, `claude-4.5-opus-high-thinking`, `claude-4.5-sonnet-thinking`, `claude-4.6-opus-medium`, `claude-4.6-sonnet-medium`, `claude-fable-5-thinking-high`, `claude-opus-4-7-thinking-xhigh`, `claude-opus-4-8-thinking-medium`, `claude-opus-5-thinking-high`, `claude-sonnet-5-thinking-high`, `composer-2.5-fast`, `cursor-grok-4.5-medium`, `gemini-2.5-flash`, `gemini-3-flash`, `gemini-3.1-pro`, `gemini-3.5-flash`, `gemini-3.6-flash-high`, `glm-5.2-high`, `gpt-5-mini`, `gpt-5.1`, `gpt-5.2`, `gpt-5.3-codex`, `gpt-5.4-medium`, `gpt-5.4-mini-medium`, `gpt-5.4-nano-medium`, `gpt-5.5-medium`, `gpt-5.6-luna-medium`, `gpt-5.6-sol-medium`, `gpt-5.6-terra-low-fast`, `kimi-k2.7-code`

---

## Full catalog (`cursor agent --list-models`)

### meta

| Slug   | Label          |
| ------ | -------------- |
| `auto` | Auto (default) |

### composer

| Slug                | Label                  |
| ------------------- | ---------------------- |
| `composer-2.5`      | Composer 2.5 (current) |
| `composer-2.5-fast` | Composer 2.5 Fast      |

### cursor-grok

| Slug                          | Label                       |
| ----------------------------- | --------------------------- |
| `cursor-grok-4.5-high`        | Cursor Grok 4.5             |
| `cursor-grok-4.5-high-fast`   | Cursor Grok 4.5 Fast        |
| `cursor-grok-4.5-low`         | Cursor Grok 4.5 Low         |
| `cursor-grok-4.5-low-fast`    | Cursor Grok 4.5 Low Fast    |
| `cursor-grok-4.5-medium`      | Cursor Grok 4.5 Medium      |
| `cursor-grok-4.5-medium-fast` | Cursor Grok 4.5 Medium Fast |

### claude-opus

| Slug                                   | Label                                |
| -------------------------------------- | ------------------------------------ |
| `claude-opus-5-thinking-high`          | Opus 5 1M Thinking                   |
| `claude-opus-5-thinking-high-fast`     | Opus 5 1M Thinking Fast              |
| `claude-opus-4-8-thinking-high`        | Opus 4.8 1M Thinking                 |
| `claude-opus-4-8-thinking-high-fast`   | Opus 4.8 1M Thinking Fast            |
| `claude-opus-5-low`                    | Opus 5 1M Low                        |
| `claude-opus-5-low-fast`               | Opus 5 1M Low Fast                   |
| `claude-opus-5-medium`                 | Opus 5 1M Medium                     |
| `claude-opus-5-medium-fast`            | Opus 5 1M Medium Fast                |
| `claude-opus-5-high`                   | Opus 5 1M                            |
| `claude-opus-5-high-fast`              | Opus 5 1M Fast                       |
| `claude-opus-5-thinking-low`           | Opus 5 1M Low Thinking               |
| `claude-opus-5-thinking-low-fast`      | Opus 5 1M Low Thinking Fast          |
| `claude-opus-5-thinking-medium`        | Opus 5 1M Medium Thinking            |
| `claude-opus-5-thinking-medium-fast`   | Opus 5 1M Medium Thinking Fast       |
| `claude-opus-5-thinking-xhigh`         | Opus 5 1M Extra High Thinking        |
| `claude-opus-5-thinking-xhigh-fast`    | Opus 5 1M Extra High Thinking Fast   |
| `claude-opus-5-thinking-max`           | Opus 5 1M Max Thinking               |
| `claude-opus-5-thinking-max-fast`      | Opus 5 1M Max Thinking Fast          |
| `claude-opus-4-8-low`                  | Opus 4.8 1M Low                      |
| `claude-opus-4-8-low-fast`             | Opus 4.8 1M Low Fast                 |
| `claude-opus-4-8-medium`               | Opus 4.8 1M Medium                   |
| `claude-opus-4-8-medium-fast`          | Opus 4.8 1M Medium Fast              |
| `claude-opus-4-8-high`                 | Opus 4.8 1M                          |
| `claude-opus-4-8-high-fast`            | Opus 4.8 1M Fast                     |
| `claude-opus-4-8-xhigh`                | Opus 4.8 1M Extra High               |
| `claude-opus-4-8-xhigh-fast`           | Opus 4.8 1M Extra High Fast          |
| `claude-opus-4-8-max`                  | Opus 4.8 1M Max                      |
| `claude-opus-4-8-max-fast`             | Opus 4.8 1M Max Fast                 |
| `claude-opus-4-8-thinking-low`         | Opus 4.8 1M Low Thinking             |
| `claude-opus-4-8-thinking-low-fast`    | Opus 4.8 1M Low Thinking Fast        |
| `claude-opus-4-8-thinking-medium`      | Opus 4.8 1M Medium Thinking          |
| `claude-opus-4-8-thinking-medium-fast` | Opus 4.8 1M Medium Thinking Fast     |
| `claude-opus-4-8-thinking-xhigh`       | Opus 4.8 1M Extra High Thinking      |
| `claude-opus-4-8-thinking-xhigh-fast`  | Opus 4.8 1M Extra High Thinking Fast |
| `claude-opus-4-8-thinking-max`         | Opus 4.8 1M Max Thinking             |
| `claude-opus-4-8-thinking-max-fast`    | Opus 4.8 1M Max Thinking Fast        |
| `claude-opus-4-7-low`                  | Opus 4.7 1M Low                      |
| `claude-opus-4-7-low-fast`             | Opus 4.7 1M Low Fast                 |
| `claude-opus-4-7-medium`               | Opus 4.7 1M Medium                   |
| `claude-opus-4-7-medium-fast`          | Opus 4.7 1M Medium Fast              |
| `claude-opus-4-7-high`                 | Opus 4.7 1M High                     |
| `claude-opus-4-7-high-fast`            | Opus 4.7 1M High Fast                |
| `claude-opus-4-7-xhigh`                | Opus 4.7 1M                          |
| `claude-opus-4-7-xhigh-fast`           | Opus 4.7 1M Fast                     |
| `claude-opus-4-7-max`                  | Opus 4.7 1M Max                      |
| `claude-opus-4-7-max-fast`             | Opus 4.7 1M Max Fast                 |
| `claude-opus-4-7-thinking-low`         | Opus 4.7 1M Low Thinking             |
| `claude-opus-4-7-thinking-low-fast`    | Opus 4.7 1M Low Thinking Fast        |
| `claude-opus-4-7-thinking-medium`      | Opus 4.7 1M Medium Thinking          |
| `claude-opus-4-7-thinking-medium-fast` | Opus 4.7 1M Medium Thinking Fast     |
| `claude-opus-4-7-thinking-high`        | Opus 4.7 1M High Thinking            |
| `claude-opus-4-7-thinking-high-fast`   | Opus 4.7 1M High Thinking Fast       |
| `claude-opus-4-7-thinking-xhigh`       | Opus 4.7 1M Thinking                 |
| `claude-opus-4-7-thinking-xhigh-fast`  | Opus 4.7 1M Thinking Fast            |
| `claude-opus-4-7-thinking-max`         | Opus 4.7 1M Max Thinking             |
| `claude-opus-4-7-thinking-max-fast`    | Opus 4.7 1M Max Thinking Fast        |

### claude-sonnet

| Slug                              | Label                           |
| --------------------------------- | ------------------------------- |
| `claude-sonnet-5-low`             | Sonnet 5 1M Low                 |
| `claude-sonnet-5-medium`          | Sonnet 5 1M Medium              |
| `claude-sonnet-5-high`            | Sonnet 5 1M                     |
| `claude-sonnet-5-xhigh`           | Sonnet 5 1M Extra High          |
| `claude-sonnet-5-max`             | Sonnet 5 1M Max                 |
| `claude-sonnet-5-thinking-low`    | Sonnet 5 1M Low Thinking        |
| `claude-sonnet-5-thinking-medium` | Sonnet 5 1M Medium Thinking     |
| `claude-sonnet-5-thinking-high`   | Sonnet 5 1M Thinking            |
| `claude-sonnet-5-thinking-xhigh`  | Sonnet 5 1M Extra High Thinking |
| `claude-sonnet-5-thinking-max`    | Sonnet 5 1M Max Thinking        |

### claude-fable

| Slug                             | Label                                   |
| -------------------------------- | --------------------------------------- |
| `claude-fable-5-thinking-high`   | Fable 5 1M Thinking (NO ZDR)            |
| `claude-fable-5-thinking-xhigh`  | Fable 5 1M Extra High Thinking (NO ZDR) |
| `claude-fable-5-low`             | Fable 5 1M Low (NO ZDR)                 |
| `claude-fable-5-medium`          | Fable 5 1M Medium (NO ZDR)              |
| `claude-fable-5-high`            | Fable 5 1M (NO ZDR)                     |
| `claude-fable-5-xhigh`           | Fable 5 1M Extra High (NO ZDR)          |
| `claude-fable-5-max`             | Fable 5 1M Max (NO ZDR)                 |
| `claude-fable-5-thinking-low`    | Fable 5 1M Low Thinking (NO ZDR)        |
| `claude-fable-5-thinking-medium` | Fable 5 1M Medium Thinking (NO ZDR)     |
| `claude-fable-5-thinking-max`    | Fable 5 1M Max Thinking (NO ZDR)        |

### claude-legacy

| Slug                                | Label                    |
| ----------------------------------- | ------------------------ |
| `claude-4.6-sonnet-medium`          | Sonnet 4.6 1M            |
| `claude-4.6-sonnet-medium-thinking` | Sonnet 4.6 1M Thinking   |
| `claude-4.6-opus-high`              | Opus 4.6 1M              |
| `claude-4.6-opus-max`               | Opus 4.6 1M Max          |
| `claude-4.6-opus-high-thinking`     | Opus 4.6 1M Thinking     |
| `claude-4.6-opus-max-thinking`      | Opus 4.6 1M Max Thinking |
| `claude-4.5-opus-high`              | Opus 4.5                 |
| `claude-4.5-opus-high-thinking`     | Opus 4.5 Thinking        |
| `claude-4.5-sonnet`                 | Sonnet 4.5               |
| `claude-4.5-sonnet-thinking`        | Sonnet 4.5 Thinking      |
| `claude-4-sonnet`                   | Sonnet 4                 |
| `claude-4-sonnet-thinking`          | Sonnet 4 Thinking        |

### gpt-5.6-sol

| Slug                      | Label                       |
| ------------------------- | --------------------------- |
| `gpt-5.6-sol-high`        | GPT-5.6 Sol 1M High         |
| `gpt-5.6-sol-high-fast`   | GPT-5.6 Sol High Fast       |
| `gpt-5.6-sol-xhigh`       | GPT-5.6 Sol 1M Extra High   |
| `gpt-5.6-sol-xhigh-fast`  | GPT-5.6 Sol Extra High Fast |
| `gpt-5.6-sol-none`        | GPT-5.6 Sol 1M None         |
| `gpt-5.6-sol-none-fast`   | GPT-5.6 Sol None Fast       |
| `gpt-5.6-sol-low`         | GPT-5.6 Sol 1M Low          |
| `gpt-5.6-sol-low-fast`    | GPT-5.6 Sol Low Fast        |
| `gpt-5.6-sol-medium`      | GPT-5.6 Sol 1M              |
| `gpt-5.6-sol-medium-fast` | GPT-5.6 Sol Fast            |
| `gpt-5.6-sol-max`         | GPT-5.6 Sol 1M Max          |
| `gpt-5.6-sol-max-fast`    | GPT-5.6 Sol Max Fast        |

### gpt-5.6-terra

| Slug                        | Label                         |
| --------------------------- | ----------------------------- |
| `gpt-5.6-terra-none`        | GPT-5.6 Terra 1M None         |
| `gpt-5.6-terra-none-fast`   | GPT-5.6 Terra None Fast       |
| `gpt-5.6-terra-low`         | GPT-5.6 Terra 1M Low          |
| `gpt-5.6-terra-low-fast`    | GPT-5.6 Terra Low Fast        |
| `gpt-5.6-terra-medium`      | GPT-5.6 Terra 1M              |
| `gpt-5.6-terra-medium-fast` | GPT-5.6 Terra Fast            |
| `gpt-5.6-terra-high`        | GPT-5.6 Terra 1M High         |
| `gpt-5.6-terra-high-fast`   | GPT-5.6 Terra High Fast       |
| `gpt-5.6-terra-xhigh`       | GPT-5.6 Terra 1M Extra High   |
| `gpt-5.6-terra-xhigh-fast`  | GPT-5.6 Terra Extra High Fast |
| `gpt-5.6-terra-max`         | GPT-5.6 Terra 1M Max          |
| `gpt-5.6-terra-max-fast`    | GPT-5.6 Terra Max Fast        |

### gpt-5.6-luna

| Slug                       | Label                        |
| -------------------------- | ---------------------------- |
| `gpt-5.6-luna-none`        | GPT-5.6 Luna 1M None         |
| `gpt-5.6-luna-none-fast`   | GPT-5.6 Luna None Fast       |
| `gpt-5.6-luna-low`         | GPT-5.6 Luna 1M Low          |
| `gpt-5.6-luna-low-fast`    | GPT-5.6 Luna Low Fast        |
| `gpt-5.6-luna-medium`      | GPT-5.6 Luna 1M              |
| `gpt-5.6-luna-medium-fast` | GPT-5.6 Luna Fast            |
| `gpt-5.6-luna-high`        | GPT-5.6 Luna 1M High         |
| `gpt-5.6-luna-high-fast`   | GPT-5.6 Luna High Fast       |
| `gpt-5.6-luna-xhigh`       | GPT-5.6 Luna 1M Extra High   |
| `gpt-5.6-luna-xhigh-fast`  | GPT-5.6 Luna Extra High Fast |
| `gpt-5.6-luna-max`         | GPT-5.6 Luna 1M Max          |
| `gpt-5.6-luna-max-fast`    | GPT-5.6 Luna Max Fast        |

### gpt-5.5

| Slug                      | Label                   |
| ------------------------- | ----------------------- |
| `gpt-5.5-high`            | GPT-5.5 1M High         |
| `gpt-5.5-high-fast`       | GPT-5.5 High Fast       |
| `gpt-5.5-none`            | GPT-5.5 1M None         |
| `gpt-5.5-none-fast`       | GPT-5.5 None Fast       |
| `gpt-5.5-low`             | GPT-5.5 1M Low          |
| `gpt-5.5-low-fast`        | GPT-5.5 Low Fast        |
| `gpt-5.5-medium`          | GPT-5.5 1M              |
| `gpt-5.5-medium-fast`     | GPT-5.5 Fast            |
| `gpt-5.5-extra-high`      | GPT-5.5 1M Extra High   |
| `gpt-5.5-extra-high-fast` | GPT-5.5 Extra High Fast |

### gpt-5.4

| Slug                  | Label                   |
| --------------------- | ----------------------- |
| `gpt-5.4-high`        | GPT-5.4 1M High         |
| `gpt-5.4-high-fast`   | GPT-5.4 High Fast       |
| `gpt-5.4-low`         | GPT-5.4 1M Low          |
| `gpt-5.4-medium`      | GPT-5.4 1M              |
| `gpt-5.4-medium-fast` | GPT-5.4 Fast            |
| `gpt-5.4-xhigh`       | GPT-5.4 1M Extra High   |
| `gpt-5.4-xhigh-fast`  | GPT-5.4 Extra High Fast |
| `gpt-5.4-mini-none`   | GPT-5.4 Mini None       |
| `gpt-5.4-mini-low`    | GPT-5.4 Mini Low        |
| `gpt-5.4-mini-medium` | GPT-5.4 Mini            |
| `gpt-5.4-mini-high`   | GPT-5.4 Mini High       |
| `gpt-5.4-mini-xhigh`  | GPT-5.4 Mini Extra High |
| `gpt-5.4-nano-none`   | GPT-5.4 Nano None       |
| `gpt-5.4-nano-low`    | GPT-5.4 Nano Low        |
| `gpt-5.4-nano-medium` | GPT-5.4 Nano            |
| `gpt-5.4-nano-high`   | GPT-5.4 Nano High       |
| `gpt-5.4-nano-xhigh`  | GPT-5.4 Nano Extra High |

### gpt-5.3-codex

| Slug                       | Label                     |
| -------------------------- | ------------------------- |
| `gpt-5.3-codex-low`        | Codex 5.3 Low             |
| `gpt-5.3-codex-low-fast`   | Codex 5.3 Low Fast        |
| `gpt-5.3-codex`            | Codex 5.3                 |
| `gpt-5.3-codex-fast`       | Codex 5.3 Fast            |
| `gpt-5.3-codex-high`       | Codex 5.3 High            |
| `gpt-5.3-codex-high-fast`  | Codex 5.3 High Fast       |
| `gpt-5.3-codex-xhigh`      | Codex 5.3 Extra High      |
| `gpt-5.3-codex-xhigh-fast` | Codex 5.3 Extra High Fast |

### gpt-5.x

| Slug                 | Label                   |
| -------------------- | ----------------------- |
| `gpt-5.2`            | GPT-5.2                 |
| `gpt-5.2-low`        | GPT-5.2 Low             |
| `gpt-5.2-low-fast`   | GPT-5.2 Low Fast        |
| `gpt-5.2-fast`       | GPT-5.2 Fast            |
| `gpt-5.2-high`       | GPT-5.2 High            |
| `gpt-5.2-high-fast`  | GPT-5.2 High Fast       |
| `gpt-5.2-xhigh`      | GPT-5.2 Extra High      |
| `gpt-5.2-xhigh-fast` | GPT-5.2 Extra High Fast |
| `gpt-5.1-low`        | GPT-5.1 Low             |
| `gpt-5.1`            | GPT-5.1                 |
| `gpt-5.1-high`       | GPT-5.1 High            |

### gemini

| Slug                       | Label                    |
| -------------------------- | ------------------------ |
| `gemini-3.6-flash-minimal` | Gemini 3.6 Flash Minimal |
| `gemini-3.6-flash-low`     | Gemini 3.6 Flash Low     |
| `gemini-3.6-flash-medium`  | Gemini 3.6 Flash Medium  |
| `gemini-3.6-flash-high`    | Gemini 3.6 Flash         |
| `gemini-3.1-pro`           | Gemini 3.1 Pro           |
| `gemini-3-flash`           | Gemini 3 Flash           |
| `gemini-3.5-flash`         | Gemini 3.5 Flash         |

### kimi

| Slug             | Label          |
| ---------------- | -------------- |
| `kimi-k2.7-code` | Kimi K2.7 Code |

### glm

| Slug           | Label       |
| -------------- | ----------- |
| `glm-5.2-high` | GLM 5.2     |
| `glm-5.2-max`  | GLM 5.2 Max |

### other

| Slug         | Label      |
| ------------ | ---------- |
| `gpt-5-mini` | GPT-5 Mini |
