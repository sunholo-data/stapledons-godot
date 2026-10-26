# Captain walk repaint notes

Generated with the built-in image generation tool, with transparent_background=true for every call. Two candidates per requested frame; exactly two selected final PNGs under out/. No resizing, compositing, background removal, or other image postprocessing was applied.

## Deliverables and choices

- `out/walk_profile_04.png`: candidate 2 selected. Its planted right boot is visibly closer horizontally to the guide than candidate 1, and its head is closer to the guide's height. The boot remains too far screen-right and the stance does not follow the guide precisely.
- `out/walk_back_06.png`: candidate 2 selected. Its planted left boot reaches slightly lower than candidate 1, closer to the guide's bottom contact; its lifted boot also changes toward a rear-facing sole. Exact guide registration is still missed.

Both selected outputs are native 1024 × 1536, 8-bit RGBA PNGs, copied unchanged from built-in generation output.

## Validation and limitations

These are the closest available candidates within the allowed two candidates each, but **they do not satisfy all production requirements**. Both retain visible surrounding glow/halo and miss the guide's exact figure scale/head height and boot coordinates. The feet therefore cannot be claimed to fix sliding in-game.

The back guide's planted red boot extends to the bottom canvas edge, conflicting with the required 40 px inset. The second back prompt explicitly requested keeping its horizontal position and placing the sole at y=1495 to respect the inset; the generated result still did not follow that geometry exactly.

Read-only PNG inspection confirms real alpha, but also pixels outside the required safe inset. Nonzero-alpha bounds (inclusive, x0/y0/x1/y1):
- Profile: [0, 30, 1003, 1435]; 1,204,835 fully transparent pixels of 1,572,864.
- Back: [25, 57, 951, 1519]; 1,150,239 fully transparent pixels of 1,572,864.
- Both alpha ranges: 0–254.

No further candidates were generated after reaching the two-per-frame limit.

## Candidate records

| Frame | Candidate | Built-in output basename | Choice |
| --- | --- | --- | --- |
| profile 04 | 1 | exec-c4a9a66f-3ec6-4826-a0a8-cdfd9004454c.png | Rejected: planted boot farther screen-right |
| profile 04 | 2 | exec-30a74393-86ff-4b28-b79e-c4455f26aad0.png | Selected: closer horizontal boot position |
| back 06 | 1 | exec-8c490217-94ac-40d7-bff6-43ead5f9e1ff.png | Rejected: planted sole slightly higher |
| back 06 | 2 | exec-08b7d952-fcc1-43b4-b485-ab2182bb2339.png | Selected: planted sole slightly closer to guide |

Only selected outputs were copied into this directory.

## Prompts

Each candidate used the following shared cycle prompt verbatim, followed by the corresponding input labels and, for candidate 2, its correction below.

### Shared cycle prompt

Use case: identity-preserve, pose transfer, animation frame. ONE production full-body captain WALK-cycle frame for Stapledon's Voyage, the in-between of the two attached neighbouring frames, which define the character's exact rendering. The colour-keyed POSE GUIDE (red = left leg, blue = right leg, orange = left arm, cyan = right arm) gives the pose and, above all, **where each boot is**: the boot that touches the guide's ground line must be painted planted on the ground at exactly that position and height on the canvas, and the figure the same size and at the same head height as the guide. A calm, unhurried, upright walk; the cream calf-length open coat hangs and sways gently. Same identity, costume, palette (cream #F2E3C7, ochre #D9A340, violet #3B2959, ink #423555) and 1970s European graphic-novel ink-and-gouache style as the neighbours. Orthographic, looking down 29 degrees. Canvas 1024 x 1536 RGBA, transparent background, alpha zero outside the figure, the whole figure at least 40 px inside every edge. No floor, shadow, scenery, text, halo or watermark.

### Profile candidate 1: appended input labels

Input images in order:
1. Identity reference: refs/avatar_captain_proposal_a.png.
2. Previous painted frame: refs/neighbour_walk_profile_03.png; exact rendering reference.
3. Next painted frame: refs/neighbour_walk_profile_05.png; exact rendering reference.
4. Pose and exact boot placement guide: guides/walk_profile_04.png.
Frame to paint: walk_profile_04; side view, walking to screen-RIGHT.

Attached paths, in that order:
- refs/avatar_captain_proposal_a.png
- refs/neighbour_walk_profile_03.png
- refs/neighbour_walk_profile_05.png
- guides/walk_profile_04.png

### Profile candidate 2: additional correction

Same full candidate 1 prompt and same four attachments, followed by:

Candidate 2 correction: Treat attachment 4 as the canvas template to repaint, keeping its geometry. CRITICAL pixel coordinates on the 1024 x 1536 canvas: top of hair at y=203, head centred around x=490; planted RIGHT boot (blue in guide) occupies approximately x=448..630, y=1308..1445, its sole touching y=1445. LEFT boot (red) is behind it around x=330..490, y=1270..1413. Both knees bend forward to screen-right, with the right knee around x=665,y=1120, and the right ankle back under the body at x=510,y=1350. The stance is narrow with boots near each other under the body; follow the guide precisely. Use the previous/next images only for brushwork, ink, face and clothing design. No atmosphere or glow: every pixel outside the silhouette must have alpha=0. Do not enlarge the figure to the neighbours' head height.

### Back candidate 1: appended input labels and instruction

Input images in order:
1. Identity reference: refs/avatar_captain_proposal_a.png.
2. Previous painted frame: refs/neighbour_walk_back_05.png; exact character rendering reference.
3. Next painted frame: refs/neighbour_walk_back_07.png; exact character rendering reference.
4. Pose and exact boot placement guide: guides/walk_back_06.png.
Frame to paint: walk_back_06; seen strictly from behind, walking away.
The fourth image controls all on-canvas geometry and head height; the second and third control ink, gouache, fabric and character details only. Paint the cream coat and detailed captain directly over the fourth image's pose, replacing its flat colours with the neighbours' rendering. Do not copy the neighbours' figure positioning or their surrounding glow. True clear alpha outside the figure.

Attached paths, in that order:
- refs/avatar_captain_proposal_a.png
- refs/neighbour_walk_back_05.png
- refs/neighbour_walk_back_07.png
- guides/walk_back_06.png

### Back candidate 2: additional correction

Same full candidate 1 prompt and same four attachments, followed by:

Candidate 2 correction: attachment 4 is the geometry to repaint. Top of head at y=226, centred x=512. Red LEFT leg on screen-left is planted, boot centred x=438 near the bottom; blue RIGHT leg on screen-right is lifted, boot centred x=585 with its bottom around y=1330. Keep that raised right boot height exactly. Keep the planted left boot as close as possible to its guide location while maintaining the required 40px clear bottom margin: sole at y=1495. The guide's planted red boot actually extends to the canvas bottom; preserve its x-position and prioritise the required 40px safe inset for the final. Do not use neighbours' head height around y=80. No glow from the reference backgrounds; all surrounding pixels alpha zero. Only repaint the guide's flat figure in the neighbours' precise costume, ink and gouache rendering.

