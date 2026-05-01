#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_lib.sh"

if [[ ! -d "$PAUSED_DIR" ]] || [[ -z "$(ls -A "$PAUSED_DIR" 2>/dev/null)" ]]; then
    # Use the "no features logged yet" emoji style; reuse MSG_NO_PAUSED but soften
    echo "📭 ${MSG_NO_PAUSED#❌ }"
    exit 0
fi

CURRENT_PROJECT="$(get_project)"
NOW=$(date +%s)

PROJECT_MATCHES=()
OTHERS=()
for f in "$PAUSED_DIR"/*.json; do
    [[ -f "$f" ]] || continue
    p=$(jq -r '.project // empty' "$f")
    if [[ "$p" == "$CURRENT_PROJECT" ]]; then
        PROJECT_MATCHES+=("$f")
    else
        OTHERS+=("$f")
    fi
done

print_one() {
    local f="$1"
    local name=$(jq -r '.name' "$f")
    local project=$(jq -r '.project' "$f")
    local started_at=$(jq -r '.started_at' "$f")
    local paused_epoch=$(jq -r '.paused_at_epoch' "$f")
    local started_epoch=$(jq -r '.started_at_epoch' "$f")
    local accum=$(jq -r '.accumulated_paused_seconds // 0' "$f")
    local pause_count=$(jq -r '.pause_count' "$f")

    local active_so_far=$((paused_epoch - started_epoch - accum))
    local in_pause=$((NOW - paused_epoch))
    local ago_str
    ago_str="$(printf "$MSG_AGO_FMT" "$(fmt_dur "$in_pause")")"

    echo "    📌 $name"
    printf "       %-13s %s\n" "$LBL_PROJECT:" "$project"
    printf "       %-13s %s\n" "$LBL_STARTED_AT:" "$started_at"
    printf "       %-13s %s\n" "$LBL_PAUSED_AT:" "$ago_str"
    printf "       %-13s %s  (%d)\n" "$LBL_WORKED:" "$(fmt_dur "$active_so_far")" "$pause_count"
    echo ""
}

echo "$MSG_LIST_PAUSED_HEADER"
echo "═══════════════════════════════════════"

if [[ ${#PROJECT_MATCHES[@]} -gt 0 ]]; then
    echo ""
    printf "$SEC_CURRENT_PROJECT_FMT\n" "$CURRENT_PROJECT"
    echo ""
    for f in "${PROJECT_MATCHES[@]}"; do
        print_one "$f"
    done
fi

if [[ ${#OTHERS[@]} -gt 0 ]]; then
    echo "$SEC_OTHER_PROJECTS"
    echo ""
    for f in "${OTHERS[@]}"; do
        print_one "$f"
    done
fi
