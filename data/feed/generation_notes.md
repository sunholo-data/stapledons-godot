# Earth feed picture library, seed v0 (comms station, R3-EARTH-LINK EL3b)

Forty-eight landscape illustrations, one for each event of `sim/data/feed_events.ail`, shipped as `pictures/<id>_v0.webp`. They are the first seed of the feed library that grows over playthroughs (Mark, attended 2026-10-28: "go ahead and we will start seeding the library - this is something that can build up over playthroughs"). Art owned by Sunholo. Generated 2026-10-28, following the process and provenance standard of `data/interlude/home/generation_notes.md`.

## Provenance and review limits

- Driver: `feed-art-work/run.sh` (zsh), one non-interactive session per batch: `env -u OPENAI_API_KEY codex exec -m gpt-6.1-sol --skip-git-repo-check -s workspace-write -C <work dir> -i style_ref.png -- <instruction> < /dev/null` (codex-cli 0.164.0; ChatGPT login, no API key). The instruction lists the batch's events and asks, for each, for exactly one call of the built-in image tool with the prompt file's contents verbatim and the reference image attached, a byte-for-byte `cp` of the output to `candidates/<id>_c<n>.png`, and no judging or retrying. Batches: one session per category (sky-sunset first as a trial); retries in three sessions of three or four (round 1) and two single-event sessions (round 2).
- Generator: OpenAI built-in `image_gen__imagegen` tool (Codex imagegen). Exact image model id/version: **not exposed by the tool** (every session reported "not exposed"); none is invented. Seed: none exposed. No size parameter is exposed; 1536x1024 was asked for in the prompt and every output is natively 1536 x 1024 RGB.
- Reference image, every call: `assets/characters/medic/portrait_medic_y0_neutral.png`, copied to `feed-art-work/style_ref.png` (sha256 `93a02944772201d3e854a283342fd189409995e85a91796d5197a9e5f0be0017`, identical to the copy the home pictures used), passed as `referenced_image_paths` with `transparent_background: false`. Style only; the prompt forbids drawing that woman or any face from it. No face from it appears in any output.
- Verified from the Codex session rollouts (`~/.codex/sessions/2026/10/28/`, the `image_gen.generation` items): for all 61 candidates the generator output file's sha256 equals the candidate's, the submitted prompt equals the prompt file byte for byte, and the input image is `style_ref.png` with the sha256 above. All 61 generations made in the work directory are candidates; there are no uncounted outputs.
- Session stalls (no effect on any image): several sessions hung at start-up when codex waited on an inherited stdin ("Reading additional input from stdin"). They were killed before making any image and rerun; `run.sh` now feeds `/dev/null` and `runw.sh` restarts a session that makes no progress in 240 s. Their logs are in `feed-art-work/logs/stalled/`.
- Candidate PNGs (`feed-art-work/candidates/`) are byte-for-byte copies of the generator outputs in `~/.codex/generated_images/`. The masters (`feed-art-work/masters/<id>_v0.png`) are byte-for-byte copies of the kept candidates (checked with `cmp`). Post-processing: none on any master. The shipped WebP is the only derived file (downscale to 1024 wide and lossy encode, see SOURCES).
- Text and rule check: every candidate was opened at full frame and in four 768x512 quadrants at 1:1 (headless Godot 4.7.2 crops, no resampling), looking for text-like marks (posters, awnings, boats, bottles, jars, books, stones, signs), symbols, the 16:9 crop (top and bottom tenth), faces (small or turned away), tier fit and continuity. No candidate showed letters, digits or glyph-like marks. 13 candidates were rejected for other rules and regenerated: faces too large and front-on (family-birthday, science-medicine, home-storm), the subject in the cropped top strip (science-launch), dated technology across the tier range (science-telescope's brass refractor, science-deep-sea's riveted bathysphere), a misread subject (science-mars, sky-station twice), symbols (town-festival's and world-rebuilt's crosses), continuity (world-rebuilt c1 showed the home town's dish in a city "far from the town"), and a skyline that evoked a real capital (world-march, superseded rather than failed).
- Contact sheet `feed-art-work/contact_sheet.png` (review aid only, not shipped): the 48 masters in catalogue order, 8 columns by 6 rows, each downscaled to 320x213 (Lanczos) in headless Godot 4.7.2.
- Tier fit: each picture had to be true for every year of its event's home-time tiers (0: under 1 year ... 8: 130-250 years after departure). The style block keeps people in plain timeless clothes with no phones, screens, vehicles or dated machines; the few technological subjects (the rocket, the observatory dome, the fusion ring hall, the station, the submersible, the new tower) are drawn generic and undated.
- The prompt is the shared style block (below), a blank line, then the event's scene paragraph; the scene paragraphs are also `scene` in `events.json`. A retry uses a revised scene paragraph (`_r1`, `_r2`), given verbatim under its event. `events.json` holds, for each event, the scene paragraph that produced the shipped picture (the retry paragraph where a retry was kept), so `style + "\n\n" + scene` reproduces the kept prompt byte for byte (checked for all 48).

## Style block adapted from the home tiers

The look (1970s European science-fiction graphic-novel illustration, ink contours, cross-hatching, gouache and watercolour on warm paper, muted earthy palette with teal, ochre and coral accents) and the place (the Mediterranean-style terracotta town with the radio dish on the headland) are the home series'. Unlike that series the viewpoint varies with the event and nothing is held calm for a text panel; instead the picture keeps its subject out of the top and bottom tenth for the game's 16:9 centre crop, and adds the rules: no text or symbols of any kind, no real people or places, no starship or voyage, faces small or turned away, warm and human, never kitsch, never judging.

## Shared style block (verbatim, first paragraph of every prompt)

> Asset: one wide landscape illustration, a single frame of the news feed from home in the game Stapledon's Voyage, a relativistic starship voyage in which years pass on Earth while the crew lives far less; this picture shows only home's own life on Earth, never the ship. Style: sophisticated hand-drawn 1970s European science-fiction graphic-novel illustration, delicate expressive ink contours, selective cross-hatching, textured gouache and watercolour on warm paper, muted earthy palette with restrained teal, ochre and coral accents. The attached image is a style reference only for line, hatching, paint texture and palette; do not draw that woman or any face from it. Landscape 3:2 at native 1536x1024. The series is set in and around one small Mediterranean-style coastal town of ochre walls, terracotta roofs and dark cypresses that climbs a slope toward a rocky headland where a large white radio telescope dish stands, above a bay and the open sea; when the news comes from elsewhere, the scene says where. Each picture is a snapshot from home's news feed with its own viewpoint (a kitchen, a street, the square, the beach, the hills, the sky), not a fixed view. The picture will be cropped to 16:9 for display, so keep every important element inside the central horizontal band and nothing important in the top or bottom tenth of the frame. Timeless everyday life: plain simple clothes, no phones, screens or electronic devices, no vehicles, machines, fashion or technology that would date the picture to any particular year. People may appear, but faces stay small, distant or turned away. No starship and nothing about a space voyage. Absolutely no text, letters, numbers, digits, writing, signage, symbols, flags, logos, brands, captions, frames, borders, UI or watermark anywhere in the image. No recognisable real people or real places. Mood: warm and human, melancholy at most, grounded and restrained, never kitsch, never judging.

## family-birthday_v0.webp (family; tiers 0-8; "a birthday party")

- Kept: candidate c2. Shipped `pictures/family-birthday_v0.webp` (1024 x 683, cwebp q85), sha256 `4fbc0070829da9d1d57722dcd72584aba82406a56c141dcd7bb845d90301afe9`; master `family-birthday_v0.png` (1536 x 1024 RGB, byte-for-byte copy of the generator output), sha256 `15b913786323f671578bd86671b8551e01c58e9b3f338416341c3fd4205b4c21`.
- Candidates: 2.

### family-birthday_c1

- Generator output `exec-46686ad4-7ee2-48c8-8468-9acedcf0d792.png`, sha256 `58d91460b4280d59ab9b63a37621ff273cc5271f1a633a771e08829255ccc02e`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_family-birthday.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, rejected: Clean at 1:1, but the parents and the child are drawn large and front-on with clear smiling faces, against the rule that faces stay small or turned away. Retried with the room seen from the doorway.

### family-birthday_c2

- Generator output `exec-c56a28fe-0d05-47a3-898d-67ea3fc14e09.png`, sha256 `15b913786323f671578bd86671b8551e01c58e9b3f338416341c3fd4205b4c21`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_family-birthday_r1.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, kept: Full frame and 1:1 clean (painted jugs carry only floral pattern; streamers plain). Seen from the doorway: the child from behind blowing out three candles, family clapping from behind and in profile, sunset, sea and dish through the window. Warm, faces small or turned.

### Prompt family-birthday (full prompt = style block, a blank line, then this scene paragraph; verbatim)

> Scene, a birthday party: a warm family kitchen in one of the town's old houses on a summer evening, the window open on terracotta roofs and the sea. A small child leans over a plain round cake to blow out a few slim candles, seen side-on with the face half hidden by the glow; parents, a grandparent and friends crowd close around the table, clapping, mostly seen from behind. Paper streamers in plain colours, glasses, a bowl of fruit. Golden candlelight, laughter, ordinary happiness.

### Prompt family-birthday_r1 (retry scene paragraph, verbatim)

> Scene, a birthday party: a warm family kitchen in one of the town's old houses on a summer evening, seen from the doorway across the room so that everyone is small in the frame, the window beyond open on terracotta roofs and the sea. A small child, seen from behind, leans over a plain round cake on the table to blow out a few slim candles; parents, a grandparent and friends crowd round the table clapping, all seen from behind or in distant profile, their faces turned toward the child and the cake, away from us. Paper streamers in plain colours, glasses, a bowl of fruit. Golden candlelight, laughter, ordinary happiness.

## family-baby_v0.webp (family; tiers 1-8; "a new baby in the family")

- Kept: candidate c1. Shipped `pictures/family-baby_v0.webp` (1024 x 683, cwebp q85), sha256 `c0d5e4916879115f3cf0d12c02a00fd0411ddde6e2a5925e1e087dafdacb7381`; master `family-baby_v0.png` (1536 x 1024 RGB, byte-for-byte copy of the generator output), sha256 `1dc550327255022e04398dcb6684cfeb93a51fe193d22f5a1a7eb1ba06e265e6`.
- Candidates: 1.

### family-baby_c1

- Generator output `exec-e02a4e3a-a6f1-41ed-afa4-779ad163471f.png`, sha256 `1dc550327255022e04398dcb6684cfeb93a51fe193d22f5a1a7eb1ba06e265e6`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_family-baby.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, kept: 1:1 clean (vase painted with leaves only). Parent and grandparent in profile, turned toward the baby, not toward us; tender morning light, the dish and town through the window.

### Prompt family-baby (full prompt = style block, a blank line, then this scene paragraph; verbatim)

> Scene, a new baby in the family: a quiet morning bedroom with whitewashed walls and green shutters opened on the bay. A young parent sits by the window holding a newborn wrapped in a plain cream blanket; a grandparent bends close to look, a hand resting on the parent's shoulder. Faces turned toward the baby and away from us. Soft early light, a vase of wildflowers on the sill. Tender and hushed.

## family-school_v0.webp (family; tiers 1-3; "the children's first day at school")

- Kept: candidate c1. Shipped `pictures/family-school_v0.webp` (1024 x 683, cwebp q85), sha256 `7084c12ebf91a1f5cd9c1e1ee981f36897d4971edc094f4d8bee08fce2512e12`; master `family-school_v0.png` (1536 x 1024 RGB, byte-for-byte copy of the generator output), sha256 `92ba739d67b2f389c64388df04f2b8fd9979c638a1c197f926dd3df5fa5d7b24`.
- Candidates: 1.

### family-school_c1

- Generator output `exec-63dd3e96-f068-4dbe-a361-6d0d5b2542a3.png`, sha256 `92ba739d67b2f389c64388df04f2b8fd9979c638a1c197f926dd3df5fa5d7b24`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_family-school.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, kept: 1:1 clean (satchels plain, no marks on the schoolhouse). Parent and boy from behind; the girl glances back as the scene asked, her face small and in the lower-middle band. Warm, a little nervous.

### Prompt family-school (full prompt = style block, a blank line, then this scene paragraph; verbatim)

> Scene, the children's first day at school: a narrow cobbled lane of the town on a bright autumn morning, ochre walls and potted geraniums. A parent walks two small children, each with a plain leather satchel, toward an old stone schoolhouse with an arched doorway at the end of the lane, all seen from behind. Other small children and parents gather at the door. One child glances back over a shoulder. Hopeful, a little nervous, the ordinary courage of a first day.

## family-wedding_v0.webp (family; tiers 3-8; "a family wedding")

- Kept: candidate c1. Shipped `pictures/family-wedding_v0.webp` (1024 x 683, cwebp q85), sha256 `903274dcaae6a2b1c11b1eed2497acf5eeb93f5b4e4a38667d393c5e6709637f`; master `family-wedding_v0.png` (1536 x 1024 RGB, byte-for-byte copy of the generator output), sha256 `faa0aa335d2315e3fda15d5425e66800437ae3f3842f5e10a30aff478c31a1fe`.
- Candidates: 1.

### family-wedding_c1

- Generator output `exec-f13d4433-3f69-415a-a8d4-9206907a1f45.png`, sha256 `faa0aa335d2315e3fda15d5425e66800437ae3f3842f5e10a30aff478c31a1fe`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_family-wedding.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, kept: 1:1 clean (lace, lanterns, the officiant's small book show no marks). The couple from behind under the arch, guests mostly from behind, faces small; dish and town at right.

### Prompt family-wedding (full prompt = style block, a blank line, then this scene paragraph; verbatim)

> Scene, a family wedding: an outdoor wedding under old olive trees on a terrace above the sea in late afternoon. A couple in simple light-coloured clothes stand hand in hand under a garland arch of greenery and white flowers, seen from a little distance and mostly from behind; guests on wooden chairs, a few wiping their eyes, children with petals. Long lace tablecloths and lanterns waiting for the evening. Warm, joyful, gently bittersweet.

## family-graduation_v0.webp (family; tiers 3-6; "graduation day")

- Kept: candidate c1. Shipped `pictures/family-graduation_v0.webp` (1024 x 683, cwebp q85), sha256 `04e877dc711833dfebe28f30e345a275b0fecdbaaf2ded002b9e6bdad3a891ff`; master `family-graduation_v0.png` (1536 x 1024 RGB, byte-for-byte copy of the generator output), sha256 `a717b88721a6abb779890bf4d11093a48f3a84fa9c0fb05cb593e6a42db130e8`.
- Candidates: 1.

### family-graduation_c1

- Generator output `exec-cf444f01-6a36-4020-ab07-120f074b83b1.png`, sha256 `a717b88721a6abb779890bf4d11093a48f3a84fa9c0fb05cb593e6a42db130e8`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_family-graduation.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, kept: 1:1 clean: caps and gowns plain, no emblems; graduates from behind, the families along the arcade small; dish and town beyond the cloister roof.

### Prompt family-graduation (full prompt = style block, a blank line, then this scene paragraph; verbatim)

> Scene, graduation day: the stone cloister courtyard of an old college in the region, arches and a cypress, bright early-summer noon. A crowd of young graduates in plain dark gowns throw flat caps into the air, seen from behind and from a distance; families stand along the arcade clapping, an older relative holding a bunch of flowers. Caps and gowns completely plain, no emblems. Proud, light, the moment before everyone scatters.

## family-empty-chair_v0.webp (family; tiers 0-2; "dinner, and your empty chair")

- Kept: candidate c1. Shipped `pictures/family-empty-chair_v0.webp` (1024 x 683, cwebp q85), sha256 `348f64053563d66e4937488c63365bc68adeaf70d19d818e4f30bc9ba659040b`; master `family-empty-chair_v0.png` (1536 x 1024 RGB, byte-for-byte copy of the generator output), sha256 `bfa224a09ad3350b5d7fb110aa3f0408adfd2ef86db32138462a066898bea8e8`.
- Candidates: 1.

### family-empty-chair_c1

- Generator output `exec-3bdb4c3f-4651-4fe1-b209-2f3c8b07d9ef.png`, sha256 `bfa224a09ad3350b5d7fb110aa3f0408adfd2ef86db32138462a066898bea8e8`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_family-empty-chair.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, kept: 1:1 clean. The empty chair at the far end with its plate and folded napkin sits dead centre; the family of four seen from behind and in side profile, the mother looking out at the dish. Loving, missing someone, not tragic.

### Prompt family-empty-chair (full prompt = style block, a blank line, then this scene paragraph; verbatim)

> Scene, dinner, and your empty chair: a family kitchen in the town at dusk, a long wooden table set for supper, a lamp warm over it, the window showing the last light on the sea and the white dish on the headland far off. A family of four sits eating and talking quietly, seen from behind and side-on; one chair at the end of the table stays empty with its plate and glass set, a folded napkin on it. Someone glances at it. Loving, missing someone, not tragic.

## family-reunion_v0.webp (family; tiers 2-8; "a family reunion")

- Kept: candidate c1. Shipped `pictures/family-reunion_v0.webp` (1024 x 683, cwebp q85), sha256 `146664c1b0a237bbeafbec107985fe6b1fb4ab5bd01e5dc770416445d9012ddd`; master `family-reunion_v0.png` (1536 x 1024 RGB, byte-for-byte copy of the generator output), sha256 `41795942e876d8b5ebdeb1cc3b18a76f131cc229a107c1191a0231e8d07786c1`.
- Candidates: 1.

### family-reunion_c1

- Generator output `exec-0782b233-9c8c-40b8-9ca0-465c94880545.png`, sha256 `41795942e876d8b5ebdeb1cc3b18a76f131cc229a107c1191a0231e8d07786c1`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_family-reunion.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, kept: 1:1 clean. Three generations under the vine pergola; faces are small (about 40 px) and mostly in profile, a child running at right. Warm and abundant.

### Prompt family-reunion (full prompt = style block, a blank line, then this scene paragraph; verbatim)

> Scene, a family reunion: a long table under a vine-covered pergola in a garden on the town's slope, late summer afternoon. Three or four generations crowd round it: old people, middle-aged couples, teenagers, small children running between the chairs; plates of food, bread, jugs of water and wine. Seen from a little above at one end of the table, most faces small or turned. The sea glitters beyond the garden wall. Noisy, warm, abundant.

## family-farewell_v0.webp (family; tiers 4-8; "a quiet farewell")

- Kept: candidate c1. Shipped `pictures/family-farewell_v0.webp` (1024 x 683, cwebp q85), sha256 `2e99f961d8c624ac3e96eea9c743172f10ee07fbbb81f7a5163ddf26527256aa`; master `family-farewell_v0.png` (1536 x 1024 RGB, byte-for-byte copy of the generator output), sha256 `90834713bfc85e28533c8baf781c14aa50b8f1db3312d99d2b750b3334e628ff`.
- Candidates: 1.

### family-farewell_c1

- Generator output `exec-0eaa9f5e-8641-4e42-b910-a55c681426f7.png`, sha256 `90834713bfc85e28533c8baf781c14aa50b8f1db3312d99d2b750b3334e628ff`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_family-farewell.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, kept: 1:1 clean: the gravestones are blank, the mourners in dark clothes from behind, flowers on the fresh grave, the sea and the dish beyond. Gentle grief.

### Prompt family-farewell (full prompt = style block, a blank line, then this scene paragraph; verbatim)

> Scene, a quiet farewell: a small hillside cemetery among dark cypresses above the town, the sea pale beyond, a soft overcast late afternoon. A small group of mourners in plain dark clothes stands around a simple grave with flowers laid on it, seen from behind at a distance; one person rests a hand on another's back. The stones are plain and completely unmarked. Calm, grieving, gentle, full of love.

## home-first-snow_v0.webp (home; tiers 0-8; "first snow on the roofs")

- Kept: candidate c1. Shipped `pictures/home-first-snow_v0.webp` (1024 x 683, cwebp q85), sha256 `4f38379059dc860eab33dd209ff0aacdaa991fb5085c1a5e4028dd492fe17fd9`; master `home-first-snow_v0.png` (1536 x 1024 RGB, byte-for-byte copy of the generator output), sha256 `e77ad9b387c691f742002df93f657cddaf35da8356f2f4363010b6ddf325a7d8`.
- Candidates: 1.

### home-first-snow_c1

- Generator output `exec-eafbfb1e-f891-411e-a3a3-eefdcd1e5f68.png`, sha256 `e77ad9b387c691f742002df93f657cddaf35da8356f2f4363010b6ddf325a7d8`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_home-first-snow.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, kept: Full frame and 1:1 quadrants clean; snow on terracotta roofs and cypresses, chimney smoke, two small coated children catching flakes in the lane, the sea and the snowy headland with its dish.

### Prompt home-first-snow (full prompt = style block, a blank line, then this scene paragraph; verbatim)

> Scene, first snow on the roofs: a rare winter morning in the town, a thin clean layer of snow on the terracotta roofs, the cypresses dusted white, smoke rising from chimneys. Seen from an upstairs window looking across the rooftops toward the grey-green sea and the headland with its white dish. In the lane below, two small figures in coats stop to catch flakes. Hushed, bright, a little magical.

## home-blossom_v0.webp (home; tiers 0-8; "spring blossom")

- Kept: candidate c1. Shipped `pictures/home-blossom_v0.webp` (1024 x 683, cwebp q85), sha256 `f62e731ff4b17114e8f059d6a5ab313e168cc815aa6df0cd09eb0def8cd92fa2`; master `home-blossom_v0.png` (1536 x 1024 RGB, byte-for-byte copy of the generator output), sha256 `cc9a2ca299a86c4a1125731a50166527b4231835738e4ed0c4db9685c38c2b29`.
- Candidates: 1.

### home-blossom_c1

- Generator output `exec-fa216a6c-7aa9-4466-9bb3-91fdc364297c.png`, sha256 `cc9a2ca299a86c4a1125731a50166527b4231835738e4ed0c4db9685c38c2b29`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_home-blossom.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, kept: Full frame and 1:1 clean; grandmother and child from behind on an orchard path in pink almond blossom, the child reaching for a branch, the town, bay and dish at right.

### Prompt home-blossom (full prompt = style block, a blank line, then this scene paragraph; verbatim)

> Scene, spring blossom: an almond orchard on the hillside above the town in full pink and white blossom, petals drifting across the path, the terracotta roofs and the blue bay below. An old woman and a child walk slowly between the trees, seen from behind, the child reaching up for a low branch. Fresh, soft, renewing.

## home-storm_v0.webp (home; tiers 0-8; "a summer storm")

- Kept: candidate c2. Shipped `pictures/home-storm_v0.webp` (1024 x 683, cwebp q85), sha256 `1baefb0920a5c10164508fce0b4d6e82ec0e5cc46ef0dc08ba9da9e20458e9e0`; master `home-storm_v0.png` (1536 x 1024 RGB, byte-for-byte copy of the generator output), sha256 `f447143d29836ae32214a97dbb60d54a7d7aab0363863bcc254bad9cd8edb47a`.
- Candidates: 2.

### home-storm_c1

- Generator output `exec-de68d35d-453f-4f50-a441-a46144d151d6.png`, sha256 `5f2655a81057e67f1c628007e81d25c0400f1fb11a06d008e14adb9b9c0c6391`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_home-storm.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, rejected: 1:1 clean of text, but the laughing couple runs straight at us with large, front-on faces, against the small-or-turned-away rule. Retried with the couple running away from us.

### home-storm_c2

- Generator output `exec-2acf9080-8edd-4e51-8463-a4f973f425c4.png`, sha256 `f447143d29836ae32214a97dbb60d54a7d7aab0363863bcc254bad9cd8edb47a`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_home-storm_r1.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, kept: Full frame and 1:1 clean (awning plain). The couple runs hand in hand away from us, others duck into doorways from behind, a man with a jacket over his head; lightning over the sea, the dish on the headland. Exhilarating, faces hidden.

### Prompt home-storm (full prompt = style block, a blank line, then this scene paragraph; verbatim)

> Scene, a summer storm: a sudden summer thunderstorm rolling in over the bay, heavy indigo clouds, a fork of lightning far out over the sea, rain sweeping the water. On a seafront street of the town, people dash for shelter under awnings and doorways, a couple laughing as they run, shirts darkened by rain. Wet cobbles shining. Exhilarating, brief, alive.

### Prompt home-storm_r1 (retry scene paragraph, verbatim)

> Scene, a summer storm: a sudden summer thunderstorm rolling in over the bay, heavy indigo clouds, a fork of lightning far out over the sea, rain sweeping the water. On a seafront street of the town, seen from a little above and behind, people dash away from us toward shelter under awnings and doorways, a couple running hand in hand with their backs to us, shirts darkened by rain, someone holding a jacket over their head. Wet cobbles shining in lamplight. Faces not visible. Exhilarating, brief, alive.

## home-harvest_v0.webp (home; tiers 0-8; "harvest in the hills")

- Kept: candidate c1. Shipped `pictures/home-harvest_v0.webp` (1024 x 683, cwebp q85), sha256 `e93def485f12f077744a09f2a442595679058c6c3d9ca99e62eec17268418c80`; master `home-harvest_v0.png` (1536 x 1024 RGB, byte-for-byte copy of the generator output), sha256 `cda92e83ed942795583df37c876d27bb6816730c9a4ff9d1031104bdd9afa505`.
- Candidates: 1.

### home-harvest_c1

- Generator output `exec-e83720c2-57f7-438b-9662-f028cb6789a1.png`, sha256 `cda92e83ed942795583df37c876d27bb6816730c9a4ff9d1031104bdd9afa505`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_home-harvest.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, kept: 1:1 clean; pickers bent over the vines with faces hidden under hats and hair, a child carrying a bunch overhead from behind, a cart of baskets, sunset over the bay and the dish.

### Prompt home-harvest (full prompt = style block, a blank line, then this scene paragraph; verbatim)

> Scene, harvest in the hills: terraced vineyards and olive groves on the hills behind the town at golden late-summer afternoon. People of several ages pick grapes into wide woven baskets along the rows, a cart of baskets waiting, a child carrying a bunch overhead. Seen from a little above, figures small, the town and the sea in the distance below. Tired, generous, unhurried.

## home-repainted_v0.webp (home; tiers 2-8; "the old house repainted")

- Kept: candidate c1. Shipped `pictures/home-repainted_v0.webp` (1024 x 683, cwebp q85), sha256 `e68de24de5bc8aa74980d209d4da55ff2daa74b3eaf76e8b358abc75614eda7c`; master `home-repainted_v0.png` (1536 x 1024 RGB, byte-for-byte copy of the generator output), sha256 `2134c065323d2377480b62bae3016bed53dc9885238f1bd0923520149d75d425`.
- Candidates: 1.

### home-repainted_c1

- Generator output `exec-54c39073-e7dc-4cd5-905a-c4daee2a092e.png`, sha256 `2134c065323d2377480b62bae3016bed53dc9885238f1bd0923520149d75d425`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_home-repainted.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, kept: 1:1 clean: a narrow house freshly painted rose with green shutters and a lemon tree, ladder and paint pots, the painter and a neighbour both seen from behind; the bay and dish down the lane.

### Prompt home-repainted (full prompt = style block, a blank line, then this scene paragraph; verbatim)

> Scene, the old house repainted: a narrow two-storey house of the town with green shutters and a lemon tree in its little front garden, its old ochre walls now freshly painted a soft new colour, a pale warm rose. A ladder leans against it, paint pots on the step, a person in paint-spattered clothes stands back to look, a neighbour admiring from the lane. Bright morning, sun on the new wall. Fresh start, a small change in a familiar place.

## home-new-road_v0.webp (home; tiers 3-8; "a new road through the valley")

- Kept: candidate c1. Shipped `pictures/home-new-road_v0.webp` (1024 x 683, cwebp q85), sha256 `4d5d6467d4ff5109101d8248491a26a643b46831513b74b1cd7319aa9619cd74`; master `home-new-road_v0.png` (1536 x 1024 RGB, byte-for-byte copy of the generator output), sha256 `a5ae4f0c1cc7edcaa1e911f90dac1d1f98fa6b5d96997625c3dce88b2d746173`.
- Candidates: 1.

### home-new-road_c1

- Generator output `exec-872e120d-fb9c-4fb3-9bc3-e4848a1a09c4.png`, sha256 `a5ae4f0c1cc7edcaa1e911f90dac1d1f98fa6b5d96997625c3dce88b2d746173`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_home-new-road.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, kept: 1:1 clean: no vehicles, markings or signs; a pale road curving through olive terraces toward the town, fresh red earth at its edges and staked saplings newly planted, a few small walkers. The surface reads as compacted gravel, which keeps it timeless; the newness rests on the earth and saplings.

### Prompt home-new-road (full prompt = style block, a blank line, then this scene paragraph; verbatim)

> Scene, a new road through the valley: seen from a hillside above, a pale freshly laid road curving through the green valley behind the town, past olive groves and stone farmhouses, toward the terracotta roofs and the sea. Fresh earth at its edges, young trees newly planted along it, a few walkers trying it out. No vehicles, no road markings, no signs. Broad daylight. Change arriving quietly.

## home-overgrown_v0.webp (home; tiers 5-8; "the garden grown wild")

- Kept: candidate c1. Shipped `pictures/home-overgrown_v0.webp` (1024 x 683, cwebp q85), sha256 `f216d3bc192f16bb8ee9ae4e832a1f31efe7b9a3f6bfb958045f44a6c1ac2cbb`; master `home-overgrown_v0.png` (1536 x 1024 RGB, byte-for-byte copy of the generator output), sha256 `4fff852a95ac67688b72ae9bf33fbeac40fa3109d9b45bea877d78f8b981a23d`.
- Candidates: 1.

### home-overgrown_c1

- Generator output `exec-e4b90a22-a1f2-4d34-a4dc-3d7edada3ca6.png`, sha256 `4fff852a95ac67688b72ae9bf33fbeac40fa3109d9b45bea877d78f8b981a23d`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_home-overgrown.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, kept: 1:1 clean; closed faded shutters, a lemon tree heavy with fruit, wild roses and grasses over the rusty gate, a cat asleep on the wall, butterflies; the bay and dish beyond. Beautiful rather than sad, as asked.

### Prompt home-overgrown (full prompt = style block, a blank line, then this scene paragraph; verbatim)

> Scene, the garden grown wild: the little front garden of the same narrow house of the town with green shutters and a lemon tree, now overgrown: tall grasses, wild roses and climbing vines over the gate and the low wall, the shutters closed and faded, the lemon tree heavy with unpicked fruit. Late golden afternoon, bees and butterflies, a cat asleep on the wall. Quiet, time passing, beautiful rather than sad.

## home-strangers_v0.webp (home; tiers 7-8; "strangers at the old house")

- Kept: candidate c1. Shipped `pictures/home-strangers_v0.webp` (1024 x 683, cwebp q85), sha256 `46281254150a24eb18e8987f28c04c06f3279b9cc57c18c8b19cefe43cb16974`; master `home-strangers_v0.png` (1536 x 1024 RGB, byte-for-byte copy of the generator output), sha256 `88604fca6d0ac279fce44604ccc6a18695158630cd720c738a60dec0e4ebbf12`.
- Candidates: 1.

### home-strangers_c1

- Generator output `exec-0b915290-b3a9-4b53-ab00-2fb09ef039c5.png`, sha256 `88604fca6d0ac279fce44604ccc6a18695158630cd720c738a60dec0e4ebbf12`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_home-strangers.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, kept: 1:1 clean: cardboard boxes plain, the rolled rug has a geometric border pattern with no glyphs. A man carries a chair through the door from behind, a small girl at the gate from behind; the bay and dish down the lane. Gentle and poignant.

### Prompt home-strangers (full prompt = style block, a blank line, then this scene paragraph; verbatim)

> Scene, strangers at the old house: the same narrow house of the town with green shutters and a lemon tree, on a bright morning. A young family nobody here knew is moving in: boxes and a rolled carpet on the step, a parent carrying a chair through the door, a small child standing at the gate looking up at the windows. Seen from across the lane, faces small and turned. Life going on, gentle, a little poignant.

## town-festival_v0.webp (town; tiers 0-8; "the harvest festival")

- Kept: candidate c2. Shipped `pictures/town-festival_v0.webp` (1024 x 683, cwebp q85), sha256 `b31e8d43dc82d7e7665851581b075f48a0a06581134b7c3d13933f4098ce4021`; master `town-festival_v0.png` (1536 x 1024 RGB, byte-for-byte copy of the generator output), sha256 `e35c9a9d873eebaeab56d1949eb75323bb6df9e4644fc9b3835c438f1a3c1a01`.
- Candidates: 2.

### town-festival_c1

- Generator output `exec-cc234022-2ab7-4283-8d26-b57c58fbf608.png`, sha256 `6f5a441042f48df1d15f73d6acb5d2b08aab31d2164e8cf4ea82ba5eb1d0f3d3`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_town-festival.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, rejected: 1:1 clean of text, but the church bell tower carries a cross (a symbol, though it sits in the top strip the 16:9 crop removes), and the diners in the foreground show mid-size faces turned toward us. Retried from higher up with no church.

### town-festival_c2

- Generator output `exec-06ea443f-28ad-449f-8e49-f6ddf7523ef0.png`, sha256 `e35c9a9d873eebaeab56d1949eb75323bb6df9e4644fc9b3835c438f1a3c1a01`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_town-festival_r1.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, kept: Full frame and 1:1 clean: no church or cross; paper lanterns, musicians with accordion and fiddle on the loggia steps, dancers, long tables, wine bottles unlabelled. Seen from a high balcony; the diners in the foreground have small faces (about 25 px), some toward us. Dish on the headland.

### Prompt town-festival (full prompt = style block, a blank line, then this scene paragraph; verbatim)

> Scene, the harvest festival: the town's main square on a warm evening, strings of paper lanterns criss-crossing above, long tables with food and wine, musicians with accordion and fiddle on the church steps, couples dancing on the cobbles, children weaving through the crowd. Seen from a little above at the edge of the square, figures small. Lantern light glowing amber against the dusk-blue sky. Joyful, communal, timeless.

### Prompt town-festival_r1 (retry scene paragraph, verbatim)

> Scene, the harvest festival: the town's main square on a warm evening, seen from a high balcony at the edge of the square so that every figure is small, strings of paper lanterns criss-crossing above, long tables with food and wine, musicians with accordion and fiddle on the steps of an old stone loggia, couples dancing on the cobbles, children weaving through the crowd. No church, crosses or religious symbols in view. Lantern light glowing amber against the dusk-blue sky. Joyful, communal, timeless.

## town-market_v0.webp (town; tiers 0-8; "market day")

- Kept: candidate c1. Shipped `pictures/town-market_v0.webp` (1024 x 683, cwebp q85), sha256 `6e10e641cc1b1e0dae5442c1a9beb634d4c71600e47732afcfebd263c94ca3c7`; master `town-market_v0.png` (1536 x 1024 RGB, byte-for-byte copy of the generator output), sha256 `3f01f63b950685ccdfeb40dbbbf4a9023f25aa16dc75984d127edf24d9cf9051`.
- Candidates: 1.

### town-market_c1

- Generator output `exec-756a4aa7-7428-4672-bf99-0f1b4523110b.png`, sha256 `3f01f63b950685ccdfeb40dbbbf4a9023f25aa16dc75984d127edf24d9cf9051`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_town-market.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, kept: 1:1 clean: awnings plain striped, crates and the balance scale unmarked, boats unnamed. Vendors in profile, eyes down at their work; shoppers from behind; a dog under the fish stall; dish on the hill.

### Prompt town-market (full prompt = style block, a blank line, then this scene paragraph; verbatim)

> Scene, market day: a busy morning market along the harbour front of the town, stalls under plain striped canvas awnings piled with tomatoes, peppers, lemons, fish on ice, bread, flowers. Shoppers with woven baskets, a vendor weighing fruit on an old balance scale, a dog under a table, fishing boats at the quay behind. Seen at street level, faces small or turned. Bustling, colourful, everyday.

## town-school-fair_v0.webp (town; tiers 0-5; "the school fair")

- Kept: candidate c1. Shipped `pictures/town-school-fair_v0.webp` (1024 x 683, cwebp q85), sha256 `ca751143eaf9255dbf31002a83e7816d59b990b546eef30b2f1b88b4539b843e`; master `town-school-fair_v0.png` (1536 x 1024 RGB, byte-for-byte copy of the generator output), sha256 `ab8d7a787f1239dda6ca2c4704d7fa19853a18f29c567efd66072bee4dc2c4a8`.
- Candidates: 1.

### town-school-fair_c1

- Generator output `exec-fe034386-5602-4748-aa27-d5c0dbd32ca7.png`, sha256 `ab8d7a787f1239dda6ca2c4704d7fa19853a18f29c567efd66072bee4dc2c4a8`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_town-school-fair.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, kept: 1:1 clean: bunting plain triangles, jars unlabelled, ring-toss pegs unmarked. Children and parents small, most from behind or in profile; dish and bay at right. Light-hearted.

### Prompt town-school-fair (full prompt = style block, a blank line, then this scene paragraph; verbatim)

> Scene, the school fair: the courtyard of the town's old stone school on a sunny afternoon, plain coloured bunting in triangles overhead, trestle tables with cakes and jars of jam, a ring-toss game, children running with balloons, a teacher handing out lemonade, parents chatting under a plane tree. Seen from the school steps, figures small. Light-hearted, a little chaotic, kind.

## town-new-tower_v0.webp (town; tiers 3-8; "a new tower on the skyline")

- Kept: candidate c1. Shipped `pictures/town-new-tower_v0.webp` (1024 x 683, cwebp q85), sha256 `d3d2d0ecaddb417611ebe1e1fa06c74d4817db22064f3314aa974aa4b23ddf96`; master `town-new-tower_v0.png` (1536 x 1024 RGB, byte-for-byte copy of the generator output), sha256 `01e67b1d5aeab910a21ff4a8aee515397e3c8669f7efa8372d189c025d8fa136`.
- Candidates: 1.

### town-new-tower_c1

- Generator output `exec-f0f373dc-4bae-4e2e-9411-6cb4ea8db0f4.png`, sha256 `01e67b1d5aeab910a21ff4a8aee515397e3c8669f7efa8372d189c025d8fa136`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_town-new-tower.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, kept: 1:1 clean; a tall pale stone-and-glass tower with planted terraces above the terracotta roofs near the harbour, two townspeople from behind on the path; the dish on the headland. The man is in three-quarter rear profile.

### Prompt town-new-tower (full prompt = style block, a blank line, then this scene paragraph; verbatim)

> Scene, a new tower on the skyline: seen from the hillside path above the town in clear morning light, a new tall slender tower rises above the old terracotta roofs and cypresses near the harbour, pale stone and glass with planted green terraces stepping up its sides, quite unlike anything else in town. Two townspeople on the path stop to look at it. The bay and the white dish on the headland beyond. Curious, not hostile: the town changing.

## town-flood_v0.webp (town; tiers 2-8; "the harbour floods")

- Kept: candidate c1. Shipped `pictures/town-flood_v0.webp` (1024 x 683, cwebp q85), sha256 `0cc98d92f65953181ddc31d021d41115c628c73d563caf9b954c5f336a9683f3`; master `town-flood_v0.png` (1536 x 1024 RGB, byte-for-byte copy of the generator output), sha256 `b64a17587a3734b7589d46a6bf992e142f29f695882ad3b2bb94fa760aec0e55`.
- Candidates: 1.

### town-flood_c1

- Generator output `exec-9380b5ed-6c44-478e-bac3-0c72a5648c6a.png`, sha256 `b64a17587a3734b7589d46a6bf992e142f29f695882ad3b2bb94fa760aec0e55`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_town-flood.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, kept: 1:1 clean: the boats carry no names or numbers, the awning is plain. Surge over the harbour wall, neighbours wading with crates and baskets, two men guiding a rowing boat with an old couple; seen from a stair above. Serious, steady, kind. The dish sits at y~60, just inside the cropped top strip; it is scenery only.

### Prompt town-flood (full prompt = style block, a blank line, then this scene paragraph; verbatim)

> Scene, the harbour floods: a grey storm morning after a high surge, the sea spilling over the harbour wall into the waterfront street of the town. Fishing boats bob high against the quay, cafe chairs float, people in boots wade knee-deep carrying belongings and helping one another, a rowing boat ferrying an old couple. Seen from a staircase above the street. Serious but steady, neighbours helping neighbours.

## town-lights_v0.webp (town; tiers 0-8; "the town lights at night")

- Kept: candidate c1. Shipped `pictures/town-lights_v0.webp` (1024 x 683, cwebp q85), sha256 `d39d7adad10fa8551100aab36d4b3320104ce4f92bdff37e00410b60762b0235`; master `town-lights_v0.png` (1536 x 1024 RGB, byte-for-byte copy of the generator output), sha256 `ade53b1ac6da55addaec9acfa968a7098bcd432400ed8f420c677dd6d7fdc1dc`.
- Candidates: 1.

### town-lights_c1

- Generator output `exec-454aba1c-0cad-44d2-a44b-23d6ed0e767d.png`, sha256 `ade53b1ac6da55addaec9acfa968a7098bcd432400ed8f420c677dd6d7fdc1dc`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_town-lights.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, kept: 1:1 clean; the town's lit windows and lamps down to the bay, boat lights reflected, the dish pale under the Milky Way, one figure from behind on the wall. Calm and homesick.

### Prompt town-lights (full prompt = style block, a blank line, then this scene paragraph; verbatim)

> Scene, the town lights at night: seen from the dark hillside above, the town at night spread down the slope to the bay, hundreds of small warm windows and streetlamps glowing gold, their reflections trembling on the black water, a few boat lights in the bay, the white dish on the headland a pale silhouette under a deep starry sky. A single figure sits on a low wall in the foreground, seen from behind. Calm, beautiful, homesick.

## town-dawn_v0.webp (town; tiers 0-8; "a quiet street at dawn")

- Kept: candidate c1. Shipped `pictures/town-dawn_v0.webp` (1024 x 683, cwebp q85), sha256 `1a8aa921271153a7589c1ead8bb445e4ef37140939026ba96a5a6d95c2779ae8`; master `town-dawn_v0.png` (1536 x 1024 RGB, byte-for-byte copy of the generator output), sha256 `60d9589104c296429758a423fd54cd9ac7af9bee72e17ff3cfbfd3a73b4cbaf5`.
- Candidates: 1.

### town-dawn_c1

- Generator output `exec-8fa63ed9-e643-4a64-b7a6-b45f7bf6c86b.png`, sha256 `60d9589104c296429758a423fd54cd9ac7af9bee72e17ff3cfbfd3a73b4cbaf5`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_town-dawn.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, kept: 1:1 clean: the awning and doors unmarked. A baker in profile setting out loaves, a cat on the step, a sweeper from behind down the lane, the sun low over the sea and the dish on the headland. Still and warm.

### Prompt town-dawn (full prompt = style block, a blank line, then this scene paragraph; verbatim)

> Scene, a quiet street at dawn: a narrow sloping street of the town just after sunrise, long pink-gold light catching the tops of the ochre walls, shutters still closed, a baker setting out loaves on a wooden board outside an open doorway, a cat on a step, a sweeper with a broom further down, the sea glimpsed at the bottom of the street. Still, peaceful, the day not yet begun.

## town-cinema_v0.webp (town; tiers 4-8; "the old cinema closes")

- Kept: candidate c1. Shipped `pictures/town-cinema_v0.webp` (1024 x 683, cwebp q85), sha256 `c14fb5c167541283908752bc890cb90bfab2300aefc5cd5cf5189ee54aff8478`; master `town-cinema_v0.png` (1536 x 1024 RGB, byte-for-byte copy of the generator output), sha256 `775dc3910f2d792cb2a31752091fea5c0bd3dd4c353888d61992b64b20a38fdd`.
- Candidates: 1.

### town-cinema_c1

- Generator output `exec-8aec5b38-be1a-4437-8cad-e7eb2649af1e.png`, sha256 `775dc3910f2d792cb2a31752091fea5c0bd3dd4c353888d61992b64b20a38fdd`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_town-cinema.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, kept: 1:1 clean: the curved canopy is completely blank, the poster cases empty and dark, the doors shut. An old man with his hand on the door from behind, a couple arm in arm from behind, townspeople mostly turned away; one old man at far left in profile. Nostalgic.

### Prompt town-cinema (full prompt = style block, a blank line, then this scene paragraph; verbatim)

> Scene, the old cinema closes: a little old picture house on a corner of the town, its curved plaster facade faded, the canopy over the door completely blank, the glass doors shut and the poster cases empty and bare. A small group of townspeople stand outside on a dusky evening, an old man touching the door, a couple arm in arm. Warm streetlamp light. Nostalgic, an ending, gentle.

## world-election_v0.webp (world; tiers 0-8; "election day")

- Kept: candidate c1. Shipped `pictures/world-election_v0.webp` (1024 x 683, cwebp q85), sha256 `fbec2ccd3ffa5431104554241f6b8d71e3cb05089ca7d33d0bbdc297857d00fd`; master `world-election_v0.png` (1536 x 1024 RGB, byte-for-byte copy of the generator output), sha256 `6c34e09631e6f8da4b3950a7092e1ee318438e7800745ae0b9e764ab96904098`.
- Candidates: 1.

### world-election_c1

- Generator output `exec-2dd773c2-886f-4a6e-a8e0-1de65759d108.png`, sha256 `6c34e09631e6f8da4b3950a7092e1ee318438e7800745ae0b9e764ab96904098`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_world-election.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, kept: Full frame and 1:1 quadrants clean: the door, the walls and the box are unmarked (a small dark lid shape on the box reads as part of the box). Faces are mid-size profiles in a queue, mostly turned toward the door; civic and warm.

### Prompt world-election (full prompt = style block, a blank line, then this scene paragraph; verbatim)

> Scene, election day: early morning outside the town hall, an old stone building on the square, a patient line of townspeople of all ages waiting to vote, an old woman on a cane helped by a young man, a parent with a child on their hip. Through the open door a simple wooden box on a table; nothing on the walls or doors. Seen across the square, faces small. Civic, ordinary, quietly hopeful.

## world-treaty_v0.webp (world; tiers 1-8; "a treaty is signed")

- Kept: candidate c1. Shipped `pictures/world-treaty_v0.webp` (1024 x 683, cwebp q85), sha256 `134e9548cb9667a10fd4abfc6068c5b17277d2020694c1fcfa7a5776f8825c68`; master `world-treaty_v0.png` (1536 x 1024 RGB, byte-for-byte copy of the generator output), sha256 `95eb0932464f186fdbc0d2ce298250208e028befc6be4afaf92dca92ef2d20ce`.
- Candidates: 1.

### world-treaty_c1

- Generator output `exec-68470664-97ab-4c44-ac78-f45fff3253c1.png`, sha256 `95eb0932464f186fdbc0d2ce298250208e028befc6be4afaf92dca92ef2d20ce`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_world-treaty.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, kept: Full frame and 1:1 quadrants clean: the sheets on the table are blank, no emblems or banners; signers small at the centre, the crowd seen from behind. The hall's windows look onto a coast like the town's, which is acceptable (no real place).

### Prompt world-treaty (full prompt = style block, a blank line, then this scene paragraph; verbatim)

> Scene, a treaty is signed: in a grand high hall far from the town, tall windows full of daylight, a long polished table, two small distant figures at its centre leaning to sign plain blank sheets while rows of delegates watch from the sides; nobody recognisable, no emblems or banners anywhere. Seen from the back of the hall, high and far. In the warm light it feels solemn and hopeful.

## world-march_v0.webp (world; tiers 0-8; "a march in the capital")

- Kept: candidate c2. Shipped `pictures/world-march_v0.webp` (1024 x 683, cwebp q85), sha256 `e4013571976133197e561387f1222d382ab5fc8bc656bab1fbcf8c70093588ef`; master `world-march_v0.png` (1536 x 1024 RGB, byte-for-byte copy of the generator output), sha256 `ccd61c0d0ad9c296b9402b7f5352258cee3be87009372b4a1e9a0e339849689f`.
- Candidates: 2.

### world-march_c1

- Generator output `exec-88de9a51-f700-4be6-ab78-23ff81ae84fe.png`, sha256 `f11a68d3ab21f500eaaa7eaf29bf28b25009b4fa92fa11df4271580bf56f2f23`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_world-march.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, rejected (superseded by c2): 1:1 clean: no banners, placards, signs or flags; lanterns and flowers; the march walks away from us, faces small. Flag for review: the far skyline (a dome, bell towers, an arched bridge over a river) evokes an Italian capital without matching a real one.

### world-march_c2

- Generator output `exec-cf9ad2a1-2262-406d-a1a7-aade68111ae6.png`, sha256 `ccd61c0d0ad9c296b9402b7f5352258cee3be87009372b4a1e9a0e339849689f`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_world-march_r1.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, kept: Full frame and 1:1 clean: a plain modern avenue with no domes, monuments or river, so no real capital is suggested; the march with lanterns and flowers walks away from us, two watchers on the balcony in small rear profile. One marcher at lower centre carries a small blank pale board (no marks at 1:1); accepted as a box-like object, flagged for review.

### Prompt world-march (full prompt = style block, a blank line, then this scene paragraph; verbatim)

> Scene, a march in the capital: a broad avenue of an unnamed old capital city, handsome stone buildings and plane trees, filled from side to side with a peaceful march of ordinary people of every age, walking arm in arm, some carrying flowers and small paper lanterns, a child on someone's shoulders. No banners, placards, signs or flags at all. Seen from a balcony above, the crowd flowing into the distance, faces small. Determined, peaceful, together.

### Prompt world-march_r1 (retry scene paragraph, verbatim)

> Scene, a march in the capital: a broad straight avenue of an unnamed modern capital city, plain handsome stone and glass buildings of no famous style, rows of plane trees, no domes, towers, monuments or river in view, filled from side to side with a peaceful march of ordinary people of every age, walking arm in arm, some carrying flowers and small paper lanterns, a child on someone's shoulders. No banners, placards, signs or flags at all. Seen from a balcony above, the crowd flowing away into the distance, faces small. Determined, peaceful, together.

## world-heat_v0.webp (world; tiers 0-8; "the hottest summer yet")

- Kept: candidate c1. Shipped `pictures/world-heat_v0.webp` (1024 x 683, cwebp q85), sha256 `36c5ecd419a0d0be9bec3f3f74048c6fe145356caf289026bda6117f7042693b`; master `world-heat_v0.png` (1536 x 1024 RGB, byte-for-byte copy of the generator output), sha256 `1ec9ad6c36cd11051ac2e97e97066d8df444e0a51fef85e8a39aa320a4b0bbe8`.
- Candidates: 1.

### world-heat_c1

- Generator output `exec-eb799446-5327-417f-96ec-b4f5a90f49f5.png`, sha256 `1ec9ad6c36cd11051ac2e97e97066d8df444e0a51fef85e8a39aa320a4b0bbe8`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_world-heat.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, kept: 1:1 clean; parched gold hills, shade under the plane tree, children at the fountain, a dog asleep on the step. Sweltering but calm.

### Prompt world-heat (full prompt = style block, a blank line, then this scene paragraph; verbatim)

> Scene, the hottest summer yet: the town under a white-hot afternoon sky, the hills behind it parched gold and brown, the air shimmering, shutters closed against the sun. In the square people crowd into the narrow shade of a plane tree and an awning, an old man fanning himself, children cooling their hands and feet in the stone fountain, a dog flat on the cool step. Heavy, sweltering, endured together, without alarm.

## world-final_v0.webp (world; tiers 0-8; "the cup final")

- Kept: candidate c1. Shipped `pictures/world-final_v0.webp` (1024 x 683, cwebp q85), sha256 `58db7f479bc5c592b7315abaef7d459f39f0c46f7652c3e28d9db554d31d07e5`; master `world-final_v0.png` (1536 x 1024 RGB, byte-for-byte copy of the generator output), sha256 `de474273b69aef80823c8141398f82695b4dbab998920071fa9bb2fbafa0d5b1`.
- Candidates: 1.

### world-final_c1

- Generator output `exec-a9e9be15-61ff-4512-9130-42ee0157dc25.png`, sha256 `de474273b69aef80823c8141398f82695b4dbab998920071fa9bb2fbafa0d5b1`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_world-final.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, kept: 1:1 clean: the bar's bottles carry no labels, scarves are plain, the crowd faces away toward the lit doorway. Raised fists read as celebration in context.

### Prompt world-final (full prompt = style block, a blank line, then this scene paragraph; verbatim)

> Scene, the cup final: the town's square on a warm night, a crowd packed outside the cafe in front of an open doorway glowing with light, everyone facing away from us toward something inside we cannot see; at the front some leap up with arms raised, others clutch their heads or hug; plain coloured scarves with no patterns, a boy on his father's shoulders. Faces turned away. Electric, communal, joy and agony at once.

## world-rebuilt_v0.webp (world; tiers 2-8; "a city rebuilt after the quake")

- Kept: candidate c3. Shipped `pictures/world-rebuilt_v0.webp` (1024 x 683, cwebp q85), sha256 `8bcc24bef0c0ec3a8ac2934da9c24d40c66f873a094ec8bc2e454e6d91b5702e`; master `world-rebuilt_v0.png` (1536 x 1024 RGB, byte-for-byte copy of the generator output), sha256 `c7fa1a53bae1d98f7c268b4fa16f09802072c4470f97d16187cf63a7f5392215`.
- Candidates: 3.

### world-rebuilt_c1

- Generator output `exec-55c4758a-78c4-43fb-bd80-d3a6a9acc231.png`, sha256 `128f4b8f0b33c1d2fc1a52b6335a7044148cf2b932eeb8c6efb56cdf889a808c`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_world-rebuilt.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, rejected: 1:1 clean and a fine picture, but the town's white dish stands on the headland at right, so the quake city reads as home itself, against the scene ("far from the town") and the continuity of the other pictures. Retried inland, with no dish and no sea.

### world-rebuilt_c2

- Generator output `exec-a77e0507-1c2b-40d6-b57d-470fa89fdf00.png`, sha256 `1f2fe6ba6a0d667d2f49966a515e68c1b284327f75e26c5698f0510f3255bf36`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_world-rebuilt_r1.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, rejected: 1:1 clean of text, and the inland mountain city fixes the continuity problem, but the bell tower and the church each carry a small cross (a symbol; the church's at y~205 is inside the 16:9 band). Retried once more with a civic tower and no religious buildings.

### world-rebuilt_c3

- Generator output `exec-c7b3da3f-6061-4ce2-8c06-a6b6398a455c.png`, sha256 `c7fa1a53bae1d98f7c268b4fa16f09802072c4470f97d16187cf63a7f5392215`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_world-rebuilt_r2.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, kept: Full frame and 1:1 clean: an inland mountain city with no sea, dish, church or cross; a plain civic tower with its scaffolding, old ruined walls kept beside new houses, gardens in the rubble, families carrying furniture, a new market square. Faces small, mostly from behind.

### Prompt world-rebuilt (full prompt = style block, a blank line, then this scene paragraph; verbatim)

> Scene, a city rebuilt after the quake: far from the town, a hillside city of stone in clear morning light, new pale houses with fresh roofs standing among a few old cracked walls kept as they were, a rebuilt bell tower with its scaffolding just coming down, gardens planted in former rubble. Families carry furniture into new homes, a market setting up in a new square. Seen from a terrace above, figures small. Resilient, healing, hopeful.

### Prompt world-rebuilt_r1 (retry scene paragraph, verbatim)

> Scene, a city rebuilt after the quake: far inland from the town, a hillside city of pale stone among mountains, with no sea and no radio dish anywhere in view, in clear morning light: new pale houses with fresh roofs stand among a few old cracked walls kept as they were, a rebuilt bell tower with its scaffolding just coming down, gardens planted in former rubble. Families carry furniture into new homes, a market setting up in a new square. Seen from a terrace above, figures small. Resilient, healing, hopeful.

### Prompt world-rebuilt_r2 (retry scene paragraph, verbatim)

> Scene, a city rebuilt after the quake: far inland from the town, a hillside city of pale stone among mountains, with no sea and no radio dish anywhere in view, in clear morning light: new pale houses with fresh roofs stand among a few old cracked walls kept as they were, a rebuilt square stone civic tower with plain arched openings and its scaffolding just coming down, gardens planted in former rubble. No churches, crosses or religious symbols anywhere. Families carry furniture into new homes, a market setting up in a new square. Seen from a terrace above, figures small. Resilient, healing, hopeful.

## world-new-nation_v0.webp (world; tiers 4-8; "a new nation's first morning")

- Kept: candidate c1. Shipped `pictures/world-new-nation_v0.webp` (1024 x 683, cwebp q85), sha256 `310cf71a316f62b543e79426f89d5043ce45a5800337d390f44ff4b7071f5279`; master `world-new-nation_v0.png` (1536 x 1024 RGB, byte-for-byte copy of the generator output), sha256 `b1f6df2624703cd16f7e8e710b912d3e4f5b236011ea25f6ab6ac106091443b4`.
- Candidates: 1.

### world-new-nation_c1

- Generator output `exec-41a3e48f-a0d5-498f-98c4-a8e5cca78b3c.png`, sha256 `b1f6df2624703cd16f7e8e710b912d3e4f5b236011ea25f6ab6ac106091443b4`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_world-new-nation.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, kept: 1:1 clean: no flags, banners or emblems; sky lanterns, pale confetti and thinning firework smoke over a coastal city at sunrise (no dish, so not the home town); people embracing and resting on steps, faces small.

### Prompt world-new-nation (full prompt = style block, a blank line, then this scene paragraph; verbatim)

> Scene, a new nation's first morning: far from the town, a wide plaza in an unnamed city on a hillside at sunrise, a gathering of ordinary people of all ages, some embracing, some sitting quietly on steps, a few releasing paper lanterns, plain pale confetti drifting in the low gold light, the last smoke of fireworks thinning in the sky. No flags, banners, emblems or signs at all. Seen from above at the edge of the plaza, faces small. Tired, moved, a new beginning.

## world-eclipse_v0.webp (world; tiers 0-8; "a total eclipse")

- Kept: candidate c1. Shipped `pictures/world-eclipse_v0.webp` (1024 x 683, cwebp q85), sha256 `14647a60ac8e048db3b58a7caa86ff925b77384d4a960306fe0b0a0b61985d73`; master `world-eclipse_v0.png` (1536 x 1024 RGB, byte-for-byte copy of the generator output), sha256 `d850f616f7b2e1a91132ec7a7344fae3e0b1b42709de1ddd49533d747cb2a1f3`.
- Candidates: 1.

### world-eclipse_c1

- Generator output `exec-f6403add-b7b2-47d0-b3fd-fdf3a4a5cdd9.png`, sha256 `d850f616f7b2e1a91132ec7a7344fae3e0b1b42709de1ddd49533d747cb2a1f3`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_world-eclipse.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, kept: 1:1 clean; black disc and corona high but inside the 16:9 band, a ring of sunset colour on the horizon, birds settling on the water, the townspeople from behind with a child pointing.

### Prompt world-eclipse (full prompt = style block, a blank line, then this scene paragraph; verbatim)

> Scene, a total eclipse: midday turned to dusk over the bay, the black disc of the Moon covering the Sun high in a deep blue-grey sky, the pale silver corona streaming around it, a few bright stars and planets out, a ring of sunset colour along the whole horizon. On the town's beach people stand and sit looking up, a child pointing, birds settling on the water. Seen from behind the crowd. Awe, stillness, a shared intake of breath.

## science-launch_v0.webp (science; tiers 0-8; "a rocket launch")

- Kept: candidate c2. Shipped `pictures/science-launch_v0.webp` (1024 x 683, cwebp q85), sha256 `bf2c0aff434477a8d643550ee915f3b00ca8d48a83aaab51847b244f48879586`; master `science-launch_v0.png` (1536 x 1024 RGB, byte-for-byte copy of the generator output), sha256 `5669b27c408adcb291d0992e342f48e23d8ab216189206e63bd7f10971488c4e`.
- Candidates: 2.

### science-launch_c1

- Generator output `exec-8ef9987d-604e-4c93-80b4-d7282f62cd20.png`, sha256 `262374881bf1664428e8104ee552d5af4d77b1f13c3d7a3af6f4530536e1c59d`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_science-launch.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, rejected: Clean at 1:1, but the rocket itself sits at y~75 of 1024, inside the top tenth that the 16:9 crop removes; only the trail would survive. Retried with the rocket low in the sky.

### science-launch_c2

- Generator output `exec-0d6c0c7a-c5b2-4e5e-b97b-d90c5a91cba5.png`, sha256 `5669b27c408adcb291d0992e342f48e23d8ab216189206e63bd7f10971488c4e`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_science-launch_r1.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, kept: Full frame and 1:1 clean: a plain unmarked rocket and its plume low over the far headland at y~290-460, well inside the 16:9 band, reflected on the sea; the townspeople on the beach all from behind, a child on a shoulder; the town and dish at left.

### Prompt science-launch (full prompt = style block, a blank line, then this scene paragraph; verbatim)

> Scene, a rocket launch: seen from the town's beach in the evening, far down the coast across the bay a generic rocket rises from a distant launch site on a long column of bright flame and billowing white smoke, a thin arc of exhaust curving up into the pink and violet sky, its light reflected on the calm sea. People on the sand stand and watch, a child on a parent's shoulders, seen from behind. The rocket is small and distant, plain and unmarked. Wonder, quiet pride.

### Prompt science-launch_r1 (retry scene paragraph, verbatim)

> Scene, a rocket launch: seen from the town's beach in the evening, far down the coast across the bay a generic rocket lifts off from a distant launch site on a short column of bright flame and billowing white smoke, still low in the sky just above the far headland, near the middle of the frame, its glow reflected on the calm sea. People on the sand stand and watch, a child on a parent's shoulders, seen from behind. The rocket is small and distant, plain and unmarked, and the whole rocket and its flame sit in the middle band of the picture, well below the top edge. Wonder, quiet pride.

## science-telescope_v0.webp (science; tiers 1-8; "a telescope's first light")

- Kept: candidate c2. Shipped `pictures/science-telescope_v0.webp` (1024 x 683, cwebp q85), sha256 `f3373d9cd26a041b3e87f1f3c8c9f0558454a93315eda737297d6d7661c18e13`; master `science-telescope_v0.png` (1536 x 1024 RGB, byte-for-byte copy of the generator output), sha256 `37b12a7aade3fa2dd304752450da0f4867940475f023ccf9aa8397aa71a60f96`.
- Candidates: 2.

### science-telescope_c1

- Generator output `exec-1c4ca913-9abc-4381-8dcc-a85105ec69c8.png`, sha256 `84ab8d16d7750e70afa167e4f9cc31912c69af333e5ca2047b949bc3b447e95a`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_science-telescope.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, rejected: Clean at 1:1, but the instrument in the open slit is an antique brass refractor, which dates the picture to about a century before departure and reads oddly for a new telescope across tiers 1-8. Retried with the telescope hidden inside the dome.

### science-telescope_c2

- Generator output `exec-ae0d5bd2-01cb-4284-a395-3f68fe1c26cf.png`, sha256 `37b12a7aade3fa2dd304752450da0f4867940475f023ccf9aa8397aa71a60f96`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_science-telescope_r1.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, kept: Full frame and 1:1 clean: a plain pale dome with the slit open on a warm glow, no instrument visible; small figures on the ridge from behind, a coastal town far below at dusk. Timeless across tiers 1-8.

### Prompt science-telescope (full prompt = style block, a blank line, then this scene paragraph; verbatim)

> Scene, a telescope's first light: on a high bare mountain ridge inland at dusk, a large new observatory dome stands with its slit open to the first stars, its pale curved shell catching the last pink light, the coast and the bay faint and far below. A handful of small figures stand outside on the ridge, one with an arm round another, looking up at the clearing sky. The dome plain and unmarked. Anticipation, wonder, calm.

### Prompt science-telescope_r1 (retry scene paragraph, verbatim)

> Scene, a telescope's first light: on a high bare mountain ridge inland at dusk, a large new observatory dome of smooth pale shell stands with its slit open to the first stars; the telescope inside is hidden in shadow, only a soft warm glow showing through the slit. Its curved shell catches the last pink light, the coast and the bay faint and far below. A handful of small figures stand outside on the ridge, one with an arm round another, looking up at the clearing sky, seen from behind. The dome plain and unmarked. Anticipation, wonder, calm.

## science-medicine_v0.webp (science; tiers 2-8; "a new medicine")

- Kept: candidate c2. Shipped `pictures/science-medicine_v0.webp` (1024 x 683, cwebp q85), sha256 `05c8a0915258bb0dfd3548e24a2ea728c513cc5594e9061ad3593f990d0780cd`; master `science-medicine_v0.png` (1536 x 1024 RGB, byte-for-byte copy of the generator output), sha256 `115f20438c9e6e83515066004b53794f1da9f565d5426aa1902f5f8c2bbfc387`.
- Candidates: 2.

### science-medicine_c1

- Generator output `exec-ed51ac9f-b224-4267-b7c9-1c2b66a580b5.png`, sha256 `7f86f2c4c6af677c7b59aa5dc982f12bfa064e72a5460ccdaef6fc7e7c3df619`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_science-medicine.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, rejected: Clean at 1:1, but the nurse and the old man are large and their faces fill the left half, against the small-or-turned-away rule. Retried from across the room.

### science-medicine_c2

- Generator output `exec-85f6fada-3893-4449-9902-ce139f393d4f.png`, sha256 `115f20438c9e6e83515066004b53794f1da9f565d5426aa1902f5f8c2bbfc387`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_science-medicine_r1.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, kept: Full frame and 1:1 clean: the vial and the bottles in the niche are unlabelled. Seen from across the room: the nurse in downcast profile, the old man from behind, the daughter at the window from behind with a hand on his shoulder. Gentle, hopeful.

### Prompt science-medicine (full prompt = style block, a blank line, then this scene paragraph; verbatim)

> Scene, a new medicine: a sunlit room of the town's small clinic with whitewashed walls and an open window on the sea. A nurse in plain clothes sits beside an elderly man in a chair, giving him a dose from a small plain glass vial with no label; his grown daughter holds his hand and looks out of the window, relieved. A potted plant and a jug of water on the sill. Gentle, quietly hopeful.

### Prompt science-medicine_r1 (retry scene paragraph, verbatim)

> Scene, a new medicine: a sunlit room of the town's small clinic with whitewashed walls and an open window on the sea, seen from across the room so the people are small in the frame. A nurse in plain clothes, seen from behind, sits beside an elderly man in a chair by the window, handing him a dose from a small plain glass vial with no label; his grown daughter stands at the window with her back to us, one hand on his shoulder, looking out at the bay, relieved. Faces turned away or in distant profile. A potted plant and a jug of water on the sill. Gentle, quietly hopeful.

## science-fusion_v0.webp (science; tiers 4-8; "the first fusion plant")

- Kept: candidate c1. Shipped `pictures/science-fusion_v0.webp` (1024 x 683, cwebp q85), sha256 `6c2381e252aecd30d91710388b7ef139c39dc26b1cff5fc8cf64965cac527a91`; master `science-fusion_v0.png` (1536 x 1024 RGB, byte-for-byte copy of the generator output), sha256 `403e49a8de45d42ae00f15e1157dacdc94c7dd79a1cb070fff652b37a7ccec05`.
- Candidates: 1.

### science-fusion_c1

- Generator output `exec-4f40b94b-902a-440c-9025-ccedb5e70409.png`, sha256 `403e49a8de45d42ae00f15e1157dacdc94c7dd79a1cb070fff652b37a7ccec05`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_science-fusion.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, kept: 1:1 clean: a glowing ring hall on the coastal plain, no chimneys or smoke, old man and young person from behind on a terrace wall; town lights coming on. Reads as a turning point without dating anything.

### Prompt science-fusion (full prompt = style block, a blank line, then this scene paragraph; verbatim)

> Scene, the first fusion plant: seen from the hills behind the town at dusk, far off on the coastal plain a new power station: a broad low ring-shaped hall of pale stone and glass with soft blue light glowing from within, no smoke and no chimneys, clean lines among fields. On a hillside terrace two townspeople, one old and one young, sit side by side looking at it. The town's lights are coming on below. Quiet wonder, a turning point.

## science-moon-base_v0.webp (science; tiers 3-8; "a base on the Moon")

- Kept: candidate c1. Shipped `pictures/science-moon-base_v0.webp` (1024 x 683, cwebp q85), sha256 `a3a0057f3a275e7bdf42d95b4ea5b7bacfff147f30c33bfce0c188d69ff545f4`; master `science-moon-base_v0.png` (1536 x 1024 RGB, byte-for-byte copy of the generator output), sha256 `fea92732f16f6a3c9fa79e3af890f444ef86bc533d648c514d38cb4a2b115bd5`.
- Candidates: 1.

### science-moon-base_c1

- Generator output `exec-6dea1a53-28dd-48a7-aa29-2a3064fd796b.png`, sha256 `fea92732f16f6a3c9fa79e3af890f444ef86bc533d648c514d38cb4a2b115bd5`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_science-moon-base.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, kept: 1:1 clean: a cluster of warm lights on the earthlit part of a crescent Moon, family from behind on a terrace. The Moon's top edge (y~50) falls just inside the top tenth and is slightly clipped by the 16:9 crop; the lights (y~205) are well inside.

### Prompt science-moon-base (full prompt = style block, a blank line, then this scene paragraph; verbatim)

> Scene, a base on the Moon: a clear night, a large bright crescent Moon low over the sea, and on its dark, earthlit part a tiny cluster of faint warm lights can be seen. On a rooftop terrace of the town a family looks up at it together, a parent pointing, a child leaning on the parapet, seen from behind. Potted herbs, a lamp, the bay shining below. Wonder, closeness, something new up there.

## science-mars_v0.webp (science; tiers 5-8; "footsteps on Mars")

- Kept: candidate c2. Shipped `pictures/science-mars_v0.webp` (1024 x 683, cwebp q85), sha256 `d016a6a05924e68f464d211c7813c2797591550cc520699a7cabbc90914168bf`; master `science-mars_v0.png` (1536 x 1024 RGB, byte-for-byte copy of the generator output), sha256 `7c9e1cb0115b43e90255aa502d40c2efee02ed8d100fee68919cad1a39d39adb`.
- Candidates: 2.

### science-mars_c1

- Generator output `exec-f810bf79-c208-4445-8280-c6a00f4cc25b.png`, sha256 `bb518e99344d4a638acacdc2fcf92168536ea858b79fad3b8aac259e8c65133d`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_science-mars.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, rejected: Clean at 1:1 and no text on the projection, but the footprint came out as a stepped trench that reads as stairs or a grave, not a footprint. Retried with a small suited figure and a line of footprints.

### science-mars_c2

- Generator output `exec-dad09c12-00b2-4473-8d38-9fb51c7e80b5.png`, sha256 `7c9e1cb0115b43e90255aa502d40c2efee02ed8d100fee68919cad1a39d39adb`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_science-mars_r1.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, kept: Full frame and 1:1 clean: the projection shows a plain white-suited figure from behind with a clear line of boot prints on a red plain, no writing, frame or graphics; the suit is unmarked. The crowd from behind, a child on shoulders, an old woman with a hand at her chest; Mars a red point above the town and dish.

### Prompt science-mars (full prompt = style block, a blank line, then this scene paragraph; verbatim)

> Scene, footsteps on Mars: the town's square at night, a crowd gathered in silence before a large image projected onto the whitewashed wall of a building: a rust-red rocky plain under a pale butterscotch sky and, in the dust, a single footprint. Only the picture, with no writing, frame or graphics around it. The crowd seen from behind in silhouette, a child on shoulders, an old woman with a hand on her heart. Above the rooftops, the small red point of Mars in the sky. Awe, a hush.

### Prompt science-mars_r1 (retry scene paragraph, verbatim)

> Scene, footsteps on Mars: the town's square at night, a crowd gathered in silence before a large image projected onto the whitewashed wall of a building: a rust-red rocky plain under a pale butterscotch sky, and on it one small figure in a plain white spacesuit, seen from behind, with a clear line of boot prints trailing behind it across the dust. Only the picture, with no writing, frame or graphics around it, and nothing on the suit. The crowd seen from behind in silhouette, a child on shoulders, an old woman with a hand on her heart. Above the rooftops, the small red point of Mars in the sky. Awe, a hush.

## science-deep-sea_v0.webp (science; tiers 2-8; "the deep sea mapped")

- Kept: candidate c2. Shipped `pictures/science-deep-sea_v0.webp` (1024 x 683, cwebp q85), sha256 `db15e66c345e63b6f6c1649b6840e49c7431a45ad63e33a63dc77a69b6052bfb`; master `science-deep-sea_v0.png` (1536 x 1024 RGB, byte-for-byte copy of the generator output), sha256 `fed88ef42d0a6d02933a743cadf826b2dcd54ea0b8491128fb4005a7dba5b6e8`.
- Candidates: 2.

### science-deep-sea_c1

- Generator output `exec-43ad810f-bb04-48ee-a9ba-ed7985a68a6f.png`, sha256 `f48baada86bdb8fa71f398aa62947f27ccb3acb4f21de15a6356d41331bb43da`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_science-deep-sea.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, rejected: 1:1 clean, but the submersible is a riveted, porthole-studded bathysphere of the Verne kind that dates the picture to the past, and the sea lilies read as palm trees. Retried with a smooth plain submersible.

### science-deep-sea_c2

- Generator output `exec-609a3430-253d-4734-8621-27217abf77ac.png`, sha256 `fed88ef42d0a6d02933a743cadf826b2dcd54ea0b8491128fb4005a7dba5b6e8`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_science-deep-sea_r1.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, kept: Full frame and 1:1 clean: a smooth pale submersible with no rivets, portholes or markings, two beams across a canyon, jellyfish and a luminous eel, feathery sea lilies and sponges. Quiet and vast.

### Prompt science-deep-sea (full prompt = style block, a blank line, then this scene paragraph; verbatim)

> Scene, the deep sea mapped: the deep ocean far below the surface, almost black-blue water, a small rounded unmarked submersible casting two soft beams of light across a vast undersea landscape of ridges and canyons, glowing jellyfish and luminous creatures drifting in the dark, a pale field of sea lilies on the slope below. No people visible. Quiet, vast, newly seen.

### Prompt science-deep-sea_r1 (retry scene paragraph, verbatim)

> Scene, the deep sea mapped: the deep ocean far below the surface, almost black-blue water, a small smooth pale rounded submersible of very simple shape, with no rivets, portholes, markings or lettering, casting two soft beams of light across a vast undersea landscape of ridges and canyons, glowing jellyfish and luminous creatures drifting in the dark, a pale field of feathery sea lilies and sponges on the slope below. No people visible. Quiet, vast, newly seen.

## science-asteroid_v0.webp (science; tiers 5-8; "an asteroid turned aside")

- Kept: candidate c1. Shipped `pictures/science-asteroid_v0.webp` (1024 x 683, cwebp q85), sha256 `58199689cbfaa6560d935bb996515d1fd7668e119c29951e22e5add8f611ba6c`; master `science-asteroid_v0.png` (1536 x 1024 RGB, byte-for-byte copy of the generator output), sha256 `a06969316d85c446721cd8f7ec0ad272c1a8b91c23a0512b63bb90f04c3bfe24`.
- Candidates: 1.

### science-asteroid_c1

- Generator output `exec-954c64dd-f4e5-4dc3-abe0-f2b2c3828f30.png`, sha256 `a06969316d85c446721cd8f7ec0ad272c1a8b91c23a0512b63bb90f04c3bfe24`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_science-asteroid.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, kept: 1:1 clean; a small bright point with a short tail among the stars, townspeople on blankets from behind, a child asleep in a lap. Note: the object reads much like a small comet, which is how an asteroid seen by eye would look only with a tail; acceptable as a picture.

### Prompt science-asteroid (full prompt = style block, a blank line, then this scene paragraph; verbatim)

> Scene, an asteroid turned aside: the night sky over the hills behind the town, a bright small point of light with a faint short tail sliding harmlessly past among the stars, far from Earth. On the hillside, townspeople have come out with blankets to watch, sitting together on the grass, one couple holding each other, a child asleep in a lap, seen from behind. The town's lights below. Relief, gratitude, quiet.

## sky-earthrise_v0.webp (sky; tiers 0-8; "Earth from the Moon")

- Kept: candidate c1. Shipped `pictures/sky-earthrise_v0.webp` (1024 x 683, cwebp q85), sha256 `b35b94874d2878a7d67ce0e0fada47643c4959418850deb55480001f2aaff47b`; master `sky-earthrise_v0.png` (1536 x 1024 RGB, byte-for-byte copy of the generator output), sha256 `edc53d76c8d9f9520671ba805bb6bdbf7ad8c36752c852f7d4c8c65366295756`.
- Candidates: 1.

### sky-earthrise_c1

- Generator output `exec-56802142-b1d2-4ef6-9785-ac975ff096d4.png`, sha256 `edc53d76c8d9f9520671ba805bb6bdbf7ad8c36752c852f7d4c8c65366295756`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_sky-earthrise.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, kept: No people, machines or marks; Earth half-lit over a cratered horizon, well inside the central band. Cleaner, less paper texture than the rest of the set, but in the series' ink language.

### Prompt sky-earthrise (full prompt = style block, a blank line, then this scene paragraph; verbatim)

> Scene, Earth from the Moon: a grey lunar landscape of soft craters and long shadows under a black sky, and above the curved horizon the Earth hangs, half lit, blue oceans and white swirling clouds and brown land, small and luminous. No people, no machines, no footprints. Silent, fragile, home.

## sky-aurora_v0.webp (sky; tiers 0-8; "the aurora")

- Kept: candidate c1. Shipped `pictures/sky-aurora_v0.webp` (1024 x 683, cwebp q85), sha256 `df810a4eecaae91974f270812056e1c06c38ea63f46d2fa3e718284529e9011a`; master `sky-aurora_v0.png` (1536 x 1024 RGB, byte-for-byte copy of the generator output), sha256 `90b01b2de33eaa496f32661239d9da1e246b78b12198bb063e6dc866c1d7ef36`.
- Candidates: 1.

### sky-aurora_c1

- Generator output `exec-3ffa3c55-d039-407c-9b59-81014240f58c.png`, sha256 `90b01b2de33eaa496f32661239d9da1e246b78b12198bb063e6dc866c1d7ef36`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_sky-aurora.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, kept: Full frame and 1:1 clean (boat at lower right unmarked); red and green curtains over the bay, people on the harbour wall seen from behind, dish in silhouette.

### Prompt sky-aurora (full prompt = style block, a blank line, then this scene paragraph; verbatim)

> Scene, the aurora: a rare night when the aurora reaches far south: soft curtains of deep red and faint green light ripple across the starry sky above the bay, reflected in the still sea. On the harbour wall of the town a scattering of people in coats stand and look up, a couple with heads tilted back, a child wrapped in a blanket. The white dish on the headland a dark silhouette. Wonder, a little uncanny, beautiful.

## sky-meteors_v0.webp (sky; tiers 0-8; "a meteor shower")

- Kept: candidate c1. Shipped `pictures/sky-meteors_v0.webp` (1024 x 683, cwebp q85), sha256 `2a38c35900bf7e2c5c48e3d95f4f6791d10cd3e258cd301e66037584ac296fb7`; master `sky-meteors_v0.png` (1536 x 1024 RGB, byte-for-byte copy of the generator output), sha256 `2e1c86716674a4d6131b5f87c40ecba963277fd80c3e7c93afb19a34e4f4677e`.
- Candidates: 1.

### sky-meteors_c1

- Generator output `exec-3101431e-80a3-43b9-8aed-1f8c5556f71f.png`, sha256 `2e1c86716674a4d6131b5f87c40ecba963277fd80c3e7c93afb19a34e4f4677e`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_sky-meteors.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, kept: 1:1 clean; meteors share a radiant, people on blankets seen from behind, town and dish at right.

### Prompt sky-meteors (full prompt = style block, a blank line, then this scene paragraph; verbatim)

> Scene, a meteor shower: a clear moonless summer night on the hills above the town, many thin bright meteor streaks across the dense starry sky and the Milky Way. Townspeople lie on blankets in a meadow looking up, a couple pointing, a teenager with arms behind the head, seen from behind and low. The town's warm lights and the bay below. Peaceful, open, making wishes.

## sky-comet_v0.webp (sky; tiers 2-8; "a comet over the bay")

- Kept: candidate c1. Shipped `pictures/sky-comet_v0.webp` (1024 x 683, cwebp q85), sha256 `2bbe59836daf7bf5b3ac04a8cbde5741e3e7574def502a056929dc74f4b43199`; master `sky-comet_v0.png` (1536 x 1024 RGB, byte-for-byte copy of the generator output), sha256 `e14cf516c8925ac9c336580bdd239ee8066a58580fac02c669252e99f9224e75`.
- Candidates: 1.

### sky-comet_c1

- Generator output `exec-71e7289a-9fed-4a7c-a96f-713760ac808b.png`, sha256 `e14cf516c8925ac9c336580bdd239ee8066a58580fac02c669252e99f9224e75`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_sky-comet.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, kept: 1:1 clean; the tail points up and away from the set sun, people on the beach and harbour wall seen from behind, dish and town at left.

### Prompt sky-comet (full prompt = style block, a blank line, then this scene paragraph; verbatim)

> Scene, a comet over the bay: a great comet hangs over the sea after dusk, a bright head and a long curved pale tail sweeping up across the deep blue sky, reflected faintly on the water. On the beach and the harbour wall people have gathered to look, small figures seen from behind, an old man with a child on the sand. The terracotta town and the white dish on the headland at the edge of the view. Awe, once in a lifetime.

## sky-full-moon_v0.webp (sky; tiers 0-8; "the full moon over town")

- Kept: candidate c1. Shipped `pictures/sky-full-moon_v0.webp` (1024 x 683, cwebp q85), sha256 `6b215e8aece2705a64396188c9df1ce6e1570148cbe9fae36e49540cb77988e1`; master `sky-full-moon_v0.png` (1536 x 1024 RGB, byte-for-byte copy of the generator output), sha256 `20e8e117cd930cf3294fd9071ad7b6a18979477a2fdbb36ad8bd9b66c68413da`.
- Candidates: 1.

### sky-full-moon_c1

- Generator output `exec-3ecd293c-65c4-4a15-a6f3-21fcf014f8c3.png`, sha256 `20e8e117cd930cf3294fd9071ad7b6a18979477a2fdbb36ad8bd9b66c68413da`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_sky-full-moon.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, kept: 1:1 clean; golden moon over the sea beside the headland and dish, couple from behind on a wall, the town's lit windows.

### Prompt sky-full-moon (full prompt = style block, a blank line, then this scene paragraph; verbatim)

> Scene, the full moon over town: a huge golden full moon rising over the sea behind the headland and its white dish, laying a glittering path across the bay, the terracotta roofs of the town silvered, a few windows lit. In the foreground a couple sits on a low garden wall seen from behind, sharing a quiet moment. Warm, calm, romantic without kitsch.

## sky-milky-way_v0.webp (sky; tiers 0-8; "the Milky Way from the hills")

- Kept: candidate c1. Shipped `pictures/sky-milky-way_v0.webp` (1024 x 683, cwebp q85), sha256 `006611453929695d44d5096cfd399adcea1fb62f47f76f0e0a689ffbf9d4f12f`; master `sky-milky-way_v0.png` (1536 x 1024 RGB, byte-for-byte copy of the generator output), sha256 `192090ff915738abeac141efade6e499b3f283720702675febb10aed31208735`.
- Candidates: 1.

### sky-milky-way_c1

- Generator output `exec-696906dd-c38e-4eee-ae16-498840dc57d3.png`, sha256 `192090ff915738abeac141efade6e499b3f283720702675febb10aed31208735`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_sky-milky-way.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, kept: 1:1 clean; one figure from behind by a shepherd's hut, the arch of the Milky Way, the town's glow and the small dish at right.

### Prompt sky-milky-way (full prompt = style block, a blank line, then this scene paragraph; verbatim)

> Scene, the Milky Way from the hills: far inland on a dark hilltop above the coast, the full arch of the Milky Way spanning the sky, dense with stars and dust lanes, a few dark cypress silhouettes and a stone shepherd's hut. A single small figure stands on the ridge looking up, seen from behind, a faint glow of the distant town at the horizon. Vast, solitary, peaceful.

## sky-station_v0.webp (sky; tiers 3-8; "a station crossing the sky")

- Kept: candidate c3. Shipped `pictures/sky-station_v0.webp` (1024 x 683, cwebp q85), sha256 `c837df2541df44fa9c8f73c173a14b195f70b3c4b5ee33e6762a509b2ef8d5e6`; master `sky-station_v0.png` (1536 x 1024 RGB, byte-for-byte copy of the generator output), sha256 `9d6e36dfd9f6f5657ea952f222addffaec9715279fb8b0f931be7b7b9c38ae18`.
- Candidates: 3.

### sky-station_c1

- Generator output `exec-968885d8-f1d9-40f7-bb14-166acadb7524.png`, sha256 `bd49d61b19452260c28189db8d2327ee6da09cb09f078b478c7bba72ddd87d1b`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_sky-station.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, rejected: 1:1 clean, but the station is a single star-like point that reads as an evening planet; nothing says it moves. Retried with a short bright streak along its path.

### sky-station_c2

- Generator output `exec-febe051f-57c5-4c27-8721-3fce19acdb17.png`, sha256 `c9661fa89a237306c1d4a7eeb88a04297b2e5aae0e65e303443ac017cab41ef7`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_sky-station_r1.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, rejected: Full frame and 1:1 clean, and the people from behind with a child pointing are right, but the point with a symmetric streak reads as a meteor, so the picture would duplicate sky-meteors. Retried once more with a tiny visible station shape.

### sky-station_c3

- Generator output `exec-d43bc3dd-f497-404b-bb6d-7128340d5417.png`, sha256 `9d6e36dfd9f6f5657ea952f222addffaec9715279fb8b0f931be7b7b9c38ae18`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_sky-station_r2.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, kept: Full frame and 1:1 clean: a small unmarked ring-and-panel station glinting high above the bay at y~180 (inside the 16:9 band) with a dotted path line, unmistakably a station and not a meteor; a family on the terrace and townspeople in the lane from behind, a child pointing; the dish on the headland. Drawn larger than a real station would look, accepted as illustration.

### Prompt sky-station (full prompt = style block, a blank line, then this scene paragraph; verbatim)

> Scene, a station crossing the sky: a clear evening sky over the town just after sunset, deep blue fading to coral at the horizon, and high above a bright steady point of light gliding across, a generic orbital station too far away to show any detail, leaving no trail. On a rooftop terrace and in the lane below, a few townspeople stop and look up, a child pointing. The first stars appearing. Ordinary wonder.

### Prompt sky-station_r1 (retry scene paragraph, verbatim)

> Scene, a station crossing the sky: a clear evening sky over the town just after sunset, deep blue fading to coral at the horizon, and high above the bay, in the middle of the sky, a generic orbital station too far away to show any detail glides across as a brilliant point of light, drawn with a short soft bright streak along its path to show that it is moving, much brighter than the first stars around it. On a rooftop terrace and in the lane below, a few townspeople stop and look up at it, a child pointing, seen from behind. Ordinary wonder.

### Prompt sky-station_r2 (retry scene paragraph, verbatim)

> Scene, a station crossing the sky: a clear evening sky over the town just after sunset, deep blue fading to coral at the horizon. High above the bay, in the middle of the sky, a generic orbital station catches the last sunlight: small and far away, but just big enough to see as a tiny glinting shape of a ring and long solar panels, with no markings, followed by a faint dotted line of its path across the sky. It is not a meteor and not a spacecraft of any voyage. On a rooftop terrace and in the lane below, a few townspeople stop and look up at it, a child pointing, seen from behind. The first stars appearing. Ordinary wonder.

## sky-sunset_v0.webp (sky; tiers 0-8; "sunset over the sea")

- Kept: candidate c1. Shipped `pictures/sky-sunset_v0.webp` (1024 x 683, cwebp q85), sha256 `0be1b1462d0e23036b58e73e38a188b421196409e6de1a6931eb67eb92ca0888`; master `sky-sunset_v0.png` (1536 x 1024 RGB, byte-for-byte copy of the generator output), sha256 `bfb738bdae504dddd7ef118f2cd98464b0559c6e3302c6b9bcb14147707feb8a`.
- Candidates: 1.

### sky-sunset_c1

- Generator output `exec-e1794542-bc0e-4f76-a542-c99dad8d66a5.png`, sha256 `bfb738bdae504dddd7ef118f2cd98464b0559c6e3302c6b9bcb14147707feb8a`; reference image passed (inputImages: style_ref.png, sha256 93a02944...0017).
- Prompt: `full_sky-sunset.txt` (submitted prompt equals the file byte for byte, checked against the session rollout).
- Decision, kept: Full frame and four 1:1 quadrants clean; boats, town and dish unmarked; gold sunset, people and dog seen from behind; dish just inside the 16:9 band.

### Prompt sky-sunset (full prompt = style block, a blank line, then this scene paragraph; verbatim)

> Scene, sunset over the sea: the sun sinking into the open sea beyond the bay, the sky in bands of coral, ochre and violet, long gold light across the water, fishing boats returning. On the rocks below the town a few people sit watching, small figures seen from behind, a dog at the water's edge, the white dish on the headland catching the last light. Calm, the end of an ordinary day.

