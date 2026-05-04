---
description: Close the in-progress feature, compute its duration, and append it to the log
allowed-tools: Bash
---

The user wants to close the active feature. Before running the close script, generate a description from the recent conversation.

## Step 1: Check description mode

```bash
echo "${FEATURE_TRACKER_DESCRIPTION_MODE:-structured}"
```

This prints `structured` (default) or `simple`. Use it to decide what JSON shape to build below.

## Step 2: Generate the description

Both modes require an `outcome` field (1-2 sentences in past tense, active voice, capturing what got DONE). Use the user's language (English or Spanish based on their most recent message).

**Good outcome examples (English):**
- `"Fixed OAuth token refresh: retries on 401 with backoff. Added regression test."`
- `"Refactored the export module to handle large datasets. Reduced memory usage by 40%."`

**Good outcome examples (Spanish):**
- `"Arreglé el refresh de OAuth: ahora reintenta en 401 con backoff. Agregué test de regresión."`
- `"Refactoricé el módulo de export para manejar datasets grandes. Reduje uso de memoria 40%."`

**Bad outcome:** `"We discussed possible approaches"` — no concrete outcome. If the conversation truly lacks substance, fall back to `"Worked on: <feature name>"` (in the user's language).

### Mode `simple`

Build JSON with only `outcome`:

```json
{"outcome": "<your generated text>"}
```

### Mode `structured`

Build JSON with `outcome` (required) plus the three optional fields below. **Strongly prefer to fill `problem` and `notes`** — only omit when truly impossible to infer from the feature name + outcome + conversation context.

- **`problem`** — 1 sentence: what was wrong or what need motivated the work. **Always try to derive this**, even if not explicitly discussed:
  - Infer from the feature name (e.g., `"fix login bug"` → `"Login was failing under <inferred condition>"`)
  - Infer from the outcome (e.g., outcome mentions "added retry logic" → problem = "no retry was happening before")
  - Infer from common context (e.g., `"refactor X module"` → `"Old structure was hard to extend / had duplication / mixed concerns"`)
  - Only omit if the feature name and outcome give literally zero hint about the underlying need.

- **`notes`** — follow-ups, links to tickets/PRs, blockers, or "not done yet" items mentioned anywhere in the conversation. **Look for these signals**:
  - Phrases like "TODO", "pendiente", "queda por", "follow-up", "luego", "later"
  - Mentions of ticket IDs (Linear `ENG-123`, Jira `PROJ-456`, etc.) or PR numbers (`#42`)
  - Acknowledged limitations ("doesn't handle X yet", "X is still buggy")
  - Manual steps the user must do later ("don't forget to deploy", "needs migration")
  - Only omit if the conversation has zero forward-looking content.

- **`tags`** — 1-3 from `[bug, feature, refactor, docs, test, perf, chore, ux, infra]`. Pick at least one when the work clearly fits a category. Omit only if the work spans many categories ambiguously.

**Don't invent content** — if you genuinely can't derive `problem` from the conversation+feature name+outcome, leave it out. The point is to be aggressive about deriving from REAL signals, not to fabricate.

Examples:

Rich context → all fields:
```json
{
  "outcome": "Added retry logic with exponential backoff for OAuth 401s.",
  "problem": "Users were being logged out when tokens expired because the OAuth client wasn't retrying.",
  "notes": "Refresh-token rotation still TODO. PR #456 merged. Linear: ENG-1234.",
  "tags": ["bug", "auth"]
}
```

Thin context → infer from name + outcome:
```json
{
  "outcome": "Refactored properties module to support nested fields.",
  "problem": "The flat schema couldn't represent computed values.",
  "tags": ["refactor"]
}
```
(`notes` omitted because no follow-ups were mentioned, but `problem` was inferred from the outcome describing a structural limitation.)

## Step 3: Run the close script with the JSON arg

```bash
bash "${CLAUDE_PLUGIN_ROOT}/bin/feature-done.sh" '<json>'
```

Use single quotes around the JSON to avoid shell expansion of `$` or `"`. Show only the script's output without extra commentary.
