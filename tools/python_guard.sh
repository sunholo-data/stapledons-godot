#!/bin/sh
# Enforce the Python policy (CLAUDE.md "Python"; roles in tools/python-allowlist.txt).
set -eu
list=tools/python-allowlist.txt
roles="oracle harness spike evidence port"
fail=0
entries=$(grep -v '^#' "$list" | grep -v '^[[:space:]]*$')
for f in $(git ls-files '*.py'); do
  if ! printf '%s\n' "$entries" | cut -f1 | grep -qx "$f"; then
    echo "python-guard: $f is not in $list (the game is AILANG + Godot; see CLAUDE.md 'Python')"; fail=1
  fi
done
printf '%s\n' "$entries" | while IFS="$(printf '\t')" read -r path role; do
  [ -f "$path" ] || { echo "python-guard: stale entry $path"; exit 1; }
  case " $roles " in *" $role "*) ;; *) echo "python-guard: $path has unknown role '$role'"; exit 1;; esac
  case "$path" in sim/*|sky/*|physics/*|bridge/*|ui/*|*.gd) echo "python-guard: $path is in a runtime directory"; exit 1;; esac
done || fail=1
for f in $(grep -o 'python3 [^ ;"]*\.py' Makefile | cut -d' ' -f2 | sort -u); do
  role=$(printf '%s\n' "$entries" | awk -F'\t' -v p="$f" '$1 == p {print $2}')
  case "$role" in oracle|harness|port) ;; *) echo "python-guard: Makefile runs $f (role '${role:-unlisted}'); only oracle, harness or port may run"; fail=1;; esac
done
count=$(printf '%s\n' "$entries" | wc -l | tr -d ' ')
ports=$(printf '%s\n' "$entries" | awk -F'\t' '$2 == "port"' | wc -l | tr -d ' ')
[ "$fail" = 0 ] && echo "python-guard: ok ($count allowlisted, $ports awaiting AILANG port)"
exit "$fail"
