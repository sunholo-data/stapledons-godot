#!/bin/sh
# Fixture-tested GNU make instrumentation; no suite policy or make target wiring.
set -eu
LC_ALL=C; export LC_ALL
SELF=$(cd "$(dirname "$0")" && pwd -P)
die() { echo "suite-profile: $*" >&2; exit 1; }
ms() { perl -MTime::HiRes=time -e 'printf "%.0f",time*1000'; }
load1() {
  if value=$(sysctl -n vm.loadavg 2>/dev/null); then printf '%s\n' "$value" | awk '{print $2}'
  elif [ -r /proc/loadavg ]; then awk '{print $1}' /proc/loadavg
  else die 'cannot read load (sysctl and /proc/loadavg unavailable)'; fi
}
companion() {
  if [ "$(basename "$1")" = profile.tsv ]; then printf '%s/%s\n' "$(dirname "$1")" "$2"
  else printf '%s.%s\n' "${1%.tsv}" "$2"; fi
}
meta() { sed -n "s/^$2=//p" "$(companion "$1" header.txt)" | tail -1; }
targets() { awk -F '\t' '{t=$6; if(t=="") t="(parse)"; n[t]++} END {for(t in n) printf "%s\t%d\n",t,n[t]}' "$1" | sort; }
# Query an inert goal, never the requested suite goal. -q alone still runs recursive
# recipes of a requested goal. The extra makefile also works with make 3.81.
closure() (
  : > "$out/query.args"; : > "$out/goals"; has_file=0; query_dir=$(pwd -P)
  while [ "$#" -gt 0 ]; do
    case "$1" in
      -f|--file|-C|--directory|-I|--include-dir)
        [ "$#" -ge 2 ] || exit 1
        case "$1" in
          -f|--file) has_file=1 ;;
          -C|--directory) query_dir=$(cd "$query_dir" && cd "$2" && pwd -P) ;;
        esac
        printf '%s\n%s\n' "$1" "$2" >> "$out/query.args"; shift ;;
      -f?*|--file=*) has_file=1; printf '%s\n' "$1" >> "$out/query.args" ;;
      -C?*|--directory=*)
        dir=${1#-C}; case "$1" in --directory=*) dir=${1#--directory=} ;; esac
        query_dir=$(cd "$query_dir" && cd "$dir" && pwd -P)
        printf '%s\n' "$1" >> "$out/query.args" ;;
      -I?*|--include-dir=*|*=*) printf '%s\n' "$1" >> "$out/query.args" ;;
      -j|--jobs) case "${2:-}" in [0-9]*) shift ;; esac ;;
      -*) : ;;
      *) printf '%s\n' "$1" >> "$out/goals" ;;
    esac
    shift
  done
  set -- "$maker" -pq
  while IFS= read -r arg; do set -- "$@" "$arg"; done < "$out/query.args"
  if [ "$has_file" = 0 ]; then
    for f in GNUmakefile makefile Makefile; do
      if [ -f "$query_dir/$f" ]; then set -- "$@" -f "$query_dir/$f"; break; fi
    done
  fi
  printf '.PHONY: __suite_profile_nop__\n__suite_profile_nop__:\n' > "$out/query.mk"
  query_rc=0; "$@" -f "$out/query.mk" __suite_profile_nop__ > "$out/database.txt" 2> "$out/query.err" || query_rc=$?
  [ "$query_rc" -le 1 ] || { cat "$out/query.err" >&2; exit 1; }
  awk '
    FILENAME==ARGV[1] {goals[++ng]=$0; next}
    /^\.DEFAULT_GOAL *[:=]/ {default_goal=$NF}
    /^# Files/ {files=1; next}
    files && /^[^#\t ][^=]*:/ {
      p=index($0,":"); t=substr($0,1,p-1); deps=substr($0,p+1); sub(/^:/,"",deps)
      gsub(/\|/," ",deps); edge[t]=edge[t] " " deps
    }
    function walk(t, a,n,i) {
      if(t=="" || seen[t]++) return; print t
      n=split(edge[t],a," "); for(i=1;i<=n;i++) walk(a[i])
    }
    END {if(!ng) walk(default_goal); else for(g=1;g<=ng;g++) walk(goals[g])}
  ' "$out/goals" "$out/database.txt" | sort -u > "$out/closure.txt"
  [ -s "$out/closure.txt" ] || exit 1
  shasum -a 256 "$out/closure.txt" | awk '{print $1}'
)
summary() {
  # Nested rows carry the parent's inclusive wall/CPU; do not count them twice.
  awk -F '\t' '
    {t=$7; if(t=="") t="(parse)"; lines[t]++; count++
     if(!have || $1<lo) lo=$1; if(!have || $2>hi) hi=$2; have=1
     if($5<=1 && ($6==$7 || $7=="")) {w[t]+=($2-$1)/1000; c[t]+=$3}}
    END {for(t in lines) printf "%s\t%.6f\t%.6f\t%d\n",t,w[t],c[t],lines[t]}
  ' "$1" | sort -t "$(printf '\t')" -k2,2nr -k1,1 | awk -F '\t' '
    {t[NR]=$1; w[NR]=$2; c[NR]=$3; n[NR]=$4; wall+=$2; cpu+=$3; lines+=$4}
    END {
      print "target\twall_s\tcpu_s\tcpu/wall\tclass\tshare\tlines"
      for(i=1;i<=NR && i<=20;i++) {
        r=w[i]?c[i]/w[i]:0; class=r<0.3?"floor":(r<0.9?"mixed":(r>1?"internally-parallel":"cpu"))
        printf "%s\t%.3f\t%.3f\t%.3f\t%s\t%.2f%%\t%d\n",t[i],w[i],c[i],r,class,wall?100*w[i]/wall:0,n[i]
      }
      printf "totals wall_s=%.3f cpu_s=%.3f",wall,cpu
    }'
  awk -F '\t' 'NR==1 {lo=$1;hi=$2} {if($1<lo)lo=$1;if($2>hi)hi=$2} END {printf " span_s=%.3f lines=%d\n",(hi-lo)/1000,NR}' "$1"
  echo 'busy_jobs	seconds'
  awk -F '\t' '$5<=1 && ($6==$7 || $7=="") {printf "%.0f\t1\n%.0f\t-1\n",$1,$2}' "$1" | sort -n | awk '
    NR>1 {h[busy]+=($1-prev)/1000} {busy+=$2;prev=$1}
    END {for(b in h) if(h[b]>0) printf "%d\t%.3f\n",b,h[b]}' | sort -n
  echo 'CPU is a lower bound for unreaped daemons; nested CPU/wall counted at the parent.'
}
gap() {
  # Timestamped GNU --trace, plus entering/leaving-directory records for folding.
  awk '
    function flush(now) {if(active!="") wall[active]+=now-start; start=now}
    {now=$1+0; last=now}
    /Entering directory/ {
      level=$0; if(level~/make\[[0-9]+\]/) {sub(/^.*make\[/,"",level); sub(/\].*$/,"",level); depth=level+0}
      else depth=0; next
    }
    /Leaving directory/ {if(depth>0) depth--; next}
    /update target / {
      if(depth>0) next
      flush(now); line=$0; sub(/^.*update target [\047\140]/,"",line); sub(/[\047\140].*$/,"",line)
      active=line; next
    }
    END {flush(last); for(t in wall) printf "%s\t%.3f\n",t,wall[t]}
  ' "$1" | sort
}
cmd=${1:-}; [ "$#" -gt 0 ] && shift
case "$cmd" in
  run)
    maker=make; jobs=1; out=.godot/tmp/suite-profile
    while [ "$#" -gt 0 ]; do
      case "$1" in
        --make) maker=$2; shift 2 ;; --jobs) jobs=$2; shift 2 ;; --out) out=$2; shift 2 ;;
        --) shift; break ;; *) die "unknown run option: $1" ;;
      esac
    done
    case "$jobs" in ''|*[!0-9]*|0) die 'jobs must be positive' ;; esac
    mkdir -p "$out"; out=$(cd "$out" && pwd -P)
    export TMPDIR="$out"
    SUITE_PROFILE_LOG=$out/profile.tsv; export SUITE_PROFILE_LOG
    : > "$SUITE_PROFILE_LOG"; : > "$out/load.tsv"; : > "$out/header.txt"
    unset SUITE_TOP_TARGET
    hash=$(closure "$@") || die 'closure query failed'
    version=$("$maker" --version | sed -n '1p')
    cores=$(sysctl -n hw.ncpu 2>/dev/null) || cores=$(getconf _NPROCESSORS_ONLN)
    start=$(ms); load_start=$(load1)
    sha=$(git rev-parse HEAD 2>/dev/null) || sha=untracked-fixture
    sampler=; child=
    cleanup() {
      if [ -n "$sampler" ]; then kill "$sampler" 2>/dev/null || :; wait "$sampler" 2>/dev/null || :; fi
      if [ -n "$child" ]; then kill "$child" 2>/dev/null || :; wait "$child" 2>/dev/null || :; fi
    }
    finish() {
      rc=$1; cleanup
      printf 'end_ms=%s\nload_end=%s\nrc=%s\n' "$(ms)" "$(load1)" "$rc" >> "$out/header.txt"
      trap - EXIT; exit "$rc"
    }
    trap cleanup EXIT
    trap 'finish 130' INT
    trap 'finish 143' TERM HUP
    # Killing the sampler also reaps its sleep child, including on interruptions.
    (
      sleeper=
      trap 'if [ -n "$sleeper" ]; then kill "$sleeper" 2>/dev/null || :; wait "$sleeper" 2>/dev/null || :; fi; exit 0' TERM INT HUP
      while :; do
        # A kill during $(load1) leaves it empty; never write that half row (report would refuse it).
        now=$(date +%s); l=$(load1)
        if [ -n "$l" ]; then printf '%s\t%s\n' "$now" "$l" >> "$out/load.tsv"; fi
        sleep 30 & sleeper=$!; wait "$sleeper" || :
      done
    ) & sampler=$!
    printf 'sha=%s\nmake=%s\njobs=%s\ncores=%s\nstart_ms=%s\nload_start=%s\nclosure_sha256=%s\nsampler_pid=%s\nsampler_interval=30\nload_rule=strict\n' "$sha" "$version" "$jobs" "$cores" "$start" "$load_start" "$hash" "$sampler" > "$out/header.txt"
    "$maker" -j "$jobs" "SHELL=$SELF/timed_recipe_shell.sh" 'SUITE_TARGET=$@' "$@" & child=$!
    rc=0; wait "$child" || rc=$?; child=
    finish "$rc" ;;
  summary) [ "$#" = 1 ] || die 'summary TSV'; summary "$1" ;;
  targets) [ "$#" = 1 ] || die 'targets TSV'; targets "$1" ;;
  compare)
    [ "$#" = 2 ] || die 'compare BEFORE AFTER'
    bh=$(meta "$1" closure_sha256); ah=$(meta "$2" closure_sha256)
    [ -n "$bh" ] && [ "$bh" = "$ah" ] || die 'closure mismatch'
    # Shell counter intentionally remains a simple, independently mutated guard.
    counts=$( { targets "$1" | awk -F '\t' '{print "B\t"$0}'; targets "$2" | awk -F '\t' '{print "A\t"$0}'; } | awk -F '\t' '
      $1=="B" {b[$2]=$3;next} {a[$2]=$3}
      END {for(t in b) {if(!(t in a)) print "missing"; else if(a[t]<b[t]) print "fewer"}
           for(t in a) if(a[t]>b[t]) print "extra"}')
    missing=0; fewer=0; extra=0
    for count in $counts; do
      case "$count" in
        missing)
          missing=$((missing + 1))
          ;;
        fewer) fewer=$((fewer + 1)) ;; extra) extra=$((extra + 1)) ;;
      esac
    done
    echo "missing=$missing fewer=$fewer extra=$extra"
    [ "$missing" = 0 ] && [ "$fewer" = 0 ] ;;
  gap) [ "$#" = 1 ] || die 'gap TRACELOG'; gap "$1" ;;
  agree)
    [ "$#" = 2 ] || die 'agree TSV TRACELOG'
    { summary "$1" | awk -F '\t' 'NF==7 && NR>1 {print "S\t"$1"\t"$2}'; gap "$2" | awk '{print "G\t"$0}'; } | awk -F '\t' '
      $1=="S" {w[$2]=$3;next} {g[$2]=$3}
      END {for(t in w) {tol=w[t]*0.02; if(tol<2)tol=2; d=w[t]-g[t]; if(d<0)d=-d
        if(!(t in g) || d>tol+0.000001) {print "agree: FAIL "t;bad=1}}
        if(!bad) print "agree: ok"; exit bad}' ;;
  report)
    # Explicit common eligibility rule across both sides, never an implicit fallback.
    rule=strict; stage=M2
    while [ "$#" -gt 0 ]; do
      case "$1" in --load-rule) rule=$2; shift 2 ;; --stage) stage=$2; shift 2 ;; *) break ;; esac
    done
    case "$rule" in strict|fallback) ;; *) die 'load rule must be strict or fallback' ;; esac
    case "$stage" in M2) threshold=0.5 ;; M3) threshold=0.35 ;; *) die 'stage must be M2 or M3' ;; esac
    # Read metadata and TSVs in Perl for medians, numeric validation and slot dedupe.
    # Arguments are passed directly; no generated shell or evaluation of metadata.
    perl - "$rule" "$stage" "$threshold" "$@" <<'PERL'
use strict; use warnings;
my ($rule,$stage,$threshold,@args)=@ARGV;
my ($side,$split,$hash)=("before",0,undef); my (%slots,@rows); my $bad=0;
sub refuse { print STDERR "suite-profile: $_[0]\n"; exit 1 }
sub median { my @s=sort {$a<=>$b} @_; return @s%2?$s[int(@s/2)]:($s[@s/2-1]+$s[@s/2])/2 }
sub numeric { defined($_[0]) && $_[0]=~/^\d+(?:\.\d+)?$/ }
print "load_rule=$rule stage=$stage threshold=$threshold\n";
for my $file (@args) {
  if($file eq '--') {$side='after'; $split++; next}
  my $stem=$file; $stem=~s/\.tsv$//;
  my ($header,$load)=$file=~m{(?:^|/)profile\.tsv$} ? ($file=~s/profile\.tsv$/header.txt/r,$file=~s/profile\.tsv$/load.tsv/r) : ("$stem.header.txt","$stem.load.tsv");
  open my $h,'<',$header or refuse("missing header $header"); my %h;
  while(<$h>) {chomp; my($k,$v)=split /=/,$_,2; $h{$k}=$v} close $h;
  ($h{make}//'') eq 'GNU Make 4.4.1' or refuse('comparison requires GNU Make 4.4.1 (3.81 evidence excluded)');
  numeric($h{rc}) && $h{rc}==0 or refuse("failed run $file");
  defined($h{closure_sha256}) && length($h{closure_sha256}) or refuse('missing closure');
  $hash //= $h{closure_sha256}; $h{closure_sha256} eq $hash or refuse('closure mismatch');
  numeric($h{start_ms}) && numeric($h{end_ms}) && $h{end_ms}>$h{start_ms} or refuse('invalid span');
  my $jobs=$h{jobs}//''; ($side eq 'before'?$jobs eq '1':($jobs eq '6'||$jobs eq '8')) or refuse('invalid jobs');
  my $attempt=$h{attempt}//0; $attempt=~/^[012]$/ or refuse('slot exhausted: at most two repeats');
  open my $l,'<',$load or refuse("missing load $load"); my @loads;
  while(<$l>) {chomp; my @f=split /\t/; @f==2 && numeric($f[0]) && numeric($f[1]) or refuse('invalid load row'); push @loads,0+$f[1]} close $l;
  @loads or refuse('empty load'); my $med=median(@loads); my $max=(sort {$b<=>$a} @loads)[0];
  my $eligible=$rule eq 'strict' ? $max<=5 : ($med<=5 && $max<=8);
  open my $t,'<',$file or refuse("missing TSV $file"); my $cpu=0;
  while(<$t>) {chomp;my @f=split /\t/,$_,-1; @f==7 && numeric($f[2]) or refuse('invalid profile row'); $cpu+=$f[2] if $f[4]<=1 && ($f[5] eq $f[6] || $f[6] eq '')} close $t;
  my $span=($h{end_ms}-$h{start_ms})/1000;
  printf "%s make=%s jobs=%s span=%.3f cpu=%.3f load_start=%s load_end=%s median=%.3f max=%.3f %s attempt=%d\n",$file,$h{make},$jobs,$span,$cpu,$h{load_start}//'?',$h{load_end}//'?',$med,$max,$eligible?'comparable':'loaded',$attempt;
  my $slot=join ':',$side,$jobs,$h{slot}//$stem;
  if(exists $slots{$slot} && $slots{$slot}{attempt} >= $attempt) {refuse('duplicate or unordered slot attempt')}
  # A retry replaces the slot; it never supplies another independent sample.
  $slots{$slot}={side=>$side,jobs=>$jobs,span=>$span,eligible=>$eligible,attempt=>$attempt};
}
$split<=1 or refuse('multiple separators');
my @before=map {$_->{span}} grep {$_->{side} eq 'before' && $_->{eligible}} values %slots;
my @after=map {$_->{span}} grep {$_->{side} eq 'after' && $_->{jobs}==6 && $_->{eligible}} values %slots;
my @j8=grep {$_->{side} eq 'after' && $_->{jobs}==8} values %slots;
if(!$split) {print "preliminary baseline only; AC9 performance pending\n"; exit(@before>=3?0:1)}
@before>=3 && @after>=3 && @j8>=1 or refuse('exhausted or insufficient comparable runs: need >=3 serial, >=3 -j6 and one -j8');
my $bm=median(@before); my $am=median(@after); my $ratio=$am/$bm;
printf "before_median=%.3f after_j6_median=%.3f ratio=%.3f\n",$bm,$am,$ratio;
print "CPU is a lower bound for unreaped daemons.\n";
exit($ratio<=$threshold?0:1);
PERL
    ;;
  *) die 'expected run, summary, targets, compare, gap, agree or report' ;;
esac
