#!/bin/sh
# Local package context for development; never changes the game's registry pin.
set -eu
A=${AILANG:?absolute AILANG binary}; PKG=${KERR_PACKAGE:?absolute development package}
ROOT=$(pwd)
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT HUP INT TERM
mkdir -p "$scratch/tools"
cp tools/kerr_dev/kerr_lut*.ail "$scratch/tools/"
cat > "$scratch/ailang.toml" <<EOF
[package]
name = "stapledons/sim"
version = "0.1.0"
edition = "1"
[exports]
modules = ["stapledons/sim/tools/kerr_lut"]
[dependencies]
"sunholo/relativity" = { path = "$PKG" }
[effects]
max = ["IO","FS"]
EOF
cd "$scratch"
"$A" lock >/dev/null
if [ "${1:-}" = fit ]; then
  "$A" run --quiet --bytecode --strict-bytecode --entry fitProbe --args-json 0 tools/kerr_lut.ail
  exit
fi
if [ "${1:-}" = row ]; then
  "$A" run --quiet --bytecode --caps IO,FS --entry rowStudy --args-json "${KERR_STUDY_ARGS:?JSON study arguments}" tools/kerr_lut_main.ail
  exit
fi
"$A" test --strict-bytecode tools/kerr_lut_test.ail
if [ "${1:-}" = mesh ]; then
  "$A" run --quiet --bytecode --caps IO,FS --entry mesh --args-json "\"$ROOT/.ailang/state/evidence/R2-KERR/boundary-mesh.json\"" tools/kerr_lut_main.ail
fi
