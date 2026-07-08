#!/usr/bin/env bash
# spec-archive-check.sh — lightweight validation for the SDD SPEC archival workflow.
#
# Checks:
#  1. specs/README.md exists and indexes every spec directory.
#  2. Every archived (completed) spec has completion.md.
#  3. Archived completed specs declare a **Completed** field.
#  4. Status values use the allowed vocabulary only.
#  5. Superseded specs declare **Superseded By**.
#  6. Archived tasks.md have no open checkbox items without a recorded disposition.
#  7. README status is consistent with directory location (active/archive/deprecated).
#
# Usage: .specify/scripts/bash/spec-archive-check.sh [specs-path]
# Exit: 0 if clean, 1 if any check fails.

set -u
ROOT="$(cd "$(dirname "$0")/../../../" 2>/dev/null && pwd)"
SPECS="${1:-$ROOT/specs}"
ALLOWED="draft active blocked completed deprecated superseded cancelled"
FAIL=0
err() { echo "✗ $*" >&2; FAIL=1; }
ok() { echo "✓ $*"; }

[ -f "$SPECS/README.md" ] || { err "specs/README.md missing"; exit 1; }
ok "specs/README.md present"

status_of() { # dir -> status value (lowercased)
  local f="$1/spec.md"
  [ -f "$f" ] || { echo ""; return; }
  grep -m1 -iE '^\*\*Status\*\*:' "$f" | sed -E 's/^\*\*Status\*\*:[[:space:]]*//I' | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]'
}

allowed_status() { local s="$1"; for a in $ALLOWED; do [ "$s" = "$a" ] && return 0; done; return 1; }

# Enumerate spec directories (active, archive/*, deprecated) and ensure each is in README.
count_indexed=0
while IFS= read -r d; do
  dn="$(basename "$d")"
  id="$(echo "$dn" | grep -oE '^[0-9]{3}')"
  [ -z "$id" ] && continue
  count_indexed=$((count_indexed+1))
  grep -q "$id" "$SPECS/README.md" || err "SPEC $id ($dn) not indexed in README.md"
  s="$(status_of "$d")"
  if [ -n "$s" ]; then
    allowed_status "$s" || err "SPEC $id: disallowed status '$s'"
  fi
  loc=""
  case "$d" in
    */active/*) loc=active;;
    */archive/*) loc=archive;;
    */deprecated/*) loc=deprecated;;
  esac
  if [ "$loc" = "archive" ]; then
    [ -f "$d/completion.md" ] || err "SPEC $id: archived spec missing completion.md"
    grep -qiE '^\*\*Completed\*\*:' "$d/spec.md" 2>/dev/null || \
      grep -qiE '^\*\*Status\*\*:[[:space:]]*(superseded|deprecated|cancelled)' "$d/spec.md" 2>/dev/null || \
      err "SPEC $id: archived completed spec missing **Completed** field"
    if echo "$s" | grep -qi 'superseded'; then
      grep -qiE '^\*\*Superseded By\*\*:' "$d/spec.md" 2>/dev/null || err "SPEC $id: superseded spec missing **Superseded By**"
    fi
    # open tasks need dispositions
    for tf in "$d/tasks.md" "$d/NextPaste_TASKS.md"; do
      [ -f "$tf" ] || continue
      before="$(awk '/^## Archive Dispositions/{exit} {print}' "$tf" | grep -cE '^[[:space:]]*- \[ \]')"
      if [ "$before" -gt 0 ]; then
        grep -q '^## Archive Dispositions' "$tf" || { err "SPEC $id: $tf has $before open item(s) without ## Archive Dispositions"; continue; }
        disp="$(awk '/^## Archive Dispositions/{f=1} f' "$tf" | grep -cE '^[[:space:]]*- Disposition:')"
        [ "$disp" -ge "$before" ] || err "SPEC $id: $tf has $before open item(s) but only $disp disposition(s)"
      fi
    done
  fi
  # README vs location consistency
  case "$loc" in
    active) echo "$s" | grep -qE '^(active|draft|blocked)$' || err "SPEC $id: active/ dir but status '$s'";;
    archive) echo "$s" | grep -qE '^(completed|deprecated|superseded|cancelled)$' || err "SPEC $id: archive/ dir but status '$s'";;
    deprecated) echo "$s" | grep -qE '^(deprecated|superseded|cancelled)$' || err "SPEC $id: deprecated/ dir but status '$s'";;
  esac
done < <(find "$SPECS" -mindepth 2 -maxdepth 3 -type d \( -path '*/active/*' -o -path '*/archive/*/*' -o -path '*/deprecated/*' \) 2>/dev/null | grep -E '/[0-9]{3}-')

ok "Indexed $count_indexed spec director(ies) against README.md"
[ "$FAIL" -eq 0 ] && { echo "spec-archive-check: PASS"; exit 0; }
echo "spec-archive-check: FAIL" >&2
exit 1