#!/bin/bash
# Explicit local-development runtime adapter; registry manifest/lock stay intact.
# Set WORLDS_DEV_PACKAGE=$(tools/worlds_dev.sh path) once for a multi-command gate.
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
bin=${WORLDS_AILANG_BIN:-$root/runtime/bin/ailang}
args=()
next_package=false
command=${1:-}
for arg in "$@"; do
  if $next_package && { [[ "$arg" == sim || "$arg" == "$root/sim" ]] || { [[ "$arg" == . ]] && [[ "$PWD" == "$root/sim" ]]; }; }; then
    arg=${WORLDS_DEV_PACKAGE:-$($root/tools/worlds_dev.sh path)}
  elif [[ "$command" == test || "$command" == check ]] && [[ "$arg" == sim/*.ail || "$arg" == "$root/sim/"*.ail ]]; then
    file=${arg#"$root/"}
    arg="${WORLDS_DEV_PACKAGE:-$($root/tools/worlds_dev.sh path)}/${file#sim/}"
  fi
  next_package=false
  case "$arg" in --package|--package-dir) next_package=true ;; esac
  args+=("$arg")
done
exec "$bin" "${args[@]}"
