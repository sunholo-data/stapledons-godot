#!/bin/sh
# M4.7 `make lore-check`: glue that lists the entry files and runs sim/tools/lore_check.ail (strict
# VM bodies; the FS shell runs on the VM with evaluator fallback for readFile).
#   LORE=<file>   check that one file (positive controls, tests/fixtures/lore/*.md), no allowlist
#   LORE=<dir>    check every entry in it, no allowlist
#   (unset)       check data/lore/archive/*.md (not README.md), id = archive.<file name>, with
#                 data/lore/unbound.txt
# Env: LORE_DATA (default data/lore), AILANG.
set -u
AILANG=${AILANG:-ailang}
LORE_DATA=${LORE_DATA:-data/lore}
LORE=${LORE:-}
if [ -z "$LORE" ]; then
  LIST=$(ls "$LORE_DATA"/archive/*.md | grep -v '/README.md$'); NAMED=true; ALLOW="$LORE_DATA/unbound.txt"
elif [ -d "$LORE" ]; then
  LIST=$(ls "$LORE"/*.md | grep -v '/README.md$'); NAMED=false; ALLOW=""
else
  LIST=$LORE; NAMED=false; ALLOW=""
fi
FILES=$(echo "$LIST" | awk 'BEGIN{printf "["} {printf "%s\"%s\"", (NR>1?",":""), $0} END{printf "]"}')
exec $AILANG run --quiet --bytecode --caps IO,FS --package-dir sim --entry loreCheck \
  --args-json "{\"registry\":\"$LORE_DATA/check_values.json\",\"files\":$FILES,\"named\":$NAMED,\"allow\":\"$ALLOW\"}" sim/tools/lore_check.ail
