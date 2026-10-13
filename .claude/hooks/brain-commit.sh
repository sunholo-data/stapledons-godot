#!/usr/bin/env bash
# brain-commit.sh: bank each git commit as a resolution frame in the PROJECT brain
# (.ailang/state/brain.db of the main checkout), so the UserPromptSubmit hook
# (ailang's scripts/hooks/brain_on_prompt.sh, wired in .claude/settings.json) can
# inject it later by semantic search.
#
# Why not ailang's own brain_resolution.sh: it reads the commit from the session's
# cwd. Attended work here commits in a separate full clone (no worktrees, see
# CLAUDE.md), as `cd <clone> && git commit ...`, so it would bank the main
# checkout's HEAD instead. And `ailang cache` picks the project brain from its cwd;
# a separate clone has its own cold brain. So: read the commit where it was made,
# write the frame from the main checkout.
#
# Hook mode (PostToolUse, Bash): reads the hook JSON on stdin.
# Backfill mode: brain-commit.sh --backfill <rev-range> [dir]
#   e.g. .claude/hooks/brain-commit.sh --backfill origin/main
# Switches: AILANG_BRAIN_HOOKS=0 disables. Never fails the tool call.

set +e
[ "${AILANG_BRAIN_HOOKS:-1}" = "0" ] && exit 0
command -v ailang >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

MAIN="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
MAX_ENRICH=2048

# Bank one commit: $1 = repo dir, $2 = sha.
bank() {
	local dir="$1" sha="$2" msg stat files enrich="" f rem
	msg=$(git -C "$dir" log -1 --format='%s%n%n%b' "$sha" 2>/dev/null | head -c 1500)
	[ -z "$msg" ] && return
	stat=$(git -C "$dir" show --stat --format= "$sha" 2>/dev/null | tail -1)
	files=$(git -C "$dir" show --name-only --format= "$sha" 2>/dev/null | head -60 | tr '\n' ',' | sed 's/,$//')
	# Design docs and changelog fragments carry the "why": the first 2 KB, as of that commit.
	while IFS= read -r f; do
		case "$f" in
			design_docs/*.md|changelogs/*.md|CLAUDE.md) ;;
			*) continue ;;
		esac
		rem=$((MAX_ENRICH - ${#enrich}))
		[ "$rem" -le 200 ] && break
		enrich="${enrich}
--- ${f} ---
$(git -C "$dir" show "$sha:$f" 2>/dev/null | head -c "$rem")"
	done < <(git -C "$dir" show --name-only --format= "$sha" 2>/dev/null)
	local args=(--commit-msg "$msg" --diff-summary "$stat" --files "$files" --source "hook:commit:stapledons-godot:${sha:0:10}" --embed)
	[ -n "$enrich" ] && args+=(--enrich "$enrich")
	(cd "$MAIN" && ailang cache put-resolution "${args[@]}" >/dev/null 2>&1)
}

if [ "$1" = "--backfill" ]; then
	range="${2:-HEAD}"; dir="${3:-$MAIN}"; n=0
	for sha in $(git -C "$dir" rev-list --no-merges --reverse "$range"); do
		bank "$dir" "$sha"; n=$((n + 1))
		[ $((n % 50)) = 0 ] && echo "banked $n"
	done
	echo "banked $n commits from $range"
	exit 0
fi

HOOK_JSON=$(cat 2>/dev/null || echo "{}")
[ "$(echo "$HOOK_JSON" | jq -r '.tool_name // ""')" = "Bash" ] || exit 0
CMD=$(echo "$HOOK_JSON" | jq -r '.tool_input.command // ""')
echo "$CMD" | grep -qE 'git( -C [^ ]+)? commit' || exit 0

# Where the commit happened: `git -C <dir> commit`, else a leading `cd <dir>`, else the cwd.
DIR=$(echo "$CMD" | sed -nE 's/.*git -C ([^ ;&|]+) commit.*/\1/p' | head -1)
[ -z "$DIR" ] && DIR=$(echo "$CMD" | sed -nE 's/^[[:space:]]*cd ([^ ;&|]+).*/\1/p' | head -1)
[ -z "$DIR" ] && DIR=$(echo "$HOOK_JSON" | jq -r '.cwd // ""')
DIR="${DIR/#\~/$HOME}"
DIR="${DIR//\"/}"
[ -d "$DIR" ] || exit 0
git -C "$DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
SHA=$(git -C "$DIR" rev-parse HEAD 2>/dev/null)
[ -z "$SHA" ] && exit 0

# Once per commit, across every clone (the marker lives in the main checkout's .git).
MARK="$(git -C "$MAIN" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)/stapledon_brain_banked"
grep -qx "$SHA" "$MARK" 2>/dev/null && exit 0
echo "$SHA" >> "$MARK"
bank "$DIR" "$SHA" &
exit 0
