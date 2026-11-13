#!/bin/sh
# Build an actual minimal PCK from the staged production bundle, then run it from
# an empty project directory. A deliberately incomplete PCK must fail as well.
set -eu
GODOT=${GODOT:-godot}
SCRIPT_GATE=${SCRIPT_GATE:-tools/script_gate.sh}
SCRATCH=${SCRATCH:-.godot/tmp/observations/export-smoke}
mkdir -p "$SCRATCH"
SCRATCH=$(cd "$SCRATCH" && pwd)
run_gate() {
  name=$1; log=$2; limit=$3; summary=$4; shift 4
  if sh "$SCRIPT_GATE" "$name" "$log" "$limit" "$summary" -- "$@" > "$log.gate" 2>&1; then
    printf '%s: passed\n' "$name"
  else
    cat "$log.gate" >&2
    exit 1
  fi
}
run_gate telescope-offline-pack "$SCRATCH/pack.log" 120 '^telescope-offline-pack: [1-9][0-9]* files, 0 failures$' "$GODOT" --headless --path . --script tools/telescope_offline_probe.gd -- "--build=$SCRATCH/telescope.pck"
mkdir -p "$SCRATCH/empty"
run_gate telescope-offline-probe "$SCRATCH/probe.log" 180 '^telescope-offline-probe: [1-9][0-9]* tiles, 0 failures$' "$GODOT" --headless --path "$SCRATCH/empty" --main-pack "$SCRATCH/telescope.pck" --script res://tools/telescope_offline_probe.gd
run_gate telescope-offline-broken-pack "$SCRATCH/broken-pack.log" 120 '^telescope-offline-pack: [1-9][0-9]* files, 0 failures$' "$GODOT" --headless --path . --script tools/telescope_offline_probe.gd -- "--build=$SCRATCH/broken.pck" --omit=res://observation_bundle/manifest.json.bin
# Negative control proves that an existing source tree cannot hide a missing pack.
set +e
"$GODOT" --headless --path "$SCRATCH/empty" --main-pack "$SCRATCH/broken.pck" --script res://tools/telescope_offline_probe.gd > "$SCRATCH/broken.log" 2>&1
status=$?
set -e
if [ "$status" -eq 0 ] || ! grep -q '^FAIL offline telescope: missing res://observation_bundle/manifest.json.bin$' "$SCRATCH/broken.log" || grep -q '^SCRIPT ERROR:' "$SCRATCH/broken.log"; then
  cat "$SCRATCH/broken.log" >&2
  exit 1
fi
printf 'telescope-export-smoke: 2 cases, 0 failures\n'
