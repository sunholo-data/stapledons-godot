#!/bin/sh
# M1.2b-T4 catalogue parity: build one tier from the real CSV on the interpreter once and on the
# ordinary bytecode VM N times (default 5), cmp every bin and sidecar against the interpreter's,
# and print each run's wall time and peak RSS. Any byte difference is a VM/interpreter divergence:
# an upstream AILANG report, and it blocks the milestone.
#   tools/catalogue_parity.sh <ailang> <tier> <out-dir> [runs]
# Timings are reported, never used as a gate (plan F3, Q3).
set -eu
A=$1; TIER=$2; OUT=$3; RUNS=${4:-5}
entry=main hip= tool=sim/tools/catalogue_main.ail
case $TIER in
  quick) src=data/raw/cns5.csv raw=data/raw/cns5.dat tool=sim/tools/bright_main.ail entry=mainFill hip=',"hip":"data/raw/hip_main.dat"' ;;
  medium|large) src=data/raw/gcns.csv raw=data/raw/table1c.dat.gz ;;
  bright) src=data/raw/hip_main.dat raw=data/raw/hip2.dat.gz entry=brightMain tool=sim/tools/bright_main.ail ;;
  *) echo "catalogue-parity: TIER must be quick, medium, large or bright (got '$TIER')" >&2; exit 2 ;;
esac
for f in "$src" "$raw"; do [ -f "$f" ] || { echo "catalogue-parity: missing $f (make sky-assets / starmap-manager)" >&2; exit 2; }; done
ver=$("$A" --version | head -1 | cut -d' ' -f2)
case $(uname) in Darwin) TIMEFLAG=-l ;; *) TIMEFLAG=-v ;; esac
rm -rf "$OUT"; mkdir -p "$OUT"

# one <label> <engine flag or ""> : run the writer into $OUT/<label>, append "<label> <secs> <rss>"
one() {
  d=$OUT/$1; mkdir -p "$d"
  args="{\"tier\":\"$TIER\",\"csv\":\"$src\",\"raw\":\"$raw\",\"lock\":\"sim/ailang.lock\",\"out\":\"$d\",\"ailang\":\"$ver\"$hip}"
  [ "$TIER" != bright ] || args="{\"hip2\":\"$raw\",\"hipMain\":\"$src\",\"cns5\":\"data/raw/cns5.dat\",\"gcns\":\"data/raw/gcns.csv\",\"overrides\":\"data/starmap/bright_overrides.json\",\"lock\":\"sim/ailang.lock\",\"out\":\"$d\",\"ailang\":\"$ver\"}"
  t0=$(date +%s)
  # shellcheck disable=SC2086
  if ! /usr/bin/time $TIMEFLAG env -u AI_LIVE "$A" run --quiet --caps IO,FS --package-dir sim $2 --entry $entry --args-json "$args" \
      "$tool" > "$d.log" 2> "$d.time"; then
    cat "$d.log" "$d.time" >&2; echo "catalogue-parity: $1 run failed" >&2; exit 1
  fi
  secs=$(awk '/ real /{print $1} /^Elapsed|Elapsed \(wall/{print $NF}' "$d.time" | head -1)
  [ -n "$secs" ] || secs=$(( $(date +%s) - t0 ))
  # macOS -l reports bytes; GNU -v reports kbytes
  rss=$(awk '/maximum resident set size/{printf "%.0f", $1/1048576} /Maximum resident set size/{printf "%.0f", $NF/1024}' "$d.time")
  printf '%-8s %8s s %6s MiB  %s\n' "$1" "$secs" "$rss" "$(cat "$d.log")"
}

one interp ""
same=0; i=1
while [ "$i" -le "$RUNS" ]; do
  one "vm$i" --bytecode
  if cmp -s "$OUT/interp/stars_$TIER.bin" "$OUT/vm$i/stars_$TIER.bin" &&
     cmp -s "$OUT/interp/stars_$TIER.json" "$OUT/vm$i/stars_$TIER.json"; then same=$((same + 1))
  else echo "catalogue-parity: vm$i differs from the interpreter (upstream AILANG report; blocks the milestone)" >&2; fi
  i=$((i + 1))
done
n=$(wc -c < "$OUT/interp/stars_$TIER.bin" | tr -d ' ')
echo "catalogue-parity $TIER: $same/$RUNS identical (VM bin + sidecar == interpreter), $n B = $((n / 24)) x 24"
[ "$same" -eq "$RUNS" ]
