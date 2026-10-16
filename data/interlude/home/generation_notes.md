# Home-time tier illustrations (review card, Home page)

Seven landscape illustrations, one per home-time tier, generated 2026-10-16 for Stapledon's Voyage. Art owned by Sunholo. Nothing was written to any repository.

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

## tier0.png

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

## tier1.png

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

## tier2.png

- Home time: < 30 years. Card line: "The children you knew have grown up; your name is a story they half remember."
- Delivered sha256: `0229d2d94f01c08dc96e96e957f3b6b6942003885a5aaa40c39b4e1a1f0b12c9`; byte-for-byte copy of `candidates/tier2_c2.png`.
- Date: 2026-10-16. Generator: OpenAI built-in `image_gen__imagegen` via Codex (agent model gpt-6.1-sol). Image model: exact id/version not exposed. Seed: none exposed.
- Native size: 1536 x 1024. Post-processing: none. Never upscaled.
- Shows: Golden late-summer evening: the town has spread up the slope and grown a long breakwater. A young adult and a small child walk the path from behind, the adult pointing out to sea. A weathered bench holds a bundle of long-dried flowers.

- Candidates: 2 generated; kept c2.

### Candidate tier2_c1 — rejected

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

## tier3.png

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

### Candidate tier3_c2 — rejected

- File: `candidates/tier3_c2.png`. Native output: 1536 x 1024 RGB; sha256 `ef141b439650632df69c1f2c14f576796dd92b7519aab350a433a6b7b82b9b50`.
- Generator output filename: `exec-676d14d5-b545-465f-ac20-f5dc7417d71c.png`.
- Decision: Equally clean. Its more brutalist town and greener slope make a weaker bridge to tiers 2 and 4.
- Prompt (full, verbatim): identical to the tier3 prompt below.

### Prompt tier3 (full, verbatim)

> Asset: one wide landscape illustration for the Home page of a review card in the game Stapledon's Voyage, a relativistic starship voyage in which decades to millennia pass on Earth while the crew lives only a few years. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour on warm paper, muted earthy palette with restrained teal, ochre and coral accents. The attached image is a style reference only for line, hatching, paint texture and palette; do not draw that woman or any face from it. Landscape 3:2 at native 1536x1024. Fixed viewpoint shared by the whole series: from a grassy hillside path high above a small coastal town that climbs a slope toward a rocky headland on the right of the frame, where a large radio telescope dish stands; the bay and open sea fill the middle distance under a wide sky. Keep the left third of the frame calm and uncluttered (open sky, soft sea, quiet meadow) so a text panel can overlay it. Absolutely no text, letters, numbers, digits, writing, signage, symbols, flags, logos, brands, captions, frames, borders, UI or watermark anywhere in the image. No recognisable real people or real places. Mood: melancholy but not despairing, grounded and restrained, never kitsch.
>
> Scene, about seventy years later: a grey overcast autumn day with low cloud. The radio dish is decommissioned and streaked with rust, a section of its rim missing, a chain-link fence sagging around it. The town below has been remodelled in unfamiliar later architecture, the old houses mostly replaced. On a worn bench on the hillside path a single very old person sits alone wrapped in a coat, seen from behind, a walking stick beside them, looking out at the sea. Fallen leaves on the path. Elegiac, solitary, quietly enduring.

## tier4.png

- Home time: < 130 years. Card line: "Everyone you knew is gone."
- Delivered sha256: `bfd69e924ea322aec5cc4fa2744ee19c9d2f57886acb8ae7bf2ea68f72e29e70`; byte-for-byte copy of `candidates/tier4_c2.png`.
- Date: 2026-10-16. Generator: OpenAI built-in `image_gen__imagegen` via Codex (agent model gpt-6.1-sol). Image model: exact id/version not exposed. Seed: none exposed.
- Native size: 1536 x 1024. Post-processing: none. Never upscaled.
- Shows: Pale winter light and thin snow. The dish has collapsed into an ivy-grown wreck. Low domed buildings of a later era stand among roofless stone ruins of the old town. The path is overgrown, gulls wheel overhead, and there are no people.

- Candidates: 2 generated; kept c2.

### Candidate tier4_c1 — rejected

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

## tier5.png

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

## tier6.png

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

- Landed 2026-10-16 in `stapledons-godot` at `data/interlude/home/tier<n>.png` (bytes unchanged; sha256 pins in `SOURCES` beside this file), read by `ui/crossing_review.gd` for the crossing review's Home page.
- The same seven pictures are on the website's concept-art page (PR #259).
