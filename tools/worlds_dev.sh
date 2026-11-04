#!/bin/bash
# Unpublished-package development only. The game's registry pins never change.
# Each caller gets an isolated ignored overlay; sources stay linked to this clone.
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
pkgs=${WORLDS_PACKAGES_DIR:-$(dirname "$root")/ailang-packages-worlds/packages}
ailang=${AILANG:-$root/runtime/bin/ailang}
case "$ailang" in /*) ;; */*) ailang="$root/$ailang" ;; *) ailang=$(command -v "$ailang") ;; esac
mkdir -p "$root/.godot/worlds-dev"
overlay=$(mktemp -d "$root/.godot/worlds-dev/run.XXXXXX")
mkdir -p "$overlay/sim/data" "$overlay/sim/tools"
for file in "$root"/sim/*.ail "$root"/sim/data/*.ail "$root"/sim/tools/*.ail; do
  rel=${file#"$root/"}
  ln -s "$file" "$overlay/$rel"
done
for file in "$root"/sim/*.ail "$root"/sim/data/*.ail "$root"/sim/tools/*.ail; do
  awk '/^module / {printf "  \"%s\",\n", $2; exit}' "$file"
done > "$overlay/modules.txt"
awk -v pkgs="$pkgs" -v moduleFile="$overlay/modules.txt" '
 /^modules = \[/ {print; while ((getline line < moduleFile) > 0) print line; close(moduleFile); next}
 /^"sunholo\/celestial"[[:space:]]*=/ {print "\"sunholo/celestial\" = { path = \"" pkgs "/celestial\" }"; next}
 {print}
 END {print "\"sunholo/worlds\" = { path = \"" pkgs "/worlds\" }"}
' "$root/sim/ailang.toml" > "$overlay/sim/ailang.toml"
(cd "$overlay/sim" && "$ailang" lock >/dev/null)
case "${1:-}" in
 run) shift; exec "$ailang" run --package-dir "$overlay/sim" "$@" ;;
 check) shift; exec "$ailang" check --package "$overlay/sim" "$@" ;;
 test) shift; exec "$ailang" test --package "$overlay/sim" "$@" ;;
 path) printf '%s\n' "$overlay/sim" ;;
 *) echo "usage: tools/worlds_dev.sh {run|check|test|path} [ailang arguments]" >&2; exit 2 ;;
esac
