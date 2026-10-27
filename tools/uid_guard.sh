#!/bin/bash
# Every tracked script and shader has its Godot .uid tracked beside it (CLAUDE.md "Checkouts and
# Godot .uid files"). An untracked .uid makes every checkout look dirty to git and the checkout audit.
set -eu
want=$(git ls-files '*.gd' '*.gdshader' '*.gdshaderinc' | sed 's/$/.uid/' | sort)
have=$(git ls-files '*.uid' | sort)
missing=$(comm -23 <(printf '%s\n' "$want") <(printf '%s\n' "$have") | grep . || true)
stale=$(comm -13 <(printf '%s\n' "$want") <(printf '%s\n' "$have") | grep . || true)
for u in $missing; do echo "uid-guard: $u is not tracked (git add $u)"; done
for u in $stale; do echo "uid-guard: $u is tracked but ${u%.uid} is not"; done
[ -z "$missing$stale" ] || exit 1
echo "uid-guard: ok ($(printf '%s\n' "$have" | wc -l | tr -d ' ') .uid files)"
