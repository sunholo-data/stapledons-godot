#!/bin/sh
# Row 7o and D-126 control: tools/rig_check.sh must post only descriptions GitHub accepts (at most 140
# characters), keep the log pointer in a failure description whenever it fits, and report a
# refused failure or success post on stdout with a nonzero exit. No network: gh, git and make
# are stubs on PATH; the stub gh refuses a long description the way GitHub does (HTTP 422).
# 1e (M1b): the profiled make is a gmake stub too, so the real gmake is never reached; the profiler cases are below.
#   sh tools/test_rig_check.sh [path/to/rig_check.sh]
set -eu
unset RIG_TEST_S RIG_GOLDEN_S RIG_SETUP_S RIG_DL_S RIG_PROFILE RIG_TRACE SUITE_TOP_TARGET   # hermetic: a caller's watchdog or profile override must not reach the cases (iteration 52, M1b)
RIG=$(cd "$(dirname "${1:-tools/rig_check.sh}")" && pwd -P)/$(basename "${1:-tools/rig_check.sh}")
TOOLS=$(cd "$(dirname "$0")" && pwd -P)   # the real instrument (suite_profile.sh, timed_recipe_shell.sh) the stub git clone copies
# The temp base is the caller's TMPDIR only when the control's own paths still fit the 100-character budget: mktemp adds
# 25 characters ("/rig-check-control.XXXXXX"), so a base over 75 characters (the profiler's --out directory is one) falls back to /tmp.
base=${TMPDIR:-/tmp}; base=${base%/}
test "${#base}" -le 75 || base=/tmp
T=$(mktemp -d "$base/rig-check-control.XXXXXX") || { echo "rig-check control: FAIL: mktemp could not make a temp directory under $base"; exit 1; }
trap 'rm -rf "$T"' EXIT
if [ "${#T}" -gt 100 ]; then echo "rig-check control: FAIL: temp path is ${#T} characters, over the 100-character budget ($T)"; exit 1; fi   # the clone-red-pointer case needs a log path short enough for the pointer to fit
export STUB_POSTS="$T/posts" STUB_SHA=0123456789abcdef0123456789abcdef01234567 STUB_MAKES="$T/makes" STUB_CHILD="$T/child"
export STUB_GMAKES="$T/gmakes" STUB_TOOLS="$TOOLS"
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
# 1e: the PR head carries the instrument (the real scripts); STUB_NO_TOOLS=1 is an older head without it.
if [ "${STUB_NO_TOOLS:-0}" != 1 ]; then mkdir -p "$d/tools"; cp "$STUB_TOOLS/suite_profile.sh" "$STUB_TOOLS/timed_recipe_shell.sh" "$d/tools/"; fi
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
# 1e: the profiled make is a gmake stub. Its own argv goes to $STUB_GMAKES; its transcript line goes to $STUB_MAKES with
# the profiler's words (-j 1, SHELL=, SUITE_TARGET=) left out, so the make-call expectations read as they do for make.
# It answers the closure query and --version as make does, runs the SHELL wrapper once (one profile row), and fails or
# hangs by the same STUB_MAKE_FAIL and STUB_MAKE_HANG knobs as make.
cat > "$T/bin/gmake" <<'STUB'
#!/bin/sh
case "${1:-}" in --version) echo 'GNU Make 4.4.1 (stub)'; exit 0 ;; esac
case " $* " in *" -pq "*) exit 0 ;; esac
echo "$*" >> "$STUB_GMAKES"
line=; skip=0; shell=
for a; do
  if [ "$skip" = 1 ]; then skip=0; continue; fi
  case "$a" in
    -j) skip=1 ;;
    SHELL=*) shell=${a#SHELL=} ;;
    SUITE_TARGET=*) ;;
    *) line="${line:+$line }$a" ;;
  esac
done
echo "$line" >> "$STUB_MAKES"
if [ -n "$shell" ]; then sh "$shell" -c true; fi
case " $* " in *" $STUB_MAKE_FAIL "*) exit 1 ;; esac
case " $* " in *" ${STUB_MAKE_HANG:-none} "*) sleep 20 & echo $! > "$STUB_CHILD"; wait ;; esac
exit 0
STUB
chmod +x "$T/bin/gh" "$T/bin/git" "$T/bin/make" "$T/bin/gmake"
# 1e: the gmake-missing case runs under this PATH: the stubs gh, git and make, then the system tools, and no gmake.
mkdir "$T/nogmake"; cp "$T/bin/gh" "$T/bin/git" "$T/bin/make" "$T/nogmake/"
NOGMAKE="$T/nogmake:/usr/bin:/bin:/usr/sbin"
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
# 7aw: run the evidence publication control alongside the profiler control.
if sh tools/test_evidence_secret_guard.sh > "$T/evidence-guard.log" 2>&1; then
  echo 'rig-check control evidence-guard: ok'
else
  cat "$T/evidence-guard.log"
  echo 'rig-check control evidence-guard: FAIL (see fixture output)'; fails=$((fails + 1))
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
# 1e: the profiler. prun <case> <gmake|nogmake> <copy|none> <unset|0>: one rig run under that PATH, with that PR head
# (copy: the real instrument; none: an older head) and that RIG_PROFILE. rc is left in $rc; the log is $pad<case>.log.
prun() {
  : > "$STUB_POSTS"; : > "$STUB_MAKES"; : > "$STUB_GMAKES"; rc=0
  p="$T/bin:$PATH"; if [ "$2" = nogmake ]; then p=$NOGMAKE; fi
  no=0; if [ "$3" = none ]; then no=1; fi
  # The fallback cases carry a long version (the 140-character clamp); the others keep a short one, so the clamp drill
  # names the fallback cases only. $5=1 sets RIG_TRACE; PRUN_FAIL (if set) is the target the stub gmake fails.
  case "$1" in profile-off|profile-absent|gmake-missing) v="AILANG v0.54.14 $long" ;; *) v="AILANG v0.54.14" ;; esac
  tr=0; if [ "${5:-0}" = 1 ]; then tr=1; fi
  ( if [ "$4" = 0 ]; then RIG_PROFILE=0; export RIG_PROFILE; fi
    if [ "$tr" = 1 ]; then RIG_TRACE=1; export RIG_TRACE; fi
    STUB_NO_TOOLS=$no STUB_VERSION=$v STUB_MAKE_FAIL=${PRUN_FAIL:-none} STUB_MAKE_HANG=none RIG_NO_STATUS=0 RIG_DIR="$pad$1" PATH=$p
    export STUB_NO_TOOLS STUB_VERSION STUB_MAKE_FAIL STUB_MAKE_HANG RIG_NO_STATUS RIG_DIR PATH
    sh "$RIG" 7 ) > "$T/out" 2>&1 || rc=$?
}
# pcase <case> <want rc> <FALLBACK reason, or none> <gmake called: 1|0> <success description ERE> <make transcript ERE>
# Checks the rc, the posts (pending, then one success of at most 140 characters), the log's fallback line and the make calls
# (STUB_MAKES then STUB_GMAKES). Sets $why; preport prints the case's verdict.
pcase() {
  why=
  test "$rc" = "$2" || why="rc $rc, want $2"
  test "$(cut -d' ' -f1 "$STUB_POSTS" | tr '\n' ' ')" = 'pending success ' || why="$why; posts: $(cut -d' ' -f1-2 "$STUB_POSTS" | tr '\n' ' ')"
  n=$(sed -n 's/^success \([0-9]*\) .*/\1/p' "$STUB_POSTS")
  if [ -n "$n" ] && [ "$n" -le 140 ]; then :; else why="$why; success description length ${n:-none}"; fi
  grep -Eq "^success [0-9]+ $5" "$STUB_POSTS" || why="$why; no success description /$5/"
  if [ "$3" = none ]; then
    if grep -Eq 'FALLBACK|SERIAL' "$STUB_POSTS" "$pad$1.log"; then why="$why; a fallback in a profiled run"; fi
  else
    grep -qx "rig-check FALLBACK $3" "$pad$1.log" || why="$why; no log line 'rig-check FALLBACK $3'"
    grep -q "SERIAL FALLBACK: $3" "$STUB_POSTS" || why="$why; no 'SERIAL FALLBACK: $3' in the post"
  fi
  if [ "$4" = 1 ]; then
    if [ ! -s "$STUB_GMAKES" ]; then why="$why; gmake was not called"; fi
  elif [ -s "$STUB_GMAKES" ]; then why="$why; gmake was called"; fi
  if ! cat "$STUB_MAKES" "$STUB_GMAKES" | grep -Eq "$6"; then
    why="$why; make calls [$(tr '\n' ' ' < "$STUB_MAKES")] [$(tr '\n' ' ' < "$STUB_GMAKES")], want /$6/"
  fi
  case "$3" in profile-off|profile-absent) if grep -q 'SHELL=' "$STUB_MAKES"; then why="$why; the profiler ran"; fi ;; esac
}
preport() { if [ -z "$why" ]; then echo "rig-check control $1: ok"; else why=${why#; }; echo "rig-check control $1: FAIL ($why)"; fails=$((fails + 1)); fi; }
# profile-on: the default. The PR head has the instrument and gmake is on PATH: the profiled run writes its raw rows beside
# the log and the summary into it, and no fallback line.
prun profile-on gmake copy unset
pcase profile-on 0 none 1 'make test green on the Studio in ' 'SHELL=[^ ]*timed_recipe_shell\.sh .*-k test$'
if [ -f "$pad"profile-on.profile/profile.tsv ] && grep -q '^totals' "$pad"profile-on.log; then :; else why="$why; no profile.tsv or summary in the log"; fi
preport profile-on
# profile-off: RIG_PROFILE=0 is plain make -k test, the fallback line, and a marked success.
prun profile-off gmake copy 0
pcase profile-off 0 profile-off 0 'make test green \(SERIAL FALLBACK: profile-off\) on the Studio in ' '^-k test$'
preport profile-off
# profile-absent: an older PR head without the instrument is plain make -k test, with its own fallback line and marker.
prun profile-absent gmake none unset
pcase profile-absent 0 profile-absent 0 'make test green \(SERIAL FALLBACK: profile-absent\) on the Studio in ' '^-k test$'
preport profile-absent
# gmake-missing: the instrument is present and no gmake is on PATH; the profiler runs on the system make (3.81).
prun gmake-missing nogmake copy unset
pcase gmake-missing 0 gmake-missing 0 'make test green \(SERIAL FALLBACK: gmake-missing\) on the Studio in ' 'SHELL=[^ ]*timed_recipe_shell\.sh SUITE_TARGET=\$@ -k test$'
if (PATH=$NOGMAKE; command -v gmake) >/dev/null 2>&1; then why="$why; gmake is on the PATH of this case"; fi
preport gmake-missing
# profile-trace: RIG_TRACE=1 on the profiled path adds --trace to the gmake run (the traced baseline, AC3, depends on it).
prun profile-trace gmake copy unset 1
pcase profile-trace 0 none 1 'make test green on the Studio in ' 'SHELL=[^ ]*timed_recipe_shell\.sh .*--trace -k test$'
preport profile-trace
# profile-red: a red profiled run still closes its log with the summary, and posts the failure.
PRUN_FAIL='test'; prun profile-red gmake copy unset; PRUN_FAIL=none
why=
test "$rc" = 1 || why="rc $rc, want 1"
test "$(cut -d' ' -f1 "$STUB_POSTS" | tr '\n' ' ')" = 'pending failure ' || why="$why; posts: $(cut -d' ' -f1-2 "$STUB_POSTS" | tr '\n' ' ')"
grep -Eq '^failure [0-9]+ 01234567: make test failed \(rc 1; bound 7200s\); no failing target in the log' "$STUB_POSTS" || why="$why; no failure description"
grep -q '^totals' "$pad"profile-red.log || why="$why; no summary totals in the log"
preport profile-red
# golden-keeps-profile: the nightly runs the full make test, then --golden-only, on the same commit and RIG_DIR. The golden
# half must not delete the full half's <dir>.profile/ (the raw rows).
prun golden-keeps-profile gmake copy unset
gk=
test "$rc" = 0 || gk="full rc $rc"
if [ -f "$pad"golden-keeps-profile.profile/profile.tsv ]; then :; else gk="$gk; no profile after the full run"; fi
rc=0; ( STUB_VERSION="AILANG v0.54.14" STUB_MAKE_FAIL=none STUB_MAKE_HANG=none RIG_NO_STATUS=0 RIG_DIR="$pad"golden-keeps-profile PATH="$T/bin:$PATH" sh "$RIG" 7 --golden-only ) > "$T/out" 2>&1 || rc=$?
test "$rc" = 0 || gk="$gk; golden rc $rc"
if [ -f "$pad"golden-keeps-profile.profile/profile.tsv ]; then :; else gk="$gk; the golden half deleted <dir>.profile"; fi
why=$gk; preport golden-keeps-profile
# caller-poison: the whole control again under a caller's overrides; it must stay green (D-126, iteration 52). The profile
# overrides (RIG_PROFILE, RIG_TRACE) and the profiler's top-target variable are caller values too.
n=26
if [ -z "${RIG_CHECK_NESTED:-}" ]; then
  n=27; nrc=0
  # The profiler sets TMPDIR to $out/tmp inside its long --out path (its rows sit beside the log).
  # The control must still run with a caller's TMPDIR of at least 110 characters (iteration 95).
  longtmp="$T/caller-tmp"; while [ ${#longtmp} -lt 110 ]; do longtmp="${longtmp}x"; done; mkdir "$longtmp"
  RIG_CHECK_NESTED=1 MAKEFLAGS=k RIG_TEST_S=1234 RIG_GOLDEN_S=7 RIG_SETUP_S=9 RIG_DL_S=9 RIG_PROFILE=0 RIG_TRACE=1 SUITE_TOP_TARGET=poison TMPDIR="$longtmp" sh "$0" "$RIG" > "$T/nested.log" 2>&1 || nrc=$?
  nok=$(grep -c ': ok$' "$T/nested.log" || true)
  if [ "$nrc" = 0 ] && [ "$nok" = 26 ]; then echo "rig-check control caller-poison: ok"; else echo "rig-check control caller-poison: FAIL (rc $nrc, $nok of 26 ok)"; fails=$((fails + 1)); fi
fi
echo "rig-check control: $n cases, $fails failures"
test "$fails" = 0
