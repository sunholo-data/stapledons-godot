#!/bin/sh
# GNU make SHELL wrapper. times must run here, after the child has been reaped.
start=$(perl -MTime::HiRes=time -e 'printf "%.0f",time*1000')
SUITE_TARGET=${SUITE_TARGET:-}
SUITE_TOP_TARGET=${SUITE_TOP_TARGET:-$SUITE_TARGET}
export SUITE_TOP_TARGET
cpu_file=$(mktemp "${TMPDIR:-/tmp}/suite-cpu.XXXXXX") || exit 1
trap 'rm -f "$cpu_file"' EXIT
/bin/sh "$@"; rc=$?
times > "$cpu_file"
end=$(perl -MTime::HiRes=time -e 'printf "%.0f",time*1000')
# Both dash and macOS sh print minutes + seconds. Only line 2 is child CPU.
cpu=$(awk 'function sec(s,a) {split(s,a,"m"); sub(/s$/,"",a[2]); return a[1]*60+a[2]} NR==2 {printf "%.3f",sec($1)+sec($2)}' "$cpu_file")
printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$start" "$end" "$cpu" "$rc" "${MAKELEVEL:-0}" "$SUITE_TARGET" "$SUITE_TOP_TARGET" >> "$SUITE_PROFILE_LOG"; exit $rc
