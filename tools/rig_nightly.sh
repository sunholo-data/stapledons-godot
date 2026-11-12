#!/bin/sh
# rig_nightly.sh: the full suite once per main commit, overnight: make test (rig/full) when the CPU
# is free, make golden (rig/golden) when the GPU is free too.
#
# Mark, 2026-11-03: a PR no longer waits on a ~70-minute rig run (serialised, they queued for
# hours and mostly failed on host load, not on bugs). PRs merge on the fast tier, the targeted
# gates, the cross-family evaluation and Mark's OK on a dev build; this run catches regressions
# on main once a night. The GPU is shared with local-model evals (ollama, llama-server, the 03:00
# AILANG nightly eval), so make golden starts only when the GPU is idle; make test needs only the CPU.
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

# context_state CONTEXT: success; failure (GitHub's error counts as failure); pending (a pending post
# younger than 3 h: a run in progress); "" for no verdict (no post, or a pending older than 3 h, a run
# that died, so it runs again); unknown (GitHub unreadable, or a state this script does not know).
context_state() {
  # "unknown" when GitHub cannot be read: never taken as no verdict (no run) or as not red (no close).
  st=$(gh api "repos/$REPO/commits/$sha/statuses" -q "[.[]|select(.context==\"$1\")][0] | (.state // \"\") + \" \" + (.updated_at // \"\")") || { echo unknown; return 0; }
  state=${st%% *}; at=${st#* }
  case "$state" in
    success|failure) echo "$state" ;;
    error) echo failure ;;
    "") echo "" ;;
    pending)
      age=$(( $(date +%s) - $(date -j -u -f '%Y-%m-%dT%H:%M:%SZ' "$at" +%s 2>/dev/null || echo 0) ))
      if [ "$age" -gt 10800 ]; then echo ""; else echo pending; fi ;;
    *) echo unknown ;;
  esac
}

# Two halves, at most one per launch (2026-11-06): make test (headless, CPU) as rig/full whenever the
# CPU is free, then make golden (GPU window) as rig/golden once the GPU is idle too. Gating both on an
# idle GPU let the overnight ollama evals (88-100% GPU from 22:30 to 06:15) block every night after
# 2026-11-04, so main went unchecked; make test barely touches the GPU.
full=$(context_state rig/full)
golden=$(context_state rig/golden)
case "$full $golden" in *unknown*) log "main $short: could not read the commit statuses, not starting"; exit 1 ;; esac
case "$full" in
  "") phase=test ;;
  pending) log "main $short rig/full pending"; exit 0 ;;
  *) case "$golden" in
       "") phase=golden ;;
       *) log "main $short already has rig/full $full, rig/golden ${golden}"; exit 0 ;;
     esac ;;
esac

if [ "${RIG_NIGHTLY_FORCE:-0}" != 1 ]; then
  # 01:45-04:00 belongs to the AILANG nightly eval (03:00) and the agent export (03:30).
  hm=$(date +%H%M)
  if [ "$hm" -ge 0145 ] && [ "$hm" -lt 0400 ]; then log "eval window, not starting"; exit 0; fi
  if pgrep -f "rig_chec[k]\.sh" > /dev/null; then log "a rig check is already running"; exit 0; fi
  load=$(sysctl -n vm.loadavg | awk '{print int($3)}')
  [ "$load" -lt "$LOAD_MAX" ] || { log "load $load >= $LOAD_MAX, not starting $phase"; exit 0; }
  if [ $phase = golden ]; then
    i=0
    while [ $i -lt "$SAMPLES" ]; do
      gpu=$(curl -s --max-time 10 "$RIG_JSON" | /usr/bin/python3 -c 'import json,sys; print(int(json.load(sys.stdin)["system"]["gpu"]["utilization"]))' 2>/dev/null || echo 100)
      [ "$gpu" -lt "$GPU_MAX" ] || { log "rig/full $full; GPU at ${gpu}% (>= $GPU_MAX), not starting make golden"; exit 0; }
      i=$((i + 1)); [ $i -lt "$SAMPLES" ] && sleep 20
    done
  fi
fi

out=$(mktemp -t rig-nightly)
rc=0
if [ $phase = test ]; then
  ctx=rig/full; other=rig/golden; suite="make test"
  log "main $short: make test"
  sh "$here/rig_check.sh" "$sha" > "$out" 2>&1 || rc=$?
else
  ctx=rig/golden; other=rig/full; suite="make golden"
  log "main $short: make golden"
  sh "$here/rig_check.sh" "$sha" --golden-only > "$out" 2>&1 || rc=$?
fi
cat "$out"
rlog=$(sed -n 's/.*; log \(.*\.log\)$/\1/p' "$out" | head -1)

open=$(gh issue list --repo "$REPO" --label nightly-rig --state open --json number -q '.[0].number // ""')
if [ $rc = 0 ]; then
  log "main $short $suite green"
  # Close only when the other half is green or has not run on this commit (not red, not unreadable).
  [ -n "$open" ] && { o=$(context_state $other); [ "$o" = success ] || [ -z "$o" ]; } && gh issue close "$open" --repo "$REPO" --comment "Green again on main at $short: $(tail -1 "$out")" > /dev/null
else
  body=$(mktemp -t rig-nightly-body)
  {
    echo "The nightly $suite ($ctx) failed on main at $sha."
    echo
    echo "$(tail -1 "$out")"
    echo
    sed -n "s/^rig-check: failed targets /Failing targets /p" "$out" | head -1   # 7ag: every red target, in run order
    echo
    echo "Failing lines (log on the Studio: \`$rlog\`):"
    echo
    echo '```'
    if [ -n "$rlog" ] && [ -f "$rlog" ]; then
      # 7ag: for each top-level make error line, the up-to-20 matching lines before it (make -k reports many).
      awk '/^g?make: \*\*\* / { for (i = 1; i <= c; i++) print b[i]; print FNR ":" $0; c = 0; next }
        /(^|[^a-z])(FAIL|SCRIPT ERROR|\*\*\*)/ && !/=FAIL$|0 fail/ { if (c == 20) { for (i = 1; i < 20; i++) b[i] = b[i + 1]; c-- } b[++c] = FNR ":" $0 }' "$rlog" | cut -c1-300 | head -200
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
  log "main $short $suite FAILED (issue filed)"
fi
rm -f "$out"
exit $rc
