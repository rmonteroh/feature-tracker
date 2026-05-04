#!/usr/bin/env bash
# Shared utilities and config for feature-tracker scripts.
# Source with: source "$(dirname "$0")/_lib.sh"

# ── Config defaults (no-op if already exported) ────────────────
: "${FEATURE_TRACKER_LANG:=en}"
: "${FEATURE_TRACKER_DATA_DIR:=$HOME/.claude/feature-tracker}"
: "${FEATURE_TRACKER_ORPHAN_HOURS:=6}"
: "${FEATURE_TRACKER_PAUSED_HOURS:=72}"
: "${FEATURE_TRACKER_DESCRIPTION_MODE:=structured}"

# FEATURE_TRACKER_MD_EXPORT_DIR (optional, unset = disabled): path where one .md
# file per closed feature is written. Typically inside an Obsidian vault.

# ── Derived paths ──────────────────────────────────────────────
STATE_FILE="$FEATURE_TRACKER_DATA_DIR/current.json"
PAUSED_DIR="$FEATURE_TRACKER_DATA_DIR/paused"
LOG_FILE="$FEATURE_TRACKER_DATA_DIR/log.jsonl"

# Ensure data dir structure exists
mkdir -p "$FEATURE_TRACKER_DATA_DIR" "$PAUSED_DIR"

# ── Load message catalog (fall back to English) ────────────────
__LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$__LIB_DIR/messages.${FEATURE_TRACKER_LANG}.sh" ]]; then
    # shellcheck disable=SC1090
    source "$__LIB_DIR/messages.${FEATURE_TRACKER_LANG}.sh"
else
    # shellcheck disable=SC1091
    source "$__LIB_DIR/messages.en.sh"
fi

# ── Helpers ────────────────────────────────────────────────────

# Format duration in seconds → human readable (e.g., "5m 30s", "2h 10m")
fmt_dur() {
    local s=$1
    if [ "$s" -lt 0 ]; then s=0; fi
    if [ "$s" -lt 60 ]; then
        echo "${s}s"
    elif [ "$s" -lt 3600 ]; then
        local m=$((s / 60))
        local r=$((s % 60))
        if [ "$r" -eq 0 ]; then
            echo "${m}m"
        else
            echo "${m}m ${r}s"
        fi
    else
        local h=$((s / 3600))
        local m=$(((s % 3600) / 60))
        echo "${h}h ${m}m"
    fi
}

# Current cwd's "project" name (basename)
get_project() {
    basename "$(pwd)"
}

# ISO timestamp now
now_iso() {
    date "+%Y-%m-%dT%H:%M:%S%z"
}

# Today's date YYYY-MM-DD
today_date() {
    date +%Y-%m-%d
}
