#!/bin/bash
# Unpublished-package development only (R3-REASONS RT2a): sunholo/observe 0.2.0 is
# built (ailang-packages PR #196) but not in the registry. The game's manifest and
# lock keep their registry pins; this stages an ignored overlay of sim/ whose
# manifest points sunholo/observe at a local checkout. Same pattern as
# tools/worlds_dev.sh. Delete this file and tools/observe_ailang.sh when 0.2.0 is
# published and pinned in sim/ailang.toml.
#   OBSERVE_PACKAGES_DIR  the checkout's packages/ directory
#                         (default ../ailang-packages-rt2ref/packages)
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
pkgs=${OBSERVE_PACKAGES_DIR:-$(dirname "$root")/ailang-packages-rt2ref/packages}
ailang=${AILANG_BIN:-$root/runtime/bin/ailang}
[ -f "$pkgs/observe/photon.ail" ] || { echo "observe_dev: no sunholo/observe 0.2.0 source at $pkgs/observe (set OBSERVE_PACKAGES_DIR)" >&2; exit 2; }
mkdir -p "$root/.godot/observe-dev"
overlay=$(mktemp -d "$root/.godot/observe-dev/run.XXXXXX")
mkdir -p "$overlay/sim/data" "$overlay/sim/tools"
for file in "$root"/sim/*.ail "$root"/sim/data/*.ail "$root"/sim/tools/*.ail; do
  ln -s "$file" "$overlay/${file#"$root/"}"
done
awk -v pkgs="$pkgs" '
 /^"sunholo\/observe"[[:space:]]*=/ {print "\"sunholo/observe\" = { path = \"" pkgs "/observe\" }"; next}
 {print}
' "$root/sim/ailang.toml" > "$overlay/sim/ailang.toml"
(cd "$overlay/sim" && "$ailang" lock >/dev/null)
case "${1:-}" in
 run) shift; exec "$ailang" run --package-dir "$overlay/sim" "$@" ;;
 check) shift; exec "$ailang" check --package "$overlay/sim" "$@" ;;
 test) shift; exec "$ailang" test --package "$overlay/sim" "$@" ;;
 path) printf '%s\n' "$overlay/sim" ;;
 *) echo "usage: tools/observe_dev.sh {run|check|test|path} [ailang arguments]" >&2; exit 2 ;;
esac
