#!/bin/sh
# make ai-live-guard (AI.9, AC15): no automation can start a live provider.
# The live service refuses before any call unless AI_LIVE=1 and a key are in
# its environment (ai/service.ail `live`); this guard keeps every path that
# could put AI_LIVE=1 there narrow and visible. Static rules over ROOT:
#   A  Makefile, mk/*.mk, *.sh, .github: a line that runs the service live
#      (--entry live, --provider gemini|openrouter, a non-stub "provider" in
#      its arguments) must clear AI_LIVE on that line (env -u AI_LIVE, or
#      $(AI_NOKEYS)).
#   B  tests/ and tools/: never `live_allowed = true`; AI_LIVE=1 set in a
#      process environment only by tests/test_ai_relay.gd (AI.7 F3: around its
#      hello-only spawns, cleared again), which is safe because live_allowed
#      defaults to false and the live wrapper clears AI_LIVE (rule D).
#   C  Makefile, mk, .github, tests, tools: no shell or YAML assignment
#      AI_LIVE=1 (messages naming it are not assignments).
#   D  the launch builder (bridge/ai_bridge.gd): `live` and `live_allowed`
#      default to false; the wrapper runs under `env -i` and passes AI_LIVE=1
#      only when its allowed argument is 1, which live_plan sets only from
#      live_allowed; Gemini is bound with --ai-key-file and --ai-no-adc.
#   E  outside tests, live_allowed is written only by AiSettings.apply, from
#      live_on(), which is false in automation runs.
# The runtime half (the builder run with AI_LIVE unset emits the stub with
# --caps IO,FS) is tests/test_ai_settings.gd --launch-default.
# AI.10b's attended `make ai-live` will need its own narrow exception here.
# Usage: tools/ai_live_guard.sh [ROOT]   exit 1 and one line per breach.
set -u
cd "${1:-.}" || exit 2
fails=0
fail() { printf 'ai-live-guard: %s\n' "$*"; fails=$((fails + 1)); }
# Mutation tables are exempt (they hold the breaches on purpose): the rows of
# this guard's own mutant list in mk/ai.mk (ending "@<rule> ...' \") and the
# TAB-separated rows of tests/ai_bridge_mutants.sh.
TAB=$(printf '\t')
exempt() { grep -vE "@[A-E] [^']*' \\\\$|^[0-9]+:[^$TAB]+$TAB[^$TAB]*$TAB[^$TAB]*$TAB"; }
T=$(mktemp) || exit 2

shellish=$(find Makefile mk .github tests tools -type f \( -name Makefile -o -name '*.mk' -o -name '*.sh' -o -name '*.yml' -o -name '*.yaml' \) 2>/dev/null | grep -v "^tools/ai_live_guard.sh$" | sort)
scripts=$(find tests tools -type f \( -name '*.gd' -o -name '*.py' -o -name '*.sh' \) 2>/dev/null | grep -v "^tools/ai_live_guard.sh$" | sort)

# A
for f in $shellish; do
	grep -nE -- '(^|[^a-z])run .*(--entry[ =]live|--provider[ =](gemini|openrouter)|"provider" *: *"(gemini|openrouter|live)")' "$f" \
		| grep -vE -- '-u AI_LIVE|\$\(AI_NOKEYS\)' | grep -vE "^[0-9]+:[[:space:]]*#" | exempt | while IFS= read -r l; do echo "A $f:$l"; done
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
for f in $shellish $scripts; do
	grep -nE '(^|[^A-Za-z0-9_])(export +)?AI_LIVE(=|: *)["'"'"']?1' "$f" \
		| grep -vE "^[0-9]+:[[:space:]]*#" | grep -vE 'AI_LIVE=1 is not set|without AI_LIVE=1|AI_LIVE=1\)|AI_LIVE=1 and|with AI_LIVE=1|AI_LIVE=1 reaches|AI_LIVE=1 passes|AI_LIVE=1 in Godot' \
		| exempt | while IFS= read -r l; do echo "C $f:$l"; done
done >> $T
# D
B=bridge/ai_bridge.gd
grep -qE '^var live_allowed := false$' $B || echo "D $B: live_allowed must default to false" >> $T
grep -qE '^var live := false$' $B || echo "D $B: live must default to false" >> $T
grep -qE '^const LIVE_WRAP := .*\[ "\$a" = 1 \] && l=AI_LIVE=1.*exec /usr/bin/env -i ' $B || echo "D $B: LIVE_WRAP must exec under env -i and pass AI_LIVE=1 only when allowed" >> $T
grep -qF '"1" if live_allowed else "0"' $B || echo "D $B: live_plan must take AI_LIVE's permission from live_allowed only" >> $T
grep -qF '"--ai-key-file", key_files["gemini"]' $B && grep -qF '"--ai-no-adc"' $B || echo "D $B: Gemini must be bound with --ai-key-file and --ai-no-adc (ADC never wins)" >> $T
# E
w=$(find . -maxdepth 4 -name '*.gd' -not -path './tests/*' -not -path './tools/*' -not -path './.godot/*' -not -path './build/*' 2>/dev/null | xargs grep -lE 'live_allowed *= ' 2>/dev/null | sort | tr '\n' ' ')
[ "$w" = "./ui/settings/ai_settings.gd " ] || echo "E live_allowed written outside AiSettings.apply: $w" >> $T
S=ui/settings/ai_settings.gd
if [ -f $S ]; then
	grep -qE '^	bridge\.live_allowed = on$' $S && grep -qE '^	var on := live_on\(\)$' $S || echo "E $S: apply must set live_allowed from live_on() only" >> $T
	grep -qE '^	return opt_in and not automation and not keys_present\(\)\.is_empty\(\)$' $S || echo "E $S: live_on() must be false in automation runs and without a key or the tick" >> $T
fi
while IFS= read -r l; do fail "$l"; done < $T
rm -f $T
[ $fails -eq 0 ] && echo "ai-live-guard: ok ($(echo $shellish | wc -w | tr -d ' ') make/shell/CI files, $(echo $scripts | wc -w | tr -d ' ') test/tool scripts, launch builder, settings)"
[ $fails -eq 0 ]
