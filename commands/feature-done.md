---
description: Close the in-progress feature, compute its duration, and append it to the log
allowed-tools: Bash
---

The user wants to close the active feature. Before running the close script, generate a description from the recent conversation.

## Step 1: Check description mode

```bash
echo "${FEATURE_TRACKER_DESCRIPTION_MODE:-simple}"
```

This prints `simple` (default) or `structured`. Use it to decide what JSON shape to build below.

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

Build JSON with `outcome` (required) plus any of these you can fill from the conversation. Omit any field you can't fill confidently:

- `problem` — 1 sentence: what was wrong or needed (omit if unclear)
- `notes` — TODOs, blockers, links to tickets/PRs (omit if none)
- `tags` — 1-3 from `[bug, feature, refactor, docs, test, perf, chore, ux, infra]` (omit if unsure)

Example:
```json
{
  "outcome": "Added retry logic with exponential backoff for OAuth 401s.",
  "problem": "Users were being logged out when tokens expired.",
  "tags": ["bug", "auth"]
}
```

## Step 3: Run the close script with the JSON arg

```bash
bash "${CLAUDE_PLUGIN_ROOT}/bin/feature-done.sh" '<json>'
```

Use single quotes around the JSON to avoid shell expansion of `$` or `"`. Show only the script's output without extra commentary.
