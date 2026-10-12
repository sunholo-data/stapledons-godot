#!/bin/sh
# make ai-live-guard (AI.9, AC15): no automation can start a live provider.
# The live service refuses before any call unless AI_LIVE=1 and a key are in
# its environment (ai/service.ail `live`); this guard keeps every path that
# could put AI_LIVE=1 there narrow and visible. Static rules over ROOT:
#   A  Makefile, every *.mk, .github and every tracked *.sh, *.py, *.gd
#      (tests/, tools/, ui/, bridge/, ...): a line that could run the service live must clear AI_LIVE on
#      that line (env -u AI_LIVE, or $(AI_NOKEYS)). Lines are normalised first
#      (quotes dropped, runs of blanks one space; AI.9 hardening), so
#      `--entry  live`, `--entry "live"` and `"--entry", "live"` all match.
#      Could run live: --entry live; --entry with a non-literal value ($x,
#      ${x}, $(X), a Python/GDScript variable), unless the line pins
#      --package-dir sim and names a literal sim/...ail program (the sim has
#      no live entry) and no ai/ package; every `include` points into mk/;
#      --provider gemini|openrouter|live; a non-stub "provider" in the
#      arguments of a run line.
#   B  every tracked script: never `live_allowed = true`; AI_LIVE=1 set in a
#      process environment only by tests/test_ai_relay.gd (AI.7 F3: around its
#      hello-only spawns, cleared again), which is safe because live_allowed
#      defaults to false and the live wrapper clears AI_LIVE (rule D).
#   C  the files of rule A: no assignment or mapping of
#      AI_LIVE to anything (AI_LIVE=, AI_LIVE: , "AI_LIVE": in a Python or
#      GDScript dict); messages naming AI_LIVE=1 are not assignments.
#   D  the launch builder (bridge/ai_bridge.gd): `live` and `live_allowed`
#      default to false; the wrapper runs under `env -i` and passes AI_LIVE=1
#      only when its allowed argument is 1, which live_plan sets only from
#      live_allowed; Gemini is bound with --ai-key-file and --ai-no-adc.
#   E  outside tests, live_allowed is written only by AiSettings.apply, from
#      live_on(), which is false in automation runs. Files are the tracked
#      ones (git ls-files) when ROOT is a work tree, so another checkout under
#      it (.claude/worktrees/*) can never make the guard pass or fail.
# The runtime half (the builder run with AI_LIVE unset emits the stub with
# --caps IO,FS) is tests/test_ai_settings.gd --launch-default.
# AI.10b's attended `make ai-live` will need its own narrow exception here.
# Usage: tools/ai_live_guard.sh [ROOT]   exit 1 and one line per breach.
set -u
cd "${1:-.}" || exit 2
fails=0
fail() { printf 'ai-live-guard: %s\n' "$*"; fails=$((fails + 1)); }
T=$(mktemp) || exit 2
# Tracked files when ROOT is a work tree (AI.9 hardening), else every file
# (the mutation check runs on a plain copy of the tracked files).
if [ "$(git rev-parse --show-toplevel 2>/dev/null)" = "$(pwd -P)" ]; then
	files() { git ls-files -- "$@"; }
else
	files() { find "$@" -type f 2>/dev/null; }
fi
# Every tracked make file (an `include`d one anywhere is scanned too), shell
# script, CI file, and every tracked .gd, .py and .sh (ui/ and bridge/ too).
shellish=$( (files Makefile mk .github tests tools; files . | sed 's|^\./||' | grep -E '\.mk$') | grep -E '(^|/)Makefile$|\.mk$|\.sh$|\.ya?ml$' | grep -v "^tools/ai_live_guard.sh$" | sort -u)
scripts=$(files . | sed 's|^\./||' | grep -E '\.(gd|py|sh)$' | grep -vE '^(\.godot|build|runtime)/' | grep -v "^tools/ai_live_guard.sh$" | sort)
scanned=$(printf '%s\n' $shellish $scripts | sort -u)

# Mutation tables hold breaches on purpose and are exempt, by place and shape
# only (AI.9 hardening round 2): in mk/ai.mk, the rows of the ai-live-guard
# recipe's `for m in \ ... ; do \` list, each one single-quoted string and
# nothing else ('"'"' is an escaped quote inside it); in
# tests/ai_bridge_mutants.sh, the here-documents that feed its mutation loops
# (opened by a line `done <<'EOF'`), not any other here-document. In
# bridge/ai_bridge.gd, the launch builder that rule D pins: the LIVE_WRAP line
# and live_plan's `"--entry", "live"` line. A comment line is never a breach.
EXEMPT='
	$in_guard = 1 if $f eq "mk/ai.mk" && /^ai-live-guard:/;
	$in_guard = 0 if $in_guard && /^\s*$/;
	if ($in_table) { $in_table = 0 if /; do \\$/; next if /^\t  \x27(?:[^\x27]|\x27"\x27"\x27)*\x27( \\|; do \\)$/; }
	$in_table = 1 if $in_guard && /for m in \\$/;
	if ($f eq "tests/ai_bridge_mutants.sh") { if (/^done <<\x27EOF\x27$/) { $heredoc = 1; next } if ($heredoc && /^EOF$/) { $heredoc = 0; next } next if $heredoc; }
	next if $f eq "bridge/ai_bridge.gd" && (/^const LIVE_WRAP := / || /^\targs\.append_array\(\["--net-allow-domains", LIVE_HOSTS, "--entry", "live", "--args-json", SimBridge\.encode\(cfg\), /);
	next if /^\s*#/;
'
# A
for f in $scanned; do
	F="$f" perl -ne '
		BEGIN { $f = $ENV{F}; $py = ($f =~ /\.(py|gd)$/); }
		'"$EXEMPT"'
		chomp; my $raw = $_; my $n = $raw;
		$n =~ tr/"\x27//d; $n =~ s/[,\[\]]/ /g; $n =~ s/\s+/ /g;
		# The sim has no live entry: a non-literal entry is allowed only on a line
		# pinned to --package-dir sim that also names a literal sim/ program.
		my $sim = $n =~ /--package-dir(?: |=)(?:sim|SIM)(?: |$)/ && $n =~ /(?:^| )(?:\.\/)?sim\/[A-Za-z0-9_\/.-]+\.ail(?: |$)/ && $n !~ /ai\/service|--package-dir(?: |=)\S*ai(?: |$)/;
		my @why;
		if ($py) {
			# argv lists: "--entry", <next> is live unless <next> is a quoted word other than live
			while ($raw =~ /["\x27]--entry["\x27]\s*,\s*([^\s,\]]+)/g) { my $v = $1; my $lit = $v =~ /^["\x27]([A-Za-z_][A-Za-z0-9_]*)["\x27]$/; push @why, "--entry $v" unless ($lit && $1 ne "live") || (!$lit && $sim); }
			push @why, "--entry= + variable" if $raw =~ /["\x27]--entry=["\x27]?\s*\+/;
		}
		while ($n =~ /(?:^| |=)--entry(?:=| )([^ ]+)/g) {
			my $v = $1; $v =~ s/[;|&]+$//; $v =~ s/\)$// unless $v =~ /\(/;
			next if $v =~ /^[A-Za-z_][A-Za-z0-9_]*$/ && $v ne "live";
			next if $v ne "live" && $sim;
			push @why, "--entry $v";
		}
		push @why, "--provider $1" if $n =~ /(?:^| |=)--provider(?:=| )(gemini|openrouter|live)\b/ && $n =~ /(^|[^a-z])run |--entry/;
		push @why, "provider $1" if $n =~ /(^|[^a-z])run / && $n =~ /provider ?: ?(gemini|openrouter|live)\b/;
		print "A $f: include outside mk/: $raw\n" if $f =~ /(^|\/)Makefile$|\.mk$/ && /^-?include\s/ && !/^-?include\s+mk\/[A-Za-z0-9_.-]+\.mk\s*$/;
		next unless @why;
		next if $n =~ /-u AI_LIVE(?: |$)|\$\(AI_NOKEYS\)/;
		print "A $f:$.:$raw (" . join(", ", @why) . "; AI_LIVE not cleared on the line)\n";
	' "$f"
done > $T
# B
for f in $scripts; do
	grep -nE 'live_allowed *:?= *true' "$f" | while IFS= read -r l; do echo "B $f:$l (live_allowed = true outside the settings)"; done
	[ "$f" = tests/test_ai_relay.gd ] && continue
	grep -nE 'set_environment\("AI_LIVE"|environ\[.AI_LIVE.\] *=|putenv\(.AI_LIVE' "$f" | while IFS= read -r l; do echo "B $f:$l (only tests/test_ai_relay.gd may set AI_LIVE)"; done
done >> $T
if [ -f tests/test_ai_relay.gd ] && grep -q 'set_environment("AI_LIVE"' tests/test_ai_relay.gd && ! grep -q 'unset_environment("AI_LIVE")' tests/test_ai_relay.gd; then
	echo "B tests/test_ai_relay.gd sets AI_LIVE and never unsets it" >> $T
fi
# C
for f in $scanned; do
	F="$f" perl -ne '
		BEGIN { $f = $ENV{F}; }
		'"$EXEMPT"'
		next unless /(^|[^A-Za-z0-9_])AI_LIVE["\x27]? *[:=]/;
		(my $m = $_) =~ s/AI_LIVE=1 (is not set|and|reaches|passes|in Godot)|(without|with) AI_LIVE=1|AI_LIVE=1\)//g;
		next unless $m =~ /(^|[^A-Za-z0-9_])AI_LIVE["\x27]? *[:=]/;
		chomp; print "C $f:$.:$_\n";
	' "$f"
done >> $T
# D
B=bridge/ai_bridge.gd
grep -qE '^var live_allowed := false$' $B || echo "D $B: live_allowed must default to false" >> $T
grep -qE '^var live := false$' $B || echo "D $B: live must default to false" >> $T
grep -qE '^const LIVE_WRAP := .*\[ "\$a" = 1 \] && l=AI_LIVE=1.*exec /usr/bin/env -i ' $B || echo "D $B: LIVE_WRAP must exec under env -i and pass AI_LIVE=1 only when allowed" >> $T
grep -qF '"1" if live_allowed else "0"' $B || echo "D $B: live_plan must take AI_LIVE's permission from live_allowed only" >> $T
grep -qF '"--ai-key-file", key_files["gemini"]' $B && grep -qF '"--ai-no-adc"' $B || echo "D $B: Gemini must be bound with --ai-key-file and --ai-no-adc (ADC never wins)" >> $T
# E
w=$(files . | sed 's|^\./||' | grep -E '\.gd$' | grep -vE '^(tests|tools|\.godot|build)/' | while IFS= read -r g; do grep -lE 'live_allowed *= ' "$g"; done | sort | tr '\n' ' ')
[ "$w" = "ui/settings/ai_settings.gd " ] || echo "E live_allowed written outside AiSettings.apply: $w" >> $T
S=ui/settings/ai_settings.gd
if [ -f $S ]; then
	grep -qE '^	bridge\.live_allowed = on$' $S && grep -qE '^	var on := live_on\(\)$' $S || echo "E $S: apply must set live_allowed from live_on() only" >> $T
	grep -qE '^	return opt_in and not automation and not keys_present\(\)\.is_empty\(\)$' $S || echo "E $S: live_on() must be false in automation runs and without a key or the tick" >> $T
fi
while IFS= read -r l; do fail "$l"; done < $T
rm -f $T
[ $fails -eq 0 ] && echo "ai-live-guard: ok ($(echo $shellish | wc -w | tr -d ' ') make/shell/CI files, $(echo $scripts | wc -w | tr -d ' ') test/tool scripts, launch builder, settings)"
[ $fails -eq 0 ]
