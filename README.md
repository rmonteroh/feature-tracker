# feature-tracker

Time tracking for development features with pause/resume support, bilingual (en/es) outputs, and automatic session-aware state recovery — for [Claude Code](https://claude.com/claude-code).

## What it does

`feature-tracker` records how long you spend on each named feature in your projects. Start tracking explicitly via `/feature-start "fix login bug"`, or let the bundled auto-tracker skill detect intent in your messages. Pause when you switch contexts; resume next session. Stats by project, day, and feature.

Sample output:

```
✅ Feature logged
    Name:      fix login bug
    Project:   myproject
    Started:   2026-04-30T14:00:00-0500
    Ended:     2026-04-30T15:30:00-0500
    Duration:  1h 30m
    Pauses:    2  (5m paused, not counted)

    Log: /Users/you/.claude/feature-tracker/log.jsonl
```

## Install

In Claude Code:

```
/plugin marketplace add github.com/rmonteroh/feature-tracker
/plugin install feature-tracker@feature-tracker
```

## Configuration

All optional. Set in your shell rc (`~/.zshrc`, `~/.bashrc`, etc.) before launching Claude Code:

| Variable | Default | Description |
|---|---|---|
| `FEATURE_TRACKER_LANG` | `en` | Output language: `en` or `es` |
| `FEATURE_TRACKER_DATA_DIR` | `$HOME/.claude/feature-tracker` | Where logs and state files live |
| `FEATURE_TRACKER_ORPHAN_HOURS` | `6` | Auto-close active feature with no activity for this long |
| `FEATURE_TRACKER_PAUSED_HOURS` | `72` | Auto-close paused features not resumed within this window |

## Slash commands

| Command | What it does |
|---|---|
| `/feature-start <name>` | Begin tracking a new feature |
| `/feature-pause` | Pause the active feature (resume later) |
| `/feature-resume [name]` | Resume a paused feature (defaults to one in current project) |
| `/feature-done` | Close the active feature, append to log |
| `/feature-stats` | Show totals by project, day, and recent features |
| `/feature-paused` | List all paused features grouped by project |

## Auto-tracking

The bundled `feature-tracker` skill auto-detects intent in your messages. If you write something like "voy a arreglar el bug del login" or "let's implement the export feature", the skill calls `feature-start.sh` automatically and tells you it's tracking. Same for pause/resume/done. You can always cancel auto-tracking with "cancel" / "cancela".

## Data

Data lives in `$FEATURE_TRACKER_DATA_DIR` (default `~/.claude/feature-tracker/`):

- `log.jsonl` — one JSON object per closed feature
- `current.json` — currently-active feature (one at a time)
- `paused/paused_<epoch>.json` — paused features

Log entry shape:

```json
{
  "date": "2026-04-30",
  "started_at": "2026-04-30T14:00:00-0500",
  "ended_at": "2026-04-30T15:30:00-0500",
  "duration_seconds": 5400,
  "duration_minutes": 90,
  "pause_count": 2,
  "paused_seconds": 300,
  "project": "myproject",
  "feature": "fix login bug",
  "cwd": "/Users/you/code/myproject"
}
```

## Requirements

- bash 4+
- `jq` (`brew install jq` on macOS, `apt install jq` on Debian/Ubuntu)

## License

MIT — see [LICENSE](./LICENSE).
