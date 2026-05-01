#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_lib.sh"

if [[ ! -f "$STATE_FILE" ]]; then
    echo "$MSG_NO_ACTIVE"
    echo "$MSG_START_HINT"
    exit 1
fi

NAME=$(jq -r '.name' "$STATE_FILE")
STARTED_AT=$(jq -r '.started_at' "$STATE_FILE")
STARTED_EPOCH=$(jq -r '.started_at_epoch' "$STATE_FILE")
PROJECT=$(jq -r '.project' "$STATE_FILE")
CWD=$(jq -r '.cwd' "$STATE_FILE")
ACCUM_PAUSED=$(jq -r '.accumulated_paused_seconds // 0' "$STATE_FILE")
PAUSE_COUNT=$(jq -r '.pause_count // 0' "$STATE_FILE")

ENDED_AT="$(now_iso)"
ENDED_EPOCH="$(date +%s)"
ELAPSED_SECONDS=$((ENDED_EPOCH - STARTED_EPOCH))
DURATION_SECONDS=$((ELAPSED_SECONDS - ACCUM_PAUSED))
if (( DURATION_SECONDS < 0 )); then DURATION_SECONDS=0; fi
DURATION_MINUTES=$((DURATION_SECONDS / 60))
DATE="$(today_date)"

DURATION_HUMAN="$(fmt_dur "$DURATION_SECONDS")"

jq -nc \
    --arg date "$DATE" \
    --arg started_at "$STARTED_AT" \
    --arg ended_at "$ENDED_AT" \
    --argjson duration_minutes "$DURATION_MINUTES" \
    --argjson duration_seconds "$DURATION_SECONDS" \
    --argjson paused_seconds "$ACCUM_PAUSED" \
    --argjson pause_count "$PAUSE_COUNT" \
    --arg project "$PROJECT" \
    --arg feature "$NAME" \
    --arg cwd "$CWD" \
    '{
        date: $date,
        started_at: $started_at,
        ended_at: $ended_at,
        duration_minutes: $duration_minutes,
        duration_seconds: $duration_seconds,
        paused_seconds: $paused_seconds,
        pause_count: $pause_count,
        project: $project,
        feature: $feature,
        cwd: $cwd
    }' >> "$LOG_FILE"

rm "$STATE_FILE"

echo "$MSG_FEATURE_LOGGED"
printf "    %-10s %s\n" "$LBL_NAME:" "$NAME"
printf "    %-10s %s\n" "$LBL_PROJECT:" "$PROJECT"
printf "    %-10s %s\n" "$LBL_STARTED:" "$STARTED_AT"
printf "    %-10s %s\n" "$LBL_ENDED:" "$ENDED_AT"
printf "    %-10s %s\n" "$LBL_DURATION:" "$DURATION_HUMAN"
if (( PAUSE_COUNT > 0 )); then
    PAUSES_SUFFIX="$(printf "$MSG_PAUSES_SUFFIX_FMT" "$(fmt_dur "$ACCUM_PAUSED")")"
    printf "    %-10s %d  %s\n" "$LBL_PAUSES:" "$PAUSE_COUNT" "$PAUSES_SUFFIX"
fi
echo ""
printf "    %s: %s\n" "$LBL_LOG" "$LOG_FILE"
