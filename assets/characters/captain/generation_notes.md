# Captain avatar set — PICKED A: Longline Navigator

Mark picked proposal A in the attended task on 2026-10-03. The eight final views preserve that identity, costume language and cream/ochre/violet palette. Final set status is proposed for visual review; the identity choice is picked. Art owned by Sunholo, contributed under Apache-2.0.

Generator: OpenAI built-in `image_gen.imagegen`; exact model ID/version is not exposed by the tool and is not guessed. Date: 2026-10-03. Seeds: none exposed. Native generations: 1024×1536 RGBA. No upscaling, tracing or third-party inputs.

The current user instruction overrides the handoff PR/push, review-subfolder and additional review-file steps: commit exactly eight avatars, this manifest, these notes and `avatar_captain_sheet.png` on `art/captain-avatar`. No publishing.

Spec interpretation: use the handoff explicit 720px/m asset-canvas contract. M4.2 describes cos(14°) projected height; no second cosine is baked into these assets. Engine integration must avoid applying projection twice. A raster sole contact is measured from alpha>=128: x is the midpoint of each separate boot footprint within the lowest 50px, y is that boot sole contour baseline; curved soles permit a few pixels of contour variation. This avoids anchoring to a heel alone on a curved sole.

Post-processing is limited to the handoff-authorized alpha cleanup, uniform Lanczos downscale, translation and transparent padding. Alpha<=10 is set to 0, alpha>=250 to 255; remaining partial-alpha fringe pixels farther than 3px Euclidean distance from opaque figure are set to 0. Throwaway scripts in /private/tmp are not committed. RGB of alpha-0 pixels is cleared to zero to avoid invisible backdrop colour leaking under filtering.

## avatar_captain_y0_front.png

- Mode: translated re-key of PICKED `proposals/avatar_captain_proposal_a.png` (sha256 f5bd39f99932fafd46c14c31faca2272fe43bbba780bed076eca924b5987a74e). No new generation, resizing or RGB repainting. Apply the set alpha cleanup described above to enforce the 3px fringe limit, then re-measure sole-contact midpoint [510.5, 1438.5]; translate (2, 2) pixels and pad to the same 1024×1536 canvas. The original proposal notes used an estimated anchor; this set uses the measured boot contacts. Original full provenance follows.

- Generator: OpenAI built-in image_gen.imagegen. Model: exact ID/version not exposed.
- Date: 2026-10-03. Seed: none exposed.
- Mode: text-to-image followed by identity-preserving stance edit.
- Initial input-free generation prompt (full, verbatim):
  > Use case: stylized-concept.
  > Asset type: production full-body static captain avatar silhouette proposal for Stapledon's Voyage, stage 0 (young adult, approximately 30), front facing.
  > Style/medium: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, fine selective cross-hatching, textured gouache and watercolour colour planes, tactile handmade cloth with convincing folds and gentle wear. Organic grown-looking fastenings; believable human anatomy. No named artist imitation.
  > Composition: exactly one complete standing human on a genuinely transparent background, portrait canvas 1024 x 1536 RGBA. Orthographic view from 14 degrees above horizontal, no perspective foreshortening. Three-quarter FRONT toward the viewer, torso and both feet turned toward screen-left. Relaxed standing pose, arms down, hands visible, soles on the same ground line. Full figure including hair and boots. A 1.75 metre adult at 720 pixels per metre: hair top near y=180, sole ground line y=1440; ground-point anchor under body centre at (512,1440), midpoint between the soles. Figure height 1260 pixels. Make the figure at least 1260 pixels high natively; never a small figure occupying half the canvas. At least 16 pixels completely transparent on every edge. Keep the feet evenly balanced about x=512.
  > Lighting: soft warm key from upper left, delicate pale cool rim #D1E0FA, restrained violet shadows #3B2959; no exterior glow.
  > Palette: cream #F2E3C7 base cloth, violet #3B2959 shadow and deep cloth, ink #423555 contours; exactly one conspicuous accent colour, ochre #D9A340. Natural skin and hair.
  > Face: calm, understated and non-specific, minimal facial detail so the player can project their identity; no expressive portrait or real person's likeness.
  > Constraints: silhouette must read at only 67 pixels high; broad legible clothing shapes, not detail-dependent. Mirror-safe design: no letters, text, numbers, logos, religious symbols or one-sided insignia. No scenery, floor, ground ellipse, contact shadow, stars, gradients, haze, halo, frame, captions or watermark. Alpha exactly zero outside figure; crisp antialiased boundary at most 3 pixels wide. No armour, helmets, guns, spacesuit, military insignia, glossy 3D, photorealism, anime, chibi, glamour, rigid mannequin anatomy.
  >
  > Design A — The Longline Navigator: slender androgynous young adult, warm medium skin, short softly swept dark hair. Narrow upright silhouette with a soft stand collar and a calf-length open cream coat whose rounded front panels reveal violet tapered trousers and practical soft boots. A single broad ochre shoulder yoke flowing into the collar gives a readable upper-body marker; symmetrical garment structure and plain grown oval fastenings. Calm attentive stance, arms separated slightly from coat, no objects. The two long coat panels should create a clean distinct taper without resembling a uniform or ceremonial robe.
- Edit input: exec-8f62cb04-d7a9-4c56-b00e-4a5bfe6f5f54.png (sha256 a3c708bca116e8d3a9ef9471736d58544c5c10146cff11a3966d8ef00d8de2f2).
- Edit prompt (full, verbatim):
  > Edit the supplied captain avatar, preserving exactly the identity, clothing design, palette, illustration style, proportions and front three-quarter screen-left facing. Change ONLY stance and framing: both boot soles must rest on the SAME horizontal ground line (no staggered foot toward viewer). Feet evenly placed about body centre. Orthographic 14-degree view, no perspective. Position head top at y=180 and both soles at y=1440 on a 1024x1536 transparent RGBA canvas, 1260px total figure height (1.75m at 720px/m), midpoint between boot contact centres x=512. No floor or shadow. Absolutely transparent outside the figure, no glow, halo or stray specks. Keep a crisp antialiased edge at most 3px wide. Do not change anything else.
- Post-processing: Pillow; retain generated alpha, set alpha <=10 to 0 to remove near-invisible isolated specks and alpha >=250 to 255; uniform Lanczos downscale from 1024×1536 to 898×1348 (0.877437326 target ratio), apply the same alpha cleanup after filtering, translate by (56, 153) pixels and pad onto a transparent 1024×1536 canvas. No RGB repainting, tracing or upscaling. Sole contact centre midpoint estimated in source at x=520; final sole ground line at y=1440 (pixel boundary), midpoint x=512 after rounding. Sole antialias curves have a few pixels of contour variation.
- Candidates: 2 generated (initial + stance edit); edit chosen for level soles, initial rejected for staggered foot placement.
- Validation: RGBA 1024×1536; all four 16px borders alpha max 0; alpha bbox (293, 178, 751, 1441); alpha>=128 figure height 1261px, 720.571px/m; sha256 f5bd39f99932fafd46c14c31faca2272fe43bbba780bed076eca924b5987a74e.


## avatar_captain_y0_back.png

- Generator: OpenAI built-in `image_gen.imagegen`. Model: exact ID/version not exposed.
- Date: 2026-10-03. Seed: none exposed.

- Initial mode: identity-preserving generation from PICKED `proposals/avatar_captain_proposal_a.png` (sha256 f5bd39f99932fafd46c14c31faca2272fe43bbba780bed076eca924b5987a74e).

- Initial prompt (full, verbatim):
  > Use case: identity-preserve. Asset: ONE production static full-body captain avatar for Stapledon's Voyage. Reference image is Mark's PICKED proposal A, Longline Navigator. Preserve this same slender androgynous warm-medium-skinned person, facial bone structure, softly swept short hair, civilian cream calf-length open long coat with rounded panels, broad ochre shoulder yoke and raised collar, ochre sash and plain oval closures, violet trousers and practical soft boots. Preserve fine ink contours, selective crosshatching, textured gouache/watercolour cloth, hand-drawn science-fiction graphic-novel style. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959 and ink #423555. Soft warm key upper left, delicate cool rim without glow. Calm non-specific face, no expressive portrait. Orthographic camera looking down 14 degrees, no perspective or oversized head. Full standing figure with relaxed arms, hands visible, both boot soles on the SAME horizontal ground line, no staggered stance. BOTH torso and boots face screen-left. Portrait 1024x1536 RGBA, figure at least 1260 pixels tall natively (fill most canvas so it can be DOWNscaled); hair near y=100 and soles near y=1450, balanced feet around x=512. Genuine transparent background, alpha exactly zero outside figure, crisp antialias <=3px, at least 16px transparent on every edge. No floor, shadow, ground ellipse, halo, haze, specks, backdrop, captions, text, letters, numbers, logos, one-sided insignia, objects, weapons or watermark. Mirror-safe clothing. Only ONE person, not a sheet. Age 30, youthful slender build, dark swept hair, upright attentive stance, fresh but tactile clothing. Three-quarter BACK view AWAY from viewer turned screen-left: see rear of head, back of coat and broad ochre yoke extending across BOTH rear shoulders; only a tiny near cheek profile, no frontal face. Coat rear has a simple practical centre vent, no new ornaments.

- Edit input: `exec-2e7c185e-005c-4824-bddf-dd18e5ac4023.png` (sha256 6030056994f1f563b27cc5627d641153b13249a86954a01dae1471f117b67532). Additional pose/costume reference: PICKED proposal A (sha256 f5bd39f99932fafd46c14c31faca2272fe43bbba780bed076eca924b5987a74e).

- Edit prompt (full, verbatim):
  > Edit target image 1, pose reference image 2. Preserve image 1's identity, age, face, hair, entire costume, colours, style and front/back orientation. Change ONLY the stance and framing. Both boot soles must end on exactly the SAME horizontal ground line; no staggered foot, no depth offset. Adopt image 2's level, even two-foot standing balance. Let boots face a little forward if necessary, while body keeps its existing screen-left three-quarter turn. Physically lower the higher boot until soles align. Separate both boots by a small clear gap. Fullbody figure at least 1260px high on native 1024x1536 RGBA, midpoint of boot contact centres at x512 and common sole baseline near y1440. Preserve age; do not rejuvenate. Alpha-0 outside figure, no floor, shadow, backdrop, halo, text or new costume details. 16px alpha-0 margins, crisp antialias <=3px.

- Selected native output: `exec-7cdf7ec7-919d-42a0-937a-911146932e9c.png` (sha256 ff9f3d330d5003c33be5287ebe8d5e185e3eaabea4fb7e068c6f1c67735405e2).

- Post-processing: alpha<=10 →0, alpha>=250 →255; partial-alpha fringe beyond 3px Euclidean distance from opaque figure →0; RGB cleared only where alpha=0. Uniform Lanczos downscale 1024×1536 → 889×1333 (requested factor 0.867768595); same alpha cleanup after filtering; translation (64,151), transparent pad to 1024×1536. Native measured contacts [(394.0, 1485), (638.5, 1485)]; native contact-midpoint-to-hair 1452.00px. Never upscaled.

- Candidates: 2 generated. Initial candidate had staggered sole contours; edit chosen for level standing balance without changing identity or costume.

## avatar_captain_y20_front.png

- Generator: OpenAI built-in `image_gen.imagegen`. Model: exact ID/version not exposed.
- Date: 2026-10-03. Seed: none exposed.

- Initial mode: identity-preserving generation from PICKED `proposals/avatar_captain_proposal_a.png` (sha256 f5bd39f99932fafd46c14c31faca2272fe43bbba780bed076eca924b5987a74e).

- Initial prompt (full, verbatim):
  > Use case: identity-preserve. Asset: ONE production static full-body captain avatar for Stapledon's Voyage. Reference image is Mark's PICKED proposal A, Longline Navigator. Preserve this same slender androgynous warm-medium-skinned person, facial bone structure, softly swept short hair, civilian cream calf-length open long coat with rounded panels, broad ochre shoulder yoke and raised collar, ochre sash and plain oval closures, violet trousers and practical soft boots. Preserve fine ink contours, selective crosshatching, textured gouache/watercolour cloth, hand-drawn science-fiction graphic-novel style. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959 and ink #423555. Soft warm key upper left, delicate cool rim without glow. Calm non-specific face, no expressive portrait. Orthographic camera looking down 14 degrees, no perspective or oversized head. Full standing figure with relaxed arms, hands visible, both boot soles on the SAME horizontal ground line, no staggered stance. BOTH torso and boots face screen-left. Portrait 1024x1536 RGBA, figure at least 1260 pixels tall natively (fill most canvas so it can be DOWNscaled); hair near y=100 and soles near y=1450, balanced feet around x=512. Genuine transparent background, alpha exactly zero outside figure, crisp antialias <=3px, at least 16px transparent on every edge. No floor, shadow, ground ellipse, halo, haze, specks, backdrop, captions, text, letters, numbers, logos, one-sided insignia, objects, weapons or watermark. Mirror-safe clothing. Only ONE person, not a sheet. Age 50, same person twenty years older: salt-and-pepper at temples, subtle smile lines and forehead creases, slightly fuller midlife waist, mature shoulders, still erect. Cream coat gently worn at cuffs and hem. Three-quarter FRONT view TOWARD viewer turned screen-left, face looking screen-left rather than directly at camera.

- Edit input: `exec-3a440ce7-1444-4152-8c8e-7ed922ba73b8.png` (sha256 1e228f633bc89d3b8fe89ae636be900234a1915adff0ea66ea0668789290d540). Additional pose/costume reference: PICKED proposal A (sha256 f5bd39f99932fafd46c14c31faca2272fe43bbba780bed076eca924b5987a74e).

- Edit prompt (full, verbatim):
  > Edit target image 1, pose reference image 2. Preserve image 1's identity, age, face, hair, entire costume, colours, style and front/back orientation. Change ONLY the stance and framing. Both boot soles must end on exactly the SAME horizontal ground line; no staggered foot, no depth offset. Adopt image 2's level, even two-foot standing balance. Let boots face a little forward if necessary, while body keeps its existing screen-left three-quarter turn. Physically lower the higher boot until soles align. Separate both boots by a small clear gap. Fullbody figure at least 1260px high on native 1024x1536 RGBA, midpoint of boot contact centres at x512 and common sole baseline near y1440. Preserve age; do not rejuvenate. Alpha-0 outside figure, no floor, shadow, backdrop, halo, text or new costume details. 16px alpha-0 margins, crisp antialias <=3px.

- Selected native output: `exec-a6620af2-3797-4a63-90c1-a14ec9909dad.png` (sha256 f04bba2f3f5bcb2631eba6b90fd579ab8c59b4449c6e7578775d7fb37ecfa490).

- Post-processing: alpha<=10 →0, alpha>=250 →255; partial-alpha fringe beyond 3px Euclidean distance from opaque figure →0; RGB cleared only where alpha=0. Uniform Lanczos downscale 1024×1536 → 879×1318 (requested factor 0.858310627); same alpha cleanup after filtering; translation (67,158), transparent pad to 1024×1536. Native measured contacts [(410.0, 1493), (628.0, 1495)]; native contact-midpoint-to-hair 1468.00px. Never upscaled.

- Candidates: 2 generated. Initial candidate had staggered sole contours; edit chosen for level standing balance without changing identity or costume.

## avatar_captain_y20_back.png

- Generator: OpenAI built-in `image_gen.imagegen`. Model: exact ID/version not exposed.
- Date: 2026-10-03. Seed: none exposed.

- Initial mode: identity-preserving generation from PICKED `proposals/avatar_captain_proposal_a.png` (sha256 f5bd39f99932fafd46c14c31faca2272fe43bbba780bed076eca924b5987a74e).

- Initial prompt (full, verbatim):
  > Use case: identity-preserve. Asset: ONE production static full-body captain avatar for Stapledon's Voyage. Reference image is Mark's PICKED proposal A, Longline Navigator. Preserve this same slender androgynous warm-medium-skinned person, facial bone structure, softly swept short hair, civilian cream calf-length open long coat with rounded panels, broad ochre shoulder yoke and raised collar, ochre sash and plain oval closures, violet trousers and practical soft boots. Preserve fine ink contours, selective crosshatching, textured gouache/watercolour cloth, hand-drawn science-fiction graphic-novel style. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959 and ink #423555. Soft warm key upper left, delicate cool rim without glow. Calm non-specific face, no expressive portrait. Orthographic camera looking down 14 degrees, no perspective or oversized head. Full standing figure with relaxed arms, hands visible, both boot soles on the SAME horizontal ground line, no staggered stance. BOTH torso and boots face screen-left. Portrait 1024x1536 RGBA, figure at least 1260 pixels tall natively (fill most canvas so it can be DOWNscaled); hair near y=100 and soles near y=1450, balanced feet around x=512. Genuine transparent background, alpha exactly zero outside figure, crisp antialias <=3px, at least 16px transparent on every edge. No floor, shadow, ground ellipse, halo, haze, specks, backdrop, captions, text, letters, numbers, logos, one-sided insignia, objects, weapons or watermark. Mirror-safe clothing. Only ONE person, not a sheet. Age 50, same person twenty years older: salt-and-pepper temples and rear swept hair, slightly fuller midlife waist, mature shoulders, still erect. Cream coat gently worn at cuffs and hem. Three-quarter BACK view AWAY from viewer turned screen-left, see rear head and back coat, broad ochre yoke across both rear shoulders and simple centre vent. Tiny near cheek profile only.

- Edit input: `exec-cb9ba20f-1a87-40d1-90cd-c5b283a003ef.png` (sha256 2c6c6cd164516091acfe84bebc09b95c962d6a10ae73faa545b5bc332a88fb4e). Additional pose/costume reference: PICKED proposal A (sha256 f5bd39f99932fafd46c14c31faca2272fe43bbba780bed076eca924b5987a74e).

- Edit prompt (full, verbatim):
  > Edit target image 1, pose reference image 2. Preserve image 1's identity, age, face, hair, entire costume, colours, style and front/back orientation. Change ONLY the stance and framing. Both boot soles must end on exactly the SAME horizontal ground line; no staggered foot, no depth offset. Adopt image 2's level, even two-foot standing balance. Let boots face a little forward if necessary, while body keeps its existing screen-left three-quarter turn. Physically lower the higher boot until soles align. Separate both boots by a small clear gap. Fullbody figure at least 1260px high on native 1024x1536 RGBA, midpoint of boot contact centres at x512 and common sole baseline near y1440. Preserve age; do not rejuvenate. Alpha-0 outside figure, no floor, shadow, backdrop, halo, text or new costume details. 16px alpha-0 margins, crisp antialias <=3px.

- Selected native output: `exec-5d797abf-948b-4453-988a-f5e2e1a1dc43.png` (sha256 e8b0e56bc56c1814b6ec09ed8f6038a96c31bf70753dc9f195267cb6b7dee70d).

- Post-processing: alpha<=10 →0, alpha>=250 →255; partial-alpha fringe beyond 3px Euclidean distance from opaque figure →0; RGB cleared only where alpha=0. Uniform Lanczos downscale 1024×1536 → 884×1326 (requested factor 0.863605209); same alpha cleanup after filtering; translation (69,160), transparent pad to 1024×1536. Native measured contacts [(387.0, 1484), (640.0, 1482)]; native contact-midpoint-to-hair 1459.00px. Never upscaled.

- Candidates: 2 generated. Initial candidate had staggered sole contours; edit chosen for level standing balance without changing identity or costume.

## avatar_captain_y40_front.png

- Generator: OpenAI built-in `image_gen.imagegen`. Model: exact ID/version not exposed.
- Date: 2026-10-03. Seed: none exposed.

- Initial mode: identity-preserving generation from PICKED `proposals/avatar_captain_proposal_a.png` (sha256 f5bd39f99932fafd46c14c31faca2272fe43bbba780bed076eca924b5987a74e).

- Initial prompt (full, verbatim):
  > Use case: identity-preserve. Asset: ONE production static full-body captain avatar for Stapledon's Voyage. Reference image is Mark's PICKED proposal A, Longline Navigator. Preserve this same slender androgynous warm-medium-skinned person, facial bone structure, softly swept short hair, civilian cream calf-length open long coat with rounded panels, broad ochre shoulder yoke and raised collar, ochre sash and plain oval closures, violet trousers and practical soft boots. Preserve fine ink contours, selective crosshatching, textured gouache/watercolour cloth, hand-drawn science-fiction graphic-novel style. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959 and ink #423555. Soft warm key upper left, delicate cool rim without glow. Calm non-specific face, no expressive portrait. Orthographic camera looking down 14 degrees, no perspective or oversized head. Full standing figure with relaxed arms, hands visible, both boot soles on the SAME horizontal ground line, no staggered stance. BOTH torso and boots face screen-left. Portrait 1024x1536 RGBA, figure at least 1260 pixels tall natively (fill most canvas so it can be DOWNscaled); hair near y=100 and soles near y=1450, balanced feet around x=512. Genuine transparent background, alpha exactly zero outside figure, crisp antialias <=3px, at least 16px transparent on every edge. No floor, shadow, ground ellipse, halo, haze, specks, backdrop, captions, text, letters, numbers, logos, one-sided insignia, objects, weapons or watermark. Mirror-safe clothing. Only ONE person, not a sheet. Age 70, unmistakably same person: predominantly silver-grey swept hair with a few dark streaks, fine wrinkles around eyes and mouth, gently hollowing cheeks, leaner build, shoulders subtly settled, slight neck inclination but upright capable independent stance. Height 1.73m. Familiar coat shows softened ochre, neatly repaired cuffs and restrained seam repairs, same original silhouette. Three-quarter FRONT view TOWARD viewer turned screen-left.

- Edit input: `exec-191affec-a0de-42cd-9d4d-400785a57268.png` (sha256 0f49b3602696b2cc02a5721538e03661ff44af5973147113e3453974849fa969). Additional pose/costume reference: PICKED proposal A (sha256 f5bd39f99932fafd46c14c31faca2272fe43bbba780bed076eca924b5987a74e).

- Edit prompt (full, verbatim):
  > Image 1 is the age-70 captain EDIT TARGET. Image 2 is the picked young captain POSE reference only. Keep image 1's age-70 face, silver hair, anatomy, costume and style exactly. Change ONLY the standing pose and canvas framing to match image 2: two boots rest on precisely the SAME horizontal ground baseline, evenly balanced, not one foot advanced or staggered towards camera. The current left boot floats ABOVE the right boot: lower that foot so both soles align. Feet may point slightly forward like image 2 while torso stays three-quarter screen-left. Preserve relaxed hands and same coat. Output one fullbody figure 1024x1536 RGBA, native height at least 1260px, head near y=120, both soles y=1440. Midpoint of soles x=512. No floor/shadow/halo/text, genuine transparency, crisp edges, 16px alpha-0 margins. Do not rejuvenate or change identity.

- Edit input: `exec-9fdf04fd-a4be-48b0-ab69-497dcbd329c1.png` (sha256 2ed880697fd66e732efb1509207dff505911101e395a622ea9030bae4141e7a7).

- Edit prompt (full, verbatim):
  > Edit this age-SEVENTY captain, same person and costume. Two focused corrections: 1) Make age 70 readable: hair predominantly SILVER grey rather than brown, fine crow's feet and forehead and mouth creases, slightly hollow cheeks and a gently settled neck/shoulder posture. Preserve facial bones, slender androgynous identity and calm expression; not frail or caricatured. 2) LEFT boot sole currently sits about 10 pixels ABOVE right boot sole. Lower the LEFT boot so BOTH soles end on an identical level baseline. Relaxed upright pose, both feet under body with a gap, facing toward viewer slightly screen-left. Keep every costume detail, ochre yoke/collar/sash, cream long coat, violet trousers, ink and gouache style. Fullbody native 1024x1536 RGBA, hair-to-sole at least 1260px, both sole contacts centred about x512. Absolutely transparent outside figure, no shadow/floor/halo/haze, no text. No upscaling.

- Edit input: `exec-370f79d9-f3b1-439c-ad34-324b3f2d5026.png` (sha256 cecdb4f606ff946572d92d724ea2f7fa656d80adf9f0b3c7bb9ffd9a6d66c7b4).

- Edit prompt (full, verbatim):
  > Change ONLY the footwear stance in this image. Raise the screen-RIGHT boot very slightly so its sole is exactly LEVEL with the screen-LEFT sole. Both boots should point forward toward the viewer like a relaxed planted stance, not diagonally staggered. Both bottom sole edges must sit at exactly the same y coordinate; the figure is NOT walking. Keep all upper-body pixels/design unchanged: same elderly age70 person with silver hair, face, coat, ochre yoke, sash, violet trousers, pose, lighting and ink/gouache style. Keep the same large native fullbody framing on 1024x1536 RGBA, do not shrink. Genuine transparent background with no halo, shadow, floor or text.

- Selected native output: `exec-1d02b97f-39d2-4baf-82a1-0921aca1395d.png` (sha256 7ba9b28705a867080b978a9a145ec8ebc78a514374c73dadb37ce83cadcc85b2).

- Post-processing: alpha<=10 →0, alpha>=250 →255; partial-alpha fringe beyond 3px Euclidean distance from opaque figure →0; RGB cleared only where alpha=0. Uniform Lanczos downscale 1024×1536 → 892×1338 (requested factor 0.871024117); same alpha cleanup after filtering; translation (55,158), transparent pad to 1024×1536. Native measured contacts [(451.0, 1471), (599.5, 1472)]; native contact-midpoint-to-hair 1430.50px. Never upscaled.

- Candidates: 4 generated. Initial and first two edit candidates retained uneven sole contours; final edit chosen for predominantly silver hair, age70 face and planted level boot stance.

## avatar_captain_y40_back.png

- Generator: OpenAI built-in `image_gen.imagegen`. Model: exact ID/version not exposed.
- Date: 2026-10-03. Seed: none exposed.

- Initial mode: identity-preserving generation from PICKED `proposals/avatar_captain_proposal_a.png` (sha256 f5bd39f99932fafd46c14c31faca2272fe43bbba780bed076eca924b5987a74e).

- Initial prompt (full, verbatim):
  > Use case: identity-preserve. Asset: ONE production static full-body captain avatar for Stapledon's Voyage. Reference image is Mark's PICKED proposal A, Longline Navigator. Preserve this same slender androgynous warm-medium-skinned person, facial bone structure, softly swept short hair, civilian cream calf-length open long coat with rounded panels, broad ochre shoulder yoke and raised collar, ochre sash and plain oval closures, violet trousers and practical soft boots. Preserve fine ink contours, selective crosshatching, textured gouache/watercolour cloth, hand-drawn science-fiction graphic-novel style. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959 and ink #423555. Soft warm key upper left, delicate cool rim without glow. Calm non-specific face, no expressive portrait. Orthographic camera looking down 14 degrees, no perspective or oversized head. Full standing figure with relaxed arms, hands visible, both boot soles on the SAME horizontal ground line, no staggered stance. BOTH torso and boots face screen-left. Portrait 1024x1536 RGBA, figure at least 1260 pixels tall natively (fill most canvas so it can be DOWNscaled); hair near y=100 and soles near y=1450, balanced feet around x=512. Genuine transparent background, alpha exactly zero outside figure, crisp antialias <=3px, at least 16px transparent on every edge. No floor, shadow, ground ellipse, halo, haze, specks, backdrop, captions, text, letters, numbers, logos, one-sided insignia, objects, weapons or watermark. Mirror-safe clothing. Only ONE person, not a sheet. Age 70, unmistakably same person: predominantly silver-grey swept hair with a few dark streaks, leaner build, shoulders subtly settled, slight neck inclination but upright capable independent stance. Height 1.73m. Familiar coat softened ochre and neatly repaired cuffs, restrained seam repairs, same original silhouette. Three-quarter BACK view AWAY from viewer turned screen-left: rear head, broad ochre yoke across both rear shoulders, coat back and simple centre vent; tiny cheek profile only.

- Edit input: `exec-538deffe-68fd-487d-b339-20c1d0394822.png` (sha256 b98da293e60ee1393f1fbcd3ad15d8b3d02e2b1f1c6c84f442b7ec5cc9cdc986). Additional pose/costume reference: PICKED proposal A (sha256 f5bd39f99932fafd46c14c31faca2272fe43bbba780bed076eca924b5987a74e).

- Edit prompt (full, verbatim):
  > Edit this supplied BACK-facing age-SEVENTY captain, preserving all identity, predominantly silver-grey short swept hair, illustration style, cream longline coat, broad ochre yoke and raised collar, violet trousers, current level two-boot stance and framing. Add the familiar plain OCHRE fabric waist sash around the back, same costume language as picked proposal A; no insignia or objects. Make the visible tiny cheek and neck honestly age70 with fine wrinkles and slightly settled shoulders, still capable upright. Keep three-quarter BACK view away from viewer screen-left. Native 1024x1536 RGBA, fullbody figure at least1260px tall, both soles on same line and feet balanced about canvas centre. Absolutely transparent outside figure, no haze, floor, shadows or text; 16px transparent margins, crisp <=3px antialias.

- Selected native output: `exec-912fc3b0-08ed-4928-9c36-4bdde73cf8e1.png` (sha256 130a226d9fbfebffd3044bf09c3c2afec4a6cd0bbd8408ceb9176e8978b45ebf).

- Post-processing: alpha<=10 →0, alpha>=250 →255; partial-alpha fringe beyond 3px Euclidean distance from opaque figure →0; RGB cleared only where alpha=0. Uniform Lanczos downscale 1024×1536 → 896×1344 (requested factor 0.875307341); same alpha cleanup after filtering; translation (60,158), transparent pad to 1024×1536. Native measured contacts [(407.0, 1466), (626.0, 1465)]; native contact-midpoint-to-hair 1423.50px. Never upscaled.

- Candidates: 2 generated. Edit chosen for restored ochre sash and older posture, retaining level soles.

## avatar_captain_y60_front.png

- Generator: OpenAI built-in `image_gen.imagegen`. Model: exact ID/version not exposed.
- Date: 2026-10-03. Seed: none exposed.

- Initial mode: identity-preserving generation from PICKED `proposals/avatar_captain_proposal_a.png` (sha256 f5bd39f99932fafd46c14c31faca2272fe43bbba780bed076eca924b5987a74e).

- Initial prompt (full, verbatim):
  > Use case: identity-preserve. Asset: ONE production static full-body captain avatar for Stapledon's Voyage. Reference image is Mark's PICKED proposal A, Longline Navigator. Preserve this same slender androgynous warm-medium-skinned person, facial bone structure, softly swept short hair, civilian cream calf-length open long coat with rounded panels, broad ochre shoulder yoke and raised collar, ochre sash and plain oval closures, violet trousers and practical soft boots. Preserve fine ink contours, selective crosshatching, textured gouache/watercolour cloth, hand-drawn science-fiction graphic-novel style. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959 and ink #423555. Soft warm key upper left, delicate cool rim without glow. Calm non-specific face, no expressive portrait. Orthographic camera looking down 14 degrees, no perspective or oversized head. Full standing figure with relaxed arms, hands visible, both boot soles on the SAME horizontal ground line, no staggered stance. BOTH torso and boots face screen-left. Portrait 1024x1536 RGBA, figure at least 1260 pixels tall natively (fill most canvas so it can be DOWNscaled); hair near y=100 and soles near y=1450, balanced feet around x=512. Genuine transparent background, alpha exactly zero outside figure, crisp antialias <=3px, at least 16px transparent on every edge. No floor, shadow, ground ellipse, halo, haze, specks, backdrop, captions, text, letters, numbers, logos, one-sided insignia, objects, weapons or watermark. Mirror-safe clothing. Only ONE person, not a sheet. Age 90, visibly old yet recognisably SAME person: fine thin white swept hair, deeply lined calm face, age spots on warm-medium skin, slim diminished muscle mass, bony hands, narrower shoulders with a modest rounded upper back and forward neck, still standing upright and capable unaided. Height 1.70m, only 5cm shorter than original, NOT severely bent. Same cream longline coat tailored slightly narrower, lovingly repaired cuffs and hem, faded but clearly ochre yoke, violet trousers, supportive soft boots, no cane. Three-quarter FRONT view TOWARD viewer turned screen-left.

- Edit input: `exec-5be5bcb6-d799-478a-a91e-7ecae82822af.png` (sha256 3151730304509fa0fcd93ed82d711b860d7e5419ee3fffc67b9198a3636b12b4).

- Edit prompt (full, verbatim):
  > Edit this supplied captain sprite. Preserve exactly this person's identity, age, haircut, costume, palette and hand-drawn ink/gouache style. Change ONLY pose/framing and remove any outside-figure alpha residue: put BOTH boot soles on ONE identical horizontal ground line at y=1440, feet separately visible with a small gap and equal weight, no staggered foot towards the viewer. Both boots point screen-left in the same three-quarter facing as the torso. Do not turn toward the camera or change the front/back facing. Hair top near y=120 on native 1024x1536 portrait canvas so figure is at least 1260px tall before downscaling. Midpoint of the two boot ground-contact centres x=512. Genuine transparency everywhere outside the figure, no shadows, haze, halo, floor, text or watermarks. Crisp antialias <=3px. At least 16px transparent margin. Never shrink figure below 1260px. This is biological age NINETY, not fifty: make ageing CLEAR and credible. Substantially thinner white swept hair showing a little scalp, deeper wrinkles, sagging jaw and cheeks, age spots, thinner neck and bony hands, reduced upper body mass and slightly rounded shoulders and forward neck, yet capable upright. Keep the same facial bones and restrained expression. Retain the broad OCHRE yoke and high collar, ochre sash, cream long coat and violet trousers. No cane. Keep front facing.

- Edit input: `exec-eb968abd-de05-4dbb-bb06-bd3fee00fe7c.png` (sha256 873e35562ee0be2315d126897ed3ecb34dab1652b68a7c056ec1a13b7808142e). Additional pose/costume reference: PICKED proposal A (sha256 f5bd39f99932fafd46c14c31faca2272fe43bbba780bed076eca924b5987a74e).

- Edit prompt (full, verbatim):
  > Edit target image 1, pose reference image 2. Preserve image 1's identity, age, face, hair, entire costume, colours, style and front/back orientation. Change ONLY the stance and framing. Both boot soles must end on exactly the SAME horizontal ground line; no staggered foot, no depth offset. Adopt image 2's level, even two-foot standing balance. Let boots face a little forward if necessary, while body keeps its existing screen-left three-quarter turn. Physically lower the higher boot until soles align. Separate both boots by a small clear gap. Fullbody figure at least 1260px high on native 1024x1536 RGBA, midpoint of boot contact centres at x512 and common sole baseline near y1440. Preserve age; do not rejuvenate. Alpha-0 outside figure, no floor, shadow, backdrop, halo, text or new costume details. 16px alpha-0 margins, crisp antialias <=3px.

- Selected native output: `exec-05d1412e-5754-4c7e-b6a8-944d34497076.png` (sha256 af892f6984ac894163758b4eb8aac2c40a45e13c0b2bf867b864a948d291405f).

- Post-processing: alpha<=10 →0, alpha>=250 →255; partial-alpha fringe beyond 3px Euclidean distance from opaque figure →0; RGB cleared only where alpha=0. Uniform Lanczos downscale 1024×1536 → 879×1319 (requested factor 0.858646089); same alpha cleanup after filtering; translation (62,175), transparent pad to 1024×1536. Native measured contacts [(426.5, 1472), (623.5, 1475)]; native contact-midpoint-to-hair 1425.50px. Never upscaled.

- Candidates: 3 generated. Initial candidate read too young; first edit improved age but retained staggered soles; final edit chosen for aged face, reduced build and level standing pose.

## avatar_captain_y60_back.png

- Generator: OpenAI built-in `image_gen.imagegen`. Model: exact ID/version not exposed.
- Date: 2026-10-03. Seed: none exposed.

- Initial mode: identity-preserving generation from PICKED `proposals/avatar_captain_proposal_a.png` (sha256 f5bd39f99932fafd46c14c31faca2272fe43bbba780bed076eca924b5987a74e).

- Initial prompt (full, verbatim):
  > Use case: identity-preserve. Asset: ONE production static full-body captain avatar for Stapledon's Voyage. Reference image is Mark's PICKED proposal A, Longline Navigator. Preserve this same slender androgynous warm-medium-skinned person, facial bone structure, softly swept short hair, civilian cream calf-length open long coat with rounded panels, broad ochre shoulder yoke and raised collar, ochre sash and plain oval closures, violet trousers and practical soft boots. Preserve fine ink contours, selective crosshatching, textured gouache/watercolour cloth, hand-drawn science-fiction graphic-novel style. Palette cream #F2E3C7, ochre #D9A340, muted violet #3B2959 and ink #423555. Soft warm key upper left, delicate cool rim without glow. Calm non-specific face, no expressive portrait. Orthographic camera looking down 14 degrees, no perspective or oversized head. Full standing figure with relaxed arms, hands visible, both boot soles on the SAME horizontal ground line, no staggered stance. BOTH torso and boots face screen-left. Portrait 1024x1536 RGBA, figure at least 1260 pixels tall natively (fill most canvas so it can be DOWNscaled); hair near y=100 and soles near y=1450, balanced feet around x=512. Genuine transparent background, alpha exactly zero outside figure, crisp antialias <=3px, at least 16px transparent on every edge. No floor, shadow, ground ellipse, halo, haze, specks, backdrop, captions, text, letters, numbers, logos, one-sided insignia, objects, weapons or watermark. Mirror-safe clothing. Only ONE person, not a sheet. Age 90, visibly old yet recognisably SAME person: fine thin white swept hair, aged warm-medium skin, slim diminished muscle mass, bony hands, narrower shoulders, modest rounded upper back and forward neck, still standing upright and capable unaided. Height 1.70m, only 5cm shorter than original, NOT severely bent. Same cream longline coat tailored slightly narrower, repaired cuffs and hem, faded but clearly ochre yoke, violet trousers, supportive soft boots, no cane. Three-quarter BACK view AWAY from viewer turned screen-left: rear head, yoke across both rear shoulders, coat back and simple centre vent; tiny cheek profile only.

- Edit input: `exec-5a17a419-79ed-4341-a4ef-19b5bbe3f656.png` (sha256 99de30fc3f10e0cfb235123c360c3fb241298eab87a822896471f03fadc1cab5). Additional pose/costume reference: PICKED proposal A (sha256 f5bd39f99932fafd46c14c31faca2272fe43bbba780bed076eca924b5987a74e).

- Edit prompt (full, verbatim):
  > Edit this supplied captain sprite. Preserve exactly this person's identity, age, haircut, costume, palette and hand-drawn ink/gouache style. Change ONLY pose/framing and remove any outside-figure alpha residue: put BOTH boot soles on ONE identical horizontal ground line at y=1440, feet separately visible with a small gap and equal weight, no staggered foot towards the viewer. Both boots point screen-left in the same three-quarter facing as the torso. Do not turn toward the camera or change the front/back facing. Hair top near y=120 on native 1024x1536 portrait canvas so figure is at least 1260px tall before downscaling. Midpoint of the two boot ground-contact centres x=512. Genuine transparency everywhere outside the figure, no shadows, haze, halo, floor, text or watermarks. Crisp antialias <=3px. At least 16px transparent margin. Never shrink figure below 1260px. This is biological age NINETY, not fifty: make ageing CLEAR and credible. Thin white swept hair showing a little scalp, deeply lined tiny cheek profile, thinner neck and bony hands, reduced upper body mass, slightly rounded shoulders and forward neck, yet capable upright. Keep back facing. RESTORE the same broad OCHRE shoulder yoke across BOTH rear shoulders connected to ochre high collar, and an ochre fabric waist sash, matching the picked Longline Navigator design. Cream coat with restrained stitched repairs and centre vent, violet trousers and soft boots. No cane.

- Selected native output: `exec-3da19add-0878-4ec4-8c63-5addba59dc12.png` (sha256 92fd57d4076343de798249c92d5e83e29e443c4f0e909a8c11ba09352d7d3ed3).

- Post-processing: alpha<=10 →0, alpha>=250 →255; partial-alpha fringe beyond 3px Euclidean distance from opaque figure →0; RGB cleared only where alpha=0. Uniform Lanczos downscale 1024×1536 → 869×1304 (requested factor 0.849115505); same alpha cleanup after filtering; translation (100,188), transparent pad to 1024×1536. Native measured contacts [(389.0, 1476), (582.0, 1473)]; native contact-midpoint-to-hair 1441.50px. Never upscaled.

- Candidates: 2 generated. Initial candidate omitted the ochre back yoke; edit chosen for restored costume continuity, credible old age and near-level sole contours.

### Validation: avatar_captain_y0_front.png
- RGBA 1024×1536; four 16px borders alpha max 0; alpha bbox (295, 180, 753, 1443); contact midpoint [512.5, 1440.5]; sole contour difference 1px; hair-to-anchor 1259px; 719.429px/m. Partial-alpha edge within 3px of opaque silhouette. SHA256 1e294b6e491a9cf978b3446553c2d57638489de1244925cda0a92d74c73609dd.

### Validation: avatar_captain_y0_back.png
- RGBA 1024×1536; four 16px borders alpha max 0; alpha bbox (314, 179, 770, 1442); contact midpoint [512.25, 1440.0]; sole contour difference 0px; hair-to-anchor 1260px; 720.000px/m. Partial-alpha edge within 3px of opaque silhouette. SHA256 f30c7325a641a34cdddc61e8d5bd3b25c6fb71a9b9134328f8e9328a1efeb5d7.

### Validation: avatar_captain_y20_front.png
- RGBA 1024×1536; four 16px borders alpha max 0; alpha bbox (270, 179, 778, 1442); contact midpoint [512.25, 1439.5]; sole contour difference 1px; hair-to-anchor 1260px; 720.000px/m. Partial-alpha edge within 3px of opaque silhouette. SHA256 504a28f9949009710b1673fd0b368b85235a5a4e5a2f228f8571eaa38e908549.

### Validation: avatar_captain_y20_back.png
- RGBA 1024×1536; four 16px borders alpha max 0; alpha bbox (302, 180, 775, 1442); contact midpoint [512.25, 1440.0]; sole contour difference 2px; hair-to-anchor 1259px; 719.429px/m. Partial-alpha edge within 3px of opaque silhouette. SHA256 b94eb896352a4aa184cc6e4fab68778c9092c72fe7adf9ba0ec596ff0217a405.

### Validation: avatar_captain_y40_front.png
- RGBA 1024×1536; four 16px borders alpha max 0; alpha bbox (282, 193, 761, 1442); contact midpoint [512.25, 1439.5]; sole contour difference 1px; hair-to-anchor 1246px; 720.231px/m. Partial-alpha edge within 3px of opaque silhouette. SHA256 eef651298ccac2790b37749de22c6f84dd7492ce1674d23a83cbb6a28e46702a.

### Validation: avatar_captain_y40_back.png
- RGBA 1024×1536; four 16px borders alpha max 0; alpha bbox (306, 194, 768, 1442); contact midpoint [512.25, 1440.0]; sole contour difference 0px; hair-to-anchor 1245px; 719.653px/m. Partial-alpha edge within 3px of opaque silhouette. SHA256 63f8121ac4ffcd15efdeb50f0c600d820da89d3a20131c9df3c5e83c489b6415.

### Validation: avatar_captain_y60_front.png
- RGBA 1024×1536; four 16px borders alpha max 0; alpha bbox (291, 215, 758, 1443); contact midpoint [512.5, 1440.0]; sole contour difference 2px; hair-to-anchor 1224px; 720.000px/m. Partial-alpha edge within 3px of opaque silhouette. SHA256 c359aa7fb78cb9da36e401bff853785db1d3c5fea48ef463ba0256fdd377cee0.

### Validation: avatar_captain_y60_back.png
- RGBA 1024×1536; four 16px borders alpha max 0; alpha bbox (349, 215, 781, 1442); contact midpoint [512.0, 1439.5]; sole contour difference 3px; hair-to-anchor 1224px; 720.000px/m. Partial-alpha edge within 3px of opaque silhouette. SHA256 1d5ca66ec8af66e635ce27961926e25b36cd4762ca3abc9c95501362ab42e210.

## avatar_captain_sheet.png
- Generator: Pillow deterministic assembly; model not applicable.
- Date: 2026-10-03. Seed: none.
- Mode: compositing all eight delivered avatar PNGs.
- Prompt (full, verbatim): none; deterministic assembly. Source prompts appear above.
- Post-processing: 4096×3584 RGBA sheet, four stage columns and front/back rows; full native canvases over split grey/dark panels, labels and uniformly Lanczos-downscaled 115px and 67px figure-height previews over both backgrounds. No upscaling.
- Candidates: one assembled sheet.
- SHA256: 0d902201a7e6890b6b4b925cda2e3978c60891c9dff492e39d8588f82eda244c
