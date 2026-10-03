#!/bin/sh
# AI.6 (and AI.9: key file, no ADC, minimal env) mutation check for bridge/ai_bridge.gd (as markers-mutants and ai-mutants):
# each mutant, applied in place, must make tests/test_ai_bridge.gd fail the named
# assertion. AI.9 hardening adds session spend and interrupted-call mutants, and
# a second table of mutants of the AI session, settings and the bridge's usage
# reader that tests/test_ai_settings.gd must kill. AI.10a adds a third table: the
# conversation's swap timing, crossfade, fallback, subtitle, no-audio path, the
# playback copy and the cast, which tests/test_conversation.gd must kill. The originals are restored
# after every mutant and on exit. A mutant whose anchor no longer matches fails
# the check, so it cannot rot.
# Usage: tests/ai_bridge_mutants.sh <godot> <scratch dir>   (AILANG_BIN set)
# Bridge rows: anchor <TAB> replacement <TAB> --only tests <TAB> assertion text
# Settings rows: file <TAB> anchor <TAB> replacement <TAB> --only tests <TAB> assertion text
# (\n and \t in the anchor and replacement stand for newline and tab).
set -u
GODOT=$1
SCRATCH=$2
FILES="bridge/ai_bridge.gd bridge/ai_session.gd ui/settings/ai_settings.gd bridge/ai_cache.gd bridge/ai_relay.gd ui/conversation/conversation.gd"
mkdir -p "$SCRATCH/orig"
for f in $FILES; do mkdir -p "$SCRATCH/orig/$(dirname $f)"; cp "$f" "$SCRATCH/orig/$f"; done
restore() { for f in $FILES; do cp "$SCRATCH/orig/$f" "$f"; done; }
trap restore EXIT INT TERM
fails=0
n=0
TAB=$(printf '\t')
# mutate <file> <anchor> <replacement> <test script> <only> <assertion> [args]
mutate() {
	src=$1 from=$2 to=$3 script=$4 only=$5 want=$6
	shift 6
	n=$((n + 1))
	restore
	if ! FROM="$from" TO="$to" perl -0pi -e '
		my ($f, $t) = ($ENV{FROM}, $ENV{TO});
		for ($f, $t) { s/\\n/\n/g; s/\\t/\t/g; }
		s/\Q$f\E/$t/ or die "anchor not found: $ENV{FROM}\n"' "$src"; then
		fails=$((fails + 1))
		return
	fi
	if "$GODOT" --headless --path . --script "$script" -- "$@" --only="$only" > "$SCRATCH/mutant.txt" 2>&1; then
		echo "mutant SURVIVED: $src '$to' ($only)"
		fails=$((fails + 1))
	elif grep -F "FAIL" "$SCRATCH/mutant.txt" | grep -F -- "$want" > /dev/null; then
		echo "mutant killed: $src '$to' fails '$want'"
	else
		echo "mutant $src '$to' did not fail '$want':"
		grep -F "FAIL" "$SCRATCH/mutant.txt"
		fails=$((fails + 1))
	fi
}
while IFS="$TAB" read -r from to only want; do
	[ -z "$from" ] && continue
	mutate bridge/ai_bridge.gd "$from" "$to" tests/test_ai_bridge.gd "$only" "$want" --faults
done <<'EOF'
{"text": 0, "voice": 1	{"text": 2, "voice": 1	stub_session	text > voice > portrait
\t_in_flight = {}\n\t_kill()\n\t_charge_interrupted(r)	\t_in_flight = {}\n\t_close_pipes()\n\t_charge_interrupted(r)	timeouts	hung child (cannot exit by itself) killed
int(timeout_ms[_in_flight["kind"]])	int(timeout_ms["text"])	timeouts	voice cancelled timeout
if chunk.is_empty():\n\t\t\tbreak\n\t\tgot = true	if chunk.is_empty():\n\t\t\tOS.delay_msec(60)\n\t\t\tbreak\n\t\tgot = true	timeouts	frame never blocked
_queues[PRIORITY[_in_flight["kind"]]].push_front(_in_flight)	pass	crash_loop	both answered after one restart
(backoff_delay(_consecutive) if backoff else 0)	0	crash_loop	backoff
const FAIL_LIMIT := 3	const FAIL_LIMIT := 4	crash_loop	three launches
if now - t < FAIL_WINDOW_MS:	if true:	crash_loop	third failure 11 min later
_line_bytes.append_array(chunk)	_line_bytes = chunk	assemble	three lines from five chunks
 and int(proto["major"]) == PROTO_MAJOR:	:	handshake_faults	proto.major 2 refused
var argv := scrubbed(plan)	var argv := PackedStringArray(["-c", 'exec "$@"', "sh", plan["bin"]]) + PackedStringArray(plan["args"])	stub_session	inherits no pipe of Godot's
func poll() -> void:\n\tvar t0 := Time.get_ticks_usec()	func poll() -> void:\n\tvar t0 := Time.get_ticks_usec()\n\tif randi() % 25 == 0: OS.delay_msec(10)	static	no blocking call reachable
func poll() -> void:\n\tvar t0 := Time.get_ticks_usec()	func poll() -> void:\n\tvar t0 := Time.get_ticks_usec()\n\tif _phase == Phase.BUSY and randi() % 40 == 0: OS.delay_msec(30)	static	no blocking call reachable
func poll() -> void:\n\tvar t0 := Time.get_ticks_usec()	func poll() -> void:\n\tvar t0 := Time.get_ticks_usec()\n\tif randi() % 25 == 0:\n\t\tvar w := Time.get_ticks_msec() + 10\n\t\twhile Time.get_ticks_msec() < w: pass	timeouts	frame never blocked
func poll() -> void:\n\tvar t0 := Time.get_ticks_usec()	func poll() -> void:\n\tvar t0 := Time.get_ticks_usec()\n\tif _phase == Phase.BUSY and randi() % 40 == 0:\n\t\tvar w := Time.get_ticks_msec() + 30\n\t\twhile Time.get_ticks_msec() < w: pass	timeouts	frame never blocked
case $n in [3-9]) eval "exec $n>&-" 2>/dev/null;; [1-9][0-9]*) [ -n "$BASH_VERSION" ] && eval "exec $n>&-" 2>/dev/null;; esac;	[ "$n" -gt 2 ] 2>/dev/null && eval "exec $n>&-" 2>/dev/null;	static	FD_SCRUB under /bin/dash
return "/bin/bash" if FileAccess.file_exists("/bin/bash") else "/bin/sh"	return "/bin/dash" if FileAccess.file_exists("/bin/dash") else "/bin/sh"	static	[5, 12, 13] closed
args.append_array(["--ai", image, "--ai-key-file", key_files["gemini"]])	args.append_array(["--ai", image])	live_plan	--ai gemini-2.5-flash-image --ai-key-file
"IO,FS,Env,Net,AI", "--ai-no-adc"])	"IO,FS,Env,Net,AI"])	live_plan	--ai-no-adc in the ailang arguments
exec /usr/bin/env -i PATH=	exec /usr/bin/env PATH=	live_env	no FOO_API_KEY
[ "$a" = 1 ] && l=AI_LIVE=1;	l=AI_LIVE=1;	live_env	AI_LIVE absent
"spent": spent_list()}	"spent": []}	session_ceiling	a fresh process per request
usage_from = f.get_length() if f != null else 0	usage_from = 0	session_ceiling	a fresh process per request
\t_kill()\n\t_charge_interrupted(r)\n\t_cancel(r, "timeout")	\t_kill()\n\t_cancel(r, "timeout")	killed_charge	timeout: 
\t_kill()\n\t_charge_interrupted(r)\n\t_failure(code)	\t_kill()\n\t_failure(code)	killed_charge	fault: 
DirAccess.remove_absolute(reserve_path()) # a reservation now is this request's	pass	killed_charge	left before send
u.get("req") == r.get("req") and 	true and 	killed_charge	stale req
GOOGLE_API_KEY=$(cat "$1")	GOOGLE_API_KEY=$(cat $1)	live_env	keys from the files only
shift 2; exec "$@"'	shift 2; exec $@'	live_env	keeps the spaced path whole
\t\t_charge_interrupted(_in_flight)	\t\tpass	killed_charge	quit mid-call
var n: int = MAX_LINE_NUSD if not usd < MAX_LINE_NUSD / 1.0e9 else mini(roundi(usd * 1.0e9), MAX_LINE_NUSD)	var n: int = roundi(usd * 1.0e9)	absurd_spend	two usd 1e300 lines
out[u["route"]] = mini(out[u["route"]] + n, MAX_LINE_NUSD)	out[u["route"]] += n	absurd_spend	two usd 1e300 lines
for d in ["res://ai", "res://data/ai"]:	for d in ["res://data/ai"]:	static	unpack digest covers every ai/*.ail
var digest := unpack_digest()	var digest := FileAccess.get_file_as_string("res://ai/service.ail").sha256_text()	static	_unpack_ai writes that digest
EOF
while IFS="$TAB" read -r src from to only want; do
	[ -z "$src" ] && continue
	mutate "$src" "$from" "$to" tests/test_ai_settings.gd "$only" "$want"
done <<'EOF'
bridge/ai_session.gd	if settings.automation and _hello_out == "":	if false:	key_edges	automation run (--map-capture): no indicator
bridge/ai_session.gd	settings.forget_session_keys() # a crash	pass # a crash	key_edges	stale session key files removed at startup
ui/settings/ai_settings.gd	FileAccess.get_file_as_string(key_path(p)).strip_edges() != ""	true	key_edges	a key file holding nothing is no key
bridge/ai_bridge.gd	f.seek(usage_from)	f.seek(0)	indicator_budget	the earlier session's 5.0 not counted
EOF
while IFS="$TAB" read -r src from to only want; do
	[ -z "$src" ] && continue
	mutate "$src" "$from" "$to" tests/test_conversation.gd "$only" "$want"
done <<'EOF'
ui/conversation/conversation.gd	t_ms >= float(offsets[_seg + 1]) + swap_offset_ms	t_ms >= float(offsets[_seg + 1])	offset	swaps at
ui/conversation/conversation.gd	offsets = segs_ms.map(func(x): return int(x))	offsets = reading_offsets(segments)	swaps	each swap within one frame after its offset
ui/conversation/conversation.gd	clampf((t_ms - _fade_from) / crossfade_ms, 0.0, 1.0)	1.0	swaps	each crossfade completes crossfade_ms after its swap
ui/conversation/conversation.gd	segments.slice(0, i + 1)	segments	swaps	subtitle reveals two segments
ui/conversation/conversation.gd	var e := cache.portrait_for(entity, emotion, years)	var e := cache.lookup({"kind": "portrait", "entity_id": entity, "emotion": emotion, "variant": "0"}, years)	fallback	happy -> loving, angry -> neutral, sad -> grieving
ui/conversation/conversation.gd	if e.is_empty():\n\t\t\t_log("missing_blob"	if false:\n\t\t\t_log("missing_blob"	no_audio	missing_blob logged, no stream
bridge/ai_cache.gd	get_basename() + ".wav"	get_basename() + ".ogg"	swaps	the WAV stream is loaded
bridge/ai_relay.gd	"voice": c["voice_id"]	"voice": "Kore"	swaps	the relay's cast comes from medic.json
EOF
echo "ai-bridge-mutants: $n mutants, $fails not killed"
[ "$fails" -eq 0 ]
