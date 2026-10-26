# Captain held poses — CA2 painted frames

Generated with the built-in image generation tool (`image_gen.imagegen`). Exactly 24 generation calls produced exactly 24 retained frames, in HANDOFF.md table order. One candidate per frame; no alternative candidates. Each call requested transparency and attached three references, plus the preceding painted frame in the same pose family when available (at most four total).

All 24 outputs were copied byte-for-byte into `out/` from the tool's saved PNGs. No resizing, compositing, repainting, background removal or other pixel editing was performed. No git, installs or other network tools were used.

## Result and limitations

The requested set is present, but it is not production-ready. Every retained candidate has a visible soft halo outside the person despite `transparent_background: true` and explicit no-halo instructions. Having an RGBA channel is not the same as meeting the zero-alpha-outside-the-figure requirement. Exact guide framing, head position, limb endpoints and boot placement were not reliably preserved. The almost-seated poses and several three-quarter facings are particularly inaccurate; see each frame below. The accepted rendering is a reference, not a claim of exact visual equivalence.

Some guides conflict with the 40 px inset requirement: sitting/seated guides approach or touch the bottom edge, and straight back/front lift guides extend a hand to a side edge. Those conflicts were retained in the supplied prompt requirements and are flagged per frame.

Prompts below contain the handoff's full prompt with pose/facing filled in. From frame 2 onward, extra constraints reinforce the guide and exclude walking foot stagger/halo; from frame 9 onward, a prefix explicitly asks to repaint the guide as a fixed canvas. Image 4, when supplied, is identified as continuity only.

## File verification

Read-only verification checked all 24 expected names, PNG signatures/chunk CRCs, successful IDAT decompression, native 1024 × 1536 dimensions, 8-bit RGBA color type, and presence of alpha-zero pixels. No file was resized or re-encoded. Alpha bounds include the unwanted halo and are not anatomical silhouette bounds. Bounds below are inclusive coordinates.

| Frame | Dimensions / mode | Alpha-zero pixels | Partial-alpha pixels | Opaque pixels | Max alpha | Nonzero-alpha bounds |
|---|---|---:|---:|---:|---:|---|
| use_low_back_00 | 1024 × 1536 RGBA | 1154320 | 418544 | 0 | 254 | 21, 20, 951, 1463 |
| use_low_front_00 | 1024 × 1536 RGBA | 1080408 | 492456 | 0 | 254 | 17, 23, 995, 1475 |
| use_low_back_01 | 1024 × 1536 RGBA | 1081927 | 490937 | 0 | 254 | 0, 23, 995, 1509 |
| use_low_front_01 | 1024 × 1536 RGBA | 1063247 | 509617 | 0 | 254 | 0, 35, 975, 1511 |
| use_mid_back_00 | 1024 × 1536 RGBA | 1159724 | 413140 | 0 | 254 | 35, 21, 995, 1507 |
| use_mid_front_00 | 1024 × 1536 RGBA | 1079602 | 493262 | 0 | 254 | 73, 22, 991, 1502 |
| use_mid_back_01 | 1024 × 1536 RGBA | 1093602 | 479262 | 0 | 254 | 0, 32, 1003, 1472 |
| use_mid_front_01 | 1024 × 1536 RGBA | 1060653 | 512211 | 0 | 254 | 39, 28, 997, 1472 |
| sit_back_00 | 1024 × 1536 RGBA | 1156226 | 416638 | 0 | 254 | 209, 198, 963, 1444 |
| sit_front_00 | 1024 × 1536 RGBA | 1134951 | 437913 | 0 | 254 | 0, 39, 991, 1465 |
| sit_back_01 | 1024 × 1536 RGBA | 1050399 | 522465 | 0 | 254 | 56, 31, 985, 1485 |
| sit_front_01 | 1024 × 1536 RGBA | 1079831 | 493033 | 0 | 254 | 33, 21, 993, 1535 |
| seated_back_00 | 1024 × 1536 RGBA | 1074222 | 498642 | 0 | 254 | 81, 55, 1009, 1471 |
| seated_front_00 | 1024 × 1536 RGBA | 1067691 | 505173 | 0 | 254 | 0, 50, 977, 1498 |
| lift_back_00 | 1024 × 1536 RGBA | 1155538 | 417326 | 0 | 254 | 0, 25, 1007, 1453 |
| lift_back_34_00 | 1024 × 1536 RGBA | 1160137 | 412727 | 0 | 254 | 25, 41, 997, 1509 |
| lift_profile_00 | 1024 × 1536 RGBA | 1216084 | 356780 | 0 | 254 | 0, 88, 997, 1441 |
| lift_front_34_00 | 1024 × 1536 RGBA | 1146425 | 426439 | 0 | 254 | 25, 68, 995, 1472 |
| lift_front_00 | 1024 × 1536 RGBA | 1113965 | 458899 | 0 | 254 | 33, 52, 1003, 1495 |
| look_up_back_00 | 1024 × 1536 RGBA | 1173416 | 399448 | 0 | 254 | 25, 45, 1005, 1454 |
| look_up_back_34_00 | 1024 × 1536 RGBA | 1211194 | 361670 | 0 | 254 | 0, 20, 1009, 1487 |
| look_up_profile_00 | 1024 × 1536 RGBA | 1253091 | 319773 | 0 | 254 | 49, 21, 995, 1455 |
| look_up_front_34_00 | 1024 × 1536 RGBA | 1232171 | 340693 | 0 | 254 | 43, 32, 985, 1463 |
| look_up_front_00 | 1024 × 1536 RGBA | 1173587 | 399277 | 0 | 254 | 41, 29, 1001, 1511 |

## Per-frame generation record

### 1. use_low_back_00

Output: [out/use_low_back_00.png](out/use_low_back_00.png)

Inputs in attachment order:

1. `refs/avatar_captain_proposal_a.png` — picked identity
2. `refs/accepted_idle_back.png` — accepted painted rendering, closest available facing
3. `guides/use_low_back_00.png` — color-keyed pose/framing guide

Candidates: 1 generated; candidate 1 kept. No second candidate generated.

Candidate 1 source: `/Users/voightkampff/.codex/generated_images/01a176da-ae50-7b51-a0b0-bd39ceb1044e/exec-8e259555-b050-4466-8800-381b1b980208.png`

Selection / visual assessment: Only candidate, kept for recognizable captain costume and painted rendering. Deviations: head is higher and feet more staggered than the guide; arms do not match the guide closely; visible soft halo/background violates the clean silhouette requirement.

Prompt (exact submitted text):

```text
Use case:identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain frame for Stapledon's Voyage: reaching forward and slightly down to a waist-high desk (0.95 m), as if about to touch its screen. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, limb positions, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels hanging naturally, broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Calm, unhurried body language. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: seen from behind. Calm non-specific face. Draw ONLY the person: no desk, console, chair, rail or lift. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, the boots exactly where the guide's boots are, on the guide's ground line. The whole figure at least 40 px inside every edge. No floor, shadow, scenery, text, halo or watermark.
```

### 2. use_low_front_00

Output: [out/use_low_front_00.png](out/use_low_front_00.png)

Inputs in attachment order:

1. `refs/avatar_captain_proposal_a.png` — picked identity
2. `refs/accepted_walk_profile.png` — accepted painted rendering, closest available facing
3. `guides/use_low_front_00.png` — color-keyed pose/framing guide
4. `out/use_low_back_00.png` — previous painted frame in this pose family; continuity only

Candidates: 1 generated; candidate 1 kept. No second candidate generated.

Candidate 1 source: `/Users/voightkampff/.codex/generated_images/01a176da-ae50-7b51-a0b0-bd39ceb1044e/exec-d2f82582-23a5-4f30-97c1-a0781e687b50.png`

Selection / visual assessment: Only candidate, retained for front-facing identity, costume and rendering. Head sits substantially above the guide; one hand reaches rather than both guide endpoints matching; visible halo remains.

Prompt (exact submitted text):

```text
Use case:identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain frame for Stapledon's Voyage: reaching forward and slightly down to a waist-high desk (0.95 m), as if about to touch its screen. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, limb positions, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels hanging naturally, broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Calm, unhurried body language. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: facing the viewer. Calm non-specific face. Draw ONLY the person: no desk, console, chair, rail or lift. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, the boots exactly where the guide's boots are, on the guide's ground line. The whole figure at least 40 px inside every edge. No floor, shadow, scenery, text, halo or watermark.
Production constraints: Image 3 is the absolute pose and framing authority. Preserve its head position, silhouette placement, limb endpoints and boot positions exactly. Do not copy walking foot stagger from image 2. Both boots stay flat on the ground. Background must be empty transparent pixels, with NO soft haze, halo, lighting bloom or ambient shadow around the person. Image 4 is the previous painted frame of this pose family, for costume/rendering continuity only; its pose and any background artifacts must not override image 3.
```

### 3. use_low_back_01

Output: [out/use_low_back_01.png](out/use_low_back_01.png)

Inputs in attachment order:

1. `refs/avatar_captain_proposal_a.png` — picked identity
2. `refs/accepted_idle_back.png` — accepted painted rendering, closest available facing
3. `guides/use_low_back_01.png` — color-keyed pose/framing guide
4. `out/use_low_front_00.png` — previous painted frame in this pose family; continuity only

Candidates: 1 generated; candidate 1 kept. No second candidate generated.

Candidate 1 source: `/Users/voightkampff/.codex/generated_images/01a176da-ae50-7b51-a0b0-bd39ceb1044e/exec-88d3d6f2-6814-4ee9-b5e9-cd07fd8f08d8.png`

Selection / visual assessment: Only candidate, kept for bowed head, paired resting hands and rear costume continuity. Head is too high and hands are too spread relative to the guide; halo remains.

Prompt (exact submitted text):

```text
Use case:identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain frame for Stapledon's Voyage: leaning in, both hands resting on the desk's edge, head bowed to read it. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, limb positions, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels hanging naturally, broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Calm, unhurried body language. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: seen from behind. Calm non-specific face. Draw ONLY the person: no desk, console, chair, rail or lift. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, the boots exactly where the guide's boots are, on the guide's ground line. The whole figure at least 40 px inside every edge. No floor, shadow, scenery, text, halo or watermark.
Production constraints: Image 3 is the absolute pose and framing authority. Preserve its head position, silhouette placement, limb endpoints and boot positions exactly. Do not copy walking foot stagger from image 2. Both boots stay flat on the ground. Background must be empty transparent pixels, with NO soft haze, halo, lighting bloom or ambient shadow around the person. Image 4 is the previous painted frame of this pose family, for costume/rendering continuity only; its pose and any background artifacts must not override image 3.
```

### 4. use_low_front_01

Output: [out/use_low_front_01.png](out/use_low_front_01.png)

Inputs in attachment order:

1. `refs/avatar_captain_proposal_a.png` — picked identity
2. `refs/accepted_walk_profile.png` — accepted painted rendering, closest available facing
3. `guides/use_low_front_01.png` — color-keyed pose/framing guide
4. `out/use_low_back_01.png` — previous painted frame in this pose family; continuity only

Candidates: 1 generated; candidate 1 kept. No second candidate generated.

Candidate 1 source: `/Users/voightkampff/.codex/generated_images/01a176da-ae50-7b51-a0b0-bd39ceb1044e/exec-a8b884ab-1a78-4991-8ec1-89ba83ff59c5.png`

Selection / visual assessment: Only candidate, kept for bowed reading pose and both palms lowered toward the unseen desk; front costume stays recognizable. Hands spread wider and head sits higher than the guide; soft halo remains.

Prompt (exact submitted text):

```text
Use case:identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain frame for Stapledon's Voyage: leaning in, both hands resting on the desk's edge, head bowed to read it. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, limb positions, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels hanging naturally, broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Calm, unhurried body language. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: facing the viewer. Calm non-specific face. Draw ONLY the person: no desk, console, chair, rail or lift. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, the boots exactly where the guide's boots are, on the guide's ground line. The whole figure at least 40 px inside every edge. No floor, shadow, scenery, text, halo or watermark.
Production constraints: Image 3 is the absolute pose and framing authority. Preserve its head position, silhouette placement, limb endpoints and boot positions exactly. Do not copy walking foot stagger from image 2. Both boots stay flat on the ground. Background must be empty transparent pixels, with NO soft haze, halo, lighting bloom or ambient shadow around the person. Image 4 is the previous painted frame of this pose family, for costume/rendering continuity only; its pose and any background artifacts must not override image 3.
```

### 5. use_mid_back_00

Output: [out/use_mid_back_00.png](out/use_mid_back_00.png)

Inputs in attachment order:

1. `refs/avatar_captain_proposal_a.png` — picked identity
2. `refs/accepted_idle_back.png` — accepted painted rendering, closest available facing
3. `guides/use_mid_back_00.png` — color-keyed pose/framing guide

Candidates: 1 generated; candidate 1 kept. No second candidate generated.

Candidate 1 source: `/Users/voightkampff/.codex/generated_images/01a176da-ae50-7b51-a0b0-bd39ceb1044e/exec-645e4692-4af7-4f1b-9bff-a6dfbb162653.png`

Selection / visual assessment: Only candidate, kept for rear-facing captain identity and chest-level console gesture. Arms are raised far above guide endpoints and head is too high; halo remains.

Prompt (exact submitted text):

```text
Use case:identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain frame for Stapledon's Voyage: reaching forward to a chest-high console (1.1 m). Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, limb positions, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels hanging naturally, broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Calm, unhurried body language. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: seen from behind. Calm non-specific face. Draw ONLY the person: no desk, console, chair, rail or lift. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, the boots exactly where the guide's boots are, on the guide's ground line. The whole figure at least 40 px inside every edge. No floor, shadow, scenery, text, halo or watermark.
Production constraints: Image 3 is the absolute pose and framing authority. Preserve its head position, silhouette placement, limb endpoints and boot positions exactly. Do not copy walking foot stagger from image 2. Both boots stay flat on the ground. Background must be empty transparent pixels, with NO soft haze, halo, lighting bloom or ambient shadow around the person.
```

### 6. use_mid_front_00

Output: [out/use_mid_front_00.png](out/use_mid_front_00.png)

Inputs in attachment order:

1. `refs/avatar_captain_proposal_a.png` — picked identity
2. `refs/accepted_walk_profile.png` — accepted painted rendering, closest available facing
3. `guides/use_mid_front_00.png` — color-keyed pose/framing guide
4. `out/use_mid_back_00.png` — previous painted frame in this pose family; continuity only

Candidates: 1 generated; candidate 1 kept. No second candidate generated.

Candidate 1 source: `/Users/voightkampff/.codex/generated_images/01a176da-ae50-7b51-a0b0-bd39ceb1044e/exec-6d190340-c2d3-484d-b673-f05f5c92f12c.png`

Selection / visual assessment: Only candidate, retained for front identity, open coat and console-reaching gesture. Hands are substantially higher than guide endpoints, head is too high, feet are slightly staggered, and halo remains.

Prompt (exact submitted text):

```text
Use case:identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain frame for Stapledon's Voyage: reaching forward to a chest-high console (1.1 m). Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, limb positions, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels hanging naturally, broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Calm, unhurried body language. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: facing the viewer. Calm non-specific face. Draw ONLY the person: no desk, console, chair, rail or lift. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, the boots exactly where the guide's boots are, on the guide's ground line. The whole figure at least 40 px inside every edge. No floor, shadow, scenery, text, halo or watermark.
Production constraints: Image 3 is the absolute pose and framing authority. Preserve its head position, silhouette placement, limb endpoints and boot positions exactly. Do not copy walking foot stagger from image 2. Both boots stay flat on the ground. Background must be empty transparent pixels, with NO soft haze, halo, lighting bloom or ambient shadow around the person. Image 4 is the previous painted frame of this pose family, for costume/rendering continuity only; its pose and any background artifacts must not override image 3.
```

### 7. use_mid_back_01

Output: [out/use_mid_back_01.png](out/use_mid_back_01.png)

Inputs in attachment order:

1. `refs/avatar_captain_proposal_a.png` — picked identity
2. `refs/accepted_idle_back.png` — accepted painted rendering, closest available facing
3. `guides/use_mid_back_01.png` — color-keyed pose/framing guide
4. `out/use_mid_front_00.png` — previous painted frame in this pose family; continuity only

Candidates: 1 generated; candidate 1 kept. No second candidate generated.

Candidate 1 source: `/Users/voightkampff/.codex/generated_images/01a176da-ae50-7b51-a0b0-bd39ceb1044e/exec-dde85434-3a24-46f6-957b-92d9c9b891af.png`

Selection / visual assessment: Only candidate, retained for rear coat/yoke continuity and paired console hands. Palms are upright and too high instead of matching the guide, head too high; halo remains.

Prompt (exact submitted text):

```text
Use case:identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain frame for Stapledon's Voyage: both hands on the console at chest height, attentive. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, limb positions, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels hanging naturally, broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Calm, unhurried body language. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: seen from behind. Calm non-specific face. Draw ONLY the person: no desk, console, chair, rail or lift. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, the boots exactly where the guide's boots are, on the guide's ground line. The whole figure at least 40 px inside every edge. No floor, shadow, scenery, text, halo or watermark.
Production constraints: Image 3 is the absolute pose and framing authority. Preserve its head position, silhouette placement, limb endpoints and boot positions exactly. Do not copy walking foot stagger from image 2. Both boots stay flat on the ground. Background must be empty transparent pixels, with NO soft haze, halo, lighting bloom or ambient shadow around the person. Image 4 is the previous painted frame of this pose family, for costume/rendering continuity only; its pose and any background artifacts must not override image 3.
```

### 8. use_mid_front_01

Output: [out/use_mid_front_01.png](out/use_mid_front_01.png)

Inputs in attachment order:

1. `refs/avatar_captain_proposal_a.png` — picked identity
2. `refs/accepted_walk_profile.png` — accepted painted rendering, closest available facing
3. `guides/use_mid_front_01.png` — color-keyed pose/framing guide
4. `out/use_mid_back_01.png` — previous painted frame in this pose family; continuity only

Candidates: 1 generated; candidate 1 kept. No second candidate generated.

Candidate 1 source: `/Users/voightkampff/.codex/generated_images/01a176da-ae50-7b51-a0b0-bd39ceb1044e/exec-04b888d8-b807-48f9-bd50-88cd2ccd09be.png`

Selection / visual assessment: Only candidate, retained for symmetric front costume and two-handed console gesture. Hands face outward and sit too high, figure is enlarged vertically relative to guide, and halo remains.

Prompt (exact submitted text):

```text
Use case:identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain frame for Stapledon's Voyage: both hands on the console at chest height, attentive. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, limb positions, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels hanging naturally, broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Calm, unhurried body language. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: facing the viewer. Calm non-specific face. Draw ONLY the person: no desk, console, chair, rail or lift. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, the boots exactly where the guide's boots are, on the guide's ground line. The whole figure at least 40 px inside every edge. No floor, shadow, scenery, text, halo or watermark.
Production constraints: Image 3 is the absolute pose and framing authority. Preserve its head position, silhouette placement, limb endpoints and boot positions exactly. Do not copy walking foot stagger from image 2. Both boots stay flat on the ground. Background must be empty transparent pixels, with NO soft haze, halo, lighting bloom or ambient shadow around the person. Image 4 is the previous painted frame of this pose family, for costume/rendering continuity only; its pose and any background artifacts must not override image 3.
```

### 9. sit_back_00

Output: [out/sit_back_00.png](out/sit_back_00.png)

Inputs in attachment order:

1. `refs/avatar_captain_proposal_a.png` — picked identity
2. `refs/accepted_idle_back.png` — accepted painted rendering, closest available facing
3. `guides/sit_back_00.png` — color-keyed pose/framing guide

Candidates: 1 generated; candidate 1 kept. No second candidate generated.

Candidate 1 source: `/Users/voightkampff/.codex/generated_images/01a176da-ae50-7b51-a0b0-bd39ceb1044e/exec-54e48a66-fb0b-4847-997a-26f4f4e2a8f7.png`

Selection / visual assessment: Only candidate, retained for rear costume and slight sitting preparation. Sitting depth is insufficient: head and hips are much higher than the guide, knees not visibly bent enough; halo remains.

Prompt (exact submitted text):

```text
Repaint the mannequin in Image 3 into the captain. Keep Image 3 as the fixed canvas and preserve its exact pose and placement. Replace its colors and flat construction with the illustrated person; do not invent a new pose or enlarge the person.
Use case:identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain frame for Stapledon's Voyage: beginning to sit: knees bending, hips going back and down toward a chair behind (the chair is NOT drawn). Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, limb positions, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels hanging naturally, broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Calm, unhurried body language. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: seen from behind. Calm non-specific face. Draw ONLY the person: no desk, console, chair, rail or lift. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, the boots exactly where the guide's boots are, on the guide's ground line. The whole figure at least 40 px inside every edge. No floor, shadow, scenery, text, halo or watermark.
Production constraints: Image 3 is the absolute pose and framing authority. Preserve its head position, silhouette placement, limb endpoints and boot positions exactly. Do not copy walking foot stagger from image 2. Both boots stay flat on the ground. Background must be empty transparent pixels, with NO soft haze, halo, lighting bloom or ambient shadow around the person.
```

### 10. sit_front_00

Output: [out/sit_front_00.png](out/sit_front_00.png)

Inputs in attachment order:

1. `refs/avatar_captain_proposal_a.png` — picked identity
2. `refs/accepted_walk_profile.png` — accepted painted rendering, closest available facing
3. `guides/sit_front_00.png` — color-keyed pose/framing guide
4. `out/sit_back_00.png` — previous painted frame in this pose family; continuity only

Candidates: 1 generated; candidate 1 kept. No second candidate generated.

Candidate 1 source: `/Users/voightkampff/.codex/generated_images/01a176da-ae50-7b51-a0b0-bd39ceb1044e/exec-dde719d8-1b9d-49de-8264-21054843d889.png`

Selection / visual assessment: Only candidate, kept for front-facing beginning-to-sit gesture, lowered hips and recognizable costume. Boots sit much higher than guide boots and bend is understated; halo remains. The guide itself reaches the lower edge, conflicting with the 40 px inset requirement.

Prompt (exact submitted text):

```text
Repaint the mannequin in Image 3 into the captain. Keep Image 3 as the fixed canvas and preserve its exact pose and placement. Replace its colors and flat construction with the illustrated person; do not invent a new pose or enlarge the person.
Use case:identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain frame for Stapledon's Voyage: beginning to sit: knees bending, hips going back and down toward a chair behind (the chair is NOT drawn). Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, limb positions, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels hanging naturally, broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Calm, unhurried body language. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: facing the viewer. Calm non-specific face. Draw ONLY the person: no desk, console, chair, rail or lift. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, the boots exactly where the guide's boots are, on the guide's ground line. The whole figure at least 40 px inside every edge. No floor, shadow, scenery, text, halo or watermark.
Production constraints: Image 3 is the absolute pose and framing authority. Preserve its head position, silhouette placement, limb endpoints and boot positions exactly. Do not copy walking foot stagger from image 2. Both boots stay flat on the ground. Background must be empty transparent pixels, with NO soft haze, halo, lighting bloom or ambient shadow around the person. Image 4 is the previous painted frame of this pose family, for costume/rendering continuity only; its pose and any background artifacts must not override image 3.
```

### 11. sit_back_01

Output: [out/sit_back_01.png](out/sit_back_01.png)

Inputs in attachment order:

1. `refs/avatar_captain_proposal_a.png` — picked identity
2. `refs/accepted_idle_back.png` — accepted painted rendering, closest available facing
3. `guides/sit_back_01.png` — color-keyed pose/framing guide
4. `out/sit_front_00.png` — previous painted frame in this pose family; continuity only

Candidates: 1 generated; candidate 1 kept. No second candidate generated.

Candidate 1 source: `/Users/voightkampff/.codex/generated_images/01a176da-ae50-7b51-a0b0-bd39ceb1044e/exec-15af45d2-6749-45ce-acc5-ba263708ebfe.png`

Selection / visual assessment: Only candidate, retained for rear rendering and costume consistency, but pose is not right: effectively upright rather than almost seated; head and hips are far above the guide. Halo remains. Guide coat reaches the bottom edge.

Prompt (exact submitted text):

```text
Repaint the mannequin in Image 3 into the captain. Keep Image 3 as the fixed canvas and preserve its exact pose and placement. Replace its colors and flat construction with the illustrated person; do not invent a new pose or enlarge the person.
Use case:identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain frame for Stapledon's Voyage: almost seated: hips just above the seat, weight back. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, limb positions, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels hanging naturally, broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Calm, unhurried body language. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: seen from behind. Calm non-specific face. Draw ONLY the person: no desk, console, chair, rail or lift. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, the boots exactly where the guide's boots are, on the guide's ground line. The whole figure at least 40 px inside every edge. No floor, shadow, scenery, text, halo or watermark.
Production constraints: Image 3 is the absolute pose and framing authority. Preserve its head position, silhouette placement, limb endpoints and boot positions exactly. Do not copy walking foot stagger from image 2. Both boots stay flat on the ground. Background must be empty transparent pixels, with NO soft haze, halo, lighting bloom or ambient shadow around the person. Image 4 is the previous painted frame of this pose family, for costume/rendering continuity only; its pose and any background artifacts must not override image 3.
```

### 12. sit_front_01

Output: [out/sit_front_01.png](out/sit_front_01.png)

Inputs in attachment order:

1. `refs/avatar_captain_proposal_a.png` — picked identity
2. `refs/accepted_walk_profile.png` — accepted painted rendering, closest available facing
3. `guides/sit_front_01.png` — color-keyed pose/framing guide
4. `out/sit_back_01.png` — previous painted frame in this pose family; continuity only

Candidates: 1 generated; candidate 1 kept. No second candidate generated.

Candidate 1 source: `/Users/voightkampff/.codex/generated_images/01a176da-ae50-7b51-a0b0-bd39ceb1044e/exec-d553e981-10d3-43e9-9e15-b19bc9fd8244.png`

Selection / visual assessment: Only candidate, kept for front identity and costume continuity, but pose is not right: largely standing instead of almost seated, head too high and hips not back/down. Halo remains. Guide boots approach the lower canvas edge.

Prompt (exact submitted text):

```text
Repaint the mannequin in Image 3 into the captain. Keep Image 3 as the fixed canvas and preserve its exact pose and placement. Replace its colors and flat construction with the illustrated person; do not invent a new pose or enlarge the person.
Use case:identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain frame for Stapledon's Voyage: almost seated: hips just above the seat, weight back. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, limb positions, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels hanging naturally, broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Calm, unhurried body language. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: facing the viewer. Calm non-specific face. Draw ONLY the person: no desk, console, chair, rail or lift. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, the boots exactly where the guide's boots are, on the guide's ground line. The whole figure at least 40 px inside every edge. No floor, shadow, scenery, text, halo or watermark.
Production constraints: Image 3 is the absolute pose and framing authority. Preserve its head position, silhouette placement, limb endpoints and boot positions exactly. Do not copy walking foot stagger from image 2. Both boots stay flat on the ground. Background must be empty transparent pixels, with NO soft haze, halo, lighting bloom or ambient shadow around the person. Image 4 is the previous painted frame of this pose family, for costume/rendering continuity only; its pose and any background artifacts must not override image 3.
```

### 13. seated_back_00

Output: [out/seated_back_00.png](out/seated_back_00.png)

Inputs in attachment order:

1. `refs/avatar_captain_proposal_a.png` — picked identity
2. `refs/accepted_idle_back.png` — accepted painted rendering, closest available facing
3. `guides/seated_back_00.png` — color-keyed pose/framing guide

Candidates: 1 generated; candidate 1 kept. No second candidate generated.

Candidate 1 source: `/Users/voightkampff/.codex/generated_images/01a176da-ae50-7b51-a0b0-bd39ceb1044e/exec-6c18783b-3166-48ad-a3cb-df1630fdd02f.png`

Selection / visual assessment: Only candidate, kept because bent thighs, resting hands and draped coat read as seated from behind. Figure sits much higher than the guide and coat does not fall to the guide's floor position; halo remains. Guide coat extends to canvas bottom.

Prompt (exact submitted text):

```text
Repaint the mannequin in Image 3 into the captain. Keep Image 3 as the fixed canvas and preserve its exact pose and placement. Replace its colors and flat construction with the illustrated person; do not invent a new pose or enlarge the person.
Use case:identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain frame for Stapledon's Voyage: seated upright on an unseen chair, hands resting on the thighs, feet flat on the floor; the coat drapes over the seat and falls to the floor. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, limb positions, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels hanging naturally, broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Calm, unhurried body language. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: seen from behind. Calm non-specific face. Draw ONLY the person: no desk, console, chair, rail or lift. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, the boots exactly where the guide's boots are, on the guide's ground line. The whole figure at least 40 px inside every edge. No floor, shadow, scenery, text, halo or watermark.
Production constraints: Image 3 is the absolute pose and framing authority. Preserve its head position, silhouette placement, limb endpoints and boot positions exactly. Do not copy walking foot stagger from image 2. Both boots stay flat on the ground. Background must be empty transparent pixels, with NO soft haze, halo, lighting bloom or ambient shadow around the person.
```

### 14. seated_front_00

Output: [out/seated_front_00.png](out/seated_front_00.png)

Inputs in attachment order:

1. `refs/avatar_captain_proposal_a.png` — picked identity
2. `refs/accepted_walk_profile.png` — accepted painted rendering, closest available facing
3. `guides/seated_front_00.png` — color-keyed pose/framing guide
4. `out/seated_back_00.png` — previous painted frame in this pose family; continuity only

Candidates: 1 generated; candidate 1 kept. No second candidate generated.

Candidate 1 source: `/Users/voightkampff/.codex/generated_images/01a176da-ae50-7b51-a0b0-bd39ceb1044e/exec-d6232c9c-38dd-4052-9703-cfcf45779c86.png`

Selection / visual assessment: Only candidate, kept for clear seated posture, both hands on thighs and draped coat. Head is higher and boots higher than guide; coat stops above the boots instead of falling fully to floor; halo remains. Guide boots touch bottom edge.

Prompt (exact submitted text):

```text
Repaint the mannequin in Image 3 into the captain. Keep Image 3 as the fixed canvas and preserve its exact pose and placement. Replace its colors and flat construction with the illustrated person; do not invent a new pose or enlarge the person.
Use case:identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain frame for Stapledon's Voyage: seated upright on an unseen chair, hands resting on the thighs, feet flat on the floor; the coat drapes over the seat and falls to the floor. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, limb positions, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels hanging naturally, broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Calm, unhurried body language. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: facing the viewer. Calm non-specific face. Draw ONLY the person: no desk, console, chair, rail or lift. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, the boots exactly where the guide's boots are, on the guide's ground line. The whole figure at least 40 px inside every edge. No floor, shadow, scenery, text, halo or watermark.
Production constraints: Image 3 is the absolute pose and framing authority. Preserve its head position, silhouette placement, limb endpoints and boot positions exactly. Do not copy walking foot stagger from image 2. Both boots stay flat on the ground. Background must be empty transparent pixels, with NO soft haze, halo, lighting bloom or ambient shadow around the person. Image 4 is the previous painted frame of this pose family, for costume/rendering continuity only; its pose and any background artifacts must not override image 3.
```

### 15. lift_back_00

Output: [out/lift_back_00.png](out/lift_back_00.png)

Inputs in attachment order:

1. `refs/avatar_captain_proposal_a.png` — picked identity
2. `refs/accepted_idle_back.png` — accepted painted rendering, closest available facing
3. `guides/lift_back_00.png` — color-keyed pose/framing guide

Candidates: 1 generated; candidate 1 kept. No second candidate generated.

Candidate 1 source: `/Users/voightkampff/.codex/generated_images/01a176da-ae50-7b51-a0b0-bd39ceb1044e/exec-ec0228ce-f6cf-4a86-a1e4-cf8bb1fce9a8.png`

Selection / visual assessment: Only candidate, kept for calm rear stance and correctly extended right hand without a drawn rail. Figure placement is closer here, but hand is within 40 px of right edge and halo remains. Guide right hand reaches the edge, so exact matching conflicts with required inset.

Prompt (exact submitted text):

```text
Repaint the mannequin in Image 3 into the captain. Keep Image 3 as the fixed canvas and preserve its exact pose and placement. Replace its colors and flat construction with the illustrated person; do not invent a new pose or enlarge the person.
Use case:identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain frame for Stapledon's Voyage: standing calmly on a lift platform, the RIGHT hand resting on a rail out to the side. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, limb positions, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels hanging naturally, broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Calm, unhurried body language. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: seen from behind. Calm non-specific face. Draw ONLY the person: no desk, console, chair, rail or lift. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, the boots exactly where the guide's boots are, on the guide's ground line. The whole figure at least 40 px inside every edge. No floor, shadow, scenery, text, halo or watermark.
Production constraints: Image 3 is the absolute pose and framing authority. Preserve its head position, silhouette placement, limb endpoints and boot positions exactly. Do not copy walking foot stagger from image 2. Both boots stay flat on the ground. Background must be empty transparent pixels, with NO soft haze, halo, lighting bloom or ambient shadow around the person.
```

### 16. lift_back_34_00

Output: [out/lift_back_34_00.png](out/lift_back_34_00.png)

Inputs in attachment order:

1. `refs/avatar_captain_proposal_a.png` — picked identity
2. `refs/accepted_idle_back.png` — accepted painted rendering, closest available facing
3. `guides/lift_back_34_00.png` — color-keyed pose/framing guide
4. `out/lift_back_00.png` — previous painted frame in this pose family; continuity only

Candidates: 1 generated; candidate 1 kept. No second candidate generated.

Candidate 1 source: `/Users/voightkampff/.codex/generated_images/01a176da-ae50-7b51-a0b0-bd39ceb1044e/exec-175a2277-5754-4253-ae40-98554914b20c.png`

Selection / visual assessment: Only candidate, retained for rear-three-quarter intent and right rail hand. Turn is too shallow, hand is higher/farther right than guide, feet differ from guide placement, and halo remains.

Prompt (exact submitted text):

```text
Repaint the mannequin in Image 3 into the captain. Keep Image 3 as the fixed canvas and preserve its exact pose and placement. Replace its colors and flat construction with the illustrated person; do not invent a new pose or enlarge the person.
Use case:identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain frame for Stapledon's Voyage: standing calmly on a lift platform, the RIGHT hand resting on a rail out to the side. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, limb positions, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels hanging naturally, broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Calm, unhurried body language. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: from behind, turned toward screen-right. Calm non-specific face. Draw ONLY the person: no desk, console, chair, rail or lift. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, the boots exactly where the guide's boots are, on the guide's ground line. The whole figure at least 40 px inside every edge. No floor, shadow, scenery, text, halo or watermark.
Production constraints: Image 3 is the absolute pose and framing authority. Preserve its head position, silhouette placement, limb endpoints and boot positions exactly. Do not copy walking foot stagger from image 2. Both boots stay flat on the ground. Background must be empty transparent pixels, with NO soft haze, halo, lighting bloom or ambient shadow around the person. Image 4 is the previous painted frame of this pose family, for costume/rendering continuity only; its pose and any background artifacts must not override image 3.
```

### 17. lift_profile_00

Output: [out/lift_profile_00.png](out/lift_profile_00.png)

Inputs in attachment order:

1. `refs/avatar_captain_proposal_a.png` — picked identity
2. `refs/accepted_walk_profile.png` — accepted painted rendering, closest available facing
3. `guides/lift_profile_00.png` — color-keyed pose/framing guide
4. `out/lift_back_34_00.png` — previous painted frame in this pose family; continuity only

Candidates: 1 generated; candidate 1 kept. No second candidate generated.

Candidate 1 source: `/Users/voightkampff/.codex/generated_images/01a176da-ae50-7b51-a0b0-bd39ceb1044e/exec-b091476c-f8b8-49c5-9231-b1536a99c1d6.png`

Selection / visual assessment: Only candidate, kept for clear right-facing profile and costume matching. Guide's near/right arm is not transferred correctly: near hand hangs while far arm reaches. Figure is too high/wide and boot placement differs; halo remains.

Prompt (exact submitted text):

```text
Repaint the mannequin in Image 3 into the captain. Keep Image 3 as the fixed canvas and preserve its exact pose and placement. Replace its colors and flat construction with the illustrated person; do not invent a new pose or enlarge the person.
Use case:identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain frame for Stapledon's Voyage: standing calmly on a lift platform, the RIGHT hand resting on a rail out to the side. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, limb positions, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels hanging naturally, broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Calm, unhurried body language. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: full side view facing screen-RIGHT (the captain's right side toward the viewer). Calm non-specific face. Draw ONLY the person: no desk, console, chair, rail or lift. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, the boots exactly where the guide's boots are, on the guide's ground line. The whole figure at least 40 px inside every edge. No floor, shadow, scenery, text, halo or watermark.
Production constraints: Image 3 is the absolute pose and framing authority. Preserve its head position, silhouette placement, limb endpoints and boot positions exactly. Do not copy walking foot stagger from image 2. Both boots stay flat on the ground. Background must be empty transparent pixels, with NO soft haze, halo, lighting bloom or ambient shadow around the person. Image 4 is the previous painted frame of this pose family, for costume/rendering continuity only; its pose and any background artifacts must not override image 3.
```

### 18. lift_front_34_00

Output: [out/lift_front_34_00.png](out/lift_front_34_00.png)

Inputs in attachment order:

1. `refs/avatar_captain_proposal_a.png` — picked identity
2. `refs/accepted_walk_profile.png` — accepted painted rendering, closest available facing
3. `guides/lift_front_34_00.png` — color-keyed pose/framing guide
4. `out/lift_profile_00.png` — previous painted frame in this pose family; continuity only

Candidates: 1 generated; candidate 1 kept. No second candidate generated.

Candidate 1 source: `/Users/voightkampff/.codex/generated_images/01a176da-ae50-7b51-a0b0-bd39ceb1044e/exec-5eae5842-f226-4e56-84ef-d080721a6ac2.png`

Selection / visual assessment: Only candidate, retained for costume and painted continuity, but facing is too close to profile rather than front three-quarter. Extended hand is on opposite screen side from guide's right-hand endpoint; framing and feet differ; halo remains.

Prompt (exact submitted text):

```text
Repaint the mannequin in Image 3 into the captain. Keep Image 3 as the fixed canvas and preserve its exact pose and placement. Replace its colors and flat construction with the illustrated person; do not invent a new pose or enlarge the person.
Use case:identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain frame for Stapledon's Voyage: standing calmly on a lift platform, the RIGHT hand resting on a rail out to the side. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, limb positions, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels hanging naturally, broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Calm, unhurried body language. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: facing the viewer, turned toward screen-right. Calm non-specific face. Draw ONLY the person: no desk, console, chair, rail or lift. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, the boots exactly where the guide's boots are, on the guide's ground line. The whole figure at least 40 px inside every edge. No floor, shadow, scenery, text, halo or watermark.
Production constraints: Image 3 is the absolute pose and framing authority. Preserve its head position, silhouette placement, limb endpoints and boot positions exactly. Do not copy walking foot stagger from image 2. Both boots stay flat on the ground. Background must be empty transparent pixels, with NO soft haze, halo, lighting bloom or ambient shadow around the person. Image 4 is the previous painted frame of this pose family, for costume/rendering continuity only; its pose and any background artifacts must not override image 3.
```

### 19. lift_front_00

Output: [out/lift_front_00.png](out/lift_front_00.png)

Inputs in attachment order:

1. `refs/avatar_captain_proposal_a.png` — picked identity
2. `refs/accepted_walk_profile.png` — accepted painted rendering, closest available facing
3. `guides/lift_front_00.png` — color-keyed pose/framing guide
4. `out/lift_front_34_00.png` — previous painted frame in this pose family; continuity only

Candidates: 1 generated; candidate 1 kept. No second candidate generated.

Candidate 1 source: `/Users/voightkampff/.codex/generated_images/01a176da-ae50-7b51-a0b0-bd39ceb1044e/exec-2466860a-fc42-47d6-90df-5d07c8da84b1.png`

Selection / visual assessment: Only candidate, kept for front-facing lift stance and correctly extended right hand toward screen-left. Head is higher, hand is higher/inset compared to guide, boots shifted, and halo remains. Guide hand touches the left edge, conflicting with the 40 px inset.

Prompt (exact submitted text):

```text
Repaint the mannequin in Image 3 into the captain. Keep Image 3 as the fixed canvas and preserve its exact pose and placement. Replace its colors and flat construction with the illustrated person; do not invent a new pose or enlarge the person.
Use case:identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain frame for Stapledon's Voyage: standing calmly on a lift platform, the RIGHT hand resting on a rail out to the side. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, limb positions, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels hanging naturally, broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Calm, unhurried body language. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: facing the viewer. Calm non-specific face. Draw ONLY the person: no desk, console, chair, rail or lift. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, the boots exactly where the guide's boots are, on the guide's ground line. The whole figure at least 40 px inside every edge. No floor, shadow, scenery, text, halo or watermark.
Production constraints: Image 3 is the absolute pose and framing authority. Preserve its head position, silhouette placement, limb endpoints and boot positions exactly. Do not copy walking foot stagger from image 2. Both boots stay flat on the ground. Background must be empty transparent pixels, with NO soft haze, halo, lighting bloom or ambient shadow around the person. Image 4 is the previous painted frame of this pose family, for costume/rendering continuity only; its pose and any background artifacts must not override image 3.
```

### 20. look_up_back_00

Output: [out/look_up_back_00.png](out/look_up_back_00.png)

Inputs in attachment order:

1. `refs/avatar_captain_proposal_a.png` — picked identity
2. `refs/accepted_idle_back.png` — accepted painted rendering, closest available facing
3. `guides/look_up_back_00.png` — color-keyed pose/framing guide

Candidates: 1 generated; candidate 1 kept. No second candidate generated.

Candidate 1 source: `/Users/voightkampff/.codex/generated_images/01a176da-ae50-7b51-a0b0-bd39ceb1044e/exec-04501f10-a7ec-44e6-ba1a-b8e031235031.png`

Selection / visual assessment: Only candidate, retained for calm rear stance and identity/costume rendering. Upward head/chest lift is too subtle; arm/coat proportions differ from guide, and halo remains.

Prompt (exact submitted text):

```text
Repaint the mannequin in Image 3 into the captain. Keep Image 3 as the fixed canvas and preserve its exact pose and placement. Replace its colors and flat construction with the illustrated person; do not invent a new pose or enlarge the person.
Use case:identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain frame for Stapledon's Voyage: standing still, head and chest lifted, gazing up at the sky in quiet wonder. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, limb positions, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels hanging naturally, broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Calm, unhurried body language. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: seen from behind. Calm non-specific face. Draw ONLY the person: no desk, console, chair, rail or lift. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, the boots exactly where the guide's boots are, on the guide's ground line. The whole figure at least 40 px inside every edge. No floor, shadow, scenery, text, halo or watermark.
Production constraints: Image 3 is the absolute pose and framing authority. Preserve its head position, silhouette placement, limb endpoints and boot positions exactly. Do not copy walking foot stagger from image 2. Both boots stay flat on the ground. Background must be empty transparent pixels, with NO soft haze, halo, lighting bloom or ambient shadow around the person.
```

### 21. look_up_back_34_00

Output: [out/look_up_back_34_00.png](out/look_up_back_34_00.png)

Inputs in attachment order:

1. `refs/avatar_captain_proposal_a.png` — picked identity
2. `refs/accepted_idle_back.png` — accepted painted rendering, closest available facing
3. `guides/look_up_back_34_00.png` — color-keyed pose/framing guide
4. `out/look_up_back_00.png` — previous painted frame in this pose family; continuity only

Candidates: 1 generated; candidate 1 kept. No second candidate generated.

Candidate 1 source: `/Users/voightkampff/.codex/generated_images/01a176da-ae50-7b51-a0b0-bd39ceb1044e/exec-505df795-3a9e-45fa-98eb-7fe2cce6ed1c.png`

Selection / visual assessment: Only candidate, kept for recognizable rear three-quarter orientation, visibly lifted chin and calm stance. Head is higher and foot spacing/coat silhouette differ from guide; halo remains.

Prompt (exact submitted text):

```text
Repaint the mannequin in Image 3 into the captain. Keep Image 3 as the fixed canvas and preserve its exact pose and placement. Replace its colors and flat construction with the illustrated person; do not invent a new pose or enlarge the person.
Use case:identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain frame for Stapledon's Voyage: standing still, head and chest lifted, gazing up at the sky in quiet wonder. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, limb positions, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels hanging naturally, broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Calm, unhurried body language. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: from behind, turned toward screen-right. Calm non-specific face. Draw ONLY the person: no desk, console, chair, rail or lift. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, the boots exactly where the guide's boots are, on the guide's ground line. The whole figure at least 40 px inside every edge. No floor, shadow, scenery, text, halo or watermark.
Production constraints: Image 3 is the absolute pose and framing authority. Preserve its head position, silhouette placement, limb endpoints and boot positions exactly. Do not copy walking foot stagger from image 2. Both boots stay flat on the ground. Background must be empty transparent pixels, with NO soft haze, halo, lighting bloom or ambient shadow around the person. Image 4 is the previous painted frame of this pose family, for costume/rendering continuity only; its pose and any background artifacts must not override image 3.
```

### 22. look_up_profile_00

Output: [out/look_up_profile_00.png](out/look_up_profile_00.png)

Inputs in attachment order:

1. `refs/avatar_captain_proposal_a.png` — picked identity
2. `refs/accepted_walk_profile.png` — accepted painted rendering, closest available facing
3. `guides/look_up_profile_00.png` — color-keyed pose/framing guide
4. `out/look_up_back_34_00.png` — previous painted frame in this pose family; continuity only

Candidates: 1 generated; candidate 1 kept. No second candidate generated.

Candidate 1 source: `/Users/voightkampff/.codex/generated_images/01a176da-ae50-7b51-a0b0-bd39ceb1044e/exec-b64c47fa-e9d6-488d-8cf1-5ea3bad7aab3.png`

Selection / visual assessment: Only candidate, kept for full right-facing profile, visibly raised gaze and calm posture. Head higher than guide; coat flares behind more than guide; boots do not match guide endpoints; halo remains.

Prompt (exact submitted text):

```text
Repaint the mannequin in Image 3 into the captain. Keep Image 3 as the fixed canvas and preserve its exact pose and placement. Replace its colors and flat construction with the illustrated person; do not invent a new pose or enlarge the person.
Use case:identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain frame for Stapledon's Voyage: standing still, head and chest lifted, gazing up at the sky in quiet wonder. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, limb positions, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels hanging naturally, broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Calm, unhurried body language. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: full side view facing screen-RIGHT (the captain's right side toward the viewer). Calm non-specific face. Draw ONLY the person: no desk, console, chair, rail or lift. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, the boots exactly where the guide's boots are, on the guide's ground line. The whole figure at least 40 px inside every edge. No floor, shadow, scenery, text, halo or watermark.
Production constraints: Image 3 is the absolute pose and framing authority. Preserve its head position, silhouette placement, limb endpoints and boot positions exactly. Do not copy walking foot stagger from image 2. Both boots stay flat on the ground. Background must be empty transparent pixels, with NO soft haze, halo, lighting bloom or ambient shadow around the person. Image 4 is the previous painted frame of this pose family, for costume/rendering continuity only; its pose and any background artifacts must not override image 3.
```

### 23. look_up_front_34_00

Output: [out/look_up_front_34_00.png](out/look_up_front_34_00.png)

Inputs in attachment order:

1. `refs/avatar_captain_proposal_a.png` — picked identity
2. `refs/accepted_walk_profile.png` — accepted painted rendering, closest available facing
3. `guides/look_up_front_34_00.png` — color-keyed pose/framing guide
4. `out/look_up_profile_00.png` — previous painted frame in this pose family; continuity only

Candidates: 1 generated; candidate 1 kept. No second candidate generated.

Candidate 1 source: `/Users/voightkampff/.codex/generated_images/01a176da-ae50-7b51-a0b0-bd39ceb1044e/exec-8fb89434-e406-48bf-b8a9-ce0d9111fdc7.png`

Selection / visual assessment: Only candidate, retained for raised gaze and captain rendering, but facing is wrong: too close to full profile rather than front three-quarter. Head, arm, coat and foot placement do not match guide; halo remains.

Prompt (exact submitted text):

```text
Repaint the mannequin in Image 3 into the captain. Keep Image 3 as the fixed canvas and preserve its exact pose and placement. Replace its colors and flat construction with the illustrated person; do not invent a new pose or enlarge the person.
Use case:identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain frame for Stapledon's Voyage: standing still, head and chest lifted, gazing up at the sky in quiet wonder. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, limb positions, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels hanging naturally, broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Calm, unhurried body language. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: facing the viewer, turned toward screen-right. Calm non-specific face. Draw ONLY the person: no desk, console, chair, rail or lift. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, the boots exactly where the guide's boots are, on the guide's ground line. The whole figure at least 40 px inside every edge. No floor, shadow, scenery, text, halo or watermark.
Production constraints: Image 3 is the absolute pose and framing authority. Preserve its head position, silhouette placement, limb endpoints and boot positions exactly. Do not copy walking foot stagger from image 2. Both boots stay flat on the ground. Background must be empty transparent pixels, with NO soft haze, halo, lighting bloom or ambient shadow around the person. Image 4 is the previous painted frame of this pose family, for costume/rendering continuity only; its pose and any background artifacts must not override image 3.
```

### 24. look_up_front_00

Output: [out/look_up_front_00.png](out/look_up_front_00.png)

Inputs in attachment order:

1. `refs/avatar_captain_proposal_a.png` — picked identity
2. `refs/accepted_walk_profile.png` — accepted painted rendering, closest available facing
3. `guides/look_up_front_00.png` — color-keyed pose/framing guide
4. `out/look_up_front_34_00.png` — previous painted frame in this pose family; continuity only

Candidates: 1 generated; candidate 1 kept. No second candidate generated.

Candidate 1 source: `/Users/voightkampff/.codex/generated_images/01a176da-ae50-7b51-a0b0-bd39ceb1044e/exec-e524ac3a-d873-4456-928b-a5f8f5588e9a.png`

Selection / visual assessment: Only candidate, kept for front-facing body, upward gaze, relaxed hands and matching costume. Head turns toward screen-right instead of remaining square to viewer; head and hand placement differ from guide, and halo remains.

Prompt (exact submitted text):

```text
Repaint the mannequin in Image 3 into the captain. Keep Image 3 as the fixed canvas and preserve its exact pose and placement. Replace its colors and flat construction with the illustrated person; do not invent a new pose or enlarge the person.
Use case:identity-preserve, pose transfer, animation frame. Asset: ONE production full-body captain frame for Stapledon's Voyage: standing still, head and chest lifted, gazing up at the sky in quiet wonder. Image 1 is the identity (Mark's PICKED captain "A, Longline Navigator"); image 2 is an accepted earlier frame — keep this exact rendering of the character; image 3 is a colour-keyed POSE GUIDE: copy ONLY its pose, limb positions, framing and foot positions (red = left leg, blue = right leg, orange = left arm, cyan = right arm), never its flat mannequin look. The same slender androgynous warm-medium-skinned young adult (about 30), softly swept short dark hair, civilian cream calf-length OPEN long coat with rounded front panels hanging naturally, broad ochre shoulder yoke and raised collar, ochre sash, plain oval closures, violet tapered trousers, practical soft boots. Calm, unhurried body language. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour; believable anatomy. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959, ink #423555. Soft warm key from upper left, delicate pale cool rim; no glow. Camera orthographic, looking DOWN 29 degrees (as the guide). Facing: facing the viewer. Calm non-specific face. Draw ONLY the person: no desk, console, chair, rail or lift. Canvas 1024 x 1536 RGBA, genuinely transparent background, alpha exactly zero outside the figure, crisp antialiased edge. Match the guide's framing: the same figure size and head position, the boots exactly where the guide's boots are, on the guide's ground line. The whole figure at least 40 px inside every edge. No floor, shadow, scenery, text, halo or watermark.
Production constraints: Image 3 is the absolute pose and framing authority. Preserve its head position, silhouette placement, limb endpoints and boot positions exactly. Do not copy walking foot stagger from image 2. Both boots stay flat on the ground. Background must be empty transparent pixels, with NO soft haze, halo, lighting bloom or ambient shadow around the person. Image 4 is the previous painted frame of this pose family, for costume/rendering continuity only; its pose and any background artifacts must not override image 3.
```
