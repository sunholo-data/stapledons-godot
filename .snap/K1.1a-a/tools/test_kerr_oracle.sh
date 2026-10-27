#!/bin/sh
# R2-KERR K1.1a-a primary test: the independent Kerr oracle tools/kerr_ref.py
# (role oracle) against the design doc's fixtures. Written FIRST, before the
# oracle existed, and run RED; see the sprint slice "K1.1a-a: Independent oracle
# and reproducible RK fixture".
#
# What is asserted, in order:
#   1. precise anchors: RK-1..RK-13 and RK-18 at the design doc's 17-significant-digit
#      CPython-Decimal-precision-60 values (design_docs/planned/r2/kerr-black-holes.md,
#      "Design" RK table and Verification log V31/V40). Compared as full-precision
#      strings, so a six-decimal display value cannot stand in for one.
#   2. display rounding at six decimals, asserted separately from the precise values,
#      including that the precise rows never carry the six-decimal rendering.
#   3. invalid inputs (NaN, negative spin, spin >= 1, non-finite or non-positive radii,
#      a radius between the horizons) are refused BEFORE any square root, with a
#      loud refusal line and a non-zero exit, and no value printed.
#   4. the exact s = 0 members (RK-Q1/RS reductions) and RK-3's identity in s: printed
#      as the exact integers they are, never as 1.999999...
#   5. the generated fixture tests/fixtures/kerr/rk.json is valid JSON, carries its
#      metadata, regenerates byte-identically from a fresh oracle run, and neither an
#      empty fixture nor a fixture whose value was replaced by the six-decimal display
#      string can pass `check` (anti-vacuity; rounded-literal reuse).
#
# No network, no GPU, no AILANG: this target exercises the oracle alone.
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd)
ORACLE=$ROOT/tools/kerr_ref.py
FIXTURE=$ROOT/tests/fixtures/kerr/rk.json
RECORDS=39
fail() { echo "test_kerr_oracle: FAIL $*"; exit 1; }

# ---- 0. the oracle exists. This line was the slice's first RED. --------------
[ -f "$ORACLE" ] || fail "missing oracle $ORACLE (K1.1a-a not implemented yet)"

T=$(mktemp -d 2> /dev/null || true)
if [ -z "$T" ]; then
  # The loop sandbox refuses /tmp and $TMPDIR; .godot/ is the repo's ignored scratch
  # (Makefile SCRATCH) and is writable everywhere this test runs.
  T=$ROOT/.godot/tmp/test_kerr_oracle.$$
  mkdir -p "$T"
fi
trap 'rm -rf "$T"' EXIT

# ---- 1. precise anchors: 17 significant digits, full precision ---------------
python3 -I "$ORACLE" closed > "$T/closed.txt" 2> "$T/closed.err" \
  || fail "kerr_ref.py closed exited non-zero: $(cat "$T/closed.err")"
need() {  # need <label> <exact expected line>
  grep -qxF -- "$2" "$T/closed.txt" \
    || fail "$1: closed did not print the precise row '$2'; it printed: $(grep -F -- "${2%% *}" "$T/closed.txt" | tr '\n' '|' || true)"
}
# RK-1/2 outer and inner horizon u_+, u_- = 1 +/- sqrt(1 - s^2), in GM/c^2.
need "RK-1/2 s=0.5"    "RK-1/2 0.5 1.8660254037844386 0.13397459621556135"
need "RK-1/2 s=0.9"    "RK-1/2 0.9 1.4358898943540674 0.56411010564593264"
need "RK-1/2 s=0.998"  "RK-1/2 0.998 1.0632139225171164 0.93678607748288357"
# RK-4/5 equatorial photon orbits, prograde then retrograde, GM/c^2.
need "RK-4/5 s=0.9"    "RK-4/5 0.9 1.5578546274233828 3.9102679391030367"
need "RK-4/5 s=0.998"  "RK-4/5 0.998 1.0739092576799517 3.9982218928479460"
# RK-6/7 ISCO, prograde then retrograde, GM/c^2.
need "RK-6/7 s=0.5"    "RK-6/7 0.5 4.2330025295308257 7.5545847145123584"
need "RK-6/7 s=0.9"    "RK-6/7 0.9 2.3208830417618872 8.7173522796064893"
# RK-8/8b ISCO orbit clocks dtau/dt (prograde, then retrograde at s=0.9; V40 at s=0.998).
need "RK-8 s=0.9"      "RK-8 0.37086794439864592 0.79319251811829484"
need "RK-8b s=0.998"   "RK-8b 0.092670308365368573"
# RK-9 horizon angular velocity, c^3/GM.
need "RK-9 s=0.9"        "RK-9 0.31339450313662925"
# RK-10/11 frame dragging and ZAMO lapse at the equatorial static limit (u = 2), s=0.9.
need "RK-10/11 s=0.9"    "RK-10/11 0.16014234875444840 0.37964208654863802"
# RK-12 ZAMO local speed of the prograde ISCO, in c: s=0.9, then s=0.5.
need "RK-12 s=0.9/0.5"   "RK-12 0.62454869546086524 0.56164924228192780"
# RK-18 10 M_sun, s=0.9: r_s; equatorial static limit; horizon; prograde ISCO;
# prograde-ISCO period; Omega_H -- IAU 2015 nominal GM_sun, km / ms / rad per s.
need "RK-18 10Msun s=0.9" "RK-18 29.532500761002495 29.532500761002495 21.202709698863643 34.270740098515360 1.3727616115380832 6362.7059001439946"
test "$(wc -l < "$T/closed.txt" | tr -d ' ')" -eq 13 \
  || fail "closed printed $(wc -l < "$T/closed.txt" | tr -d ' ') rows, expected 13"

# ---- 2. display rounding is a separate, six-decimal rendering ----------------
# (design: "The spec may round its display values; tests of such text use half a unit
# in its last printed place, separately from physics assertions".)
python3 -I "$ORACLE" display > "$T/display.txt" 2> "$T/display.err" \
  || fail "kerr_ref.py display exited non-zero: $(cat "$T/display.err")"
needd() {  # needd <label> <exact expected line>
  grep -qxF -- "$2" "$T/display.txt" \
    || fail "$1: display did not print '$2'; it printed: $(grep -F -- "${2%% *}" "$T/display.txt" | tr '\n' '|' || true)"
}
needd "RK-1 s=0.5 rounds down"    "RK-1 0.5 outerHorizonU 1.866025"
needd "RK-2 s=0.5 rounds up"      "RK-2 0.5 innerHorizonU 0.133975"
needd "RK-4 s=0.9 rounds up"      "RK-4 0.9 photonProgradeU 1.557855"
needd "RK-5 s=0.998 rounds up"    "RK-5 0.998 photonRetrogradeU 3.998222"
needd "RK-8b s=0.998 rounds down" "RK-8b 0.998 iscoProgradeClock 0.092670"
needd "RK-9 s=0.9 rounds up"      "RK-9 0.9 horizonOmega 0.313395"
needd "RK-10 s=0.9"               "RK-10 0.9 staticLimitFrameDragOmega 0.160142"
needd "RK-12 s=0.5"               "RK-12 0.5 iscoProgradeZamoSpeed 0.561649"
needd "RK-18 period"              "RK-18 0.9 iscoProgradePeriodMs 1.372762"
needd "RK-18 Omega_H"             "RK-18 0.9 horizonOmegaRadPerSec 6362.705900"
needd "RK-Q1 s=0 horizon is exact 2" "RK-Q1 0 outerHorizonU 2.000000"
# The two renderings must not be conflated: the precise rows must not carry the
# six-decimal display string as if it were the value.
if grep -qE '(^| )1\.866025( |$)' "$T/closed.txt"; then
  fail "closed printed the six-decimal display string 1.866025 as a precise value (display rounding conflated with the precise value)"
fi
if grep -qE '(^| )0\.092670( |$)' "$T/closed.txt"; then
  fail "closed printed the six-decimal display string 0.092670 as a precise value (display rounding conflated with the precise value)"
fi

# ---- 3. invalid inputs are refused before any square root --------------------
refused() {  # refused <label> <token the refusal must name> <args...>
  label=$1; token=$2; shift 2
  if out=$(python3 -I "$ORACLE" "$@" 2>&1); then
    fail "$label: exited 0, so an invalid input was accepted; output: $out"
  fi
  printf '%s\n' "$out" | grep -q 'kerr_ref: refused' \
    || fail "$label: no refusal line (a crash is not a domain refusal); output: $out"
  printf '%s\n' "$out" | grep -qF -- "$token" \
    || fail "$label: refusal did not name $token; output: $out"
  case "$out" in
    *"RK-"*) fail "$label: printed a value before refusing; output: $out" ;;
  esac
}
refused "NaN spin"                "spin s=nan"            probe nan
refused "Infinity spin"           "spin s=inf"            probe inf
refused "negative spin"           "spin s=-0.5"           probe -0.5
refused "extremal spin s=1"       "spin s=1"              probe 1
refused "spin above extremal"     "spin s=1.5"            probe 1.5
refused "NaN radius"              "radius u=nan"          probe 0.9 nan
refused "infinite radius"         "radius u=inf"          probe 0.9 inf
refused "negative radius"         "radius u=-3"           probe 0.9 -3
refused "zero radius"             "radius u=0"            probe 0.9 0
refused "radius between horizons" "between the horizons"  probe 0.9 1.3
# A valid input still works, through the same code path.
out=$(python3 -I "$ORACLE" probe 0.9 5) || fail "probe 0.9 5 refused a valid input: $out"
printf '%s\n' "$out" | grep -q '^probe s=0.9 u_plus=1.4358898943540674$' \
  || fail "probe s=0.9 did not print the precise outer horizon: $out"

# ---- 4. the exact members: s = 0 (RK-Q1) and the s-identity RK-3 ------------
python3 -I "$ORACLE" exact > "$T/exact.txt" 2> "$T/exact.err" \
  || fail "kerr_ref.py exact exited non-zero: $(cat "$T/exact.err")"
needx() {  # needx <label> <exact expected line>
  grep -qxF -- "$2" "$T/exact.txt" \
    || fail "$1: exact did not print '$2'; it printed: $(tr '\n' '|' < "$T/exact.txt")"
}
needx "RK-3 identity in s, s=0"            "RK-3 0 staticLimitU 2"
needx "RK-3 identity in s, s=0.9"          "RK-3 0.9 staticLimitU 2"
needx "RK-3 identity in s, s=0.998"        "RK-3 0.998 staticLimitU 2"
needx "RK-13 static clock at the static limit, s=0.9" "RK-13 0.9 staticClockAtStaticLimit 0"
needx "RK-13 zero-spin dispatch, u=2"                 "RK-13 0 staticClockAtStaticLimit 0"
needx "RK-Q1 s=0 outer horizon = 1 r_s = 2 GM/c^2"     "RK-Q1 0 outerHorizonU 2"
needx "RK-Q1 s=0 inner horizon = 0"                    "RK-Q1 0 innerHorizonU 0"
needx "RK-Q1 s=0 static limit = 2"                     "RK-Q1 0 staticLimitU 2"
needx "RK-Q1 s=0 photon orbit = 1.5 r_s = 3 GM/c^2"    "RK-Q1 0 photonProgradeU 3"
needx "RK-Q1 s=0 ISCO = 3 r_s = 6 GM/c^2"             "RK-Q1 0 iscoProgradeU 6"
needx "RK-Q1 s=0 horizon angular velocity = 0"         "RK-Q1 0 horizonOmega 0"

# ---- 5. the generated fixture -----------------------------------------------
[ -f "$FIXTURE" ] || fail "fixture $FIXTURE is missing (generate it: python3 -I tools/kerr_ref.py fixture)"
python3 -I "$ORACLE" fixture "$T/regen.json" > /dev/null 2> "$T/fix.err" \
  || fail "fixture regeneration failed: $(cat "$T/fix.err")"
cmp -s "$T/regen.json" "$FIXTURE" \
  || fail "tests/fixtures/kerr/rk.json differs from a fresh oracle run (hand-edited, or generated by a different oracle); regenerate with: python3 -I tools/kerr_ref.py fixture"
n=$(python3 -I -c 'import json,sys; d = json.load(open(sys.argv[1])); r = d["records"]; print(len(r))' "$FIXTURE")
test "$n" -eq "$RECORDS" || fail "fixture holds $n records, expected $RECORDS"
missing=$(python3 -I -c 'import json,sys
d = json.load(open(sys.argv[1]))
bad = [r.get("id", "?") for r in d["records"]
       if not all(str(r.get(k, "")).strip() for k in ("id", "spin", "quantity", "symbol", "unit", "formula", "source", "value", "display6"))]
print(" ".join(bad))' "$FIXTURE")
[ -z "$missing" ] || fail "fixture records without the units/source/formula metadata: $missing"
python3 -I "$ORACLE" check > "$T/check.txt" 2>&1 \
  || fail "kerr_ref.py check failed on the committed fixture: $(cat "$T/check.txt")"
grep -q 'kerr_ref: ok' "$T/check.txt" || fail "check exited 0 without its ok line: $(cat "$T/check.txt")"

# Anti-vacuity: an empty fixture is a failure, never a pass.
printf '%s\n' '{"schema": "kerr-rk-fixtures/1", "records": []}' > "$T/empty.json"
if out=$(python3 -I "$ORACLE" check "$T/empty.json" 2>&1); then
  fail "check exited 0 on an empty fixture (anti-vacuity): $out"
fi
printf '%s\n' "$out" | grep -q 'kerr_ref: FAIL' \
  || fail "check failed an empty fixture without a loud FAIL line: $out"

# Rounded-literal reuse: a value replaced by its six-decimal display string must fail.
python3 -I -c 'import json,sys
d = json.load(open(sys.argv[1]))
d["records"][0]["value"] = d["records"][0]["display6"]
with open(sys.argv[2], "w") as f:
    json.dump(d, f, indent=2)
    f.write("\n")' "$FIXTURE" "$T/rounded.json"
if out=$(python3 -I "$ORACLE" check "$T/rounded.json" 2>&1); then
  fail "check exited 0 on a fixture whose first value is the six-decimal display string (rounded-literal reuse): $out"
fi
printf '%s\n' "$out" | grep -q 'kerr_ref: FAIL' \
  || fail "check accepted a rounded literal without a loud FAIL line: $out"
printf '%s\n' "$out" | grep -qF "$(python3 -I -c 'import json,sys; r = json.load(open(sys.argv[1]))["records"][0]; print(r["id"] + " " + r["spin"] + " " + r["quantity"])' "$FIXTURE")" \
  || fail "check reported a rounded literal but did not name the offending record: $out"

echo "test_kerr_oracle: RK-1..RK-13 and RK-18 match the design doc at 17 significant digits, display strings at six decimals; 10 invalid inputs refused before any square root; the s = 0 members exact; the $RECORDS-record fixture regenerates byte-identically and rejects empty and rounded fixtures"
echo "test_kerr_oracle: fixture sha256 $(shasum -a 256 "$FIXTURE" | cut -d' ' -f1)"
