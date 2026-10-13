#!/bin/sh
# R2-CREW C0 (design crew-integration.md §CI-1, AC7): the crew scenario pack is authored and
# checked in the crew lab (ailang-packages examples/crew-lab/scenarios/stapledon, crew-sim
# --check), then synced here. Never edit data/crew/ by hand: change the lab and re-sync.
#   tools/crew_sync.sh sync <ailang-packages clone> <rev>   copy the pack at <rev>, write SYNC, regenerate
#   tools/crew_sync.sh check                                 SYNC hashes, regenerated module and round trip
set -eu
AILANG=${AILANG:-ailang}
SCRATCH=${SCRATCH:-/tmp/stapledon-crew-sync}
DIR=data/crew
PACK=examples/crew-lab/scenarios/stapledon
# data/crew name <- lab file (D-70 OQ3: last-messages-home comes aboard first)
MAP="scenario.json:last-messages-home.json policy.json:policy.json"
OUT=sim/data/crew_pack.ail

gen() { $AILANG run --quiet --bytecode --caps IO,FS --package-dir sim --entry generate --args-json "{\"dir\":\"$DIR\",\"out\":\"$1\"}" sim/tools/crew_pack.ail; }

case "${1:-}" in
sync)
  src=${2:?usage: sync <ailang-packages clone> <rev>}; rev=${3:?usage: sync <clone> <rev>}
  full=$(git -C "$src" rev-parse "$rev^{commit}")
  mkdir -p "$DIR"
  { echo "source: https://github.com/sunholo-data/ailang-packages/tree/$full/$PACK"
    echo "commit: $full"
    for m in $MAP; do
      name=${m%%:*}; lab=${m#*:}
      git -C "$src" show "$full:$PACK/$lab" > "$DIR/$name"
      echo "$name <- $lab sha256 $(shasum -a 256 "$DIR/$name" | cut -d' ' -f1)"
    done; } > "$DIR/SYNC"
  cat "$DIR/SYNC"
  gen "$OUT" ;;
check)
  for m in $MAP; do
    name=${m%%:*}; want=$(sed -n "s/^$name <- .* sha256 //p" "$DIR/SYNC"); got=$(shasum -a 256 "$DIR/$name" | cut -d' ' -f1)
    [ "$want" = "$got" ] || { echo "crew-sync-check: FAIL: $DIR/$name edited (sha256 $got, SYNC says $want); re-sync from the lab"; exit 1; }
  done
  mkdir -p "$SCRATCH"; gen "$SCRATCH/crew_pack.ail" > /dev/null
  cmp -s "$SCRATCH/crew_pack.ail" "$OUT" || { echo "crew-sync-check: FAIL: $OUT is not what crew_pack.ail generates from $DIR (run make crew-sync)"; exit 1; }
  $AILANG run --quiet --bytecode --caps IO,FS --package-dir sim --entry check --args-json "\"$DIR\"" sim/tools/crew_pack_check.ail | grep -q '^crew-pack: embedded pack equals data/crew$' || { echo "crew-sync-check: FAIL: round trip"; exit 1; }
  echo "crew-sync-check: ok ($(sed -n 's/^commit: //p' "$DIR/SYNC" | cut -c1-7))" ;;
*) echo "usage: $0 sync <ailang-packages clone> <rev> | check"; exit 2 ;;
esac
