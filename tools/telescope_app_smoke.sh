#!/bin/sh
# Complete exported-app probe from empty cwd/fresh HOME, with networking denied
# at the process sandbox (inherited by the bundled AILANG child).
set -eu
TASK_ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
APP=${TELESCOPE_APP:-"$TASK_ROOT/build/macos/Stapledons Voyage.app"}
EXPECTED=${TELESCOPE_EXPECTED_COMMIT:-$(git -C "$TASK_ROOT" rev-parse HEAD)}
SCRATCH=${SCRATCH:-"$TASK_ROOT/.godot/tmp/observations/app-smoke"}
SCRIPT_GATE=${SCRIPT_GATE:-"$TASK_ROOT/tools/script_gate.sh"}
if [ "$(uname -s)" != Darwin ] || [ ! -x /usr/bin/sandbox-exec ]; then
  echo 'FAIL telescope-app-smoke: unsupported host; macOS sandbox-exec network denial is required' >&2
  exit 1
fi
if ! /usr/bin/sandbox-exec -p '(version 1) (allow default) (deny network*)' /usr/bin/true; then
  echo 'FAIL telescope-app-smoke: network-denial sandbox unavailable' >&2
  exit 1
fi
mkdir -p "$SCRATCH"
SCRATCH=$(cd "$SCRATCH" && pwd)
RUN_DIR=$(mktemp -d "$SCRATCH/run.XXXXXX")
mkdir "$RUN_DIR/empty" "$RUN_DIR/home"
EXE_NAME=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$APP/Contents/Info.plist")
EXE="$APP/Contents/MacOS/$EXE_NAME"
(
  cd "$RUN_DIR/empty"
  sh "$SCRIPT_GATE" telescope-app-probe "$RUN_DIR/probe.log" 600 '^telescope-app-probe: [1-9][0-9]* passed, 0 failures$' -- /usr/bin/sandbox-exec -p '(version 1) (allow default) (deny network*)' /usr/bin/env -i PATH=/usr/bin:/bin HOME="$RUN_DIR/home" "$EXE" --headless --log-file "$RUN_DIR/engine.log" -- --telescope-app-probe "--expected=$EXPECTED" "--fresh-home=$RUN_DIR/home" "--report=$RUN_DIR/report.json"
) > "$RUN_DIR/gate.log" 2>&1 || {
  cat "$RUN_DIR/gate.log" >&2
  echo "telescope-app-smoke: FAIL; evidence $RUN_DIR" >&2
  exit 1
}
printf '%s\n' "$RUN_DIR" > "$SCRATCH/latest-run.txt"
printf 'telescope-app-smoke: evidence %s\n' "$RUN_DIR"
printf 'telescope-app-smoke: 1 app, 0 failures\n'
