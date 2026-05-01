#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/_lib.sh"

MD_DIR="${FEATURE_TRACKER_MD_EXPORT_DIR:-}"

# ── Helpers ──────────────────────────────────────────────────

# slug: turn a feature name into a filesystem-safe lowercase slug.
# - ASCII-fold (drops accents/emoji)
# - lowercase
# - non-alphanumeric → -
# - collapse multiple -
# - trim leading/trailing -
# - max 60 chars
# - fallback "untitled" if empty
slug() {
    local s="$1"
    s=$(printf '%s' "$s" | iconv -f UTF-8 -t ASCII//TRANSLIT//IGNORE 2>/dev/null || printf '%s' "$s")
    # macOS BSD iconv inserts apostrophes/backticks for accented chars (á→'a).
    # Strip them so slugify doesn't turn them into extra dashes.
    s=$(printf '%s' "$s" | tr -d "'\`")
    s=$(printf '%s' "$s" | tr '[:upper:]' '[:lower:]')
    s=$(printf '%s' "$s" | tr -c 'a-z0-9' '-')
    s=$(printf '%s' "$s" | tr -s '-')
    s="${s#-}"
    s="${s%-}"
    s="${s:0:60}"
    s="${s%-}"
    if [[ -z "$s" ]]; then
        s="untitled"
    fi
    printf '%s' "$s"
}

# yaml_quote: escape a string for YAML double-quoted form.
yaml_quote() {
    local v="$1"
    v="${v//\\/\\\\}"   # escape backslashes first
    v="${v//\"/\\\"}"   # escape double quotes
    printf '"%s"' "$v"
}

# write_one: take a single JSON entry (string), write the corresponding .md file.
# Requires MD_DIR to be set + writable; caller is responsible for mkdir.
write_one() {
    local entry="$1"
    local date feature project duration_minutes duration_seconds pause_count
    local started_at ended_at desc_type
    local outcome problem notes tags_array

    date=$(jq -r '.date' <<<"$entry")
    feature=$(jq -r '.feature' <<<"$entry")
    project=$(jq -r '.project' <<<"$entry")
    duration_minutes=$(jq -r '.duration_minutes // 0' <<<"$entry")
    duration_seconds=$(jq -r '.duration_seconds // 0' <<<"$entry")
    pause_count=$(jq -r '.pause_count // 0' <<<"$entry")
    started_at=$(jq -r '.started_at' <<<"$entry")
    ended_at=$(jq -r '.ended_at' <<<"$entry")

    desc_type=$(jq -r '.description | type' <<<"$entry" 2>/dev/null || echo "null")

    case "$desc_type" in
        string)
            outcome=$(jq -r '.description' <<<"$entry")
            problem=""
            notes=""
            tags_array=""
            ;;
        object)
            outcome=$(jq -r '.description.outcome // empty' <<<"$entry")
            problem=$(jq -r '.description.problem // empty' <<<"$entry")
            notes=$(jq -r '.description.notes // empty' <<<"$entry")
            tags_array=$(jq -r '(.description.tags // []) | join(", ")' <<<"$entry")
            ;;
        *)
            outcome=""
            problem=""
            notes=""
            tags_array=""
            ;;
    esac

    local s
    s=$(slug "$feature")
    local filename="$MD_DIR/${date}-${s}.md"

    {
        echo "---"
        echo "date: $date"
        echo "project: $(yaml_quote "$project")"
        echo "feature: $(yaml_quote "$feature")"
        echo "duration_minutes: $duration_minutes"
        echo "duration_seconds: $duration_seconds"
        echo "pause_count: $pause_count"
        echo "started_at: $started_at"
        echo "ended_at: $ended_at"
        if [[ -n "$tags_array" ]]; then
            echo "tags: [$tags_array]"
        fi
        echo "---"
        echo ""
        echo "# $feature"
        echo ""
        if [[ -n "$outcome" ]]; then
            echo "## $LBL_OUTCOME"
            echo ""
            echo "$outcome"
            echo ""
        fi
        if [[ -n "$problem" ]]; then
            echo "## $LBL_PROBLEM"
            echo ""
            echo "$problem"
            echo ""
        fi
        if [[ -n "$notes" ]]; then
            echo "## $LBL_NOTES"
            echo ""
            echo "$notes"
            echo ""
        fi
    } > "$filename"
}

# ── Main ─────────────────────────────────────────────────────

# Single-entry mode: pass JSON entry as $1
if [[ $# -ge 1 && -n "$1" ]]; then
    if [[ -z "$MD_DIR" ]]; then
        exit 0  # silently disabled
    fi
    mkdir -p "$MD_DIR"
    write_one "$1"
    exit 0
fi

# Bulk mode: regenerate all from the log
if [[ -z "$MD_DIR" ]]; then
    echo "$MSG_EXPORT_NO_DIR_SET" >&2
    exit 1
fi

if [[ ! -f "$LOG_FILE" || ! -s "$LOG_FILE" ]]; then
    echo "$MSG_EXPORT_NO_LOG"
    exit 0
fi

mkdir -p "$MD_DIR"

count=0
while IFS= read -r entry; do
    [[ -n "$entry" ]] || continue
    write_one "$entry"
    count=$((count + 1))
done < "$LOG_FILE"

printf "$MSG_EXPORT_DONE_FMT\n" "$count" "$MD_DIR"
