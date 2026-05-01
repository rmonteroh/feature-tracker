#!/usr/bin/env bash
# Feature-tracker English message catalog.
# Sourced by _lib.sh when FEATURE_TRACKER_LANG=en (default).
# Keep keys in sync with messages.es.sh.

# ── Action headers (full lines) ─────────────────────────────────
MSG_FEATURE_STARTED="✅ Feature started"
MSG_FEATURE_PAUSED="⏸  Feature paused"
MSG_FEATURE_RESUMED="▶️  Feature resumed"
MSG_FEATURE_LOGGED="✅ Feature logged"

# ── Errors and warnings ─────────────────────────────────────────
MSG_USAGE_START="Usage: feature-start <feature name>"
MSG_ALREADY_ACTIVE="⚠️  A feature is already in progress:"
MSG_ALREADY_ACTIVE_INLINE="⚠️  A feature is already active: %s"
MSG_NO_ACTIVE="❌ No feature in progress."
MSG_NO_ACTIVE_TO_PAUSE="❌ No feature in progress to pause."
MSG_NO_PAUSED="❌ No paused features."
MSG_NO_PAUSED_PROJECT="❌ No paused features in this project (%s)."
MSG_NO_MATCH="❌ No paused feature matches: %s"
MSG_MULTIPLE_MATCH="🔍 %d paused features match. Specify with: /feature-resume <text>"
MSG_NO_FEATURES_LOGGED="📭 No features logged yet."
MSG_STATE_CORRUPT="⚠️  state file corrupt, removing"

# ── Hints (action-suggestion lines) ─────────────────────────────
MSG_CLOSE_OR_DISCARD="Close it first with /feature-done, or to discard:"
MSG_PAUSE_OR_CLOSE_HINT="    Pause or close it first: /feature-pause or /feature-done"
MSG_LIST_ALL_HINT="   List all with: /feature-paused"
MSG_OR_SPECIFY_HINT="   Or specify one: /feature-resume <name text>"
MSG_RESUME_HINT="Resume with: /feature-resume"
MSG_START_HINT="   Start one with: /feature-start <name>"

# ── Labels (used as 'Label: value') ─────────────────────────────
LBL_NAME="Name"
LBL_PROJECT="Project"
LBL_STARTED="Started"
LBL_STARTED_AT="Started at"
LBL_ENDED="Ended"
LBL_DURATION="Duration"
LBL_WORKED="Worked"
LBL_PAUSED_AT="Paused"
LBL_PAUSED_FOR="Paused for"
LBL_PAUSE_NUM="Pause #"
LBL_PAUSES_TOTAL="Total pauses"
LBL_PAUSES="Pauses"
LBL_LOG="Log"

# ── Suffixes / templates with interpolation ─────────────────────
MSG_THIS_PAUSE_SUFFIX="(this pause)"
MSG_PAUSES_SUFFIX_FMT="(%s paused, not counted)"
MSG_AGO_FMT="%s ago"

# ── Stats sections ──────────────────────────────────────────────
MSG_STATS_HEADER="📊 Feature stats"
SEC_BY_PROJECT="── By project ────────────────────────"
SEC_LAST_7_DAYS="── Last 7 days ───────────────────────"
SEC_LAST_5_FEATURES="── Last 5 features ───────────────────"
SEC_IN_PROGRESS="── In progress ───────────────────────"
SEC_PAUSED="── Paused ────────────────────────────"
MSG_TOTAL_LINE_FMT="Total: %d features  /  %s"
MSG_FEATURE_IN_PROGRESS_NOW="🔄 A feature is in progress right now:"
MSG_PROJECT_STAT_LINE_FMT="    %s: %d features, %s"
MSG_DATE_STAT_LINE_FMT="    %s: %d features, %s"
MSG_RECENT_FEATURE_LINE_FMT="    [%s] %s · %s · %s"
MSG_PAUSED_BRIEF_FMT="    📌 [%s] %s  (paused %s ago)"

# ── List-paused ─────────────────────────────────────────────────
MSG_LIST_PAUSED_HEADER="📋 Paused features"
SEC_CURRENT_PROJECT_FMT="── Current project (%s) ──────────────"
SEC_OTHER_PROJECTS="── Other projects ────────────────────"
MSG_RESUME_LIST_ITEM_FMT="    - %s  (project: %s, paused: %s)"

# ── Auto-close / session hooks ──────────────────────────────────
MSG_AUTO_CLOSED_FMT="⏰ Auto-closed feature '%s' (open for %dh)"
MSG_AUTO_CLOSED_PAUSED_FMT="⏰ Auto-closed paused feature '%s' (paused %dh ago)"
MSG_PREV_SESSION_PAUSED_FMT="⏸  Feature from previous session auto-paused: '%s'"
MSG_AUTO_PAUSED_AT_END_FMT="⏸  Auto-paused on session end: %s"
MSG_GAP_NOTE_INFO="    Marked with gap_detected: true (duration unreliable)"
MSG_AUTO_CLOSE_NOTE_FMT="Auto-closed on detecting gap of %dh without activity. Duration unreliable."
MSG_AUTO_CLOSE_PAUSED_NOTE_FMT="Paused feature auto-closed: paused %dh ago without resuming."

# ── Session-start additionalContext (read by Claude) ────────────
MSG_SESSION_START_HEADER_FMT="📌 There are %d paused feature(s) in the current project ('%s'):"
MSG_SESSION_START_ITEM_FMT="  - '%s' (worked %s, paused %s ago)"
MSG_SESSION_START_FOOTER="Ask the user what to do with each: resume (/feature-resume), close (/feature-done after resuming), or leave paused. If only one, suggest /feature-resume directly."

# ── Migration ───────────────────────────────────────────────────
MSG_MIGRATION_DONE_FMT="✅ Migration complete → %s"
