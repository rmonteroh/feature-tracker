# Platform Support Disclosure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Document supported platforms (macOS officially, Linux untested, Windows native unsupported) and surface a Platform check in `/feature-tracker:doctor` so Windows users get a clear error instead of cryptic failures.

**Architecture:** Three small additions — bilingual message keys, a new `── Platform ──` section in `feature-doctor.sh` that branches on `$OSTYPE` (with `uname -s` fallback), and a README "Supported platforms" subsection. No new files, no logic changes outside doctor, no per-script guards.

**Tech Stack:** bash (POSIX-portable flags only), the existing `messages.en.sh` / `messages.es.sh` catalog pattern, the existing `ok` / `warn` / `err` helpers in `feature-doctor.sh`.

**Testing note:** This project has no test framework — verification is done by running `feature-doctor.sh` with `OSTYPE` overrides and visually confirming the output. There is no separate test file to write.

**Spec:** `docs/superpowers/specs/2026-05-02-platform-support-disclosure-design.md`

---

## File Structure

| File | Change |
|---|---|
| `bin/messages.en.sh` | Add 5 keys: `LBL_DOCTOR_PLATFORM`, `MSG_DOCTOR_PLATFORM_MACOS`, `MSG_DOCTOR_PLATFORM_LINUX`, `MSG_DOCTOR_PLATFORM_WINDOWS`, `MSG_DOCTOR_PLATFORM_UNKNOWN_FMT` |
| `bin/messages.es.sh` | Same 5 keys, Spanish |
| `bin/feature-doctor.sh` | New `── Platform ──` section between `── Dependencies ──` and `── State ──`, using `$OSTYPE` |
| `README.md` | Replace single-line `bash 4+` requirements with subsections for Dependencies + Supported platforms |

---

### Task 1: Add bilingual message keys

**Files:**
- Modify: `bin/messages.en.sh:33` (after `LBL_DOCTOR_STATE`)
- Modify: `bin/messages.es.sh:34` (after `LBL_DOCTOR_STATE`)

- [ ] **Step 1: Add English keys**

In `bin/messages.en.sh`, immediately after the line `LBL_DOCTOR_STATE="State"` (line 34), add:

```bash
LBL_DOCTOR_PLATFORM="Platform"
MSG_DOCTOR_PLATFORM_MACOS="macOS (supported)"
MSG_DOCTOR_PLATFORM_LINUX="Linux (untested, may work — please file issues)"
MSG_DOCTOR_PLATFORM_WINDOWS="Windows native not supported — please use WSL"
MSG_DOCTOR_PLATFORM_UNKNOWN_FMT="Unknown platform: %s"
```

- [ ] **Step 2: Add Spanish keys**

In `bin/messages.es.sh`, immediately after the line `LBL_DOCTOR_STATE="Estado"` (line 34), add:

```bash
LBL_DOCTOR_PLATFORM="Plataforma"
MSG_DOCTOR_PLATFORM_MACOS="macOS (soportado)"
MSG_DOCTOR_PLATFORM_LINUX="Linux (no probado, posiblemente funcione — por favor reporta issues)"
MSG_DOCTOR_PLATFORM_WINDOWS="Windows nativo no soportado — usá WSL"
MSG_DOCTOR_PLATFORM_UNKNOWN_FMT="Plataforma desconocida: %s"
```

- [ ] **Step 3: Verify both files load without error**

Run:
```bash
bash -n bin/messages.en.sh && bash -n bin/messages.es.sh && echo OK
```

Expected: `OK` (no syntax errors).

- [ ] **Step 4: Commit**

```bash
git add bin/messages.en.sh bin/messages.es.sh
git commit -m "Add bilingual message keys for doctor platform check"
```

---

### Task 2: Add platform detection in feature-doctor.sh

**Files:**
- Modify: `bin/feature-doctor.sh` (insert new section between dependencies block ending at line 84 and state block starting at line 86)

- [ ] **Step 1: Insert platform detection block**

In `bin/feature-doctor.sh`, immediately after line 84 (the closing `fi` of the iconv check) and before line 86 (`# ─────── State ───`), insert:

```bash
# ─────────────────────────────────────── Platform ───
section "$LBL_DOCTOR_PLATFORM"

# Detect host OS. Prefer $OSTYPE (set by bash); fall back to `uname -s`.
platform_id="${OSTYPE:-$(uname -s 2>/dev/null | tr '[:upper:]' '[:lower:]')}"
case "$platform_id" in
    darwin*)
        ok "$MSG_DOCTOR_PLATFORM_MACOS"
        ;;
    linux*)
        warn "$MSG_DOCTOR_PLATFORM_LINUX"
        ;;
    cygwin*|msys*|mingw*|win32*)
        err "$MSG_DOCTOR_PLATFORM_WINDOWS"
        ;;
    *)
        # shellcheck disable=SC2059
        warn "$(printf "$MSG_DOCTOR_PLATFORM_UNKNOWN_FMT" "$platform_id")"
        ;;
esac

```

- [ ] **Step 2: Verify the script still parses**

Run:
```bash
bash -n bin/feature-doctor.sh && echo OK
```

Expected: `OK`.

- [ ] **Step 3: Run doctor on macOS (current host) and confirm new section appears**

Run:
```bash
bash bin/feature-doctor.sh
```

Expected output (relevant excerpt):
```
── Dependencies ──
✅ bash 5.x.x
✅ jq-1.x
✅ iconv

── Platform ──
✅ macOS (supported)

── State ──
...
```

Confirm:
- New `── Platform ──` (or `── Plataforma ──`) section appears between `── Dependencies ──` and `── State ──`
- macOS line shows `✅`
- Exit code is unchanged (still 0 on healthy state)

- [ ] **Step 4: Verify Linux branch via OSTYPE override**

Run:
```bash
OSTYPE=linux-gnu bash bin/feature-doctor.sh | grep -A1 'Platform\|Plataforma'
```

Expected: a `⚠️` line with the Linux message.

- [ ] **Step 5: Verify Windows branch via OSTYPE override**

Run:
```bash
OSTYPE=msys bash bin/feature-doctor.sh; echo "exit=$?"
```

Expected:
- A `❌` line with the Windows message
- `exit=1` (because the err count is now ≥1)

- [ ] **Step 6: Verify Unknown branch**

Run:
```bash
OSTYPE=plan9 bash bin/feature-doctor.sh | grep -A1 'Platform\|Plataforma'
```

Expected: a `⚠️` line containing `plan9` formatted into the unknown-platform message.

- [ ] **Step 7: Commit**

```bash
git add bin/feature-doctor.sh
git commit -m "Add platform detection to feature-tracker doctor"
```

---

### Task 3: Update README with Supported platforms section

**Files:**
- Modify: `README.md:150-153` (the existing `## Requirements` section)

- [ ] **Step 1: Replace the Requirements section**

Find this block in `README.md` (lines 150–153):

```markdown
## Requirements

- bash 4+
- `jq` (`brew install jq` on macOS, `apt install jq` on Debian/Ubuntu)
```

Replace it with:

```markdown
## Requirements

### Supported platforms

- ✅ **macOS** — developed and tested here
- ⚠️ **Linux** — should work but untested; please file issues
- ❌ **Windows native** — not supported; use [WSL](https://learn.microsoft.com/en-us/windows/wsl/)

`/feature-tracker:doctor` reports the detected platform and will surface an error on Windows-native shells (Cygwin/MSYS/MINGW).

### Dependencies

- bash 4+
- `jq` — `brew install jq` (macOS), `apt install jq` (Linux)
- `iconv` (used for slug generation; ships with macOS and most Linux distros)
```

- [ ] **Step 2: Spot-check the README renders**

Run:
```bash
grep -n 'Supported platforms\|Dependencies\|bash 4+' README.md
```

Expected: lines for the new headers + the bash 4+ line still present, in order.

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "Document supported platforms in README"
```

---

### Task 4: End-to-end verification

- [ ] **Step 1: Run the installed plugin's doctor command**

Note: the installed plugin uses a cached copy at `~/.claude/plugins/cache/feature-tracker/feature-tracker/1.4.0/bin/feature-doctor.sh`, NOT the repo files. To verify against the repo's bin scripts:

```bash
bash /Users/rmonteroh/Programation/claude-plugins/feature-tracker/bin/feature-doctor.sh
```

Expected: full doctor output with the new Platform section showing `✅ macOS (soportado)` (since `FEATURE_TRACKER_LANG=es` per the user's env).

- [ ] **Step 2: Confirm exit code unchanged on healthy state**

Run:
```bash
bash /Users/rmonteroh/Programation/claude-plugins/feature-tracker/bin/feature-doctor.sh; echo "exit=$?"
```

Expected: `exit=0` (no errors introduced for the user's actual platform).

- [ ] **Step 3: Confirm clean git tree**

Run:
```bash
git status
```

Expected: working tree clean (everything committed in tasks 1–3).

- [ ] **Step 4: Skim the three commits**

Run:
```bash
git log --oneline -3
```

Expected: three commits in order — message keys, doctor detection, README.

---

## Self-Review Notes

- ✅ Spec coverage: README change → Task 3, doctor change → Task 2, message keys → Task 1, manual test plan → Task 2 steps 3–6 + Task 4.
- ✅ No placeholders: every step has the actual code/commands.
- ✅ Type/key consistency: all 5 message keys are introduced in Task 1 and consumed in Task 2 with identical names. Format-string key uses the `_FMT` suffix per existing convention (matches `MSG_DOCTOR_WARN_FMT` etc.).
- ✅ Scope: single subsystem, single coherent change.
