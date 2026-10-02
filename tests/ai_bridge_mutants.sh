#!/bin/sh
# AI.6 mutation check for bridge/ai_bridge.gd (as markers-mutants and ai-mutants):
# each mutant, applied in place, must make tests/test_ai_bridge.gd fail the named
# assertion. The original file is restored after every mutant and on exit. A
# mutant whose anchor no longer matches fails the check, so it cannot rot.
# Usage: tests/ai_bridge_mutants.sh <godot> <scratch dir>   (AILANG_BIN set)
# Mutant lines: anchor <TAB> replacement <TAB> --only tests <TAB> assertion text
# (\n and \t in the anchor and replacement stand for newline and tab).
set -u
GODOT=$1
SCRATCH=$2
SRC=bridge/ai_bridge.gd
mkdir -p "$SCRATCH"
cp "$SRC" "$SCRATCH/ai_bridge.gd.orig"
trap 'cp "$SCRATCH/ai_bridge.gd.orig" "$SRC"' EXIT INT TERM
fails=0
n=0
TAB=$(printf '\t')
while IFS="$TAB" read -r from to only want; do
	[ -z "$from" ] && continue
	n=$((n + 1))
	cp "$SCRATCH/ai_bridge.gd.orig" "$SRC"
	if ! FROM="$from" TO="$to" perl -0pi -e '
		my ($f, $t) = ($ENV{FROM}, $ENV{TO});
		for ($f, $t) { s/\\n/\n/g; s/\\t/\t/g; }
		s/\Q$f\E/$t/ or die "anchor not found: $ENV{FROM}\n"' "$SRC"; then
		fails=$((fails + 1))
		continue
	fi
	if "$GODOT" --headless --path . --script tests/test_ai_bridge.gd -- --faults --only="$only" > "$SCRATCH/mutant.txt" 2>&1; then
		echo "mutant SURVIVED: '$to' ($only)"
		fails=$((fails + 1))
	elif grep -F "FAIL" "$SCRATCH/mutant.txt" | grep -F -- "$want" > /dev/null; then
		echo "mutant killed: '$to' fails '$want'"
	else
		echo "mutant '$to' did not fail '$want':"
		grep -F "FAIL" "$SCRATCH/mutant.txt"
		fails=$((fails + 1))
	fi
done <<'EOF'
{"text": 0, "voice": 1	{"text": 2, "voice": 1	stub_session	text > voice > portrait
\t_in_flight = {}\n\t_kill()\n\t_cancel(r, "timeout")	\t_in_flight = {}\n\t_cancel(r, "timeout")	timeouts	next request relaunches at once
int(timeout_ms[_in_flight["kind"]])	int(timeout_ms["text"])	timeouts	voice cancelled timeout
if chunk.is_empty():\n\t\t\tbreak\n\t\tgot = true	if chunk.is_empty():\n\t\t\tOS.delay_msec(60)\n\t\t\tbreak\n\t\tgot = true	timeouts	frame never blocked
_queues[PRIORITY[_in_flight["kind"]]].push_front(_in_flight)	pass	crash_loop	both answered after one restart
(backoff_delay(_consecutive) if backoff else 0)	0	crash_loop	backoff
const FAIL_LIMIT := 3	const FAIL_LIMIT := 4	crash_loop	three launches
if now - t < FAIL_WINDOW_MS:	if true:	crash_loop	third failure 11 min later
_line_bytes.append_array(chunk)	_line_bytes = chunk	assemble	three lines from five chunks
 and int(proto["major"]) == PROTO_MAJOR:	:	handshake_faults	proto.major 2 refused
var argv := scrubbed(plan)	var argv := PackedStringArray(["-c", 'exec "$@"', "sh", plan["bin"]]) + PackedStringArray(plan["args"])	stub_session	inherits no pipe of Godot's
EOF
echo "ai-bridge-mutants: $n mutants, $fails not killed"
[ "$fails" -eq 0 ]
