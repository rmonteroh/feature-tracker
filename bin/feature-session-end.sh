#!/usr/bin/env bash
# SessionEnd hook: auto-pause active feature so it can be resumed next session.
set -euo pipefail
source "$(dirname "$0")/_lib.sh"

if [[ ! -f "$STATE_FILE" ]]; then
    exit 0
fi

NAME=$(jq -r '.name // "(unnamed)"' "$STATE_FILE" 2>/dev/null)

# Pause silently
bash "$(dirname "$0")/feature-pause.sh" >/dev/null 2>&1 || exit 0

printf "$MSG_AUTO_PAUSED_AT_END_FMT\n" "$NAME"
