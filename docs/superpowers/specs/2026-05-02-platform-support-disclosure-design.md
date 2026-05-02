# Platform Support Disclosure — Design

## Goal

Communicate clearly which platforms `feature-tracker` is known to work on, so a Windows user doesn't waste time debugging cryptic failures from a plugin that was never meant to run there.

## Non-goals

- Adding real Windows support
- Auditing or testing Linux portability — Linux is documented as "should work, untested"
- Hard-blocking execution on any platform other than where it actually breaks (Windows native shells)

## Scope

Three small changes:

1. README: a new "Supported platforms" section
2. `feature-doctor.sh`: a new `── Plataforma ──` / `── Platform ──` section that detects the host OS and reports it
3. `messages.en.sh` / `messages.es.sh`: bilingual strings for the new doctor section

## Behavior

### Doctor platform detection

Detection uses `$OSTYPE` first (set by bash on most systems), falling back to `uname -s`. The four cases:

| OSTYPE / uname           | Doctor output                                              | Severity |
|--------------------------|------------------------------------------------------------|----------|
| `darwin*`                | ✅ macOS (supported)                                        | ok       |
| `linux*` / `Linux`       | ⚠️ Linux (should work, untested — please file issues)       | warn     |
| `cygwin*` / `msys*` / `mingw*` | ❌ Windows native not supported — please use WSL      | error    |
| anything else            | ⚠️ Unknown platform: `<value>`                              | warn     |

The error case contributes to the doctor's exit code (non-zero), matching how missing `bash 4+` already does.

### README addition

Inside the existing "Requirements" section, add a "Supported platforms" subsection (or replace the platform-implicit `apt install jq` line) with:

```
- ✅ macOS — developed and tested here
- ⚠️ Linux — should work but untested; please file issues
- ❌ Windows native — not supported (use WSL)
```

The `jq` install hints stay but get reorganized so they don't imply Linux is officially supported.

### Bilingual strings

New keys in both `messages.en.sh` and `messages.es.sh`:

- `MSG_DOCTOR_PLATFORM_HEADER` — `── Platform ──` / `── Plataforma ──`
- `MSG_DOCTOR_PLATFORM_MACOS` — `macOS (supported)` / `macOS (soportado)`
- `MSG_DOCTOR_PLATFORM_LINUX` — `Linux (untested, may work — please file issues)` / `Linux (no probado, posiblemente funcione — por favor reporta issues)`
- `MSG_DOCTOR_PLATFORM_WINDOWS` — `Windows native not supported — please use WSL` / `Windows nativo no soportado — usá WSL`
- `MSG_DOCTOR_PLATFORM_UNKNOWN` — `Unknown platform: %s` / `Plataforma desconocida: %s`

## What we explicitly do NOT do

- We do NOT add platform guards to `feature-start.sh`, `feature-done.sh`, etc. Doctor + README is enough; per-script abort is friction without a meaningful safety win for the stated goal.
- We do NOT change `plugin.json`. Keywords/description don't drive Windows-user discovery enough to matter.
- We do NOT add Linux CI. That would imply we support Linux, which we don't yet claim.

## Files touched

- `README.md` — Requirements section
- `bin/feature-doctor.sh` — new detection block, calling new message keys
- `bin/messages.en.sh` — five new keys
- `bin/messages.es.sh` — five new keys

## Testing

Manual: run `feature-doctor.sh` on the dev machine (macOS) and confirm:
- New "Platform" section renders
- macOS branch shows ✅
- Existing exit-code behavior is preserved (no false errors)

Linux/Windows branches will be exercised by manual override (`OSTYPE=linux-gnu bash feature-doctor.sh`, `OSTYPE=msys bash feature-doctor.sh`) since we don't have CI on those platforms.
