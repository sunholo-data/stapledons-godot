#!/bin/sh
# Row 7o and D-126 control: tools/rig_check.sh must post only descriptions GitHub accepts (at most 140
# characters), keep the log pointer in a failure description whenever it fits, and report a
# refused failure or success post on stdout with a nonzero exit. No network: gh, git and make
# are stubs on PATH; the stub gh refuses a long description the way GitHub does (HTTP 422).
#   sh tools/test_rig_check.sh [path/to/rig_check.sh]
set -eu
unset RIG_TEST_S RIG_GOLDEN_S   # hermetic: a caller's watchdog override must not reach the cases (iteration 52)
RIG=$(cd "$(dirname "${1:-tools/rig_check.sh}")" && pwd -P)/$(basename "${1:-tools/rig_check.sh}")
T=$(mktemp -d "${TMPDIR:-/tmp}/rig-check-control.XXXXXX")
trap 'rm -rf "$T"' EXIT
test "${#T}" -le 100   # the clone-red-pointer case needs a log path short enough for the pointer to fit
export STUB_POSTS="$T/posts" STUB_SHA=0123456789abcdef0123456789abcdef01234567
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
printf '#!/bin/sh\ncase " $* " in *" $STUB_MAKE_FAIL "*) exit 1 ;; esac\n' > "$T/bin/make"
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
run make-test-red 1 failure '01234567: make test failed or ran over 7200s$' '^rig-check: FAIL: make test failed.*\.log\)$' 'AILANG v0.54.14' test "$pad"
run long-reason 1 failure "01234567: runtime is 'AILANG 0{100}" '^rig-check: FAIL: runtime is ' "AILANG $long" none "$T/r2"
run long-success 0 success 'make test green on the Studio' '^rig-check: ok, 01234567 green' "AILANG v0.54.14 $long" none "$T/r3"
# A short log path: the pointer fits, so it is in the description.
run clone-red-pointer 1 failure '01234567: clone failed \(log: .*/c\.log\)$' '^rig-check: FAIL: clone failed \(log: .*/c\.log\)$' 'AILANG v0.54.14' none "$T/c" clone
# An explicit RIG_TEST_S still sets the watchdog (the escape hatch, D-126).
run watchdog-override 1 failure '01234567: make test failed or ran over 60s$' '^rig-check: FAIL: make test failed or ran over 60s ' 'AILANG v0.54.14' test "$pad" '' 60
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
# caller-poison: the whole control again under a caller's overrides; it must stay green (D-126, iteration 52).
n=8
if [ -z "${RIG_CHECK_NESTED:-}" ]; then
  n=9; nrc=0
  RIG_CHECK_NESTED=1 RIG_TEST_S=1234 RIG_GOLDEN_S=7 sh "$0" "$RIG" > "$T/nested.log" 2>&1 || nrc=$?
  nok=$(grep -c ': ok$' "$T/nested.log" || true)
  if [ "$nrc" = 0 ] && [ "$nok" = 8 ]; then echo "rig-check control caller-poison: ok"; else echo "rig-check control caller-poison: FAIL (rc $nrc, $nok of 8 ok)"; fails=$((fails + 1)); fi
fi
echo "rig-check control: $n cases, $fails failures"
test "$fails" = 0
