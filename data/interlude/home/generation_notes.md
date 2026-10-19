# Home-time tier illustrations (review card, Home page)

Twenty-eight landscape illustrations for the sixteen home-time tiers of Stapledon's Voyage (R2-HOME-TIERS; ledger D-86: each tier has a pool of variants and the voyage's seed picks one). Art owned by Sunholo.

- **2026-10-16 session** (below, first): seven illustrations, one per tier of the old seven-tier ladder. They ship as variant 0 of the new tiers 0, 2, 4, 6, 8, 10 and 13 (old tier K is now `tier<new>_v0.webp`; each heading says which). Three of that session's rejected candidates now ship as variant 1 (D-86, Mark: "these are all good for now"): tier2_c1 as `tier4_v1`, tier3_c2 as `tier6_v1`, tier4_c1 as `tier8_v1`. The others stay excluded for the reasons given (tier0_c1 figures in the text column, tier1_c1 and tier1b_c1 text-like marks, tier1_c2 the wrong town, tier5_c1 kitsch, tier6_c1 two moons).
- **2026-10-19 session** (at the end): two candidates each for the nine new tiers 1, 3, 5, 7, 9, 11, 12, 14 and 15; every one ships (c1 as v0, c2 as v1).

## Provenance and review limits

- Driver: `env -u OPENAI_API_KEY codex exec -m gpt-6.1-sol` (codex-cli 0.162.0), one non-interactive session per tier. The session rollouts record `"model":"gpt-6.1-sol"` (provider `openai`, ChatGPT login; no API key, no OpenRouter). That is the agent model, not the image model.
- Generator: OpenAI built-in `image_gen__imagegen` tool (Codex imagegen). Exact image model id/version: **not exposed by the tool**; none is invented. Seed: none exposed. No size parameter is exposed; 1536x1024 landscape was requested inside the prompt and every output is natively 1536 x 1024.
- Every call passed one reference image, `stapledons-godot-attended/assets/characters/medic/portrait_medic_y0_neutral.png` (sha256 `93a02944772201d3e854a283342fd189409995e85a91796d5197a9e5f0be0017`), as `referenced_image_paths` with `transparent_background: false`. It is a style reference only; the prompt forbids drawing that woman or any face from it. No face from it appears in any output.
- Each tier's two calls are independent generations from the same prompt; neither candidate is an edit of another. The prompt strings submitted to the tool were extracted from the Codex session rollouts and compared byte-for-byte with the prompt files below: all match.
- Each prompt is a shared style/viewpoint block plus a per-tier scene paragraph, so the set reads as one place across time: a hillside path above a Mediterranean-style coastal town with a radio dish on a headland at right, the left third kept calm for a text overlay.
- Candidate PNGs in `candidates/` are byte-for-byte copies of the generator outputs in `~/.codex/generated_images/` (hashes verified equal). Delivered `tierN.png` files are byte-for-byte copies of the kept candidates.
- Post-processing: none on any delivered image. No resampling, crop, padding, colour change or re-encoding. Never upscaled.
- Text check: every candidate was opened and inspected at full frame. Posters, the bus and the tier 6 orbital arcs were also inspected at 1:1 crops. Two candidates were rejected for text-like marks.
- Contact sheet `contact_sheet.png` (2384 x 816) is a review aid only: the seven delivered images in tier order, 4 + 3 grid, each downscaled from 1536x1024 to 576x384 with Lanczos in headless Godot 4.7.2. No upscaling.
- Tier 1 was regenerated once (round "b") after the first contact sheet: round-1 candidate 2 showed a northern slate-roofed harbour town that broke continuity with the terracotta town in tiers 0, 2 and 3. The round-b scene paragraph names the town's look explicitly and asks for posters "completely unmarked".

## Shared style block (verbatim, first paragraph of every prompt)

> Asset: one wide landscape illustration for the Home page of a review card in the game Stapledon's Voyage, a relativistic starship voyage in which decades to millennia pass on Earth while the crew lives only a few years. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour on warm paper, muted earthy palette with restrained teal, ochre and coral accents. The attached image is a style reference only for line, hatching, paint texture and palette; do not draw that woman or any face from it. Landscape 3:2 at native 1536x1024. Fixed viewpoint shared by the whole series: from a grassy hillside path high above a small coastal town that climbs a slope toward a rocky headland on the right of the frame, where a large radio telescope dish stands; the bay and open sea fill the middle distance under a wide sky. Keep the left third of the frame calm and uncluttered (open sky, soft sea, quiet meadow) so a text panel can overlay it. Absolutely no text, letters, numbers, digits, writing, signage, symbols, flags, logos, brands, captions, frames, borders, UI or watermark anywhere in the image. No recognisable real people or real places. Mood: melancholy but not despairing, grounded and restrained, never kitsch.

## tier0.png (now tier0_v0.webp; tier 0, < 1 year)

- Home time: < 1 year. Card line: "Less than a year at home. They are still watching for word from you."
- Delivered sha256: `8513eb0ea5063524e0c0008b8781834a5953fabbb88848869334782d67911e1c`; byte-for-byte copy of `candidates/tier0_c2.png`.
- Date: 2026-10-16. Generator: OpenAI built-in `image_gen__imagegen` via Codex (agent model gpt-6.1-sol). Image model: exact id/version not exposed. Seed: none exposed.
- Native size: 1536 x 1024. Post-processing: none. Never upscaled.
- Shows: Dusk just after launch: a contrail and a climbing point of light over the sea, a family seen from behind at a hillside rail with a child on a shoulder, the lit dish and glowing town at right.

- Candidates: 2 generated; kept c2.

### Candidate tier0_c1 — rejected

- File: `candidates/tier0_c1.png`. Native output: 1536 x 1024 RGB; sha256 `a027c9845275266c10b2a6d67642f177dcc563c8a0ca6663b28442c6f802851f`.
- Generator output filename: `exec-74f24e85-23b6-427d-a345-6addd52103e1.png`.
- Decision: Strong, but the family stands inside the left third, where the text panel must sit.
- Prompt (full, verbatim): identical to the tier0 prompt below.

### Candidate tier0_c2 — kept

- File: `candidates/tier0_c2.png`. Native output: 1536 x 1024 RGB; sha256 `8513eb0ea5063524e0c0008b8781834a5953fabbb88848869334782d67911e1c`.
- Generator output filename: `exec-cb386cbf-d9c7-4046-a533-f3db1becd5b0.png`.
- Decision: The figures sit centre-right, leaving the left third as calm sea and sunset sky; tender, expectant mood; no text-like marks.
- Prompt (full, verbatim): identical to the tier0 prompt below.

### Prompt tier0 (full, verbatim)

> Asset: one wide landscape illustration for the Home page of a review card in the game Stapledon's Voyage, a relativistic starship voyage in which decades to millennia pass on Earth while the crew lives only a few years. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour on warm paper, muted earthy palette with restrained teal, ochre and coral accents. The attached image is a style reference only for line, hatching, paint texture and palette; do not draw that woman or any face from it. Landscape 3:2 at native 1536x1024. Fixed viewpoint shared by the whole series: from a grassy hillside path high above a small coastal town that climbs a slope toward a rocky headland on the right of the frame, where a large radio telescope dish stands; the bay and open sea fill the middle distance under a wide sky. Keep the left third of the frame calm and uncluttered (open sky, soft sea, quiet meadow) so a text panel can overlay it. Absolutely no text, letters, numbers, digits, writing, signage, symbols, flags, logos, brands, captions, frames, borders, UI or watermark anywhere in the image. No recognisable real people or real places. Mood: melancholy but not despairing, grounded and restrained, never kitsch.
>
> Scene, less than a year after departure: early evening, the departure still fresh. A thin, fading launch contrail curves up into the deepening blue sky above the sea and one bright point of light is climbing away. The white radio dish on the headland is tilted upward, freshly painted, its service lights on. On the hillside path a small family stands at a wooden rail seen from behind, a child on a parent's shoulders, all looking up at the sky, waiting for word; faces not visible. The town below is lit and alive, windows glowing warm. Tender, expectant, a little anxious.

## tier1.png (now tier2_v0.webp; tier 2, 3-10 years)

- Home time: < 10 years. Card line: "N years at home. The news you left with is history."
- Delivered sha256: `96e30bed8c7d2921809462c8c89eff59c00282ab3bd653ed9da5b6e1c8a6057b`; byte-for-byte copy of `candidates/tier1b_c2.png`.
- Date: 2026-10-16. Generator: OpenAI built-in `image_gen__imagegen` via Codex (agent model gpt-6.1-sol). Image model: exact id/version not exposed. Seed: none exposed.
- Native size: 1536 x 1024. Post-processing: none. Never upscaled.
- Shows: An ordinary sunny afternoon in the same terracotta-and-cypress town: laundry, a bus on the viaduct road, fishing boats, a stray dog on the path, blank sun-bleached posters on the wall; nobody looks up at the dish.

- Candidates: 4 generated over two rounds (round 1: c1, c2; round b: c1, c2); kept round-b c2.

### Candidate tier1_c1 — rejected

- File: `candidates/tier1_c1.png`. Native output: 1536 x 1024 RGB; sha256 `d73cba5c97e1223e66dfc16ed211812a4fc190645cc7d8b4a0055eb7f0e13406`.
- Generator output filename: `exec-a337b3cb-025b-4717-8caf-d170a6d485a4.png`.
- Decision: The torn posters on the right wall carry scribbled line marks that read as writing at 1:1. This fails the no-text rule.
- Prompt (full, verbatim): identical to the tier1 prompt below.

### Candidate tier1_c2 — rejected (continuity)

- File: `candidates/tier1_c2.png`. Native output: 1536 x 1024 RGB; sha256 `9367d86535b67c3a6d766b76821b075c75cf095a7e40b578a014f71d5fde6a32`.
- Generator output filename: `exec-eed0bb1b-fe22-439c-8a52-776adca412d9.png`.
- Decision: The posters are blank and the image is clean, but its grey slate-roofed northern harbour town clashed with the terracotta town in tiers 0, 2 and 3 on the contact sheet. Tier 1 was regenerated as round b.
- Prompt (full, verbatim): identical to the tier1 prompt below.

### Candidate tier1b_c1 — rejected

- File: `candidates/tier1b_c1.png`. Native output: 1536 x 1024 RGB; sha256 `737c40ae5c73ee7858cd8260be8603642500d748595691090801eb28b929feef`.
- Generator output filename: `exec-9084159a-13d5-4776-a520-9bf7b39c7dd2.png`.
- Decision: Good continuity, but the orange torn poster on the right has a small dark glyph-like mark at 1:1. Rejected under the no-text rule.
- Prompt (full, verbatim): identical to the tier1b prompt below.

### Candidate tier1b_c2 — kept

- File: `candidates/tier1b_c2.png`. Native output: 1536 x 1024 RGB; sha256 `96e30bed8c7d2921809462c8c89eff59c00282ab3bd653ed9da5b6e1c8a6057b`.
- Generator output filename: `exec-f6b1d619-d1be-4ff1-a720-c2b87becc83b.png`.
- Decision: Matches the town of tiers 0, 2 and 3. Posters blank, bus unmarked at 1:1. The left third is calm sea and sky, and the mood is everyday and indifferent.
- Prompt (full, verbatim): identical to the tier1b prompt below.

### Prompt tier1 (full, verbatim)

> Asset: one wide landscape illustration for the Home page of a review card in the game Stapledon's Voyage, a relativistic starship voyage in which decades to millennia pass on Earth while the crew lives only a few years. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour on warm paper, muted earthy palette with restrained teal, ochre and coral accents. The attached image is a style reference only for line, hatching, paint texture and palette; do not draw that woman or any face from it. Landscape 3:2 at native 1536x1024. Fixed viewpoint shared by the whole series: from a grassy hillside path high above a small coastal town that climbs a slope toward a rocky headland on the right of the frame, where a large radio telescope dish stands; the bay and open sea fill the middle distance under a wide sky. Keep the left third of the frame calm and uncluttered (open sky, soft sea, quiet meadow) so a text panel can overlay it. Absolutely no text, letters, numbers, digits, writing, signage, symbols, flags, logos, brands, captions, frames, borders, UI or watermark anywhere in the image. No recognisable real people or real places. Mood: melancholy but not despairing, grounded and restrained, never kitsch.
>
> Scene, several years later: the same view on an ordinary bright afternoon; the world has simply moved on. Laundry flutters on lines between the town houses, a small bus travels the coast road, fishing boats in the bay, a few new roofs among the old ones. On a stone wall beside the hillside path, old paper posters are sun-bleached, peeling and torn to blank pale scraps with no legible marks. The radio dish still works but no one is looking up; it points at an ordinary angle. Nobody on the hillside path except a passing dog. Wistful, everyday, quietly indifferent.

### Prompt tier1b (full, verbatim)

> Asset: one wide landscape illustration for the Home page of a review card in the game Stapledon's Voyage, a relativistic starship voyage in which decades to millennia pass on Earth while the crew lives only a few years. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour on warm paper, muted earthy palette with restrained teal, ochre and coral accents. The attached image is a style reference only for line, hatching, paint texture and palette; do not draw that woman or any face from it. Landscape 3:2 at native 1536x1024. Fixed viewpoint shared by the whole series: from a grassy hillside path high above a small coastal town that climbs a slope toward a rocky headland on the right of the frame, where a large radio telescope dish stands; the bay and open sea fill the middle distance under a wide sky. Keep the left third of the frame calm and uncluttered (open sky, soft sea, quiet meadow) so a text panel can overlay it. Absolutely no text, letters, numbers, digits, writing, signage, symbols, flags, logos, brands, captions, frames, borders, UI or watermark anywhere in the image. No recognisable real people or real places. Mood: melancholy but not despairing, grounded and restrained, never kitsch.
>
> Scene, several years later: the same view on an ordinary bright afternoon; the world has simply moved on. The same warm Mediterranean hill town of ochre walls, terracotta roofs and dark cypresses climbs toward the headland. Laundry flutters on lines between the houses, a small bus travels the coast road, fishing boats in the bay, a few new roofs among the old ones. On a stone wall beside the hillside path, a few old paper posters have been bleached by sun and rain to plain blank pale scraps, completely unmarked. The radio dish still works but no one is looking up; it points at an ordinary angle. Nobody on the hillside path except a passing dog. Wistful, everyday, quietly indifferent.

## tier2.png (now tier4_v0.webp; tier 4, 20-35 years)

- Home time: < 30 years. Card line: "The children you knew have grown up; your name is a story they half remember."
- Delivered sha256: `0229d2d94f01c08dc96e96e957f3b6b6942003885a5aaa40c39b4e1a1f0b12c9`; byte-for-byte copy of `candidates/tier2_c2.png`.
- Date: 2026-10-16. Generator: OpenAI built-in `image_gen__imagegen` via Codex (agent model gpt-6.1-sol). Image model: exact id/version not exposed. Seed: none exposed.
- Native size: 1536 x 1024. Post-processing: none. Never upscaled.
- Shows: Golden late-summer evening: the town has spread up the slope and grown a long breakwater. A young adult and a small child walk the path from behind, the adult pointing out to sea. A weathered bench holds a bundle of long-dried flowers.

- Candidates: 2 generated; kept c2.

### Candidate tier2_c1 — rejected 2026-10-16; ships since 2026-10-19 as tier4_v1.webp (D-86)

- File: `candidates/tier2_c1.png`. Native output: 1536 x 1024 RGB; sha256 `befdf3afea8ba8e87cd8022e2e08e5b7f0a5f16cfe516975521cb858846e15e4`.
- Generator output filename: `exec-3969dab0-945c-4db2-9c3e-2d9a5e0c9b3b.png`.
- Decision: Good mood, but the bench is large in the lower left and the overall frame is busier; the grown town reads less clearly.
- Prompt (full, verbatim): identical to the tier2 prompt below.

### Candidate tier2_c2 — kept

- File: `candidates/tier2_c2.png`. Native output: 1536 x 1024 RGB; sha256 `0229d2d94f01c08dc96e96e957f3b6b6942003885a5aaa40c39b4e1a1f0b12c9`.
- Generator output filename: `exec-8b3169e5-51b9-443d-aae9-57bc50800320.png`.
- Decision: Figures right of centre, upper-left sky and sea calm; the visibly expanded town and harbour carry the passage of time; no text-like marks.
- Prompt (full, verbatim): identical to the tier2 prompt below.

### Prompt tier2 (full, verbatim)

> Asset: one wide landscape illustration for the Home page of a review card in the game Stapledon's Voyage, a relativistic starship voyage in which decades to millennia pass on Earth while the crew lives only a few years. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour on warm paper, muted earthy palette with restrained teal, ochre and coral accents. The attached image is a style reference only for line, hatching, paint texture and palette; do not draw that woman or any face from it. Landscape 3:2 at native 1536x1024. Fixed viewpoint shared by the whole series: from a grassy hillside path high above a small coastal town that climbs a slope toward a rocky headland on the right of the frame, where a large radio telescope dish stands; the bay and open sea fill the middle distance under a wide sky. Keep the left third of the frame calm and uncluttered (open sky, soft sea, quiet meadow) so a text panel can overlay it. Absolutely no text, letters, numbers, digits, writing, signage, symbols, flags, logos, brands, captions, frames, borders, UI or watermark anywhere in the image. No recognisable real people or real places. Mood: melancholy but not despairing, grounded and restrained, never kitsch.
>
> Scene, about twenty-five years later: late-summer golden light. The town has grown and changed: trees once saplings are now tall, newer houses spread up the slope, the harbour has a modern breakwater. The radio dish looks dated, its paint chalky and weathered. On the hillside path a young adult walks with a small child, seen from behind, the adult pointing vaguely toward the sky over the sea as if retelling an old half-remembered story; faces not visible. A weathered wooden bench beside the path holds a small bunch of long-dried flowers. Nostalgic, gentle, a story fading into legend.

## tier3.png (now tier6_v0.webp; tier 6, 55-90 years)

- Home time: < 80 years. Card line: "Your parents' generation is gone; the friends you left are old."
- Delivered sha256: `9f44e1145f389c5d3439b4dc67b75f8ae52f812433c1126a117e591e2b9e0ff8`; byte-for-byte copy of `candidates/tier3_c1.png`.
- Date: 2026-10-16. Generator: OpenAI built-in `image_gen__imagegen` via Codex (agent model gpt-6.1-sol). Image model: exact id/version not exposed. Seed: none exposed.
- Native size: 1536 x 1024. Post-processing: none. Never upscaled.
- Shows: Grey overcast autumn: the dish is rusted with part of its rim gone, behind a sagging fence. The town is rebuilt as pale terraced blocks. A very old person sits alone on a bench with a cane, seen from behind, looking at the sea.

- Candidates: 2 generated; kept c1.

### Candidate tier3_c1 — kept

- File: `candidates/tier3_c1.png`. Native output: 1536 x 1024 RGB; sha256 `9f44e1145f389c5d3439b4dc67b75f8ae52f812433c1126a117e591e2b9e0ff8`.
- Generator output filename: `exec-9596790b-cab4-40ef-8c78-c03448a2720f.png`.
- Decision: The broken rim reads clearly. Autumn colour carries the warm palette forward, and the solitary figure is elegiac without despair. No text-like marks.
- Prompt (full, verbatim): identical to the tier3 prompt below.

### Candidate tier3_c2 — rejected 2026-10-16; ships since 2026-10-19 as tier6_v1.webp (D-86)

- File: `candidates/tier3_c2.png`. Native output: 1536 x 1024 RGB; sha256 `ef141b439650632df69c1f2c14f576796dd92b7519aab350a433a6b7b82b9b50`.
- Generator output filename: `exec-676d14d5-b545-465f-ac20-f5dc7417d71c.png`.
- Decision: Equally clean. Its more brutalist town and greener slope make a weaker bridge to tiers 2 and 4.
- Prompt (full, verbatim): identical to the tier3 prompt below.

### Prompt tier3 (full, verbatim)

> Asset: one wide landscape illustration for the Home page of a review card in the game Stapledon's Voyage, a relativistic starship voyage in which decades to millennia pass on Earth while the crew lives only a few years. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour on warm paper, muted earthy palette with restrained teal, ochre and coral accents. The attached image is a style reference only for line, hatching, paint texture and palette; do not draw that woman or any face from it. Landscape 3:2 at native 1536x1024. Fixed viewpoint shared by the whole series: from a grassy hillside path high above a small coastal town that climbs a slope toward a rocky headland on the right of the frame, where a large radio telescope dish stands; the bay and open sea fill the middle distance under a wide sky. Keep the left third of the frame calm and uncluttered (open sky, soft sea, quiet meadow) so a text panel can overlay it. Absolutely no text, letters, numbers, digits, writing, signage, symbols, flags, logos, brands, captions, frames, borders, UI or watermark anywhere in the image. No recognisable real people or real places. Mood: melancholy but not despairing, grounded and restrained, never kitsch.
>
> Scene, about seventy years later: a grey overcast autumn day with low cloud. The radio dish is decommissioned and streaked with rust, a section of its rim missing, a chain-link fence sagging around it. The town below has been remodelled in unfamiliar later architecture, the old houses mostly replaced. On a worn bench on the hillside path a single very old person sits alone wrapped in a coat, seen from behind, a walking stick beside them, looking out at the sea. Fallen leaves on the path. Elegiac, solitary, quietly enduring.

## tier4.png (now tier8_v0.webp; tier 8, 130-250 years)

- Home time: < 130 years. Card line: "Everyone you knew is gone."
- Delivered sha256: `bfd69e924ea322aec5cc4fa2744ee19c9d2f57886acb8ae7bf2ea68f72e29e70`; byte-for-byte copy of `candidates/tier4_c2.png`.
- Date: 2026-10-16. Generator: OpenAI built-in `image_gen__imagegen` via Codex (agent model gpt-6.1-sol). Image model: exact id/version not exposed. Seed: none exposed.
- Native size: 1536 x 1024. Post-processing: none. Never upscaled.
- Shows: Pale winter light and thin snow. The dish has collapsed into an ivy-grown wreck. Low domed buildings of a later era stand among roofless stone ruins of the old town. The path is overgrown, gulls wheel overhead, and there are no people.

- Candidates: 2 generated; kept c2.

### Candidate tier4_c1 — rejected 2026-10-16; ships since 2026-10-19 as tier8_v1.webp (D-86)

- File: `candidates/tier4_c1.png`. Native output: 1536 x 1024 RGB; sha256 `acd42fd8df31169f18574a60974757cfa884ec21b67e2bd97d4a8b1894dded7d`.
- Generator output filename: `exec-c273a4b9-0138-48cc-bcab-9335f05966f8.png`.
- Decision: Strong and clean. Its foreground brambles crowd the bottom band, and the sky is busier than c2's.
- Prompt (full, verbatim): identical to the tier4 prompt below.

### Candidate tier4_c2 — kept

- File: `candidates/tier4_c2.png`. Native output: 1536 x 1024 RGB; sha256 `bfd69e924ea322aec5cc4fa2744ee19c9d2f57886acb8ae7bf2ea68f72e29e70`.
- Generator output filename: `exec-7f12c6ed-63e1-46ed-adb9-aec8f849de68.png`.
- Decision: Wide calm sky and sea in the left and upper frame. The ruin-and-domes mix reads as 'no one left who remembers'. No text-like marks.
- Prompt (full, verbatim): identical to the tier4 prompt below.

### Prompt tier4 (full, verbatim)

> Asset: one wide landscape illustration for the Home page of a review card in the game Stapledon's Voyage, a relativistic starship voyage in which decades to millennia pass on Earth while the crew lives only a few years. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour on warm paper, muted earthy palette with restrained teal, ochre and coral accents. The attached image is a style reference only for line, hatching, paint texture and palette; do not draw that woman or any face from it. Landscape 3:2 at native 1536x1024. Fixed viewpoint shared by the whole series: from a grassy hillside path high above a small coastal town that climbs a slope toward a rocky headland on the right of the frame, where a large radio telescope dish stands; the bay and open sea fill the middle distance under a wide sky. Keep the left third of the frame calm and uncluttered (open sky, soft sea, quiet meadow) so a text panel can overlay it. Absolutely no text, letters, numbers, digits, writing, signage, symbols, flags, logos, brands, captions, frames, borders, UI or watermark anywhere in the image. No recognisable real people or real places. Mood: melancholy but not despairing, grounded and restrained, never kitsch.
>
> Scene, about a hundred and twenty years later: pale winter light, thin snow on the grass. The radio dish has collapsed and lies tilted and broken on the headland, its frame overgrown with ivy and brambles. The hillside path is overgrown and the bench is gone. The town below is quieter and unfamiliar: low rounded buildings of a later era among a few roofless ruins of the old houses. No people anywhere; only seabirds wheeling over the bay. Empty, hushed, no one left who remembers.

## tier5.png (now tier10_v0.webp; tier 10, 500-1000 years)

- Home time: < 1000 years. Card line: "No one alive on Earth was born when you left. The countries you knew may not exist."
- Delivered sha256: `b55a3c62fde9c1dfe1719357093d50b1b7041b4e3570ccc26c070341e9229453`; byte-for-byte copy of `candidates/tier5_c2.png`.
- Date: 2026-10-16. Generator: OpenAI built-in `image_gen__imagegen` via Codex (agent model gpt-6.1-sol). Image model: exact id/version not exposed. Seed: none exposed.
- Native size: 1536 x 1024. Post-processing: none. Never upscaled.
- Shows: The sea has drowned the old town, leaving only broken arches standing in the water and the dish's mossy foundation ring on the islanded headland. Terraced organic architecture of an unfamiliar later people lines the far cliffs, and sail-like craft cross the bay.

- Candidates: 2 generated; kept c2.

### Candidate tier5_c1 — rejected

- File: `candidates/tier5_c1.png`. Native output: 1536 x 1024 RGB; sha256 `fcc91cfb5a56ba692cc128ae7a1e4e58eb0c75d48b962cf79ed13dbc2f2f694c`.
- Generator output filename: `exec-60991039-6402-4e40-9e0c-3491e8683fb8.png`.
- Decision: Clean, but its spired cliff city leans towards high-fantasy kitsch, and the composition is busier.
- Prompt (full, verbatim): identical to the tier5 prompt below.

### Candidate tier5_c2 — kept

- File: `candidates/tier5_c2.png`. Native output: 1536 x 1024 RGB; sha256 `b55a3c62fde9c1dfe1719357093d50b1b7041b4e3570ccc26c070341e9229453`.
- Generator output filename: `exec-c0ec0ebe-3333-4554-b406-f12199494243.png`.
- Decision: More restrained architecture. The left third is open sea and a low sun, and the drowned arches carry the loss quietly. No text-like marks. A mild spire tendency remains.
- Prompt (full, verbatim): identical to the tier5 prompt below.

### Prompt tier5 (full, verbatim)

> Asset: one wide landscape illustration for the Home page of a review card in the game Stapledon's Voyage, a relativistic starship voyage in which decades to millennia pass on Earth while the crew lives only a few years. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour on warm paper, muted earthy palette with restrained teal, ochre and coral accents. The attached image is a style reference only for line, hatching, paint texture and palette; do not draw that woman or any face from it. Landscape 3:2 at native 1536x1024. Fixed viewpoint shared by the whole series: from a grassy hillside path high above a small coastal town that climbs a slope toward a rocky headland on the right of the frame, where a large radio telescope dish stands; the bay and open sea fill the middle distance under a wide sky. Keep the left third of the frame calm and uncluttered (open sky, soft sea, quiet meadow) so a text panel can overlay it. Absolutely no text, letters, numbers, digits, writing, signage, symbols, flags, logos, brands, captions, frames, borders, UI or watermark anywhere in the image. No recognisable real people or real places. Mood: melancholy but not despairing, grounded and restrained, never kitsch.
>
> Scene, about eight hundred years later: the sea has risen and drowned the old town; only the tops of a few broken stone walls break the water of the widened bay. On the rocky headland, now nearly an island, a mossy ring of old concrete foundation is all that remains of the dish. The hillside is wild grassland and wind-shaped pines. On the far shore across the bay, an unfamiliar later civilisation: graceful terraced organic architecture grown into the cliffs, soft amber lights, slender sail-like craft on the water. No figures in the foreground. Strange, calm, a world that never knew the old one.

## tier6.png (now tier13_v0.webp; tier 13, 10000-50000 years)

- Home time: beyond. Card line: "Longer than recorded history before you left. Whatever answers your signal will not be the Earth you left."
- Delivered sha256: `a534e46430ad574bedfc33e47f56b6a6c440dec0686a4b313c268c7b1f2fdf62`; byte-for-byte copy of `candidates/tier6_c2.png`.
- Date: 2026-10-16. Generator: OpenAI built-in `image_gen__imagegen` via Codex (agent model gpt-6.1-sol). Image model: exact id/version not exposed. Seed: none exposed.
- Native size: 1536 x 1024. Post-processing: none. Never upscaled.
- Shows: Deep-time dusk: the coast is reshaped into a tidal plain of pools, the headland worn to a lone sea stack, and the foreground is lichened rock. A faint orbital ring-thread crosses the starry sky, and one immense slender structure rises on the horizon as if listening.

- Candidates: 2 generated; kept c2.

### Candidate tier6_c1 — rejected

- File: `candidates/tier6_c1.png`. Native output: 1536 x 1024 RGB; sha256 `a9f25c5cb99e164c84c1962f83ff7543d614a718be38f69be83a4fc31b122eab`.
- Generator output filename: `exec-e7a7efcc-949d-4ae7-8769-45845d4430a1.png`.
- Decision: Clean (arcs checked at 1:1). Its two crescent moons make the scene read as another planet rather than a deep-future Earth.
- Prompt (full, verbatim): identical to the tier6 prompt below.

### Candidate tier6_c2 — kept

- File: `candidates/tier6_c2.png`. Native output: 1536 x 1024 RGB; sha256 `a534e46430ad574bedfc33e47f56b6a6c440dec0686a4b313c268c7b1f2fdf62`.
- Generator output filename: `exec-b6404419-76e6-48aa-9d03-6b08d89f3c5b.png`.
- Decision: Grounded as Earth, with a single sun and moonless dusk. The listening spire is centred on the setting sun, and the orbital arc is clean at 1:1 with no glyphs. The left third is calm sky over the tidal plain.
- Prompt (full, verbatim): identical to the tier6 prompt below.

### Prompt tier6 (full, verbatim)

> Asset: one wide landscape illustration for the Home page of a review card in the game Stapledon's Voyage, a relativistic starship voyage in which decades to millennia pass on Earth while the crew lives only a few years. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour on warm paper, muted earthy palette with restrained teal, ochre and coral accents. The attached image is a style reference only for line, hatching, paint texture and palette; do not draw that woman or any face from it. Landscape 3:2 at native 1536x1024. Fixed viewpoint shared by the whole series: from a grassy hillside path high above a small coastal town that climbs a slope toward a rocky headland on the right of the frame, where a large radio telescope dish stands; the bay and open sea fill the middle distance under a wide sky. Keep the left third of the frame calm and uncluttered (open sky, soft sea, quiet meadow) so a text panel can overlay it. Absolutely no text, letters, numbers, digits, writing, signage, symbols, flags, logos, brands, captions, frames, borders, UI or watermark anywhere in the image. No recognisable real people or real places. Mood: melancholy but not despairing, grounded and restrained, never kitsch.
>
> Scene, deep time, many thousands of years later: the coastline is reshaped beyond recognition; the headland has eroded into a lone sea stack, the hillside is bare windswept rock and lichen, the bay a broad tidal plain of pools reflecting the sky. Dusk, with an unfamiliar sky: a faint, vast arc of distant orbital structures crossing the heavens like a pale thread of light, and stars emerging. On the far horizon a single immense, slender, unfathomable structure of unknown purpose rises toward the stars, as if listening. No people, no ruins of the old town. Awe, depth and quiet dignity; the Earth that answers will not be the Earth that was left.

## Contact sheet

- `contact_sheet.png`: sha256 `bc162b1a76c495acf004300530cd4dcfbed258ee804900377a0de53611260329`, 2384 x 816, review aid only (Lanczos downscale to 576x384 tiles, headless Godot). Not a game asset.
- Set check: the hillside path, the headland at right, the sea at left and the same ink-and-gouache hand run through all seven. Light moves from launch dusk, through everyday afternoon, golden evening, overcast autumn and winter, to a drowned-coast sunset and deep-time dusk. The dish is lit, then routine, dated, rusted, collapsed, a foundation ring, and finally gone, replaced by an unknown listening spire. Figures go from a waiting family, to a passing dog, to a parent and child, to a lone old person, and then to no one.

## In the game repository

- Landed 2026-10-16 in `stapledons-godot` as `data/interlude/home/tier<n>.webp` (renamed `tier<new>_v0.webp` on 2026-10-19, R2-HOME-TIERS) (lossy WebP at native 1536x1024, `cwebp -q 88 -m 6 -sharp_yuv`), read by `ui/crossing_review.gd` for the crossing review's Home page. The PNG masters described above are not in git (D-18): they are in the public bucket at `gs://stapledons-voyage-assets/site/<sha256>.png`. `SOURCES` beside this file pins both the WebP and the master hashes, with the master URLs.
- The same seven pictures were on the website's concept-art page (PR #259). Since R2-HOME-TIERS the page shows every variant of tiers 0-12 only: tiers from ten thousand years on show Earth's fate in canon (the rogue black hole), so old tier 6 (now tier 13) came down.

# 2026-10-19 session: the nine new tiers (R2-HOME-TIERS)

## Provenance

- Driver: `home_art2/run.sh <x>` (zsh), one non-interactive session per scene: `env -u OPENAI_API_KEY codex exec -m gpt-6.1-sol --skip-git-repo-check -s workspace-write -i <reference> -- <instruction>`. The instruction asks for exactly two separate, independent calls of the built-in image tool with the image prompt verbatim, a byte-for-byte copy of each output to `candidates/tier_<x>_c1.png` and `_c2.png`, and a report of the generated paths, the submitted prompt, the model id and the size. The session logs are `home_art2/logs/<x>.log` (codex-cli 0.162.0, `model: gpt-6.1-sol`, provider openai, every run `exit 0`).
- Generator: OpenAI built-in image tool via Codex. Every call reported the image model id and version as **not exposed**; none is invented. Seed: none exposed. No size parameter is exposed; 1536x1024 was asked for in the prompt and every output is natively 1536 x 1024.
- Reference image, every call: `stapledons-godot-attended/assets/characters/medic/portrait_medic_y0_neutral.png` (sha256 `93a02944772201d3e854a283342fd189409995e85a91796d5197a9e5f0be0017`), style only; the prompt forbids drawing that woman or any face from it.
- Prompt: the shared style block of the 2026-10-16 session (above, verbatim and unchanged; `home_art2/prompts/style.txt`), a blank line, then the scene paragraph (`home_art2/prompts/scene_<x>.txt`); the full prompt is `home_art2/prompts/full_<x>.txt`, and its scene line appears verbatim in each session log.
- Scenes g and h were run twice. The first runs (`tier_g_*`, `tier_h_*`) kept the radio dish, which by then has fallen, so they were excluded; g2 and h2 add a no-dish sentence and are the ones that ship.
- Candidate PNGs are byte-for-byte copies of the generator outputs in `~/.codex/generated_images/` (sha256 of each output file equals its candidate's, checked 2026-10-19). No post-processing, never upscaled.
- Text check (2026-10-19): every shipped candidate was opened at full frame and in four 768x512 quadrants at 1:1, with 3x zooms of the plain memorial stones in d_c1 and d_c2. No text, letters, numbers or glyph-like marks were found. Nothing was dropped.
- Ruling: Mark, attended 2026-10-19 (ledger D-86): "we can just have random choices from the varients we have. good replayability. I think we may generate even more variations but these are all good for now." Every candidate below ships; c1 is v0 and c2 is v1.

## tier1 (1-3 Earth years): scene a

- Line: "%s years at home. The people who saw you off still look up some evenings."
- `tier1_v0.webp` <- `candidates/tier_a_c1.png`: 1536 x 1024 RGB, sha256 `e84b4c60618535859df1ed51059d31661cd94220be6dfd1fc11b8dac16ccf04c`; generator output `exec-335f3602-f6a5-4a09-ae3e-80d8177c9f4b.png`; 1:1 check clean; ships.
- `tier1_v1.webp` <- `candidates/tier_a_c2.png`: 1536 x 1024 RGB, sha256 `e21318eea283186e7d676e047b358a725d308d79e23f7d6912d20ec91fa61cf7`; generator output `exec-e3b5dd63-8022-48c4-b071-4a6f1060f890.png`; 1:1 check clean; ships.

Scene paragraph (verbatim):

> Scene, a year or two after the launch, a clear fresh spring morning: the same family seen from behind at the wooden hillside rail, the child from the launch now a little older and standing on their own feet, holding a parent's hand and looking out to sea. A small bunch of fresh wildflowers is tied to the rail. The same warm Mediterranean hill town of ochre walls, terracotta roofs and dark cypresses, unchanged, fishing boats in the bay. The radio dish on the headland points high into the sky, a light on in its small control hut. Hopeful, tender, still waiting for word.

## tier3 (10-20 Earth years): scene b

- Line: "%s years. The children who waved you off are growing up; they know your leaving mostly from what they were told."
- `tier3_v0.webp` <- `candidates/tier_b_c1.png`: 1536 x 1024 RGB, sha256 `025203d7aefe6f23f1e21bf341fcd22498082b00b43781584d33e831d9887a13`; generator output `exec-83a737e0-49df-424a-a739-2a66e5b70198.png`; 1:1 check clean; ships.
- `tier3_v1.webp` <- `candidates/tier_b_c2.png`: 1536 x 1024 RGB, sha256 `ada1a11de6a3897ec27e71fcc5027fcd6faed079e0c6497cb36239ad0a69fc0e`; generator output `exec-8dec7269-4759-44dc-a105-bdbc27be2b9b.png`; 1:1 check clean; ships.

Scene paragraph (verbatim):

> Scene, about fifteen years later, a windy blue dusk with the first stars: the child from the launch, now a teenager, seen from behind, sits alone on the low stone wall beside the hillside path with knees drawn up, looking at the sky. The ochre-and-terracotta town has grown: a few pale modern buildings among the old roofs, a new switchback road, small wind turbines on the far ridge. The old radio dish still turns on the headland, with a small newer antenna mast beside it. Restless, private, remembering.

## tier5 (35-55 Earth years): scene c

- Line: "%s years. Your parents' generation is passing; the friends you left are growing old."
- `tier5_v0.webp` <- `candidates/tier_c_c1.png`: 1536 x 1024 RGB, sha256 `752c3d7f713858e8d5df136f6986ffcd175b1c0733c5fddaac03ee04f07a99da`; generator output `exec-da334e00-cc03-4ba1-8cfa-8ade69f54a0e.png`; 1:1 check clean; ships.
- `tier5_v1.webp` <- `candidates/tier_c_c2.png`: 1536 x 1024 RGB, sha256 `d2ffc831e5d5b15fc419aa1e67bea96fd11e7a8be438d8cf867a69b9bb568e8a`; generator output `exec-18f9fb2f-4ffa-4020-8c52-b4c98e40deee.png`; 1:1 check clean; ships.

Scene paragraph (verbatim):

> Scene, about half a century later, a warm early-autumn late afternoon: a middle-aged adult and a teenager, seen from behind, lay a small bunch of flowers on a weathered stone bench beside the hillside path. The town is larger and quietly modern, solar tiles on many roofs, a light tram crossing the viaduct, but the old terracotta core and cypresses remain. The old radio dish on the headland has been restored and freshly painted as a fenced heritage monument, with a row of smaller modern dishes beside it. Tender, generational, a family that still remembers.

## tier7 (90-130 Earth years): scene d

- Line: "%s years. Everyone you knew is gone, or nearly. Strangers live in the houses you knew."
- `tier7_v0.webp` <- `candidates/tier_d_c1.png`: 1536 x 1024 RGB, sha256 `a6cc3f8df55cdf397b4440ce6ba28328c15e2243b0c4617b9c303cdadd788f98`; generator output `exec-28523d7f-8c19-45f6-8ff7-6aaed9b04be4.png`; 1:1 check clean; ships.
- `tier7_v1.webp` <- `candidates/tier_d_c2.png`: 1536 x 1024 RGB, sha256 `4bad13905b51de1fe3f58b68fc460432d0002fed6826d6aa0ee395a56fb5f557`; generator output `exec-fdf28119-b1ae-4898-be3a-7aff9faef1bd.png`; 1:1 check clean; ships.

Scene paragraph (verbatim):

> Scene, about a century later, a cold bright winter afternoon: where the wooden rail once stood there is now a small worn stone memorial, its face completely plain, smooth and unmarked, half hidden in tall pale grass. In the middle distance a few strangers in unfamiliar long coats walk the path away from the viewer, not looking at it. The town has been rebuilt in pale curved terraces of an unfamiliar style; only an old bell tower and a few terracotta roofs survive. The old dish on the headland stands rusted and still, tilted toward the ground; a sleek slender new tower stands on the next ridge. Quiet, gently forgotten.

## tier9 (250-500 Earth years): scene e

- Line: "%s years. The countries you knew may not exist. Your way of speaking would sound old to anyone at home."
- `tier9_v0.webp` <- `candidates/tier_e_c1.png`: 1536 x 1024 RGB, sha256 `58bce70d3280c407c642766016130d41ad1b5c7c46238d399188138e59a0164a`; generator output `exec-52718da0-0bdc-4c45-9fa9-596bdfaa8c73.png`; 1:1 check clean; ships.
- `tier9_v1.webp` <- `candidates/tier_e_c2.png`: 1536 x 1024 RGB, sha256 `257cf9290a022a4bcfc2c5a21bc7c65df8818054c36e4a6a898096af63da00fc`; generator output `exec-7749c5ed-b1de-48ba-8cf7-7e1667077444.png`; 1:1 check clean; ships.

Scene paragraph (verbatim):

> Scene, several centuries later, a hazy humid summer day: the sea has risen. The lower town and the old harbour lie under water behind a long grey curved sea wall, old rooftops and a bell tower standing in the calm shallows inside it. Low domed and terraced buildings of a later era climb the upper slope. On the headland, now almost an island at high tide, the old radio dish has collapsed into a vine-grown ruin of struts. Small quiet boats cross the bay. The hillside path has become a cobbled lane of a different style, empty of people. Wistful, adapting, time moving on.

## tier11 (1000-3000 Earth years): scene f

- Line: "%s years. Languages, faiths and borders have had time to rise and be forgotten. Anyone who reads your signal will need old records to do it."
- `tier11_v0.webp` <- `candidates/tier_f_c1.png`: 1536 x 1024 RGB, sha256 `e82a9dd41cc90fb0dc7d79092ad70b69f60390234c6b34988a5bce8878199fd8`; generator output `exec-9769bd83-e4a3-47a6-96a9-4ab21c4ab6a2.png`; 1:1 check clean; ships.
- `tier11_v1.webp` <- `candidates/tier_f_c2.png`: 1536 x 1024 RGB, sha256 `ff5fbc304faa10f18b47f993c8ff5d56c5e127b1dfa6d46fea93d40d10423e98`; generator output `exec-8675bcc2-7efa-493d-af51-3258d006314b.png`; 1:1 check clean; ships.

Scene paragraph (verbatim):

> Scene, a few thousand years later, a still golden morning: of the old town only a faint pattern of worn stones and stumps of arches remains, visible under the clear turquoise shallows of the bay. The slopes and cliffs are covered in the terraced garden architecture of a later people, grown into the hillside with living green roofs and hanging gardens. The headland is a low island with a ring of mossy stones where the dish once stood. Graceful sail-craft and one slow airship move over the sea. A few tiny distant figures in flowing clothes tend the terraces far below, never facing the viewer. Serene, unfamiliar, peaceful.

## tier12 (3000-10000 Earth years): scene g2

- Line: "%s years. Time enough for whole civilisations to rise and fall. You cannot know who still keeps a record of your leaving."
- `tier12_v0.webp` <- `candidates/tier_g2_c1.png`: 1536 x 1024 RGB, sha256 `458bcb676e8c4c1ce8ba80adf0c13ad5fc9e038681f7e1d348318533f43ae6e3`; generator output `exec-55fe5411-69a2-44e9-9c73-eb0f22c93a8f.png`; 1:1 check clean; ships.
- `tier12_v1.webp` <- `candidates/tier_g2_c2.png`: 1536 x 1024 RGB, sha256 `a175bc08ebdb89a1cd93849a1103802582de34514046e0e31c935c9b53615886`; generator output `exec-6d8cfbbf-c588-40b1-a778-e98393146618.png`; 1:1 check clean; ships.

Scene paragraph (verbatim):

> Scene, many thousands of years later, a deep blue dusk: the bay has been shaped into a calm engineered lagoon of curving green terraces and still pools; the hillside path is a smooth pale walkway through tall meadow grass. Across the darkening sky a thin chain of tiny bright orbital lights arcs from horizon to horizon, and a slender beam of pale light rises straight up from the far rocky islet where the headland was. No people visible. Awe, stillness, a world grown strange but gentle. There is no radio dish, antenna or telescope anywhere in the image: the old dish fell and vanished thousands of years ago.

## tier14 (50000-250000 Earth years): scene h2

- Line: "%s years. Long enough for ice to advance and retreat across continents. Whoever lives at home now has had time to become someone you would not recognise."
- `tier14_v0.webp` <- `candidates/tier_h2_c1.png`: 1536 x 1024 RGB, sha256 `7b149e8e9d757e9152e67b2bbdc63e20bf799a3cf158739a1b69b21400d510c1`; generator output `exec-f781cb13-af44-49d8-a2d5-89f141ed3391.png`; 1:1 check clean; ships.
- `tier14_v1.webp` <- `candidates/tier_h2_c2.png`: 1536 x 1024 RGB, sha256 `954da1741e36292c07bec6ec2ec3e99a26e1a75bfa52012eab502cfc291d853c`; generator output `exec-3a420593-6f84-4f95-bad2-20e43b2488fa.png`; 1:1 check clean; ships.

Scene paragraph (verbatim):

> Scene, an ice age tens of thousands of years later, a cold clear morning: the sea has retreated far away; the old bay is now a wide frost-covered plain of grass and tundra, the shoreline a thin silver line near the horizon. Glaciers cap the mountains behind. The old headland is an isolated rocky hill on the plain. On the far horizon an immense slender structure from an earlier age stands frost-rimed and dark, as if listening. Herds of large shaggy animals graze the plain. The hillside path is gone; the foreground is frozen grass and lichened boulders. A faint thin ring-thread crosses the pale sky. Vast, patient, indifferent. There is no radio dish, antenna or telescope anywhere in the image: the old dish fell and vanished thousands of years ago. The old headland hill is bare rock.

## tier15 (250000 and more Earth years): scene i

- Line: "%s years. Time on the scale of geology: seas and coasts have moved. There may be no one left who could read your signal as yours."
- `tier15_v0.webp` <- `candidates/tier_i_c1.png`: 1536 x 1024 RGB, sha256 `3e343d7a4a40d3f20c63db33af91967631f3598d0a0aac2f2bf0a75dc607d6c0`; generator output `exec-b29c7922-7185-4dd3-a6a8-15bcc313f6de.png`; 1:1 check clean; ships.
- `tier15_v1.webp` <- `candidates/tier_i_c2.png`: 1536 x 1024 RGB, sha256 `7bae6a0af9df421882a9fba0c7ebc16be18f9d8cb35157c8a0a60ed260c08000`; generator output `exec-e960d874-e8be-476d-9b0e-80b95f8e1ff6.png`; 1:1 check clean; ships.

Scene paragraph (verbatim):

> Scene, deep geological time, hundreds of thousands of years later, a warm violet twilight: the land itself has changed. The hillside is a gentle slope of unfamiliar flowering plants; the coast is a new shoreline of pale chalk cliffs; the headland has vanished entirely beneath the sea. Of the immense listening structure only a single broken spire remains on the horizon, weathered smooth like old bone. In the sky the stars glitter in unfamiliar patterns, and a faint broken arc of an old orbital ring-thread fades into the dusk. No people and no buildings. Elegiac and vast, yet the Earth is still alive and beautiful.

## Excluded from this session

- `tier_g_c1.png`, `tier_g_c2.png`, `tier_h_c1.png`, `tier_h_c2.png`: the first runs of scenes g and h, which still showed the radio dish; replaced by g2 and h2. Not shipped and not uploaded.
