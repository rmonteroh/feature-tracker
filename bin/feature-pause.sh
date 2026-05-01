#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_lib.sh"

if [[ ! -f "$STATE_FILE" ]]; then
    echo "$MSG_NO_ACTIVE_TO_PAUSE"
    exit 1
fi

NAME=$(jq -r '.name' "$STATE_FILE")
STARTED_AT=$(jq -r '.started_at' "$STATE_FILE")
STARTED_EPOCH=$(jq -r '.started_at_epoch' "$STATE_FILE")
PROJECT=$(jq -r '.project' "$STATE_FILE")
CWD=$(jq -r '.cwd' "$STATE_FILE")
ACCUM=$(jq -r '.accumulated_paused_seconds // 0' "$STATE_FILE")
PAUSE_COUNT=$(jq -r '.pause_count // 0' "$STATE_FILE")

PAUSED_AT="$(now_iso)"
PAUSED_EPOCH="$(date +%s)"
NEW_PAUSE_COUNT=$((PAUSE_COUNT + 1))

PAUSED_FILE="$PAUSED_DIR/paused_${STARTED_EPOCH}.json"

jq -n \
    --arg name "$NAME" \
    --arg started_at "$STARTED_AT" \
    --argjson started_at_epoch "$STARTED_EPOCH" \
    --arg paused_at "$PAUSED_AT" \
    --argjson paused_at_epoch "$PAUSED_EPOCH" \
    --argjson accumulated_paused_seconds "$ACCUM" \
    --argjson pause_count "$NEW_PAUSE_COUNT" \
    --arg project "$PROJECT" \
    --arg cwd "$CWD" \
    '{
        name: $name,
        started_at: $started_at,
        started_at_epoch: $started_at_epoch,
        paused_at: $paused_at,
        paused_at_epoch: $paused_at_epoch,
        accumulated_paused_seconds: $accumulated_paused_seconds,
        pause_count: $pause_count,
        project: $project,
        cwd: $cwd
    }' > "$PAUSED_FILE"

rm "$STATE_FILE"

ACTIVE_SECONDS=$((PAUSED_EPOCH - STARTED_EPOCH - ACCUM))

echo "$MSG_FEATURE_PAUSED"
printf "    %-12s %s\n" "$LBL_NAME:" "$NAME"
printf "    %-12s %s\n" "$LBL_PROJECT:" "$PROJECT"
printf "    %-12s %s\n" "$LBL_WORKED:" "$(fmt_dur "$ACTIVE_SECONDS")"
printf "    %-12s %d\n" "$LBL_PAUSE_NUM:" "$NEW_PAUSE_COUNT"
echo ""
echo "$MSG_RESUME_HINT"
