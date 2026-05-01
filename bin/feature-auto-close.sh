#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_lib.sh"

# Threshold: explicit arg wins, else FEATURE_TRACKER_ORPHAN_HOURS env (set by _lib.sh).
GAP_THRESHOLD_SECONDS="${1:-$((FEATURE_TRACKER_ORPHAN_HOURS * 3600))}"

if [[ ! -f "$STATE_FILE" ]]; then
    exit 0  # nothing to close, silent
fi

STARTED_EPOCH=$(jq -r '.started_at_epoch' "$STATE_FILE" 2>/dev/null) || {
    echo "$MSG_STATE_CORRUPT"
    rm -f "$STATE_FILE"
    exit 0
}

NOW_EPOCH="$(date +%s)"
GAP_SECONDS=$((NOW_EPOCH - STARTED_EPOCH))

if (( GAP_SECONDS <= GAP_THRESHOLD_SECONDS )); then
    exit 0  # not stale, leave it alone
fi

NAME=$(jq -r '.name' "$STATE_FILE")
STARTED_AT=$(jq -r '.started_at' "$STATE_FILE")
PROJECT=$(jq -r '.project' "$STATE_FILE")
CWD=$(jq -r '.cwd' "$STATE_FILE")

ENDED_AT="$(now_iso)"
DURATION_MINUTES=$((GAP_SECONDS / 60))
GAP_HOURS=$((GAP_SECONDS / 3600))
DATE="$(today_date)"

NOTE="$(printf "$MSG_AUTO_CLOSE_NOTE_FMT" "$GAP_HOURS")"

jq -nc \
    --arg date "$DATE" \
    --arg started_at "$STARTED_AT" \
    --arg ended_at "$ENDED_AT" \
    --argjson duration_minutes "$DURATION_MINUTES" \
    --argjson duration_seconds "$GAP_SECONDS" \
    --arg project "$PROJECT" \
    --arg feature "$NAME" \
    --arg cwd "$CWD" \
    --argjson gap_hours "$GAP_HOURS" \
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
    }' \
    >> "$LOG_FILE"

rm "$STATE_FILE"

printf "$MSG_AUTO_CLOSED_FMT\n" "$NAME" "$GAP_HOURS"
printf "    %s: %s\n" "$LBL_PROJECT" "$PROJECT"
printf "    %s: %s\n" "$LBL_STARTED" "$STARTED_AT"
printf "    %s: %s\n" "$LBL_ENDED" "$ENDED_AT"
echo "$MSG_GAP_NOTE_INFO"
