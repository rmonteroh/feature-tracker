#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_lib.sh"

# Optional first arg: JSON object with at least {"outcome": "<non-empty string>"}.
# In `simple` mode (default): only `outcome` is read; stored as plain string.
# In `structured` mode: full JSON object is stored as-is in the log entry.
DESCRIPTION_JSON="${1:-}"
DESCRIPTION_VALUE=""
DESCRIPTION_TYPE=""  # "string" | "object" | "" (none)

if [[ -n "$DESCRIPTION_JSON" ]]; then
    OUTCOME=$(jq -r '.outcome // empty' <<<"$DESCRIPTION_JSON" 2>/dev/null) || OUTCOME=""
    if [[ -z "$OUTCOME" ]]; then
        echo "$MSG_DESCRIPTION_INVALID" >&2
        exit 1
    fi
    if [[ "$FEATURE_TRACKER_DESCRIPTION_MODE" == "structured" ]]; then
        DESCRIPTION_VALUE="$DESCRIPTION_JSON"
        DESCRIPTION_TYPE="object"
    else
        DESCRIPTION_VALUE="$OUTCOME"
        DESCRIPTION_TYPE="string"
    fi
fi

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

# Build the log entry. The shape changes depending on whether a description
# was provided and which mode is active.
if [[ "$DESCRIPTION_TYPE" == "object" ]]; then
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
        --argjson description "$DESCRIPTION_VALUE" \
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
            cwd: $cwd,
            description: $description
        }' >> "$LOG_FILE"
elif [[ "$DESCRIPTION_TYPE" == "string" ]]; then
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
        --arg description "$DESCRIPTION_VALUE" \
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
            cwd: $cwd,
            description: $description
        }' >> "$LOG_FILE"
else
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
fi

# Trigger MD export for the just-written entry. Errors suppressed so JSONL
# remains the source of truth — manual /feature-tracker:feature-export-md
# can regenerate if this fails. Skips silently if MD_EXPORT_DIR is unset.
LATEST_ENTRY=$(tail -n 1 "$LOG_FILE")
bash "$(dirname "$0")/feature-export-md.sh" "$LATEST_ENTRY" 2>/dev/null || true

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

# Description output (only if a description was provided)
if [[ "$DESCRIPTION_TYPE" == "string" ]]; then
    printf "    %-10s %s\n" "$LBL_OUTCOME:" "$DESCRIPTION_VALUE"
elif [[ "$DESCRIPTION_TYPE" == "object" ]]; then
    OUTCOME_TXT=$(jq -r '.outcome' <<<"$DESCRIPTION_VALUE")
    PROBLEM_TXT=$(jq -r '.problem // empty' <<<"$DESCRIPTION_VALUE")
    NOTES_TXT=$(jq -r '.notes // empty' <<<"$DESCRIPTION_VALUE")
    TAGS_TXT=$(jq -r '(.tags // []) | if type == "array" then join(", ") else "" end' <<<"$DESCRIPTION_VALUE" 2>/dev/null || echo "")
    printf "    %-10s %s\n" "$LBL_OUTCOME:" "$OUTCOME_TXT"
    [[ -n "$PROBLEM_TXT" ]] && printf "    %-10s %s\n" "$LBL_PROBLEM:" "$PROBLEM_TXT"
    [[ -n "$NOTES_TXT" ]] && printf "    %-10s %s\n" "$LBL_NOTES:" "$NOTES_TXT"
    [[ -n "$TAGS_TXT" ]] && printf "    %-10s %s\n" "$LBL_TAGS:" "$TAGS_TXT"
fi
