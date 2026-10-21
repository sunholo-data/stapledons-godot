#!/bin/sh
# rig_check.sh: the full suite on the Studio, posted to GitHub as the rig/full commit status.
# Rig-first merges (Mark, 2026-10-19): GitHub runs the fast clean-Linux tier (make ci-fast);
# a PR merges on a green rig/full, which is the whole of make test (plus make golden for
# visual changes, which needs a GPU window) on the PR's exact head.
#
#   tools/rig_check.sh <PR number | ref> [--golden]
#
# It clones fresh under RIG_DIR (default ${TMPDIR}/rig-check/<sha>; never the attended checkout),
# stages the pinned runtime if the clone lacks it, fetches the sky textures, runs the suite under
# a watchdog (macOS has no timeout), keeps the log, and posts pending, then success or failure.
# RIG_NO_STATUS=1 skips the status posts (a dry run on someone else's PR, say).
set -eu
REPO=sunholo-data/stapledons-godot
TEST_S=${RIG_TEST_S:-5400}   # make test is ~50 min on the Studio
GOLDEN_S=${RIG_GOLDEN_S:-1800}

usage() { echo "usage: $0 <PR number | ref> [--golden]"; exit 2; }
[ $# -ge 1 ] || usage
target=$1; shift
golden=0
for a in "$@"; do case "$a" in --golden) golden=1 ;; *) usage ;; esac; done

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
  gh api "repos/$REPO/statuses/$sha" -f state="$1" -f context=rig/full -f description="${2:0:140}" > /dev/null
}

suite="make test"; [ $golden = 1 ] && suite="make test + make golden"
echo "rig-check: $target -> $short in $dir ($suite); log $log"
status pending "$suite running on the Studio"

fail() { status failure "$1 (log: rig-check/$short.log on the Studio)"; echo "rig-check: FAIL: $1"; exit 1; }

rm -rf "$dir"; mkdir -p "$(dirname "$dir")"
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
perl -e 'alarm shift; exec @ARGV' "$TEST_S" make test >> "$log" 2>&1 || fail "make test failed or ran over ${TEST_S}s"
if [ $golden = 1 ]; then
  perl -e 'alarm shift; exec @ARGV' "$GOLDEN_S" make golden >> "$log" 2>&1 || fail "make golden failed or ran over ${GOLDEN_S}s"
fi
mins=$(( ($(date +%s) - start + 59) / 60 ))
status success "$suite green on the Studio in ${mins} min ($(ailang --version 2>&1 | head -1))"
echo "rig-check: ok, $short green ($suite, ${mins} min)"
