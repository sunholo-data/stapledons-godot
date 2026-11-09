#!/bin/sh
# Row 7o and D-126 control: tools/rig_check.sh must post only descriptions GitHub accepts (at most 140
# characters), keep the log pointer in a failure description whenever it fits, and report a
# refused failure or success post on stdout with a nonzero exit. No network: gh, git and make
# are stubs on PATH; the stub gh refuses a long description the way GitHub does (HTTP 422).
#   sh tools/test_rig_check.sh [path/to/rig_check.sh]
set -eu
unset RIG_TEST_S RIG_GOLDEN_S RIG_SETUP_S RIG_DL_S   # hermetic: a caller's watchdog override must not reach the cases (iteration 52)
RIG=$(cd "$(dirname "${1:-tools/rig_check.sh}")" && pwd -P)/$(basename "${1:-tools/rig_check.sh}")
T=$(mktemp -d "${TMPDIR:-/tmp}/rig-check-control.XXXXXX")
trap 'rm -rf "$T"' EXIT
test "${#T}" -le 100   # the clone-red-pointer case needs a log path short enough for the pointer to fit
export STUB_POSTS="$T/posts" STUB_SHA=0123456789abcdef0123456789abcdef01234567 STUB_MAKES="$T/makes" STUB_CHILD="$T/child"
mkdir "$T/bin"
cat > "$T/bin/gh" <<'STUB'
#!/bin/sh
[ "$1" = pr ] && { echo "$STUB_SHA"; exit 0; }
for a; do case "$a" in state=*) s=${a#state=} ;; description=*) d=${a#description=} ;; esac; done
n=$(printf %s "$d" | wc -m | tr -d ' ')
[ "$n" -le 140 ] && [ "$s" != "${STUB_REFUSE:-}" ] || { echo "$s $n refused" >> "$STUB_POSTS"; echo 'Validation failed: Description is too long (maximum is 140 characters) (HTTP 422)' >&2; exit 1; }
echo "$s $n $d" >> "$STUB_POSTS"
STUB
cat > "$T/bin/git" <<'STUB'
#!/bin/sh
[ "$1" = clone ] || exit 0
[ "${STUB_GIT_FAIL:-}" = clone ] && exit 1
for d; do :; done
mkdir -p "$d/runtime/bin"; echo 'AILANG_RELEASE ?= v0.54.14' > "$d/Makefile"
printf '#!/bin/sh\necho "%s"\n' "$STUB_VERSION" > "$d/runtime/bin/ailang"; chmod +x "$d/runtime/bin/ailang"
STUB
# The stub make logs each call to $STUB_MAKES; for the target named in $STUB_MAKE_HANG it hangs with a 20 s child
# whose pid goes to $STUB_CHILD, so a mutant that loses a bound ends red after about 20 s and never hangs the control.
cat > "$T/bin/make" <<'STUB'
#!/bin/sh
echo "$*" >> "$STUB_MAKES"
case " $* " in *" $STUB_MAKE_FAIL "*) exit 1 ;; esac
case " $* " in *" ${STUB_MAKE_HANG:-none} "*)
  # STUB_CHILD_IGNORE_TERM=1: the child ignores TERM (the trap survives exec), so only the KILL escalation ends it.
  if [ "${STUB_CHILD_IGNORE_TERM:-0}" = 1 ]; then sh -c 'trap "" TERM; exec sleep 20' & else sleep 20 & fi
  echo $! > "$STUB_CHILD"; wait ;; esac
STUB
chmod +x "$T/bin/gh" "$T/bin/git" "$T/bin/make"
long=$(printf '%0200d' 0)
pad="$T/rig-check/"; while [ ${#pad} -lt 100 ]; do pad="${pad}x"; done   # the rig's 104-character log path
fails=0
# run <case> <want rc> <want final state> <want description (ERE)> <want stdout (ERE)> <version> <failing make target> <RIG_DIR> [clone] [RIG_TEST_S]
run() {
  : > "$STUB_POSTS"; why=
  rc=0; ( if [ -n "${10:-}" ]; then RIG_TEST_S=${10}; export RIG_TEST_S; fi; STUB_VERSION=$6 STUB_MAKE_FAIL=$7 RIG_DIR=$8 STUB_GIT_FAIL=${9:-} RIG_NO_STATUS=0 PATH="$T/bin:$PATH" sh "$RIG" 7 ) > "$T/out" 2>&1 || rc=$?
  test "$rc" = "$2" || why="rc $rc, want $2"
  if grep -q refused "$STUB_POSTS"; then why="$why; refused: $(grep refused "$STUB_POSTS" | tr '\n' ' ')"; fi
  test "$(cut -d' ' -f1 "$STUB_POSTS" | tr '\n' ' ')" = "pending $3 " || why="$why; posts: $(cut -d' ' -f1-2 "$STUB_POSTS" | tr '\n' ' ')"
  grep -Eq "^$3 [0-9]+ $4" "$STUB_POSTS" || why="$why; no $3 description /$4/"
  grep -Eq "$5" "$T/out" || why="$why; no stdout /$5/"
  if [ -z "$why" ]; then echo "rig-check control $1: ok"; else echo "rig-check control $1: FAIL ($why)"; fails=$((fails + 1)); fi
}
# The rig's 104-character log: the pointer does not fit, so the description is exactly sha and reason.
run make-test-red 1 failure '01234567: make test failed \(rc 1; bound 7200s\); no failing target in the log$' '^rig-check: FAIL: make test failed.*\.log\)$' 'AILANG v0.54.14' test "$pad"
run long-reason 1 failure "01234567: runtime is 'AILANG 0{100}" '^rig-check: FAIL: runtime is ' "AILANG $long" none "$T/r2"
run long-success 0 success 'make test green on the Studio' '^rig-check: ok, 01234567 green' "AILANG v0.54.14 $long" none "$T/r3"
# A short log path: the pointer fits, so it is in the description.
run clone-red-pointer 1 failure '01234567: clone failed \(log: .*/c\.log\)$' '^rig-check: FAIL: clone failed \(log: .*/c\.log\)$' 'AILANG v0.54.14' none "$T/c" clone
# An explicit RIG_TEST_S still sets the watchdog (the escape hatch, D-126).
run watchdog-override 1 failure '01234567: make test failed \(rc 1; bound 60s\); no failing target in the log$' '^rig-check: FAIL: make test failed \(rc 1; bound 60s\); no failing target in the log' 'AILANG v0.54.14' test "$pad" '' 60
# refused <case> <state to refuse> <failing make target> <want rc> <want stdout line 1 (ERE)> <want stdout line 2 (exact)>
refused() {
  : > "$STUB_POSTS"; rc=0
  STUB_REFUSE=$2 STUB_VERSION='AILANG v0.54.14' STUB_MAKE_FAIL=$3 RIG_DIR="$T/$1" RIG_NO_STATUS=0 PATH="$T/bin:$PATH" sh "$RIG" 7 > "$T/out" 2>&1 || rc=$?
  if test "$rc" = "$4" && grep -Eq "$5" "$T/out" && grep -qx "$6" "$T/out" && grep -q "^$2 [0-9]* refused$" "$STUB_POSTS"; then
    echo "rig-check control $1: ok"
  else echo "rig-check control $1: FAIL (rc $rc)"; fails=$((fails + 1)); fi
}
# A refused post (GitHub down, say) still reports on stdout and exits 1; GitHub keeps showing pending.
refused failure-refused failure test 1 '^rig-check: FAIL: make test failed.*\.log\)$' 'rig-check: could not post the failure status'
refused success-refused success none 1 '^rig-check: ok, 01234567 green' 'rig-check: could not post the success status'
# Instrument fixtures are one case in this already-wired control.
if sh tools/test_suite_profile.sh > "$T/suite-profile.log" 2>&1; then
  echo 'rig-check control suite-profile: ok'
else
  cat "$T/suite-profile.log"
  echo 'rig-check control suite-profile: FAIL (see fixture output)'; fails=$((fails + 1))
fi
# Row 7ag: a red make test target must not stop the run before the other targets (make -k) or hide them (the nightly list).
HERE=$(cd "$(dirname "$0")/.." && pwd -P)
if sh "$HERE/tools/test_rig_keep_going.sh" "$HERE" > "$T/keep-going.log" 2>&1; then
  echo 'rig-check control keep-going: ok'
else
  cat "$T/keep-going.log"
  echo 'rig-check control keep-going: FAIL (see fixture output)'; fails=$((fails + 1))
fi
# Reaper probe for the hang cases: the pid is gone within a 3 s poll (rc 0), or still alive (rc 1).
alive() { kill -0 "$1" 2>/dev/null; }
reaped() { i=0; while alive "$1"; do i=$((i + 1)); [ "$i" -ge 30 ] && return 1; sleep 0.1; done; return 0; }
# Positive control: the probe must see a live sleep as alive, or the reaped checks prove nothing. Not a case (no ': ok').
sleep 30 & probe=$!
if reaped "$probe"; then echo "rig-check reaper positive control: FAIL (kill -0 misses a live sleep)"; fails=$((fails + 1)); else echo "rig-check reaper positive control: sees a live sleep"; fi
kill "$probe" 2>/dev/null || true; wait "$probe" 2>/dev/null || true
# order <case> <flag> <failing target | hang:<target> | none> <want rc> <want make calls, in order> <want state> <want description ERE>
#       [RIG_SETUP_S] [RIG_DL_S] [STUB_VERSION]
# The make calls are logged in order. hang:<target> makes that call hang with a child; after the rig exits, that child
# must be gone (the bound took its whole process group). The description is checked with a log path too long to fit.
order() {
  c=$1; flag=$2; ft=$3; want_rc=$4; want_calls=$5; want_state=$6; want_desc=$7
  setup_s=${8:-}; dl_s=${9:-}; ver=${10:-AILANG v0.54.14}; test_s=${11:-}; golden_s=${12:-}
  ign=0
  case "$ft" in
    hang-term:*) hang=${ft#hang-term:}; fail=none; ign=1 ;;
    hang:*) hang=${ft#hang:}; fail=none ;;
    *) hang=none; fail=$ft ;;
  esac
  : > "$STUB_POSTS"; : > "$STUB_MAKES"; rm -f "$STUB_CHILD"; why=; rc=0
  ( if [ -n "$setup_s" ]; then RIG_SETUP_S=$setup_s; export RIG_SETUP_S; fi
    if [ -n "$dl_s" ]; then RIG_DL_S=$dl_s; export RIG_DL_S; fi
    if [ -n "$test_s" ]; then RIG_TEST_S=$test_s; export RIG_TEST_S; fi
    if [ -n "$golden_s" ]; then RIG_GOLDEN_S=$golden_s; export RIG_GOLDEN_S; fi
    export STUB_VERSION="$ver" STUB_MAKE_FAIL="$fail" STUB_MAKE_HANG="$hang" STUB_CHILD_IGNORE_TERM="$ign" RIG_DIR="$pad$c" RIG_NO_STATUS=0
    PATH="$T/bin:$PATH"; export PATH
    if [ -n "$flag" ]; then sh "$RIG" 7 "$flag"; else sh "$RIG" 7; fi
  ) > "$T/out" 2>&1 || rc=$?
  test "$rc" = "$want_rc" || why="rc $rc, want $want_rc"
  got=$(tr '\n' ' ' < "$STUB_MAKES" | sed 's/ $//')
  test "$got" = "$want_calls" || why="$why; make calls [$got], want [$want_calls]"
  test "$(cut -d' ' -f1 "$STUB_POSTS" | tr '\n' ' ')" = "pending $want_state " || why="$why; posts: $(cut -d' ' -f1-2 "$STUB_POSTS" | tr '\n' ' ')"
  grep -Eq "^$want_state [0-9]+ $want_desc" "$STUB_POSTS" || why="$why; no $want_state description /$want_desc/"
  if [ "$hang" != none ]; then
    child=$(cat "$STUB_CHILD" 2>/dev/null || true)
    if [ -z "$child" ]; then why="$why; the $hang hang never ran"
    elif ! reaped "$child"; then why="$why; hang child $child still alive"; kill -9 "$child" 2>/dev/null || true
    fi
  fi
  if [ -z "$why" ]; then echo "rig-check control $c: ok"; else echo "rig-check control $c: FAIL ($why)"; fails=$((fails + 1)); fi
}
# The golden setup: make runs in GOLDEN_SETUP order, after sky-assets, before golden (the nightly rig/golden path).
order golden-only-setup --golden-only none 0 'sky-assets deps starmap-assets planet-assets import golden' success 'make golden green'
order golden-setup --golden none 0 'sky-assets -k test deps starmap-assets planet-assets import golden' success 'make test \+ make golden green'
# A failing setup target stops the run before golden; the default SETUP_S is 600 s (RIG_SETUP_S unset here).
order golden-setup-red --golden-only import 1 'sky-assets deps starmap-assets planet-assets import' failure '01234567: golden setup: make import failed or ran over 600s$'
# The rig/full path has no setup, so the make test run is unchanged.
order full-no-setup "" none 0 'sky-assets -k test' success 'make test green'
# Bounds: a hung setup target, sky-assets or runtime is ended by its bound (2 s here), named, and its child is reaped.
order setup-hang --golden-only hang:deps 1 'sky-assets deps' failure '01234567: golden setup: make deps failed or ran over 2s$' 2
order sky-hang --golden-only hang:sky-assets 1 'sky-assets' failure '01234567: rig setup: make sky-assets failed or ran over 2s$' "" 2
order runtime-hang --golden-only hang:runtime 1 'runtime' failure '01234567: rig setup: make runtime failed or ran over 2s$' "" 2 'AILANG v0.54.11'
# The rig/full make test and the golden make are bounded too (evaluation round 1). golden-hang's child ignores TERM,
# so only the KILL escalation ends it: a bound without KILL leaves it alive and the case fails.
order test-hang "" hang:test 1 'sky-assets -k test' failure '01234567: make test ran over 2s; no failing target in the log$' "" "" 'AILANG v0.54.14' 2
order golden-hang --golden-only hang-term:golden 1 'sky-assets deps starmap-assets planet-assets import golden' failure '01234567: make golden failed or ran over 2s$' "" "" 'AILANG v0.54.14' "" 2
# caller-poison: the whole control again under a caller's overrides; it must stay green (D-126, iteration 52).
n=18
if [ -z "${RIG_CHECK_NESTED:-}" ]; then
  n=19; nrc=0
  RIG_CHECK_NESTED=1 MAKEFLAGS=k RIG_TEST_S=1234 RIG_GOLDEN_S=7 RIG_SETUP_S=9 RIG_DL_S=9 sh "$0" "$RIG" > "$T/nested.log" 2>&1 || nrc=$?
  nok=$(grep -c ': ok$' "$T/nested.log" || true)
  if [ "$nrc" = 0 ] && [ "$nok" = 18 ]; then echo "rig-check control caller-poison: ok"; else echo "rig-check control caller-poison: FAIL (rc $nrc, $nok of 18 ok)"; fails=$((fails + 1)); fi
fi
echo "rig-check control: $n cases, $fails failures"
test "$fails" = 0
