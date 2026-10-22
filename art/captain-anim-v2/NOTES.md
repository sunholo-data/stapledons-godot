# Captain jog repaint notes

Exactly 24 frames were painted with 24 separate calls to the built-in image generation tool: profile 00–11 first, then back 00–11. One candidate was generated and kept per frame; no alternate candidates were generated or ranked. All 24 native PNGs were copied into `out/` without resizing, mirroring, compositing, alpha repair or other pixel editing. No git, installs, other network calls, animation assembly or downstream integration were performed.

The identity, both approved stage-0 stills, both accepted earlier paintings, and all 24 pose guides were inspected. Each generation used the attachment list recorded below (at most four images). The previous painting was omitted for jog_profile_03, jog_profile_08, jog_back_03, jog_back_06, jog_back_09 to reduce pose/arm anchoring; the identity, accepted rendering and current guide remained attached.

## Outcome and unresolved issues

All 24 files exist at their requested names, are native **1024 × 1536, 8-bit RGBA**, pass PNG chunk CRC and decompression checks, and have distinct SHA-256 hashes. Distinct bytes do not establish distinct gait poses: near-repeated poses and insufficient pose changes are called out in the individual reviews.

**These frames do not fully meet the production brief.** The built-in tool retained a visible soft halo/wash from the accepted rendering despite `transparent_background: true` and repeated explicit requests to exclude it. Exact alpha-zero outside the figure was not achieved. 17 of 24 files also contain nonzero alpha within the required 16-pixel transparent border. The remaining files pass that border-only check but still have a visible halo closer to the figure. All returned alpha ranges are 0–254 (there are no alpha-255 pixels); this was preserved unchanged.

Pose transfer and framing are also imperfect. The generator repeatedly enlarged or raised the head relative to the guide, approximated boot locations and angles, and sometimes copied too much of the previous gait phase. Profile 01–02 and 06–07, plus back 01–02, 07–08 and 11, are especially weak on the requested phase changes or compression. Every frame has unresolved deviations, described below. The sole candidate was retained for its character/rendering match and whatever pose structure it achieved, not because it passed all requirements.

Validation below used only read-only PNG inspection with the Python standard library. It did not alter the artwork. A border count of zero certifies only the 16-pixel border, not alpha outside the anatomical silhouette.

## jog_profile_00.png

Output: `out/jog_profile_00.png`.

Inputs (attachment order): Image 1: `refs/avatar_captain_proposal_a.png`; Image 2: `refs/accepted_v1_profile.png`; Image 3: `guides/jog_profile_00.png`.

Candidates: candidate 1. Selection/review: Character rendering and opposite arm swing retained; left planted boot and right recovery leg present. Deviations: head is higher/larger than guide, rear heel angle differs, and a visible background halo remains despite transparent-background request.

Native file QA: 1024 × 1536, RGBA8; alpha range 0–254; 1,125,717 alpha-zero pixels; **135 nonzero-alpha pixels in the 16-pixel border**.

SHA-256: `858c0f50b503bec802640b382acdc5016f0bde7a5c8f59fd2c66b5a406706549`.

Generated source: `/Users/voightkampff/.codex/generated_images/01a15ea2-a119-7993-8620-babc75a736d0/exec-5d6ac880-b62a-4085-99e6-736cbb2ceecb.png`.

Exact submitted prompt:

```text
Use case: identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain jog-cycle frame (1 of 12) for Stapledon's Voyage. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, limb positions, body lean, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. A natural, light, believable jog: planted foot flat on the ground where the guide's touches the ground line, the recovering leg's heel kicking up behind, arms swinging opposite to the legs with elbows bent about 90 degrees, a slight forward lean. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels (it swings and trails with the stride), broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: full side view moving to screen-RIGHT, captain's right side toward viewer. Calm non-specific face. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, each boot exactly where the guide's boot is. At least 16 px fully transparent on every edge. No floor, shadow, scenery, text, halo or watermark.
Pose for frame 00: Left leg extends forward and down to planted flat boot at screen right near (795,1365). Right knee is bent with lower leg folded back horizontally left, airborne boot near (300,1225). Right arm swings back/down; left arm swings forward/up. Head crown near (435,220). Do not copy the earlier frame's tall framing or halo.
```

## jog_profile_01.png

Output: `out/jog_profile_01.png`.

Inputs (attachment order): Image 1: `refs/avatar_captain_proposal_a.png`; Image 2: `refs/accepted_v1_profile.png`; Image 3: `guides/jog_profile_01.png`; Image 4: `out/jog_profile_00.png`.

Candidates: candidate 1 (sole candidate). Selection/review: Retained for character rendering. Failed guide compression: output repeats the broad stride of frame 00 with minor changes, planted boot too far right, head too high; halo persists.

Native file QA: 1024 × 1536, RGBA8; alpha range 0–254; 1,122,308 alpha-zero pixels; **5 nonzero-alpha pixels in the 16-pixel border**.

SHA-256: `d83472cad17f8757cf58eba1aebb19702b6e8857e5048f5fbc105de29d037e95`.

Generated source: `/Users/voightkampff/.codex/generated_images/01a15ea2-a119-7993-8620-babc75a736d0/exec-047dee5c-f631-4478-983e-e2204cd80206.png`.

Exact submitted prompt:

```text
Use case: identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain jog-cycle frame (2 of 12) for Stapledon's Voyage. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, limb positions, body lean, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. A natural, light, believable jog: planted foot flat on the ground where the guide's touches the ground line, the recovering leg's heel kicking up behind, arms swinging opposite to the legs with elbows bent about 90 degrees, a slight forward lean. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels (it swings and trails with the stride), broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: full side view moving to screen-RIGHT, captain's right side toward viewer. Calm non-specific face. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, each boot exactly where the guide's boot is. At least 16 px fully transparent on every edge. No floor, shadow, scenery, text, halo or watermark.
Pose for frame 01: Left planted boot stays near (620,1365), below a bent left knee at (680,1060). Right knee comes forward at (650,1140) with lower leg folded back left, airborne right boot near (400,1210). Right arm back and down with hand near (600,915), left arm forward/up near (780,505). Crown near (435,235). This is a distinct compression/passing pose.
Image 4, when provided, is only the previous frame's character-rendering reference; the current Image 3 guide overrides its pose. CRITICAL: match Image 3's smaller figure framing and exact boot/head coordinates. Do not enlarge the figure to fill the canvas as Image 2 does. Exclude the entire dark/gold halo/background of Image 2 and Image 4: the canvas outside the painted person must be empty transparent alpha=0, including between limbs. No atmospheric paint outside the silhouette.
```

## jog_profile_02.png

Output: `out/jog_profile_02.png`.

Inputs (attachment order): Image 1: `refs/avatar_captain_proposal_a.png`; Image 2: `refs/accepted_v1_profile.png`; Image 3: `guides/jog_profile_02.png`; Image 4: `out/jog_profile_01.png`.

Candidates: candidate 1 (sole candidate). Selection/review: Retained consistent hair, face, costume and paint. Guide pose not achieved: right knee should lead, but generated legs still resemble previous recovery stride. Head too high and halo remains.

Native file QA: 1024 × 1536, RGBA8; alpha range 0–254; 1,137,299 alpha-zero pixels; **14 nonzero-alpha pixels in the 16-pixel border**.

SHA-256: `81a1e4dd15a5a702b5e041cc60a1cbcc1c5b71c82ffeeebd1f32cf14e4801f61`.

Generated source: `/Users/voightkampff/.codex/generated_images/01a15ea2-a119-7993-8620-babc75a736d0/exec-4748bcf2-facf-4ad0-9f62-4ddbcaf204aa.png`.

Exact submitted prompt:

```text
PRIMARY EDIT TARGET IS IMAGE 3, THE COLOUR-KEYED POSE GUIDE. Repaint that mannequin into the captain, keeping its entire skeleton, head position, hands, knees and boots locked at their original pixel locations. Image 1 and Image 2 supply paint, face and costume ONLY, not composition or pose. Image 4 supplies ONLY rendering continuity, never pose. This is a new, distinct gait phase, not a variation on Image 4. The guide's red and blue legs must both become VIOLET trousers and BROWN boots. The guide's orange and cyan arms must both become CREAM sleeves and skin hands. Keep the guide's canvas transparent; no background gradient or halo from the earlier painted references.
Use case: identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain jog-cycle frame (3 of 12) for Stapledon's Voyage. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, limb positions, body lean, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. A natural, light, believable jog: planted foot flat on the ground where the guide's touches the ground line, the recovering leg's heel kicking up behind, arms swinging opposite to the legs with elbows bent about 90 degrees, a slight forward lean. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels (it swings and trails with the stride), broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: full side view moving to screen-RIGHT, captain's right side toward viewer. Calm non-specific face. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, each boot exactly where the guide's boot is. At least 16 px fully transparent on every edge. No floor, shadow, scenery, text, halo or watermark.
Pose for frame 02: Left foot is planted near (445,1365), trailing behind hip. Right knee raised ahead to (735,1080), right lower leg folded back with airborne boot near (520,1210). Right hand near (665,880), left hand forward near (780,560). Crown near (435,245).
Image 4, when provided, is only the previous frame's character-rendering reference; the current Image 3 guide overrides its pose. CRITICAL: match Image 3's smaller figure framing and exact boot/head coordinates. Do not enlarge the figure to fill the canvas as Image 2 does. Exclude the entire dark/gold halo/background of Image 2 and Image 4: the canvas outside the painted person must be empty transparent alpha=0, including between limbs. No atmospheric paint outside the silhouette.
```

## jog_profile_03.png

Output: `out/jog_profile_03.png`.

Inputs (attachment order): Image 1: `refs/avatar_captain_proposal_a.png`; Image 2: `refs/accepted_v1_profile.png`; Image 3: `guides/jog_profile_03.png`.

Candidates: candidate 1 (sole candidate). Selection/review: Kept because raised forward right knee and trailing left leg now match the guide's flight-phase structure, with accepted rendering. Previous-frame attachment omitted here after pose anchoring in 01–02. Deviations: head still too high, boot angles/positions approximate, and halo persists.

Native file QA: 1024 × 1536, RGBA8; alpha range 0–254; 1,194,959 alpha-zero pixels; **7 nonzero-alpha pixels in the 16-pixel border**.

SHA-256: `b5cb4c5db8bd7d5cfb5d7bfa3ad12b2ff686a798afd49dd47d2e3152f7d639f3`.

Generated source: `/Users/voightkampff/.codex/generated_images/01a15ea2-a119-7993-8620-babc75a736d0/exec-dd90d7aa-a9f9-452c-9a4e-fda4044a4dec.png`.

Exact submitted prompt:

```text
PRIMARY EDIT TARGET IS IMAGE 3, THE COLOUR-KEYED POSE GUIDE. Paint over its mannequin with the detailed captain, keeping its skeleton and all positions fixed. The RIGHT thigh points FORWARD toward screen right, nearly horizontal, and right knee is high in front of body; right lower leg folds back. The LEFT leg trails toward screen left. This reverses the legs of the earlier painted reference. BOTH BOOTS AIRBORNE. Image 1 and 2 provide ONLY identity/style/costume. Never copy their pose, framing or halo. Keep empty transparent alpha=0 around figure.
Use case: identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain jog-cycle frame (4 of 12) for Stapledon's Voyage. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, limb positions, body lean, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. A natural, light, believable jog: planted foot flat on the ground where the guide's touches the ground line, the recovering leg's heel kicking up behind, arms swinging opposite to the legs with elbows bent about 90 degrees, a slight forward lean. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels (it swings and trails with the stride), broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: full side view moving to screen-RIGHT, captain's right side toward viewer. Calm non-specific face. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, each boot exactly where the guide's boot is. At least 16 px fully transparent on every edge. No floor, shadow, scenery, text, halo or watermark.
Pose for frame 03: Flight: neither boot grounded. Left leg trails down/back with left boot near (250,1330); right knee lifts forward near (780,1000), lower right leg folds back to boot near (625,1230). Right forearm forward near waist level, hand (740,785); left hand (740,610). Crown (435,235).
Image 4, when provided, is only the previous frame's character-rendering reference; the current Image 3 guide overrides its pose. CRITICAL: match Image 3's smaller figure framing and exact boot/head coordinates. Do not enlarge the figure to fill the canvas as Image 2 does. Exclude the entire dark/gold halo/background of Image 2 and Image 4: the canvas outside the painted person must be empty transparent alpha=0, including between limbs. No atmospheric paint outside the silhouette.
```

## jog_profile_04.png

Output: `out/jog_profile_04.png`.

Inputs (attachment order): Image 1: `refs/avatar_captain_proposal_a.png`; Image 2: `refs/accepted_v1_profile.png`; Image 3: `guides/jog_profile_04.png`; Image 4: `out/jog_profile_03.png`.

Candidates: candidate 1 (sole candidate). Selection/review: Kept for distinct flight pose, raised right knee and accepted paint. Guide only approximate: trailing left boot too low, forward right forearm too horizontal, and halo persists.

Native file QA: 1024 × 1536, RGBA8; alpha range 0–254; 1,189,833 alpha-zero pixels; **2 nonzero-alpha pixels in the 16-pixel border**.

SHA-256: `ca1d352283dda01d7d98e42087d340da4a093a1cec0c30179128326375639e24`.

Generated source: `/Users/voightkampff/.codex/generated_images/01a15ea2-a119-7993-8620-babc75a736d0/exec-064e6928-286f-44f7-aa9c-e0327e46e224.png`.

Exact submitted prompt:

```text
PRIMARY EDIT TARGET IS IMAGE 3, THE COLOUR-KEYED POSE GUIDE. Repaint that mannequin into the captain, keeping its entire skeleton, head position, hands, knees and boots locked at their original pixel locations. Image 1 and Image 2 supply paint, face and costume ONLY, not composition or pose. Image 4 supplies ONLY rendering continuity, never pose. This is a new, distinct gait phase, not a variation on Image 4. The guide's red and blue legs must both become VIOLET trousers and BROWN boots. The guide's orange and cyan arms must both become CREAM sleeves and skin hands. Keep the guide's canvas transparent; no background gradient or halo from the earlier painted references.
Use case: identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain jog-cycle frame (5 of 12) for Stapledon's Voyage. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, limb positions, body lean, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. A natural, light, believable jog: planted foot flat on the ground where the guide's touches the ground line, the recovering leg's heel kicking up behind, arms swinging opposite to the legs with elbows bent about 90 degrees, a slight forward lean. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels (it swings and trails with the stride), broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: full side view moving to screen-RIGHT, captain's right side toward viewer. Calm non-specific face. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, each boot exactly where the guide's boot is. At least 16 px fully transparent on every edge. No floor, shadow, scenery, text, halo or watermark.
Pose for frame 04: Flight with wide split: left leg trails to airborne boot near (180,1210), right knee forward near (800,970) and right boot airborne near (720,1250). Right arm swings forward with fist (780,680), left arm recedes with hand (675,650). Crown near (435,220).
Image 4, when provided, is only the previous frame's character-rendering reference; the current Image 3 guide overrides its pose. CRITICAL: match Image 3's smaller figure framing and exact boot/head coordinates. Do not enlarge the figure to fill the canvas as Image 2 does. Exclude the entire dark/gold halo/background of Image 2 and Image 4: the canvas outside the painted person must be empty transparent alpha=0, including between limbs. No atmospheric paint outside the silhouette.
```

## jog_profile_05.png

Output: `out/jog_profile_05.png`.

Inputs (attachment order): Image 1: `refs/avatar_captain_proposal_a.png`; Image 2: `refs/accepted_v1_profile.png`; Image 3: `guides/jog_profile_05.png`; Image 4: `out/jog_profile_04.png`.

Candidates: candidate 1 (sole candidate). Selection/review: Kept for sharper left-heel recovery, lowered right boot and raised right arm; clearly differs from 04 and retains costume. Guide framing remains approximate, head too high and left boot angle too vertical; halo persists.

Native file QA: 1024 × 1536, RGBA8; alpha range 0–254; 1,189,116 alpha-zero pixels; **8 nonzero-alpha pixels in the 16-pixel border**.

SHA-256: `e87941067adccc5839038d9f9bbe86fdba821d78ca0291b496310cc240c415c2`.

Generated source: `/Users/voightkampff/.codex/generated_images/01a15ea2-a119-7993-8620-babc75a736d0/exec-d2e7be44-35f7-44fb-a6b8-985f9286a7c1.png`.

Exact submitted prompt:

```text
PRIMARY EDIT TARGET IS IMAGE 3, THE COLOUR-KEYED POSE GUIDE. Repaint that mannequin into the captain, keeping its entire skeleton, head position, hands, knees and boots locked at their original pixel locations. Image 1 and Image 2 supply paint, face and costume ONLY, not composition or pose. Image 4 supplies ONLY rendering continuity, never pose. This is a new, distinct gait phase, not a variation on Image 4. The guide's red and blue legs must both become VIOLET trousers and BROWN boots. The guide's orange and cyan arms must both become CREAM sleeves and skin hands. Keep the guide's canvas transparent; no background gradient or halo from the earlier painted references.
Use case: identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain jog-cycle frame (6 of 12) for Stapledon's Voyage. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, limb positions, body lean, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. A natural, light, believable jog: planted foot flat on the ground where the guide's touches the ground line, the recovering leg's heel kicking up behind, arms swinging opposite to the legs with elbows bent about 90 degrees, a slight forward lean. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels (it swings and trails with the stride), broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: full side view moving to screen-RIGHT, captain's right side toward viewer. Calm non-specific face. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, each boot exactly where the guide's boot is. At least 16 px fully transparent on every edge. No floor, shadow, scenery, text, halo or watermark.
Pose for frame 05: Flight approaching right contact: left heel kicked high/back, left boot near (220,1190); right knee ahead (790,990), right boot airborne near (780,1295). Right hand forward/up near (790,600); left arm behind. Crown (435,215).
Image 4, when provided, is only the previous frame's character-rendering reference; the current Image 3 guide overrides its pose. CRITICAL: match Image 3's smaller figure framing and exact boot/head coordinates. Do not enlarge the figure to fill the canvas as Image 2 does. Exclude the entire dark/gold halo/background of Image 2 and Image 4: the canvas outside the painted person must be empty transparent alpha=0, including between limbs. No atmospheric paint outside the silhouette.
Specific change from previous frame: bend the recovering LEFT knee sharply, bringing left heel up to y1190 instead of y1300, while lowering and extending the right shin toward next contact. Raise RIGHT forearm diagonally forward/up, fist y600. Do not repeat previous pose.
```

## jog_profile_06.png

Output: `out/jog_profile_06.png`.

Inputs (attachment order): Image 1: `refs/avatar_captain_proposal_a.png`; Image 2: `refs/accepted_v1_profile.png`; Image 3: `guides/jog_profile_06.png`; Image 4: `out/jog_profile_05.png`.

Candidates: candidate 1 (sole candidate). Selection/review: Kept for right-support/left-recovery structure and accepted character. Contact is not exact: planted right boot is too high, left boot too vertical, head too high; pose too close to 05 and halo persists.

Native file QA: 1024 × 1536, RGBA8; alpha range 0–254; 1,198,264 alpha-zero pixels; **0 nonzero-alpha pixels in the 16-pixel border**.

SHA-256: `978fb5e8e64eca5353f84bb25eb4e44a7f39906d56b0a208a093eb63a1704e0c`.

Generated source: `/Users/voightkampff/.codex/generated_images/01a15ea2-a119-7993-8620-babc75a736d0/exec-a9cf1930-e580-44d1-9a73-9f8fa10fb415.png`.

Exact submitted prompt:

```text
PRIMARY EDIT TARGET IS IMAGE 3, THE COLOUR-KEYED POSE GUIDE. Repaint that mannequin into the captain, keeping its entire skeleton, head position, hands, knees and boots locked at their original pixel locations. Image 1 and Image 2 supply paint, face and costume ONLY, not composition or pose. Image 4 supplies ONLY rendering continuity, never pose. This is a new, distinct gait phase, not a variation on Image 4. The guide's red and blue legs must both become VIOLET trousers and BROWN boots. The guide's orange and cyan arms must both become CREAM sleeves and skin hands. Keep the guide's canvas transparent; no background gradient or halo from the earlier painted references.
Use case: identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain jog-cycle frame (7 of 12) for Stapledon's Voyage. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, limb positions, body lean, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. A natural, light, believable jog: planted foot flat on the ground where the guide's touches the ground line, the recovering leg's heel kicking up behind, arms swinging opposite to the legs with elbows bent about 90 degrees, a slight forward lean. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels (it swings and trails with the stride), broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: full side view moving to screen-RIGHT, captain's right side toward viewer. Calm non-specific face. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, each boot exactly where the guide's boot is. At least 16 px fully transparent on every edge. No floor, shadow, scenery, text, halo or watermark.
Pose for frame 06: Right leg extends forward/down to planted right boot near (795,1420). Left knee bends behind with left lower leg folded back horizontally to airborne boot near (300,1160). Right arm forward/up, right fist (790,590); left arm back/down. Crown (435,225).
Image 4, when provided, is only the previous frame's character-rendering reference; the current Image 3 guide overrides its pose. CRITICAL: match Image 3's smaller figure framing and exact boot/head coordinates. Do not enlarge the figure to fill the canvas as Image 2 does. Exclude the entire dark/gold halo/background of Image 2 and Image 4: the canvas outside the painted person must be empty transparent alpha=0, including between limbs. No atmospheric paint outside the silhouette.
Contact phase: right planted boot flat, right shin extends down/front, left heel stays raised behind. Guide head crown at y225, not y145 as prior painting; keep exact guide figure size. Clean cutout, NO halo.
```

## jog_profile_07.png

Output: `out/jog_profile_07.png`.

Inputs (attachment order): Image 1: `refs/avatar_captain_proposal_a.png`; Image 2: `refs/accepted_v1_profile.png`; Image 3: `guides/jog_profile_07.png`; Image 4: `out/jog_profile_06.png`.

Candidates: candidate 1 (sole candidate). Selection/review: Kept for character consistency and slight compression/arm/coat change. Failed exact compression: right boot remains too far forward and high, left boot too far back, head too high; halo persists.

Native file QA: 1024 × 1536, RGBA8; alpha range 0–254; 1,188,030 alpha-zero pixels; **0 nonzero-alpha pixels in the 16-pixel border**.

SHA-256: `bb80b2ee0d7dc61f8165448e505c22ce14205d99a291695854f2754ad7c57927`.

Generated source: `/Users/voightkampff/.codex/generated_images/01a15ea2-a119-7993-8620-babc75a736d0/exec-8794b295-a0dc-422c-8765-dbaea16f9267.png`.

Exact submitted prompt:

```text
PRIMARY EDIT TARGET IS IMAGE 3, THE COLOUR-KEYED POSE GUIDE. Repaint that mannequin into the captain, keeping its entire skeleton, head position, hands, knees and boots locked at their original pixel locations. Image 1 and Image 2 supply paint, face and costume ONLY, not composition or pose. Image 4 supplies ONLY rendering continuity, never pose. This is a new, distinct gait phase, not a variation on Image 4. The guide's red and blue legs must both become VIOLET trousers and BROWN boots. The guide's orange and cyan arms must both become CREAM sleeves and skin hands. Keep the guide's canvas transparent; no background gradient or halo from the earlier painted references.
Use case: identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain jog-cycle frame (8 of 12) for Stapledon's Voyage. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, limb positions, body lean, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. A natural, light, believable jog: planted foot flat on the ground where the guide's touches the ground line, the recovering leg's heel kicking up behind, arms swinging opposite to the legs with elbows bent about 90 degrees, a slight forward lean. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels (it swings and trails with the stride), broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: full side view moving to screen-RIGHT, captain's right side toward viewer. Calm non-specific face. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, each boot exactly where the guide's boot is. At least 16 px fully transparent on every edge. No floor, shadow, scenery, text, halo or watermark.
Pose for frame 07: Right stance compression: planted right boot near (620,1435), right knee flexed near (680,1140); left heel up behind with boot near (400,1145). Right arm forward/up to hand (790,635), left arm back. Crown (435,245).
Image 4, when provided, is only the previous frame's character-rendering reference; the current Image 3 guide overrides its pose. CRITICAL: match Image 3's smaller figure framing and exact boot/head coordinates. Do not enlarge the figure to fill the canvas as Image 2 does. Exclude the entire dark/gold halo/background of Image 2 and Image 4: the canvas outside the painted person must be empty transparent alpha=0, including between limbs. No atmospheric paint outside the silhouette.
NEW POSE: compress body downward, bend supporting RIGHT knee deeply and move planted right boot to x620,y1435. Bring left airborne heel toward body to x400,y1145. Right arm forward/up; left arm back/down. Do not retain the extended boot position from Image 4.
```

## jog_profile_08.png

Output: `out/jog_profile_08.png`.

Inputs (attachment order): Image 1: `refs/avatar_captain_proposal_a.png`; Image 2: `refs/accepted_v1_profile.png`; Image 3: `guides/jog_profile_08.png`.

Candidates: candidate 1 (sole candidate). Selection/review: Kept because left knee is now raised and right leg extends down as required. Previous-frame attachment omitted to break pose anchoring. Exact foot angles and arm swing differ, head is much too high and halo remains.

Native file QA: 1024 × 1536, RGBA8; alpha range 0–254; 1,170,512 alpha-zero pixels; **4 nonzero-alpha pixels in the 16-pixel border**.

SHA-256: `222d42746c6658a700aa385b9e9bb7bee6532292743d49453bdac5ee909fe878`.

Generated source: `/Users/voightkampff/.codex/generated_images/01a15ea2-a119-7993-8620-babc75a736d0/exec-bb0a78b9-69f3-483a-88e7-0d3f478a50ae.png`.

Exact submitted prompt:

```text
Paint Image 3, not Image 2: LEFT knee high and forward, LEFT heel tucked backward. RIGHT leg supports and trails down toward screen left. RIGHT arm remains forward/up, LEFT arm recedes. This is late right stance, a new gait pose.
PRIMARY EDIT TARGET IS IMAGE 3, THE COLOUR-KEYED POSE GUIDE. Repaint that mannequin into the captain, keeping its entire skeleton, head position, hands, knees and boots locked at their original pixel locations. Image 1 and Image 2 supply paint, face and costume ONLY, not composition or pose. Image 4 supplies ONLY rendering continuity, never pose. This is a new, distinct gait phase, not a variation on Image 4. The guide's red and blue legs must both become VIOLET trousers and BROWN boots. The guide's orange and cyan arms must both become CREAM sleeves and skin hands. Keep the guide's canvas transparent; no background gradient or halo from the earlier painted references.
Use case: identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain jog-cycle frame (9 of 12) for Stapledon's Voyage. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, limb positions, body lean, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. A natural, light, believable jog: planted foot flat on the ground where the guide's touches the ground line, the recovering leg's heel kicking up behind, arms swinging opposite to the legs with elbows bent about 90 degrees, a slight forward lean. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels (it swings and trails with the stride), broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: full side view moving to screen-RIGHT, captain's right side toward viewer. Calm non-specific face. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, each boot exactly where the guide's boot is. At least 16 px fully transparent on every edge. No floor, shadow, scenery, text, halo or watermark.
Pose for frame 08: Right stance late: planted right boot near (445,1435), right knee near (600,1190); left knee high forward near (735,1000) with left lower leg folded back to airborne boot (520,1140). Right hand (780,715), left hand (675,680). Crown (435,245).
Image 4, when provided, is only the previous frame's character-rendering reference; the current Image 3 guide overrides its pose. CRITICAL: match Image 3's smaller figure framing and exact boot/head coordinates. Do not enlarge the figure to fill the canvas as Image 2 does. Exclude the entire dark/gold halo/background of Image 2 and Image 4: the canvas outside the painted person must be empty transparent alpha=0, including between limbs. No atmospheric paint outside the silhouette.
```

## jog_profile_09.png

Output: `out/jog_profile_09.png`.

Inputs (attachment order): Image 1: `refs/avatar_captain_proposal_a.png`; Image 2: `refs/accepted_v1_profile.png`; Image 3: `guides/jog_profile_09.png`; Image 4: `out/jog_profile_08.png`.

Candidates: candidate 1 (sole candidate). Selection/review: Kept for distinct flight stride, trailing right leg and raised left knee with boots relatively close to guide. Head too high, arms differ from guide's passing swing, halo persists.

Native file QA: 1024 × 1536, RGBA8; alpha range 0–254; 1,184,749 alpha-zero pixels; **0 nonzero-alpha pixels in the 16-pixel border**.

SHA-256: `4a5f05175210966fcc3e7169bc10dedbd478518f0261b1af6c1868d9b4477c74`.

Generated source: `/Users/voightkampff/.codex/generated_images/01a15ea2-a119-7993-8620-babc75a736d0/exec-819e2e57-d009-4af4-ab78-090a5a30eafd.png`.

Exact submitted prompt:

```text
PRIMARY EDIT TARGET IS IMAGE 3, THE COLOUR-KEYED POSE GUIDE. Repaint that mannequin into the captain, keeping its entire skeleton, head position, hands, knees and boots locked at their original pixel locations. Image 1 and Image 2 supply paint, face and costume ONLY, not composition or pose. Image 4 supplies ONLY rendering continuity, never pose. This is a new, distinct gait phase, not a variation on Image 4. The guide's red and blue legs must both become VIOLET trousers and BROWN boots. The guide's orange and cyan arms must both become CREAM sleeves and skin hands. Keep the guide's canvas transparent; no background gradient or halo from the earlier painted references.
Use case: identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain jog-cycle frame (10 of 12) for Stapledon's Voyage. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, limb positions, body lean, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. A natural, light, believable jog: planted foot flat on the ground where the guide's touches the ground line, the recovering leg's heel kicking up behind, arms swinging opposite to the legs with elbows bent about 90 degrees, a slight forward lean. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels (it swings and trails with the stride), broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: full side view moving to screen-RIGHT, captain's right side toward viewer. Calm non-specific face. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, each boot exactly where the guide's boot is. At least 16 px fully transparent on every edge. No floor, shadow, scenery, text, halo or watermark.
Pose for frame 09: Flight: right leg trails down/back to airborne boot (250,1405); left knee raised forward (785,920), lower leg folded back to left boot (625,1150). Right forearm near horizontal with fist (740,785), left hand (740,610). Crown (435,235).
Image 4, when provided, is only the previous frame's character-rendering reference; the current Image 3 guide overrides its pose. CRITICAL: match Image 3's smaller figure framing and exact boot/head coordinates. Do not enlarge the figure to fill the canvas as Image 2 does. Exclude the entire dark/gold halo/background of Image 2 and Image 4: the canvas outside the painted person must be empty transparent alpha=0, including between limbs. No atmospheric paint outside the silhouette.
Move right boot farther BACK to x250,y1405; keep left knee high in front but place left boot x625,y1150. Lower head to crown y235 exactly as guide. Both boots airborne.
```

## jog_profile_10.png

Output: `out/jog_profile_10.png`.

Inputs (attachment order): Image 1: `refs/avatar_captain_proposal_a.png`; Image 2: `refs/accepted_v1_profile.png`; Image 3: `guides/jog_profile_10.png`; Image 4: `out/jog_profile_09.png`.

Candidates: candidate 1 (sole candidate). Selection/review: Kept for visible arm reversal and distinct flight stride in accepted style. Right trailing boot remains too low and rear leg too extended; guide head framing and boot angles not exact; halo persists.

Native file QA: 1024 × 1536, RGBA8; alpha range 0–254; 1,156,975 alpha-zero pixels; **0 nonzero-alpha pixels in the 16-pixel border**.

SHA-256: `060709ac7169387fa20af0c731082e8de6904feae0497b7e8707286f9e07cd4f`.

Generated source: `/Users/voightkampff/.codex/generated_images/01a15ea2-a119-7993-8620-babc75a736d0/exec-faf5469c-0dcc-41f8-bfd8-00e6a120b46a.png`.

Exact submitted prompt:

```text
PRIMARY EDIT TARGET IS IMAGE 3, THE COLOUR-KEYED POSE GUIDE. Repaint that mannequin into the captain, keeping its entire skeleton, head position, hands, knees and boots locked at their original pixel locations. Image 1 and Image 2 supply paint, face and costume ONLY, not composition or pose. Image 4 supplies ONLY rendering continuity, never pose. This is a new, distinct gait phase, not a variation on Image 4. The guide's red and blue legs must both become VIOLET trousers and BROWN boots. The guide's orange and cyan arms must both become CREAM sleeves and skin hands. Keep the guide's canvas transparent; no background gradient or halo from the earlier painted references.
Use case: identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain jog-cycle frame (11 of 12) for Stapledon's Voyage. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, limb positions, body lean, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. A natural, light, believable jog: planted foot flat on the ground where the guide's touches the ground line, the recovering leg's heel kicking up behind, arms swinging opposite to the legs with elbows bent about 90 degrees, a slight forward lean. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels (it swings and trails with the stride), broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: full side view moving to screen-RIGHT, captain's right side toward viewer. Calm non-specific face. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, each boot exactly where the guide's boot is. At least 16 px fully transparent on every edge. No floor, shadow, scenery, text, halo or watermark.
Pose for frame 10: Flight wide split: right leg trails toward airborne right boot (180,1290), left knee leads at (800,900), left boot airborne near (720,1175). Right hand near (675,850), left hand forward/up at (780,525). Crown (435,215).
Image 4, when provided, is only the previous frame's character-rendering reference; the current Image 3 guide overrides its pose. CRITICAL: match Image 3's smaller figure framing and exact boot/head coordinates. Do not enlarge the figure to fill the canvas as Image 2 does. Exclude the entire dark/gold halo/background of Image 2 and Image 4: the canvas outside the painted person must be empty transparent alpha=0, including between limbs. No atmospheric paint outside the silhouette.
Arms switch: near RIGHT arm swings back/down with hand x675,y850. Far LEFT arm swings forward/up with hand x780,y525. Left knee leads. Right heel kicks higher/back toward x180,y1290, bending knee more. NO background or halo.
```

## jog_profile_11.png

Output: `out/jog_profile_11.png`.

Inputs (attachment order): Image 1: `refs/avatar_captain_proposal_a.png`; Image 2: `refs/accepted_v1_profile.png`; Image 3: `guides/jog_profile_11.png`; Image 4: `out/jog_profile_10.png`.

Candidates: candidate 1 (sole candidate). Selection/review: Kept for a unique transition toward left contact and opposite arm swing. Right recovery knee remains insufficiently bent, left boot a little too low, head too high; halo persists.

Native file QA: 1024 × 1536, RGBA8; alpha range 0–254; 1,149,286 alpha-zero pixels; **16 nonzero-alpha pixels in the 16-pixel border**.

SHA-256: `8528dfabf926d2c081d9deb783c0e91c75f00098368d5960827412cd031f984b`.

Generated source: `/Users/voightkampff/.codex/generated_images/01a15ea2-a119-7993-8620-babc75a736d0/exec-0836f09b-de69-49a3-aa5d-7dd37e127d1b.png`.

Exact submitted prompt:

```text
PRIMARY EDIT TARGET IS IMAGE 3, THE COLOUR-KEYED POSE GUIDE. Repaint that mannequin into the captain, keeping its entire skeleton, head position, hands, knees and boots locked at their original pixel locations. Image 1 and Image 2 supply paint, face and costume ONLY, not composition or pose. Image 4 supplies ONLY rendering continuity, never pose. This is a new, distinct gait phase, not a variation on Image 4. The guide's red and blue legs must both become VIOLET trousers and BROWN boots. The guide's orange and cyan arms must both become CREAM sleeves and skin hands. Keep the guide's canvas transparent; no background gradient or halo from the earlier painted references.
Use case: identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain jog-cycle frame (12 of 12) for Stapledon's Voyage. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, limb positions, body lean, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. A natural, light, believable jog: planted foot flat on the ground where the guide's touches the ground line, the recovering leg's heel kicking up behind, arms swinging opposite to the legs with elbows bent about 90 degrees, a slight forward lean. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels (it swings and trails with the stride), broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: full side view moving to screen-RIGHT, captain's right side toward viewer. Calm non-specific face. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, each boot exactly where the guide's boot is. At least 16 px fully transparent on every edge. No floor, shadow, scenery, text, halo or watermark.
Pose for frame 11: Flight approaching left contact: right heel kicked behind at (220,1265), left knee forward at (790,920) and left boot still airborne at (780,1225). Right arm back/down with hand (600,885); left arm forward/up (790,480). Crown (435,205).
Image 4, when provided, is only the previous frame's character-rendering reference; the current Image 3 guide overrides its pose. CRITICAL: match Image 3's smaller figure framing and exact boot/head coordinates. Do not enlarge the figure to fill the canvas as Image 2 does. Exclude the entire dark/gold halo/background of Image 2 and Image 4: the canvas outside the painted person must be empty transparent alpha=0, including between limbs. No atmospheric paint outside the silhouette.
Specific pose change: bend recovering RIGHT knee so right shin is almost horizontal behind and heel kicks up at x220,y1265. Extend leading LEFT shin down to airborne left boot x780,y1225. Near right hand x600,y885, far left hand up x790,y480. This is flight, no planted foot yet. Head crown y205.
```

## jog_back_00.png

Output: `out/jog_back_00.png`.

Inputs (attachment order): Image 1: `refs/avatar_captain_proposal_a.png`; Image 2: `refs/accepted_v1_back.png`; Image 3: `guides/jog_back_00.png`.

Candidates: candidate 1 (sole candidate). Selection/review: Kept for correct direct rear facing, left-arm-forward/right-arm-back swing, right recovering sole and accepted back rendering. Head position close to guide. Both boots too low, recovering heel insufficiently raised; halo remains.

Native file QA: 1024 × 1536, RGBA8; alpha range 0–254; 1,253,896 alpha-zero pixels; **7 nonzero-alpha pixels in the 16-pixel border**.

SHA-256: `e17609255c970af0db988d6064481d833e60c2c29dfb6b081a63dd58edba4137`.

Generated source: `/Users/voightkampff/.codex/generated_images/01a15ea2-a119-7993-8620-babc75a736d0/exec-81d4f62b-f3c1-4163-a557-d9b8726df3a2.png`.

Exact submitted prompt:

```text
PRIMARY EDIT TARGET IS IMAGE 3, THE COLOUR-KEYED POSE GUIDE. Repaint that mannequin into the captain, keeping its entire skeleton, head position, hands, knees and boots locked at their original pixel locations. Image 1 and Image 2 supply paint, face and costume ONLY, not composition or pose. Image 4 supplies ONLY rendering continuity, never pose. This is a new, distinct gait phase, not a variation on Image 4. The guide's red and blue legs must both become VIOLET trousers and BROWN boots. The guide's orange and cyan arms must both become CREAM sleeves and skin hands. Keep the guide's canvas transparent; no background gradient or halo from the earlier painted references.
Use case: identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain jog-cycle frame (1 of 12) for Stapledon's Voyage. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, limb positions, body lean, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. A natural, light, believable jog: planted foot flat on the ground where the guide's touches the ground line, the recovering leg's heel kicking up behind, arms swinging opposite to the legs with elbows bent about 90 degrees, a slight forward lean. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels (it swings and trails with the stride), broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: directly from BEHIND, moving away up-screen; back of head, shoulders and coat, no face. Calm non-specific face. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, each boot exactly where the guide's boot is. At least 16 px fully transparent on every edge. No floor, shadow, scenery, text, halo or watermark.
Pose for back frame 00: Direct rear view. Left foot (screen left) near (440,1275), extending forward away; right recovering heel (screen right) near (585,1270), visibly raised toward viewer. Left arm bends upward with hand near (390,395); right arm back/down toward (715,780). Head crown (505,255).
Image 4, when provided, is only the previous frame's character-rendering reference; the current Image 3 guide overrides its pose. CRITICAL: match Image 3's smaller figure framing and exact boot/head coordinates. Do not enlarge the figure to fill the canvas as Image 2 does. Exclude the entire dark/gold halo/background of Image 2 and Image 4: the canvas outside the painted person must be empty transparent alpha=0, including between limbs. No atmospheric paint outside the silhouette.
LEFT arm is raised beside left side of head; RIGHT arm bends down/back. Follow guide: do not use the reversed arm swing from accepted Image 2. Hair crown y255, same figure size as guide. No halo, no vignette; isolated transparent sprite.
```

## jog_back_01.png

Output: `out/jog_back_01.png`.

Inputs (attachment order): Image 1: `refs/avatar_captain_proposal_a.png`; Image 2: `refs/accepted_v1_back.png`; Image 3: `guides/jog_back_01.png`; Image 4: `out/jog_back_00.png`.

Candidates: candidate 1 (sole candidate). Selection/review: Kept for stronger right heel recovery and continuity in rear costume/paint. Compression/framing not achieved: head too high, left foot and right heel both too low relative to guide. Halo persists.

Native file QA: 1024 × 1536, RGBA8; alpha range 0–254; 1,182,189 alpha-zero pixels; **50 nonzero-alpha pixels in the 16-pixel border**.

SHA-256: `ffd3967c3f7210779bd761b1b1f634ec7800f16bd443dae7c2e32645ddac3837`.

Generated source: `/Users/voightkampff/.codex/generated_images/01a15ea2-a119-7993-8620-babc75a736d0/exec-2e835438-c78c-42bd-9ff1-a6a67bae45e2.png`.

Exact submitted prompt:

```text
PRIMARY EDIT TARGET IS IMAGE 3, THE COLOUR-KEYED POSE GUIDE. Repaint that mannequin into the captain, keeping its entire skeleton, head position, hands, knees and boots locked at their original pixel locations. Image 1 and Image 2 supply paint, face and costume ONLY, not composition or pose. Image 4 supplies ONLY rendering continuity, never pose. This is a new, distinct gait phase, not a variation on Image 4. The guide's red and blue legs must both become VIOLET trousers and BROWN boots. The guide's orange and cyan arms must both become CREAM sleeves and skin hands. Keep the guide's canvas transparent; no background gradient or halo from the earlier painted references.
Use case: identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain jog-cycle frame (2 of 12) for Stapledon's Voyage. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, limb positions, body lean, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. A natural, light, believable jog: planted foot flat on the ground where the guide's touches the ground line, the recovering leg's heel kicking up behind, arms swinging opposite to the legs with elbows bent about 90 degrees, a slight forward lean. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels (it swings and trails with the stride), broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: directly from BEHIND, moving away up-screen; back of head, shoulders and coat, no face. Calm non-specific face. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, each boot exactly where the guide's boot is. At least 16 px fully transparent on every edge. No floor, shadow, scenery, text, halo or watermark.
Pose for back frame 01: Direct rear view stance compression: left boot at screen left near (440,1355), right heel raised near (585,1230), knees slightly flexed. Left hand high near (380,435), right elbow/hand low near (710,780). Head crown (505,275).
Image 4, when provided, is only the previous frame's character-rendering reference; the current Image 3 guide overrides its pose. CRITICAL: match Image 3's smaller figure framing and exact boot/head coordinates. Do not enlarge the figure to fill the canvas as Image 2 does. Exclude the entire dark/gold halo/background of Image 2 and Image 4: the canvas outside the painted person must be empty transparent alpha=0, including between limbs. No atmospheric paint outside the silhouette.
Lower the body into compression and flex right knee MORE than previous frame, raising recovering right boot toward y1230 and left boot near y1355. Arms maintain left forward/up and right back/down. Exact head crown y275. Remove every halo/background pixel; transparent outside silhouette.
```

## jog_back_02.png

Output: `out/jog_back_02.png`.

Inputs (attachment order): Image 1: `refs/avatar_captain_proposal_a.png`; Image 2: `refs/accepted_v1_back.png`; Image 3: `guides/jog_back_02.png`; Image 4: `out/jog_back_01.png`.

Candidates: candidate 1 (sole candidate). Selection/review: Kept for rear rendering and left-support/right-recovery arrangement. Failed guide heights: right heel remains too low and left hand too high; head framing drifts upward substantially. Halo persists.

Native file QA: 1024 × 1536, RGBA8; alpha range 0–254; 1,160,451 alpha-zero pixels; **9 nonzero-alpha pixels in the 16-pixel border**.

SHA-256: `d97b822b896b4087c77b3152914ee5c8dcb30eff5c6b185920b3fd942c717a4d`.

Generated source: `/Users/voightkampff/.codex/generated_images/01a15ea2-a119-7993-8620-babc75a736d0/exec-b5f0d13b-112e-48c0-a943-b203e7bf864c.png`.

Exact submitted prompt:

```text
PRIMARY EDIT TARGET IS IMAGE 3, THE COLOUR-KEYED POSE GUIDE. Repaint that mannequin into the captain, keeping its entire skeleton, head position, hands, knees and boots locked at their original pixel locations. Image 1 and Image 2 supply paint, face and costume ONLY, not composition or pose. Image 4 supplies ONLY rendering continuity, never pose. This is a new, distinct gait phase, not a variation on Image 4. The guide's red and blue legs must both become VIOLET trousers and BROWN boots. The guide's orange and cyan arms must both become CREAM sleeves and skin hands. Keep the guide's canvas transparent; no background gradient or halo from the earlier painted references.
Use case: identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain jog-cycle frame (3 of 12) for Stapledon's Voyage. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, limb positions, body lean, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. A natural, light, believable jog: planted foot flat on the ground where the guide's touches the ground line, the recovering leg's heel kicking up behind, arms swinging opposite to the legs with elbows bent about 90 degrees, a slight forward lean. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels (it swings and trails with the stride), broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: directly from BEHIND, moving away up-screen; back of head, shoulders and coat, no face. Calm non-specific face. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, each boot exactly where the guide's boot is. At least 16 px fully transparent on every edge. No floor, shadow, scenery, text, halo or watermark.
Pose for back frame 02: Direct rear view late left stance: left boot extends down at screen left near (440,1435), right lower leg folded up with boot near (585,1135). Left hand near (360,500), right elbow/back arm near (705,750). Head crown (510,280).
Image 4, when provided, is only the previous frame's character-rendering reference; the current Image 3 guide overrides its pose. CRITICAL: match Image 3's smaller figure framing and exact boot/head coordinates. Do not enlarge the figure to fill the canvas as Image 2 does. Exclude the entire dark/gold halo/background of Image 2 and Image 4: the canvas outside the painted person must be empty transparent alpha=0, including between limbs. No atmospheric paint outside the silhouette.
RIGHT knee folds strongly and right boot sole must be raised near y1135, well above left ankle. LEFT boot down near y1435. Lower head crown to y280 and match guide shoulder/waist heights. Left hand lowers to y500. Transparent cutout only, no halo.
```

## jog_back_03.png

Output: `out/jog_back_03.png`.

Inputs (attachment order): Image 1: `refs/avatar_captain_proposal_a.png`; Image 2: `refs/accepted_v1_back.png`; Image 3: `guides/jog_back_03.png`.

Candidates: candidate 1 (sole candidate). Selection/review: Kept for near-symmetrical bent passing arms and raised right sole, closer to guide flight phase. Previous attachment omitted to break arm/pose anchoring. Head too high and left boot somewhat high; halo persists.

Native file QA: 1024 × 1536, RGBA8; alpha range 0–254; 1,222,362 alpha-zero pixels; **2 nonzero-alpha pixels in the 16-pixel border**.

SHA-256: `58a240527a8718108e8a6caa0711e5b4b93ef7dd94bf7aa4cd6d4d13877eac20`.

Generated source: `/Users/voightkampff/.codex/generated_images/01a15ea2-a119-7993-8620-babc75a736d0/exec-147679f1-27b2-4ba7-80c3-8b5f6119f217.png`.

Exact submitted prompt:

```text
REPAINT IMAGE 3'S EXACT POSE. Both elbows are bent near the same passing height; neither hand is raised beside head. Left leg trails straight down; RIGHT heel is kicked up high with sole visible at y1130, not y1300. Scale entire figure to the guide's framing, head crown y270.
PRIMARY EDIT TARGET IS IMAGE 3, THE COLOUR-KEYED POSE GUIDE. Repaint that mannequin into the captain, keeping its entire skeleton, head position, hands, knees and boots locked at their original pixel locations. Image 1 and Image 2 supply paint, face and costume ONLY, not composition or pose. Image 4 supplies ONLY rendering continuity, never pose. This is a new, distinct gait phase, not a variation on Image 4. The guide's red and blue legs must both become VIOLET trousers and BROWN boots. The guide's orange and cyan arms must both become CREAM sleeves and skin hands. Keep the guide's canvas transparent; no background gradient or halo from the earlier painted references.
Use case: identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain jog-cycle frame (4 of 12) for Stapledon's Voyage. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, limb positions, body lean, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. A natural, light, believable jog: planted foot flat on the ground where the guide's touches the ground line, the recovering leg's heel kicking up behind, arms swinging opposite to the legs with elbows bent about 90 degrees, a slight forward lean. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels (it swings and trails with the stride), broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: directly from BEHIND, moving away up-screen; back of head, shoulders and coat, no face. Calm non-specific face. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, each boot exactly where the guide's boot is. At least 16 px fully transparent on every edge. No floor, shadow, scenery, text, halo or watermark.
Pose for back frame 03: Direct rear view flight: left leg trails down with boot near (440,1495); right recovery boot raised near (585,1130). Both elbows bent and near symmetrical passing swing, arms at waist/chest height, no straight dangling arm. Crown (510,270). Match guide framing while keeping 16px edge margin.
Image 4, when provided, is only the previous frame's character-rendering reference; the current Image 3 guide overrides its pose. CRITICAL: match Image 3's smaller figure framing and exact boot/head coordinates. Do not enlarge the figure to fill the canvas as Image 2 does. Exclude the entire dark/gold halo/background of Image 2 and Image 4: the canvas outside the painted person must be empty transparent alpha=0, including between limbs. No atmospheric paint outside the silhouette.
```

## jog_back_04.png

Output: `out/jog_back_04.png`.

Inputs (attachment order): Image 1: `refs/avatar_captain_proposal_a.png`; Image 2: `refs/accepted_v1_back.png`; Image 3: `guides/jog_back_04.png`; Image 4: `out/jog_back_03.png`.

Candidates: candidate 1 (sole candidate). Selection/review: Kept for correct right-forward/left-back arm transition and raised right heel. Left elbow too straight, head too high, heel a little too low; halo persists.

Native file QA: 1024 × 1536, RGBA8; alpha range 0–254; 1,208,567 alpha-zero pixels; **1 nonzero-alpha pixels in the 16-pixel border**.

SHA-256: `a21a4d7066e8633a5cf885254585cddfd438a90dead80414a5ac90a45a4401db`.

Generated source: `/Users/voightkampff/.codex/generated_images/01a15ea2-a119-7993-8620-babc75a736d0/exec-0cab1e23-3701-47c7-a951-686452376e14.png`.

Exact submitted prompt:

```text
PRIMARY EDIT TARGET IS IMAGE 3, THE COLOUR-KEYED POSE GUIDE. Repaint that mannequin into the captain, keeping its entire skeleton, head position, hands, knees and boots locked at their original pixel locations. Image 1 and Image 2 supply paint, face and costume ONLY, not composition or pose. Image 4 supplies ONLY rendering continuity, never pose. This is a new, distinct gait phase, not a variation on Image 4. The guide's red and blue legs must both become VIOLET trousers and BROWN boots. The guide's orange and cyan arms must both become CREAM sleeves and skin hands. Keep the guide's canvas transparent; no background gradient or halo from the earlier painted references.
Use case: identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain jog-cycle frame (5 of 12) for Stapledon's Voyage. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, limb positions, body lean, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. A natural, light, believable jog: planted foot flat on the ground where the guide's touches the ground line, the recovering leg's heel kicking up behind, arms swinging opposite to the legs with elbows bent about 90 degrees, a slight forward lean. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels (it swings and trails with the stride), broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: directly from BEHIND, moving away up-screen; back of head, shoulders and coat, no face. Calm non-specific face. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, each boot exactly where the guide's boot is. At least 16 px fully transparent on every edge. No floor, shadow, scenery, text, halo or watermark.
Pose for back frame 04: Direct rear view flight: left leg trailing down, boot near (440,1415); right boot folded up toward (585,1125). Right arm swings forward/up with hand near (660,470), left arm back/down near (320,725). Crown (515,250).
Image 4, when provided, is only the previous frame's character-rendering reference; the current Image 3 guide overrides its pose. CRITICAL: match Image 3's smaller figure framing and exact boot/head coordinates. Do not enlarge the figure to fill the canvas as Image 2 does. Exclude the entire dark/gold halo/background of Image 2 and Image 4: the canvas outside the painted person must be empty transparent alpha=0, including between limbs. No atmospheric paint outside the silhouette.
RIGHT arm swings forward/up, right hand y470; LEFT arm recedes down/back, left hand/elbow y725. Keep right heel kicked high at y1125, left trailing boot near y1415. Crown y250. Empty alpha=0 outside person, no halo.
```

## jog_back_05.png

Output: `out/jog_back_05.png`.

Inputs (attachment order): Image 1: `refs/avatar_captain_proposal_a.png`; Image 2: `refs/accepted_v1_back.png`; Image 3: `guides/jog_back_05.png`; Image 4: `out/jog_back_04.png`.

Candidates: candidate 1 (sole candidate). Selection/review: Kept for distinct higher right fist and rear costume continuity. Left elbow still too straight, left boot too low, head too high and halo remains; guide pose only approximate.

Native file QA: 1024 × 1536, RGBA8; alpha range 0–254; 1,201,070 alpha-zero pixels; **0 nonzero-alpha pixels in the 16-pixel border**.

SHA-256: `d027b7c2883052a37b98d20c3f3af4da90cafcef5044504b3bd82b275cb925d9`.

Generated source: `/Users/voightkampff/.codex/generated_images/01a15ea2-a119-7993-8620-babc75a736d0/exec-5abbb91e-5e61-4c0c-80c4-64b78cd2799f.png`.

Exact submitted prompt:

```text
PRIMARY EDIT TARGET IS IMAGE 3, THE COLOUR-KEYED POSE GUIDE. Repaint that mannequin into the captain, keeping its entire skeleton, head position, hands, knees and boots locked at their original pixel locations. Image 1 and Image 2 supply paint, face and costume ONLY, not composition or pose. Image 4 supplies ONLY rendering continuity, never pose. This is a new, distinct gait phase, not a variation on Image 4. The guide's red and blue legs must both become VIOLET trousers and BROWN boots. The guide's orange and cyan arms must both become CREAM sleeves and skin hands. Keep the guide's canvas transparent; no background gradient or halo from the earlier painted references.
Use case: identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain jog-cycle frame (6 of 12) for Stapledon's Voyage. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, limb positions, body lean, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. A natural, light, believable jog: planted foot flat on the ground where the guide's touches the ground line, the recovering leg's heel kicking up behind, arms swinging opposite to the legs with elbows bent about 90 degrees, a slight forward lean. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels (it swings and trails with the stride), broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: directly from BEHIND, moving away up-screen; back of head, shoulders and coat, no face. Calm non-specific face. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, each boot exactly where the guide's boot is. At least 16 px fully transparent on every edge. No floor, shadow, scenery, text, halo or watermark.
Pose for back frame 05: Direct rear view flight approaching right contact: left boot still low/back near (440,1350), right folded recovery boot near (585,1140). Right hand raised beside head near (640,405), left arm down/back near (315,760). Crown (520,245).
Image 4, when provided, is only the previous frame's character-rendering reference; the current Image 3 guide overrides its pose. CRITICAL: match Image 3's smaller figure framing and exact boot/head coordinates. Do not enlarge the figure to fill the canvas as Image 2 does. Exclude the entire dark/gold halo/background of Image 2 and Image 4: the canvas outside the painted person must be empty transparent alpha=0, including between limbs. No atmospheric paint outside the silhouette.
Right fist rises beside head to y405, left arm still back/down but elbow BENT about 90 degrees, not dangling straight. Right boot remains high at y1140, left boot rises to y1350. Guide crown y245. Clean truly transparent canvas, no halo.
```

## jog_back_06.png

Output: `out/jog_back_06.png`.

Inputs (attachment order): Image 1: `refs/avatar_captain_proposal_a.png`; Image 2: `refs/accepted_v1_back.png`; Image 3: `guides/jog_back_06.png`.

Candidates: candidate 1 (sole candidate). Selection/review: Kept for correct switch to left recovery/right reach and raised right fist, with accepted back rendering. Previous attachment omitted at half-cycle switch. Right boot too low, left elbow too straight and head somewhat high; halo persists.

Native file QA: 1024 × 1536, RGBA8; alpha range 0–254; 1,218,363 alpha-zero pixels; **14 nonzero-alpha pixels in the 16-pixel border**.

SHA-256: `cf0015f7a47b459f13103bdc787aa6d31f1abfd50e2f4102bd63d86f91e04393`.

Generated source: `/Users/voightkampff/.codex/generated_images/01a15ea2-a119-7993-8620-babc75a736d0/exec-9fb6e8b1-3f40-43c5-902c-63f2d332a2ab.png`.

Exact submitted prompt:

```text
OPPOSITE CONTACT HALF-CYCLE: LEFT heel is now kicked up behind, sole visible at screen LEFT. RIGHT leg now reaches forward away/down, screen RIGHT. RIGHT fist stays up beside right side of head, LEFT arm bends back/down. Paint image 3's skeleton precisely.
PRIMARY EDIT TARGET IS IMAGE 3, THE COLOUR-KEYED POSE GUIDE. Repaint that mannequin into the captain, keeping its entire skeleton, head position, hands, knees and boots locked at their original pixel locations. Image 1 and Image 2 supply paint, face and costume ONLY, not composition or pose. Image 4 supplies ONLY rendering continuity, never pose. This is a new, distinct gait phase, not a variation on Image 4. The guide's red and blue legs must both become VIOLET trousers and BROWN boots. The guide's orange and cyan arms must both become CREAM sleeves and skin hands. Keep the guide's canvas transparent; no background gradient or halo from the earlier painted references.
Use case: identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain jog-cycle frame (7 of 12) for Stapledon's Voyage. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, limb positions, body lean, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. A natural, light, believable jog: planted foot flat on the ground where the guide's touches the ground line, the recovering leg's heel kicking up behind, arms swinging opposite to the legs with elbows bent about 90 degrees, a slight forward lean. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels (it swings and trails with the stride), broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: directly from BEHIND, moving away up-screen; back of head, shoulders and coat, no face. Calm non-specific face. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, each boot exactly where the guide's boot is. At least 16 px fully transparent on every edge. No floor, shadow, scenery, text, halo or watermark.
Pose for back frame 06: Direct rear view, opposite contact half-cycle: right foot reaches forward away, toe/boot near (585,1270); left recovering heel kicks up toward viewer near (440,1270). Right hand high beside head near (635,395), left arm back/down near (310,780). Crown (520,255).
Image 4, when provided, is only the previous frame's character-rendering reference; the current Image 3 guide overrides its pose. CRITICAL: match Image 3's smaller figure framing and exact boot/head coordinates. Do not enlarge the figure to fill the canvas as Image 2 does. Exclude the entire dark/gold halo/background of Image 2 and Image 4: the canvas outside the painted person must be empty transparent alpha=0, including between limbs. No atmospheric paint outside the silhouette.
Head crown y255, right fist x635,y395; both boots around y1270, left sole toward viewer. No halo or gradient; transparent sprite.
```

## jog_back_07.png

Output: `out/jog_back_07.png`.

Inputs (attachment order): Image 1: `refs/avatar_captain_proposal_a.png`; Image 2: `refs/accepted_v1_back.png`; Image 3: `guides/jog_back_07.png`; Image 4: `out/jog_back_06.png`.

Candidates: candidate 1 (sole candidate). Selection/review: Kept for left recovering heel and accepted rear rendering. Failed guide compression/framing: head too high, right foot too low, right fist too high and left elbow insufficiently bent. Halo remains.

Native file QA: 1024 × 1536, RGBA8; alpha range 0–254; 1,192,998 alpha-zero pixels; **0 nonzero-alpha pixels in the 16-pixel border**.

SHA-256: `64262a702dbaf11ddf5981493a8d1bc9750c93ba05bc86a4ff3355888fe21d23`.

Generated source: `/Users/voightkampff/.codex/generated_images/01a15ea2-a119-7993-8620-babc75a736d0/exec-4b623316-063c-4265-9c80-53414260278e.png`.

Exact submitted prompt:

```text
PRIMARY EDIT TARGET IS IMAGE 3, THE COLOUR-KEYED POSE GUIDE. Repaint that mannequin into the captain, keeping its entire skeleton, head position, hands, knees and boots locked at their original pixel locations. Image 1 and Image 2 supply paint, face and costume ONLY, not composition or pose. Image 4 supplies ONLY rendering continuity, never pose. This is a new, distinct gait phase, not a variation on Image 4. The guide's red and blue legs must both become VIOLET trousers and BROWN boots. The guide's orange and cyan arms must both become CREAM sleeves and skin hands. Keep the guide's canvas transparent; no background gradient or halo from the earlier painted references.
Use case: identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain jog-cycle frame (8 of 12) for Stapledon's Voyage. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, limb positions, body lean, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. A natural, light, believable jog: planted foot flat on the ground where the guide's touches the ground line, the recovering leg's heel kicking up behind, arms swinging opposite to the legs with elbows bent about 90 degrees, a slight forward lean. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels (it swings and trails with the stride), broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: directly from BEHIND, moving away up-screen; back of head, shoulders and coat, no face. Calm non-specific face. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, each boot exactly where the guide's boot is. At least 16 px fully transparent on every edge. No floor, shadow, scenery, text, halo or watermark.
Pose for back frame 07: Direct rear view right stance compression: right boot screen right near (585,1355), left heel raised screen left near (440,1230). Right hand high near (640,435), left arm low/back near (315,780). Crown (520,275).
Image 4, when provided, is only the previous frame's character-rendering reference; the current Image 3 guide overrides its pose. CRITICAL: match Image 3's smaller figure framing and exact boot/head coordinates. Do not enlarge the figure to fill the canvas as Image 2 does. Exclude the entire dark/gold halo/background of Image 2 and Image 4: the canvas outside the painted person must be empty transparent alpha=0, including between limbs. No atmospheric paint outside the silhouette.
Compress right stance and raise left recovering boot toward y1230; right boot near y1355, head crown y275. Right hand at y435, left arm back with elbow bent, not straight down. Follow guide's entire framing. Transparent cutout with no halo.
```

## jog_back_08.png

Output: `out/jog_back_08.png`.

Inputs (attachment order): Image 1: `refs/avatar_captain_proposal_a.png`; Image 2: `refs/accepted_v1_back.png`; Image 3: `guides/jog_back_08.png`; Image 4: `out/jog_back_07.png`.

Candidates: candidate 1 (sole candidate). Selection/review: Kept for right-leg extension and left sole recovery in accepted rendering. Left heel still somewhat low, right hand too high, left elbow too straight and head much too high; halo persists.

Native file QA: 1024 × 1536, RGBA8; alpha range 0–254; 1,190,467 alpha-zero pixels; **8 nonzero-alpha pixels in the 16-pixel border**.

SHA-256: `2bf898144c2ffbfe7ac75ff4a9c36ecd08ceba24117751987426d812fe4fdd8d`.

Generated source: `/Users/voightkampff/.codex/generated_images/01a15ea2-a119-7993-8620-babc75a736d0/exec-990f5e30-7e4a-40e6-adf2-fd3e8981ece0.png`.

Exact submitted prompt:

```text
PRIMARY EDIT TARGET IS IMAGE 3, THE COLOUR-KEYED POSE GUIDE. Repaint that mannequin into the captain, keeping its entire skeleton, head position, hands, knees and boots locked at their original pixel locations. Image 1 and Image 2 supply paint, face and costume ONLY, not composition or pose. Image 4 supplies ONLY rendering continuity, never pose. This is a new, distinct gait phase, not a variation on Image 4. The guide's red and blue legs must both become VIOLET trousers and BROWN boots. The guide's orange and cyan arms must both become CREAM sleeves and skin hands. Keep the guide's canvas transparent; no background gradient or halo from the earlier painted references.
Use case: identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain jog-cycle frame (9 of 12) for Stapledon's Voyage. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, limb positions, body lean, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. A natural, light, believable jog: planted foot flat on the ground where the guide's touches the ground line, the recovering leg's heel kicking up behind, arms swinging opposite to the legs with elbows bent about 90 degrees, a slight forward lean. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels (it swings and trails with the stride), broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: directly from BEHIND, moving away up-screen; back of head, shoulders and coat, no face. Calm non-specific face. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, each boot exactly where the guide's boot is. At least 16 px fully transparent on every edge. No floor, shadow, scenery, text, halo or watermark.
Pose for back frame 08: Direct rear view late right stance: right boot extends down screen right near (585,1435), left boot folded up screen left near (440,1135). Right hand near (660,500), left arm back/down near (320,755). Crown (515,280).
Image 4, when provided, is only the previous frame's character-rendering reference; the current Image 3 guide overrides its pose. CRITICAL: match Image 3's smaller figure framing and exact boot/head coordinates. Do not enlarge the figure to fill the canvas as Image 2 does. Exclude the entire dark/gold halo/background of Image 2 and Image 4: the canvas outside the painted person must be empty transparent alpha=0, including between limbs. No atmospheric paint outside the silhouette.
Fold LEFT knee strongly, left heel sole raised to y1135. Extend RIGHT leg down to right boot y1435. Lower RIGHT hand to y500 as guide, LEFT elbow bent back/down near y755. Head crown y280. Repaint guide geometry, no halo.
```

## jog_back_09.png

Output: `out/jog_back_09.png`.

Inputs (attachment order): Image 1: `refs/avatar_captain_proposal_a.png`; Image 2: `refs/accepted_v1_back.png`; Image 3: `guides/jog_back_09.png`.

Candidates: candidate 1 (sole candidate). Selection/review: Kept for near-symmetrical bent passing arms, left raised sole and right trailing leg; one of the closer back poses. Previous attachment omitted to release arm anchoring. Head and heel/boot positions still approximate and halo remains.

Native file QA: 1024 × 1536, RGBA8; alpha range 0–254; 1,261,090 alpha-zero pixels; **0 nonzero-alpha pixels in the 16-pixel border**.

SHA-256: `8f497f384141ceaabd5516ff784f6b60b02728d544caadb30c7343f380f38d5b`.

Generated source: `/Users/voightkampff/.codex/generated_images/01a15ea2-a119-7993-8620-babc75a736d0/exec-6f828ee5-d8c6-4246-a836-a3c243400663.png`.

Exact submitted prompt:

```text
PAINT IMAGE 3'S PASSING POSE: BOTH elbows bent near same height, neither hand raised next to head. LEFT heel high behind, sole toward viewer near y1130. RIGHT leg trails down to boot y1495. Head crown y270, matching guide size.
PRIMARY EDIT TARGET IS IMAGE 3, THE COLOUR-KEYED POSE GUIDE. Repaint that mannequin into the captain, keeping its entire skeleton, head position, hands, knees and boots locked at their original pixel locations. Image 1 and Image 2 supply paint, face and costume ONLY, not composition or pose. Image 4 supplies ONLY rendering continuity, never pose. This is a new, distinct gait phase, not a variation on Image 4. The guide's red and blue legs must both become VIOLET trousers and BROWN boots. The guide's orange and cyan arms must both become CREAM sleeves and skin hands. Keep the guide's canvas transparent; no background gradient or halo from the earlier painted references.
Use case: identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain jog-cycle frame (10 of 12) for Stapledon's Voyage. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, limb positions, body lean, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. A natural, light, believable jog: planted foot flat on the ground where the guide's touches the ground line, the recovering leg's heel kicking up behind, arms swinging opposite to the legs with elbows bent about 90 degrees, a slight forward lean. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels (it swings and trails with the stride), broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: directly from BEHIND, moving away up-screen; back of head, shoulders and coat, no face. Calm non-specific face. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, each boot exactly where the guide's boot is. At least 16 px fully transparent on every edge. No floor, shadow, scenery, text, halo or watermark.
Pose for back frame 09: Direct rear view flight: right leg trails down with right boot near (585,1495); left recovery boot raised near (440,1130). Elbows bent in a near symmetrical passing arm swing at waist/chest level. Crown (510,270). Match guide framing while keeping 16px transparent edge margin.
Image 4, when provided, is only the previous frame's character-rendering reference; the current Image 3 guide overrides its pose. CRITICAL: match Image 3's smaller figure framing and exact boot/head coordinates. Do not enlarge the figure to fill the canvas as Image 2 does. Exclude the entire dark/gold halo/background of Image 2 and Image 4: the canvas outside the painted person must be empty transparent alpha=0, including between limbs. No atmospheric paint outside the silhouette.
Flight phase: no grounded boot, no floor, no shadow. Truly transparent around exact silhouette, no atmospheric wash or glow.
```

## jog_back_10.png

Output: `out/jog_back_10.png`.

Inputs (attachment order): Image 1: `refs/avatar_captain_proposal_a.png`; Image 2: `refs/accepted_v1_back.png`; Image 3: `guides/jog_back_10.png`; Image 4: `out/jog_back_09.png`.

Candidates: candidate 1 (sole candidate). Selection/review: Kept for correct left-forward/right-back arm transition and left heel recovery. Head too high and both boots somewhat too low; guide registration approximate and halo persists.

Native file QA: 1024 × 1536, RGBA8; alpha range 0–254; 1,194,158 alpha-zero pixels; **3 nonzero-alpha pixels in the 16-pixel border**.

SHA-256: `ec8c59396f296109a7eb01a65d16ebaf6b88fdc0cf82acf95cba99207fc56775`.

Generated source: `/Users/voightkampff/.codex/generated_images/01a15ea2-a119-7993-8620-babc75a736d0/exec-50c2319c-8614-4349-98e8-429555f15ce0.png`.

Exact submitted prompt:

```text
PRIMARY EDIT TARGET IS IMAGE 3, THE COLOUR-KEYED POSE GUIDE. Repaint that mannequin into the captain, keeping its entire skeleton, head position, hands, knees and boots locked at their original pixel locations. Image 1 and Image 2 supply paint, face and costume ONLY, not composition or pose. Image 4 supplies ONLY rendering continuity, never pose. This is a new, distinct gait phase, not a variation on Image 4. The guide's red and blue legs must both become VIOLET trousers and BROWN boots. The guide's orange and cyan arms must both become CREAM sleeves and skin hands. Keep the guide's canvas transparent; no background gradient or halo from the earlier painted references.
Use case: identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain jog-cycle frame (11 of 12) for Stapledon's Voyage. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, limb positions, body lean, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. A natural, light, believable jog: planted foot flat on the ground where the guide's touches the ground line, the recovering leg's heel kicking up behind, arms swinging opposite to the legs with elbows bent about 90 degrees, a slight forward lean. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels (it swings and trails with the stride), broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: directly from BEHIND, moving away up-screen; back of head, shoulders and coat, no face. Calm non-specific face. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, each boot exactly where the guide's boot is. At least 16 px fully transparent on every edge. No floor, shadow, scenery, text, halo or watermark.
Pose for back frame 10: Direct rear view flight: right leg trails down, right boot near (585,1415); left recovering boot raised near (440,1125). Left arm swings forward/up with hand near (360,470), right arm back/down near (710,725). Crown (510,250).
Image 4, when provided, is only the previous frame's character-rendering reference; the current Image 3 guide overrides its pose. CRITICAL: match Image 3's smaller figure framing and exact boot/head coordinates. Do not enlarge the figure to fill the canvas as Image 2 does. Exclude the entire dark/gold halo/background of Image 2 and Image 4: the canvas outside the painted person must be empty transparent alpha=0, including between limbs. No atmospheric paint outside the silhouette.
LEFT hand swings up forward to y470; RIGHT arm swings back/down, elbow bent near y725. LEFT heel stays kicked up at y1125; RIGHT boot rises from previous frame to y1415. Head crown y250. Both boots airborne. No halo.
```

## jog_back_11.png

Output: `out/jog_back_11.png`.

Inputs (attachment order): Image 1: `refs/avatar_captain_proposal_a.png`; Image 2: `refs/accepted_v1_back.png`; Image 3: `guides/jog_back_11.png`; Image 4: `out/jog_back_10.png`.

Candidates: candidate 1 (sole candidate). Selection/review: Kept for left-arm-forward/right-arm-back finish, left raised sole and accepted character rendering. Pose too close to 10: right boot did not rise enough, left fist not high enough and head too high. Halo persists.

Native file QA: 1024 × 1536, RGBA8; alpha range 0–254; 1,195,368 alpha-zero pixels; **5 nonzero-alpha pixels in the 16-pixel border**.

SHA-256: `15d694b63bbf8c612d0f3a358bfacac516f121ecb40e4102e1e18a03212eeeab`.

Generated source: `/Users/voightkampff/.codex/generated_images/01a15ea2-a119-7993-8620-babc75a736d0/exec-051a1d1f-5028-40b2-8429-19f71e2ecc40.png`.

Exact submitted prompt:

```text
PRIMARY EDIT TARGET IS IMAGE 3, THE COLOUR-KEYED POSE GUIDE. Repaint that mannequin into the captain, keeping its entire skeleton, head position, hands, knees and boots locked at their original pixel locations. Image 1 and Image 2 supply paint, face and costume ONLY, not composition or pose. Image 4 supplies ONLY rendering continuity, never pose. This is a new, distinct gait phase, not a variation on Image 4. The guide's red and blue legs must both become VIOLET trousers and BROWN boots. The guide's orange and cyan arms must both become CREAM sleeves and skin hands. Keep the guide's canvas transparent; no background gradient or halo from the earlier painted references.
Use case: identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain jog-cycle frame (12 of 12) for Stapledon's Voyage. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, limb positions, body lean, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. A natural, light, believable jog: planted foot flat on the ground where the guide's touches the ground line, the recovering leg's heel kicking up behind, arms swinging opposite to the legs with elbows bent about 90 degrees, a slight forward lean. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels (it swings and trails with the stride), broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: directly from BEHIND, moving away up-screen; back of head, shoulders and coat, no face. Calm non-specific face. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, each boot exactly where the guide's boot is. At least 16 px fully transparent on every edge. No floor, shadow, scenery, text, halo or watermark.
Pose for back frame 11: Direct rear view flight approaching left contact: right boot low/back near (585,1350), left folded recovery boot near (440,1140). Left hand raised near (380,405), right arm low/back near (710,760). Crown (505,245).
Image 4, when provided, is only the previous frame's character-rendering reference; the current Image 3 guide overrides its pose. CRITICAL: match Image 3's smaller figure framing and exact boot/head coordinates. Do not enlarge the figure to fill the canvas as Image 2 does. Exclude the entire dark/gold halo/background of Image 2 and Image 4: the canvas outside the painted person must be empty transparent alpha=0, including between limbs. No atmospheric paint outside the silhouette.
LEFT fist rises beside left side of head to y405, RIGHT arm bends back/down near y760. RIGHT boot rises to y1350, left heel remains tucked high y1140. Head crown y245; shorten previous oversized framing to precisely match guide. Final flight frame before left contact. Background fully empty transparent, no halo.
```

