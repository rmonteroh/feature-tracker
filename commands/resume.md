---
description: Resume a paused feature (defaults to one in the current project, or interactive selector if multiple)
argument-hint: [name text, optional]
allowed-tools: Bash, AskUserQuestion
---

The user wants to resume a paused feature. They wrote: $ARGUMENTS

## Step 1: If `$ARGUMENTS` is non-empty, run the script directly

When the user passed a name argument, the resume script handles single match / multi match / no match by itself. Run:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/bin/feature-resume.sh" "$ARGUMENTS"
```

Show only the script's output. Done.

## Step 2: If `$ARGUMENTS` is empty, list paused features first

```bash
bash "${CLAUDE_PLUGIN_ROOT}/bin/feature-list-paused.sh"
```

Read the output. Each paused feature begins with a line `    📌 <feature name>`, followed by indented lines with `Project:` / `Proyecto:`, `Started at:` / `Iniciada:`, `Paused:` / `Pausada:`, `Worked:` / `Trabajado:`. Sections are headed by `── Current project (...) ──` / `── Proyecto actual (...) ──` and `── Other projects ──` / `── Otros proyectos ──`.

Decide which path:

- **0 paused features** (output starts with `📭`) → show that line to the user, you're done.
- **Exactly 1 paused feature in the current-project section AND no other-projects section** → run `feature-resume.sh` with NO args. The script picks the single match.
  ```bash
  bash "${CLAUDE_PLUGIN_ROOT}/bin/feature-resume.sh"
  ```
- **Any other case** (multiple paused, or 1 in current + others elsewhere) → go to Step 3.

## Step 3: Interactive selector with `AskUserQuestion`

Use the `AskUserQuestion` tool. Hard constraints:

- **2-4 options max** (tool limit). If there are more than 4 paused features in total, prefer the current-project ones first; if still more than 4, pick the 4 most-recently-paused (smallest `paused <X> ago` value).
- The "Other" option is added automatically by the tool — don't include it yourself. If the user picks "Other", they'll type a substring; pass that to the resume script.

Build each option from a paused-feature entry:
- `label`: the feature name. Truncate to ≤ 5 words if longer (e.g., `"fix oauth login refresh bug"` → `"fix oauth login refresh"`).
- `description`: `"<project> · paused <duration>"` (use the same `<duration>` text the listing shows, e.g., `"2h"` or `"hace 2h"`).

Question / header (match user's most recent message language):
- **English**: `question="Which paused feature do you want to resume?"`, `header="Resume"`
- **Spanish**: `question="¿Qué feature pausada quieres reanudar?"`, `header="Reanudar"`

Use `multiSelect: false` (only one feature can be active at a time).

After the user selects, capture the chosen feature name (from the selected option's label, OR the user's free text if they picked "Other"). Run:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/bin/feature-resume.sh" "<chosen text>"
```

Show only the script's output.

## Edge case: more than 4 paused features

If the listing has > 4 entries and the chosen 4 don't include what the user wanted, after running the resume the user can always retry with `/feature-tracker:resume <name>` (Step 1 path) or `/feature-tracker:paused` to see the full list.
