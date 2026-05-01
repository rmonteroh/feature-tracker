#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_lib.sh"

if [[ ! -f "$LOG_FILE" || ! -s "$LOG_FILE" ]]; then
    echo "$MSG_NO_FEATURES_LOGGED"
    if [[ -f "$STATE_FILE" ]]; then
        echo ""
        echo "$MSG_FEATURE_IN_PROGRESS_NOW"
        printf "    %-10s %s\n" "$LBL_NAME:" "$(jq -r '.name' "$STATE_FILE")"
        printf "    %-10s %s\n" "$LBL_PROJECT:" "$(jq -r '.project' "$STATE_FILE")"
        printf "    %-10s %s\n" "$LBL_STARTED:" "$(jq -r '.started_at' "$STATE_FILE")"
    fi
    exit 0
fi

TOTAL=$(wc -l < "$LOG_FILE" | tr -d ' ')
TOTAL_SEC=$(jq -s 'map(.duration_seconds // 0) | add' "$LOG_FILE")

echo "$MSG_STATS_HEADER"
echo "═══════════════════════════════════════"
echo ""
printf "$MSG_TOTAL_LINE_FMT\n" "$TOTAL" "$(fmt_dur "$TOTAL_SEC")"
echo ""
echo "$SEC_BY_PROJECT"
# jq emits "<project>|<count>|<seconds>" tuples; we format in bash for i18n control.
jq -s -r '
    group_by(.project)
    | map({project: .[0].project, count: length, total: (map(.duration_seconds // 0) | add)})
    | sort_by(-.total)[]
    | "\(.project)|\(.count)|\(.total)"
' "$LOG_FILE" | while IFS='|' read -r project count total; do
    printf "$MSG_PROJECT_STAT_LINE_FMT\n" "$project" "$count" "$(fmt_dur "$total")"
done

echo ""
echo "$SEC_LAST_7_DAYS"
jq -s -r '
    group_by(.date)
    | map({date: .[0].date, count: length, total: (map(.duration_seconds // 0) | add)})
    | sort_by(.date)
    | reverse
    | .[:7][]
    | "\(.date)|\(.count)|\(.total)"
' "$LOG_FILE" | while IFS='|' read -r date count total; do
    printf "$MSG_DATE_STAT_LINE_FMT\n" "$date" "$count" "$(fmt_dur "$total")"
done

echo ""
echo "$SEC_LAST_5_FEATURES"
jq -s -r '
    sort_by(.ended_at)
    | reverse
    | .[:5][]
    | "\(.date)|\(.project)|\(.feature)|\(.duration_seconds // 0)"
' "$LOG_FILE" | while IFS='|' read -r date project feature dur; do
    printf "$MSG_RECENT_FEATURE_LINE_FMT\n" "$date" "$project" "$feature" "$(fmt_dur "$dur")"
done

if [[ -f "$STATE_FILE" ]]; then
    echo ""
    echo "$SEC_IN_PROGRESS"
    printf "    %-10s %s\n" "$LBL_NAME:" "$(jq -r '.name' "$STATE_FILE")"
    printf "    %-10s %s\n" "$LBL_PROJECT:" "$(jq -r '.project' "$STATE_FILE")"
    printf "    %-10s %s\n" "$LBL_STARTED:" "$(jq -r '.started_at' "$STATE_FILE")"
fi

if [[ -d "$PAUSED_DIR" ]] && [[ -n "$(ls -A "$PAUSED_DIR" 2>/dev/null)" ]]; then
    NOW=$(date +%s)
    echo ""
    echo "$SEC_PAUSED"
    for f in "$PAUSED_DIR"/*.json; do
        [[ -f "$f" ]] || continue
        name=$(jq -r '.name' "$f")
        project=$(jq -r '.project' "$f")
        paused_epoch=$(jq -r '.paused_at_epoch' "$f")
        in_pause=$((NOW - paused_epoch))
        printf "$MSG_PAUSED_BRIEF_FMT\n" "$project" "$name" "$(fmt_dur "$in_pause")"
    done
fi
