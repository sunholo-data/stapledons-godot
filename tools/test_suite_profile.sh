#!/bin/sh
# Hermetic fixture control. Each case runs on every distinct GNU make on PATH.
set -u
ROOT=$(cd "$(dirname "$0")/.." && pwd -P)
T=$(mktemp -d "${TMPDIR:-/tmp}/suite-profile-control.XXXXXX") || exit 1
trap 'rm -rf "$T"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM HUP
mkdir "$T/tmp"
TMPDIR=$T/tmp; export TMPDIR
# Deterministic probes also keep sysctl sandbox restrictions out of fixtures.
mkdir "$T/probes"
cat > "$T/probes/sysctl" <<'STUB'
#!/bin/sh
case "$2" in vm.loadavg) echo '{ 2.00 2.00 2.00 }' ;; hw.ncpu) echo 4 ;; *) exit 1 ;; esac
STUB
chmod +x "$T/probes/sysctl"
PATH="$T/probes:$PATH"; export PATH
P=$ROOT/tools/suite_profile.sh
W=$ROOT/tools/timed_recipe_shell.sh
makes=; versions=; nm=0
for candidate in make gmake; do
  path=$(command -v "$candidate" 2>/dev/null) || continue
  version=$("$path" --version | sed -n '1p')
  case "$version" in 'GNU Make '*) ;; *) continue ;; esac
  printf '%s\n' "$versions" | grep -Fqx "$version" && continue
  makes="$makes $path"; versions="${versions}${version}
"; nm=$((nm + 1))
done
if [ "$nm" = 0 ]; then echo 'suite-profile control make-discovery: FAIL (GNU make required)'; exit 1; fi
if ! command -v gmake >/dev/null 2>&1; then
  echo "suite-profile control: gmake absent; ran on $(make --version | sed -n '1p') only"
fi
profile() { sh "$P" "$@"; }
run() { profile run --make "$M" --out "$D/out" "$@"; }
row() { awk -F '\t' -v t="$1" '$6==t {print; found=1} END {exit !found}' "$D/out/profile.tsv"; }
header() { sed -n "s/^$1=//p" "$D/out/header.txt"; }
# Synthetic committed-stem companions; no absolute path is stored in metadata.
record() {
  name=$1; jobs=$2; span=$3; version=${4:-4.4.1}; loads=${5:-2 3 4}
  printf '0\t%s\t1.000\t0\t1\ta\ta\n' "$((span * 1000))" > "$D/$name.tsv"
  printf 'make=GNU Make %s\njobs=%s\nstart_ms=0\nend_ms=%s\nrc=0\nclosure_sha256=fixture\nload_start=2\nload_end=4\nload_rule=strict\nslot=%s\nattempt=0\n' "$version" "$jobs" "$((span * 1000))" "$name" > "$D/$name.header.txt"
  load_epoch=0; for load in $loads; do printf '%s\t%s\n' "$load_epoch" "$load"; load_epoch=$((load_epoch + 30)); done > "$D/$name.load.tsv"
}
reports() {
  for i in 1 2 3; do record "b$i" 1 100; record "a$i" 6 40; done
  record j8 8 35
}
report() { profile report "$@" "$D"/b?.tsv -- "$D"/a?.tsv "$D/j8.tsv"; }
expect_rc() {
  want=$1; shift; actual=0; "$@" > "$D/result" 2>&1 || actual=$?
  [ "$actual" = "$want" ] || { cat "$D/result"; echo "rc=$actual want=$want"; return 1; }
}
check_case() (
  set -e
  # A broken cleanup mutant must not leave fixture processes running.
  trap 'if [ -f "$D/out/header.txt" ]; then p=$(header sampler_pid); if [ -n "$p" ]; then kill "$p" 2>/dev/null || :; fi; fi
    if [ -s "$D/out/sleeper.pid" ]; then kill "$(cat "$D/out/sleeper.pid")" 2>/dev/null || :; fi' EXIT
  case "$CASE" in
    rc-passthrough)
      printf 'all:\n\t@false\n' > Makefile
      expect_rc 2 run -- all
      row all | awk -F '\t' 'END {exit !($4==1)}' ;;
    bare-true)
      printf 'all:\n\t@true\n' > Makefile
      run -- all; [ "$(row all | wc -l | tr -d ' ')" = 1 ] ;;
    submake-level)
      printf 'all:\n\t@$(MAKE) child\nchild:\n\t@true\n' > Makefile
      run -- all
      row child | awk -F '\t' 'END {exit !($5==2 && $6=="child" && $7=="all")}' ;;
    top-target-j2)
      printf 'all: p q\np q:\n\t@$(MAKE) child-$@\nchild-p child-q:\n\t@sleep 0.1\n' > Makefile
      run --jobs 2 -- all
      row child-p | awk -F '\t' 'END {exit !($7=="p")}'
      row child-q | awk -F '\t' 'END {exit !($7=="q")}'
      awk -F '\t' '$6=="child-p" {s=$1;e=$2} $6=="child-q" {q=$1;r=$2} END {exit !(s<r && q<e)}' "$D/out/profile.tsv" ;;
    caller-top-poison)
      printf 'all:\n\t@true\n' > Makefile
      SUITE_TOP_TARGET=x; export SUITE_TOP_TARGET
      run -- all
      row all | awk -F '\t' 'END {exit !($7=="all")}' ;;
    parallel-overlap)
      printf 'all: p q\np q:\n\t@sleep 0.2\n' > Makefile
      run --jobs 2 -- all
      awk -F '\t' 'NR==1 {s=$1;e=$2} NR==2 {exit !($1<e && s<$2)} END {if(NR!=2) exit 1}' "$D/out/profile.tsv" ;;
    cpu-busy-sleep)
      # Fixed child CPU work stays meaningful when other rig jobs consume wall time.
      cat > Makefile <<'MAKE'
all: busy nap sys
busy:
	@perl -e 'do { @t=times } while $$t[0]+$$t[1]<0.25'
nap:
	@sleep 0.2
sys:
	@perl -e 'open my $$n, ">", "syscall.data" or die $$!; do { for (1..10000) { syswrite $$n,"x" } @t=times } while $$t[1]<0.20; print $$t[0]+$$t[1],"\n"' > syscall.cpu
MAKE
      run -- all
      row busy | awk -F '\t' 'END {exit !($3>=0.20)}'
      row nap | awk -F '\t' 'END {exit !($3<=0.1)}'
      # The recipe records its own user+sys; user-only accounting loses >=0.20 s.
      row sys | awk -F '\t' -v cpu="$(cat syscall.cpu)" 'END {exit !($3>=cpu-0.04)}' ;;
    compare-missing)
      record b 1 10; cp "$D/b.header.txt" "$D/a.header.txt"; : > "$D/a.tsv"
      expect_rc 1 profile compare "$D/b.tsv" "$D/a.tsv"
      grep -qx 'missing=1 fewer=0 extra=0' "$D/result" ;;
    compare-fewer-extra)
      record b 1 10; cp "$D/b.header.txt" "$D/a.header.txt"; cp "$D/b.tsv" "$D/a.tsv"
      cat "$D/a.tsv" >> "$D/b.tsv"
      expect_rc 1 profile compare "$D/b.tsv" "$D/a.tsv"
      grep -qx 'missing=0 fewer=1 extra=0' "$D/result"
      expect_rc 0 profile compare "$D/a.tsv" "$D/b.tsv"
      grep -qx 'missing=0 fewer=0 extra=1' "$D/result" ;;
    closure-mismatch)
      record b 1 10; record a 1 10
      sed 's/closure_sha256=fixture/closure_sha256=other/' "$D/a.header.txt" > "$D/h"; mv "$D/h" "$D/a.header.txt"
      expect_rc 1 profile compare "$D/b.tsv" "$D/a.tsv"
      grep -q 'closure mismatch' "$D/result"
      for side in b a; do
        sed 's/^closure_sha256=.*/closure_sha256=/' "$D/$side.header.txt" > "$D/h"; mv "$D/h" "$D/$side.header.txt"
      done
      expect_rc 1 profile compare "$D/b.tsv" "$D/a.tsv"
      grep -q 'closure mismatch' "$D/result" ;;
    overhead-200)
      { echo all:; i=0; while [ "$i" -lt 200 ]; do printf '\t@true\n'; i=$((i + 1)); done; } > Makefile
      start=$(perl -MTime::HiRes=time -e 'printf "%.0f",time*1000')
      times > "$D/cpu-before"
      run -- all
      times > "$D/cpu-after"
      end=$(perl -MTime::HiRes=time -e 'printf "%.0f",time*1000')
      cpu=$(awk 'function sec(s,a) {split(s,a,"m"); sub(/s$/,"",a[2]); return a[1]*60+a[2]}
        FNR==2 {c=sec($1)+sec($2); if(NR==FNR) before=c; else printf "%.0f",(c-before)*1000}' "$D/cpu-before" "$D/cpu-after")
      wall=$((end - start))
      awk -v wall="$wall" -v cpu="$cpu" 'BEGIN {printf "overhead-200: wall %d ms, cpu %d ms over 200 lines (%.2f ms/line wall, %.2f ms/line cpu)\n",wall,cpu,wall/200,cpu/200}'
      [ "$(wc -l < "$D/out/profile.tsv" | tr -d ' ')" = 200 ]
      [ "$cpu" -le 30000 ]; [ "$wall" -le 200000 ] ;;
    atomic-rows)
      { printf 'all:'; i=0; while [ "$i" -lt 40 ]; do printf ' t%s' "$i"; i=$((i + 1)); done
        printf '\n'; i=0; while [ "$i" -lt 40 ]; do printf 't%s:\n\t@true\n' "$i"; i=$((i + 1)); done; } > Makefile
      run --jobs 2 -- all
      awk -F '\t' 'NF!=7 || $1!~/^[0-9]+$/ || $2<$1 || $3!~/^[0-9.]+$/ || $4!=0 || $5!=1 || $6!~/^t[0-9]+$/ || $7!=$6 {bad=1} END {exit (bad || NR!=40)}' "$D/out/profile.tsv" ;;
    load-sampler)
      mkdir bin
      cat > bin/sleep <<'STUB'
#!/bin/sh
printf '%s\n' "$1" >> "$PROBE"
exec /bin/sleep 0.05
STUB
      cat > bin/sysctl <<'STUB'
#!/bin/sh
case "$2" in
  hw.ncpu) echo 4 ;;
  vm.loadavg) case "${EMPTY_LOAD:-}" in sysctl) exit 0 ;; proc) exit 1 ;; *) echo '{ 2.00 2.00 2.00 }' ;; esac ;;
  *) exit 1 ;;
esac
STUB
      chmod +x bin/sleep bin/sysctl
      # Wait (at most 5 s) until the sampler reaches its first sleep, so the cadence probe is never empty.
      printf 'all:\n\t@i=0; while [ ! -s "$$PROBE" ] && [ $$i -lt 100 ]; do /bin/sleep 0.05; i=$$((i+1)); done\n' > Makefile
      PROBE=$D/cadence PATH="$D/bin:$PATH"; export PROBE PATH
      run -- all
      [ "$(sort -u "$PROBE")" = 30 ]
      [ "$(header sampler_interval)" = 30 ]; [ -n "$(header sampler_pid)" ]
      awk -F '\t' 'NF!=2 || $1!~/^[0-9]+$/ || $2!~/^[0-9.]+$/ {bad=1} END {exit (bad || NR<1)}' "$D/out/load.tsv"
      [ -n "$(header cores)" ]; [ -n "$(header sha)" ]; [ -n "$(header closure_sha256)" ]
      # macOS has no /proc: redirect only that path in a scratch copy to an empty
      # readable fixture file, preserving load1 and the sampler guard verbatim.
      mkdir "$D/proc-probe"; : > "$D/proc-loadavg"
      sed "s|/proc/loadavg|$D/proc-loadavg|g" "$P" > "$D/proc-probe/suite_profile.sh"
      cp "$W" "$D/proc-probe/timed_recipe_shell.sh"
      for EMPTY_LOAD in sysctl proc; do
        export EMPTY_LOAD
        if [ "$EMPTY_LOAD" = proc ]; then P=$D/proc-probe/suite_profile.sh; fi
        rm "$PROBE"
        run -- all
        [ -s "$PROBE" ] # The sampler completed a load probe before the recipe finished.
        awk -F '\t' 'NF!=2 || $2=="" {bad=1} END {exit bad}' "$D/out/load.tsv"
        [ ! -s "$D/out/load.tsv" ]
      done ;;
    sampler-cleanup)
      # Keep the real 30-second sleeper in flight until the recipe can observe it.
      printf 'all:\n\t@i=0; while [ ! -s out/sleeper.pid ] && [ $$i -lt 500 ]; do /bin/sleep 0.01; i=$$((i+1)); done; test -s out/sleeper.pid\n' > Makefile
      run -- all
      ! kill -0 "$(header sampler_pid)" 2>/dev/null
      [ -s "$D/out/sleeper.pid" ]; ! kill -0 "$(cat "$D/out/sleeper.pid")" 2>/dev/null
      printf 'all:\n\t@/bin/sleep 1\n' > Makefile
      for sig in TERM INT; do
        rm -f "$D/out/header.txt" "$D/out/sleeper.pid"
        # Perl restores INT before exec: POSIX background shells otherwise inherit SIG_IGN.
        perl -e '$SIG{INT}="DEFAULT"; exec @ARGV' sh "$P" run --make "$M" --out "$D/out" -- all > "$D/signal.log" 2>&1 & runner=$!
        i=0; until grep -q '^sampler_pid=' "$D/out/header.txt" && [ -s "$D/out/sleeper.pid" ] && kill -0 "$(cat "$D/out/sleeper.pid")" 2>/dev/null; do
          /bin/sleep 0.01; i=$((i + 1)); [ "$i" -lt 100 ]
        done
        kill -"$sig" "$runner"; signal_rc=0; wait "$runner" || signal_rc=$?
        case "$sig:$signal_rc" in TERM:143|INT:130) ;; *) exit 1 ;; esac
        ! kill -0 "$(header sampler_pid)" 2>/dev/null
        ! kill -0 "$(cat "$D/out/sleeper.pid")" 2>/dev/null
      done ;;
    report-version)
      reports; record b1 1 100 3.81
      expect_rc 1 report; grep -q '4.4.1' "$D/result"
      reports; printf 'rc=2\n' >> "$D/b1.header.txt"
      expect_rc 1 report; grep -q 'failed run' "$D/result"
      reports; printf 'closure_sha256=other\n' >> "$D/a1.header.txt"
      expect_rc 1 report; grep -q 'closure mismatch' "$D/result" ;;
    report-load)
      reports; rm "$D/b1.load.tsv"; expect_rc 1 report
      reports; record b1 1 100 4.4.1 '2 6 2'; expect_rc 1 report
      expect_rc 0 report --load-rule fallback
      grep -q 'load_rule=fallback' "$D/result"; grep -q 'median=2.000 max=6.000' "$D/result"
      record b1 1 100 4.4.1 '2 9 2'; expect_rc 1 report --load-rule fallback
      record b1 1 100 4.4.1 '6 6 2'; expect_rc 1 report --load-rule fallback
      reports; printf 'attempt=3\n' >> "$D/b1.header.txt"; expect_rc 1 report
      reports; printf 'slot=b1\nattempt=1\n' >> "$D/b2.header.txt"; expect_rc 1 report
      grep -q 'insufficient comparable runs' "$D/result"
      # Four serial inputs leave three slots if deduplication alone replaces b1.
      # Thus this assertion fails on the duplicate refusal itself, never the count.
      reports; record b4 1 100; printf 'slot=b1\nattempt=0\n' >> "$D/b2.header.txt"
      expect_rc 1 report; grep -q 'duplicate or unordered slot attempt' "$D/result" ;;
    report-medians)
      reports; expect_rc 0 report
      grep -q 'before_median=100.000 after_j6_median=40.000 ratio=0.400' "$D/result"
      grep -q 'j8.tsv.*jobs=8' "$D/result"
      expect_rc 1 profile report "$D"/b?.tsv -- "$D"/a?.tsv
      grep -q 'insufficient comparable runs' "$D/result"
      for spec in 'b1 6' 'a1 1' 'a1 7'; do
        reports; set -- $spec; record "$1" "$2" 100
        expect_rc 1 report; grep -q 'invalid jobs' "$D/result"
      done
      reports
      expect_rc 1 report --stage M3
      rm "$D/b3.tsv"; expect_rc 1 report
      reports; rm "$D/a3.tsv"; expect_rc 1 report
      reports; record a3 6 90; expect_rc 0 report
      record a2 6 90; expect_rc 1 report
      reports; record a3 6 50; record a2 6 50; expect_rc 0 report
      record a3 6 51; record a2 6 51; expect_rc 1 report
      reports; record a2 6 35; record a3 6 35; expect_rc 0 report --stage M3
      reports; record b1 1 100 3.81; expect_rc 1 report ;;
    summary-targets)
      printf '0\t1000\t0.200\t0\t1\tz\tz\n1000\t3000\t1.000\t0\t1\ta\ta\n1100\t1900\t0.400\t0\t2\tchild\ta\n3000\t4000\t0.900\t0\t1\tc\tc\n4000\t5000\t1.200\t0\t1\td\td\n5000\t6000\t0.000\t0\t1\t\t\n' > "$D/s.tsv"
      profile targets "$D/s.tsv" > "$D/targets"
      printf '(parse)\t1\na\t1\nc\t1\nchild\t1\nd\t1\nz\t1\n' > "$D/expected"
      cmp "$D/expected" "$D/targets"
      profile summary "$D/s.tsv" > "$D/summary"
      cat > "$D/expected" <<'GOLD'
target	wall_s	cpu_s	cpu/wall	class	share	lines
a	2.000	1.000	0.500	mixed	33.33%	2
(parse)	1.000	0.000	0.000	floor	16.67%	1
c	1.000	0.900	0.900	cpu	16.67%	1
d	1.000	1.200	1.200	internally-parallel	16.67%	1
z	1.000	0.200	0.200	floor	16.67%	1
totals wall_s=6.000 cpu_s=3.300 span_s=6.000 lines=6
busy_jobs	seconds
1	6.000
CPU is a lower bound for unreaped daemons; nested CPU/wall counted at the parent.
GOLD
      cmp "$D/expected" "$D/summary"
      profile summary "$D/s.tsv" > "$D/again"; cmp "$D/again" "$D/summary"
      printf '0\t2000\t0.200\t0\t1\tp\tp\n1000\t3000\t0.200\t0\t1\tq\tq\n' > "$D/parallel.tsv"
      profile summary "$D/parallel.tsv" > "$D/summary"
      grep -qx "1$(printf '\t')2.000" "$D/summary"
      grep -qx "2$(printf '\t')1.000" "$D/summary" ;;
    gap-agree)
      record s 1 100
      printf "0 Makefile:1: update target 'a' due to: x\n100 done\n" > "$D/trace"
      profile gap "$D/trace" > "$D/gap"; printf 'a\t100.000\n' > "$D/expected"; cmp "$D/expected" "$D/gap"
      printf "0 Makefile:1: update target 'a' due to: x\n1 make[1]: Entering directory 'fixture'\n2 Makefile:2: update target 'child' due to: x\n90 make[1]: Leaving directory 'fixture'\n100 done\n" > "$D/nested-trace"
      profile gap "$D/nested-trace" > "$D/gap"; cmp "$D/expected" "$D/gap"
      expect_rc 0 profile agree "$D/s.tsv" "$D/trace"
      printf "0 Makefile:1: update target 'a' due to: x\n102 done\n" > "$D/trace"; expect_rc 0 profile agree "$D/s.tsv" "$D/trace"
      printf "0 Makefile:1: update target 'a' due to: x\n103 done\n" > "$D/trace"; expect_rc 1 profile agree "$D/s.tsv" "$D/trace"
      record s 1 200
      printf "0 Makefile:1: update target 'a' due to: x\n204 done\n" > "$D/trace"; expect_rc 0 profile agree "$D/s.tsv" "$D/trace"
      printf "0 Makefile:1: update target 'a' due to: x\n205 done\n" > "$D/trace"; expect_rc 1 profile agree "$D/s.tsv" "$D/trace"
      printf '0 done\n200 done\n' > "$D/trace"; expect_rc 1 profile agree "$D/s.tsv" "$D/trace" ;;
    temp-only)
      # Observe known external paths only; the positive observation probe stays inside T.
      observe() { for f in "$HOME" "$HOME/.ailang" "$ROOT/.ailang" "$T/outside-fixture"; do ls -ld "$f" 2>/dev/null || :; done; }
      : > "$T/outside-fixture"; observe > "$D/before"
      printf 'all:\n\t@true\n' > Makefile
      run -- all
      observe > "$D/after"; cmp "$D/before" "$D/after"
      test ! -s "$T/outside-fixture"
      ls -ld "$T/outside-fixture" > "$D/probe-before"
      rm "$T/outside-fixture"; mkdir "$T/outside-fixture"
      ls -ld "$T/outside-fixture" > "$D/probe-after"
      ! cmp -s "$D/probe-before" "$D/probe-after"
      rmdir "$T/outside-fixture"
      test -f "$D/out/header.txt"; test -f "$D/out/profile.tsv"; test -f "$D/out/load.tsv" ;;
  esac
)
cases='rc-passthrough bare-true submake-level top-target-j2 caller-top-poison parallel-overlap cpu-busy-sleep compare-missing compare-fewer-extra closure-mismatch overhead-200 atomic-rows load-sampler sampler-cleanup report-version report-load report-medians summary-targets gap-agree temp-only'
case_count=20
# Optional single-case invocation makes independent scratch mutation drills quick.
if [ "$#" -gt 0 ]; then
  [ "$#" = 1 ] || exit 1
  case " $cases " in *" $1 "*) cases=$1; case_count=1 ;; *) exit 1 ;; esac
fi
fails=0; executions=0
for CASE in $cases; do
  why=; index=0
  for M in $makes; do
    index=$((index + 1)); executions=$((executions + 1))
    D=$T/$CASE-$index; mkdir "$D"
    if [ ! -f "$P" ] || [ ! -f "$W" ]; then
      why="$why missing instrument ($M)"
    else
      (cd "$D" && check_case) > "$D/log" 2>&1 & case_pid=$!
      case_rc=0; wait "$case_pid" || case_rc=$?
      if [ "$CASE" = overhead-200 ]; then sed -n '/^overhead-200:/p' "$D/log"; fi
      if [ "$case_rc" != 0 ]; then
        why="$why $M: $(tail -5 "$D/log" | tr '\n' ' ')"
      fi
    fi
  done
  if [ -z "$why" ]; then echo "suite-profile control $CASE: ok"
  else echo "suite-profile control $CASE: FAIL ($why)"; fails=$((fails + 1)); fi
done
[ "$executions" = "$((case_count * nm))" ] || fails=$((fails + 1))
echo "suite-profile control: $executions cases, $fails failures"
[ "$fails" = 0 ]
