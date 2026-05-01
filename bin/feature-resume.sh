#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_lib.sh"

# Reject if a feature is already active
if [[ -f "$STATE_FILE" ]]; then
    NAME=$(jq -r '.name' "$STATE_FILE")
    printf "$MSG_ALREADY_ACTIVE_INLINE\n" "$NAME"
    echo "$MSG_PAUSE_OR_CLOSE_HINT"
    exit 1
fi

# Empty paused dir
if [[ ! -d "$PAUSED_DIR" ]] || [[ -z "$(ls -A "$PAUSED_DIR" 2>/dev/null)" ]]; then
    echo "$MSG_NO_PAUSED"
    exit 1
fi

CURRENT_PROJECT="$(get_project)"
TARGET="${1:-}"

PROJECT_MATCHES=()
ALL=()
for f in "$PAUSED_DIR"/*.json; do
    [[ -f "$f" ]] || continue
    ALL+=("$f")
    p=$(jq -r '.project // empty' "$f" 2>/dev/null)
    if [[ "$p" == "$CURRENT_PROJECT" ]]; then
        PROJECT_MATCHES+=("$f")
    fi
done

if [[ -n "$TARGET" ]]; then
    SET=()
    for f in "${ALL[@]}"; do
        n=$(jq -r '.name' "$f")
        if [[ "${n,,}" == *"${TARGET,,}"* ]]; then
            SET+=("$f")
        fi
    done
    if [[ ${#SET[@]} -eq 0 ]]; then
        printf "$MSG_NO_MATCH\n" "$TARGET"
        echo "$MSG_LIST_ALL_HINT"
        exit 1
    fi
else
    if [[ ${#PROJECT_MATCHES[@]} -eq 0 ]]; then
        printf "$MSG_NO_PAUSED_PROJECT\n" "$CURRENT_PROJECT"
        echo "$MSG_LIST_ALL_HINT"
        echo "$MSG_OR_SPECIFY_HINT"
        exit 1
    fi
    SET=("${PROJECT_MATCHES[@]}")
fi

if [[ ${#SET[@]} -gt 1 ]]; then
    printf "$MSG_MULTIPLE_MATCH\n" "${#SET[@]}"
    echo ""
    for f in "${SET[@]}"; do
        n=$(jq -r '.name' "$f")
        p=$(jq -r '.project' "$f")
        pa=$(jq -r '.paused_at' "$f")
        printf "$MSG_RESUME_LIST_ITEM_FMT\n" "$n" "$p" "$pa"
    done
    exit 1
fi

PAUSED_FILE="${SET[0]}"

NAME=$(jq -r '.name' "$PAUSED_FILE")
STARTED_AT=$(jq -r '.started_at' "$PAUSED_FILE")
STARTED_EPOCH=$(jq -r '.started_at_epoch' "$PAUSED_FILE")
PAUSED_EPOCH=$(jq -r '.paused_at_epoch' "$PAUSED_FILE")
PRIOR_ACCUM=$(jq -r '.accumulated_paused_seconds // 0' "$PAUSED_FILE")
PAUSE_COUNT=$(jq -r '.pause_count' "$PAUSED_FILE")
PROJECT=$(jq -r '.project' "$PAUSED_FILE")
CWD=$(jq -r '.cwd' "$PAUSED_FILE")

NOW_EPOCH="$(date +%s)"
THIS_PAUSE=$((NOW_EPOCH - PAUSED_EPOCH))
NEW_ACCUM=$((PRIOR_ACCUM + THIS_PAUSE))
ACTIVE_SECONDS=$((NOW_EPOCH - STARTED_EPOCH - NEW_ACCUM))

jq -n \
    --arg name "$NAME" \
    --arg started_at "$STARTED_AT" \
    --argjson started_at_epoch "$STARTED_EPOCH" \
    --argjson accumulated_paused_seconds "$NEW_ACCUM" \
    --argjson pause_count "$PAUSE_COUNT" \
    --arg project "$PROJECT" \
    --arg cwd "$CWD" \
    '{
        name: $name,
        started_at: $started_at,
        started_at_epoch: $started_at_epoch,
        accumulated_paused_seconds: $accumulated_paused_seconds,
        pause_count: $pause_count,
        project: $project,
        cwd: $cwd
    }' > "$STATE_FILE"

rm "$PAUSED_FILE"

echo "$MSG_FEATURE_RESUMED"
printf "    %-15s %s\n" "$LBL_NAME:" "$NAME"
printf "    %-15s %s\n" "$LBL_PROJECT:" "$PROJECT"
printf "    %-15s %s\n" "$LBL_WORKED:" "$(fmt_dur "$ACTIVE_SECONDS")"
printf "    %-15s %s  %s\n" "$LBL_PAUSED_FOR:" "$(fmt_dur "$THIS_PAUSE")" "$MSG_THIS_PAUSE_SUFFIX"
printf "    %-15s %d\n" "$LBL_PAUSES_TOTAL:" "$PAUSE_COUNT"
