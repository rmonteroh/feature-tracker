#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_lib.sh"

if [[ $# -lt 1 || -z "${1:-}" ]]; then
    echo "$MSG_USAGE_START"
    exit 1
fi

FEATURE_NAME="$*"

if [[ -f "$STATE_FILE" ]]; then
    EXISTING_NAME=$(jq -r '.name' "$STATE_FILE")
    EXISTING_START=$(jq -r '.started_at' "$STATE_FILE")
    echo "$MSG_ALREADY_ACTIVE"
    printf "    %s: %s\n" "$LBL_NAME" "$EXISTING_NAME"
    printf "    %s: %s\n" "$LBL_STARTED_AT" "$EXISTING_START"
    echo ""
    echo "$MSG_CLOSE_OR_DISCARD"
    echo "    rm $STATE_FILE"
    exit 1
fi

CWD="$(pwd)"
PROJECT="$(get_project)"
STARTED_AT="$(now_iso)"
STARTED_EPOCH="$(date +%s)"

jq -n \
    --arg name "$FEATURE_NAME" \
    --arg started_at "$STARTED_AT" \
    --argjson started_at_epoch "$STARTED_EPOCH" \
    --arg project "$PROJECT" \
    --arg cwd "$CWD" \
    '{name: $name, started_at: $started_at, started_at_epoch: $started_at_epoch, project: $project, cwd: $cwd}' \
    > "$STATE_FILE"

echo "$MSG_FEATURE_STARTED"
printf "    %-10s %s\n" "$LBL_NAME:" "$FEATURE_NAME"
printf "    %-10s %s\n" "$LBL_PROJECT:" "$PROJECT"
printf "    %-10s %s\n" "$LBL_STARTED:" "$STARTED_AT"
