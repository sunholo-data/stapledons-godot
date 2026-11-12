#!/bin/bash
# `make <gate> AILANG=tools/observe_ailang.sh`: runs the pinned runtime against the
# observe 0.2.0 development overlay (tools/observe_dev.sh). Set
# OBSERVE_DEV_PACKAGE=$(tools/observe_dev.sh path) once for a multi-command gate.
# Registry manifest and lock stay intact. Remove with observe_dev.sh at the pin.
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
export WORLDS_DEV_PACKAGE=${OBSERVE_DEV_PACKAGE:-$("$root/tools/observe_dev.sh" path)}
exec "$root/tools/worlds_ailang.sh" "$@"
