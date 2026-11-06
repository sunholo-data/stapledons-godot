#!/bin/sh
# Row 7x ratchet: every Godot --script invocation on a recipe line of the Makefile or mk/*.mk runs through
# $(SCRIPT_GATE) (tools/script_gate.sh: rc, no SCRIPT ERROR, its own summary line, a timeout) or is a row
# of tools/script-gate-baseline.txt. Migrating a gate deletes its row (a stale row fails) and lowers the pin
# SCRIPT_GATE_BASELINE_ROWS (mk/script-gates.mk) with it, so the unguarded count can only fall.
# Each --script occurrence is classed on its own: it is gated only when its own shell command (the text
# after the last unquoted ; & | before it) starts with $(SCRIPT_GATE) ahead of the $(GODOT) token.
# Rows are keyed on target and script, not line numbers: edits that move lines keep them.
# The scanned set is closed: every include resolves to a scanned mk/*.mk, every mk/*.mk is included, and
# every makefile in the tree is scanned. --inventory prints every invocation: file:line, target, script,
# class, inline predicate pieces (a hint). SCRIPT_GATE_FILES / SCRIPT_GATE_BASELINE /
# SCRIPT_GATE_ALL_MAKEFILES override the inputs (make script-gate-lint's negative control).
set -u
base=${SCRIPT_GATE_BASELINE:-tools/script-gate-baseline.txt}
mkset=$(git ls-files -co --exclude-standard 'mk/*.mk')
files=${SCRIPT_GATE_FILES:-"Makefile $mkset"}
scanned=$(for f in $files; do echo "$f"; done)
pin=${SCRIPT_GATE_BASELINE_ROWS:?script-gate-lint: SCRIPT_GATE_BASELINE_ROWS is not set}
inventory() {
  for src in $files; do
    awk -v SRC="$src" '
      # the line with every quoted character (and every backslash-escaped one) replaced by x, same length
      function mask(s,   out, i, c, q, n) {
        out = ""; q = ""; n = length(s)
        for (i = 1; i <= n; i++) {
          c = substr(s, i, 1)
          if (c == "\\" && q != "'\''") { out = out "x"; if (i < n) { out = out "x"; i++ }; continue }
          if (q == "") { if (c == "'\''" || c == "\"") { q = c; c = "x" } }
          else { if (c == q) q = ""; c = "x" }
          out = out c
        }
        return out
      }
      function row(l, n,   m, fl, off, i, p, pre, j, last, seg, g, sg, cls, scr) {
        m = mask(l); gsub(/[<>]&/, "xx", m)
        fl = ((l ~ /rc=\$\$\?|\$\$rc/) ? "rc" : "-") "," ((l ~ /SCRIPT ERROR/) ? "se" : "-") "," \
             ((l ~ /grep -[A-Za-z]*q[A-Za-z]* ["'\'']\^/) ? "sum" : "-") "," ((l ~ /alarm/) ? "to" : "-")
        off = 0
        while ((i = index(substr(l, off + 1), "--script")) > 0) {
          p = off + i; off = p + 7
          scr = substr(l, p + 8); sub(/^[ \t]+/, "", scr); sub(/[ \t;>|\\].*$/, "", scr)
          if (substr(m, p, 1) == "x") { printf "%s:%d\t%s\t-\tother\t%s\n", SRC, n, t, fl; continue }
          pre = substr(m, 1, p - 1); last = 0
          for (j = length(pre); j > 0; j--) if (index(";|&", substr(pre, j, 1))) { last = j; break }
          seg = substr(pre, last + 1)
          g = match(seg, /(^|[^$])\$\((GODOT|GODOT_SIM)\)/)
          sg = index(seg, "$(SCRIPT_GATE)")
          cls = !g ? "other" : (sg && sg < g + 1) ? "gated" : "ungated"
          if (cls == "other") scr = "-"
          printf "%s:%d\t%s\t%s\t%s\t%s\n", SRC, n, t, scr, cls, (cls == "gated") ? "rc,se,sum,to" : fl
        }
      }
      !cont && /^[A-Za-z0-9_.%\/-][A-Za-z0-9_.%\/ -]*:([^=]|$)/ { split($0, a, ":"); t = a[1] }
      {
        if (cont) buf = buf " " $0; else { if ($0 !~ /^\t/) next; buf = $0; start = FNR }
        if (buf ~ /\\$/) { sub(/\\$/, "", buf); cont = 1; next }
        cont = 0
        if (buf ~ /^\t[ \t]*@?#/) next
        if (index(buf, "--script")) row(buf, start)
      }' "$src"
  done
}
inv=$(inventory)
if [ "${1:-}" = --inventory ]; then printf '%s\n' "$inv"; exit 0; fi
fail=0
# Closure 1: every include / -include / sinclude in the scanned set names a scanned mk/*.mk file.
incs=$(for src in $files; do
  awk -v SRC="$src" '/^ *(-|s)?include[ \t]/ { l = $0; sub(/#.*/, "", l); sub(/^ *(-|s)?include[ \t]+/, "", l)
    n = split(l, a, /[ \t]+/); for (i = 1; i <= n; i++) if (a[i] != "") print SRC ":" FNR "\t" a[i] }' "$src"; done)
ninc=0
while IFS="$(printf '\t')" read -r where target; do
  [ -n "$where" ] || continue
  ninc=$((ninc + 1))
  case $target in mk/*.mk) printf '%s\n' "$mkset" | grep -qxF -- "$target" && continue ;; esac
  echo "script-gate-lint: include outside the scanned set (mk/*.mk): $where $target"; fail=1
done <<EOF
$incs
EOF
# Closure 2: every makefile in the tree is scanned; with the default inputs, every mk/*.mk is also included.
if [ -z "${SCRIPT_GATE_FILES:-}" ] || [ -n "${SCRIPT_GATE_ALL_MAKEFILES:-}" ]; then
  all=${SCRIPT_GATE_ALL_MAKEFILES:-$(git ls-files -co --exclude-standard | grep -E '(^|/)(GNUmakefile|makefile|Makefile)$|\.mk$')}
  for f in $all; do
    printf '%s\n' "$scanned" | grep -qxF -- "$f" || { echo "script-gate-lint: makefile not scanned: $f (add it to the scanned set or move it under mk/)"; fail=1; }
  done
fi
if [ -z "${SCRIPT_GATE_FILES:-}" ]; then
  for f in $mkset; do
    printf '%s\n' "$incs" | cut -f2 | grep -qxF -- "$f" || { echo "script-gate-lint: $f is not included by any scanned makefile"; fail=1; }
  done
fi
# Known-positive control: every --script on a non-comment recipe line is one inventory row, and there is one.
tab=$(printf '\t')
want=$(for src in $files; do grep -E "^$tab" "$src" | grep -vE "^${tab}[[:space:]]*@?#" | grep -o -- '--script'; done | wc -l | tr -d ' ')
got=$(printf '%s\n' "$inv" | grep -c .)
if [ "$want" -eq 0 ] || [ "$got" != "$want" ]; then
  echo "script-gate-lint: FAIL the inventory found $got --script invocations and grep finds $want: the parser is broken"; exit 1
fi
tmp=$(mktemp -d "${TMPDIR:-/tmp}/script-gate-lint.XXXXXX")
trap 'rm -rf "$tmp"' EXIT
printf '%s\n' "$inv" | awk -F'\t' '$4 != "gated" { print $2 "\t" $3 }' | LC_ALL=C sort > "$tmp/live"
grep -v '^#' "$base" | grep . | cut -f1,2 | LC_ALL=C sort > "$tmp/listed"
rows=$(grep -c . "$tmp/listed")
new=$(LC_ALL=C comm -13 "$tmp/listed" "$tmp/live")
if [ -n "$new" ]; then
  printf '%s\n' "$new" | tr '\t' ' ' | sed 's/^/script-gate-lint: unguarded --script gate not on the baseline: /'
  echo "script-gate-lint: wrap it: @\$(SCRIPT_GATE) NAME LOG TIMEOUT_S '^its summary line\$\$' -- \$(GODOT) --headless --path . --script ... (tools/script_gate.sh)"
  fail=1
fi
stale=$(LC_ALL=C comm -23 "$tmp/listed" "$tmp/live")
if [ -n "$stale" ]; then
  printf '%s\n' "$stale" | tr '\t' ' ' | sed 's/^/script-gate-lint: stale baseline row (no longer unguarded): delete it and lower SCRIPT_GATE_BASELINE_ROWS: /'
  fail=1
fi
if [ "$rows" != "$pin" ]; then
  echo "script-gate-lint: the baseline has $rows rows but SCRIPT_GATE_BASELINE_ROWS is $pin: the pin moves with the rows, and only down"
  fail=1
fi
[ "$fail" = 0 ] || exit 1
gated=$(printf '%s\n' "$inv" | awk -F'\t' '$4 == "gated"' | grep -c .)
echo "script-gate-lint: ok ($got --script invocations: $gated through \$(SCRIPT_GATE), $rows on the baseline; $ninc includes, all in mk/*.mk; $(printf '%s\n' "$scanned" | grep -c .) makefiles scanned)"
