# Known model slugs

Slugs below are common Cursor / Verasic harness identifiers. Availability varies by
account, plan, and platform. The main agent validates before spawn — **no silent
substitution**.

Always include **`composer-2.5-fast`** in fusion rosters unless the user explicitly
excludes it (Verasic default orchestration model).

## Recommended roster (when user asks for suggestions)

```text
composer-2.5-fast, gemini-3-flash, glm-5.2-high, claude-sonnet-5-thinking-high
```

Adjust if any slug is unavailable on the harness or account.

## Slug reference

| User-facing name  | Slug                              |
| ----------------- | --------------------------------- |
| Composer 2.5 Fast | `composer-2.5-fast`               |
| Gemini Flash      | `gemini-3-flash`                  |
| Gemini Pro        | `gemini-3.1-pro`                  |
| Sonnet            | `claude-sonnet-5-thinking-high`   |
| Haiku             | `claude-haiku-4-5`                |
| Opus              | `claude-opus-4-8-thinking-medium` |
| GLM               | `glm-5.2-high`                    |
| Auto              | `auto`                            |
| Grok              | `cursor-grok-4.5-medium`          |
| Fable 5           | `claude-fable-5-thinking-xhigh`   |
| GPT               | `gpt-5.6-sol-medium`              |
| Codex             | `gpt-5.6-terra-medium`            |
| Kimi              | `kimi-k2`                         |

## Aliases (normalize to slug before spawn)

| Alias                                       | Normalized slug                   |
| ------------------------------------------- | --------------------------------- |
| `composer`, `composer-2.5`, `composer-fast` | `composer-2.5-fast`               |
| `gemini-flash`, `flash`                     | `gemini-3-flash`                  |
| `gemini-pro`, `pro`                         | `gemini-3.1-pro`                  |
| `sonnet-5`, `claude-sonnet`                 | `claude-sonnet-5-thinking-high`   |
| `haiku`, `claude-haiku`                     | `claude-haiku-4-5`                |
| `opus-4.8`, `claude-opus`, `opus`           | `claude-opus-4-8-thinking-medium` |
| `glm`, `glm-5`, `glm-5.2`                   | `glm-5.2-high`                    |
| `fable`, `fable-5`                          | `claude-fable-5-thinking-xhigh`   |
| `grok-4.5`, `grok`                          | `cursor-grok-4.5-medium`          |
| `gpt-5.6`, `gpt`, `sol`                     | `gpt-5.6-sol-medium`              |
| `codex`, `terra`                            | `gpt-5.6-terra-medium`            |
| `kimi`                                      | `kimi-k2`                         |

If the harness exposes a different canonical slug at runtime, prefer the harness list
and update this file upstream. Slugs not on the harness list may still be valid elsewhere —
fail before spawn with substitutes; do not silently swap models.

## Harness availability (Cursor Task)

These slugs are known to the catalog but **may fail** Task spawn on some accounts or quota
states: `kimi-k2`, `claude-haiku-4-5` (validate before spawn — often unavailable in Cursor
Task). Prefer validating at pre-flight; use substitutes from the table below. GLM (`glm-5.2-high`) and frontier models may hit API usage limits —
report unavailable slugs; fuse from surviving models unless all inputs are unusable.

## Substitutes when unavailable

| If unavailable                    | Try                               |
| --------------------------------- | --------------------------------- |
| `claude-opus-4-8-thinking-medium` | `claude-sonnet-5-thinking-high`   |
| `claude-fable-5-thinking-xhigh`   | `claude-opus-4-8-thinking-medium` |
| `gemini-3.1-pro`                  | `gemini-3-flash`                  |
| `gemini-3-flash`                  | `glm-5.2-high`                    |
| `gpt-5.6-terra-medium`            | `gpt-5.6-sol-medium`              |
| `glm-5.2-high`                    | `cursor-grok-4.5-medium`          |
| `kimi-k2`                         | `cursor-grok-4.5-medium`          |
| `claude-haiku-4-5`                | `gemini-3-flash`                  |

Always keep `composer-2.5-fast` when substituting.
