#!/bin/sh
# AC19: repeated paired service timings, alternating order to limit warm-cache bias.
# The zero-tick session removes setup from steady-tick time; its paired difference
# includes the ISM plan, commit and startup delta. Performance evidence, not physics.
set -eu
AILANG=${AILANG:-runtime/bin/ailang}
SCRATCH=${SCRATCH:-.godot/tmp}
mkdir -p "$SCRATCH/ism"
samples="$SCRATCH/ism/bench-samples.tsv"
measure() {
    perl -MTime::HiRes=time -e '
      my $start=time; my $rc;
      { local *STDOUT; open STDOUT, ">", "/dev/null" or die $!;
        system @ARGV; $rc=$?; }
      printf "%.9f\n", time-$start;
      exit($rc == -1 ? 1 : $rc >> 8);
    ' "$@"
}
run() {
    measure env -u AI_LIVE "$AILANG" run --quiet --package-dir sim --bytecode --strict-bytecode --entry "$1" --args-json "$2" sim/protocol_ism_test.ail
}
run ismStream 2 >/dev/null
run uniformStream 2 >/dev/null
: > "$samples"
for round in 1 2 3 4 5; do
    if [ $((round % 2)) = 1 ]; then
        l0=$(run ismStream 0); l=$(run ismStream 400)
        u0=$(run uniformStream 0); u=$(run uniformStream 400)
    else
        u0=$(run uniformStream 0); u=$(run uniformStream 400)
        l0=$(run ismStream 0); l=$(run ismStream 400)
    fi
    printf '%s %s %s %s %s\n' "$round" "$l0" "$l" "$u0" "$u" >> "$samples"
done
perl -e '
  my (@tick,@plan);
  while (<>) {
    my ($round,$l0,$l,$u0,$u)=split;
    my $t=(($l-$l0)-($u-$u0))/400*1000;
    my $p=($l0-$u0)*1000;
    push @tick,$t; push @plan,$p;
    printf "ism-bench: pair %d, tick delta %.3f ms, setup/plan delta %.3f ms\n",$round,$t,$p;
  }
  die "ism-bench: incomplete sample set\n" unless @tick==5;
  @tick=sort {$a<=>$b} @tick; @plan=sort {$a<=>$b} @plan;
  printf "ism-bench: median tick %.3f ms / 0.5 ms; median setup/plan %.3f ms / 20 ms\n",$tick[2],$plan[2];
  exit($tick[2] <= 0.5 && $plan[2] <= 20 ? 0 : 1);
' "$samples"
