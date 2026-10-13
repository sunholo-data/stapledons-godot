#!/usr/bin/env bash
# brain-prompt.sh (UserPromptSubmit): inject up to 3 PROJECT-brain frames matching the
# prompt (`ailang cache search`, embeddinggemma), the frames .claude/hooks/brain-commit.sh banks.
#
# Why not ailang's scripts/hooks/brain_on_prompt.sh: it searches user + project brains at a
# 0.70 floor calibrated on the AILANG corpus. Measured here 2026-10-13 (631 commits backfilled):
# project-scope on-topic prompts score 0.55-0.66, off-topic 0.33-0.36; and one user-brain frame
# ("SESSION-NOTES-2026-05-14: motoko_ext_ailang_docs") scores 0.62-0.70 on anything, weather
# included. So: project scope, floor 0.55.
#
# Switches: AILANG_BRAIN_HOOKS=0 or AILANG_BRAIN_ON_PROMPT=0 disables; STAPLEDON_BRAIN_MIN_SCORE,
# STAPLEDON_BRAIN_LIMIT tune. Frozen mission stages and coordinator tasks get nothing (as
# ailang's hook: their inputs must not vary with the brain's contents).

[ -n "${AILANG_MISSION_STAGE:-}" ] && exit 0
[ -n "${AILANG_TASK_ID:-}" ] && exit 0
[ "${AILANG_BRAIN_HOOKS:-1}" = "0" ] && exit 0
[ "${AILANG_BRAIN_ON_PROMPT:-1}" = "0" ] && exit 0
command -v ailang >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

PROMPT=$(jq -r '.prompt // ""' 2>/dev/null)
[ "${#PROMPT}" -lt 25 ] && exit 0
MIN="${STAPLEDON_BRAIN_MIN_SCORE:-0.55}"
LIMIT="${STAPLEDON_BRAIN_LIMIT:-3}"

cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0
RESULT=$(perl -e 'alarm shift; exec @ARGV' 3 ailang cache search -json -limit "$LIMIT" -scope project "$PROMPT" 2>/dev/null)
[ -z "$RESULT" ] && exit 0

CTX=$(echo "$RESULT" | jq -r --arg min "$MIN" '
  (.results // []) | map(select((.score // 0) >= ($min | tonumber)))
  | if length == 0 then "" else
      "Project brain (past commits matching this prompt; background, verify before relying on it):\n" +
      ([.[] | "  - (" + ((.score * 100 | floor) / 100 | tostring) + ") "
              + ((.content // "") | gsub("\\s+"; " ") | .[0:220])] | join("\n"))
    end' 2>/dev/null)
[ -z "$CTX" ] && exit 0

jq -n --arg ctx "$CTX" '{hookSpecificOutput: {hookEventName: "UserPromptSubmit", additionalContext: $ctx}}'
exit 0
