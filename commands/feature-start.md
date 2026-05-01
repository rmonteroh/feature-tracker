---
description: Start tracking a new feature for time logging
argument-hint: <feature description or name>
allowed-tools: Bash
---

The user wants to start tracking a feature. They wrote:

$ARGUMENTS

## Deriving the name

Before running the script, derive a **concise** name of **3-8 words** in the **user's language**:

- **If the input is already concise** (≤ 8 words, no filler like "voy a", "I want to") → use as-is.
- **If it's a long description, question, or paragraph** → extract: verb + concrete noun, in the user's language, no filler.

Examples (any language):

| User input | Derived name |
|------------|--------------|
| `arreglar bug login OAuth` | `arreglar bug login OAuth` (already concise) |
| `voy a arreglar el bug del login con OAuth porque está fallando en producción` | `arreglar bug login OAuth` |
| `let's fix the OAuth login bug because it's failing in production` | `fix OAuth login bug` |
| `Puedes agregar una opción para pausar la feature...` | `agregar pausa y resume features` |
| `I need to implement the full Stripe integration with webhooks` | `Stripe integration with webhooks` |

## Execute

After deriving the name, run:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/bin/feature-start.sh" "<derived name>"
```

Show only the script's output without extra commentary.
