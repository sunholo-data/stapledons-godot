#!/bin/bash
# Explicit unpublished-package diagnostics. No registry pin or production output changes.
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"
ailang=${AILANG:-$root/runtime/bin/ailang}
case "$ailang" in /*) ;; */*) ailang="$root/$ailang" ;; *) ailang=$(command -v "$ailang") ;; esac
pkgs=${WORLDS_PACKAGES_DIR:-$(dirname "$root")/ailang-packages-worlds/packages}
overlay=$(AILANG="$ailang" tools/worlds_dev.sh path)
main="$overlay/tools/calibrate_main.ail"
mode=${1:-parity}
shift || true
case "$mode" in
 test)
  "$ailang" test --strict-bytecode "$overlay/calibrate_test.ail" "$overlay/calibrate_search_test.ail"
  ;;
 smoke)
  timing=$(mktemp "$root/.godot/worlds-dev/calibration-time.XXXXXX")
  /usr/bin/time -p env -u AI_LIVE "$ailang" run --quiet --strict-bytecode --caps IO --package-dir "$overlay" --entry smoke --args-json '{"seeds":4,"supportLy":10}' "$main" 2>"$timing"
  cat "$timing"
  elapsed=$(awk '/^real / {print $2}' "$timing")
  if ! awk -v elapsed="$elapsed" 'BEGIN {exit !(elapsed <= 60)}'; then
    echo "calib-smoke-development: MISS ($elapsed s > 60 s); photon-budget acceptance remains open" >&2
    exit 1
  fi
  ;;
 parity)
  temp=$(mktemp -d "$root/.godot/worlds-dev/calibration-parity.XXXXXX")
  "$ailang" run --quiet --strict-bytecode --caps IO --package-dir "$overlay" --entry calibVm "$overlay/calibrate_test.ail" > "$temp/vm.jsonl"
  "$ailang" run --quiet --caps IO --package-dir "$overlay" --entry calibVm "$overlay/calibrate_test.ail" > "$temp/interpreter.jsonl"
  cmp "$temp/vm.jsonl" "$temp/interpreter.jsonl"
  echo "calibVm-development: 2 seeds strict VM = interpreter (byte-identical); photon_budget=false"
  ;;
 emit|interpreter|emit-full|interpreter-full)
  output=${1:-data/worlds/calibration-development.json}
  seeds=${CALIB_SEEDS:-4}
  support=${CALIB_SUPPORT_LY:-10}
  doom=${CALIB_DOOM_YR:-16000}
  digest_args=$(jq -n --arg worldsRoot "$pkgs/worlds" --arg celestialRoot "$pkgs/celestial" '{worldsRoot:$worldsRoot,celestialRoot:$celestialRoot}')
  digest=$(env -u AI_LIVE "$ailang" run --quiet --caps IO,FS --package-dir "$overlay" --entry digest --args-json "$digest_args" "$main")
  args=$(jq -n --argjson seeds "$seeds" --argjson supportLy "$support" --argjson doom "$doom" --arg inputDigest "$digest" '{seeds:$seeds,supportLy:$supportLy,doom:$doom,inputDigest:$inputDigest}')
  mkdir -p "$(dirname "$output")"
  entry=emitBinding
  if [ "$mode" = emit-full ] || [ "$mode" = interpreter-full ]; then entry=emit; fi
  if [ "$mode" = emit ] || [ "$mode" = emit-full ]; then
    /usr/bin/time -p env -u AI_LIVE "$ailang" run --quiet --strict-bytecode --caps IO --package-dir "$overlay" --entry "$entry" --args-json "$args" "$main" > "$output"
  else
    /usr/bin/time -p env -u AI_LIVE "$ailang" run --quiet --caps IO --package-dir "$overlay" --entry "$entry" --args-json "$args" "$main" > "$output"
  fi
  echo "calibration-development: $mode; $output; $seeds seeds; photon_budget=false; presets provisional"
  ;;
 *) echo "usage: tools/calibration_dev.sh {test|smoke|parity|emit|interpreter|emit-full|interpreter-full} [output.json]" >&2; exit 2 ;;
esac
