#!/bin/sh
# rig_nightly.sh: the full suite (make test + make golden) once per main commit, overnight,
# only when the Studio is free.
#
# Mark, 2026-11-03: a PR no longer waits on a ~70-minute rig run (serialised, they queued for
# hours and mostly failed on host load, not on bugs). PRs merge on the fast tier, the targeted
# gates, the cross-family evaluation and Mark's OK on a dev build; this run catches regressions
# on main once a night. The GPU is shared with local-model evals (ollama, llama-server, the 03:00
# AILANG nightly eval), so it starts only when the GPU and the CPU are idle.
#
#   tools/rig_nightly.sh                       # launchd, several times a night; a no-op unless
#                                              # main has an unchecked commit and the rig is free
#   RIG_NIGHTLY_FORCE=1 tools/rig_nightly.sh   # skip the idle and time-window checks
#
# On failure it opens (or comments on) a GitHub issue labelled nightly-rig with the failing lines;
# on the next green run it closes it. launchd: tools/launchd/dev.stapledon.rig-nightly.plist.
set -eu
REPO=sunholo-data/stapledons-godot
GPU_MAX=${RIG_NIGHTLY_GPU_MAX:-25}     # % GPU utilisation, every sample must be below
LOAD_MAX=${RIG_NIGHTLY_LOAD_MAX:-16}   # 5-minute load average (40 cores)
SAMPLES=${RIG_NIGHTLY_SAMPLES:-6}      # GPU samples, 20 s apart
RIG_JSON=http://127.0.0.1:8941/rig.json
here=$(cd "$(dirname "$0")" && pwd)
log() { echo "rig-nightly $(date '+%F %T'): $*"; }

sha=$(gh api "repos/$REPO/commits/main" -q .sha)
short=$(printf %s "$sha" | cut -c1-8)

# One run per main commit. A pending status older than 3 h is a run that died: try again.
st=$(gh api "repos/$REPO/commits/$sha/statuses" -q '[.[]|select(.context=="rig/full")][0] | (.state // "") + " " + (.updated_at // "")')
state=${st%% *}; at=${st#* }
case "$state" in
  success|failure) log "main $short already has rig/full $state"; exit 0 ;;
  pending)
    age=$(( $(date +%s) - $(date -j -u -f '%Y-%m-%dT%H:%M:%SZ' "$at" +%s 2>/dev/null || echo 0) ))
    [ "$age" -gt 10800 ] || { log "main $short rig/full pending ($((age / 60)) min)"; exit 0; } ;;
esac

if [ "${RIG_NIGHTLY_FORCE:-0}" != 1 ]; then
  # 01:45-04:00 belongs to the AILANG nightly eval (03:00) and the agent export (03:30).
  hm=$(date +%H%M)
  if [ "$hm" -ge 0145 ] && [ "$hm" -lt 0400 ]; then log "eval window, not starting"; exit 0; fi
  if pgrep -f "rig_chec[k]\.sh" > /dev/null; then log "a rig check is already running"; exit 0; fi
  load=$(sysctl -n vm.loadavg | awk '{print int($3)}')
  [ "$load" -lt "$LOAD_MAX" ] || { log "load $load >= $LOAD_MAX, not starting"; exit 0; }
  i=0
  while [ $i -lt "$SAMPLES" ]; do
    gpu=$(curl -s --max-time 10 "$RIG_JSON" | /usr/bin/python3 -c 'import json,sys; print(int(json.load(sys.stdin)["system"]["gpu"]["utilization"]))' 2>/dev/null || echo 100)
    [ "$gpu" -lt "$GPU_MAX" ] || { log "GPU at ${gpu}% (>= $GPU_MAX), not starting"; exit 0; }
    i=$((i + 1)); [ $i -lt "$SAMPLES" ] && sleep 20
  done
fi

log "main $short: make test + make golden"
out=$(mktemp -t rig-nightly)
rc=0; sh "$here/rig_check.sh" "$sha" --golden > "$out" 2>&1 || rc=$?
cat "$out"
rlog=$(sed -n 's/.*; log \(.*\.log\)$/\1/p' "$out" | head -1)

open=$(gh issue list --repo "$REPO" --label nightly-rig --state open --json number -q '.[0].number // ""')
if [ $rc = 0 ]; then
  log "main $short green"
  [ -n "$open" ] && gh issue close "$open" --repo "$REPO" --comment "Green again on main at $short: $(tail -1 "$out")" > /dev/null
else
  body=$(mktemp -t rig-nightly-body)
  {
    echo "The nightly full suite failed on main at $sha."
    echo
    echo "$(tail -1 "$out")"
    echo
    echo "Failing lines (log on the Studio: \`$rlog\`):"
    echo
    echo '```'
    if [ -n "$rlog" ] && [ -f "$rlog" ]; then
      grep -nE '(^|[^a-z])(FAIL|SCRIPT ERROR|\*\*\*)' "$rlog" | grep -vE '=FAIL$|0 fail' | tail -30
      echo '...'
      tail -20 "$rlog"
    fi
    echo '```'
    echo
    echo "Find the merge that broke it with \`git log\` since the last green nightly; fix forward or revert."
  } > "$body"
  if [ -n "$open" ]; then
    gh issue comment "$open" --repo "$REPO" --body-file "$body" > /dev/null
  else
    gh label create nightly-rig --repo "$REPO" --color B60205 --description "main failed the nightly full suite" > /dev/null 2>&1 || true
    gh issue create --repo "$REPO" --label nightly-rig --title "Nightly rig: main red at $short" --body-file "$body" > /dev/null
  fi
  log "main $short FAILED (issue filed)"
fi
rm -f "$out"
exit $rc
