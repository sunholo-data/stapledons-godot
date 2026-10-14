# Medic stage-0 emotion portraits

Art handoff part (b), step 1. Work on branch `art/medic-emotions`, 2026-10-14. Art owned by Sunholo, contributed under Apache-2.0. No commits, avatar, age-50 delivery, index changes or source-image changes.

## Provenance and review limits

- The five new emotions each have two independent built-in imagegen edits of the same accepted neutral. All ten submitted prompts are reproduced verbatim below. No candidate is an edit of another candidate.
- Generator: OpenAI built-in `image_gen.imagegen` tool. Exact model id/version: **not exposed by the tool**; no version was returned, so none is invented. Seed: none exposed. `transparent_background: true`; the only image input on every call was `portrait_medic_age0_neutral_v2.png`.
- The accepted neutral, loving and grieving were copied byte-for-byte. Their historical tool/model/date/seed and complete original generation prompts are absent from this bundle. No generation occurred for those three files in this task. The supplied handoff descriptions/pattern are transcribed below as source documentation, not claimed to be a recovered historical request.
- All five supplied PNG hashes were verified against `art-refs/SHA256SUMS` before use. Only project-owned inputs were used. The older neutral and avatar were visually inspected for style and were not passed to the generator.
- `name_region: south_asia` is a proposed D-80 naming convention based on this fictional art direction, not an established ancestry. `gender_presentation: woman` follows the accepted Medic description. No personal name has been chosen.
- Every portrait is native 1254 x 1254 RGBA. No portrait resampling, translation, padding, crop, alpha cleanup or other post-processing was performed. Transparent background and the accepted crop were preserved as generated/copied.
- **Alpha exception:** accepted neutral/loving/grieving already touch top and side edges. Every new edit preserves that composition. The strict three-edge alpha-zero check therefore fails; no passing result is claimed. Upper-corner alpha maxima are listed below; near-transparent residuals can occur outside the figure. Faint coloured antialiased fringe pixels inherited from the references remain visible on black at high magnification. Fixing those or adding margin would conflict with the requested byte-for-byte copies and exact crop.
- Contact sheet: all eight emotions on mid-grey and black, plus neutral composited at 50% alpha over each image at identical coordinates. Review thumbnails alone are downscaled from 1254 to 340 px with Lanczos; no upscaling. Visual QA checks head scale, hair outline, scarf, shoulder placement and expression readability. Minor regenerated ink/texture differences remain; no material head jump was seen.

## Supplied handoff identity description (verbatim)

> a woman of about 35, with warm medium-brown skin, a distinctive believable face, dark expressive eyes, gently arched imperfect eyebrows, a long slightly crooked nose, soft natural lips, and thick dark wavy hair swept loosely behind the ears with a few escaped strands. She has compassionate attention and quiet intelligence. She wears cream layered cloth medical workwear, a deep teal folded shawl collar, a small coral seam and an understated worn brass fastening.

## Supplied accepted grief-edit pattern (verbatim; historical request not independently recovered)

> Input image is the identity/style reference and edit target. Change ONLY her expression to quiet grief: eyes lowered slightly, a fragile tension in the brow and lower eyelids, lips held gently together, a person trying to remain present through loss. Subtle, believable, deeply felt; no theatrical crying. Same age. Preserve the sophisticated hand-drawn graphic-novel ink-and-gouache look, original palette, lighting direction, clothing, hair design, anatomical identity. For portraits preserve exact square bust crop, head scale, camera angle, pose and eye-line as closely as possible so images can swap in the same dialogue UI. Keep genuinely transparent alpha background, no scenery, caption, frame, UI or watermark. This is a static game image; no animation.

## portrait_medic_y0_neutral.png

- Delivered sha256: `93a02944772201d3e854a283342fd189409995e85a91796d5197a9e5f0be0017`
- Generator / model: historical values not supplied; no generation in this task.
- Date: re-keyed 2026-10-14; original generation date not supplied. Seed: historical value not supplied.
- Mode: byte-for-byte copy of `portrait_medic_age0_neutral_v2.png` (sha256 `93a02944772201d3e854a283342fd189409995e85a91796d5197a9e5f0be0017`).
- Prompt (full, verbatim): not applicable to this copy operation. Complete historical prompt was not supplied; see source handoff documentation above.
- Post-processing: none; only filename re-keying. Never upscaled.
- Candidates: 0 generated; accepted source retained as instructed.

## portrait_medic_y0_happy.png

- Delivered sha256: `0dc9e2d4a37c1ff611f4f92599e34bba85d9e7b297eeb2d794582ef6ed0dc738`
- Generator: OpenAI built-in `image_gen.imagegen`. Model: exact id/version not exposed.
- Date: 2026-10-14. Seed: none exposed.
- Mode: edit of `portrait_medic_age0_neutral_v2.png` (sha256 `93a02944772201d3e854a283342fd189409995e85a91796d5197a9e5f0be0017`).
- Post-processing: none; selected output copied byte-for-byte. Never upscaled.
- Candidates: 2 generated; kept candidate 1. The narrow tooth-showing smile and lifted cheeks read as quiet happiness and distinguish it from loving without becoming laughter.

### Candidate 1 — kept

- Native output: 1254 x 1254 RGBA; sha256 `0dc9e2d4a37c1ff611f4f92599e34bba85d9e7b297eeb2d794582ef6ed0dc738`.
- Generator output filename: `exec-2a10ff22-816e-44aa-8d8e-038e621fcc7b.png`. Delivered under the section filename.
- Decision: The narrow tooth-showing smile and lifted cheeks read as quiet happiness and distinguish it from loving without becoming laughter.
- Prompt (full, verbatim):

> Use case: identity-preserve. Asset type: square stage-0 emotion portrait for Stapledon's Voyage dialogue UI. Input image 1 is the accepted portrait_medic_age0_neutral_v2.png, the identity/style reference and EDIT TARGET. Edit this image, do not redraw a different woman. Change ONLY her expression to quiet happiness: a small but clearly readable open smile showing only a sliver of upper teeth, lifted mouth corners, softly lifted cheeks and smiling eyes. Warm relief and unforced delight, not laughter, not a broad grin. Same woman, about 35. Preserve her exact facial structure, long slightly crooked nose, natural lips, skin tone and facial marks, thick dark wavy hair and escaped strands. Preserve the cream tunic, deep teal folded scarf, coral trim, worn brass fastening and pens in the pocket. Preserve the sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour, original palette and lighting direction. Preserve exact square mid-chest bust crop, head scale, head position, camera angle, pose and eye-line, every hair silhouette and clothing fold as closely as possible, so the image swaps in the same dialogue UI. Native square resolution only, never upscale. Keep genuinely transparent alpha outside the figure, with no scenery, backdrop, gradient, glow, halo, caption, frame, UI, logo or watermark. Keep the original composition; no added headroom or zoom-out. Static game image, no animation.

### Candidate 2 — rejected

- Native output: 1254 x 1254 RGBA; sha256 `be7f259277d8c44da99f2b8555b46d5e779a4ecaaa19f8826dd5afa289df4866`.
- Generator output filename: `exec-fe297dad-fd63-4f32-9da9-60d003f8bfa1.png`. Not delivered; the original remains in the tool output directory.
- Decision: The closed-lip warmth is too close to the existing loving portrait, making the two emotion ids less distinct.
- Prompt (full, verbatim):

> Use case: identity-preserve. Asset type: square stage-0 emotion portrait for Stapledon's Voyage dialogue UI. Input image 1 is the accepted portrait_medic_age0_neutral_v2.png, the identity/style reference and EDIT TARGET. Edit this image, do not redraw a different woman. Change ONLY her expression to quiet happiness: a restrained closed-lip smile with clearly lifted mouth corners, slightly raised cheeks and bright smiling eyes. Gentle satisfaction, visibly happier than neutral and distinct from a tender loving gaze. Same woman, about 35. Preserve her exact facial structure, long slightly crooked nose, natural lips, skin tone and facial marks, thick dark wavy hair and escaped strands. Preserve the cream tunic, deep teal folded scarf, coral trim, worn brass fastening and pens in the pocket. Preserve the sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour, original palette and lighting direction. Preserve exact square mid-chest bust crop, head scale, head position, camera angle, pose and eye-line, every hair silhouette and clothing fold as closely as possible, so the image swaps in the same dialogue UI. Native square resolution only, never upscale. Keep genuinely transparent alpha outside the figure, with no scenery, backdrop, gradient, glow, halo, caption, frame, UI, logo or watermark. Keep the original composition; no added headroom or zoom-out. Static game image, no animation.

## portrait_medic_y0_sad.png

- Delivered sha256: `c126b9e11fc34ee2fecb652f192e9381bcebb80ab48bf18b3cc904df4db105ca`
- Generator: OpenAI built-in `image_gen.imagegen`. Model: exact id/version not exposed.
- Date: 2026-10-14. Seed: none exposed.
- Mode: edit of `portrait_medic_age0_neutral_v2.png` (sha256 `93a02944772201d3e854a283342fd189409995e85a91796d5197a9e5f0be0017`).
- Post-processing: none; selected output copied byte-for-byte. Never upscaled.
- Candidates: 2 generated; kept candidate 1. The gently raised inner brow, subdued lids and unsmiling mouth read as sadness while the gaze stays present, distinct from the lowered, inward grieving gaze.

### Candidate 1 — kept

- Native output: 1254 x 1254 RGBA; sha256 `c126b9e11fc34ee2fecb652f192e9381bcebb80ab48bf18b3cc904df4db105ca`.
- Generator output filename: `exec-14442dac-f0e7-457e-97a0-728e4fe48953.png`. Delivered under the section filename.
- Decision: The gently raised inner brow, subdued lids and unsmiling mouth read as sadness while the gaze stays present, distinct from the lowered, inward grieving gaze.
- Prompt (full, verbatim):

> Use case: identity-preserve. Asset type: square stage-0 emotion portrait for Stapledon's Voyage dialogue UI. Input image 1 is the accepted portrait_medic_age0_neutral_v2.png, the identity/style reference and EDIT TARGET. Edit this image, do not redraw a different woman. Change ONLY her expression to ordinary quiet sadness: slightly raised inner brows, heavy lower eyelids, gently downturned closed lips, subdued attention. No tears, no crying; less inward and less deeply bereaved than the grieving portrait. Same woman, about 35. Preserve her exact facial structure, long slightly crooked nose, natural lips, skin tone and facial marks, thick dark wavy hair and escaped strands. Preserve the cream tunic, deep teal folded scarf, coral trim, worn brass fastening and pens in the pocket. Preserve the sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour, original palette and lighting direction. Preserve exact square mid-chest bust crop, head scale, head position, camera angle, pose and eye-line, every hair silhouette and clothing fold as closely as possible, so the image swaps in the same dialogue UI. Native square resolution only, never upscale. Keep genuinely transparent alpha outside the figure, with no scenery, backdrop, gradient, glow, halo, caption, frame, UI, logo or watermark. Keep the original composition; no added headroom or zoom-out. Static game image, no animation.

### Candidate 2 — rejected

- Native output: 1254 x 1254 RGBA; sha256 `a2066f2921bdba0703492a822835532fb201996c4bccc9481a362e6950856b9c`.
- Generator output filename: `exec-9092afd3-1dd6-45e3-b79a-a7c0b221ea05.png`. Not delivered; the original remains in the tool output directory.
- Decision: The more visibly pinched inner brow reads somewhat more as worry, reducing separation from fearful.
- Prompt (full, verbatim):

> Use case: identity-preserve. Asset type: square stage-0 emotion portrait for Stapledon's Voyage dialogue UI. Input image 1 is the accepted portrait_medic_age0_neutral_v2.png, the identity/style reference and EDIT TARGET. Edit this image, do not redraw a different woman. Change ONLY her expression to quiet sadness: a small worried lift at the inner eyebrows, softened lowered eyelids and a modest downward pull at the corners of the closed mouth. A humane disappointed expression, not dramatic sorrow. Same woman, about 35. Preserve her exact facial structure, long slightly crooked nose, natural lips, skin tone and facial marks, thick dark wavy hair and escaped strands. Preserve the cream tunic, deep teal folded scarf, coral trim, worn brass fastening and pens in the pocket. Preserve the sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour, original palette and lighting direction. Preserve exact square mid-chest bust crop, head scale, head position, camera angle, pose and eye-line, every hair silhouette and clothing fold as closely as possible, so the image swaps in the same dialogue UI. Native square resolution only, never upscale. Keep genuinely transparent alpha outside the figure, with no scenery, backdrop, gradient, glow, halo, caption, frame, UI, logo or watermark. Keep the original composition; no added headroom or zoom-out. Static game image, no animation.

## portrait_medic_y0_angry.png

- Delivered sha256: `6800f1c3e89f4989a8b506715e3aed264ea539504fe97a6ed65a2f9b27d8daec`
- Generator: OpenAI built-in `image_gen.imagegen`. Model: exact id/version not exposed.
- Date: 2026-10-14. Seed: none exposed.
- Mode: edit of `portrait_medic_age0_neutral_v2.png` (sha256 `93a02944772201d3e854a283342fd189409995e85a91796d5197a9e5f0be0017`).
- Post-processing: none; selected output copied byte-for-byte. Never upscaled.
- Candidates: 2 generated; kept candidate 2. The sharper knitted brow and steady focused gaze read as controlled displeasure. The mouth stays closed, with no shouting, bared teeth or sneer.

### Candidate 1 — rejected

- Native output: 1254 x 1254 RGBA; sha256 `de43257713ef211cb21bf1aba6acfb54c123c82418eb8b7f1cef76c8d0523623`.
- Generator output filename: `exec-5f704029-9b9d-450f-901d-8e4f1ac76345.png`. Not delivered; the original remains in the tool output directory.
- Decision: The brow tension is softer and the overall expression reads closer to stern concern than controlled anger.
- Prompt (full, verbatim):

> Use case: identity-preserve. Asset type: square stage-0 emotion portrait for Stapledon's Voyage dialogue UI. Input image 1 is the accepted portrait_medic_age0_neutral_v2.png, the identity/style reference and EDIT TARGET. Edit this image, do not redraw a different woman. Change ONLY her expression to controlled anger: eyebrows drawn slightly inward and down, focused narrowed eyes, lips pressed into a firm closed line, subtle tension at the jaw. Steady contained displeasure, no shouting, no bared teeth, no sneer. Same woman, about 35. Preserve her exact facial structure, long slightly crooked nose, natural lips, skin tone and facial marks, thick dark wavy hair and escaped strands. Preserve the cream tunic, deep teal folded scarf, coral trim, worn brass fastening and pens in the pocket. Preserve the sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour, original palette and lighting direction. Preserve exact square mid-chest bust crop, head scale, head position, camera angle, pose and eye-line, every hair silhouette and clothing fold as closely as possible, so the image swaps in the same dialogue UI. Native square resolution only, never upscale. Keep genuinely transparent alpha outside the figure, with no scenery, backdrop, gradient, glow, halo, caption, frame, UI, logo or watermark. Keep the original composition; no added headroom or zoom-out. Static game image, no animation.

### Candidate 2 — kept

- Native output: 1254 x 1254 RGBA; sha256 `6800f1c3e89f4989a8b506715e3aed264ea539504fe97a6ed65a2f9b27d8daec`.
- Generator output filename: `exec-cc0e288f-1b8c-4ae3-bd02-dfef56fe79ef.png`. Delivered under the section filename.
- Decision: The sharper knitted brow and steady focused gaze read as controlled displeasure. The mouth stays closed, with no shouting, bared teeth or sneer.
- Prompt (full, verbatim):

> Use case: identity-preserve. Asset type: square stage-0 emotion portrait for Stapledon's Voyage dialogue UI. Input image 1 is the accepted portrait_medic_age0_neutral_v2.png, the identity/style reference and EDIT TARGET. Edit this image, do not redraw a different woman. Change ONLY her expression to controlled anger: a slight knitted brow, a direct intent gaze along the existing eye-line, subtly tightened eyelids and firmly compressed closed lips. Calm restrained indignation, no shouting, no aggression or caricature. Same woman, about 35. Preserve her exact facial structure, long slightly crooked nose, natural lips, skin tone and facial marks, thick dark wavy hair and escaped strands. Preserve the cream tunic, deep teal folded scarf, coral trim, worn brass fastening and pens in the pocket. Preserve the sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour, original palette and lighting direction. Preserve exact square mid-chest bust crop, head scale, head position, camera angle, pose and eye-line, every hair silhouette and clothing fold as closely as possible, so the image swaps in the same dialogue UI. Native square resolution only, never upscale. Keep genuinely transparent alpha outside the figure, with no scenery, backdrop, gradient, glow, halo, caption, frame, UI, logo or watermark. Keep the original composition; no added headroom or zoom-out. Static game image, no animation.

## portrait_medic_y0_fearful.png

- Delivered sha256: `fd0daac66190895014093d4e9703cd30b70236fe2d277aa1fcd58838d44c3a54`
- Generator: OpenAI built-in `image_gen.imagegen`. Model: exact id/version not exposed.
- Date: 2026-10-14. Seed: none exposed.
- Mode: edit of `portrait_medic_age0_neutral_v2.png` (sha256 `93a02944772201d3e854a283342fd189409995e85a91796d5197a9e5f0be0017`).
- Post-processing: none; selected output copied byte-for-byte. Never upscaled.
- Candidates: 2 generated; kept candidate 1. The wider watchful eyes, raised inner brow and small lip parting convey apprehension, with a clearer distinction from sad than candidate 2.

### Candidate 1 — kept

- Native output: 1254 x 1254 RGBA; sha256 `fd0daac66190895014093d4e9703cd30b70236fe2d277aa1fcd58838d44c3a54`.
- Generator output filename: `exec-007488d6-b858-4ae2-996d-d3772c4ca31d.png`. Delivered under the section filename.
- Decision: The wider watchful eyes, raised inner brow and small lip parting convey apprehension, with a clearer distinction from sad than candidate 2.
- Prompt (full, verbatim):

> Use case: identity-preserve. Asset type: square stage-0 emotion portrait for Stapledon's Voyage dialogue UI. Input image 1 is the accepted portrait_medic_age0_neutral_v2.png, the identity/style reference and EDIT TARGET. Edit this image, do not redraw a different woman. Change ONLY her expression to contained fear: inner brows slightly raised and drawn together, eyes subtly widened without bulging, a faint tension in the lower eyelids, lips very slightly parted as breath catches. Vulnerable apprehension, no screaming, no theatrical panic. Same woman, about 35. Preserve her exact facial structure, long slightly crooked nose, natural lips, skin tone and facial marks, thick dark wavy hair and escaped strands. Preserve the cream tunic, deep teal folded scarf, coral trim, worn brass fastening and pens in the pocket. Preserve the sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour, original palette and lighting direction. Preserve exact square mid-chest bust crop, head scale, head position, camera angle, pose and eye-line, every hair silhouette and clothing fold as closely as possible, so the image swaps in the same dialogue UI. Native square resolution only, never upscale. Keep genuinely transparent alpha outside the figure, with no scenery, backdrop, gradient, glow, halo, caption, frame, UI, logo or watermark. Keep the original composition; no added headroom or zoom-out. Static game image, no animation.

### Candidate 2 — rejected

- Native output: 1254 x 1254 RGBA; sha256 `595e6da00c6204fc4792bac0ae021517b8f607e4af276e7dc1b4f7b94d6abbea`.
- Generator output filename: `exec-544f2fd9-bb0e-4f6f-9de8-237e53725237.png`. Not delivered; the original remains in the tool output directory.
- Decision: The eyelids are less open and the expression is closer to sadness or general worry.
- Prompt (full, verbatim):

> Use case: identity-preserve. Asset type: square stage-0 emotion portrait for Stapledon's Voyage dialogue UI. Input image 1 is the accepted portrait_medic_age0_neutral_v2.png, the identity/style reference and EDIT TARGET. Edit this image, do not redraw a different woman. Change ONLY her expression to quiet apprehension: a modest rise of the inner brows, slightly wider watchful eyes, subtly tense mouth with a tiny parting of the lips. A person sensing danger while trying to stay composed, no exaggerated alarm. Same woman, about 35. Preserve her exact facial structure, long slightly crooked nose, natural lips, skin tone and facial marks, thick dark wavy hair and escaped strands. Preserve the cream tunic, deep teal folded scarf, coral trim, worn brass fastening and pens in the pocket. Preserve the sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour, original palette and lighting direction. Preserve exact square mid-chest bust crop, head scale, head position, camera angle, pose and eye-line, every hair silhouette and clothing fold as closely as possible, so the image swaps in the same dialogue UI. Native square resolution only, never upscale. Keep genuinely transparent alpha outside the figure, with no scenery, backdrop, gradient, glow, halo, caption, frame, UI, logo or watermark. Keep the original composition; no added headroom or zoom-out. Static game image, no animation.

## portrait_medic_y0_curious.png

- Delivered sha256: `254b25bd4e15aad6a211fcfe4f885797f5d8777b2ba92f5f58141ffc3542ec8f`
- Generator: OpenAI built-in `image_gen.imagegen`. Model: exact id/version not exposed.
- Date: 2026-10-14. Seed: none exposed.
- Mode: edit of `portrait_medic_age0_neutral_v2.png` (sha256 `93a02944772201d3e854a283342fd189409995e85a91796d5197a9e5f0be0017`).
- Post-processing: none; selected output copied byte-for-byte. Never upscaled.
- Candidates: 2 generated; kept candidate 2. The asymmetric raised eyebrow and relaxed closed mouth suggest a thoughtful question while staying distinct from fearful.

### Candidate 1 — rejected

- Native output: 1254 x 1254 RGBA; sha256 `87d1f51bc37fbdcdcdedb44990e7647cd6a4bee67c60455d8090a28381dd4c74`.
- Generator output filename: `exec-78850514-9c7f-427d-ac7b-44e0def82869.png`. Not delivered; the original remains in the tool output directory.
- Decision: The slightly parted lips and more open eyes overlap with the chosen fearful expression.
- Prompt (full, verbatim):

> Use case: identity-preserve. Asset type: square stage-0 emotion portrait for Stapledon's Voyage dialogue UI. Input image 1 is the accepted portrait_medic_age0_neutral_v2.png, the identity/style reference and EDIT TARGET. Edit this image, do not redraw a different woman. Change ONLY her expression to quiet curiosity: one eyebrow subtly raised, eyes a little more attentive and open along the same eye-line, lips softly relaxed and slightly parted as if about to ask a thoughtful question. Interested and questioning, no grin, no head tilt. Same woman, about 35. Preserve her exact facial structure, long slightly crooked nose, natural lips, skin tone and facial marks, thick dark wavy hair and escaped strands. Preserve the cream tunic, deep teal folded scarf, coral trim, worn brass fastening and pens in the pocket. Preserve the sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour, original palette and lighting direction. Preserve exact square mid-chest bust crop, head scale, head position, camera angle, pose and eye-line, every hair silhouette and clothing fold as closely as possible, so the image swaps in the same dialogue UI. Native square resolution only, never upscale. Keep genuinely transparent alpha outside the figure, with no scenery, backdrop, gradient, glow, halo, caption, frame, UI, logo or watermark. Keep the original composition; no added headroom or zoom-out. Static game image, no animation.

### Candidate 2 — kept

- Native output: 1254 x 1254 RGBA; sha256 `254b25bd4e15aad6a211fcfe4f885797f5d8777b2ba92f5f58141ffc3542ec8f`.
- Generator output filename: `exec-d15661f0-5a29-41ea-843f-850899f0241e.png`. Delivered under the section filename.
- Decision: The asymmetric raised eyebrow and relaxed closed mouth suggest a thoughtful question while staying distinct from fearful.
- Prompt (full, verbatim):

> Use case: identity-preserve. Asset type: square stage-0 emotion portrait for Stapledon's Voyage dialogue UI. Input image 1 is the accepted portrait_medic_age0_neutral_v2.png, the identity/style reference and EDIT TARGET. Edit this image, do not redraw a different woman. Change ONLY her expression to thoughtful curiosity: a subtle asymmetric eyebrow lift and gently widened attentive eyes, lips softly closed with a tiny thoughtful asymmetry. A receptive questioning look, not surprise, no head tilt. Same woman, about 35. Preserve her exact facial structure, long slightly crooked nose, natural lips, skin tone and facial marks, thick dark wavy hair and escaped strands. Preserve the cream tunic, deep teal folded scarf, coral trim, worn brass fastening and pens in the pocket. Preserve the sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour, original palette and lighting direction. Preserve exact square mid-chest bust crop, head scale, head position, camera angle, pose and eye-line, every hair silhouette and clothing fold as closely as possible, so the image swaps in the same dialogue UI. Native square resolution only, never upscale. Keep genuinely transparent alpha outside the figure, with no scenery, backdrop, gradient, glow, halo, caption, frame, UI, logo or watermark. Keep the original composition; no added headroom or zoom-out. Static game image, no animation.

## portrait_medic_y0_loving.png

- Delivered sha256: `3c23ffe2b657f9045a998ab7416af0bee667a91dbb806f54d09f167172075b29`
- Generator / model: historical values not supplied; no generation in this task.
- Date: re-keyed 2026-10-14; original generation date not supplied. Seed: historical value not supplied.
- Mode: byte-for-byte copy of `portrait_medic_age0_loving_v2.png` (sha256 `3c23ffe2b657f9045a998ab7416af0bee667a91dbb806f54d09f167172075b29`).
- Prompt (full, verbatim): not applicable to this copy operation. Complete historical prompt was not supplied; see source handoff documentation above.
- Post-processing: none; only filename re-keying. Never upscaled.
- Candidates: 0 generated; accepted source retained as instructed.

## portrait_medic_y0_grieving.png

- Delivered sha256: `2a68ffbec262bae0e48607ab097a9f7747a1e2ae085bf91274d4fce15eebb0ca`
- Generator / model: historical values not supplied; no generation in this task.
- Date: re-keyed 2026-10-14; original generation date not supplied. Seed: historical value not supplied.
- Mode: byte-for-byte copy of `portrait_medic_age0_grieving_v2.png` (sha256 `2a68ffbec262bae0e48607ab097a9f7747a1e2ae085bf91274d4fce15eebb0ca`).
- Prompt (full, verbatim): not applicable to this copy operation. Complete historical prompt was not supplied; see source handoff documentation above.
- Post-processing: none; only filename re-keying. Never upscaled.
- Candidates: 0 generated; accepted source retained as instructed.

## Self-check output

RGBA and native dimensions: PASS for all eight. Manifest keys and hashes: PASS. Accepted copies: byte-for-byte PASS. Source pins: PASS for all five inputs. Strict edge-alpha requirement: FAIL (preserved accepted-crop exception).

| File | Size / mode | Alpha max: top / left / right | Empty upper corners |
|---|---|---|---|
| `portrait_medic_y0_neutral.png` | 1254 x 1254 / RGBA | 202 / 255 / 253 | 0 / 1 |
| `portrait_medic_y0_happy.png` | 1254 x 1254 / RGBA | 250 / 253 / 254 | 0 / 0 |
| `portrait_medic_y0_sad.png` | 1254 x 1254 / RGBA | 251 / 253 / 254 | 0 / 0 |
| `portrait_medic_y0_angry.png` | 1254 x 1254 / RGBA | 252 / 253 / 254 | 0 / 0 |
| `portrait_medic_y0_fearful.png` | 1254 x 1254 / RGBA | 246 / 253 / 254 | 0 / 0 |
| `portrait_medic_y0_curious.png` | 1254 x 1254 / RGBA | 252 / 254 / 254 | 0 / 0 |
| `portrait_medic_y0_loving.png` | 1254 x 1254 / RGBA | 247 / 254 / 253 | 0 / 0 |
| `portrait_medic_y0_grieving.png` | 1254 x 1254 / RGBA | 249 / 254 / 253 | 0 / 0 |

No game-code tests run: this batch contains only portrait PNGs, a review image and metadata. No scripts are stored in the repository. Contact-sheet hash and size are recorded in manifest.json; asset hashes are repeated in each section above.
