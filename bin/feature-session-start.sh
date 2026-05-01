#!/usr/bin/env bash
# SessionStart hook:
#   1. Convert orphan active feature → paused (in case SessionEnd didn't fire)
#   2. Auto-close paused features older than threshold (default FEATURE_TRACKER_PAUSED_HOURS)
#   3. If paused features exist for current project, inject context for Claude
#      to ask the user what to do.
#
# Output format:
#   - JSON if anything to communicate (systemMessage + hookSpecificOutput.additionalContext)
#   - Empty otherwise
set -euo pipefail
source "$(dirname "$0")/_lib.sh"

# Threshold: explicit arg wins, else FEATURE_TRACKER_PAUSED_HOURS env (set by _lib.sh).
THRESHOLD_SEC="${1:-$((FEATURE_TRACKER_PAUSED_HOURS * 3600))}"

NOW=$(date +%s)
TODAY="$(today_date)"

SYSTEM_MESSAGES=()

# ── Step 1: orphan active → paused ────────────────────────────────
if [[ -f "$STATE_FILE" ]]; then
    NAME=$(jq -r '.name // "(unnamed)"' "$STATE_FILE" 2>/dev/null)
    if bash "$(dirname "$0")/feature-pause.sh" >/dev/null 2>&1; then
        SYSTEM_MESSAGES+=("$(printf "$MSG_PREV_SESSION_PAUSED_FMT" "$NAME")")
    fi
fi

# ── Step 2: auto-close paused features older than threshold ───────
for f in "$PAUSED_DIR"/*.json; do
    [[ -f "$f" ]] || continue
    paused_epoch=$(jq -r '.paused_at_epoch // empty' "$f" 2>/dev/null) || continue
    [[ -z "$paused_epoch" ]] && continue
    gap=$((NOW - paused_epoch))
    if (( gap > THRESHOLD_SEC )); then
        name=$(jq -r '.name' "$f")
        started_at=$(jq -r '.started_at' "$f")
        started_epoch=$(jq -r '.started_at_epoch' "$f")
        paused_at=$(jq -r '.paused_at' "$f")
        accum=$(jq -r '.accumulated_paused_seconds // 0' "$f")
        project=$(jq -r '.project' "$f")
        cwd=$(jq -r '.cwd' "$f")
        active_seconds=$((paused_epoch - started_epoch - accum))
        if (( active_seconds < 0 )); then active_seconds=0; fi
        gap_hours=$((gap / 3600))

        NOTE="$(printf "$MSG_AUTO_CLOSE_PAUSED_NOTE_FMT" "$gap_hours")"

        jq -nc \
            --arg date "$TODAY" \
            --arg started_at "$started_at" \
            --arg ended_at "$paused_at" \
            --argjson duration_minutes $((active_seconds / 60)) \
            --argjson duration_seconds "$active_seconds" \
            --arg project "$project" \
            --arg feature "$name" \
            --arg cwd "$cwd" \
            --argjson gap_hours "$gap_hours" \
            --arg note "$NOTE" \
            '{
                date: $date,
                started_at: $started_at,
                ended_at: $ended_at,
                duration_minutes: $duration_minutes,
                duration_seconds: $duration_seconds,
                project: $project,
                feature: $feature,
                cwd: $cwd,
                auto_closed: true,
                gap_detected: true,
                gap_hours: $gap_hours,
                note: $note
            }' >> "$LOG_FILE"

        rm "$f"
        SYSTEM_MESSAGES+=("$(printf "$MSG_AUTO_CLOSED_PAUSED_FMT" "$name" "$gap_hours")")
    fi
done

# ── Step 3: detect paused for current project, build context ───────
CURRENT_PROJECT="$(get_project)"
MATCHES=()
for f in "$PAUSED_DIR"/*.json; do
    [[ -f "$f" ]] || continue
    p=$(jq -r '.project // empty' "$f")
    if [[ "$p" == "$CURRENT_PROJECT" ]]; then
        MATCHES+=("$f")
    fi
done

ADDITIONAL_CONTEXT=""
if [[ ${#MATCHES[@]} -gt 0 ]]; then
    ADDITIONAL_CONTEXT="$(printf "$MSG_SESSION_START_HEADER_FMT" "${#MATCHES[@]}" "$CURRENT_PROJECT")"$'\n'
    for f in "${MATCHES[@]}"; do
        name=$(jq -r '.name' "$f")
        paused_epoch=$(jq -r '.paused_at_epoch' "$f")
        started_epoch=$(jq -r '.started_at_epoch' "$f")
        accum=$(jq -r '.accumulated_paused_seconds // 0' "$f")
        active_so_far=$((paused_epoch - started_epoch - accum))
        if (( active_so_far < 0 )); then active_so_far=0; fi
        in_pause=$((NOW - paused_epoch))
        ITEM="$(printf "$MSG_SESSION_START_ITEM_FMT" "$name" "$(fmt_dur "$active_so_far")" "$(fmt_dur "$in_pause")")"
        ADDITIONAL_CONTEXT+="$ITEM"$'\n'
    done
    ADDITIONAL_CONTEXT+=$'\n'
    ADDITIONAL_CONTEXT+="$MSG_SESSION_START_FOOTER"
fi

# ── Output JSON if anything to communicate ────────────────────────
if [[ ${#SYSTEM_MESSAGES[@]} -eq 0 ]] && [[ -z "$ADDITIONAL_CONTEXT" ]]; then
    exit 0
fi

SYSTEM_MESSAGE_STR=""
if [[ ${#SYSTEM_MESSAGES[@]} -gt 0 ]]; then
    SYSTEM_MESSAGE_STR=$(printf '%s\n' "${SYSTEM_MESSAGES[@]}")
fi

jq -n \
    --arg system_msg "$SYSTEM_MESSAGE_STR" \
    --arg add_ctx "$ADDITIONAL_CONTEXT" \
    '{
        systemMessage: (if $system_msg == "" then null else $system_msg end),
        hookSpecificOutput: (if $add_ctx == "" then null else {hookEventName: "SessionStart", additionalContext: $add_ctx} end)
    } | with_entries(select(.value != null))'
