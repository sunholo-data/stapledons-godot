# R2-HOME-TIERS: sixteen home-time tiers for the crossing review's Home page

**Status:** Planned 2026-10-19 (design and sprint plan; **awaiting Mark's approval**, no implementation).
**Release:** R2 (voyage life). A follow-up to R2-INTERLUDE ([interlude-card.md](../../implemented/r2/interlude-card.md), Rulings §2 and §7).
**Priority:** P1 for R2. Mark found it in playtest: the guided tour ends at about 150 Earth years, which today shows tier 5, the drowned town, a picture that reads as a millennium on.
**Origin:** Mark, attended 2026-10-19: "these pictures are great, lets get more of them so we can split the tiers up more" and "we can have even more actually". The 16-tier ladder below was agreed in that session. The nine new pictures are being generated now and wait for Mark's pick.

**Implements** (design repo):
- [voyage-life-loop.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/next/voyage-life-loop.md): the report "What happened aboard" and the cost at home that it shows.
- [journey-system.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/phase3-gameplay/journey-system.md): "WHAT HAPPENED ABOARD" and the Destination Reveal mock.
- [archive-voice.md](https://github.com/sunholo-data/stapledons-design/blob/main/features/next/archive-voice.md): the Archive's authored framing line on the crossing page.
- [roadmap/r2-voyage-life.md](https://github.com/sunholo-data/stapledons-design/blob/main/roadmap/r2-voyage-life.md), rows E4 and G2 (the skip report).
- [vision/core-pillars.md](https://github.com/sunholo-data/stapledons-design/blob/main/vision/core-pillars.md), pillar 3 ("Civilizations age, change, forget you, or die while you travel").
- Ledger (`design_docs/stapledon-mission.md`): D-7 (generate and cache), D-18 (large assets out of git), D-21 (no digits in generated text; numbers only from sim fields), D-67 (in-world voice), D-68 (never hint at what the ship does not know).
- No physics-spec section. Nothing new shows SR or GR. The Earth years come from the existing `cruise.digest.time.earth_year_total`.

**Depends on:**
- R2-INTERLUDE (implemented, PR #264): `sim/cruise_digest.ail`, `sim/protocol_interlude.ail`, `ui/crossing_review.gd`, `data/interlude/home/`.
- R2-CREW-CONSOLE-V2 (implemented, PR #267): protocol 2.11, whose gate this copies.
- Mark's picks of the nine new pictures (N a to N i). Only H3 (assets) waits on them.
- Protocol minor 12 is free on origin/main today. The open plan PR #272 (R2-SIMILAR-S0) also plans 2.12. See OQ3.

**Estimated LOC:** about 640 (the sum of the milestone table), plus nine binary pictures (about 5 MB).

## Game vision alignment

Scored with the `game-vision-designer` skill (feature-validation mode, against `vision/core-pillars.md`), 2026-10-19. **ALIGNED.**

| Pillar | Score | Rationale |
|---|---|---|
| Choices Are Final | +1 | The cost of a route is shown at a finer grain. 150 years and 900 years no longer get the same picture, so the player sees what their choice of route really spent at home. Nothing can be undone |
| The Game Doesn't Judge | +1 | Pictures and lines report time, not a verdict. The lines stay inferable from the elapsed years ("may not exist", "has had time to") and never grade the crossing. Risk: deep-time scenes (sea wall, ice) could read as story. The lines stay conditional, and OQ4 covers the website |
| Time Has Emotional Weight | +2 | This is the core of it. Today one picture covers 130 to 1,000 years. After this change the child at the rail grows up, the dish becomes a memorial, and then the sea comes in. Each step is one the player can feel |
| The Ship Is Home | 0 | Not touched. The crew pages are unchanged |
| Grounded Strangeness | +1 | The deep-time steps follow real timescales: language drift over centuries, recorded history at about five thousand years, ice-age cycles of about a hundred thousand years, geological change beyond that |
| We Are Not Built For This | +1 | "The genuine horror of deep time" becomes visible up to geological time, instead of stopping at "beyond" from a thousand years on |
| **Net** | **+6** | **Go.** No pillar is negative. Pillar 4 is neutral by design |

## Problem

| # | Evidence (today) | Consequence |
|---|---|---|
| P1 | `sim/cruise_digest.ail:110` `homeTier`: 7 tiers, <1, 1–10, 10–30, 30–80, 80–130, 130–1000, ≥1000 | One picture covers 870 years (tier 5) and one covers everything past a thousand (tier 6) |
| P2 | Mark's playtest (2026-10-19): the guided tour ends at about 150 Earth years and shows tier 5, the drowned town | The picture claims about a millennium of change for a century and a half |
| P3 | Tier 6's line is "Longer than recorded history before you left", from 1,000 years on | Recorded history is about five thousand years old, so the claim is false from 1,000 to about 5,000 years. The eval R2-INTERLUDE (2) rule says "each line must be true for every crossing its key covers" |
| P4 | Tier 5's line is "No one alive on Earth was born when you left. The countries you knew may not exist." from 130 to 1,000 years | At 900 years this is an understatement. Ruling 7 moved the first claim here because it only holds beyond about 120 years |
| P5 | `ui/crossing_review.gd` loads `tier<n>.webp` straight from `time.tier`, and recorded 2.10 and 2.11 streams carry the 7-tier numbers | Renumbering the files without a mapping would show the wrong picture for every older stream |

## Goals and non-goals

**Goals**
- G1. A 16-tier ladder in the sim (`time.tier` 0–15) at protocol **2.12**, with 16 tier lines, 16 distinct digit-free tier words and 16 Archive crossing lines.
- G2. Streams below 2.12 are byte-identical: 2.10 and 2.11 keep the 7-tier mapping, its lines, its words and its narration keys.
- G3. Sixteen pictures `tier0.webp`…`tier15.webp`, renumbered, with provenance rows and masters in the public bucket (D-18).
- G4. Older streams still show the right picture through a fixed 7→16 picture map.
- G5. The website's concept-art page grows to 16.

**Non-goals**
- No new page, layout or scrim. The Home page's layout is unchanged.
- No change to the counts bands or the aboard lines.
- No change to `home.news.tier`, which is the news template's own tier, not the home tier.
- No physics change.

## Design

### H1. The ladder in the sim (protocol 2.12)

**New module `sim/home_tiers.ail`** (pure, strict VM, no imports from `cruise_digest`, so there is no cycle). It holds the 16-tier tables. `sim/cruise_digest.ail` imports it.

```
export pure func tierCount() -> int = 16
export pure func homeTier16(years: float) -> int        -- edges 1, 3, 10, 20, 35, 55, 90, 130, 250, 500, 1000, 3000, 10000, 50000, 250000
export pure func tierLine16(tier: int, whole: int) -> string
export pure func tierWord16(tier: int) -> string
export pure func crossingLine16(tier: int) -> string
export pure func pictureOfSeven(tier: int) -> int       -- the 7-tier picture's new file index: [0, 2, 4, 6, 8, 10, 13]
```

`homeTier16` uses half-open ranges with the lower edge inclusive, as `homeTier` does. A negative or NaN-free input below 1 gives tier 0. Each body is one `if … else if` chain like today's (no list-literal splits are needed since v0.54.13).

**`sim/cruise_digest.ail`** keeps `homeTier`, `tierLine`, `tierWord`, `crossingLine`, `narrationFor`, `narrationOf` and `narrationKey` exactly as they are: the 7-tier ladder. It adds a switch that picks a ladder:

```
export pure func homeTierAt(sixteen: bool, years: float) -> int
export pure func tierLineAt(sixteen: bool, tier: int, whole: int) -> string
export pure func narrationForAt(sixteen: bool, tier: int, band: string) -> Narration   -- key tierWord16 "." band at 16
export pure func narrationOfAt(sixteen: bool, d: Digest) -> Narration
```

**The gate copies 2.11.** Protocol 2.11 (R2-CREW-CONSOLE-V2) added `consoleMinor()` to `sim/protocol.ail`. It extended `helloFor` and `sessionMinor`, and it threaded one bool (`console = s.minor >= consoleMinor()`) into `encodeCruiseSectionAt(stop, d, console)` → `digestJsonAt(d, console)`. That bool adds the `stand_downs_*` counts. The new gate does the same:

- `sim/protocol.ail`: `export pure func homeTiersMinor() -> int = 12`, with a comment block in the same form as 2.10 and 2.11. It joins the `helloFor` chain (relativity `relativityPin()`) and `sessionMinor`. `withCruise` and `cruiseFull` pass `s.minor >= homeTiersMinor()` as a second bool.
- `sim/protocol_interlude.ail`: `encodeCruiseSectionAt(stop, d, console, sixteen)` and `digestJsonAt(d, console, sixteen)`. `timeJson`, `homeJson` and `narrationJson` use `homeTierAt(sixteen, …)`, `tierLineAt` and `narrationOfAt`. At 2.12, `time` gains **`tier_count: 16`**. The host uses it to tell a 16-tier stream from an older one without knowing the session minor (fixtures and replays carry only the frames). Below 2.12 no field is added.
- `encodeDigest(d)`, used by `sim/crew_script.ail` for `tests/crew/crossing_hold.ndjson`, stays the 2.10 encoding. That recording therefore stays byte-identical, and a 2.12 sibling is not needed: the 16 ladder is covered by H1's own tests.
- The protocol header comment in `protocol_interlude.ail` documents `tier (0-6; 0-15 from 2.12)` and `tier_count`.

**Determinism.** The ladder is a pure function of `sinceDeparture`. It has no state and no float subtraction near an edge. A new `make home-tiers-vm` target runs the entry `homeTiersTable` (in `sim/home_tiers_test.ail`) on the strict VM and on the interpreter. The entry prints one row per tier at its lower edge, at the largest float below its upper edge, and at its midpoint: tier, word and line. The two outputs must be byte-identical. The target joins `make test`.

### H1 text: the 16 lines

Rules (all checked by `make sim`):
- D-21: no digits. Whole years appear only as `%s`, bound to `time.years_at_home`.
- D-67: in-world voice (the `outOfWorld` word list in `cruise_digest_test.ail`).
- D-68: never claim what the ship cannot know. Every claim is either inferable from elapsed time ("is gone", "is growing up") or conditional ("may not exist", "has had time to").
- Eval R2-INTERLUDE (2): each line is true for **every** year in its range.
- Crossing lines stay ≤ 280 characters (`narrationMax`) and never contain the banned phrases ("while we crossed", "in weeks", "we crossed in", "centuries turned", "than my oldest records").
- The website spoiler policy (`website/news/README.md`): none of these lines go on the site. The site shows the pictures under time-range titles only (H4).

Legend: **K** keeps the existing line word for word; **A** adapts an existing line; **N** is new; ⚑ marks a line whose year range changes meaning.

#### Tier lines (Home page; `%s` = whole Earth years since departure)

| # | Earth years | Picture | Line | Origin |
|---|---|---|---|---|
| 0 | < 1 | E tier0 | "Less than a year at home. They are still watching for word from you." | K (old 0) |
| 1 | 1–3 | N a | "%s years at home. The people who saw you off still look up some evenings." (whole = 1: "A year at home. The people who saw you off still look up some evenings.") | N; takes over the singular case from old tier 1 |
| 2 | 3–10 | E tier1 | "%s years at home. The news you left with is history." | K (old 1). The range narrows from 1–10 to 3–10 and the line stays true. The "A year" case can no longer occur here and is dropped |
| 3 | 10–20 | N b | "%s years. The children who waved you off are growing up; they know your leaving mostly from what they were told." | N |
| 4 | 20–35 | E tier2 | "%s years. The children you knew have grown up; your name is a story they half remember." | K (old 2). Range 10–30 becomes 20–35, which fits better: at 10 the children had not grown up |
| 5 | 35–55 | N c | "%s years. Your parents' generation is passing; the friends you left are growing old." | A (old 3). ⚑ Old 3 said "is gone … are old" from 30 years on, which is too strong at 30–50. It is softened here |
| 6 | 55–90 | E tier3 | "%s years. Your parents' generation is gone. The friends you left are very old now, or gone." | A (old 3). ⚑ Old 3's "the friends you left are old" stops being true towards 90, so "or gone" is added |
| 7 | 90–130 | N d | "%s years. Everyone you knew is gone, or nearly. Strangers live in the houses you knew." | A (old 4). ⚑ "Everyone you knew is gone" held from 80 years, and at 90 it is still not quite true (someone who was a small child at launch can live past a hundred), so "or nearly" is added. The unqualified line moves to tier 8 with its picture |
| 8 | 130–250 | E tier4 | "%s years. Everyone you knew is gone. No one alive on Earth was born when you left." | A (old 4 + old 5's first sentence). Both claims hold everywhere from 130 on (ruling 7: beyond about 120) |
| 9 | 250–500 | N e | "%s years. The countries you knew may not exist. Your way of speaking would sound old to anyone at home." | A (old 5's second sentence + N) |
| 10 | 500–1000 | E tier5 | "%s years. Longer than most nations last. If anyone still speaks your language, they would struggle to understand you." | N. ⚑ The old tier-5 line (130–1000) understates 500–1000 years, so this picture gets new words |
| 11 | 1000–3000 | N f | "%s years. Languages, faiths and borders have had time to rise and be forgotten. Anyone who reads your signal will need old records to do it." | N |
| 12 | 3000–10000 | N g | "%s years. Time enough for whole civilisations to rise and fall. You cannot know who still keeps a record of your leaving." | N |
| 13 | 10000–50000 | E tier6 | "%s years. Longer than recorded history before you left. Whatever answers your signal will not be the Earth you left." | K (old 6). ⚑ Fixes P3: the claim was false from 1,000 to about 5,000 years and is true from 10,000 on |
| 14 | 50000–250000 | N h | "%s years. Long enough for ice to advance and retreat across continents. Whoever lives at home now has had time to become someone you would not recognise." | N |
| 15 | ≥ 250000 | N i | "%s years. Time on the scale of geology: seas and coasts have moved. There may be no one left who could read your signal as yours." | N |

#### Tier words (narration key `tierWord16 "." band`; distinct, digit-free, time words only)

The words name a span of time, never a scene: the Archive's live telling gets the key as context, and a scene word such as "ice" would hint at what the ship cannot know (D-68). The geological order is era > period > epoch, and aeon is the longest unit, so 13 to 15 use epochs, eras and aeons.

| # | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
|---|---|---|---|---|---|---|---|---|
| word | launch | seasons | years | decade | decades | generation | lifetime | lifetimes |
| # | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 |
| word | century | centuries | millennium | millennia | ages | epochs | eras | aeons |

Six of the seven old words survive (launch, years, decades, generation, lifetimes, centuries, ages), but at 2.12 several of them name different ranges. That is allowed because the keys are gated. At 2.12 the scripted crossing (seven years) is tier 2, so its key is still `years.held`, and `ai/prompt_test.ail`'s `years.held` context needs no change.

#### Archive crossing lines (crossing page; same for every band)

| # | Line | Origin |
|---|---|---|
| 0 | "We crossed quickly, Captain. Home has barely turned since we left; the people there are still looking up." | K (old 0) |
| 1 | "Home has turned through a few seasons since we left, Captain. The people who saw us off still look up, though less often now." | N |
| 2 | "Our clock runs slow out here. At home the seasons have kept turning without us, and the news we carry has become history." | K (old 1) |
| 3 | "The children who watched us leave are growing up, Captain. To them our leaving is a story; to me it is a record, kept as it was." | N |
| 4 | "Since we left, the children at home have grown up. My records of them stop where we left; theirs of us grow thinner." | K (old 2) |
| 5 | "Half a lifetime has passed at home since we left. The parents who saw us off are passing now; the friends we left are growing old." | N |
| 6 | "A lifetime has passed at home since we left, and far less for us. The voices I hold from that world are mostly the voices of the dead." | K (old 3). Range 30–80 becomes 55–90, a better fit for "a lifetime" |
| 7 | "Almost no one who watched us leave is still alive, Captain. Strangers keep the places we knew, if anyone keeps them." | N |
| 8 | "Everyone who watched us leave is gone, Captain. My records of them are not. I keep them carefully." | K (old 4). ⚑ It held from 80 years (not strictly true there) and now starts at 130, where it is |
| 9 | "More than two centuries have passed at home since we left. The nations in my entries may be names in someone else's histories now." | A (old 5: "More than a century has turned"). ⚑ Narrowed to 250–500, so it says two centuries |
| 10 | "Many centuries have passed at home since we left. If anyone there still speaks as we do, they learned it from old books." | N |
| 11 | "More than a thousand years have passed at home since we left. What answers our signal, I cannot predict from anything I hold." | K (old 6). ⚑ The line stays at 1,000–3,000, where it is exact. Its picture (E tier6) moves to 13 |
| 12 | "Thousands of years have passed at home since we left, Captain. Whole histories have been written there that I will never read." | N |
| 13 | "More time has passed at home than all the history in my keeping. I cannot say who, or what, keeps the Earth now." | N |
| 14 | "Tens of thousands of years have passed at home, Captain. The climate there has had time to turn over; I hold no map of the world it made." | N |
| 15 | "Time at home is now measured as geologists measure it. Whatever we return to, Captain, I can only describe it from the rocks up." | N |

The text is a draft for Mark's ruling (OQ1). The sprint writes these strings verbatim into the H1 tests (red first) once he approves.

### H2. The host

- `bridge/sim_bridge.gd`: `const HOME_TIERS_MINOR := 12`, with a doc comment in the form used for the other minors. The game's sessions ask for it in place of `CONSOLE_MINOR`: `main.gd:286`, `demos/ship_geometry_demo.gd:772`, and the prefetch `ui/loading_jump.gd:254` (`SimBridge.warm`), which must match the session minor or the prefetch is not adopted. Test-only and fixture tools that pin 2.10 or 2.11 stay pinned.
- `ui/crossing_review.gd`:
  - `const TIER_COUNT := 16` and `const PICTURE_OF_SEVEN := [0, 2, 4, 6, 8, 10, 13]`, which mirrors `home_tiers.ail pictureOfSeven`. A test compares the two.
  - `static func picture_index(time: Dictionary) -> int` returns `tier` when `time.tier_count == 16` and `PICTURE_OF_SEVEN[tier]` when the field is absent. Out-of-range values clamp, and a missing tier gives 0.
  - `_home` uses `home_path(home_dir, picture_index(...))`.
  - The words-only fallback (`_home_missing`) is unchanged.
- `tools/crossing_review_capture.gd`: `art_tier<n>` loops over 16 (`for tier in CrossingReview.TIER_COUNT`), with `tier_count: 16` set on the view.
- `tools/crossing_review_fixture.gd`: records at `HOME_TIERS_MINOR`.

### H3. The pictures

**Renumbering (E pictures).** The files are moved with `git mv`, from the top down so nothing is overwritten: 6→13, 5→10, 4→8, 3→6, 2→4, 1→2 (0 stays). Their WebP bytes and sha256 are unchanged, and `make crossing-review-test` checks that (AC9).

**New pictures (N a … N i → tiers 1, 3, 5, 7, 9, 11, 12, 14, 15).** Mark picks one candidate per slot (OQ2). Then, for each pick:
1. Check the master: 1536×1024 RGB PNG, with the left third calm and no text-like marks at 1:1, as in `generation_notes.md`.
2. Upload it to the public bucket under its sha256 (standing approval, D-18):
   `sha=$(shasum -a 256 tierN.png | cut -d' ' -f1); gcloud storage cp tierN.png gs://stapledons-voyage-assets/site/$sha.png`
3. Convert it with the same command and encoder as `SOURCES` (libwebp 1.6.0):
   `cwebp -q 88 -m 6 -sharp_yuv -metadata none tierN.png -o data/interlude/home/tierN.webp`
4. Compare it with the master at 1:1, skies included, and record that there is no visible banding.

**Provenance.**
- `data/interlude/home/SOURCES`: the header is updated (16 tiers, 2026-10-19 generation, the approximate total size). There are 16 rows of the form `tier<n>.webp sha256 <webp> <- master sha256 <png> <url>`. The 7 E rows keep their shas under their new names.
- `generation_notes.md`: the 7 existing sections are renamed to their new tier numbers, each marked "(was tierK)". Nine new sections cover the driver, generator, reference image, prompts verbatim, candidates kept and rejected, and Mark's pick. These come from the generating session's notes and use the same fields as today.

**Size.** Today the seven WebPs take about 3.8 MB. Nine more at about 0.55 MB each add about 5 MB, for **about 8.8 MB** in all. The export ships them through the existing `data/interlude/*` include filter, and `make export-filter-audit` stays green.

### H4. The website

- `website/static/img/concept/home-tier<n>.jpg`: the 7 existing thumbnails are renumbered by the same map. Nine new 800×533 JPG thumbnails are made by a headless Godot script (`tools/concept_thumbs.gd`: Lanczos down from the master, `Image.save_jpg` at quality 0.85, under 1 MB each). Image I/O is Godot (CLAUDE.md §Python).
- `website/src/data/concept.js`: `HOME_FULL` gets 16 master sha256 values, and `HOME` gets 16 titles. The titles are time ranges only, with no scene words (spoiler policy): "Less than a year", "A year or two", "Under ten years", "Under twenty years", "Under thirty-five years", "Under fifty-five years", "Under ninety years", "Under 130 years", "Under 250 years", "Under 500 years", "Under a thousand years", "Under 3,000 years", "Under 10,000 years", "Under 50,000 years", "Under 250,000 years", "Deep time". Digits are allowed here: D-21 covers generated in-game text, and the site's existing titles already use them.
- The comment above `HOME_FULL` is updated: 16 pictures, generated on 16 and 19 October.
- Whether all 16 go on the site is OQ4.

### H5. Verify and land

Captures: `make crossing-review-capture` writes `art_tier0..15` and the guided crossings, and **every frame is opened and looked at**. Then `make display-audit-interlude`, a green local `make test`, a changelog fragment and the CHANGELOG protocol line for 2.12, an evaluation by a different agent, and the landing steps in CLAUDE.md.

## Acceptance criteria

Each row is checked by its command. "Pinned" means `PATH=$PWD/runtime/bin:$PATH`.

| AC | Criterion | Command |
|---|---|---|
| AC1 | `homeTier16` puts every edge in the right tier: for each of the 15 edges e, `homeTier16(e) == k` and `homeTier16(e - d) == k-1`, with d = 1e-6 below 1,000 years and 1e-3 above (the existing test's style, scaled so that float spacing at 250,000 cannot round back onto the edge); also 0.0 → 0, a negative value → 0, 1e9 → 15 | `make sim` (`sim/home_tiers_test.ail`) |
| AC2 | The 16 tier lines, words and crossing lines equal the approved text word for word. No digits anywhere (`noDigit` on `tierLine16(t, 1)` and `(t, 2)`). Each has exactly one `%s` except tier 0 and tier 1's singular. The 16 words are distinct. The 16 crossing lines are distinct, in-world, ≤ 280 characters and free of the banned phrases. Every key `tierWord16(t).band` (80 of them) is distinct and digit-free | `make sim` |
| AC3 | Each line is true for its whole range: a table test pins each tier's line at its lower edge, midpoint and top, so the same line is shown across the range; the text review is OQ1 | `make sim` |
| AC4 | VM == interpreter: `homeTiersTable` (all 16 tiers at three points each) is byte-identical on the strict VM and the interpreter, and runs under `--strict-bytecode` | `make home-tiers-vm` (in `make test`) |
| AC5 | The gate: a session at want 12 is answered minor 12. At 2.12 the digest's `time.tier` is 16-tier, `time.tier_count == 16`, and `narration.key` uses `tierWord16`. At 2.10 and 2.11 the digest is byte-identical to today's (the same scripted world encoded at 11 before and after), with no `tier_count` | `make sim` (`sim/protocol_interlude_test.ail`, `sim/protocol_test.ail`) |
| AC6 | Below 2.12 nothing moves: every replay golden and `tests/crew/*.ndjson` (`crossing_hold` included) is unchanged, and no golden is re-recorded | `make replay parity parity-v2 crew-parity` and `git diff --exit-code origin/main -- tests/replays tests/crew` |
| AC7 | The core stays pure: `home_tiers.ail` and the changed codecs pass the strict VM | `make strict` |
| AC8 | The host asks for 2.12: the bridge negotiates `HOME_TIERS_MINOR`; the game sessions and the loading-jump prefetch use the same minor | `make crew-bridge-test crossing-review-test` (a real-sim case asserts `hello_reply.proto.minor == 12`) |
| AC9 | Pictures: 16 files `tier0..15.webp`, each 1536×1024 WebP, with no PNG in the tree. The E pictures' sha256 equal their old SOURCES rows under the new names (old k → `PICTURE_OF_SEVEN[k]`). `SOURCES` has 16 rows whose webp sha matches the file | `make crossing-review-test` and `make home-art-check` (new: `shasum -a 256` of each file against its SOURCES row; 16 rows) |
| AC10 | Picture choice: a 16-tier frame shows `tier<tier>.webp`. A 7-tier frame (the kept 2.10 fixture, no `tier_count`) shows `tier<PICTURE_OF_SEVEN[tier]>.webp`. `PICTURE_OF_SEVEN` equals the sim's `pictureOfSeven` | `make crossing-review-test` |
| AC11 | The missing-picture fallback: with `home_dir` pointing at an empty directory, and separately with one tier file absent, the Home page shows the words alone across the page, the bound tier line, and nothing broken; `home_art_missing()` is true | `make crossing-review-test` |
| AC12 | The existing crossing-review tests pass on fixtures re-recorded at 2.12. The guided voyage's last crossing (about 150 Earth years, Mark's playtest) is tier 8 and shows `tier8.webp`, the collapsed dish, not the drowned town | `make crossing-review-fixtures` (reviewed diff), then `make crossing-review-test` |
| AC13 | Display audit: the guided crossing with crew, every review page sampled, every label a binding, no entry added to the known file | `make display-audit-interlude` |
| AC14 | Size: the 16 WebPs total ≤ 10 MB and the export still classifies every shipped `res://` literal | `du -ck data/interlude/home/*.webp \| tail -1` (≤ 10240) and `make export-filter-audit` |
| AC15 | Website: `HOME` has 16 entries, each with an existing thumbnail ≤ 1 MB and a master URL that answers 200. The site builds with no broken link | `make site` and `node -e "import('./website/src/data/concept.js').then(m=>process.exit(m.HOME.length===16?0:1))"` and `for u in $(node …HOME.map(h=>h.full)); do curl -sfI $u; done` |
| AC16 | Captures: `art_tier0..15` and the guided crossings are written, and each frame has been opened (the report lists them) | `make crossing-review-capture` (GPU window) |
| AC17 | Full suite: green locally on the pinned runtime and in CI | `PATH=$PWD/runtime/bin:$PATH make test` |

## Sub-milestones and estimates

| ID | What | LOC | Depends on | Waits on Mark |
|---|---|---|---|---|
| H1 | `sim/home_tiers.ail` + tests; `cruise_digest` switch; protocol 2.12 gate; `home-tiers-vm` | ~330 (≈150 sim, ≈180 tests) | n/a | OQ1 text (approval of this doc), OQ3 minor |
| H2 | Bridge minor; sessions; `picture_index` + legacy map; capture and fixture tools; fixtures re-recorded | ~170 | H1 | n/a |
| H3 | Renumber E; nine N pictures → bucket, WebP, SOURCES, notes; `home-art-check` | ~40 (+ binaries) | H2 (for AC9–AC11) | **OQ2 picks** |
| H4 | Website thumbnails (Godot), `concept.js` | ~70 | H3 | OQ4 |
| H5 | Captures opened, display audit, `make test`, changelog, eval, landing | ~30 | H1–H4 | review of the renders |
| | **Total** | **~640** | | |

Everything ships as one PR. If H3 is still waiting for picks, H1 and H2 sit on the branch: a merged 16-tier sim with nine missing pictures would show words only on half the ladder (OQ5).

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| Minor 12 is also planned by R2-SIMILAR-S0 (PR #272, parked on D-85) | Re-check `git grep -E 'Minor\(\) *= *1[2-9]' origin/main -- sim/` before H1 and before merge. The second branch to merge takes 13. Only `homeTiersMinor()`, the bridge constant and the fixture minor change (OQ3) |
| An older stream shows the wrong picture after the renumber | `tier_count` at 2.12; `PICTURE_OF_SEVEN` for anything without it; AC10 on a kept 2.10 fixture |
| A line overclaims somewhere in its range | Every line was checked against both ends of its range (⚑ rows). The AC3 table pins each line; Mark rules on the text (OQ1) |
| Deep-time pictures on the site read as story (spoiler policy) | Time-range titles only, no captions; OQ4 lets Mark hold back 11–15 |
| New pictures break continuity (town, dish, viewpoint) | The same shared style block and fixed viewpoint as `generation_notes.md`. Mark picks from candidates on a contact sheet |
| The shipped size grows by about 5 MB | It stays within the 10 MB budget (AC14). WebP q88 as today, compared at 1:1 |
| A file is clobbered during the renumber | Moves go top down; AC9 compares the E shas |

## Open questions for Mark

1. **OQ1, the text.** Approve the 16 tier lines, words and crossing lines above, or edit them. The ⚑ rows change meaning: tier 5 ("is passing", from old 3's "is gone"), tier 6 ("or gone" added), tier 7 ("Everyone you knew is gone, or nearly"; the unqualified line now starts at 130), tier 9 ("two centuries"), tier 10 (new words for the drowned town), tier 11 (the old ≥1000 Archive line stays at 1,000–3,000 while its picture moves to 13), and tier 13 (old 6's "Longer than recorded history" now starts at 10,000, where it is true).
2. **OQ2, the picks.** One candidate each for N a to N i. H3 starts when they arrive.
3. **OQ3, the minor.** R2-SIMILAR-S0 (PR #272) also plans 2.12. Recommendation: whichever merges first takes 12. Home tiers is the smaller change and can land first, which would move S0 to 2.13.
4. **OQ4, the website.** Should all 16 go on the concept-art page? The 7 already public include the drowned town. The new deep-time scenes (11–15: lagoon and orbital lights, ice, a new coast) show more of what happens to Earth. Recommendation: show all 16 under time-range titles, with no captions.
5. **OQ5, the landing order.** One PR after the picks (recommended), or land H1–H2 first with words only on the nine new tiers until the pictures arrive?

## Deliverables

- `sim/home_tiers.ail`, `sim/home_tiers_test.ail` (added to `[exports].modules` in `sim/ailang.toml`).
- Edits to `sim/cruise_digest.ail`, `sim/cruise_digest_test.ail`, `sim/protocol.ail`, `sim/protocol_test.ail`, `sim/protocol_interlude.ail` and `sim/protocol_interlude_test.ail`.
- `bridge/sim_bridge.gd`, `main.gd`, `demos/ship_geometry_demo.gd`, `ui/loading_jump.gd`, `ui/crossing_review.gd`.
- `tools/crossing_review_capture.gd`, `tools/crossing_review_fixture.gd`, `tools/concept_thumbs.gd`, `tests/test_crossing_review.gd`.
- `tests/fixtures/crossing_review/*.ndjson`, re-recorded at 2.12, plus `legacy_2_10_trappist.ndjson`, which is today's `trappist.ndjson` kept as it is.
- `data/interlude/home/tier0..15.webp`, `SOURCES` and `generation_notes.md`; the masters in `gs://stapledons-voyage-assets/site/`.
- `website/static/img/concept/home-tier0..15.jpg`, `website/src/data/concept.js`.
- Make targets `home-tiers-vm` and `home-art-check` (in `make test`).
- `CHANGELOG.md` (protocol 2.12), `changelogs/unreleased/2026-10-<dd>-home-tiers.md`, and the design repo's roadmap row.
- `design_docs/implemented/r2/home-tiers-report.md` at landing.
