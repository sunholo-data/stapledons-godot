#!/bin/bash
# PreToolUse(Bash) guard: refuse unbounded filesystem walks over home or root.
# An agent's `find ~ -path ...` hung the rig on 2026-10-02 (iCloud, network
# mounts, huge trees). Allowed: searches inside the repo or a worktree, known
# paths, or a walk over a broad root with -maxdepth <= 3.
cmd=$(jq -r '.tool_input.command // empty')
[ -z "$cmd" ] && exit 0
# Only judge what runs: drop heredoc bodies and quoted strings (commit
# messages, docs text and patterns often mention these commands).
cmd=$(printf '%s' "$cmd" | perl -0777 -pe '
  s/<<-?\s*([\x27"]?)(\w+)\1[^\n]*\n.*?\n\s*\2\s*(\n|$)/ /gs;
  my $r = qr{^(?:/|~|~/|\$HOME|\$\{HOME\}|/Users(?:/[^/ ]+)?(?:/dev)?|/Volumes|/private|/System|~/dev|\$HOME/dev)/?$};
  s/"((?:\\.|[^"\\])*)"/ do { my $x = $1; ($x =~ $r) ? $x : q("") } /gse;
  s/\x27([^\x27]*)\x27/ do { my $x = $1; ($x =~ $r) ? $x : q("") } /gse;')

# Broad roots: / ~ $HOME /Users[/name] /Volumes /private /System ~/dev, as the
# whole path argument (optionally with a trailing slash).
roots='(/|~|~/|\$HOME|\$\{HOME\}|/Users|/Users/[^/ ]+|/Volumes|/private|/System|~/dev|\$HOME/dev|/Users/[^/ ]+/dev)/?'
walkers='(find|fd|rg|grep[[:space:]]+(-[a-zA-Z]*[rR][a-zA-Z]*|--recursive)|mdfind|du)'

if printf '%s' "$cmd" | grep -Eq "(^|[;&|(\`]|[[:space:]])${walkers}([[:space:]]+[^;&|[:space:]]+)*[[:space:]]+(['\"])?${roots}(['\"])?([[:space:]]|$|;|\||\))"; then
  depth=$(printf '%s' "$cmd" | grep -Eo -- '-maxdepth[[:space:]]+[0-9]+' | grep -Eo '[0-9]+' | sort -n | tail -1)
  if [ -n "$depth" ] && [ "$depth" -le 3 ]; then exit 0; fi
  cat >&2 <<'MSG'
Blocked: unbounded filesystem walk over home or root (find/grep -r/rg/fd/du on /, ~, $HOME, /Users, /Volumes, ~/dev ...). It can hang the machine.
Search inside the repo or your worktree instead (git ls-files | grep ..., or find <repo-subdir> -maxdepth 4).
Known paths: AILANG packages are in runtime/cache/registry/<owner>/<pkg>/<ver>/ (also ~/.ailang/cache/registry/...); star data under data/; design repo at ../stapledons-design.
If you truly need a broad root, add -maxdepth 3 or less.
MSG
  exit 2
fi
exit 0
