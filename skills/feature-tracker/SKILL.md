---
name: feature-tracker
description: Auto-tracks feature work timing with pause/resume support. Triggers when user expresses clear intent to START concrete work on a named deliverable ("voy a arreglar X", "vamos a implementar Y", "necesito agregar Z", "let's implement Z", "I'm going to fix Y"), SIGNAL COMPLETION ("listo", "termine", "ya quedó", "funciona", "done", "finished", "it works"), PIVOT to a different feature, PAUSE work ("pausa esto", "déjalo para mañana", "lo dejo aquí por ahora", "pause this", "let's stop here for now"), or RESUME paused work ("retoma lo de X", "sigamos con Y", "reanuda", "resume X", "let's continue with Y"). Runs feature-start.sh, feature-pause.sh, feature-resume.sh, and feature-done.sh automatically without requiring slash command invocation.
---

# Feature Tracker (auto)

Automatic time tracking for features with pause/resume support. Bilingual (English / Spanish triggers).

## Files & paths

The data dir is `${FEATURE_TRACKER_DATA_DIR:-$HOME/.claude/feature-tracker}/`. Inside it:

- **Active state**: `current.json` (one feature at a time)
- **Paused dir**: `paused/paused_<epoch>.json` (multiple paused features)
- **Log**: `log.jsonl`

## Companion slash commands

`/feature-start <name>`, `/feature-pause`, `/feature-resume [name]`, `/feature-done`, `/feature-stats`, `/feature-paused`. If the user invokes any of these manually, this skill stays out of the way.

## Operating principles

- **Strict triggers, not loose.** If in doubt, don't trigger. False positives pollute the log.
- **Always announce.** Every auto-action must be visible in the response so the user can override.
- **Coexist with manual commands.** If the user types a `/feature-*` slash command, do nothing here.
- **One active at a time.** Always check state before starting/resuming.
- **Pause is the default for "I'm stopping for now"**, not done. Done means "this work is finished".

## Always check state first

Before deciding any action, run:

```bash
cat "${FEATURE_TRACKER_DATA_DIR:-$HOME/.claude/feature-tracker}/current.json" 2>/dev/null
ls "${FEATURE_TRACKER_DATA_DIR:-$HOME/.claude/feature-tracker}/paused/" 2>/dev/null
```

This tells you what's active and what's paused.

---

## START tracking (strict)

Run `bash "${CLAUDE_PLUGIN_ROOT}/bin/feature-start.sh" "<feature name>"` ONLY when ALL of:

1. **No feature currently active.** If there is one and the user is clearly pivoting, run pause or done on the current first.

2. **User uses an action-intent phrase**:
   - **Spanish:** "voy a [hacer/implementar/arreglar/agregar/crear/refactorizar/construir]", "vamos a [verb]", "hagamos [X]", "trabajemos en [X]", "necesito [implementar/arreglar/agregar]", "tengo que [hacer/implementar/arreglar]"
   - **English:** "let's [implement/build/fix/add]", "I'm going to [verb]", "I need to [implement/fix/add]", "going to work on [X]"

3. **The work has a concrete deliverable noun** (not vague things like "code", "stuff").

### Don't trigger on

- Questions ("¿cómo se haría X?" / "how would X work?")
- Explorations ("estoy pensando en X" / "I'm thinking about X")
- Design discussions without commitment
- Confirmations ("sí hazlo así" / "yes do it that way")
- Code review or analysis

### Feature name derivation

Extract a concise (3-7 words) name in the user's language. Strip filler. Verb + concrete noun.

| Input | Name |
|-------|------|
| "voy a arreglar el bug del login con OAuth" | `arreglar bug login OAuth` |
| "vamos a implementar el checkout con Stripe" | `checkout con Stripe` |
| "let's refactor the auth middleware" | `refactor auth middleware` |
| "I need to build the export-to-CSV feature" | `build export to CSV` |

### Announce on START

Append to your response a one-liner in the **user's language**:

- **English:** `📝 Tracking started: <name>  ·  say "cancel" if not a feature`
- **Spanish:** `📝 Tracking iniciado: <name>  ·  di "cancela" si no era feature`

Match the language of the user's most recent message.

If the user replies "cancel" / "cancela" / "no era feature" / "discard" / "descarta" next:

```bash
rm -f "${FEATURE_TRACKER_DATA_DIR:-$HOME/.claude/feature-tracker}/current.json"
```

Acknowledge in user's language: `🗑️ Tracking discarded` / `🗑️ Tracking descartado`.

---

## PAUSE tracking (strict)

Run `bash "${CLAUDE_PLUGIN_ROOT}/bin/feature-pause.sh"` when the user signals **temporary stop** with intent to resume:

- **Spanish:** "pausa esto", "pausa la feature", "pausémosla", "déjalo para mañana", "lo dejo para luego", "lo retomo después", "voy a salir un rato y luego sigo"
- **English:** "pause this", "let's pause", "leave it for tomorrow", "I'll come back to this", "stop for now but I'll resume"

### Don't pause on

- Done signals ("listo", "termine", "done", "finished") — those are CLOSE, not pause
- Quick affirmations during work
- Confusion (clarify first if user means pause vs done)

### Announce on PAUSE

Read the script's output and append a one-liner in the user's language:

- **English:** `⏸  Paused: <name>  ·  worked <duration>`
- **Spanish:** `⏸  Pausada: <name>  ·  trabajado <duration>`

---

## RESUME tracking (strict)

Run `bash "${CLAUDE_PLUGIN_ROOT}/bin/feature-resume.sh"` (with optional name arg) when the user signals returning to a paused feature:

- **Spanish:** "retoma lo de X", "sigamos con X", "reanudemos"
- **English:** "resume the X feature", "let's continue with X", "pick up where we left off"
- After session start, when SessionStart hook injected context about paused features, and the user says "sí retomemos" / "yes resume" / "la primera" / "the first one" etc.

### Two flavors

1. **Specific name mentioned** ("retoma lo del login OAuth" / "resume the login OAuth one") → run `feature-resume.sh "login OAuth"`
2. **Generic resume** ("reanudemos" / "let's resume") → run `feature-resume.sh` (no args; resumes if 1 paused in current project, else asks for disambiguation)

### Announce on RESUME

- **English:** `▶️  Resumed: <name>  ·  total worked <duration>`
- **Spanish:** `▶️  Reanudada: <name>  ·  trabajado total <duration>`

---

## CLOSE tracking (strict)

Before running the close script, generate a description from the conversation. Read `${FEATURE_TRACKER_DESCRIPTION_MODE:-simple}` and follow the rules in `commands/feature-done.md` (or recap below):

- **`outcome` (required, both modes)**: 1-2 sentences in past tense, user's language, what got DONE. Fallback: `"Worked on: <feature name>"` if context is thin.
- **`structured` mode adds**: `problem`, `notes`, `tags` (each optional — omit if unclear).
- Build the JSON, then run: `bash "${CLAUDE_PLUGIN_ROOT}/bin/feature-done.sh" '<json>'`.

Trigger the close flow when ANY of:

1. **User explicitly signals completion**:
   - **Spanish:** "listo", "ya quedó", "ya está", "termine", "funciona", "perfecto, ya"
   - **English:** "done", "finished", "it works", "all good", "that's it", "wrapped up"

   **Context check:** closure phrases come after work appears complete. Mid-work "perfecto" / "perfect" is NOT closure.

2. **User pivots to a clearly different feature**: close current first, then evaluate if the new statement meets START criteria.

3. **User explicitly requests closure**: "cierra la feature" / "close it" / "stop tracking".

### Don't close on

- Mid-work checkpoints ("ahora hazlo así" / "now do it this way")
- Partial confirmations ("sí ese cambio se ve bien" / "yes that change looks good")
- Pause signals (those are PAUSE, not close)

### Announce on CLOSE

- **English:** `✅ Feature closed: <name>  ·  <duration>`
- **Spanish:** `✅ Feature cerrada: <name>  ·  <duration>`

---

## Pivot pattern (close + start)

When the user pivots to a new feature while one is active, in one turn:

1. Run `feature-done.sh` (or `feature-pause.sh` if pivot is temporary, "vamos con X mientras pienso esto" / "let's do X while I think about this")
2. Run `feature-start.sh "<new name>"`
3. Announce both, in user's language. English example:

```
✅ Feature closed: <old>  ·  <duration>
📝 Tracking started: <new>  ·  say "cancel" if not a feature
```

Spanish example:

```
✅ Feature cerrada: <old>  ·  <duration>
📝 Tracking iniciado: <new>  ·  di "cancela" si no era feature
```

---

## Don't interfere with manual commands

If the user types `/feature-start`, `/feature-pause`, `/feature-resume`, `/feature-done`, `/feature-stats`, or `/feature-paused`, those slash commands handle it. Don't auto-trigger on the same turn.

---

## SessionStart context handling

When you receive a SessionStart message in `additionalContext` mentioning paused features in the current project:

1. **Read it carefully** — it lists features with name, accumulated active time, and time-since-paused.
2. **Ask the user** what to do with each. Format suggestion (in user's language):

   English:
   > 📌 I see you had paused features in this project:
   >
   > - **<name>** (worked <accum>, paused <pause> ago)
   >
   > Want to resume with `/feature-resume`, close it, or leave it paused?

   Spanish:
   > 📌 Veo que tenías features pausadas en este proyecto:
   >
   > - **<name>** (trabajaste <accum>, en pausa hace <pause>)
   >
   > ¿Quieres retomarla con `/feature-resume`, cerrarla, o dejarla pausada?

3. If only one paused feature, propose `/feature-resume` directly as the obvious action.
4. If the user replies with intent ("sí retomemos" / "yes resume" / "ciérrala" / "close it"), invoke the appropriate script.

---

## Stale state handling

The SessionStart hook handles stale state automatically before you receive the conversation:
- Orphan active features → converted to paused
- Paused features older than `FEATURE_TRACKER_PAUSED_HOURS` (default 72h) → auto-closed with `gap_detected: true`

You don't need to handle this manually.

---

## Configuration

Users can customize via env vars in their shell rc:

- `FEATURE_TRACKER_LANG` — `en` (default) or `es` for script outputs
- `FEATURE_TRACKER_DATA_DIR` — default `$HOME/.claude/feature-tracker`
- `FEATURE_TRACKER_ORPHAN_HOURS` — default `6` (auto-close active if no activity for N hours)
- `FEATURE_TRACKER_PAUSED_HOURS` — default `72` (auto-close paused if not resumed for N hours)
- `FEATURE_TRACKER_MD_EXPORT_DIR` — optional; if set, each closed feature is also written as a `.md` file there (typically an Obsidian vault). Unset = disabled.
