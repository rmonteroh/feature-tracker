#!/usr/bin/env bash
# Diagnostic command: checks env vars, dependencies, filesystem state, and
# plugin operational state. Prints a per-check status and summary. Exits 0
# if no errors (warnings allowed), 1 if any error.
set -uo pipefail
source "$(dirname "$0")/_lib.sh"

errors=0
warnings=0

ok()      { printf '%s\n' "✅ $*"; }
warn()    { printf '%s\n' "⚠️  $*"; warnings=$((warnings + 1)); }
err()     { printf '%s\n' "❌ $*"; errors=$((errors + 1)); }
info()    { printf '%s\n' "ℹ️  $*"; }
section() { printf '\n── %s ──\n' "$1"; }

echo "🩺 $MSG_DOCTOR_HEADER"

# ─────────────────────────────────────── Config ───
section "$LBL_DOCTOR_CONFIG"

# LANG
case "$FEATURE_TRACKER_LANG" in
    en|es) ok "FEATURE_TRACKER_LANG=$FEATURE_TRACKER_LANG" ;;
    *)     warn "FEATURE_TRACKER_LANG='$FEATURE_TRACKER_LANG' not in [en, es] — falls back to en" ;;
esac

# DATA_DIR
if [[ -d "$FEATURE_TRACKER_DATA_DIR" && -w "$FEATURE_TRACKER_DATA_DIR" ]]; then
    ok "FEATURE_TRACKER_DATA_DIR=$FEATURE_TRACKER_DATA_DIR (exists, writable)"
else
    err "FEATURE_TRACKER_DATA_DIR=$FEATURE_TRACKER_DATA_DIR (missing or not writable)"
fi

# DESCRIPTION_MODE
case "$FEATURE_TRACKER_DESCRIPTION_MODE" in
    simple|structured) ok "FEATURE_TRACKER_DESCRIPTION_MODE=$FEATURE_TRACKER_DESCRIPTION_MODE" ;;
    *)                 err "FEATURE_TRACKER_DESCRIPTION_MODE='$FEATURE_TRACKER_DESCRIPTION_MODE' not in [simple, structured]" ;;
esac

# Thresholds
if [[ "$FEATURE_TRACKER_ORPHAN_HOURS" =~ ^[0-9]+$ ]] && [[ "$FEATURE_TRACKER_PAUSED_HOURS" =~ ^[0-9]+$ ]]; then
    ok "Thresholds: orphan=${FEATURE_TRACKER_ORPHAN_HOURS}h, paused=${FEATURE_TRACKER_PAUSED_HOURS}h"
else
    err "Thresholds invalid: orphan='$FEATURE_TRACKER_ORPHAN_HOURS', paused='$FEATURE_TRACKER_PAUSED_HOURS' (must be integers)"
fi

# MD_EXPORT_DIR (optional)
md_dir="${FEATURE_TRACKER_MD_EXPORT_DIR:-}"
if [[ -z "$md_dir" ]]; then
    info "FEATURE_TRACKER_MD_EXPORT_DIR not set (MD export disabled — set in shell rc to enable)"
elif [[ -d "$md_dir" && -w "$md_dir" ]]; then
    ok "FEATURE_TRACKER_MD_EXPORT_DIR set (exists, writable)"
elif [[ -d "$md_dir" ]]; then
    err "FEATURE_TRACKER_MD_EXPORT_DIR exists but not writable: $md_dir"
else
    warn "FEATURE_TRACKER_MD_EXPORT_DIR set but path does not exist: $md_dir"
fi

# ─────────────────────────────────────── Dependencies ───
section "$LBL_DOCTOR_DEPS"

# bash
bash_version=$(bash --version | head -1 | grep -oE '[0-9]+(\.[0-9]+)+' | head -1)
bash_major=$(echo "$bash_version" | cut -d. -f1)
if [[ -n "$bash_major" && "$bash_major" -ge 4 ]]; then
    ok "bash $bash_version"
else
    err "bash $bash_version (need 4+)"
fi

# jq
if command -v jq >/dev/null 2>&1; then
    ok "$(jq --version 2>&1 | head -1)"
else
    err "jq not found in PATH (install: brew install jq / apt install jq)"
fi

# iconv
if command -v iconv >/dev/null 2>&1; then
    ok "iconv"
else
    err "iconv not found (needed for slug generation)"
fi

# ─────────────────────────────────────── State ───
section "$LBL_DOCTOR_STATE"

# Active feature
if [[ -f "$STATE_FILE" ]]; then
    name=$(jq -r '.name // "?"' "$STATE_FILE" 2>/dev/null)
    project=$(jq -r '.project // "?"' "$STATE_FILE" 2>/dev/null)
    started=$(jq -r '.started_at // "?"' "$STATE_FILE" 2>/dev/null)
    info "Active: \"$name\" ($project, started $started)"
else
    info "Active: none"
fi

# Paused
paused_count=0
if [[ -d "$PAUSED_DIR" ]]; then
    shopt -s nullglob
    paused_files=("$PAUSED_DIR"/*.json)
    paused_count=${#paused_files[@]}
    shopt -u nullglob
fi
info "Paused: $paused_count"

# Log
if [[ -f "$LOG_FILE" ]]; then
    log_count=$(wc -l < "$LOG_FILE" | tr -d ' ')
    info "Log: $log_count entries"
else
    info "Log: not yet created"
fi

# MD files
if [[ -n "$md_dir" && -d "$md_dir" ]]; then
    shopt -s nullglob
    md_files=("$md_dir"/*.md)
    md_count=${#md_files[@]}
    shopt -u nullglob
    info "MD files: $md_count exported"
fi

# ─────────────────────────────────────── Summary ───
echo ""
if [[ $errors -eq 0 && $warnings -eq 0 ]]; then
    echo "✅ $MSG_DOCTOR_ALL_OK"
elif [[ $errors -eq 0 ]]; then
    printf "⚠️  $MSG_DOCTOR_WARN_FMT\n" "$warnings"
else
    printf "❌ $MSG_DOCTOR_ERR_FMT\n" "$errors" "$warnings"
fi

[[ $errors -eq 0 ]] && exit 0 || exit 1
