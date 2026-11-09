#!/bin/sh
# Row 7ag control: rig/full keeps going past a red make test target. tools/rig_check.sh runs make -k test, names
# every failing target (stdout and the 140-character status), still exits red; tools/rig_nightly.sh lists them all
# in the nightly issue. Real GNU make on fixture suites (every distinct make on PATH); gh, git and the setup makes
# are stubs, so no network.
#   sh tools/test_rig_keep_going.sh ROOT      (ROOT: the checkout whose tools/rig_check.sh and rig_nightly.sh are tested)
set -u
# An outer make's -k (the rig's own make -k test) must not reach the fixture makes: it would keep a mutant that
# drops -k going (iteration 56: outer MAKEFLAGS/MAKELEVEL reached rig-check fixtures).
unset MAKELEVEL MAKEFLAGS MFLAGS MAKEOVERRIDES GNUMAKEFLAGS MAKE_TERMOUT MAKE_TERMERR
unset RIG_TEST_S RIG_GOLDEN_S RIG_SETUP_S RIG_DL_S RIG_DIR RIG_KEEP RIG_NIGHTLY_FORCE
[ $# = 1 ] && [ -f "$1/tools/rig_check.sh" ] && [ -f "$1/tools/rig_nightly.sh" ] || { echo "usage: $0 ROOT"; exit 2; }
ROOT=$(cd "$1" && pwd -P)
T=$(mktemp -d "${TMPDIR:-/tmp}/rig-keep-going.XXXXXX") || exit 1
trap 'rm -rf "$T"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM HUP
mkdir "$T/bin" "$T/n" "$T/tmp"
cp "$ROOT/tools/rig_check.sh" "$ROOT/tools/rig_nightly.sh" "$T/n/"   # side by side, as the launchd job runs them
export STUB_SHA=0123456789abcdef0123456789abcdef01234567 STUB_POSTS="$T/posts" STUB_BODY="$T/body" TMPDIR="$T/tmp"
cat > "$T/bin/gh" <<'STUB'
#!/bin/sh
case "$1 $2" in
  "api repos/sunholo-data/stapledons-godot/commits/$STUB_SHA/statuses") echo " " ;;          # no verdict yet
  "api repos/sunholo-data/stapledons-godot/statuses/$STUB_SHA")
    for a; do case "$a" in state=*) s=${a#state=} ;; description=*) d=${a#description=} ;; esac; done
    echo "$s $(printf %s "$d" | wc -m | tr -d ' ') $d" >> "$STUB_POSTS" ;;
  "api "*) echo "$STUB_SHA" ;;                                                               # commits/main, commits/<sha>
  "pr view") echo "$STUB_SHA" ;;
  "issue list") ;;                                                                           # no open issue
  "issue create"|"issue comment") while [ $# -gt 0 ]; do [ "$1" = --body-file ] && cp "$2" "$STUB_BODY"; shift; done ;;
esac
exit 0
STUB
cat > "$T/bin/git" <<'STUB'
#!/bin/sh
[ "$1" = clone ] || exit 0
for d; do :; done
mkdir -p "$d/runtime/bin"; cp "$STUB_SUITE" "$d/Makefile"
printf '#!/bin/sh\necho "AILANG v0.54.14"\n' > "$d/runtime/bin/ailang"; chmod +x "$d/runtime/bin/ailang"
STUB
# The setup makes are stubbed; make test runs the fixture suite on the real make under test.
cat > "$T/bin/make" <<'STUB'
#!/bin/sh
case " $* " in *" test "*) exec "$REAL_MAKE" "$@" ;; esac
exit 0
STUB
chmod +x "$T/bin/gh" "$T/bin/git" "$T/bin/make"
# Two independent red targets around a green one. gamma fails through a nested make (a make[1] line too) after 40
# FAIL lines, so the old tail -30 of the nightly would drop alpha entirely.
printf '%s\n' 'AILANG_RELEASE ?= v0.54.14' 'test: alpha-check beta-ok gamma-check' \
  'alpha-check: ; @echo "alpha: FAIL one"; exit 1' 'beta-ok: ; @echo "beta: 3 passed, 0 failures"' \
  'gamma-check: ; @$(MAKE) --no-print-directory gamma-sub' 'gamma-sub: ; @i=0; while [ $$i -lt 40 ]; do i=$$((i + 1)); echo "gamma: FAIL $$i"; done; exit 1' > "$T/two.mk"
printf '%s\n' 'AILANG_RELEASE ?= v0.54.14' 'test: alpha-ok beta-ok' 'alpha-ok beta-ok: ; @echo "$@: 1 passed, 0 failures"' > "$T/green.mk"
{ echo 'AILANG_RELEASE ?= v0.54.14'; printf 'test:'; for i in 1 2 3 4 5 6 7 8 9 10 11 12; do printf ' a-rather-long-failing-target-%s' "$i"; done; echo
  echo 'a-rather-long-failing-target-%: ; @echo "$@: FAIL"; exit 1'; } > "$T/many.mk"
# hundred: 120 reds (a 3-digit count). Under the 140 budget n1 (36) fits and n2 (37) does not; a suffix reserved at the old
# fixed 9 lets n2 in and overflows to 141. longname: the first red alone is longer than the budget, so it is cut.
n1=n1-$(printf %033d 0); n2=n2-$(printf %034d 0); ln=x-$(printf %098d 0)
{ echo 'AILANG_RELEASE ?= v0.54.14'; printf 'test: %s %s' "$n1" "$n2"; i=3; while [ $i -le 120 ]; do printf ' r-%s' "$i"; i=$((i + 1)); done; echo
  printf '%s %s r-%%: ; @exit 1\n' "$n1" "$n2"; } > "$T/hundred.mk"
printf '%s\n' 'AILANG_RELEASE ?= v0.54.14' "test: $ln b-red" "$ln b-red: ; @exit 1" > "$T/longname.mk"
# reason: the failure reason rig_check printed (stdout), before status() cuts anything to 140 characters
reason() { sed -n 's/^rig-check: FAIL: \(.*\) (log: .*)$/\1/p' "$T/out"; }
fails=0; cases=0
ok() { cases=$((cases + 1)); echo "rig-keep-going control $1 [$V]: ok"; }
no() { cases=$((cases + 1)); fails=$((fails + 1)); echo "rig-keep-going control $1 [$V]: FAIL ($2)"; }
# rig <suite> <RIG_DIR name>: rig_check.sh on the fixture; rc in $rc, stdout in $T/out, posts in $STUB_POSTS
rig() { : > "$STUB_POSTS"; rc=0; STUB_SUITE="$T/$1.mk" RIG_DIR="$T/r/$2" PATH="$T/bin:$PATH" sh "$T/n/rig_check.sh" 7 ${3:+"$3"} > "$T/out" 2>&1 || rc=$?; }
# nightly <suite>: rig_nightly.sh beside rig_check.sh, as launchd runs it; rc in $rc, stdout in $T/out, body in $STUB_BODY
nightly() { : > "$STUB_POSTS"; rm -f "$STUB_BODY"; rc=0; STUB_SUITE="$T/$1.mk" RIG_NIGHTLY_FORCE=1 PATH="$T/bin:$PATH" sh "$T/n/rig_nightly.sh" > "$T/out" 2>&1 || rc=$?; }
makes=; versions=
for c in make gmake; do
  p=$(command -v "$c" 2>/dev/null) || continue; v=$("$p" --version 2>/dev/null | sed -n 1p)
  case "$v" in 'GNU Make '*) ;; *) continue ;; esac
  printf '%s\n' "$versions" | grep -Fqx "$v" && continue
  makes="$makes $p"; versions="$versions$v
"
done
[ -n "$makes" ] || { echo 'rig-keep-going control: FAIL (no GNU make on PATH)'; exit 1; }
for REAL_MAKE in $makes; do
  export REAL_MAKE; V=$("$REAL_MAKE" --version | sed -n '1s/GNU Make //p')
  # two-red: both reds named on stdout and in the one failure post, the green target between them ran, rc 1.
  rig two two-$V; L="$T/r/two-$V.log"
  why=
  grep -q '^alpha: FAIL one$' "$L" || why="log capture is not live"   # positive control for the log reads below
  test "$rc" = 1 || why="$why; rc $rc"
  grep -qx 'rig-check: failed targets (2): alpha-check gamma-check' "$T/out" || why="$why; stdout list"
  test "$(grep -c '^beta: 3 passed, 0 failures$' "$L")" = 1 || why="$why; beta-ok did not run (no keep-going)"
  test "$(cut -d' ' -f1 "$STUB_POSTS" | tr '\n' ' ')" = 'pending failure ' || why="$why; posts"
  grep -Eqx 'failure [0-9]+ 01234567: make test failed \(rc 2; bound 7200s\); 2 red: alpha-check gamma-check( \(log: .*\))?' "$STUB_POSTS" || why="$why; description"
  if [ -z "$why" ]; then ok two-red; else no two-red "$why"; fi
  # golden-log-kept: a later --golden-only run on the same commit writes its own log; the rig/full log survives.
  cksum < "$L" > "$T/before"; rig green two-$V --golden-only; why=
  test "$rc" = 0 || why="rc $rc"
  grep -q "; log $T/r/two-$V.golden.log\$" "$T/out" || why="$why; golden log path"
  cksum < "$L" | cmp -s - "$T/before" || why="$why; the rig/full log changed"
  if [ -z "$why" ]; then ok golden-log-kept; else no golden-log-kept "$why"; fi
  # green: rc 0 and a success post, no failed-targets line (positive: the ok line is there).
  rig green green-$V; why=
  test "$rc" = 0 || why="rc $rc"
  grep -q '^rig-check: ok, 01234567 green (make test' "$T/out" || why="$why; no ok line"
  test "$(grep -c '^rig-check: failed targets' "$T/out")" = 0 || why="$why; a failed-targets line"
  test "$(cut -d' ' -f1 "$STUB_POSTS" | tr '\n' ' ')" = 'pending success ' || why="$why; posts"
  if [ -z "$why" ]; then ok green; else no green "$why"; fi
  # many-red: 12 reds; the post fits 140 characters and says how many it left out; stdout names all 12.
  rig many many-$V; why=
  test "$rc" = 1 || why="rc $rc"
  test "$(sed -n 's/^rig-check: failed targets (12): //p' "$T/out" | wc -w | tr -d ' ')" = 12 || why="$why; stdout list"
  d=$(sed -n 's/^failure \([0-9]*\) .*/\1/p' "$STUB_POSTS")
  test -n "$d" && test "$d" -le 140 || why="$why; description length ${d:-none}"
  grep -Eq '^failure [0-9]+ 01234567: make test failed \(rc 2; bound 7200s\); 12 red: a-rather-long-failing-target-1 .* \+[0-9]+ more$' "$STUB_POSTS" || why="$why; description"
  if [ -z "$why" ]; then ok many-red; else no many-red "$why"; fi
  # hundred-red: 120 reds; the reason plus "01234567: " fits 140 exactly as written, with n1 and +119 more.
  rig hundred hundred-$V; why=; r=$(reason)
  test "$rc" = 1 || why="rc $rc"
  test -n "$r" || why="$why; no FAIL line"   # positive control: the reason capture is live
  test $((${#r} + 10)) -le 140 || why="$why; reason $((${#r} + 10)) characters"
  test "$r" = "make test failed (rc 2; bound 7200s); 120 red: $n1 +119 more" || why="$why; reason [$r]"
  test "$(sed -n 's/^rig-check: failed targets (120): //p' "$T/out" | wc -w | tr -d ' ')" = 120 || why="$why; stdout list"
  if [ -z "$why" ]; then ok hundred-red; else no hundred-red "$why"; fi
  # longname-red: the first name is longer than the budget: its first 74 characters, "...", +1 more (140 in all).
  rig longname longname-$V; why=; r=$(reason)
  test "$rc" = 1 || why="rc $rc"
  test -n "$r" || why="$why; no FAIL line"
  test $((${#r} + 10)) -le 140 || why="$why; reason $((${#r} + 10)) characters"
  test "$r" = "make test failed (rc 2; bound 7200s); 2 red: $(printf %s "$ln" | cut -c1-74)... +1 more" || why="$why; reason [$r]"
  grep -qx "rig-check: failed targets (2): $ln b-red" "$T/out" || why="$why; stdout list"
  if [ -z "$why" ]; then ok longname-red; else no longname-red "$why"; fi
  # nightly-two-red: the issue body names both targets and carries both top-level error lines.
  nightly two; why=
  test -f "$STUB_BODY" || why="no issue body"
  test "$rc" = 1 || why="$why; rc $rc"
  grep -qx 'Failing targets (2): alpha-check gamma-check' "$STUB_BODY" 2>/dev/null || why="$why; no Failing targets line"
  test "$(grep -cE '^[0-9]+:make: \*\*\* \[|^[0-9]+:g?make: \*\*\* \[' "$STUB_BODY" 2>/dev/null)" = 2 || why="$why; top-level error lines"
  grep -q '^[0-9]*:alpha: FAIL one$' "$STUB_BODY" 2>/dev/null && grep -q '^[0-9]*:gamma: FAIL 40$' "$STUB_BODY" 2>/dev/null || why="$why; failing lines"
  if [ -z "$why" ]; then ok nightly-two-red; else no nightly-two-red "$why"; fi
  # nightly-green: rc 0, no issue body (positive: the green log line is there).
  nightly green; why=
  test "$rc" = 0 || why="rc $rc"
  grep -q 'main 01234567 make test green$' "$T/out" || why="$why; no green line"
  test -f "$STUB_BODY" && why="$why; an issue body was written"
  if [ -z "$why" ]; then ok nightly-green; else no nightly-green "$why"; fi
done
echo "rig-keep-going control: $cases cases, $fails failures"
test "$fails" = 0
