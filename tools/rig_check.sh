#!/bin/sh
# rig_check.sh: the full suite on the Studio, posted to GitHub as the rig/full commit status
# (rig/golden for --golden-only).
# Since 2026-11-03 (Mark) it runs nightly on main (tools/rig_nightly.sh) rather than per PR: a PR
# merges on the fast tier, its targeted gates, the cross-family evaluation and Mark's OK on a dev
# build. Run it by hand on a PR only when a change is risky enough to want the whole suite first
# (make test, plus make golden for visual changes, which needs a GPU window).
#
#   tools/rig_check.sh <PR number | ref> [--golden | --golden-only]
#
# --golden-only runs make golden alone and posts rig/golden instead of rig/full: the nightly runs the
# headless make test whenever the CPU is free and holds the GPU half back until the GPU is (2026-11-06).
#
# It clones fresh under RIG_DIR (default ${TMPDIR}/rig-check/<sha>; never the attended checkout),
# stages the pinned runtime if the clone lacks it, fetches the sky textures, runs the suite under
# a watchdog (macOS has no timeout), keeps the log, and posts pending, then success or failure.
# RIG_NO_STATUS=1 skips the status posts (a dry run on someone else's PR, say).
set -eu
REPO=sunholo-data/stapledons-godot
TEST_S=${RIG_TEST_S:-7200}   # make test is 66-90 min on the Studio; D-126 C (Mark, 2026-10-28)
GOLDEN_S=${RIG_GOLDEN_S:-1800}

usage() { echo "usage: $0 <PR number | ref> [--golden | --golden-only]"; exit 2; }
[ $# -ge 1 ] || usage
target=$1; shift
golden=0; tests=1; ctx=rig/full
for a in "$@"; do case "$a" in --golden) golden=1 ;; --golden-only) golden=1; tests=0; ctx=rig/golden ;; *) usage ;; esac; done

case "$target" in
  *[!0-9]*) sha=$(gh api "repos/$REPO/commits/$target" -q .sha) ;;
  *) sha=$(gh pr view "$target" --repo "$REPO" --json headRefOid -q .headRefOid) ;;
esac
[ -n "$sha" ] || { echo "rig-check: could not resolve $target"; exit 2; }
short=$(printf %s "$sha" | cut -c1-8)
dir=${RIG_DIR:-${TMPDIR:-/tmp}/rig-check/$sha}
log="$dir.log"

status() {
  [ "${RIG_NO_STATUS:-0}" = 1 ] && return 0
  # GitHub refuses a description over 140 characters (row 7o): cut every post to fit.
  gh api "repos/$REPO/statuses/$sha" -f state="$1" -f context="$ctx" -f description="$(printf %s "$2" | cut -c1-140)" > /dev/null
}

suite="make test"; [ $golden = 1 ] && suite="make test + make golden"; [ $tests = 0 ] && suite="make golden"
echo "rig-check: $target -> $short in $dir ($suite); log $log"
status pending "$suite running on the Studio"

fail() {
  echo "rig-check: FAIL: $1 (log: $log)"
  d="$short: $1"   # the log pointer goes in too whenever it fits GitHub's 140 characters (row 7o)
  if [ $((${#d} + ${#log} + 8)) -le 140 ]; then d="$d (log: $log)"; fi
  status failure "$d" || echo "rig-check: could not post the failure status"
  exit 1
}

rm -rf "$dir"; mkdir -p "$(dirname "$dir")"
# The clone goes when the run ends, pass or fail; the log ($dir.log) stays. 41 kept clones once
# filled 40 GB (2026-11-03). RIG_KEEP=1 keeps it for debugging.
[ "${RIG_KEEP:-0}" = 1 ] || trap 'cd / && rm -rf "$dir"' EXIT
git clone --quiet "https://github.com/$REPO.git" "$dir" || fail "clone failed"
cd "$dir"
git fetch --quiet origin "$sha" && git checkout --quiet --detach "$sha" || fail "checkout of $short failed"

# The pin is the Makefile's AILANG_RELEASE (ci.yml's AILANG_VERSION moves with it). A runtime that is
# absent or off the pin is restaged: a stale v0.54.11 runtime once failed make test on parse errors.
pin=$(sed -n 's/^AILANG_RELEASE ?= *//p' Makefile)
[ -n "$pin" ] || fail "no AILANG_RELEASE pin in the Makefile"
have=$(runtime/bin/ailang --version 2>/dev/null | head -1 || true)
case "$have" in
  *"${pin#v}"*) echo "rig-check: runtime $pin" > "$log" ;;
  *) echo "rig-check: staging runtime $pin (had: ${have:-none})" > "$log"
     make runtime >> "$log" 2>&1 || fail "make runtime failed" ;;
esac
have=$(runtime/bin/ailang --version 2>/dev/null | head -1 || true)
case "$have" in *"${pin#v}"*) ;; *) fail "runtime is '$have', pin is $pin" ;; esac
PATH=$PWD/runtime/bin:$PATH; export PATH
make sky-assets >> "$log" 2>&1 || fail "make sky-assets failed"

start=$(date +%s)
[ $tests = 0 ] || perl -e 'alarm shift; exec @ARGV' "$TEST_S" make test >> "$log" 2>&1 || fail "make test failed or ran over ${TEST_S}s"
if [ $golden = 1 ]; then
  perl -e 'alarm shift; exec @ARGV' "$GOLDEN_S" make golden >> "$log" 2>&1 || fail "make golden failed or ran over ${GOLDEN_S}s"
fi
mins=$(( ($(date +%s) - start + 59) / 60 ))
echo "rig-check: ok, $short green ($suite, ${mins} min)"
status success "$suite green on the Studio in ${mins} min ($(ailang --version 2>&1 | head -1))" || { echo "rig-check: could not post the success status"; exit 1; }
