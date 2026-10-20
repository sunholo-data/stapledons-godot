#!/bin/sh
# R2-CAPTAIN-ANIMATION review folder (the CA1 pilot pause): captures the captain through the real Bow
# view (tools/captain_review.gd, GPU window), copies the painted cells, and assembles looping
# animated WebPs (img2webp) at game speed and at 3x, the side-by-side and the moonwalk before/after.
# Usage: tools/captain_review.sh <out dir>   (make captain-anim-capture OUT=<dir>)
set -eu
OUT=${1:-build/captain_review}
mkdir -p "$OUT"
OUT=$(cd "$OUT" && pwd)
GODOT=${GODOT:-godot}
command -v img2webp >/dev/null || { echo "captain-review: FAIL img2webp missing (brew install webp)"; exit 1; }
perl -e 'alarm 900; exec @ARGV' "$GODOT" --path . --resolution 1280x720 --script tools/captain_review.gd -- --out="$OUT" > "$OUT/capture.log" 2>&1 || { grep -E '^(FAIL|captain-review)' "$OUT/capture.log"; exit 1; }
grep -E '^(clip|moonwalk|captain-review)' "$OUT/capture.log"
mkdir -p "$OUT/cells" "$OUT/anim"
jq -r ".anim.clips[].stages[][][] | .file" assets/characters/captain/anim_pilot.json | sort -u | while read -r f; do
  cp "assets/characters/captain/$f" "$OUT/cells/"; done
# One loop per clip: game speed and 3x.
jq -c '.clips[]' "$OUT/review_capture.json" | while read -r c; do
  dir=$(echo "$c" | jq -r .dir); name=$(basename "$dir"); ms=$(echo "$c" | jq -r '.ms_per_frame_at_game_speed | floor')
  [ "$ms" -lt 20 ] && ms=20
  img2webp -loop 0 -lossy -q 85 -d "$ms" $(ls "$OUT/$dir"/f??.png) -o "$OUT/anim/${name}.webp" >/dev/null
  img2webp -loop 0 -lossy -q 85 -d "$ms" $(ls "$OUT/$dir"/f??_3x.png) -o "$OUT/anim/${name}_3x.webp" >/dev/null
done
ms=$(jq -r '[.clips[] | select(.kind=="gait") | .ms_per_frame_at_game_speed] | first // 83 | floor' "$OUT/review_capture.json")
img2webp -loop 0 -lossy -q 85 -d "$ms" $(ls "$OUT/side_by_side"/f??.png) -o "$OUT/anim/side_by_side.webp" >/dev/null
for m in before_today after_ca0_stills after_ca0_pilot; do
  img2webp -loop 0 -lossy -q 85 -d 83 $(ls "$OUT/moonwalk/$m"/f??.png) -o "$OUT/anim/moonwalk_${m}.webp" >/dev/null
done
ls "$OUT/anim"
echo "captain-review: $OUT"
