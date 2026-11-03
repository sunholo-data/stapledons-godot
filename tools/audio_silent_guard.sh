#!/bin/sh
# Windowed tools stay silent (Mark, 2026-11-03: captures and goldens played the bridge's sound on the Studio
# speakers once ShipSound was wired in). Every godot invocation in the Makefile, mk/*.mk and tracked shell
# scripts that opens a window (no --headless) must carry the dummy audio driver ($(AUDIO_OFF) or
# --audio-driver Dummy), unless its target (or script) is in tools/audio-silent-allowlist.txt with a reason.
set -eu
list=tools/audio-silent-allowlist.txt
allowed=$(grep -v '^#' "$list" | grep -v '^[[:space:]]*$' | cut -f1)
fail=0
n=0
# AUDIO_GUARD_FILES overrides the list (make audio-silent-guard's negative control).
files=${AUDIO_GUARD_FILES:-"Makefile $(git ls-files 'mk/*.mk') $(git ls-files '*.sh')"}
for src in $files; do
  out=$(awk -v SRC="$src" '
    /^[A-Za-z0-9_.%\/-]+[ \t]*:([^=]|$)/ && !/^\t/ { split($0, a, ":"); t = a[1] }
    /^[ \t]*#/ { next }
    {
      line = $0
      if (SRC !~ /\.sh$/ && line !~ /^\t/) next # make files: recipe lines only (a target line or comment may mention godot)
      if (line ~ /(\$\((GODOT|GODOT_SIM)\)|"\$GODOT"|(^|[ \t;'\''])godot)[ \t]+(--|res:\/\/|demos\/|\$\(AUDIO_OFF\))/ && line !~ /--headless/) {
        tgt = (SRC ~ /\.sh$/) ? SRC : t
        if (line ~ /\$\(AUDIO_OFF\)|--audio-driver Dummy/) print "ok\t" tgt
        else print "bad\t" tgt "\t" NR
      }
    }' "$src")
  [ -z "$out" ] && continue
  while IFS="$(printf '\t')" read -r status tgt nr; do
    n=$((n + 1))
    [ "$status" = ok ] && continue
    if printf '%s\n' "$allowed" | grep -qx "$tgt"; then continue; fi
    echo "audio-silent-guard: $src:$nr ($tgt) opens a window with sound; add \$(AUDIO_OFF) (--audio-driver Dummy) or allowlist it in $list with a reason"
    fail=1
  done <<EOT
$out
EOT
done
[ -n "${AUDIO_GUARD_FILES:-}" ] || printf '%s\n' "$allowed" | while read -r tgt; do
  grep -q "^$tgt[ \t]*:" Makefile mk/*.mk 2>/dev/null || [ -f "$tgt" ] || { echo "audio-silent-guard: stale allowlist entry $tgt"; exit 1; }
done || fail=1
[ "$fail" = 0 ] && echo "audio-silent-guard: ok ($n windowed godot invocations; $(printf '%s\n' "$allowed" | wc -l | tr -d ' ') allowlisted to keep sound)"
exit "$fail"
