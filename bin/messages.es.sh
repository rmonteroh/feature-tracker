#!/usr/bin/env bash
# Feature-tracker Spanish message catalog.
# Sourced by _lib.sh when FEATURE_TRACKER_LANG=es.
# Keep keys in sync with messages.en.sh.

# ── Action headers (full lines) ─────────────────────────────────
MSG_FEATURE_STARTED="✅ Feature iniciada"
MSG_FEATURE_PAUSED="⏸  Feature pausada"
MSG_FEATURE_RESUMED="▶️  Feature reanudada"
MSG_FEATURE_LOGGED="✅ Feature registrada"

# ── Errors and warnings ─────────────────────────────────────────
MSG_USAGE_START="Uso: feature-start <nombre de la feature>"
MSG_ALREADY_ACTIVE="⚠️  Ya hay una feature en progreso:"
MSG_ALREADY_ACTIVE_INLINE="⚠️  Ya hay una feature activa: %s"
MSG_NO_ACTIVE="❌ No hay feature en progreso."
MSG_NO_ACTIVE_TO_PAUSE="❌ No hay feature en progreso para pausar."
MSG_NO_PAUSED="❌ No hay features pausadas."
MSG_NO_PAUSED_PROJECT="❌ No hay paused features en este proyecto (%s)."
MSG_NO_MATCH="❌ Ninguna paused feature coincide con: %s"
MSG_MULTIPLE_MATCH="🔍 Hay %d features pausadas que coinciden. Especifica con: /feature-resume <texto>"
MSG_NO_FEATURES_LOGGED="📭 No hay features registradas todavía."
MSG_STATE_CORRUPT="⚠️  state file corrupto, removiéndolo"
MSG_DESCRIPTION_INVALID="❌ JSON de descripción sin el campo 'outcome' requerido"

# ── Hints (action-suggestion lines) ─────────────────────────────
MSG_CLOSE_OR_DISCARD="Cierra primero con /feature-done, o si quieres descartarla:"
MSG_PAUSE_OR_CLOSE_HINT="    Pausa o cierra primero: /feature-pause o /feature-done"
MSG_LIST_ALL_HINT="   Lista todas con: /feature-paused"
MSG_OR_SPECIFY_HINT="   O especifica una: /feature-resume <texto del nombre>"
MSG_RESUME_HINT="Reanudar con: /feature-resume"
MSG_START_HINT="   Inicia una con: /feature-start <nombre>"

# ── Labels (used as 'Label: value') ─────────────────────────────
LBL_NAME="Nombre"
LBL_PROJECT="Proyecto"
LBL_STARTED="Inicio"
LBL_STARTED_AT="Iniciada"
LBL_ENDED="Fin"
LBL_DURATION="Duración"
LBL_WORKED="Trabajado"
LBL_PAUSED_AT="Pausada"
LBL_PAUSED_FOR="Pausada por"
LBL_PAUSE_NUM="Pausa #"
LBL_PAUSES_TOTAL="Pausas total"
LBL_PAUSES="Pausas"
LBL_LOG="Log"
LBL_OUTCOME="Resultado"
LBL_PROBLEM="Problema"
LBL_NOTES="Notas"
LBL_TAGS="Tags"

# ── Suffixes / templates with interpolation ─────────────────────
MSG_THIS_PAUSE_SUFFIX="(esta pausa)"
MSG_PAUSES_SUFFIX_FMT="(%s en pausa, no contadas)"
MSG_AGO_FMT="hace %s"

# ── Stats sections ──────────────────────────────────────────────
MSG_STATS_HEADER="📊 Estadísticas de features"
SEC_BY_PROJECT="── Por proyecto ──────────────────────"
SEC_LAST_7_DAYS="── Últimos 7 días ────────────────────"
SEC_LAST_5_FEATURES="── Últimas 5 features ────────────────"
SEC_IN_PROGRESS="── En progreso ───────────────────────"
SEC_PAUSED="── En pausa ──────────────────────────"
MSG_TOTAL_LINE_FMT="Total: %d features  /  %s"
MSG_FEATURE_IN_PROGRESS_NOW="🔄 Hay una feature en progreso ahora mismo:"
MSG_PROJECT_STAT_LINE_FMT="    %s: %d features, %s"
MSG_DATE_STAT_LINE_FMT="    %s: %d features, %s"
MSG_RECENT_FEATURE_LINE_FMT="    [%s] %s · %s · %s"
MSG_PAUSED_BRIEF_FMT="    📌 [%s] %s  (pausada hace %s)"

# ── List-paused ─────────────────────────────────────────────────
MSG_LIST_PAUSED_HEADER="📋 Features pausadas"
SEC_CURRENT_PROJECT_FMT="── Proyecto actual (%s) ──────────────"
SEC_OTHER_PROJECTS="── Otros proyectos ───────────────────"
MSG_RESUME_LIST_ITEM_FMT="    - %s  (proyecto: %s, pausada: %s)"

# ── Auto-close / session hooks ──────────────────────────────────
MSG_AUTO_CLOSED_FMT="⏰ Auto-cerré la feature '%s' (abierta hace %dh)"
MSG_AUTO_CLOSED_PAUSED_FMT="⏰ Auto-cerrada paused feature '%s' (pausada hace %dh)"
MSG_PREV_SESSION_PAUSED_FMT="⏸  Feature de sesión anterior auto-pausada: '%s'"
MSG_AUTO_PAUSED_AT_END_FMT="⏸  Auto-pausada al cerrar sesión: %s"
MSG_GAP_NOTE_INFO="    Marcada con gap_detected: true (duración no confiable)"
MSG_AUTO_CLOSE_NOTE_FMT="Auto-cerrada al detectar gap de %dh sin actividad. Duración no confiable."
MSG_AUTO_CLOSE_PAUSED_NOTE_FMT="Paused feature auto-cerrada: pausada hace %dh sin retomar."

# ── Session-start additionalContext (read by Claude) ────────────
MSG_SESSION_START_HEADER_FMT="📌 Hay %d feature(s) pausada(s) en el proyecto actual ('%s'):"
MSG_SESSION_START_ITEM_FMT="  - '%s' (trabajado %s, pausada hace %s)"
MSG_SESSION_START_FOOTER="Pregunta al usuario qué hacer con cada una: retomar (/feature-resume), cerrar (/feature-done después de retomar), o dejar pausada. Si hay solo una, sugiere /feature-resume directamente."

# ── Migration ───────────────────────────────────────────────────
MSG_MIGRATION_DONE_FMT="✅ Migración completa → %s"
