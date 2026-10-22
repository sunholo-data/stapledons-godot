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
# The painted frames at 2x their cell, at game speed.
jq -c '.clips[]' "$OUT/review_capture.json" | while read -r c; do
  name=$(basename "$(echo "$c" | jq -r .dir)"); ms=$(echo "$c" | jq -r '.ms_per_frame_at_game_speed | floor')
  img2webp -loop 0 -lossy -q 90 -d "$ms" $(ls "$OUT/painted/$name"/f??.png) -o "$OUT/anim/${name}_painted_2x.webp" >/dev/null
done
ms=$(jq -r '[.clips[] | select(.kind=="gait") | .ms_per_frame_at_game_speed] | first // 83 | floor' "$OUT/review_capture.json")
img2webp -loop 0 -lossy -q 85 -d "$ms" $(ls "$OUT/side_by_side"/f??.png) -o "$OUT/anim/side_by_side.webp" >/dev/null
for m in before_today after_ca0_stills after_ca0_pilot; do
  img2webp -loop 0 -lossy -q 85 -d 83 $(ls "$OUT/moonwalk/$m"/f??.png) -o "$OUT/anim/moonwalk_${m}.webp" >/dev/null
done
ls "$OUT/anim"
echo "captain-review: $OUT"
# The A/B against the previous review (PREV=<its folder>, PREV_CLIP, PREV_MS a frame) and the
# foot-contact overlays of the moving clip (CLIP, default walk).
CLIP=${CLIP:-walk}
PREV=${PREV:-build/captain_review_jog_v2}
PREV_CLIP=${PREV_CLIP:-jog}
PREV_MS=${PREV_MS:-69.3}
SPEED=$(grep -E '^const WALK_SPEED_MPS := ' demos/ship_consoles.gd | sed 's/.*:= //')
if [ -d "$PREV/clips/${PREV_CLIP}_back" ]; then
  perl -e 'alarm 600; exec @ARGV' "$GODOT" --headless --path . --script tools/captain_overlay.gd -- --out="$OUT" --prev="$(cd "$PREV" && pwd)" --clip="$CLIP" --prev-clip="$PREV_CLIP" --prev-ms="$PREV_MS" > "$OUT/overlay.log" 2>&1 || { tail -5 "$OUT/overlay.log"; exit 1; }
  for f in back profile; do
    ms=$(jq -r ".$f.m_per_frame * 1000 / $SPEED | floor" "$OUT/overlay.json")
    img2webp -loop 0 -lossy -q 90 -d "$ms" $(ls "$OUT/overlay/${CLIP}_$f"/f??.png) -o "$OUT/anim/${CLIP}_${f}_contacts_2x.webp" >/dev/null
    img2webp -loop 0 -lossy -q 85 -d 17 $(ls "$OUT/ab/${CLIP}_$f"/f???.png) -o "$OUT/anim/${CLIP}_${f}_ab_${PREV_CLIP}_${CLIP}.webp" >/dev/null
  done
fi
# D-118: feet on the floor before/after the settle, and the between-frame effect options (GPU window).
perl -e 'alarm 2400; exec @ARGV' "$GODOT" --path . --resolution 1280x720 --script tools/captain_fx_review.gd -- --out="$OUT" > "$OUT/fx.log" 2>&1 || { grep -E '^(FAIL|captain-fx)' "$OUT/fx.log"; exit 1; }
grep -E '^(feet after|captain-fx)' "$OUT/fx.log"
for d in "$OUT"/feet/*; do
  n=$(basename "$d")
  img2webp -loop 0 -lossy -q 85 -d 95 $(ls "$d"/f??.png) -o "$OUT/anim/feet_${n}.webp" >/dev/null
done
perl -e 'alarm 900; exec @ARGV' "$GODOT" --headless --path . --script tools/captain_fx_sheet.gd -- --out="$OUT" > "$OUT/fx_sheet.log" 2>&1 || { tail -3 "$OUT/fx_sheet.log"; exit 1; }
for d in "$OUT"/fx/*; do
  n=$(basename "$d")
  img2webp -loop 0 -lossy -q 85 -d 17 $(ls "$d"/f???.png) -o "$OUT/anim/fx_${n}.webp" >/dev/null
done
for f in back profile; do
  img2webp -loop 0 -lossy -q 85 -d 17 $(ls "$OUT/fx_side/$f"/f???.png) -o "$OUT/anim/fx_options_${f}.webp" >/dev/null
  img2webp -loop 0 -lossy -q 85 -d 95 $(ls "$OUT/feet_side/$f"/f??.png) -o "$OUT/anim/feet_before_after_${f}.webp" >/dev/null
done
# The frame checks and the review description.
perl -e 'alarm 600; exec @ARGV' "$GODOT" --headless --path . --script tools/captain_frames.gd -- --json "$OUT/frames_check.json" > "$OUT/frames_check.log" 2>&1 || true
for n in art/captain-anim-v1/NOTES.md art/captain-anim-v2/NOTES.md art/captain-anim-v3/NOTES.md; do [ -f "$n" ] && cp "$n" "$OUT/generation_notes_$(basename $(dirname $n)).md"; done
[ -f "$OUT/overlay.json" ] || echo null > "$OUT/overlay.json"
jq -n --arg clip "$CLIP" --arg prev "$PREV_CLIP" --arg speed "$SPEED" --slurpfile cap "$OUT/review_capture.json" --slurpfile chk "$OUT/frames_check.json" --slurpfile ov "$OUT/overlay.json" '
  ($chk[0].frames | map({key: .src, value: {pose_iou: .iou, leg_coverage: .legs, height_ratio: .height_ratio, palette_dE: .de, passed: .ok, notes: .notes}}) | from_entries) as $c |
  {about: "R2-CAPTAIN-ANIMATION CA1 pilot review (ledger D-102): 10 painted frames (jog half cycle and idle, back and profile, age 0) and the CA0 facing fix, seen through the real Bow view at 1280x720 (the captain ~81 px). anim/<clip>_<facing>.webp loops at game speed, _3x is the same 3x, _painted_2x is the art itself; side_by_side.webp shows the four clips at real size; moonwalk_*.webp is a 2 s walk to starboard before and after.",
   figure_px_720p: $cap[0].figure_px_720p,
   checks_passed: ($chk[0].failures | length == 0),
   budgets: {disk_bytes: $chk[0].disk_bytes, gpu_bytes_with_mips: $chk[0].gpu_bytes_with_mips},
   clips: [$cap[0].clips[] | {name: "\(.clip)_\(.facing)", clip, facing, frame_count: .frames, kind, ms_per_frame_at_game_speed, m_per_frame, fps,
     loops: {game_speed: "anim/\(.clip)_\(.facing).webp", x3: "anim/\(.clip)_\(.facing)_3x.webp", painted_2x: "anim/\(.clip)_\(.facing)_painted_2x.webp"},
     frames_dir: .dir, frames: .files, blank_frames, frozen,
     frame_checks: ([.files[].file | split("/")[-1] | sub("\\.webp$"; "")] | unique | map({key: ., value: $c[.]}) | from_entries)}],
   side_by_side: ($cap[0].side_by_side + {loop: "anim/side_by_side.webp"}),
   moonwalk: [$cap[0].moonwalk[] | . + {loop: "anim/moonwalk_\(.mode).webp"}],
   contact_sheet: "contact_sheet.png", cells_dir: "cells/",
   moving_clip: {name: $clip, walk_speed_mps: ($speed | tonumber), ab_loops: {back: "anim/\($clip)_back_ab_\($prev)_\($clip).webp", profile: "anim/\($clip)_profile_ab_\($prev)_\($clip).webp"}, contact_loops: {back: "anim/\($clip)_back_contacts_2x.webp", profile: "anim/\($clip)_profile_contacts_2x.webp"}, overlay: ($ov[0] // null), planted_feet: $chk[0].stance}}' > "$OUT/review.json"
if [ -f "$OUT/feet.json" ] && [ -f "$OUT/fx.json" ]; then
  jq --slurpfile feet "$OUT/feet.json" --slurpfile fx "$OUT/fx.json" '. + {feet_on_floor: {about: $feet[0].about, before_after_loops: {back: "anim/feet_before_after_back.webp", profile: "anim/feet_before_after_profile.webp"}, rows: $feet[0].rows}, between_frame_effects: {about: "D-118 options on the billboard shader (no new paintings); fx_options_<facing>.webp left to right: none, echo, trail, blur; recommended and the demo default: echo", options: $fx[0].options, loops: {back: "anim/fx_options_back.webp", profile: "anim/fx_options_profile.webp"}, per_option: "anim/fx_<effect>_<facing>.webp and _3x.webp", note: $fx[0].about}}' "$OUT/review.json" > "$OUT/review.json.tmp" && mv "$OUT/review.json.tmp" "$OUT/review.json"
fi
echo "captain-review: review.json written ($(jq -r '.checks_passed' "$OUT/review.json"))"
