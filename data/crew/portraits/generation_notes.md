# Crew emotion portraits: engineer, analyst, pilot, counselor (2026-10-28)

Twenty-eight emotion portraits (happy, sad, angry, fearful, curious, loving, grieving for each of four members) for the crew console and the comms station, where faces follow news from home. Approved by Mark on 2026-10-28 ("yeah we can do the crew faces as well"). Art owned by Sunholo. The medic's set already existed (assets/characters/medic, 2026-10-14) and is unchanged; `medic_sad.png` was already shipped (SOURCES row from `portrait_medic_y0_sad.png`), so nothing was generated for the medic.

## Provenance and review limits

- Driver: `env -u OPENAI_API_KEY codex exec -m gpt-6.1-sol --json --skip-git-repo-check --sandbox read-only` (codex-cli 0.164.0, ChatGPT login, no API key), one non-interactive session per candidate. gpt-6.1-sol is the agent model, not the image model.
- Generator: OpenAI built-in `image_gen__imagegen` tool (Codex imagegen). Exact image model id/version: **not exposed by the tool**; none is invented. Seed: none exposed. Every call: `transparent_background: true`, and exactly one reference image, the member's own accepted neutral master (sha256 below), as `referenced_image_paths`. Each prompt asks for an edit of that image changing only the expression.
- References (downloaded from `https://storage.googleapis.com/stapledons-voyage-assets/refs/characters_v1/`, hashes checked against SOURCES before use):
  - engineer: `portrait_engineer_age0_neutral_v1.png` sha256 `c62e29720cf4c1bb0e2aabe16e287c12a90e375b7b5b82f6d740675714129186`
  - analyst: `portrait_analyst_age0_neutral_v1.png` sha256 `e755fc7f3e52f559bb3e7eba91c985a1ea99d0a682e638b6a6ac48d16252453a`
  - pilot: `portrait_pilot_age0_neutral_v1.png` sha256 `f3db1dfa92f5466761549283fc6dfe2fc7d93977bf8a61bda599035e1962cc22`
  - counselor: `portrait_diplomat_age0_neutral_v1.png` sha256 `2674d7162bd3ec0265e2f8a4c2378ca9a75d02f9a8cc1bb4b22e41f8356b8a9e` (the counselor wears the diplomat concept face)
- Prompts mirror the medic set's accepted edit prompts (assets/characters/medic/generation_notes.md): the same identity-preserve frame, with each member's own face and clothing described, and the medic's kept emotion wordings adapted. Variant a is the first try; b and c are retries with stronger wording (c: "must read clearly even at a small thumbnail"). No candidate is an edit of another candidate.
- Prompt check: for every candidate the prompt string passed to `image_gen__imagegen` was extracted from the Codex session rollout (`~/.codex/sessions/.../rollout-*-<thread>.jsonl`) and compared byte for byte with the prompt below: all 39 match, each session made exactly one imagegen call, and each passed only its own reference path.
- Candidate PNGs are byte-for-byte copies of the generator outputs in `~/.codex/generated_images/<thread>/`. Kept masters (`portrait_<face>_age0_<emotion>_v1.png`, `<face>` = diplomat for the counselor) are byte-for-byte copies of the kept candidates (hash checked against the generator output). Every output is native 1254 x 1254 RGBA with transparent background, the neutral's crop and pose.
- Shipped files `<role>_<emotion>.png` are `sips -Z 256` of the master, the same process as the existing files (re-running it on the neutral masters reproduces the shipped neutrals byte for byte). No other post-processing. Never upscaled.
- Masters are **not yet uploaded**; the lead uploads them to `gs://stapledons-voyage-assets/refs/characters_v1/`. They sit in `~/dev/sunholo-data/crew-portraits-work/masters/` until then.
- Review: every candidate was opened and inspected at full frame (768 px view of the whole 1254 px image) for identity (same person, age, hair, clothes, crop), for whether the emotion reads, and for text-like marks. None had text-like marks. Rejections were all "emotion does not read" (too close to the neutral); there was no identity drift. A contact sheet of all 40 shipped portraits (role x emotion, 256 px tiles on mid-grey; headless Godot 4.7.2, no resampling) was reviewed at the end: `crew-portraits-work/contact_sheet.png`.
- **Flagged for review:** `pilot_loving` and `counselor_loving` stay close to their neutrals, both of which already smile warmly in the concept art. Three candidates each (a, b, c) did not move further while keeping identity; the best was kept.

## engineer_happy.png

- Master: `portrait_engineer_age0_happy_v1.png` sha256 `b4ffdbb210bfce56128ba4a3dfb35ee39536d059de3c7edc8081bdf82c7c19b3`; byte-for-byte copy of candidate `c1`.
- Shipped: `engineer_happy.png` (sips -Z 256, 256 x 256) sha256 `61b64abfb2d86352413aa2f12b5601d6f55656300eb7cd7ff8dfc467e80d2536`.
- Date: 2026-10-28. Generator: OpenAI built-in `image_gen__imagegen` via Codex (agent model gpt-6.1-sol). Image model: not exposed. Seed: none exposed.
- Candidates: 1 generated; kept c1.

### Candidate c1: kept

- Native output: 1254 x 1254 RGBA; sha256 `b4ffdbb210bfce56128ba4a3dfb35ee39536d059de3c7edc8081bdf82c7c19b3`. Generator output: `exec-40c7a283-8a67-4426-a6cc-5d4a1289ac2a.png` (Codex thread `01a182f5-b02f-7931-939b-84570cbaa144`).
- Decision: Same woman, hair streaks, freckles, jacket, braces and buckles unchanged; a small warm smile with lifted cheeks and smiling eyes reads clearly as happy without a grin. No text-like marks (the small teal stitch on the right shoulder is in the neutral master).
- Prompt (full, verbatim):

> Use case: identity-preserve. Asset type: square stage-0 emotion portrait for the crew console of Stapledon's Voyage. Input image 1 is the accepted portrait_engineer_age0_neutral_v1.png, the identity/style reference and EDIT TARGET. Edit this image, do not redraw a different woman. Change ONLY her expression to quiet happiness: a small but clearly readable open smile showing only a sliver of upper teeth, lifted mouth corners, softly lifted cheeks and smiling eyes. Warm relief and unforced delight, not laughter, not a broad grin. Same woman, the same age as in the input. Preserve her exact facial structure, weathered fair freckled skin, lined forehead and strong jaw, grey-blue eyes, short tousled grey hair with copper-red streaks swept to one side, and every facial line and mark. Preserve the worn dark olive waxed work jacket with its cream inner collar, the canvas braces with worn brass buckles, every seam and scuff. Preserve the sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour, original palette and lighting direction. Preserve exact square bust crop, head scale, head position, camera angle, pose and eye-line, every hair silhouette and clothing fold as closely as possible, so the image swaps in the same UI. Native square resolution only, never upscale. Keep genuinely transparent alpha outside the figure, with no scenery, backdrop, gradient, glow, halo, caption, frame, UI, logo or watermark. Absolutely no text, letters, numbers, digits or writing anywhere in the image. Keep the original composition; no added headroom or zoom-out. Static game image, no animation.

## engineer_sad.png

- Master: `portrait_engineer_age0_sad_v1.png` sha256 `37cbc6d7da81238c2695b60deb62b92d2633daa51ce4865a4932cc60367f8309`; byte-for-byte copy of candidate `c1`.
- Shipped: `engineer_sad.png` (sips -Z 256, 256 x 256) sha256 `29e7c7a8eebea51f099dca306e55c8e3775b530adb83b5073d9bb78611a0727c`.
- Date: 2026-10-28. Generator: OpenAI built-in `image_gen__imagegen` via Codex (agent model gpt-6.1-sol). Image model: not exposed. Seed: none exposed.
- Candidates: 1 generated; kept c1.

### Candidate c1: kept

- Native output: 1254 x 1254 RGBA; sha256 `37cbc6d7da81238c2695b60deb62b92d2633daa51ce4865a4932cc60367f8309`. Generator output: `exec-7e83e369-f9c4-4244-aed2-1caff9afbb5e.png` (Codex thread `01a182fb-52e0-7cd0-8736-7b365410fb5b`).
- Decision: Same woman and clothing; raised inner brows, heavy lids and downturned closed lips read as ordinary sadness, not grief. No text-like marks.
- Prompt (full, verbatim):

> Use case: identity-preserve. Asset type: square stage-0 emotion portrait for the crew console of Stapledon's Voyage. Input image 1 is the accepted portrait_engineer_age0_neutral_v1.png, the identity/style reference and EDIT TARGET. Edit this image, do not redraw a different woman. Change ONLY her expression to ordinary quiet sadness: slightly raised inner brows, heavy lower eyelids, gently downturned closed lips, subdued attention. No tears, no crying; less inward and less deeply bereaved than grief. Same woman, the same age as in the input. Preserve her exact facial structure, weathered fair freckled skin, lined forehead and strong jaw, grey-blue eyes, short tousled grey hair with copper-red streaks swept to one side, and every facial line and mark. Preserve the worn dark olive waxed work jacket with its cream inner collar, the canvas braces with worn brass buckles, every seam and scuff. Preserve the sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour, original palette and lighting direction. Preserve exact square bust crop, head scale, head position, camera angle, pose and eye-line, every hair silhouette and clothing fold as closely as possible, so the image swaps in the same UI. Native square resolution only, never upscale. Keep genuinely transparent alpha outside the figure, with no scenery, backdrop, gradient, glow, halo, caption, frame, UI, logo or watermark. Absolutely no text, letters, numbers, digits or writing anywhere in the image. Keep the original composition; no added headroom or zoom-out. Static game image, no animation.

## engineer_angry.png

- Master: `portrait_engineer_age0_angry_v1.png` sha256 `d36f522c98e2c5999a1da780484c366f05ce3228e9de5c83731fc8fa8f38428f`; byte-for-byte copy of candidate `c1`.
- Shipped: `engineer_angry.png` (sips -Z 256, 256 x 256) sha256 `09426b5b8a68c988e65e7714fe34ea92582c7ef4f373632484d00bac0dae2c95`.
- Date: 2026-10-28. Generator: OpenAI built-in `image_gen__imagegen` via Codex (agent model gpt-6.1-sol). Image model: not exposed. Seed: none exposed.
- Candidates: 1 generated; kept c1.

### Candidate c1: kept

- Native output: 1254 x 1254 RGBA; sha256 `d36f522c98e2c5999a1da780484c366f05ce3228e9de5c83731fc8fa8f38428f`. Generator output: `exec-e4fe3c2e-0f56-4ae5-b728-5e213c6af28a.png` (Codex thread `01a182fc-604c-7611-865c-403f47ba48fd`).
- Decision: Same woman and clothing; knitted brows, narrowed eyes and a tight mouth read as controlled anger without caricature. No text-like marks.
- Prompt (full, verbatim):

> Use case: identity-preserve. Asset type: square stage-0 emotion portrait for the crew console of Stapledon's Voyage. Input image 1 is the accepted portrait_engineer_age0_neutral_v1.png, the identity/style reference and EDIT TARGET. Edit this image, do not redraw a different woman. Change ONLY her expression to controlled anger: a slight knitted brow, a direct intent gaze along the existing eye-line, subtly tightened eyelids and firmly compressed closed lips. Calm restrained indignation, no shouting, no aggression or caricature. Same woman, the same age as in the input. Preserve her exact facial structure, weathered fair freckled skin, lined forehead and strong jaw, grey-blue eyes, short tousled grey hair with copper-red streaks swept to one side, and every facial line and mark. Preserve the worn dark olive waxed work jacket with its cream inner collar, the canvas braces with worn brass buckles, every seam and scuff. Preserve the sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour, original palette and lighting direction. Preserve exact square bust crop, head scale, head position, camera angle, pose and eye-line, every hair silhouette and clothing fold as closely as possible, so the image swaps in the same UI. Native square resolution only, never upscale. Keep genuinely transparent alpha outside the figure, with no scenery, backdrop, gradient, glow, halo, caption, frame, UI, logo or watermark. Absolutely no text, letters, numbers, digits or writing anywhere in the image. Keep the original composition; no added headroom or zoom-out. Static game image, no animation.

## engineer_fearful.png

- Master: `portrait_engineer_age0_fearful_v1.png` sha256 `a74681431cd0887d0bb486eb90ad12f744de902526d8c7c75cb227692c805a86`; byte-for-byte copy of candidate `c1`.
- Shipped: `engineer_fearful.png` (sips -Z 256, 256 x 256) sha256 `8c773b09c24371e9de17669ade4af12e92afae21dd590e0c8ccfba53a925702f`.
- Date: 2026-10-28. Generator: OpenAI built-in `image_gen__imagegen` via Codex (agent model gpt-6.1-sol). Image model: not exposed. Seed: none exposed.
- Candidates: 1 generated; kept c1.

### Candidate c1: kept

- Native output: 1254 x 1254 RGBA; sha256 `a74681431cd0887d0bb486eb90ad12f744de902526d8c7c75cb227692c805a86`. Generator output: `exec-2bdf69d6-ed89-4bdf-ab47-82de70e2a7f5.png` (Codex thread `01a1830c-22d3-7932-b1df-e708e18bc73a`).
- Decision: Same woman and clothing; raised drawn inner brows, wider eyes and slightly parted lips read as contained fear, not panic. No text-like marks.
- Prompt (full, verbatim):

> Use case: identity-preserve. Asset type: square stage-0 emotion portrait for the crew console of Stapledon's Voyage. Input image 1 is the accepted portrait_engineer_age0_neutral_v1.png, the identity/style reference and EDIT TARGET. Edit this image, do not redraw a different woman. Change ONLY her expression to contained fear: inner brows slightly raised and drawn together, eyes subtly widened without bulging, a faint tension in the lower eyelids, lips very slightly parted as breath catches. Vulnerable apprehension, no screaming, no theatrical panic. Same woman, the same age as in the input. Preserve her exact facial structure, weathered fair freckled skin, lined forehead and strong jaw, grey-blue eyes, short tousled grey hair with copper-red streaks swept to one side, and every facial line and mark. Preserve the worn dark olive waxed work jacket with its cream inner collar, the canvas braces with worn brass buckles, every seam and scuff. Preserve the sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour, original palette and lighting direction. Preserve exact square bust crop, head scale, head position, camera angle, pose and eye-line, every hair silhouette and clothing fold as closely as possible, so the image swaps in the same UI. Native square resolution only, never upscale. Keep genuinely transparent alpha outside the figure, with no scenery, backdrop, gradient, glow, halo, caption, frame, UI, logo or watermark. Absolutely no text, letters, numbers, digits or writing anywhere in the image. Keep the original composition; no added headroom or zoom-out. Static game image, no animation.

## engineer_curious.png

- Master: `portrait_engineer_age0_curious_v1.png` sha256 `e45983e5a4c221e3c4c61fc93e30cbedc5bdc5dee38ecfd082a0437733296944`; byte-for-byte copy of candidate `c2`.
- Shipped: `engineer_curious.png` (sips -Z 256, 256 x 256) sha256 `1ca317d9ef460e0729df767e23bd22c285ea142e5c9ead48c5294c82e4195aaa`.
- Date: 2026-10-28. Generator: OpenAI built-in `image_gen__imagegen` via Codex (agent model gpt-6.1-sol). Image model: not exposed. Seed: none exposed.
- Candidates: 2 generated; kept c2.

### Candidate c1: rejected

- Native output: 1254 x 1254 RGBA; sha256 `0e945b68f77f77cf4d928f6e5c7367273bade091da86be853c367c1e6ea9649b`. Generator output: `exec-a4a57b86-03a4-4165-a069-77683cc63455.png` (Codex thread `01a182fb-52cf-7d81-9d9b-c5617fac81ef`).
- Decision: Identity and clothing hold, but the expression is almost the neutral (a faint brow lift only); curiosity does not read. Regenerated with variant b.
- Prompt (full, verbatim):

> Use case: identity-preserve. Asset type: square stage-0 emotion portrait for the crew console of Stapledon's Voyage. Input image 1 is the accepted portrait_engineer_age0_neutral_v1.png, the identity/style reference and EDIT TARGET. Edit this image, do not redraw a different woman. Change ONLY her expression to thoughtful curiosity: a subtle asymmetric eyebrow lift and gently widened attentive eyes, lips softly closed with a tiny thoughtful asymmetry. A receptive questioning look, not surprise, no head tilt. Same woman, the same age as in the input. Preserve her exact facial structure, weathered fair freckled skin, lined forehead and strong jaw, grey-blue eyes, short tousled grey hair with copper-red streaks swept to one side, and every facial line and mark. Preserve the worn dark olive waxed work jacket with its cream inner collar, the canvas braces with worn brass buckles, every seam and scuff. Preserve the sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour, original palette and lighting direction. Preserve exact square bust crop, head scale, head position, camera angle, pose and eye-line, every hair silhouette and clothing fold as closely as possible, so the image swaps in the same UI. Native square resolution only, never upscale. Keep genuinely transparent alpha outside the figure, with no scenery, backdrop, gradient, glow, halo, caption, frame, UI, logo or watermark. Absolutely no text, letters, numbers, digits or writing anywhere in the image. Keep the original composition; no added headroom or zoom-out. Static game image, no animation.

### Candidate c2: kept

- Native output: 1254 x 1254 RGBA; sha256 `e45983e5a4c221e3c4c61fc93e30cbedc5bdc5dee38ecfd082a0437733296944`. Generator output: `exec-39008154-b5bc-4343-97ec-03494a504df8.png` (Codex thread `01a18304-5076-7281-800f-75e1ae19781a`).
- Decision: Same woman and clothing; one brow clearly raised, attentive eyes and slightly parted lips read as a questioning look, distinct from neutral. No text-like marks.
- Prompt (full, verbatim):

> Use case: identity-preserve. Asset type: square stage-0 emotion portrait for the crew console of Stapledon's Voyage. Input image 1 is the accepted portrait_engineer_age0_neutral_v1.png, the identity/style reference and EDIT TARGET. Edit this image, do not redraw a different woman. Change ONLY her expression to quiet curiosity: one eyebrow clearly raised, eyes a little more attentive and open along the same eye-line, lips softly relaxed and slightly parted as if about to ask a thoughtful question. Interested and questioning, no grin, no head tilt. Same woman, the same age as in the input. Preserve her exact facial structure, weathered fair freckled skin, lined forehead and strong jaw, grey-blue eyes, short tousled grey hair with copper-red streaks swept to one side, and every facial line and mark. Preserve the worn dark olive waxed work jacket with its cream inner collar, the canvas braces with worn brass buckles, every seam and scuff. Preserve the sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour, original palette and lighting direction. Preserve exact square bust crop, head scale, head position, camera angle, pose and eye-line, every hair silhouette and clothing fold as closely as possible, so the image swaps in the same UI. Native square resolution only, never upscale. Keep genuinely transparent alpha outside the figure, with no scenery, backdrop, gradient, glow, halo, caption, frame, UI, logo or watermark. Absolutely no text, letters, numbers, digits or writing anywhere in the image. Keep the original composition; no added headroom or zoom-out. Static game image, no animation.

## engineer_loving.png

- Master: `portrait_engineer_age0_loving_v1.png` sha256 `20075702eb58abd866f2aed55a67c8b9d9b2f3c931dd1780b6a0835bd1d251cd`; byte-for-byte copy of candidate `c1`.
- Shipped: `engineer_loving.png` (sips -Z 256, 256 x 256) sha256 `8cc453e0c03f71cee87813b54f337a63dfdb4609dae5f181f63ac805443fe1fc`.
- Date: 2026-10-28. Generator: OpenAI built-in `image_gen__imagegen` via Codex (agent model gpt-6.1-sol). Image model: not exposed. Seed: none exposed.
- Candidates: 1 generated; kept c1.

### Candidate c1: kept

- Native output: 1254 x 1254 RGBA; sha256 `20075702eb58abd866f2aed55a67c8b9d9b2f3c931dd1780b6a0835bd1d251cd`. Generator output: `exec-a20800a4-89b7-46cd-8a9e-e5df090d91e3.png` (Codex thread `01a18302-ff43-7de3-b2e0-7e30bd507a7b`).
- Decision: Same woman and clothing; a soft closed-lip smile and softened eyes read as tender warmth, distinct from her stern neutral and from the open smile of her happy portrait. No text-like marks.
- Prompt (full, verbatim):

> Use case: identity-preserve. Asset type: square stage-0 emotion portrait for the crew console of Stapledon's Voyage. Input image 1 is the accepted portrait_engineer_age0_neutral_v1.png, the identity/style reference and EDIT TARGET. Edit this image, do not redraw a different woman. Change ONLY her expression to tender loving warmth: a soft gentle closed-lip smile, softened shining eyes full of affection, a relaxed open brow, as if looking at a dear one or remembering family at home. Tender and quiet, distinct from plain happiness, never flirtatious or sentimental. Same woman, the same age as in the input. Preserve her exact facial structure, weathered fair freckled skin, lined forehead and strong jaw, grey-blue eyes, short tousled grey hair with copper-red streaks swept to one side, and every facial line and mark. Preserve the worn dark olive waxed work jacket with its cream inner collar, the canvas braces with worn brass buckles, every seam and scuff. Preserve the sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour, original palette and lighting direction. Preserve exact square bust crop, head scale, head position, camera angle, pose and eye-line, every hair silhouette and clothing fold as closely as possible, so the image swaps in the same UI. Native square resolution only, never upscale. Keep genuinely transparent alpha outside the figure, with no scenery, backdrop, gradient, glow, halo, caption, frame, UI, logo or watermark. Absolutely no text, letters, numbers, digits or writing anywhere in the image. Keep the original composition; no added headroom or zoom-out. Static game image, no animation.

## engineer_grieving.png

- Master: `portrait_engineer_age0_grieving_v1.png` sha256 `27bd59d4749a1f571599bcced88c8b6916a69dce21328405ebdec3a47817c2d3`; byte-for-byte copy of candidate `c1`.
- Shipped: `engineer_grieving.png` (sips -Z 256, 256 x 256) sha256 `fe640739e3e8d4f6516352861d8daeed389175ddc647b17a54c82abd4bdd7a07`.
- Date: 2026-10-28. Generator: OpenAI built-in `image_gen__imagegen` via Codex (agent model gpt-6.1-sol). Image model: not exposed. Seed: none exposed.
- Candidates: 1 generated; kept c1.

### Candidate c1: kept

- Native output: 1254 x 1254 RGBA; sha256 `27bd59d4749a1f571599bcced88c8b6916a69dce21328405ebdec3a47817c2d3`. Generator output: `exec-de4ddbc6-c138-4591-991f-60b7b301656b.png` (Codex thread `01a18315-22e6-7620-8eb9-7fee047a8033`).
- Decision: Same woman and clothing; gaze lowered and turned down, a fragile tension in brow and lids, lips held together; reads as inward grief, heavier than her sad portrait, no tears. No text-like marks.
- Prompt (full, verbatim):

> Use case: identity-preserve. Asset type: square stage-0 emotion portrait for the crew console of Stapledon's Voyage. Input image 1 is the accepted portrait_engineer_age0_neutral_v1.png, the identity/style reference and EDIT TARGET. Edit this image, do not redraw a different woman. Change ONLY her expression to quiet grief: eyes lowered slightly, a fragile tension in the brow and lower eyelids, lips held gently together, a person trying to remain present through loss. Subtle, believable, deeply felt; deeper and more inward than ordinary sadness; no theatrical crying. Same woman, the same age as in the input. Preserve her exact facial structure, weathered fair freckled skin, lined forehead and strong jaw, grey-blue eyes, short tousled grey hair with copper-red streaks swept to one side, and every facial line and mark. Preserve the worn dark olive waxed work jacket with its cream inner collar, the canvas braces with worn brass buckles, every seam and scuff. Preserve the sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour, original palette and lighting direction. Preserve exact square bust crop, head scale, head position, camera angle, pose and eye-line, every hair silhouette and clothing fold as closely as possible, so the image swaps in the same UI. Native square resolution only, never upscale. Keep genuinely transparent alpha outside the figure, with no scenery, backdrop, gradient, glow, halo, caption, frame, UI, logo or watermark. Absolutely no text, letters, numbers, digits or writing anywhere in the image. Keep the original composition; no added headroom or zoom-out. Static game image, no animation.

## analyst_happy.png

- Master: `portrait_analyst_age0_happy_v1.png` sha256 `e51551ff8c62af31e9874cacae5ae9b7b6818d4d7299c92e70909be836dd3e57`; byte-for-byte copy of candidate `c1`.
- Shipped: `analyst_happy.png` (sips -Z 256, 256 x 256) sha256 `456b35dd4ae14950b83aca5a451b20495d5cfeff7e31c21ca03ad9f497d57e3a`.
- Date: 2026-10-28. Generator: OpenAI built-in `image_gen__imagegen` via Codex (agent model gpt-6.1-sol). Image model: not exposed. Seed: none exposed.
- Candidates: 1 generated; kept c1.

### Candidate c1: kept

- Native output: 1254 x 1254 RGBA; sha256 `e51551ff8c62af31e9874cacae5ae9b7b6818d4d7299c92e70909be836dd3e57`. Generator output: `exec-5a77cd33-3e13-43ae-8d1c-3e414b1f76ff.png` (Codex thread `01a182fb-52cb-7170-9021-72d9b832c35f`).
- Decision: Same woman, grey-streaked bob, teal tunic with violet seam unchanged; a gentle smile with a sliver of teeth and lifted cheeks reads as quiet happiness. No text-like marks.
- Prompt (full, verbatim):

> Use case: identity-preserve. Asset type: square stage-0 emotion portrait for the crew console of Stapledon's Voyage. Input image 1 is the accepted portrait_analyst_age0_neutral_v1.png, the identity/style reference and EDIT TARGET. Edit this image, do not redraw a different woman. Change ONLY her expression to quiet happiness: a small but clearly readable open smile showing only a sliver of upper teeth, lifted mouth corners, softly lifted cheeks and smiling eyes. Warm relief and unforced delight, not laughter, not a broad grin. Same woman, the same age as in the input. Preserve her exact facial structure, warm brown skin, dark eyes, long straight nose, natural lips, chin-length straight dark hair heavily streaked with grey and parted to one side, and every facial line and mark. Preserve the muted teal-green tunic with its cream stand collar and the thin violet seam stripe. Preserve the sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour, original palette and lighting direction. Preserve exact square bust crop, head scale, head position, camera angle, pose and eye-line, every hair silhouette and clothing fold as closely as possible, so the image swaps in the same UI. Native square resolution only, never upscale. Keep genuinely transparent alpha outside the figure, with no scenery, backdrop, gradient, glow, halo, caption, frame, UI, logo or watermark. Absolutely no text, letters, numbers, digits or writing anywhere in the image. Keep the original composition; no added headroom or zoom-out. Static game image, no animation.

## analyst_sad.png

- Master: `portrait_analyst_age0_sad_v1.png` sha256 `0b2d937fb53691456a5cb566fca71069d6e098fabc666d09480f0a97d6c703a4`; byte-for-byte copy of candidate `c1`.
- Shipped: `analyst_sad.png` (sips -Z 256, 256 x 256) sha256 `47f1163a83fb5c964bc876882df6f36a415e90a412d285067a16b5a3b5cc15c7`.
- Date: 2026-10-28. Generator: OpenAI built-in `image_gen__imagegen` via Codex (agent model gpt-6.1-sol). Image model: not exposed. Seed: none exposed.
- Candidates: 1 generated; kept c1.

### Candidate c1: kept

- Native output: 1254 x 1254 RGBA; sha256 `0b2d937fb53691456a5cb566fca71069d6e098fabc666d09480f0a97d6c703a4`. Generator output: `exec-9216fa8b-3c36-49b4-9481-36ae6b60eeeb.png` (Codex thread `01a182fc-5e55-7d71-b65e-4747b21daab1`).
- Decision: Same woman and tunic; raised inner brows, heavy lids and downturned mouth read as quiet sadness. No text-like marks.
- Prompt (full, verbatim):

> Use case: identity-preserve. Asset type: square stage-0 emotion portrait for the crew console of Stapledon's Voyage. Input image 1 is the accepted portrait_analyst_age0_neutral_v1.png, the identity/style reference and EDIT TARGET. Edit this image, do not redraw a different woman. Change ONLY her expression to ordinary quiet sadness: slightly raised inner brows, heavy lower eyelids, gently downturned closed lips, subdued attention. No tears, no crying; less inward and less deeply bereaved than grief. Same woman, the same age as in the input. Preserve her exact facial structure, warm brown skin, dark eyes, long straight nose, natural lips, chin-length straight dark hair heavily streaked with grey and parted to one side, and every facial line and mark. Preserve the muted teal-green tunic with its cream stand collar and the thin violet seam stripe. Preserve the sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour, original palette and lighting direction. Preserve exact square bust crop, head scale, head position, camera angle, pose and eye-line, every hair silhouette and clothing fold as closely as possible, so the image swaps in the same UI. Native square resolution only, never upscale. Keep genuinely transparent alpha outside the figure, with no scenery, backdrop, gradient, glow, halo, caption, frame, UI, logo or watermark. Absolutely no text, letters, numbers, digits or writing anywhere in the image. Keep the original composition; no added headroom or zoom-out. Static game image, no animation.

## analyst_angry.png

- Master: `portrait_analyst_age0_angry_v1.png` sha256 `df4ca47284c53958a0f0da381a19f12e05d919e0a2df7ce7d5e536c47265fe9b`; byte-for-byte copy of candidate `c1`.
- Shipped: `analyst_angry.png` (sips -Z 256, 256 x 256) sha256 `59b58c698579179b5e4e22000edf605f894176217a9bd48b7e557537ff3d0565`.
- Date: 2026-10-28. Generator: OpenAI built-in `image_gen__imagegen` via Codex (agent model gpt-6.1-sol). Image model: not exposed. Seed: none exposed.
- Candidates: 1 generated; kept c1.

### Candidate c1: kept

- Native output: 1254 x 1254 RGBA; sha256 `df4ca47284c53958a0f0da381a19f12e05d919e0a2df7ce7d5e536c47265fe9b`. Generator output: `exec-481bcb94-80f7-49a3-a567-3e1b492f3273.png` (Codex thread `01a18302-eb09-7df0-9448-6ecb891b1350`).
- Decision: Same woman and tunic; brows drawn in and down, narrowed eyes and a firm closed mouth read as controlled anger. No text-like marks.
- Prompt (full, verbatim):

> Use case: identity-preserve. Asset type: square stage-0 emotion portrait for the crew console of Stapledon's Voyage. Input image 1 is the accepted portrait_analyst_age0_neutral_v1.png, the identity/style reference and EDIT TARGET. Edit this image, do not redraw a different woman. Change ONLY her expression to controlled anger: a slight knitted brow, a direct intent gaze along the existing eye-line, subtly tightened eyelids and firmly compressed closed lips. Calm restrained indignation, no shouting, no aggression or caricature. Same woman, the same age as in the input. Preserve her exact facial structure, warm brown skin, dark eyes, long straight nose, natural lips, chin-length straight dark hair heavily streaked with grey and parted to one side, and every facial line and mark. Preserve the muted teal-green tunic with its cream stand collar and the thin violet seam stripe. Preserve the sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour, original palette and lighting direction. Preserve exact square bust crop, head scale, head position, camera angle, pose and eye-line, every hair silhouette and clothing fold as closely as possible, so the image swaps in the same UI. Native square resolution only, never upscale. Keep genuinely transparent alpha outside the figure, with no scenery, backdrop, gradient, glow, halo, caption, frame, UI, logo or watermark. Absolutely no text, letters, numbers, digits or writing anywhere in the image. Keep the original composition; no added headroom or zoom-out. Static game image, no animation.

## analyst_fearful.png

- Master: `portrait_analyst_age0_fearful_v1.png` sha256 `0d38c83f5452f424195e132a411d8fdae111e380b990854f45364834ff64ba93`; byte-for-byte copy of candidate `c1`.
- Shipped: `analyst_fearful.png` (sips -Z 256, 256 x 256) sha256 `61840d48afa33570230ae094cc734828112c931580e3732e024a1171bc7dea46`.
- Date: 2026-10-28. Generator: OpenAI built-in `image_gen__imagegen` via Codex (agent model gpt-6.1-sol). Image model: not exposed. Seed: none exposed.
- Candidates: 1 generated; kept c1.

### Candidate c1: kept

- Native output: 1254 x 1254 RGBA; sha256 `0d38c83f5452f424195e132a411d8fdae111e380b990854f45364834ff64ba93`. Generator output: `exec-e93fd7f4-7929-4f28-aa2e-6542ed21437e.png` (Codex thread `01a1830c-175b-7663-bd1d-cde40c81055f`).
- Decision: Same woman and tunic; raised inner brows, watchful eyes and parted lips read as apprehension. No text-like marks.
- Prompt (full, verbatim):

> Use case: identity-preserve. Asset type: square stage-0 emotion portrait for the crew console of Stapledon's Voyage. Input image 1 is the accepted portrait_analyst_age0_neutral_v1.png, the identity/style reference and EDIT TARGET. Edit this image, do not redraw a different woman. Change ONLY her expression to contained fear: inner brows slightly raised and drawn together, eyes subtly widened without bulging, a faint tension in the lower eyelids, lips very slightly parted as breath catches. Vulnerable apprehension, no screaming, no theatrical panic. Same woman, the same age as in the input. Preserve her exact facial structure, warm brown skin, dark eyes, long straight nose, natural lips, chin-length straight dark hair heavily streaked with grey and parted to one side, and every facial line and mark. Preserve the muted teal-green tunic with its cream stand collar and the thin violet seam stripe. Preserve the sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour, original palette and lighting direction. Preserve exact square bust crop, head scale, head position, camera angle, pose and eye-line, every hair silhouette and clothing fold as closely as possible, so the image swaps in the same UI. Native square resolution only, never upscale. Keep genuinely transparent alpha outside the figure, with no scenery, backdrop, gradient, glow, halo, caption, frame, UI, logo or watermark. Absolutely no text, letters, numbers, digits or writing anywhere in the image. Keep the original composition; no added headroom or zoom-out. Static game image, no animation.

## analyst_curious.png

- Master: `portrait_analyst_age0_curious_v1.png` sha256 `ae89cabeccdea725e4f1454e21e394071ac42c5882de6ca381d60015a95ea5bd`; byte-for-byte copy of candidate `c3`.
- Shipped: `analyst_curious.png` (sips -Z 256, 256 x 256) sha256 `21a3d1700d4bdedf411e3a82d90965b0d84a0b75142fbe89b341240236cee14e`.
- Date: 2026-10-28. Generator: OpenAI built-in `image_gen__imagegen` via Codex (agent model gpt-6.1-sol). Image model: not exposed. Seed: none exposed.
- Candidates: 3 generated; kept c3.

### Candidate c1: rejected

- Native output: 1254 x 1254 RGBA; sha256 `bd4e7a7057468969654aa15bdc38fa70fd84fe0c66196840ccb310b4a0ae8efe`. Generator output: `exec-7ea96f88-c8ef-4a64-abd7-42cb627faa26.png` (Codex thread `01a182fb-52cd-7f12-a5db-9000a69f6fa2`).
- Decision: Identity holds, but the expression is barely different from her neutral; curiosity does not read. Regenerated with variant b.
- Prompt (full, verbatim):

> Use case: identity-preserve. Asset type: square stage-0 emotion portrait for the crew console of Stapledon's Voyage. Input image 1 is the accepted portrait_analyst_age0_neutral_v1.png, the identity/style reference and EDIT TARGET. Edit this image, do not redraw a different woman. Change ONLY her expression to thoughtful curiosity: a subtle asymmetric eyebrow lift and gently widened attentive eyes, lips softly closed with a tiny thoughtful asymmetry. A receptive questioning look, not surprise, no head tilt. Same woman, the same age as in the input. Preserve her exact facial structure, warm brown skin, dark eyes, long straight nose, natural lips, chin-length straight dark hair heavily streaked with grey and parted to one side, and every facial line and mark. Preserve the muted teal-green tunic with its cream stand collar and the thin violet seam stripe. Preserve the sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour, original palette and lighting direction. Preserve exact square bust crop, head scale, head position, camera angle, pose and eye-line, every hair silhouette and clothing fold as closely as possible, so the image swaps in the same UI. Native square resolution only, never upscale. Keep genuinely transparent alpha outside the figure, with no scenery, backdrop, gradient, glow, halo, caption, frame, UI, logo or watermark. Absolutely no text, letters, numbers, digits or writing anywhere in the image. Keep the original composition; no added headroom or zoom-out. Static game image, no animation.

### Candidate c2: rejected

- Native output: 1254 x 1254 RGBA; sha256 `bfc0211a4280d891cf3fbd250a35c7d63a97535f6ce7b15a64c795632385f542`. Generator output: `exec-3e382c71-7421-48bd-851d-48bbbd6c8db8.png` (Codex thread `01a18315-76f2-7570-b38a-4c46186889d3`).
- Decision: Identity holds; slightly parted lips and a faint brow lift, better than c1 but still weak. Last retry with the stronger variant c.
- Prompt (full, verbatim):

> Use case: identity-preserve. Asset type: square stage-0 emotion portrait for the crew console of Stapledon's Voyage. Input image 1 is the accepted portrait_analyst_age0_neutral_v1.png, the identity/style reference and EDIT TARGET. Edit this image, do not redraw a different woman. Change ONLY her expression to quiet curiosity: one eyebrow clearly raised, eyes a little more attentive and open along the same eye-line, lips softly relaxed and slightly parted as if about to ask a thoughtful question. Interested and questioning, no grin, no head tilt. Same woman, the same age as in the input. Preserve her exact facial structure, warm brown skin, dark eyes, long straight nose, natural lips, chin-length straight dark hair heavily streaked with grey and parted to one side, and every facial line and mark. Preserve the muted teal-green tunic with its cream stand collar and the thin violet seam stripe. Preserve the sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour, original palette and lighting direction. Preserve exact square bust crop, head scale, head position, camera angle, pose and eye-line, every hair silhouette and clothing fold as closely as possible, so the image swaps in the same UI. Native square resolution only, never upscale. Keep genuinely transparent alpha outside the figure, with no scenery, backdrop, gradient, glow, halo, caption, frame, UI, logo or watermark. Absolutely no text, letters, numbers, digits or writing anywhere in the image. Keep the original composition; no added headroom or zoom-out. Static game image, no animation.

### Candidate c3: kept

- Native output: 1254 x 1254 RGBA; sha256 `ae89cabeccdea725e4f1454e21e394071ac42c5882de6ca381d60015a95ea5bd`. Generator output: `exec-91dbc556-717a-47e0-a283-729e7909ba28.png` (Codex thread `01a18317-17c0-7181-9b93-625532708e9d`).
- Decision: Same woman and tunic; eyes more open and bright, brows lifted and lips parted read as alert interest, clearer than c1 and c2. No text-like marks.
- Prompt (full, verbatim):

> Use case: identity-preserve. Asset type: square stage-0 emotion portrait for the crew console of Stapledon's Voyage. Input image 1 is the accepted portrait_analyst_age0_neutral_v1.png, the identity/style reference and EDIT TARGET. Edit this image, do not redraw a different woman. Change ONLY her expression to open, alert curiosity that must read clearly even at a small thumbnail: one eyebrow raised high while the other stays level, eyes widened and bright with interest, lips parted as if just about to ask a question, any smile in the input removed. Clearly different from the input expression, yet adult and understated; not surprise, not a grin, no head tilt. Same woman, the same age as in the input. Preserve her exact facial structure, warm brown skin, dark eyes, long straight nose, natural lips, chin-length straight dark hair heavily streaked with grey and parted to one side, and every facial line and mark. Preserve the muted teal-green tunic with its cream stand collar and the thin violet seam stripe. Preserve the sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour, original palette and lighting direction. Preserve exact square bust crop, head scale, head position, camera angle, pose and eye-line, every hair silhouette and clothing fold as closely as possible, so the image swaps in the same UI. Native square resolution only, never upscale. Keep genuinely transparent alpha outside the figure, with no scenery, backdrop, gradient, glow, halo, caption, frame, UI, logo or watermark. Absolutely no text, letters, numbers, digits or writing anywhere in the image. Keep the original composition; no added headroom or zoom-out. Static game image, no animation.

## analyst_loving.png

- Master: `portrait_analyst_age0_loving_v1.png` sha256 `98bfdc16f3e2d00e5300c94a741c61c7e55112b51a4886d3ebf3159be247ef6a`; byte-for-byte copy of candidate `c1`.
- Shipped: `analyst_loving.png` (sips -Z 256, 256 x 256) sha256 `d7040e20d0bbe2109171dc63682fdf71c35517f3532f50ac896b37ae305a87ac`.
- Date: 2026-10-28. Generator: OpenAI built-in `image_gen__imagegen` via Codex (agent model gpt-6.1-sol). Image model: not exposed. Seed: none exposed.
- Candidates: 1 generated; kept c1.

### Candidate c1: kept

- Native output: 1254 x 1254 RGBA; sha256 `98bfdc16f3e2d00e5300c94a741c61c7e55112b51a4886d3ebf3159be247ef6a`. Generator output: `exec-31098653-738d-4163-850c-d3eef051ecc2.png` (Codex thread `01a18315-38d2-7770-9f20-8ad3890ac513`).
- Decision: Same woman and tunic; a faint closed-lip smile and softened eyes read as gentle warmth, distinct from her serious neutral and from the open smile of her happy portrait. No text-like marks.
- Prompt (full, verbatim):

> Use case: identity-preserve. Asset type: square stage-0 emotion portrait for the crew console of Stapledon's Voyage. Input image 1 is the accepted portrait_analyst_age0_neutral_v1.png, the identity/style reference and EDIT TARGET. Edit this image, do not redraw a different woman. Change ONLY her expression to tender loving warmth: a soft gentle closed-lip smile, softened shining eyes full of affection, a relaxed open brow, as if looking at a dear one or remembering family at home. Tender and quiet, distinct from plain happiness, never flirtatious or sentimental. Same woman, the same age as in the input. Preserve her exact facial structure, warm brown skin, dark eyes, long straight nose, natural lips, chin-length straight dark hair heavily streaked with grey and parted to one side, and every facial line and mark. Preserve the muted teal-green tunic with its cream stand collar and the thin violet seam stripe. Preserve the sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour, original palette and lighting direction. Preserve exact square bust crop, head scale, head position, camera angle, pose and eye-line, every hair silhouette and clothing fold as closely as possible, so the image swaps in the same UI. Native square resolution only, never upscale. Keep genuinely transparent alpha outside the figure, with no scenery, backdrop, gradient, glow, halo, caption, frame, UI, logo or watermark. Absolutely no text, letters, numbers, digits or writing anywhere in the image. Keep the original composition; no added headroom or zoom-out. Static game image, no animation.

## analyst_grieving.png

- Master: `portrait_analyst_age0_grieving_v1.png` sha256 `a5c15ce69beaf2cf8d9a0d932093ea8fa92463219173bc6e4f66afaa705b3959`; byte-for-byte copy of candidate `c1`.
- Shipped: `analyst_grieving.png` (sips -Z 256, 256 x 256) sha256 `43274253a510ee45345f471988cc1f9366a2b3b61e11e3ffc810ad353f716bbc`.
- Date: 2026-10-28. Generator: OpenAI built-in `image_gen__imagegen` via Codex (agent model gpt-6.1-sol). Image model: not exposed. Seed: none exposed.
- Candidates: 1 generated; kept c1.

### Candidate c1: kept

- Native output: 1254 x 1254 RGBA; sha256 `a5c15ce69beaf2cf8d9a0d932093ea8fa92463219173bc6e4f66afaa705b3959`. Generator output: `exec-3a06aef1-0ad0-4ca1-b0bb-ef23d362dcbb.png` (Codex thread `01a18316-404f-7c73-b3e9-dd610af319b2`).
- Decision: Same woman and tunic; lowered gaze, inner brows drawn up and lips held together read as inward grief, deeper than her sad portrait, no tears. No text-like marks.
- Prompt (full, verbatim):

> Use case: identity-preserve. Asset type: square stage-0 emotion portrait for the crew console of Stapledon's Voyage. Input image 1 is the accepted portrait_analyst_age0_neutral_v1.png, the identity/style reference and EDIT TARGET. Edit this image, do not redraw a different woman. Change ONLY her expression to quiet grief: eyes lowered slightly, a fragile tension in the brow and lower eyelids, lips held gently together, a person trying to remain present through loss. Subtle, believable, deeply felt; deeper and more inward than ordinary sadness; no theatrical crying. Same woman, the same age as in the input. Preserve her exact facial structure, warm brown skin, dark eyes, long straight nose, natural lips, chin-length straight dark hair heavily streaked with grey and parted to one side, and every facial line and mark. Preserve the muted teal-green tunic with its cream stand collar and the thin violet seam stripe. Preserve the sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour, original palette and lighting direction. Preserve exact square bust crop, head scale, head position, camera angle, pose and eye-line, every hair silhouette and clothing fold as closely as possible, so the image swaps in the same UI. Native square resolution only, never upscale. Keep genuinely transparent alpha outside the figure, with no scenery, backdrop, gradient, glow, halo, caption, frame, UI, logo or watermark. Absolutely no text, letters, numbers, digits or writing anywhere in the image. Keep the original composition; no added headroom or zoom-out. Static game image, no animation.

## pilot_happy.png

- Master: `portrait_pilot_age0_happy_v1.png` sha256 `1c0cefec666b238c252d3b3498ea327c02933bc300c1c93d585f1c6ff8848158`; byte-for-byte copy of candidate `c1`.
- Shipped: `pilot_happy.png` (sips -Z 256, 256 x 256) sha256 `1158aaf670f56ca94f061ad15243912fd869cce065e11e13c28216754f090ec6`.
- Date: 2026-10-28. Generator: OpenAI built-in `image_gen__imagegen` via Codex (agent model gpt-6.1-sol). Image model: not exposed. Seed: none exposed.
- Candidates: 1 generated; kept c1.

### Candidate c1: kept

- Native output: 1254 x 1254 RGBA; sha256 `1c0cefec666b238c252d3b3498ea327c02933bc300c1c93d585f1c6ff8848158`. Generator output: `exec-8f82cc68-cfb6-4543-a335-806dfeeb96a8.png` (Codex thread `01a182fb-52cf-7121-9b15-09ca95e78880`).
- Decision: Same man: curls, stubble, coral jacket and teal placket unchanged; an easy smile with a sliver of teeth and smiling eyes reads clearly as happy. No text-like marks.
- Prompt (full, verbatim):

> Use case: identity-preserve. Asset type: square stage-0 emotion portrait for the crew console of Stapledon's Voyage. Input image 1 is the accepted portrait_pilot_age0_neutral_v1.png, the identity/style reference and EDIT TARGET. Edit this image, do not redraw a different man. Change ONLY his expression to quiet happiness: a small but clearly readable open smile showing only a sliver of upper teeth, lifted mouth corners, softly lifted cheeks and smiling eyes. Warm relief and unforced delight, not laughter, not a broad grin. Same man, the same age as in the input. Preserve his exact facial structure, warm olive-tan skin, heavy dark eyebrows, dark brown eyes, short dark stubble beard and moustache, thick curly black hair, and every facial line and mark. Preserve the weathered coral-red jacket with its turned-up collar and chest pocket, the cream open-necked shirt and the teal inner placket with its button. Preserve the sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour, original palette and lighting direction. Preserve exact square bust crop, head scale, head position, camera angle, pose and eye-line, every hair silhouette and clothing fold as closely as possible, so the image swaps in the same UI. Native square resolution only, never upscale. Keep genuinely transparent alpha outside the figure, with no scenery, backdrop, gradient, glow, halo, caption, frame, UI, logo or watermark. Absolutely no text, letters, numbers, digits or writing anywhere in the image. Keep the original composition; no added headroom or zoom-out. Static game image, no animation.

## pilot_sad.png

- Master: `portrait_pilot_age0_sad_v1.png` sha256 `fa468486a735b68559fafb5ef9801af593a8596e01bd048600d6b4b220927059`; byte-for-byte copy of candidate `c1`.
- Shipped: `pilot_sad.png` (sips -Z 256, 256 x 256) sha256 `d34e0e8d6b0c7bb0510c0c931d00f28f7e78bf6b0b2ea3d31fd988a3eea08dc6`.
- Date: 2026-10-28. Generator: OpenAI built-in `image_gen__imagegen` via Codex (agent model gpt-6.1-sol). Image model: not exposed. Seed: none exposed.
- Candidates: 1 generated; kept c1.

### Candidate c1: kept

- Native output: 1254 x 1254 RGBA; sha256 `fa468486a735b68559fafb5ef9801af593a8596e01bd048600d6b4b220927059`. Generator output: `exec-401693c1-1b42-4a95-9c54-88a67fff7338.png` (Codex thread `01a18302-cc30-7a20-81be-4d88f275f7e0`).
- Decision: Same man and jacket; raised inner brows, softened eyes and the smirk replaced by a downturned mouth read as quiet sadness. No text-like marks.
- Prompt (full, verbatim):

> Use case: identity-preserve. Asset type: square stage-0 emotion portrait for the crew console of Stapledon's Voyage. Input image 1 is the accepted portrait_pilot_age0_neutral_v1.png, the identity/style reference and EDIT TARGET. Edit this image, do not redraw a different man. Change ONLY his expression to ordinary quiet sadness: slightly raised inner brows, heavy lower eyelids, gently downturned closed lips, subdued attention. No tears, no crying; less inward and less deeply bereaved than grief. Same man, the same age as in the input. Preserve his exact facial structure, warm olive-tan skin, heavy dark eyebrows, dark brown eyes, short dark stubble beard and moustache, thick curly black hair, and every facial line and mark. Preserve the weathered coral-red jacket with its turned-up collar and chest pocket, the cream open-necked shirt and the teal inner placket with its button. Preserve the sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour, original palette and lighting direction. Preserve exact square bust crop, head scale, head position, camera angle, pose and eye-line, every hair silhouette and clothing fold as closely as possible, so the image swaps in the same UI. Native square resolution only, never upscale. Keep genuinely transparent alpha outside the figure, with no scenery, backdrop, gradient, glow, halo, caption, frame, UI, logo or watermark. Absolutely no text, letters, numbers, digits or writing anywhere in the image. Keep the original composition; no added headroom or zoom-out. Static game image, no animation.

## pilot_angry.png

- Master: `portrait_pilot_age0_angry_v1.png` sha256 `521ddcaee6932a72c22006f91ea0442eb2a427951b056f37a78282e73132dcfc`; byte-for-byte copy of candidate `c1`.
- Shipped: `pilot_angry.png` (sips -Z 256, 256 x 256) sha256 `578f03ade124fcc364ee8a79799e24a9bdbceae1dc72e6f63a4f29f8f2e4e321`.
- Date: 2026-10-28. Generator: OpenAI built-in `image_gen__imagegen` via Codex (agent model gpt-6.1-sol). Image model: not exposed. Seed: none exposed.
- Candidates: 1 generated; kept c1.

### Candidate c1: kept

- Native output: 1254 x 1254 RGBA; sha256 `521ddcaee6932a72c22006f91ea0442eb2a427951b056f37a78282e73132dcfc`. Generator output: `exec-cd4c8a72-c06e-49fb-ad95-ec1eda8d7fdf.png` (Codex thread `01a1830c-21eb-7cb1-878c-eca898958a66`).
- Decision: Same man and jacket; heavy brows pulled down, narrowed eyes and a set jaw read clearly as anger, restrained, no sneer. No text-like marks.
- Prompt (full, verbatim):

> Use case: identity-preserve. Asset type: square stage-0 emotion portrait for the crew console of Stapledon's Voyage. Input image 1 is the accepted portrait_pilot_age0_neutral_v1.png, the identity/style reference and EDIT TARGET. Edit this image, do not redraw a different man. Change ONLY his expression to controlled anger: a slight knitted brow, a direct intent gaze along the existing eye-line, subtly tightened eyelids and firmly compressed closed lips. Calm restrained indignation, no shouting, no aggression or caricature. Same man, the same age as in the input. Preserve his exact facial structure, warm olive-tan skin, heavy dark eyebrows, dark brown eyes, short dark stubble beard and moustache, thick curly black hair, and every facial line and mark. Preserve the weathered coral-red jacket with its turned-up collar and chest pocket, the cream open-necked shirt and the teal inner placket with its button. Preserve the sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour, original palette and lighting direction. Preserve exact square bust crop, head scale, head position, camera angle, pose and eye-line, every hair silhouette and clothing fold as closely as possible, so the image swaps in the same UI. Native square resolution only, never upscale. Keep genuinely transparent alpha outside the figure, with no scenery, backdrop, gradient, glow, halo, caption, frame, UI, logo or watermark. Absolutely no text, letters, numbers, digits or writing anywhere in the image. Keep the original composition; no added headroom or zoom-out. Static game image, no animation.

## pilot_fearful.png

- Master: `portrait_pilot_age0_fearful_v1.png` sha256 `c754f4dfb26710ae3712e9d550f4b8144ece58dd7d41b434f9d13b8e1ca70db2`; byte-for-byte copy of candidate `c1`.
- Shipped: `pilot_fearful.png` (sips -Z 256, 256 x 256) sha256 `500d4aae819c8d62be848f14ad0e5635258a2df4ff7f99692ca69ad8195cf3db`.
- Date: 2026-10-28. Generator: OpenAI built-in `image_gen__imagegen` via Codex (agent model gpt-6.1-sol). Image model: not exposed. Seed: none exposed.
- Candidates: 1 generated; kept c1.

### Candidate c1: kept

- Native output: 1254 x 1254 RGBA; sha256 `c754f4dfb26710ae3712e9d550f4b8144ece58dd7d41b434f9d13b8e1ca70db2`. Generator output: `exec-468826dd-1ae7-4d1b-9b26-4ffd08120e2e.png` (Codex thread `01a1830d-0558-7e53-96fc-7b13c65e757d`).
- Decision: Same man and jacket; inner brows raised and drawn together, wider eyes and parted lips read as worry (console word for fearful). Close to his curious c2 at full size but distinguishable by the pinched symmetric brow; checked again on the contact sheet. No text-like marks.
- Prompt (full, verbatim):

> Use case: identity-preserve. Asset type: square stage-0 emotion portrait for the crew console of Stapledon's Voyage. Input image 1 is the accepted portrait_pilot_age0_neutral_v1.png, the identity/style reference and EDIT TARGET. Edit this image, do not redraw a different man. Change ONLY his expression to contained fear: inner brows slightly raised and drawn together, eyes subtly widened without bulging, a faint tension in the lower eyelids, lips very slightly parted as breath catches. Vulnerable apprehension, no screaming, no theatrical panic. Same man, the same age as in the input. Preserve his exact facial structure, warm olive-tan skin, heavy dark eyebrows, dark brown eyes, short dark stubble beard and moustache, thick curly black hair, and every facial line and mark. Preserve the weathered coral-red jacket with its turned-up collar and chest pocket, the cream open-necked shirt and the teal inner placket with its button. Preserve the sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour, original palette and lighting direction. Preserve exact square bust crop, head scale, head position, camera angle, pose and eye-line, every hair silhouette and clothing fold as closely as possible, so the image swaps in the same UI. Native square resolution only, never upscale. Keep genuinely transparent alpha outside the figure, with no scenery, backdrop, gradient, glow, halo, caption, frame, UI, logo or watermark. Absolutely no text, letters, numbers, digits or writing anywhere in the image. Keep the original composition; no added headroom or zoom-out. Static game image, no animation.

## pilot_curious.png

- Master: `portrait_pilot_age0_curious_v1.png` sha256 `79f562bfe58f44a229b443ce5656a0d3449704b809712bd9aa3a1354696bded0`; byte-for-byte copy of candidate `c2`.
- Shipped: `pilot_curious.png` (sips -Z 256, 256 x 256) sha256 `e540fa1e8d60ceda1a0c3d58918eb2a454ca4c96e0a7cd41cc68f05ea983b6a4`.
- Date: 2026-10-28. Generator: OpenAI built-in `image_gen__imagegen` via Codex (agent model gpt-6.1-sol). Image model: not exposed. Seed: none exposed.
- Candidates: 2 generated; kept c2.

### Candidate c1: rejected

- Native output: 1254 x 1254 RGBA; sha256 `82629fcd1debcbf23e42622cfcf1abf859926c6fe383a83f2c06727ae4f8fdbe`. Generator output: `exec-52fa95ae-14d9-4ccb-88e1-8a7d9afa2ec6.png` (Codex thread `01a182fb-52cd-7920-9a6d-2743ffe0666d`).
- Decision: Identity holds; a raised brow over a faint smirk reads as a sly intrigued look too close to his neutral. Regenerated with variant b; c2 reads more clearly.
- Prompt (full, verbatim):

> Use case: identity-preserve. Asset type: square stage-0 emotion portrait for the crew console of Stapledon's Voyage. Input image 1 is the accepted portrait_pilot_age0_neutral_v1.png, the identity/style reference and EDIT TARGET. Edit this image, do not redraw a different man. Change ONLY his expression to thoughtful curiosity: a subtle asymmetric eyebrow lift and gently widened attentive eyes, lips softly closed with a tiny thoughtful asymmetry. A receptive questioning look, not surprise, no head tilt. Same man, the same age as in the input. Preserve his exact facial structure, warm olive-tan skin, heavy dark eyebrows, dark brown eyes, short dark stubble beard and moustache, thick curly black hair, and every facial line and mark. Preserve the weathered coral-red jacket with its turned-up collar and chest pocket, the cream open-necked shirt and the teal inner placket with its button. Preserve the sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour, original palette and lighting direction. Preserve exact square bust crop, head scale, head position, camera angle, pose and eye-line, every hair silhouette and clothing fold as closely as possible, so the image swaps in the same UI. Native square resolution only, never upscale. Keep genuinely transparent alpha outside the figure, with no scenery, backdrop, gradient, glow, halo, caption, frame, UI, logo or watermark. Absolutely no text, letters, numbers, digits or writing anywhere in the image. Keep the original composition; no added headroom or zoom-out. Static game image, no animation.

### Candidate c2: kept

- Native output: 1254 x 1254 RGBA; sha256 `79f562bfe58f44a229b443ce5656a0d3449704b809712bd9aa3a1354696bded0`. Generator output: `exec-fbd28b02-b240-4d7b-992b-16821941b8e6.png` (Codex thread `01a1830c-69a9-79d3-9418-7d0f54419f1b`).
- Decision: Same man and jacket; one brow clearly raised, attentive eyes and slightly parted lips read as a questioning look, distinct from neutral and happy. No text-like marks.
- Prompt (full, verbatim):

> Use case: identity-preserve. Asset type: square stage-0 emotion portrait for the crew console of Stapledon's Voyage. Input image 1 is the accepted portrait_pilot_age0_neutral_v1.png, the identity/style reference and EDIT TARGET. Edit this image, do not redraw a different man. Change ONLY his expression to quiet curiosity: one eyebrow clearly raised, eyes a little more attentive and open along the same eye-line, lips softly relaxed and slightly parted as if about to ask a thoughtful question. Interested and questioning, no grin, no head tilt. Same man, the same age as in the input. Preserve his exact facial structure, warm olive-tan skin, heavy dark eyebrows, dark brown eyes, short dark stubble beard and moustache, thick curly black hair, and every facial line and mark. Preserve the weathered coral-red jacket with its turned-up collar and chest pocket, the cream open-necked shirt and the teal inner placket with its button. Preserve the sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour, original palette and lighting direction. Preserve exact square bust crop, head scale, head position, camera angle, pose and eye-line, every hair silhouette and clothing fold as closely as possible, so the image swaps in the same UI. Native square resolution only, never upscale. Keep genuinely transparent alpha outside the figure, with no scenery, backdrop, gradient, glow, halo, caption, frame, UI, logo or watermark. Absolutely no text, letters, numbers, digits or writing anywhere in the image. Keep the original composition; no added headroom or zoom-out. Static game image, no animation.

## pilot_loving.png

- Master: `portrait_pilot_age0_loving_v1.png` sha256 `5d778bbec1b14478746c15fb88553d58bfcf5880d6ec98cf5900f37a62a925c0`; byte-for-byte copy of candidate `c3`.
- Shipped: `pilot_loving.png` (sips -Z 256, 256 x 256) sha256 `dbc3e5d4cc0ae68b8d678ddbead7f28023ea4eda3ad867207b9f7b0c2fb4845e`.
- Date: 2026-10-28. Generator: OpenAI built-in `image_gen__imagegen` via Codex (agent model gpt-6.1-sol). Image model: not exposed. Seed: none exposed.
- Candidates: 3 generated; kept c3.

### Candidate c1: rejected

- Native output: 1254 x 1254 RGBA; sha256 `98ef1456742142f7b8c230bbbd04e38d9fc6c9cf9c25126ae94ff4230f7ab2d4`. Generator output: `exec-db63a7af-6896-4a2d-81a6-00b980469da4.png` (Codex thread `01a1830c-1ce8-7b93-88fc-cbf737988990`).
- Decision: Identity holds, but the soft smile is too close to his smirking neutral; loving does not read as its own emotion. Regenerated with variant b.
- Prompt (full, verbatim):

> Use case: identity-preserve. Asset type: square stage-0 emotion portrait for the crew console of Stapledon's Voyage. Input image 1 is the accepted portrait_pilot_age0_neutral_v1.png, the identity/style reference and EDIT TARGET. Edit this image, do not redraw a different man. Change ONLY his expression to tender loving warmth: a soft gentle closed-lip smile, softened shining eyes full of affection, a relaxed open brow, as if looking at a dear one or remembering family at home. Tender and quiet, distinct from plain happiness, never flirtatious or sentimental. Same man, the same age as in the input. Preserve his exact facial structure, warm olive-tan skin, heavy dark eyebrows, dark brown eyes, short dark stubble beard and moustache, thick curly black hair, and every facial line and mark. Preserve the weathered coral-red jacket with its turned-up collar and chest pocket, the cream open-necked shirt and the teal inner placket with its button. Preserve the sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour, original palette and lighting direction. Preserve exact square bust crop, head scale, head position, camera angle, pose and eye-line, every hair silhouette and clothing fold as closely as possible, so the image swaps in the same UI. Native square resolution only, never upscale. Keep genuinely transparent alpha outside the figure, with no scenery, backdrop, gradient, glow, halo, caption, frame, UI, logo or watermark. Absolutely no text, letters, numbers, digits or writing anywhere in the image. Keep the original composition; no added headroom or zoom-out. Static game image, no animation.

### Candidate c2: rejected

- Native output: 1254 x 1254 RGBA; sha256 `9f3876935bcc0e2ba89887c16b263a63edab0e695da72d0b0bf408b70ef8b782`. Generator output: `exec-08394e05-9498-46d2-a31a-d9d8e795f2b6.png` (Codex thread `01a1830d-737e-7da0-94b5-ef69b9fad6ec`).
- Decision: Identity holds, but nearly identical to c1 and to his neutral. Last retry with the stronger variant c.
- Prompt (full, verbatim):

> Use case: identity-preserve. Asset type: square stage-0 emotion portrait for the crew console of Stapledon's Voyage. Input image 1 is the accepted portrait_pilot_age0_neutral_v1.png, the identity/style reference and EDIT TARGET. Edit this image, do not redraw a different man. Change ONLY his expression to tender affection: a small soft closed-lip smile, gentle half-lowered eyelids, warm softened eyes and a relaxed brow, the look of someone thinking of a person they love far away. Tender, calm and adult, distinct from plain happiness, never flirtatious. Same man, the same age as in the input. Preserve his exact facial structure, warm olive-tan skin, heavy dark eyebrows, dark brown eyes, short dark stubble beard and moustache, thick curly black hair, and every facial line and mark. Preserve the weathered coral-red jacket with its turned-up collar and chest pocket, the cream open-necked shirt and the teal inner placket with its button. Preserve the sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour, original palette and lighting direction. Preserve exact square bust crop, head scale, head position, camera angle, pose and eye-line, every hair silhouette and clothing fold as closely as possible, so the image swaps in the same UI. Native square resolution only, never upscale. Keep genuinely transparent alpha outside the figure, with no scenery, backdrop, gradient, glow, halo, caption, frame, UI, logo or watermark. Absolutely no text, letters, numbers, digits or writing anywhere in the image. Keep the original composition; no added headroom or zoom-out. Static game image, no animation.

### Candidate c3: kept

- Native output: 1254 x 1254 RGBA; sha256 `5d778bbec1b14478746c15fb88553d58bfcf5880d6ec98cf5900f37a62a925c0`. Generator output: `exec-8bd0fc39-73ad-4d22-adb3-6f3299b84ea8.png` (Codex thread `01a18317-17da-7131-b6ad-588e402d4086`).
- Decision: (flagged) Best of three by a small margin (slightly softer eyes); same man and jacket. All three loving candidates stay very close to his neutral, which already carries a soft half-smile; the generator would not move further while preserving identity. Retries exhausted, flagged for review. No text-like marks.
- Prompt (full, verbatim):

> Use case: identity-preserve. Asset type: square stage-0 emotion portrait for the crew console of Stapledon's Voyage. Input image 1 is the accepted portrait_pilot_age0_neutral_v1.png, the identity/style reference and EDIT TARGET. Edit this image, do not redraw a different man. Change ONLY his expression to deep tender love that must read clearly even at a small thumbnail and look clearly different from the input expression: eyelids softly half-lowered, eyes glistening with warm affection, eyebrows gently lifted at the centre, a small closed-lip tender smile, the whole face softened as if gazing at a picture of someone dear who is far away. Adult and quiet; not a grin, not flirtatious, no tears falling. Same man, the same age as in the input. Preserve his exact facial structure, warm olive-tan skin, heavy dark eyebrows, dark brown eyes, short dark stubble beard and moustache, thick curly black hair, and every facial line and mark. Preserve the weathered coral-red jacket with its turned-up collar and chest pocket, the cream open-necked shirt and the teal inner placket with its button. Preserve the sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour, original palette and lighting direction. Preserve exact square bust crop, head scale, head position, camera angle, pose and eye-line, every hair silhouette and clothing fold as closely as possible, so the image swaps in the same UI. Native square resolution only, never upscale. Keep genuinely transparent alpha outside the figure, with no scenery, backdrop, gradient, glow, halo, caption, frame, UI, logo or watermark. Absolutely no text, letters, numbers, digits or writing anywhere in the image. Keep the original composition; no added headroom or zoom-out. Static game image, no animation.

## pilot_grieving.png

- Master: `portrait_pilot_age0_grieving_v1.png` sha256 `637eb9a698fac3e54d4d3a078c547a62da37d7798e18acc9630a9747c10a840b`; byte-for-byte copy of candidate `c1`.
- Shipped: `pilot_grieving.png` (sips -Z 256, 256 x 256) sha256 `d5baab945686216950df653d92ce29ce1a17b73f7306286768c92843a44a9551`.
- Date: 2026-10-28. Generator: OpenAI built-in `image_gen__imagegen` via Codex (agent model gpt-6.1-sol). Image model: not exposed. Seed: none exposed.
- Candidates: 1 generated; kept c1.

### Candidate c1: kept

- Native output: 1254 x 1254 RGBA; sha256 `637eb9a698fac3e54d4d3a078c547a62da37d7798e18acc9630a9747c10a840b`. Generator output: `exec-cac146e3-715f-4f06-918f-b2751639fcd0.png` (Codex thread `01a1830d-0f0e-7d60-9dc4-dc9f12c9550e`).
- Decision: Same man and jacket; gaze lowered, inner brows drawn up, mouth set and the smirk gone; reads as inward grief, deeper than his sad portrait, no tears. No text-like marks.
- Prompt (full, verbatim):

> Use case: identity-preserve. Asset type: square stage-0 emotion portrait for the crew console of Stapledon's Voyage. Input image 1 is the accepted portrait_pilot_age0_neutral_v1.png, the identity/style reference and EDIT TARGET. Edit this image, do not redraw a different man. Change ONLY his expression to quiet grief: eyes lowered slightly, a fragile tension in the brow and lower eyelids, lips held gently together, a person trying to remain present through loss. Subtle, believable, deeply felt; deeper and more inward than ordinary sadness; no theatrical crying. Same man, the same age as in the input. Preserve his exact facial structure, warm olive-tan skin, heavy dark eyebrows, dark brown eyes, short dark stubble beard and moustache, thick curly black hair, and every facial line and mark. Preserve the weathered coral-red jacket with its turned-up collar and chest pocket, the cream open-necked shirt and the teal inner placket with its button. Preserve the sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour, original palette and lighting direction. Preserve exact square bust crop, head scale, head position, camera angle, pose and eye-line, every hair silhouette and clothing fold as closely as possible, so the image swaps in the same UI. Native square resolution only, never upscale. Keep genuinely transparent alpha outside the figure, with no scenery, backdrop, gradient, glow, halo, caption, frame, UI, logo or watermark. Absolutely no text, letters, numbers, digits or writing anywhere in the image. Keep the original composition; no added headroom or zoom-out. Static game image, no animation.

## counselor_happy.png

- Master: `portrait_diplomat_age0_happy_v1.png` sha256 `f24e2a78acb3f7833ed9617563f3046fb0016ccd444e53fe653a67ecd585b3c1`; byte-for-byte copy of candidate `c1`.
- Shipped: `counselor_happy.png` (sips -Z 256, 256 x 256) sha256 `dd56e165dff4d53ab73343ee9cf3eefac144e04ba9f4c5238e739d073f9aa444`.
- Date: 2026-10-28. Generator: OpenAI built-in `image_gen__imagegen` via Codex (agent model gpt-6.1-sol). Image model: not exposed. Seed: none exposed.
- Candidates: 1 generated; kept c1.

### Candidate c1: kept

- Native output: 1254 x 1254 RGBA; sha256 `f24e2a78acb3f7833ed9617563f3046fb0016ccd444e53fe653a67ecd585b3c1`. Generator output: `exec-19736af3-dcde-4147-9c14-ac069732e9e0.png` (Codex thread `01a182fb-52cb-7382-ba6b-a82d0ef79f5a`).
- Decision: Same woman: grey curls, violet robe, cream scarf, brass clasp unchanged; a fuller smile with teeth and lifted cheeks, clearly happier than her already warm neutral. No text-like marks.
- Prompt (full, verbatim):

> Use case: identity-preserve. Asset type: square stage-0 emotion portrait for the crew console of Stapledon's Voyage. Input image 1 is the accepted portrait_diplomat_age0_neutral_v1.png, the identity/style reference and EDIT TARGET. Edit this image, do not redraw a different woman. Change ONLY her expression to quiet happiness: a small but clearly readable open smile showing only a sliver of upper teeth, lifted mouth corners, softly lifted cheeks and smiling eyes. Warm relief and unforced delight, not laughter, not a broad grin. Same woman, the same age as in the input. Preserve her exact facial structure, deep brown skin, dark eyes, broad warm face, natural lips, short tightly curled grey hair, and every facial line and mark. Preserve the deep violet layered wrap robe with its ochre trim, the cream scarf at the neck and the round brass clasp. Preserve the sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour, original palette and lighting direction. Preserve exact square bust crop, head scale, head position, camera angle, pose and eye-line, every hair silhouette and clothing fold as closely as possible, so the image swaps in the same UI. Native square resolution only, never upscale. Keep genuinely transparent alpha outside the figure, with no scenery, backdrop, gradient, glow, halo, caption, frame, UI, logo or watermark. Absolutely no text, letters, numbers, digits or writing anywhere in the image. Keep the original composition; no added headroom or zoom-out. Static game image, no animation.

## counselor_sad.png

- Master: `portrait_diplomat_age0_sad_v1.png` sha256 `4c09dd11b012abf16ac16f9d2dd0ac44698e5964675caffeda0f9da91f7ceee0`; byte-for-byte copy of candidate `c1`.
- Shipped: `counselor_sad.png` (sips -Z 256, 256 x 256) sha256 `1cd66d47fd8950788e722905a2d17610accf10c95f1b2fdb6538a7e9c990e3ff`.
- Date: 2026-10-28. Generator: OpenAI built-in `image_gen__imagegen` via Codex (agent model gpt-6.1-sol). Image model: not exposed. Seed: none exposed.
- Candidates: 1 generated; kept c1.

### Candidate c1: kept

- Native output: 1254 x 1254 RGBA; sha256 `4c09dd11b012abf16ac16f9d2dd0ac44698e5964675caffeda0f9da91f7ceee0`. Generator output: `exec-fdc4b9ff-0df5-4f19-8a12-7c76e576015b.png` (Codex thread `01a18302-dd80-7fd0-8939-988ccbe0f1ab`).
- Decision: Same woman and robe; the neutral's smile is gone, inner brows lift and the mouth turns down; reads as sadness. No text-like marks.
- Prompt (full, verbatim):

> Use case: identity-preserve. Asset type: square stage-0 emotion portrait for the crew console of Stapledon's Voyage. Input image 1 is the accepted portrait_diplomat_age0_neutral_v1.png, the identity/style reference and EDIT TARGET. Edit this image, do not redraw a different woman. Change ONLY her expression to ordinary quiet sadness: slightly raised inner brows, heavy lower eyelids, gently downturned closed lips, subdued attention. No tears, no crying; less inward and less deeply bereaved than grief. Same woman, the same age as in the input. Preserve her exact facial structure, deep brown skin, dark eyes, broad warm face, natural lips, short tightly curled grey hair, and every facial line and mark. Preserve the deep violet layered wrap robe with its ochre trim, the cream scarf at the neck and the round brass clasp. Preserve the sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour, original palette and lighting direction. Preserve exact square bust crop, head scale, head position, camera angle, pose and eye-line, every hair silhouette and clothing fold as closely as possible, so the image swaps in the same UI. Native square resolution only, never upscale. Keep genuinely transparent alpha outside the figure, with no scenery, backdrop, gradient, glow, halo, caption, frame, UI, logo or watermark. Absolutely no text, letters, numbers, digits or writing anywhere in the image. Keep the original composition; no added headroom or zoom-out. Static game image, no animation.

## counselor_angry.png

- Master: `portrait_diplomat_age0_angry_v1.png` sha256 `cdfbcd8bc44d37879584eafd5dd24c8622dfe791dda11ee0aa63086008a9a786`; byte-for-byte copy of candidate `c1`.
- Shipped: `counselor_angry.png` (sips -Z 256, 256 x 256) sha256 `17bbff94aae32cbb2c8caaf9857c6c5f090428300e2bef267d643ea9a0f177e8`.
- Date: 2026-10-28. Generator: OpenAI built-in `image_gen__imagegen` via Codex (agent model gpt-6.1-sol). Image model: not exposed. Seed: none exposed.
- Candidates: 1 generated; kept c1.

### Candidate c1: kept

- Native output: 1254 x 1254 RGBA; sha256 `cdfbcd8bc44d37879584eafd5dd24c8622dfe791dda11ee0aa63086008a9a786`. Generator output: `exec-827a659f-4385-4fcb-96cf-3df92f35b90d.png` (Codex thread `01a18303-bdec-7d00-94d5-8f8cf3a881f3`).
- Decision: Same woman and robe; knitted brow, narrowed eyes and firmly pressed lips read as contained displeasure, understated but no longer the neutral's smile. No text-like marks.
- Prompt (full, verbatim):

> Use case: identity-preserve. Asset type: square stage-0 emotion portrait for the crew console of Stapledon's Voyage. Input image 1 is the accepted portrait_diplomat_age0_neutral_v1.png, the identity/style reference and EDIT TARGET. Edit this image, do not redraw a different woman. Change ONLY her expression to controlled anger: a slight knitted brow, a direct intent gaze along the existing eye-line, subtly tightened eyelids and firmly compressed closed lips. Calm restrained indignation, no shouting, no aggression or caricature. Same woman, the same age as in the input. Preserve her exact facial structure, deep brown skin, dark eyes, broad warm face, natural lips, short tightly curled grey hair, and every facial line and mark. Preserve the deep violet layered wrap robe with its ochre trim, the cream scarf at the neck and the round brass clasp. Preserve the sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour, original palette and lighting direction. Preserve exact square bust crop, head scale, head position, camera angle, pose and eye-line, every hair silhouette and clothing fold as closely as possible, so the image swaps in the same UI. Native square resolution only, never upscale. Keep genuinely transparent alpha outside the figure, with no scenery, backdrop, gradient, glow, halo, caption, frame, UI, logo or watermark. Absolutely no text, letters, numbers, digits or writing anywhere in the image. Keep the original composition; no added headroom or zoom-out. Static game image, no animation.

## counselor_fearful.png

- Master: `portrait_diplomat_age0_fearful_v1.png` sha256 `b2f3c57bb26b92ca5732364fd905d3b8e4572fc2e9e5b741207e9335460b38e0`; byte-for-byte copy of candidate `c1`.
- Shipped: `counselor_fearful.png` (sips -Z 256, 256 x 256) sha256 `642a41cd2245466b82c86301cee17fceb7d3ea538bcd625154656c352f775094`.
- Date: 2026-10-28. Generator: OpenAI built-in `image_gen__imagegen` via Codex (agent model gpt-6.1-sol). Image model: not exposed. Seed: none exposed.
- Candidates: 1 generated; kept c1.

### Candidate c1: kept

- Native output: 1254 x 1254 RGBA; sha256 `b2f3c57bb26b92ca5732364fd905d3b8e4572fc2e9e5b741207e9335460b38e0`. Generator output: `exec-3f8ca69f-db34-4373-aa32-da8bf89150eb.png` (Codex thread `01a18304-bfd7-7503-8d92-a9b65db01d8c`).
- Decision: Same woman and robe; raised drawn inner brows, wider eyes and slightly parted lips read as worry (the console word for fearful). No text-like marks.
- Prompt (full, verbatim):

> Use case: identity-preserve. Asset type: square stage-0 emotion portrait for the crew console of Stapledon's Voyage. Input image 1 is the accepted portrait_diplomat_age0_neutral_v1.png, the identity/style reference and EDIT TARGET. Edit this image, do not redraw a different woman. Change ONLY her expression to contained fear: inner brows slightly raised and drawn together, eyes subtly widened without bulging, a faint tension in the lower eyelids, lips very slightly parted as breath catches. Vulnerable apprehension, no screaming, no theatrical panic. Same woman, the same age as in the input. Preserve her exact facial structure, deep brown skin, dark eyes, broad warm face, natural lips, short tightly curled grey hair, and every facial line and mark. Preserve the deep violet layered wrap robe with its ochre trim, the cream scarf at the neck and the round brass clasp. Preserve the sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour, original palette and lighting direction. Preserve exact square bust crop, head scale, head position, camera angle, pose and eye-line, every hair silhouette and clothing fold as closely as possible, so the image swaps in the same UI. Native square resolution only, never upscale. Keep genuinely transparent alpha outside the figure, with no scenery, backdrop, gradient, glow, halo, caption, frame, UI, logo or watermark. Absolutely no text, letters, numbers, digits or writing anywhere in the image. Keep the original composition; no added headroom or zoom-out. Static game image, no animation.

## counselor_curious.png

- Master: `portrait_diplomat_age0_curious_v1.png` sha256 `588a18d842b864d448cc505c2278072f3c90111d3b198d4e9c0282436ee86ea3`; byte-for-byte copy of candidate `c3`.
- Shipped: `counselor_curious.png` (sips -Z 256, 256 x 256) sha256 `fae80b6f7ba618049cff2fdb8121e9ffac349a7b2dd9d0e9a15d1d232a5488e1`.
- Date: 2026-10-28. Generator: OpenAI built-in `image_gen__imagegen` via Codex (agent model gpt-6.1-sol). Image model: not exposed. Seed: none exposed.
- Candidates: 3 generated; kept c3.

### Candidate c1: rejected

- Native output: 1254 x 1254 RGBA; sha256 `dc4d48d56325bc4704e7c02e69c7837c779c6a11532068db66328949d454bf93`. Generator output: `exec-0df78745-eeeb-4b07-b961-89601e350f68.png` (Codex thread `01a182fb-52df-77b1-be27-2554d737c5b1`).
- Decision: Identity holds, but the face is almost her neutral warm smile; curiosity does not read. Regenerated with variant b.
- Prompt (full, verbatim):

> Use case: identity-preserve. Asset type: square stage-0 emotion portrait for the crew console of Stapledon's Voyage. Input image 1 is the accepted portrait_diplomat_age0_neutral_v1.png, the identity/style reference and EDIT TARGET. Edit this image, do not redraw a different woman. Change ONLY her expression to thoughtful curiosity: a subtle asymmetric eyebrow lift and gently widened attentive eyes, lips softly closed with a tiny thoughtful asymmetry. A receptive questioning look, not surprise, no head tilt. Same woman, the same age as in the input. Preserve her exact facial structure, deep brown skin, dark eyes, broad warm face, natural lips, short tightly curled grey hair, and every facial line and mark. Preserve the deep violet layered wrap robe with its ochre trim, the cream scarf at the neck and the round brass clasp. Preserve the sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour, original palette and lighting direction. Preserve exact square bust crop, head scale, head position, camera angle, pose and eye-line, every hair silhouette and clothing fold as closely as possible, so the image swaps in the same UI. Native square resolution only, never upscale. Keep genuinely transparent alpha outside the figure, with no scenery, backdrop, gradient, glow, halo, caption, frame, UI, logo or watermark. Absolutely no text, letters, numbers, digits or writing anywhere in the image. Keep the original composition; no added headroom or zoom-out. Static game image, no animation.

### Candidate c2: rejected

- Native output: 1254 x 1254 RGBA; sha256 `0c8d870cf657fea54c660100c291d1a1b9aa9a6785db54003a62f6e0268f9ca5`. Generator output: `exec-6b155ea1-f8f4-43b4-937b-a69e80f0a6e3.png` (Codex thread `01a1830c-826f-7fd3-ad22-31bf6e031de4`).
- Decision: Identity holds; slightly parted lips but still essentially her neutral smile; curiosity reads weakly. Last retry with the stronger variant c.
- Prompt (full, verbatim):

> Use case: identity-preserve. Asset type: square stage-0 emotion portrait for the crew console of Stapledon's Voyage. Input image 1 is the accepted portrait_diplomat_age0_neutral_v1.png, the identity/style reference and EDIT TARGET. Edit this image, do not redraw a different woman. Change ONLY her expression to quiet curiosity: one eyebrow clearly raised, eyes a little more attentive and open along the same eye-line, lips softly relaxed and slightly parted as if about to ask a thoughtful question. Interested and questioning, no grin, no head tilt. Same woman, the same age as in the input. Preserve her exact facial structure, deep brown skin, dark eyes, broad warm face, natural lips, short tightly curled grey hair, and every facial line and mark. Preserve the deep violet layered wrap robe with its ochre trim, the cream scarf at the neck and the round brass clasp. Preserve the sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour, original palette and lighting direction. Preserve exact square bust crop, head scale, head position, camera angle, pose and eye-line, every hair silhouette and clothing fold as closely as possible, so the image swaps in the same UI. Native square resolution only, never upscale. Keep genuinely transparent alpha outside the figure, with no scenery, backdrop, gradient, glow, halo, caption, frame, UI, logo or watermark. Absolutely no text, letters, numbers, digits or writing anywhere in the image. Keep the original composition; no added headroom or zoom-out. Static game image, no animation.

### Candidate c3: kept

- Native output: 1254 x 1254 RGBA; sha256 `588a18d842b864d448cc505c2278072f3c90111d3b198d4e9c0282436ee86ea3`. Generator output: `exec-68a13e49-cf7d-4cfb-9457-ab0887e647a6.png` (Codex thread `01a18317-17cf-7a70-b587-39b19c6ed3e9`).
- Decision: Same woman and robe; the neutral smile reduced, brows lifted, attentive eyes and parted lips read as interest, about to ask a question. No text-like marks.
- Prompt (full, verbatim):

> Use case: identity-preserve. Asset type: square stage-0 emotion portrait for the crew console of Stapledon's Voyage. Input image 1 is the accepted portrait_diplomat_age0_neutral_v1.png, the identity/style reference and EDIT TARGET. Edit this image, do not redraw a different woman. Change ONLY her expression to open, alert curiosity that must read clearly even at a small thumbnail: one eyebrow raised high while the other stays level, eyes widened and bright with interest, lips parted as if just about to ask a question, any smile in the input removed. Clearly different from the input expression, yet adult and understated; not surprise, not a grin, no head tilt. Same woman, the same age as in the input. Preserve her exact facial structure, deep brown skin, dark eyes, broad warm face, natural lips, short tightly curled grey hair, and every facial line and mark. Preserve the deep violet layered wrap robe with its ochre trim, the cream scarf at the neck and the round brass clasp. Preserve the sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour, original palette and lighting direction. Preserve exact square bust crop, head scale, head position, camera angle, pose and eye-line, every hair silhouette and clothing fold as closely as possible, so the image swaps in the same UI. Native square resolution only, never upscale. Keep genuinely transparent alpha outside the figure, with no scenery, backdrop, gradient, glow, halo, caption, frame, UI, logo or watermark. Absolutely no text, letters, numbers, digits or writing anywhere in the image. Keep the original composition; no added headroom or zoom-out. Static game image, no animation.

## counselor_loving.png

- Master: `portrait_diplomat_age0_loving_v1.png` sha256 `fa74d810118a479100ae26233f9fe3198e0ab37b90d6be440de4450ddc0d2f0a`; byte-for-byte copy of candidate `c3`.
- Shipped: `counselor_loving.png` (sips -Z 256, 256 x 256) sha256 `8861fc1dba1bff0417085b7d27ffd4565499de965065aa6678c1e1e1775961c3`.
- Date: 2026-10-28. Generator: OpenAI built-in `image_gen__imagegen` via Codex (agent model gpt-6.1-sol). Image model: not exposed. Seed: none exposed.
- Candidates: 3 generated; kept c3.

### Candidate c1: rejected

- Native output: 1254 x 1254 RGBA; sha256 `a7994f9791cf5af6d7adf1025e064eff79211baddddaca9c95e4b0b78eee181f`. Generator output: `exec-24c6f806-2d6d-4373-88c1-80680df23cb9.png` (Codex thread `01a1830c-3af0-77b2-88d4-20d77f754193`).
- Decision: Identity holds, but it is nearly the same face as her smiling neutral; loving does not read as distinct. Regenerated with variant b.
- Prompt (full, verbatim):

> Use case: identity-preserve. Asset type: square stage-0 emotion portrait for the crew console of Stapledon's Voyage. Input image 1 is the accepted portrait_diplomat_age0_neutral_v1.png, the identity/style reference and EDIT TARGET. Edit this image, do not redraw a different woman. Change ONLY her expression to tender loving warmth: a soft gentle closed-lip smile, softened shining eyes full of affection, a relaxed open brow, as if looking at a dear one or remembering family at home. Tender and quiet, distinct from plain happiness, never flirtatious or sentimental. Same woman, the same age as in the input. Preserve her exact facial structure, deep brown skin, dark eyes, broad warm face, natural lips, short tightly curled grey hair, and every facial line and mark. Preserve the deep violet layered wrap robe with its ochre trim, the cream scarf at the neck and the round brass clasp. Preserve the sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour, original palette and lighting direction. Preserve exact square bust crop, head scale, head position, camera angle, pose and eye-line, every hair silhouette and clothing fold as closely as possible, so the image swaps in the same UI. Native square resolution only, never upscale. Keep genuinely transparent alpha outside the figure, with no scenery, backdrop, gradient, glow, halo, caption, frame, UI, logo or watermark. Absolutely no text, letters, numbers, digits or writing anywhere in the image. Keep the original composition; no added headroom or zoom-out. Static game image, no animation.

### Candidate c2: rejected

- Native output: 1254 x 1254 RGBA; sha256 `26fd814dfafe8a284b79c66e1b2a3358361732fcb88fd0f41d5b461ec51bcbf8`. Generator output: `exec-b0f2dad6-6789-4c7f-9259-0d2463e83184.png` (Codex thread `01a1830d-737f-7c01-bc15-289454e325d3`).
- Decision: Identity holds, but again nearly the same face as her warm smiling neutral. Last retry with the stronger variant c.
- Prompt (full, verbatim):

> Use case: identity-preserve. Asset type: square stage-0 emotion portrait for the crew console of Stapledon's Voyage. Input image 1 is the accepted portrait_diplomat_age0_neutral_v1.png, the identity/style reference and EDIT TARGET. Edit this image, do not redraw a different woman. Change ONLY her expression to tender affection: a small soft closed-lip smile, gentle half-lowered eyelids, warm softened eyes and a relaxed brow, the look of someone thinking of a person they love far away. Tender, calm and adult, distinct from plain happiness, never flirtatious. Same woman, the same age as in the input. Preserve her exact facial structure, deep brown skin, dark eyes, broad warm face, natural lips, short tightly curled grey hair, and every facial line and mark. Preserve the deep violet layered wrap robe with its ochre trim, the cream scarf at the neck and the round brass clasp. Preserve the sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour, original palette and lighting direction. Preserve exact square bust crop, head scale, head position, camera angle, pose and eye-line, every hair silhouette and clothing fold as closely as possible, so the image swaps in the same UI. Native square resolution only, never upscale. Keep genuinely transparent alpha outside the figure, with no scenery, backdrop, gradient, glow, halo, caption, frame, UI, logo or watermark. Absolutely no text, letters, numbers, digits or writing anywhere in the image. Keep the original composition; no added headroom or zoom-out. Static game image, no animation.

### Candidate c3: kept

- Native output: 1254 x 1254 RGBA; sha256 `fa74d810118a479100ae26233f9fe3198e0ab37b90d6be440de4450ddc0d2f0a`. Generator output: `exec-d6e7e3ef-d3b4-4aef-b01d-88eff34415e7.png` (Codex thread `01a18317-17a3-7c20-96b4-2d032238886a`).
- Decision: (flagged) Best of three: same woman and robe; softer half-lowered lids and a tender closed smile. Still close to her neutral, which is itself a warm smile in the diplomat concept art; retries exhausted, flagged for review. No text-like marks.
- Prompt (full, verbatim):

> Use case: identity-preserve. Asset type: square stage-0 emotion portrait for the crew console of Stapledon's Voyage. Input image 1 is the accepted portrait_diplomat_age0_neutral_v1.png, the identity/style reference and EDIT TARGET. Edit this image, do not redraw a different woman. Change ONLY her expression to deep tender love that must read clearly even at a small thumbnail and look clearly different from the input expression: eyelids softly half-lowered, eyes glistening with warm affection, eyebrows gently lifted at the centre, a small closed-lip tender smile, the whole face softened as if gazing at a picture of someone dear who is far away. Adult and quiet; not a grin, not flirtatious, no tears falling. Same woman, the same age as in the input. Preserve her exact facial structure, deep brown skin, dark eyes, broad warm face, natural lips, short tightly curled grey hair, and every facial line and mark. Preserve the deep violet layered wrap robe with its ochre trim, the cream scarf at the neck and the round brass clasp. Preserve the sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour, original palette and lighting direction. Preserve exact square bust crop, head scale, head position, camera angle, pose and eye-line, every hair silhouette and clothing fold as closely as possible, so the image swaps in the same UI. Native square resolution only, never upscale. Keep genuinely transparent alpha outside the figure, with no scenery, backdrop, gradient, glow, halo, caption, frame, UI, logo or watermark. Absolutely no text, letters, numbers, digits or writing anywhere in the image. Keep the original composition; no added headroom or zoom-out. Static game image, no animation.

## counselor_grieving.png

- Master: `portrait_diplomat_age0_grieving_v1.png` sha256 `76648b27c2ac9b839b408d4925618389ce1b19e477b1338847f13329e2fb389d`; byte-for-byte copy of candidate `c2`.
- Shipped: `counselor_grieving.png` (sips -Z 256, 256 x 256) sha256 `4af64d8f54a38e688d8d604ad28c6f3883ea00822bfd35cb035d3901b935f5a5`.
- Date: 2026-10-28. Generator: OpenAI built-in `image_gen__imagegen` via Codex (agent model gpt-6.1-sol). Image model: not exposed. Seed: none exposed.
- Candidates: 2 generated; kept c2.

### Candidate c1: rejected

- Native output: 1254 x 1254 RGBA; sha256 `36e89734f47a5e4619c2976b1a5200a462ac97c416da5cdeaed40b2d53cffcfc`. Generator output: `exec-b92ac183-1930-49bc-8366-ef1a796d147e.png` (Codex thread `01a1830d-1459-7c10-9b66-b531c28a1357`).
- Decision: Identity holds, but narrowed eyes and pursed lips read as scepticism, close to her angry portrait; grief does not read. Regenerated with variant b.
- Prompt (full, verbatim):

> Use case: identity-preserve. Asset type: square stage-0 emotion portrait for the crew console of Stapledon's Voyage. Input image 1 is the accepted portrait_diplomat_age0_neutral_v1.png, the identity/style reference and EDIT TARGET. Edit this image, do not redraw a different woman. Change ONLY her expression to quiet grief: eyes lowered slightly, a fragile tension in the brow and lower eyelids, lips held gently together, a person trying to remain present through loss. Subtle, believable, deeply felt; deeper and more inward than ordinary sadness; no theatrical crying. Same woman, the same age as in the input. Preserve her exact facial structure, deep brown skin, dark eyes, broad warm face, natural lips, short tightly curled grey hair, and every facial line and mark. Preserve the deep violet layered wrap robe with its ochre trim, the cream scarf at the neck and the round brass clasp. Preserve the sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour, original palette and lighting direction. Preserve exact square bust crop, head scale, head position, camera angle, pose and eye-line, every hair silhouette and clothing fold as closely as possible, so the image swaps in the same UI. Native square resolution only, never upscale. Keep genuinely transparent alpha outside the figure, with no scenery, backdrop, gradient, glow, halo, caption, frame, UI, logo or watermark. Absolutely no text, letters, numbers, digits or writing anywhere in the image. Keep the original composition; no added headroom or zoom-out. Static game image, no animation.

### Candidate c2: kept

- Native output: 1254 x 1254 RGBA; sha256 `76648b27c2ac9b839b408d4925618389ce1b19e477b1338847f13329e2fb389d`. Generator output: `exec-dc02f94f-85c0-4b38-a5b9-0df9bc946acd.png` (Codex thread `01a18316-64f3-74f2-9e64-e8e742ef8414`).
- Decision: Same woman and robe; inner brows drawn up, lids lowered and the mouth turned down with the smile gone; reads as grief, distinct from her angry and sad portraits. No text-like marks.
- Prompt (full, verbatim):

> Use case: identity-preserve. Asset type: square stage-0 emotion portrait for the crew console of Stapledon's Voyage. Input image 1 is the accepted portrait_diplomat_age0_neutral_v1.png, the identity/style reference and EDIT TARGET. Edit this image, do not redraw a different woman. Change ONLY her expression to quiet grief: eyelids lowered with the gaze dropped slightly below the existing eye-line, inner brows drawn up with a fragile tension, lips held together with a faint tremble at the corners, all trace of a smile gone. A person holding steady through bereavement; deeply felt, no theatrical crying, no tears streaming. Same woman, the same age as in the input. Preserve her exact facial structure, deep brown skin, dark eyes, broad warm face, natural lips, short tightly curled grey hair, and every facial line and mark. Preserve the deep violet layered wrap robe with its ochre trim, the cream scarf at the neck and the round brass clasp. Preserve the sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour, original palette and lighting direction. Preserve exact square bust crop, head scale, head position, camera angle, pose and eye-line, every hair silhouette and clothing fold as closely as possible, so the image swaps in the same UI. Native square resolution only, never upscale. Keep genuinely transparent alpha outside the figure, with no scenery, backdrop, gradient, glow, halo, caption, frame, UI, logo or watermark. Absolutely no text, letters, numbers, digits or writing anywhere in the image. Keep the original composition; no added headroom or zoom-out. Static game image, no animation.

