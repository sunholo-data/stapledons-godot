# Captain calm WALK paint pass

Date: 2026-10-21. Source brief: HANDOFF.md, R2-CAPTAIN-ANIMATION / D-115.

## Deliverables and method

Exactly 24 PNG files in out/: walk_profile_00.png through walk_profile_11.png, then walk_back_00.png through walk_back_11.png. Painted in that order using the built-in image generation tool, one frame per call, with transparent_background=true. There were 25 generated candidates total: two for profile_00 and one for every other frame. Only the selected 24 files were copied into out/.

Each call attached the picked identity, accepted v1 frame for its facing, current pose guide, and (except frame00 of each facing) previous retained frame of that cycle, in that order. The stage-0 references were inspected for context but not attached to the generation calls. All local inputs were viewed before use. Outputs were copied unchanged from the tool's generated PNGs: no resizing, compositing, repainting, alpha cleanup, external API, git, installs or other network use.

## Unresolved results

The 24 requested files exist, but this is a best-effort paint pass, not an approved production walk cycle. No frame fully satisfies every constraint.

All frames retain a visible warm halo in the built-in previews and local image inspection despite transparent_background=true and repeated no-halo instructions. The PNG alpha checks confirm substantial zero-alpha background, but also nonzero alpha far outside the main figure in most frames; exact alpha-zero isolation and a clean 40px margin were not achieved consistently. No saved image contains a pixel with alpha=255; the generated figure itself is slightly translucent. These alpha problems were left unaltered to preserve native tool output.

All frames drift from their guides in head position, figure scale and/or boot positions. The profile coat continues to sweep backward more than the calm-walk brief allows. Several foot angles look too raised; precise planted ground contact, a no-flight cycle, minimal bob and seamless loop closure are not certified. Back coats hang more quietly, but scale/head registration drifts across that cycle. The per-frame entries identify visible problems.

The back guides themselves conflict with the 40px whole-figure margin: several boots cross/touch the bottom edge and others approach it more closely than 40px. Those prompts explicitly prioritize showing the whole boot with 40px clearance. This is a documented pose-coordinate deviation; it does not account for the larger generated registration errors.

Candidate 2 was tried for profile_00 to address halo, coat and placement. It improved the coat slightly but did not solve the halo or registration. The remaining frames use one candidate each; the same correction instructions were carried through their prompts. All retained frames are kept as the requested 24-image set with the failures disclosed here.

## File validation

Verified exact 24-name inventory and native 1024 × 1536, 8-bit RGBA, non-interlaced PNG for every saved frame. Read-only PNG decoding with Python standard-library struct/zlib checked the alpha channel; no image pixels were edited. The alpha bounding box includes every pixel with alpha greater than zero, even faint residue. Coordinates are inclusive. This is not a measurement of the solid character silhouette.

| Frame | Alpha-zero pixels | Nonzero alpha bounding box | Minimum canvas clearance, including residue |
| --- | ---: | --- | ---: |
| walk_profile_00.png | 1214325 | 25, 20, 1003, 1471 | 20px |
| walk_profile_01.png | 1185009 | 27, 23, 993, 1509 | 23px |
| walk_profile_02.png | 1187117 | 0, 53, 999, 1446 | 0px |
| walk_profile_03.png | 1233935 | 0, 31, 1009, 1471 | 0px |
| walk_profile_04.png | 1203638 | 55, 23, 1001, 1495 | 22px |
| walk_profile_05.png | 1189214 | 0, 55, 1001, 1447 | 0px |
| walk_profile_06.png | 1171606 | 23, 25, 1003, 1511 | 20px |
| walk_profile_07.png | 1162857 | 37, 53, 1022, 1470 | 1px |
| walk_profile_08.png | 1166736 | 0, 37, 993, 1496 | 0px |
| walk_profile_09.png | 1175592 | 0, 17, 1001, 1535 | 0px |
| walk_profile_10.png | 1171311 | 0, 31, 1009, 1503 | 0px |
| walk_profile_11.png | 1165297 | 87, 29, 989, 1502 | 29px |
| walk_back_00.png | 1220830 | 55, 35, 1013, 1515 | 10px |
| walk_back_01.png | 1195429 | 41, 128, 969, 1511 | 24px |
| walk_back_02.png | 1154517 | 0, 0, 1001, 1519 | 0px |
| walk_back_03.png | 1136092 | 33, 54, 1001, 1457 | 22px |
| walk_back_04.png | 1135483 | 0, 29, 1011, 1469 | 0px |
| walk_back_05.png | 1147669 | 43, 78, 1009, 1474 | 14px |
| walk_back_06.png | 1148595 | 57, 55, 983, 1486 | 40px |
| walk_back_07.png | 1142775 | 79, 61, 985, 1495 | 38px |
| walk_back_08.png | 1146389 | 25, 19, 1005, 1525 | 10px |
| walk_back_09.png | 1147948 | 0, 29, 1005, 1501 | 0px |
| walk_back_10.png | 1159791 | 0, 21, 991, 1495 | 0px |
| walk_back_11.png | 1168220 | 0, 47, 1009, 1519 | 0px |

All frame outputs have zero fully opaque pixels. The sampled upper-left corner has alpha 0 except walk_back_02.png (alpha 1). The sample at (200,700), outside the figure, has alpha 0 for all frames; that single sample does not establish clean transparency everywhere.

## Per-frame prompts, inputs and selections

Prompts below are the exact strings supplied to the built-in tool. Input lists are ordered. Native source paths are recorded for provenance only; the usable project copies are in out/.

### walk_profile_00

Output: out/walk_profile_00.png

Inputs:

1. refs/avatar_captain_proposal_a.png
2. refs/accepted_v1_profile.png
3. guides/walk_profile_00.png

Candidates: 2. Candidate 1 rejected; candidate 2 retained.

Candidate 1 source: /Users/voightkampff/.codex/generated_images/01a15fc2-48ff-7c40-9cdc-90f46d669ece/exec-eadf49a6-1282-41d7-ab49-5b31847a2c51.png

Candidate 1 assessment: Rejected: broad warm halo, guide framing drift, and trailing coat flare.

Candidate 1 prompt:

```text
Use case: identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain WALK-cycle frame (00 of 12) for Stapledon's Voyage. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, leg and arm positions, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. A calm, unhurried, upright WALK — not a run, not a jog: at least one foot on the ground, heel striking first, the other foot rolling off its toe, arms hanging and swinging only slightly, elbows soft, shoulders relaxed, head level. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels that HANGS and sways gently with the step (no flying or flaring coat), broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: full side view, walking to screen-RIGHT, the captain's right side toward the viewer. Calm non-specific face. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, each boot exactly where the guide's boot is. The whole figure, coat included, at least 40 px inside every edge. No floor, shadow, scenery, text, halo or watermark.
Pose for frame 00: left (red, far) leg reaches forward to screen-right in heel strike, right (blue, near) leg trails left with heel lifted and toe pushing off; right/cyan arm hangs slightly backward, far left/orange arm swings gently forward. Copy guide coordinates exactly. Use image 2 for fine painted rendering, NEVER its surrounding glow; background must be fully transparent.
```

Candidate 2 prompt:

```text
Use case: identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain WALK-cycle frame (00 of 12) for Stapledon's Voyage. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, leg and arm positions, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. A calm, unhurried, upright WALK — not a run, not a jog: at least one foot on the ground, heel striking first, the other foot rolling off its toe, arms hanging and swinging only slightly, elbows soft, shoulders relaxed, head level. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels that HANGS and sways gently with the step (no flying or flaring coat), broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: full side view, walking to screen-RIGHT, the captain's right side toward the viewer. Calm non-specific face. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, each boot exactly where the guide's boot is. The whole figure, coat included, at least 40 px inside every edge. No floor, shadow, scenery, text, halo or watermark.
Pose for frame 00: left (red, far) leg reaches forward to screen-right in heel strike, right (blue, near) leg trails left with heel lifted and toe pushing off; right/cyan arm hangs slightly backward, far left/orange arm swings gently forward. Copy guide coordinates exactly. Use image 2 for fine painted rendering, NEVER its surrounding glow; background must be fully transparent.
CRITICAL CORRECTION: image 2 contains an unwanted brown/ochre glow surrounding the figure. REMOVE ALL of that glow and ALL background pixels. This is an isolated cutout sprite, only character pixels and antialiased edges, alpha=0 everywhere else including between legs. Also use image 3's head top y=214 and boot coordinates, NOT image 2's larger head framing. Coat should hang vertically close behind the calves, with zero wind or trailing flare. Exact guide boot silhouettes; back foot toe points right while its heel lifts. Do not reproduce the standing frame silhouette.
```

Kept source: /Users/voightkampff/.codex/generated_images/01a15fc2-48ff-7c40-9cdc-90f46d669ece/exec-202c0f3e-179b-4528-b16a-7b34cde88483.png

Selection and limitations: Candidate 2 kept: coat hangs closer to calves than candidate 1, rendering consistent with approved profile. Unresolved: inherited halo remains; head and boot coordinates differ from guide.

### walk_profile_01

Output: out/walk_profile_01.png

Inputs:

1. refs/avatar_captain_proposal_a.png
2. refs/accepted_v1_profile.png
3. guides/walk_profile_01.png
4. out/walk_profile_00.png

Candidates: 1; candidate 1 retained. No alternate was generated for this frame.

Prompt:

```text
Use case: identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain WALK-cycle frame (01 of 12) for Stapledon's Voyage. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, leg and arm positions, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. A calm, unhurried, upright WALK — not a run, not a jog: at least one foot on the ground, heel striking first, the other foot rolling off its toe, arms hanging and swinging only slightly, elbows soft, shoulders relaxed, head level. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels that HANGS and sways gently with the step (no flying or flaring coat), broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: full side view, walking to screen-RIGHT, the captain's right side toward the viewer. Calm non-specific face. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, each boot exactly where the guide's boot is. The whole figure, coat included, at least 40 px inside every edge. No floor, shadow, scenery, text, halo or watermark.
CRITICAL: Reference image 2 has an unwanted surrounding brown halo: do not copy ANY halo or background. Generate ONLY the painted character on genuine transparent alpha, including between the legs. Image 3 is authoritative for figure size, head position and all limb coordinates; the standing image 2 is ONLY a rendering/identity reference. Image 4, if present, is previous-cycle rendering continuity ONLY; do not copy its pose or its unwanted halo. Keep coat narrow, hanging close to calves without wind. Native 1024x1536 output.
Pose frame 01: left/far red leg forward and planted flat at screen-right; right/near blue leg extended behind to screen-left, toe still contacting ground as heel rises; arms in the modest opposing positions shown. Head top y214, coat hangs vertically down the central guide silhouette. Do not exaggerate stride or lean.
```

Kept source: /Users/voightkampff/.codex/generated_images/01a15fc2-48ff-7c40-9cdc-90f46d669ece/exec-ef107d4d-8e8b-473e-b7e2-d55d9a5400b6.png

Selection and limitations: Candidate 1 kept: same profile identity and paint, upright shoulders and opposed limbs. Unresolved: broad halo, coat sweep, and guide coordinate drift persist.

### walk_profile_02

Output: out/walk_profile_02.png

Inputs:

1. refs/avatar_captain_proposal_a.png
2. refs/accepted_v1_profile.png
3. guides/walk_profile_02.png
4. out/walk_profile_01.png

Candidates: 1; candidate 1 retained. No alternate was generated for this frame.

Prompt:

```text
Use case: identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain WALK-cycle frame (02 of 12) for Stapledon's Voyage. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, leg and arm positions, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. A calm, unhurried, upright WALK — not a run, not a jog: at least one foot on the ground, heel striking first, the other foot rolling off its toe, arms hanging and swinging only slightly, elbows soft, shoulders relaxed, head level. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels that HANGS and sways gently with the step (no flying or flaring coat), broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: full side view, walking to screen-RIGHT, the captain's right side toward the viewer. Calm non-specific face. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, each boot exactly where the guide's boot is. The whole figure, coat included, at least 40 px inside every edge. No floor, shadow, scenery, text, halo or watermark.
CRITICAL: Reference image 2 has an unwanted surrounding brown halo: do not copy ANY halo or background. Generate ONLY the painted character on genuine transparent alpha, including between the legs. Image 3 is authoritative for figure size, head position and all limb coordinates; the standing image 2 is ONLY a rendering/identity reference. Image 4, if present, is previous-cycle rendering continuity ONLY; do not copy its pose or its unwanted halo. Keep coat narrow, hanging close to calves without wind. Native 1024x1536 output.
Pose frame 02: left/red support boot now near x600,y1370, left knee softly bent, body progressing over planted left foot. Right/blue trailing boot near x175,y1380 starts toe-off behind; right arm shifts toward neutral hanging beside hip, left arm slightly forward. Head top y210. Paint the current guide pose, different from previous frame.
```

Kept source: /Users/voightkampff/.codex/generated_images/01a15fc2-48ff-7c40-9cdc-90f46d669ece/exec-a85bd407-9a2d-4b3d-b0ff-07b83617477c.png

Selection and limitations: Candidate 1 kept: support knee softens and forward boot moves inward, preserving approved profile rendering. Unresolved halo, excessive trailing skirt, and inexact guide/head/boot coordinates.

### walk_profile_03

Output: out/walk_profile_03.png

Inputs:

1. refs/avatar_captain_proposal_a.png
2. refs/accepted_v1_profile.png
3. guides/walk_profile_03.png
4. out/walk_profile_02.png

Candidates: 1; candidate 1 retained. No alternate was generated for this frame.

Prompt:

```text
Use case: identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain WALK-cycle frame (03 of 12) for Stapledon's Voyage. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, leg and arm positions, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. A calm, unhurried, upright WALK — not a run, not a jog: at least one foot on the ground, heel striking first, the other foot rolling off its toe, arms hanging and swinging only slightly, elbows soft, shoulders relaxed, head level. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels that HANGS and sways gently with the step (no flying or flaring coat), broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: full side view, walking to screen-RIGHT, the captain's right side toward the viewer. Calm non-specific face. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, each boot exactly where the guide's boot is. The whole figure, coat included, at least 40 px inside every edge. No floor, shadow, scenery, text, halo or watermark.
CRITICAL: Reference image 2 has an unwanted surrounding brown halo: do not copy ANY halo or background. Generate ONLY the painted character on genuine transparent alpha, including between the legs. Image 3 is authoritative for figure size, head position and all limb coordinates; the standing image 2 is ONLY a rendering/identity reference. Image 4, if present, is previous-cycle rendering continuity ONLY; do not copy its pose or its unwanted halo. Keep coat narrow, hanging close to calves without wind. Native 1024x1536 output.
Pose frame 03, passing: LEFT/red support foot under body around x510,y1360; RIGHT/blue foot passes from behind, around x340,y1400 with knee softly flexed. Both boots close to one another, NOT wide stride. Right/cyan hand swings slightly forward near x600,y980; left/orange arm almost hidden. Use guide head top y203. Narrow vertical hanging coat.
```

Kept source: /Users/voightkampff/.codex/generated_images/01a15fc2-48ff-7c40-9cdc-90f46d669ece/exec-5f021425-fa4c-42d0-bb2c-b691512a3a55.png

Selection and limitations: Candidate 1 kept: narrower passing stride and forward near hand distinguish this pose; face, costume, paint preserved. Unresolved halo, trailing skirt sweep, head too high and boots offset from guide.

### walk_profile_04

Output: out/walk_profile_04.png

Inputs:

1. refs/avatar_captain_proposal_a.png
2. refs/accepted_v1_profile.png
3. guides/walk_profile_04.png
4. out/walk_profile_03.png

Candidates: 1; candidate 1 retained. No alternate was generated for this frame.

Prompt:

```text
Use case: identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain WALK-cycle frame (04 of 12) for Stapledon's Voyage. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, leg and arm positions, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. A calm, unhurried, upright WALK — not a run, not a jog: at least one foot on the ground, heel striking first, the other foot rolling off its toe, arms hanging and swinging only slightly, elbows soft, shoulders relaxed, head level. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels that HANGS and sways gently with the step (no flying or flaring coat), broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: full side view, walking to screen-RIGHT, the captain's right side toward the viewer. Calm non-specific face. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, each boot exactly where the guide's boot is. The whole figure, coat included, at least 40 px inside every edge. No floor, shadow, scenery, text, halo or watermark.
CRITICAL: Reference image 2 has an unwanted surrounding brown halo: do not copy ANY halo or background. Generate ONLY the painted character on genuine transparent alpha, including between the legs. Image 3 is authoritative for figure size, head position and all limb coordinates; the standing image 2 is ONLY a rendering/identity reference. Image 4, if present, is previous-cycle rendering continuity ONLY; do not copy its pose or its unwanted halo. Keep coat narrow, hanging close to calves without wind. Native 1024x1536 output.
Pose frame 04: left/red support leg trails slightly, its boot at x420,y1360; right/blue swing knee ahead at x650,y1100 and foot low near x540,y1390, just passing the planted foot. Right/cyan arm swings gently forward to x660,y960. No high knee or running kick. Head top y203. Coat vertical.
```

Kept source: /Users/voightkampff/.codex/generated_images/01a15fc2-48ff-7c40-9cdc-90f46d669ece/exec-c609dae6-1f3d-4a65-9877-e6b6a5630374.png

Selection and limitations: Candidate 1 kept: near arm and leg begin forward swing, upright body and matched rendering. Unresolved halo, guide stride too wide and skirt trailing left; exact guide placement not achieved.

### walk_profile_05

Output: out/walk_profile_05.png

Inputs:

1. refs/avatar_captain_proposal_a.png
2. refs/accepted_v1_profile.png
3. guides/walk_profile_05.png
4. out/walk_profile_04.png

Candidates: 1; candidate 1 retained. No alternate was generated for this frame.

Prompt:

```text
Use case: identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain WALK-cycle frame (05 of 12) for Stapledon's Voyage. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, leg and arm positions, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. A calm, unhurried, upright WALK — not a run, not a jog: at least one foot on the ground, heel striking first, the other foot rolling off its toe, arms hanging and swinging only slightly, elbows soft, shoulders relaxed, head level. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels that HANGS and sways gently with the step (no flying or flaring coat), broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: full side view, walking to screen-RIGHT, the captain's right side toward the viewer. Calm non-specific face. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, each boot exactly where the guide's boot is. The whole figure, coat included, at least 40 px inside every edge. No floor, shadow, scenery, text, halo or watermark.
CRITICAL: Reference image 2 has an unwanted surrounding brown halo: do not copy ANY halo or background. Generate ONLY the painted character on genuine transparent alpha, including between the legs. Image 3 is authoritative for figure size, head position and all limb coordinates; the standing image 2 is ONLY a rendering/identity reference. Image 4, if present, is previous-cycle rendering continuity ONLY; do not copy its pose or its unwanted halo. Keep coat narrow, hanging close to calves without wind. Native 1024x1536 output.
Pose frame 05: RIGHT/blue near leg reaches forward toward screen-right, boot centered x710,y1400 with heel low for coming heel strike; LEFT/red far support leg extends behind, boot x320,y1350. Near right/cyan hand slightly forward at x700,y940; far left arm back. Head top y210. Coat hangs as narrow central silhouette, no flaring train.
```

Kept source: /Users/voightkampff/.codex/generated_images/01a15fc2-48ff-7c40-9cdc-90f46d669ece/exec-ded065e6-55b3-42ac-8d3e-d45ffda31ada.png

Selection and limitations: Candidate 1 kept: forward right-side arm and reaching near boot continue the step while preserving identity. Unresolved: halo, coat flare and guide coordinate drift; boot angle is over-raised.

### walk_profile_06

Output: out/walk_profile_06.png

Inputs:

1. refs/avatar_captain_proposal_a.png
2. refs/accepted_v1_profile.png
3. guides/walk_profile_06.png
4. out/walk_profile_05.png

Candidates: 1; candidate 1 retained. No alternate was generated for this frame.

Prompt:

```text
Use case: identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain WALK-cycle frame (06 of 12) for Stapledon's Voyage. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, leg and arm positions, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. A calm, unhurried, upright WALK — not a run, not a jog: at least one foot on the ground, heel striking first, the other foot rolling off its toe, arms hanging and swinging only slightly, elbows soft, shoulders relaxed, head level. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels that HANGS and sways gently with the step (no flying or flaring coat), broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: full side view, walking to screen-RIGHT, the captain's right side toward the viewer. Calm non-specific face. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, each boot exactly where the guide's boot is. The whole figure, coat included, at least 40 px inside every edge. No floor, shadow, scenery, text, halo or watermark.
CRITICAL: Reference image 2 has an unwanted surrounding brown halo: do not copy ANY halo or background. Generate ONLY the painted character on genuine transparent alpha, including between the legs. Image 3 is authoritative for figure size, head position and all limb coordinates; the standing image 2 is ONLY a rendering/identity reference. Image 4, if present, is previous-cycle rendering continuity ONLY; do not copy its pose or its unwanted halo. Keep coat narrow, hanging close to calves without wind. Native 1024x1536 output.
Pose frame 06: RIGHT/blue near boot heel strikes ahead at x785,y1430; LEFT/red far boot rolls off toe behind at x220,y1320. Right arm swung modestly forward at x720,y950, left arm behind. This is opposite-leg contact to frame00; keep at least one foot firmly grounded. Head top y215 and nearly level. All coat fabric close to central calves.
```

Kept source: /Users/voightkampff/.codex/generated_images/01a15fc2-48ff-7c40-9cdc-90f46d669ece/exec-7efc67a8-5bd5-441e-92a8-454cd97b6e75.png

Selection and limitations: Candidate 1 kept: opposite contact with forward near boot, relaxed shoulders and matched style. Unresolved halo, swept coat, guide placement and ambiguous heel contact.

### walk_profile_07

Output: out/walk_profile_07.png

Inputs:

1. refs/avatar_captain_proposal_a.png
2. refs/accepted_v1_profile.png
3. guides/walk_profile_07.png
4. out/walk_profile_06.png

Candidates: 1; candidate 1 retained. No alternate was generated for this frame.

Prompt:

```text
Use case: identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain WALK-cycle frame (07 of 12) for Stapledon's Voyage. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, leg and arm positions, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. A calm, unhurried, upright WALK — not a run, not a jog: at least one foot on the ground, heel striking first, the other foot rolling off its toe, arms hanging and swinging only slightly, elbows soft, shoulders relaxed, head level. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels that HANGS and sways gently with the step (no flying or flaring coat), broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: full side view, walking to screen-RIGHT, the captain's right side toward the viewer. Calm non-specific face. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, each boot exactly where the guide's boot is. The whole figure, coat included, at least 40 px inside every edge. No floor, shadow, scenery, text, halo or watermark.
CRITICAL: Reference image 2 has an unwanted surrounding brown halo: do not copy ANY halo or background. Generate ONLY the painted character on genuine transparent alpha, including between the legs. Image 3 is authoritative for figure size, head position and all limb coordinates; the standing image 2 is ONLY a rendering/identity reference. Image 4, if present, is previous-cycle rendering continuity ONLY; do not copy its pose or its unwanted halo. Keep coat narrow, hanging close to calves without wind. Native 1024x1536 output.
Pose frame 07: RIGHT/blue near foot flat/planted forward near x695,y1440, knee softly bent. LEFT/red leg trailing diagonally back to low toe-off boot at x95,y1290. Near right/cyan arm slightly forward, left arm backward. Head top y215. Keep torso vertical. One boot definitely planted, no floating pose.
```

Kept source: /Users/voightkampff/.codex/generated_images/01a15fc2-48ff-7c40-9cdc-90f46d669ece/exec-b40f37d2-ef99-459f-94f1-a3bea8abbac5.png

Selection and limitations: Candidate 1 kept: flat forward boot and lifted trailing heel advance the opposite step; approved rendering maintained. Unresolved halo, head/framing drift, backward coat flare and trailing boot too airborne.

### walk_profile_08

Output: out/walk_profile_08.png

Inputs:

1. refs/avatar_captain_proposal_a.png
2. refs/accepted_v1_profile.png
3. guides/walk_profile_08.png
4. out/walk_profile_07.png

Candidates: 1; candidate 1 retained. No alternate was generated for this frame.

Prompt:

```text
Use case: identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain WALK-cycle frame (08 of 12) for Stapledon's Voyage. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, leg and arm positions, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. A calm, unhurried, upright WALK — not a run, not a jog: at least one foot on the ground, heel striking first, the other foot rolling off its toe, arms hanging and swinging only slightly, elbows soft, shoulders relaxed, head level. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels that HANGS and sways gently with the step (no flying or flaring coat), broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: full side view, walking to screen-RIGHT, the captain's right side toward the viewer. Calm non-specific face. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, each boot exactly where the guide's boot is. The whole figure, coat included, at least 40 px inside every edge. No floor, shadow, scenery, text, halo or watermark.
CRITICAL: Reference image 2 has an unwanted surrounding brown halo: do not copy ANY halo or background. Generate ONLY the painted character on genuine transparent alpha, including between the legs. Image 3 is authoritative for figure size, head position and all limb coordinates; the standing image 2 is ONLY a rendering/identity reference. Image 4, if present, is previous-cycle rendering continuity ONLY; do not copy its pose or its unwanted halo. Keep coat narrow, hanging close to calves without wind. Native 1024x1536 output.
Pose frame 08: RIGHT/blue near support knee softens, its planted boot moves beneath body near x600,y1440. LEFT/red trailing boot near x175,y1300 approaches toe-off. Near right/cyan hand eases back toward hip at x660,y970. Head top y210. Absolutely retain guide ground contact and low foot clearance. Narrow vertical coat.
```

Kept source: /Users/voightkampff/.codex/generated_images/01a15fc2-48ff-7c40-9cdc-90f46d669ece/exec-36cb31bf-e031-40bb-903c-183f3f3440a5.png

Selection and limitations: Candidate 1 kept: support boot moves inward and knee softens; rendering remains consistent. Unresolved halo, swept skirt, trailing boot too high and inexact guide coordinates.

### walk_profile_09

Output: out/walk_profile_09.png

Inputs:

1. refs/avatar_captain_proposal_a.png
2. refs/accepted_v1_profile.png
3. guides/walk_profile_09.png
4. out/walk_profile_08.png

Candidates: 1; candidate 1 retained. No alternate was generated for this frame.

Prompt:

```text
Use case: identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain WALK-cycle frame (09 of 12) for Stapledon's Voyage. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, leg and arm positions, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. A calm, unhurried, upright WALK — not a run, not a jog: at least one foot on the ground, heel striking first, the other foot rolling off its toe, arms hanging and swinging only slightly, elbows soft, shoulders relaxed, head level. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels that HANGS and sways gently with the step (no flying or flaring coat), broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: full side view, walking to screen-RIGHT, the captain's right side toward the viewer. Calm non-specific face. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, each boot exactly where the guide's boot is. The whole figure, coat included, at least 40 px inside every edge. No floor, shadow, scenery, text, halo or watermark.
CRITICAL: Reference image 2 has an unwanted surrounding brown halo: do not copy ANY halo or background. Generate ONLY the painted character on genuine transparent alpha, including between the legs. Image 3 is authoritative for figure size, head position and all limb coordinates; the standing image 2 is ONLY a rendering/identity reference. Image 4, if present, is previous-cycle rendering continuity ONLY; do not copy its pose or its unwanted halo. Keep coat narrow, hanging close to calves without wind. Native 1024x1536 output.
Pose frame 09, opposite passing: RIGHT/blue support boot below body near x510,y1440; LEFT/red swing boot close behind near x340,y1320. Knees close together, no wide stride. Near/cyan hand returning to almost neutral at x600,y990; far/orange arm modestly forward. Head top y203. Boots follow guide exactly; central vertical hanging coat.
```

Kept source: /Users/voightkampff/.codex/generated_images/01a15fc2-48ff-7c40-9cdc-90f46d669ece/exec-0ac41576-6edf-4502-8b23-e84f8dca39fd.png

Selection and limitations: Candidate 1 kept: feet narrow toward passing and arm swing reverses; consistent profile identity and costume. Unresolved halo, trailing skirt and guide coordinates, particularly raised rear boot.

### walk_profile_10

Output: out/walk_profile_10.png

Inputs:

1. refs/avatar_captain_proposal_a.png
2. refs/accepted_v1_profile.png
3. guides/walk_profile_10.png
4. out/walk_profile_09.png

Candidates: 1; candidate 1 retained. No alternate was generated for this frame.

Prompt:

```text
Use case: identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain WALK-cycle frame (10 of 12) for Stapledon's Voyage. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, leg and arm positions, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. A calm, unhurried, upright WALK — not a run, not a jog: at least one foot on the ground, heel striking first, the other foot rolling off its toe, arms hanging and swinging only slightly, elbows soft, shoulders relaxed, head level. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels that HANGS and sways gently with the step (no flying or flaring coat), broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: full side view, walking to screen-RIGHT, the captain's right side toward the viewer. Calm non-specific face. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, each boot exactly where the guide's boot is. The whole figure, coat included, at least 40 px inside every edge. No floor, shadow, scenery, text, halo or watermark.
CRITICAL: Reference image 2 has an unwanted surrounding brown halo: do not copy ANY halo or background. Generate ONLY the painted character on genuine transparent alpha, including between the legs. Image 3 is authoritative for figure size, head position and all limb coordinates; the standing image 2 is ONLY a rendering/identity reference. Image 4, if present, is previous-cycle rendering continuity ONLY; do not copy its pose or its unwanted halo. Keep coat narrow, hanging close to calves without wind. Native 1024x1536 output.
Pose frame10: RIGHT/blue near support foot slightly back at x420,y1430, left/red far knee gently ahead, swing boot low near x540,y1320. Near cyan arm hangs mostly straight, left/orange far arm eases forward. A compact calm walk, no high knee. Head top y203. Follow image3 over image4 for new pose.
```

Kept source: /Users/voightkampff/.codex/generated_images/01a15fc2-48ff-7c40-9cdc-90f46d669ece/exec-fe6783db-f4cd-47d1-b60f-d0d4a62af14b.png

Selection and limitations: Candidate 1 kept: swing leg comes forward and arm opposition returns; rendering preserved. Unresolved halo, coat flare and guide mismatch; swing boot too extended ahead and tilted.

### walk_profile_11

Output: out/walk_profile_11.png

Inputs:

1. refs/avatar_captain_proposal_a.png
2. refs/accepted_v1_profile.png
3. guides/walk_profile_11.png
4. out/walk_profile_10.png

Candidates: 1; candidate 1 retained. No alternate was generated for this frame.

Prompt:

```text
Use case: identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain WALK-cycle frame (11 of 12) for Stapledon's Voyage. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, leg and arm positions, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. A calm, unhurried, upright WALK — not a run, not a jog: at least one foot on the ground, heel striking first, the other foot rolling off its toe, arms hanging and swinging only slightly, elbows soft, shoulders relaxed, head level. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels that HANGS and sways gently with the step (no flying or flaring coat), broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: full side view, walking to screen-RIGHT, the captain's right side toward the viewer. Calm non-specific face. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, each boot exactly where the guide's boot is. The whole figure, coat included, at least 40 px inside every edge. No floor, shadow, scenery, text, halo or watermark.
CRITICAL: Reference image 2 has an unwanted surrounding brown halo: do not copy ANY halo or background. Generate ONLY the painted character on genuine transparent alpha, including between the legs. Image 3 is authoritative for figure size, head position and all limb coordinates; the standing image 2 is ONLY a rendering/identity reference. Image 4, if present, is previous-cycle rendering continuity ONLY; do not copy its pose or its unwanted halo. Keep coat narrow, hanging close to calves without wind. Native 1024x1536 output.
Pose frame11: LEFT/red far leg extends ahead with low boot near x710,y1330, preparing heel strike at frame00. RIGHT/blue near support leg extends back, boot near x320,y1420. Near right/cyan arm subtly back and far left/orange arm forward. Head top y210. Match guide and close cycle with frame00. Planted right foot, no flight; vertical coat.
```

Kept source: /Users/voightkampff/.codex/generated_images/01a15fc2-48ff-7c40-9cdc-90f46d669ece/exec-10d44752-4446-42c4-b60e-b29f4a39fbf7.png

Selection and limitations: Candidate 1 kept: reaches toward next left heel strike with opposing arm swing; approved profile rendering remains recognizable. Unresolved halo, wind-swept coat, planted-foot and guide coordinate mismatch; loop not certified.

### walk_back_00

Output: out/walk_back_00.png

Inputs:

1. refs/avatar_captain_proposal_a.png
2. refs/accepted_v1_back.png
3. guides/walk_back_00.png

Candidates: 1; candidate 1 retained. No alternate was generated for this frame.

Prompt:

```text
Use case: identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain WALK-cycle frame (00 of 12) for Stapledon's Voyage. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, leg and arm positions, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. A calm, unhurried, upright WALK — not a run, not a jog: at least one foot on the ground, heel striking first, the other foot rolling off its toe, arms hanging and swinging only slightly, elbows soft, shoulders relaxed, head level. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels that HANGS and sways gently with the step (no flying or flaring coat), broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: directly from behind, walking AWAY up the screen; back of head only, no face, symmetrical rear camera. Calm non-specific face. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, each boot exactly where the guide's boot is. The whole figure, coat included, at least 40 px inside every edge. No floor, shadow, scenery, text, halo or watermark.
CRITICAL: Reference image 2 has an unwanted surrounding brown halo: do not copy ANY halo or background. Generate ONLY the painted character on genuine transparent alpha, including between the legs. Image 3 is authoritative for figure size, head position and all limb coordinates; the standing image 2 is ONLY a rendering/identity reference. Image 4, if present, is previous-cycle rendering continuity ONLY; do not copy its pose or its unwanted halo. Keep coat narrow, hanging close to calves without wind. Native 1024x1536 output.
Pose frame00: LEFT/red leg forward away from camera, its boot higher at screen-left near x440,y1300. RIGHT/blue leg trails toward viewer, boot lower at x585. Left/orange arm swings forward away and is foreshortened; right/cyan arm swings back and appears longer at screen-right. Head top y225. IMPORTANT guide trailing boot runs beyond canvas; preserve its pose while keeping WHOLE boot at least40px above bottom (lowest tip y1495 maximum). Rear split coat hangs near x340..685, hem near y1290, no billowing. Eliminate reference2 halo entirely.
```

Kept source: /Users/voightkampff/.codex/generated_images/01a15fc2-48ff-7c40-9cdc-90f46d669ece/exec-ad3cd192-ac85-496d-ad16-90c9d15ab68e.png

Selection and limitations: Candidate 1 kept: rear identity, hanging split coat and opposing arm/leg depth match the intended rear contact better than the profile attempts. Unresolved halo and shifted head/boots. Guide trailing boot clips below canvas; prompt prioritized whole boot with 40px clearance, deliberately deviating from that impossible coordinate.

### walk_back_01

Output: out/walk_back_01.png

Inputs:

1. refs/avatar_captain_proposal_a.png
2. refs/accepted_v1_back.png
3. guides/walk_back_01.png
4. out/walk_back_00.png

Candidates: 1; candidate 1 retained. No alternate was generated for this frame.

Prompt:

```text
Use case: identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain WALK-cycle frame (01 of 12) for Stapledon's Voyage. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, leg and arm positions, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. A calm, unhurried, upright WALK — not a run, not a jog: at least one foot on the ground, heel striking first, the other foot rolling off its toe, arms hanging and swinging only slightly, elbows soft, shoulders relaxed, head level. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels that HANGS and sways gently with the step (no flying or flaring coat), broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: directly from behind, walking AWAY up the screen, back of head only. Calm non-specific face. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, each boot exactly where the guide's boot is. The whole figure, coat included, at least 40 px inside every edge. No floor, shadow, scenery, text, halo or watermark.
CRITICAL: Reference image 2 has an unwanted surrounding brown halo: do not copy ANY halo or background. Generate ONLY the painted character on genuine transparent alpha, including between the legs. Image 3 is authoritative for figure size, head position and all limb coordinates; the standing image 2 is ONLY a rendering/identity reference. Image 4, if present, is previous-cycle rendering continuity ONLY; do not copy its pose or its unwanted halo. Keep coat narrow, hanging close to calves without wind. Native 1024x1536 output.
Pose frame01: LEFT/red foot higher forward at screen-left near x440,y1320, accepting weight and rolling flat; RIGHT/blue foot trails lower at x585, heel rising/toe push-off. Left/orange arm forward and foreshortened, right/cyan back and longer. Head top y226. Guide right boot crosses bottom edge: preserve whole boot at least40px inside (tip y1495 max), do not crop. Rear coat hangs gently with split; no wind.
```

Kept source: /Users/voightkampff/.codex/generated_images/01a15fc2-48ff-7c40-9cdc-90f46d669ece/exec-09032613-0d10-464b-8170-1867bb2e3413.png

Selection and limitations: Candidate 1 kept: controlled rear coat, rear costume and alternating depth preserved. Unresolved halo, head drift and exact boot/ground placement. Guide boot crosses bottom edge; whole-boot margin was prioritized.

### walk_back_02

Output: out/walk_back_02.png

Inputs:

1. refs/avatar_captain_proposal_a.png
2. refs/accepted_v1_back.png
3. guides/walk_back_02.png
4. out/walk_back_01.png

Candidates: 1; candidate 1 retained. No alternate was generated for this frame.

Prompt:

```text
Use case: identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain WALK-cycle frame (02 of 12) for Stapledon's Voyage. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, leg and arm positions, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. A calm, unhurried, upright WALK — not a run, not a jog: at least one foot on the ground, heel striking first, the other foot rolling off its toe, arms hanging and swinging only slightly, elbows soft, shoulders relaxed, head level. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels that HANGS and sways gently with the step (no flying or flaring coat), broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: directly from behind, walking AWAY up the screen, back of head only. Calm non-specific face. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, each boot exactly where the guide's boot is. The whole figure, coat included, at least 40 px inside every edge. No floor, shadow, scenery, text, halo or watermark.
CRITICAL: Reference image 2 has an unwanted surrounding brown halo: do not copy ANY halo or background. Generate ONLY the painted character on genuine transparent alpha, including between the legs. Image 3 is authoritative for figure size, head position and all limb coordinates; the standing image 2 is ONLY a rendering/identity reference. Image 4, if present, is previous-cycle rendering continuity ONLY; do not copy its pose or its unwanted halo. Keep coat narrow, hanging close to calves without wind. Native 1024x1536 output.
Pose frame02: left/red support knee softens and its screen-left boot is near x440,y1370; right/blue trailing leg begins toe-off with boot lower at x585. Left/orange arm starts returning toward neutral; right/cyan arm comes toward neutral and hand slightly higher. Head top y220. Guide lower boot touches/crosses canvas bottom: keep entire boot tip no lower than y1495, all else follow guide. No flight; calf-length rear panels hang.
```

Kept source: /Users/voightkampff/.codex/generated_images/01a15fc2-48ff-7c40-9cdc-90f46d669ece/exec-e3880f70-860a-401f-92f8-24977ef4de4f.png

Selection and limitations: Candidate 1 kept: weight transfer and right heel lift visible; coat hanging and approved rear paint maintained. Unresolved halo, arm phase differs from guide, head/boot registration drift. Canvas-edge guide boot contained by prompt.

### walk_back_03

Output: out/walk_back_03.png

Inputs:

1. refs/avatar_captain_proposal_a.png
2. refs/accepted_v1_back.png
3. guides/walk_back_03.png
4. out/walk_back_02.png

Candidates: 1; candidate 1 retained. No alternate was generated for this frame.

Prompt:

```text
Use case: identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain WALK-cycle frame (03 of 12) for Stapledon's Voyage. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, leg and arm positions, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. A calm, unhurried, upright WALK — not a run, not a jog: at least one foot on the ground, heel striking first, the other foot rolling off its toe, arms hanging and swinging only slightly, elbows soft, shoulders relaxed, head level. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels that HANGS and sways gently with the step (no flying or flaring coat), broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: directly from behind, walking AWAY up the screen, back of head only. Calm non-specific face. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, each boot exactly where the guide's boot is. The whole figure, coat included, at least 40 px inside every edge. No floor, shadow, scenery, text, halo or watermark.
CRITICAL: Reference image 2 has an unwanted surrounding brown halo: do not copy ANY halo or background. Generate ONLY the painted character on genuine transparent alpha, including between the legs. Image 3 is authoritative for figure size, head position and all limb coordinates; the standing image 2 is ONLY a rendering/identity reference. Image 4, if present, is previous-cycle rendering continuity ONLY; do not copy its pose or its unwanted halo. Keep coat narrow, hanging close to calves without wind. Native 1024x1536 output.
Pose frame03, passing: LEFT/red support foot near x440,y1410, RIGHT/blue swing foot close alongside near x585,y1450, knee softly flexed. Arms both near neutral, hands at similar height around y850; shoulders relaxed. Head top y214. No lifted running heel, feet stay low. Keep rear coat hem close to guide y1270; boots fully inside40px margin.
```

Kept source: /Users/voightkampff/.codex/generated_images/01a15fc2-48ff-7c40-9cdc-90f46d669ece/exec-c1208dde-d684-4a7b-a9c7-e5cc3fba424e.png

Selection and limitations: Candidate 1 kept: near-neutral arms and narrowed feet create rear passing stage, with hanging panels. Unresolved halo and head/boot registration drift; right sole too exposed versus guide.

### walk_back_04

Output: out/walk_back_04.png

Inputs:

1. refs/avatar_captain_proposal_a.png
2. refs/accepted_v1_back.png
3. guides/walk_back_04.png
4. out/walk_back_03.png

Candidates: 1; candidate 1 retained. No alternate was generated for this frame.

Prompt:

```text
Use case: identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain WALK-cycle frame (04 of 12) for Stapledon's Voyage. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, leg and arm positions, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. A calm, unhurried, upright WALK — not a run, not a jog: at least one foot on the ground, heel striking first, the other foot rolling off its toe, arms hanging and swinging only slightly, elbows soft, shoulders relaxed, head level. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels that HANGS and sways gently with the step (no flying or flaring coat), broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: directly from behind, walking AWAY up the screen, back of head only. Calm non-specific face. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, each boot exactly where the guide's boot is. The whole figure, coat included, at least 40 px inside every edge. No floor, shadow, scenery, text, halo or watermark.
CRITICAL: Reference image 2 has an unwanted surrounding brown halo: do not copy ANY halo or background. Generate ONLY the painted character on genuine transparent alpha, including between the legs. Image 3 is authoritative for figure size, head position and all limb coordinates; the standing image 2 is ONLY a rendering/identity reference. Image 4, if present, is previous-cycle rendering continuity ONLY; do not copy its pose or its unwanted halo. Keep coat narrow, hanging close to calves without wind. Native 1024x1536 output.
Pose frame04: LEFT/red support leg trails low at screen-left, boot x440,y1450; RIGHT/blue swing knee soft and its boot moves forward away at x585,y1350. Left/orange arm swinging back appears longer and lower, right/cyan arm forward appears shorter. Head top y214. Keep boot minimum40px bottom margin (guide has only~35px), keep exact native1024x1536. TRANSPARENT CUTOUT SPRITE: no black background, no vignette, no brown atmospheric haze.
```

Kept source: /Users/voightkampff/.codex/generated_images/01a15fc2-48ff-7c40-9cdc-90f46d669ece/exec-5b51f752-17f4-4d19-91a0-d01b0b7c4182.png

Selection and limitations: Candidate 1 kept: left support and right forward swing are readable, hands reverse depth and panels hang. Unresolved halo, head drift and sole angle/boot position differ from guide. Prompt adds 40px margin for guide boot~35px from edge.

### walk_back_05

Output: out/walk_back_05.png

Inputs:

1. refs/avatar_captain_proposal_a.png
2. refs/accepted_v1_back.png
3. guides/walk_back_05.png
4. out/walk_back_04.png

Candidates: 1; candidate 1 retained. No alternate was generated for this frame.

Prompt:

```text
Use case: identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain WALK-cycle frame (05 of 12) for Stapledon's Voyage. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, leg and arm positions, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. A calm, unhurried, upright WALK — not a run, not a jog: at least one foot on the ground, heel striking first, the other foot rolling off its toe, arms hanging and swinging only slightly, elbows soft, shoulders relaxed, head level. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels that HANGS and sways gently with the step (no flying or flaring coat), broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: directly from behind, walking AWAY up the screen, back of head only. Calm non-specific face. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, each boot exactly where the guide's boot is. The whole figure, coat included, at least 40 px inside every edge. No floor, shadow, scenery, text, halo or watermark.
CRITICAL: Reference image 2 has an unwanted surrounding brown halo: do not copy ANY halo or background. Generate ONLY the painted character on genuine transparent alpha, including between the legs. Image 3 is authoritative for figure size, head position and all limb coordinates; the standing image 2 is ONLY a rendering/identity reference. Image 4, if present, is previous-cycle rendering continuity ONLY; do not copy its pose or its unwanted halo. Keep coat narrow, hanging close to calves without wind. Native 1024x1536 output.
Pose frame05: RIGHT/blue boot reaches forward away, high in screen at x585,y1290; LEFT/red support boot trails toward viewer low at x440. Left/orange arm slightly back and lower; right/cyan arm forward and foreshortened, elbow only soft. Head top y219. Guide left boot nearly hits bottom: whole boot tip at most1495 for40px clearance. Hanging calf-length coat, upright calm walk.
```

Kept source: /Users/voightkampff/.codex/generated_images/01a15fc2-48ff-7c40-9cdc-90f46d669ece/exec-8a33976b-5b6e-47ea-9b8d-760c6a95c721.png

Selection and limitations: Candidate 1 kept: right leg progresses away while left trails, arm depth is opposed, rear coat remains controlled. Unresolved halo, head/boot positions drift; exact guide heel/toe shape not matched. Whole boot retained despite guide near bottom.

### walk_back_06

Output: out/walk_back_06.png

Inputs:

1. refs/avatar_captain_proposal_a.png
2. refs/accepted_v1_back.png
3. guides/walk_back_06.png
4. out/walk_back_05.png

Candidates: 1; candidate 1 retained. No alternate was generated for this frame.

Prompt:

```text
Use case: identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain WALK-cycle frame (06 of 12) for Stapledon's Voyage. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, leg and arm positions, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. A calm, unhurried, upright WALK — not a run, not a jog: at least one foot on the ground, heel striking first, the other foot rolling off its toe, arms hanging and swinging only slightly, elbows soft, shoulders relaxed, head level. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels that HANGS and sways gently with the step (no flying or flaring coat), broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: directly from behind, walking AWAY up the screen, back of head only. Calm non-specific face. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, each boot exactly where the guide's boot is. The whole figure, coat included, at least 40 px inside every edge. No floor, shadow, scenery, text, halo or watermark.
CRITICAL: Reference image 2 has an unwanted surrounding brown halo: do not copy ANY halo or background. Generate ONLY the painted character on genuine transparent alpha, including between the legs. Image 3 is authoritative for figure size, head position and all limb coordinates; the standing image 2 is ONLY a rendering/identity reference. Image 4, if present, is previous-cycle rendering continuity ONLY; do not copy its pose or its unwanted halo. Keep coat narrow, hanging close to calves without wind. Native 1024x1536 output.
Pose frame06 opposite contact: RIGHT/blue boot forward/away near x585,y1300, heel strike accepting weight; LEFT/red boot trailing toward viewer at x440 low, heel raised, toe pushes off. Left/orange arm back/down, right/cyan arm forward/foreshortened. Head top y225, level shoulders. Guide left foot clips bottom: keep WHOLE boot inside40px margin with tip no lower1495. Coat hangs.
```

Kept source: /Users/voightkampff/.codex/generated_images/01a15fc2-48ff-7c40-9cdc-90f46d669ece/exec-774a54f1-43a6-4933-a34d-9f3472125d93.png

Selection and limitations: Candidate 1 kept: opposite rear contact leg and arm opposition clear; coat controlled and approved paint maintained. Unresolved halo, head/foot registration and floor-contact ambiguity. Guide clipped left boot moved inside margin.

### walk_back_07

Output: out/walk_back_07.png

Inputs:

1. refs/avatar_captain_proposal_a.png
2. refs/accepted_v1_back.png
3. guides/walk_back_07.png
4. out/walk_back_06.png

Candidates: 1; candidate 1 retained. No alternate was generated for this frame.

Prompt:

```text
Use case: identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain WALK-cycle frame (07 of 12) for Stapledon's Voyage. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, leg and arm positions, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. A calm, unhurried, upright WALK — not a run, not a jog: at least one foot on the ground, heel striking first, the other foot rolling off its toe, arms hanging and swinging only slightly, elbows soft, shoulders relaxed, head level. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels that HANGS and sways gently with the step (no flying or flaring coat), broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: directly from behind, walking AWAY up the screen, back of head only. Calm non-specific face. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, each boot exactly where the guide's boot is. The whole figure, coat included, at least 40 px inside every edge. No floor, shadow, scenery, text, halo or watermark.
CRITICAL: Reference image 2 has an unwanted surrounding brown halo: do not copy ANY halo or background. Generate ONLY the painted character on genuine transparent alpha, including between the legs. Image 3 is authoritative for figure size, head position and all limb coordinates; the standing image 2 is ONLY a rendering/identity reference. Image 4, if present, is previous-cycle rendering continuity ONLY; do not copy its pose or its unwanted halo. Keep coat narrow, hanging close to calves without wind. Native 1024x1536 output.
Pose frame07: RIGHT/blue forward support boot higher on screen-right near x585,y1330, rolling flat. LEFT/red trailing leg extends toward viewer and toe rolls off, boot lower on left x440. Left/orange arm back/down to y930, right/cyan arm forward shorter to y780. Head top y226. Guide left boot clipped: keep whole boot inside40px bottom margin with tip<=1495. Unhurried, vertical torso, no flying coat.
```

Kept source: /Users/voightkampff/.codex/generated_images/01a15fc2-48ff-7c40-9cdc-90f46d669ece/exec-7afecfc7-7441-441a-aa05-193b70bd90b7.png

Selection and limitations: Candidate 1 kept: right support farther away, left toe-off lower, arm phase and hanging coat consistent. Unresolved halo, enlarged body/head position drift and exact foot placement; clipped guide boot kept whole.

### walk_back_08

Output: out/walk_back_08.png

Inputs:

1. refs/avatar_captain_proposal_a.png
2. refs/accepted_v1_back.png
3. guides/walk_back_08.png
4. out/walk_back_07.png

Candidates: 1; candidate 1 retained. No alternate was generated for this frame.

Prompt:

```text
Use case: identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain WALK-cycle frame (08 of 12) for Stapledon's Voyage. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, leg and arm positions, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. A calm, unhurried, upright WALK — not a run, not a jog: at least one foot on the ground, heel striking first, the other foot rolling off its toe, arms hanging and swinging only slightly, elbows soft, shoulders relaxed, head level. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels that HANGS and sways gently with the step (no flying or flaring coat), broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: directly from behind, walking AWAY up the screen, back of head only. Calm non-specific face. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, each boot exactly where the guide's boot is. The whole figure, coat included, at least 40 px inside every edge. No floor, shadow, scenery, text, halo or watermark.
CRITICAL: Reference image 2 has an unwanted surrounding brown halo: do not copy ANY halo or background. Generate ONLY the painted character on genuine transparent alpha, including between the legs. Image 3 is authoritative for figure size, head position and all limb coordinates; the standing image 2 is ONLY a rendering/identity reference. Image 4, if present, is previous-cycle rendering continuity ONLY; do not copy its pose or its unwanted halo. Keep coat narrow, hanging close to calves without wind. Native 1024x1536 output.
Pose frame08: RIGHT/blue support knee softly bends, boot screen-right x585,y1370. LEFT/red trailing boot x440 low, prepares toe-off, low clearance. Left/orange arm starts toward neutral but remains lower than forward right/cyan arm. Head top y220. Guide left boot touches bottom: whole boot tip no lower1495 with40px clearance. No high backward heel; grounded quiet walk and hanging coat.
```

Kept source: /Users/voightkampff/.codex/generated_images/01a15fc2-48ff-7c40-9cdc-90f46d669ece/exec-6128a43e-8864-4680-830b-3f781d97ab35.png

Selection and limitations: Candidate 1 kept: right support and left toe-off continue opposite step, identity/costume and hanging panels consistent. Unresolved halo, enlarged scale/head drift and exact guide boot/arm positions. Guide edge foot contained.

### walk_back_09

Output: out/walk_back_09.png

Inputs:

1. refs/avatar_captain_proposal_a.png
2. refs/accepted_v1_back.png
3. guides/walk_back_09.png
4. out/walk_back_08.png

Candidates: 1; candidate 1 retained. No alternate was generated for this frame.

Prompt:

```text
Use case: identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain WALK-cycle frame (09 of 12) for Stapledon's Voyage. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, leg and arm positions, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. A calm, unhurried, upright WALK — not a run, not a jog: at least one foot on the ground, heel striking first, the other foot rolling off its toe, arms hanging and swinging only slightly, elbows soft, shoulders relaxed, head level. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels that HANGS and sways gently with the step (no flying or flaring coat), broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: directly from behind, walking AWAY up the screen, back of head only. Calm non-specific face. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, each boot exactly where the guide's boot is. The whole figure, coat included, at least 40 px inside every edge. No floor, shadow, scenery, text, halo or watermark.
CRITICAL: Reference image 2 has an unwanted surrounding brown halo: do not copy ANY halo or background. Generate ONLY the painted character on genuine transparent alpha, including between the legs. Image 3 is authoritative for figure size, head position and all limb coordinates; the standing image 2 is ONLY a rendering/identity reference. Image 4, if present, is previous-cycle rendering continuity ONLY; do not copy its pose or its unwanted halo. Keep coat narrow, hanging close to calves without wind. Native 1024x1536 output.
Pose frame09, opposite passing: RIGHT/blue support boot screen-right near x585,y1410, LEFT/red swing boot alongside on left near x440,y1450. Both arms near neutral with hands same height around y850, shoulders level. Head top y214. Low foot clearance, no high heel kick, at least one flat planted boot. Guide left tip has~30px margin: keep at least40px. Rear coat close to guide silhouette.
```

Kept source: /Users/voightkampff/.codex/generated_images/01a15fc2-48ff-7c40-9cdc-90f46d669ece/exec-680fea73-7d63-4bed-9959-744c2d90493d.png

Selection and limitations: Candidate 1 kept: feet move alongside in opposite passing phase, rendering and gentle rear coat maintained. Unresolved halo, unequal arm heights, head/boot drift and left sole exposure beyond guide. Guide~30px foot margin prioritized to40px in prompt.

### walk_back_10

Output: out/walk_back_10.png

Inputs:

1. refs/avatar_captain_proposal_a.png
2. refs/accepted_v1_back.png
3. guides/walk_back_10.png
4. out/walk_back_09.png

Candidates: 1; candidate 1 retained. No alternate was generated for this frame.

Prompt:

```text
Use case: identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain WALK-cycle frame (10 of 12) for Stapledon's Voyage. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, leg and arm positions, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. A calm, unhurried, upright WALK — not a run, not a jog: at least one foot on the ground, heel striking first, the other foot rolling off its toe, arms hanging and swinging only slightly, elbows soft, shoulders relaxed, head level. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels that HANGS and sways gently with the step (no flying or flaring coat), broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: directly from behind, walking AWAY up the screen, back of head only. Calm non-specific face. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, each boot exactly where the guide's boot is. The whole figure, coat included, at least 40 px inside every edge. No floor, shadow, scenery, text, halo or watermark.
CRITICAL: Reference image 2 has an unwanted surrounding brown halo: do not copy ANY halo or background. Generate ONLY the painted character on genuine transparent alpha, including between the legs. Image 3 is authoritative for figure size, head position and all limb coordinates; the standing image 2 is ONLY a rendering/identity reference. Image 4, if present, is previous-cycle rendering continuity ONLY; do not copy its pose or its unwanted halo. Keep coat narrow, hanging close to calves without wind. Native 1024x1536 output.
Pose frame10: RIGHT/blue support leg trails on screen-right, boot near x585,y1450. LEFT/red swing knee softly flexes forward away, boot screen-left x440,y1350. Left/orange arm forward appears shorter, right/cyan arm swinging back appears longer and lower. Head top y214. Low foot clearance, gentle heel/toe roll, no flight. Guide right boot~35px from bottom: preserve at least40px margin. Hanging split rear coat.
```

Kept source: /Users/voightkampff/.codex/generated_images/01a15fc2-48ff-7c40-9cdc-90f46d669ece/exec-682d39b0-2adc-4da0-8cad-a3f593b2a489.png

Selection and limitations: Candidate 1 kept: left swing advances away while right supports, arms reverse in intended opposition; hanging coat and paint preserved. Unresolved halo, guide head/boot placement and excessive sole visibility. Prompt prioritizes40px boot margin.

### walk_back_11

Output: out/walk_back_11.png

Inputs:

1. refs/avatar_captain_proposal_a.png
2. refs/accepted_v1_back.png
3. guides/walk_back_11.png
4. out/walk_back_10.png

Candidates: 1; candidate 1 retained. No alternate was generated for this frame.

Prompt:

```text
Use case: identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain WALK-cycle frame (11 of 12) for Stapledon's Voyage. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, leg and arm positions, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. A calm, unhurried, upright WALK — not a run, not a jog: at least one foot on the ground, heel striking first, the other foot rolling off its toe, arms hanging and swinging only slightly, elbows soft, shoulders relaxed, head level. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels that HANGS and sways gently with the step (no flying or flaring coat), broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: directly from behind, walking AWAY up the screen, back of head only. Calm non-specific face. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, each boot exactly where the guide's boot is. The whole figure, coat included, at least 40 px inside every edge. No floor, shadow, scenery, text, halo or watermark.
CRITICAL: Reference image 2 has an unwanted surrounding brown halo: do not copy ANY halo or background. Generate ONLY the painted character on genuine transparent alpha, including between the legs. Image 3 is authoritative for figure size, head position and all limb coordinates; the standing image 2 is ONLY a rendering/identity reference. Image 4, if present, is previous-cycle rendering continuity ONLY; do not copy its pose or its unwanted halo. Keep coat narrow, hanging close to calves without wind. Native 1024x1536 output.
Pose frame11: LEFT/red leg reaches forward away, its boot higher at x440,y1290 preparing next left heel strike in frame00. RIGHT/blue support boot trails lower at x585,y1480. Left/orange arm forward foreshortened and right/cyan arm back lower. Head top y219. Guide right tip near bottom violates40px clearance: keep entire boot tip no lower1495. Close cycle gently toward frame00, quiet low feet and hanging rear coat, no wind.
```

Kept source: /Users/voightkampff/.codex/generated_images/01a15fc2-48ff-7c40-9cdc-90f46d669ece/exec-39b62ee3-3141-43b5-9f01-f47c22e7f260.png

Selection and limitations: Candidate 1 kept: left reaches away, right trails and opposing hands prepare return to frame00; accepted rear rendering and hanging coat preserved. Unresolved halo, head/scale/boot registration drift, sole orientation and seamless loop not certified. Guide foot margin conflict noted.

End of requested paint pass. No downstream animation, game integration, publishing or additional art work performed.

