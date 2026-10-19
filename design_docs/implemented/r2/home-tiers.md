# R2-HOME-TIERS: sixteen home-time tiers for the crossing review's Home page

**Status:** **IMPLEMENTED** 2026-10-19 (PR #277; independent evaluation 91/100 PASS, `.ailang/state/evaluations/eval_home_tiers_round_1.json`). **Approved** 2026-10-19 (Mark, attended), with one change: no single pick per tier. Every tier has a **pool of variants**, and each voyage picks one per tier from its seed (ledger **D-86**). Mark: "we can just have random choices from the varients we have. good replayability. I think we may generate even more variations but these are all good for now." See [Rulings](#rulings-mark-attended-2026-10-19).
**Release:** R2 (voyage life). A follow-up to R2-INTERLUDE ([interlude-card.md](../../implemented/r2/interlude-card.md), Rulings §2 and §7).
**Priority:** P1 for R2. Mark found it in playtest: the guided tour ends at about 150 Earth years, which today shows tier 5, the drowned town, a picture that reads as a millennium on.
**Origin:** Mark, attended 2026-10-19: "these pictures are great, lets get more of them so we can split the tiers up more" and "we can have even more actually". The 16-tier ladder below was agreed in that session. The nine new tiers were generated the same day with two candidates each; Mark ruled that every good candidate ships as a variant (D-86).

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
- The variant pool generated 2026-10-19 (home_art2: two candidates per new tier) and the earlier candidates of 2026-10-16 (D-86).
- Protocol minor 12 is free on origin/main today. The open plan PR #272 (R2-SIMILAR-S0) also plans 2.12. See OQ3.

**Estimated LOC:** about 720 (the sum of the milestone table), plus 21 new WebP variants (about 11 MB).

## Game vision alignment

Scored with the `game-vision-designer` skill (feature-validation mode, against `vision/core-pillars.md`), 2026-10-19. **ALIGNED.**

| Pillar | Score | Rationale |
|---|---|---|
| Choices Are Final | +1 | The cost of a route is shown at a finer grain. 150 years and 900 years no longer get the same picture, so the player sees what their choice of route really spent at home. Nothing can be undone |
| The Game Doesn't Judge | +1 | Pictures and lines report time, not a verdict. The lines stay inferable from the elapsed years ("may not exist", "has had time to") and never grade the crossing. Risk: deep-time scenes (sea wall, ice) could read as story. The lines stay conditional, and tiers 13–15 stay off the website |
| Time Has Emotional Weight | +2 | This is the core of it. Variants (D-86) make each voyage's home its own: two voyages to the same century can see different afternoons. Today one picture covers 130 to 1,000 years. After this change the child at the rail grows up, the dish becomes a memorial, and then the sea comes in. Each step is one the player can feel |
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
- G3. A pool of variants per tier, `tier<n>_v<k>.webp`, with provenance rows and masters in the public bucket (D-18). Variant 0 of each old tier is the picture shipped today.
- G4. Each voyage shows one variant per tier, picked from its seed: the same picture every time that tier comes up in that voyage (D-86). Older streams show variant 0 through a fixed 7→16 picture map.
- G5. The website's concept-art page shows every variant of tiers 0–12 only. Tiers 13–15 (10,000 years and later) show Earth's fate and stay off the site (spoiler policy; see the canon note in H4).

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
- The protocol header comment in `protocol_interlude.ail` documents `tier (0-6; 0-15 from 2.12)`, `tier_count` and `variant`.

**Variants (D-86).** Each tier has a pool of pictures, and each voyage picks one per tier:

- **Counts are data.** `sim/data/home_variants.ail` exports `variantCounts() -> [int]`, one row per tier. To add a variant later, raise that tier's count and add the file `tier<n>_v<k>.webp` with its `SOURCES` row. No other code changes. `make home-art-check` fails when the counts and the files disagree.
- **The pick is pure and stable.** `homeVariant(seed, tier) = top53(splitmix64(homeKey(seed), tier)) mod count(tier)`, where `homeKey(seed) = mix64(mix64(seed) ^ homeSalt())`.
  - This is the dust key's pattern (`ism.ail dustKey`) with its own salt. It **draws nothing from the world's `Rng`**, so no other stream moves.
  - One voyage seed and one tier always give the same variant, so a tier shows the same picture every time it comes up in that voyage.
  - It returns 0 when a tier has one variant or the tier is out of range.
  - It lives in `sim/home_tiers.ail`.
- **On the wire at 2.12 only.** `time.variant` (int) sits beside `tier` and `tier_count`. `digestJsonAt` takes the world's `seed`, and `withCruise` and `cruiseFull` pass it. Below 2.12 nothing is added, and the host shows variant 0.
- **Host fallback.** The host loads `tier<n>_v<variant>.webp`. If that file is missing it loads `tier<n>_v0.webp`. If both are missing the page shows words only (AC11).

**Determinism.**
- The ladder is a pure function of `sinceDeparture`, and the variant is a pure function of `(seed, tier)`. Neither has state.
- `make home-tiers-vm` runs the entry `homeTiersTable` (in `sim/home_tiers_test.ail`) on the strict VM and on the interpreter, and the two outputs must be byte-identical. The target is in `make test`.
- `homeTiersTable` prints, for each tier: the tier at its lower edge, just below its upper edge and at its midpoint, its word and its line; then `homeVariant` for 20 seeds.

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

Mark accepted this text as drafted on 2026-10-19 (Rulings, OQ1). The H1 tests pin these strings verbatim.

**Canon note: the doom and the late tiers.** In canon (stapledons-design `vision/premise-and-loop.md` §1–3), a rogue black hole wrecks Earth's orbit roughly 10,000 to 24,000 Earth years after the voyage begins; the exact figure is still open. Tiers 13–15 (10,000 years and later) therefore show Earth's fate. **This ladder is the "no threat modelled yet" baseline.** A follow-up design will make every tier at 10,000 years or later depend on that fate: Earth survived, or one of the doom outcomes. Mark is deciding how. Until then these tiers ship in the game as written here, and they stay off the website (H4).

### H2. The host

- `bridge/sim_bridge.gd`: `const HOME_TIERS_MINOR := 12`, with a doc comment in the form used for the other minors.
  - The game's sessions ask for it in place of `CONSOLE_MINOR`: `main.gd`, `demos/ship_geometry_demo.gd` and the `ui/loading_jump.gd` prefetch (`SimBridge.warm`). The prefetch must match the session minor or the session does not adopt it.
  - Tests and tools that pin 2.10 or 2.11 stay pinned.
- `ui/crossing_review.gd`:
  - `const TIER_COUNT := 16` and `const PICTURE_OF_SEVEN := [0, 2, 4, 6, 8, 10, 13]`. The second mirrors `home_tiers.ail pictureOfSeven`, and a test compares the two.
  - `static func picture_index(time: Dictionary) -> int` returns `tier` when `time.tier_count == 16` and `PICTURE_OF_SEVEN[tier]` when the field is absent. Out-of-range values clamp, and a missing tier gives 0.
  - `static func picture_variant(time: Dictionary) -> int` returns `time.variant` at 16 tiers and 0 otherwise.
  - `static func home_path(dir, tier, variant)` gives `tier<n>_v<k>.webp`. `home_texture_for(dir, tier, variant)` tries v`k` first, then v0, then gives null (words only).
  - The words-only fallback (`_home_missing`) is unchanged.
- `tools/crossing_review_capture.gd`: `art_tier<n>_v<k>` covers every shipped variant, with `tier_count: 16` set on the view.
- `tools/crossing_review_fixture.gd`: records at `HOME_TIERS_MINOR`.
- **The tour's end, measured.** The re-recorded `tour` fixture (seed 42, an orders crew under critical_only, Alpha Centauri, TRAPPIST-1, Aldebaran) ends its last crossing at **120.5 Earth years: tier 7** (90–130, the plain memorial). The old 2.10 recording ended at 115 years (old tier 4, the collapsed dish). Mark's playtest reported about 150 years and the drowned town (old tier 5, 130 years and up), so his voyage ran longer than this recording. Under the sixteen tiers, 120–150 years is tier 7 or 8, never the drowned town (tier 10, 500–1,000 years).

### H3. The pictures

**The pool (D-86).** 28 pictures across 16 tiers:

| Tier | Years | v0 | v1 | Count |
|---|---|---|---|---|
| 0 | < 1 | shipped tier0 | | 1 |
| 1 | 1–3 | new tier_a_c1 | new tier_a_c2 | 2 |
| 2 | 3–10 | shipped tier1 | | 1 |
| 3 | 10–20 | new tier_b_c1 | new tier_b_c2 | 2 |
| 4 | 20–35 | shipped tier2 | 2026-10-16 tier2_c1 | 2 |
| 5 | 35–55 | new tier_c_c1 | new tier_c_c2 | 2 |
| 6 | 55–90 | shipped tier3 | 2026-10-16 tier3_c2 | 2 |
| 7 | 90–130 | new tier_d_c1 | new tier_d_c2 | 2 |
| 8 | 130–250 | shipped tier4 | 2026-10-16 tier4_c1 | 2 |
| 9 | 250–500 | new tier_e_c1 | new tier_e_c2 | 2 |
| 10 | 500–1000 | shipped tier5 | | 1 |
| 11 | 1000–3000 | new tier_f_c1 | new tier_f_c2 | 2 |
| 12 | 3000–10000 | new tier_g2_c1 | new tier_g2_c2 | 2 |
| 13 | 10000–50000 | shipped tier6 | | 1 |
| 14 | 50000–250000 | new tier_h2_c1 | new tier_h2_c2 | 2 |
| 15 | ≥ 250000 | new tier_i_c1 | new tier_i_c2 | 2 |

Excluded, with the reasons recorded in `generation_notes.md`:
- tier0_c1: the family stands in the text column.
- tier1_c1 and tier1b_c1: text-like marks.
- tier1_c2: the wrong town.
- tier5_c1: kitsch.
- tier6_c1: two moons.
- tier_g_* and tier_h_*: they keep the dish; the g2 and h2 prompts add a no-dish sentence.

**Renumbering.** The shipped files move with `git mv` to `tier<new>_v0.webp`: 0→0, 1→2, 2→4, 3→6, 4→8, 5→10, 6→13. Their WebP bytes and sha256 do not change, and `make home-art-check` checks that (AC9).

**Each added variant** (21 of them) goes through these steps:
1. Inspect it at 1:1 in quadrants for text, letters or glyph-like marks, as `generation_notes.md` did. A variant that fails is dropped and listed.
2. Upload the master with `tools/site_media.sh asset` to `gs://stapledons-voyage-assets/site/<sha256>.png` (standing approval, D-18).
3. Convert it with the command in `SOURCES`: `cwebp -q 88 -m 6 -sharp_yuv -metadata none` (libwebp 1.6.0).
4. Compare the WebP with its master at 1:1.

**Provenance.**
- `SOURCES` has one row per file: `tier<n>_v<k>.webp sha256 <webp> <- master sha256 <png> <url>` (28 rows).
- `generation_notes.md` renames the existing sections to their new tier numbers ("was tierK"), marks the three 2026-10-16 candidates that now ship as variants, and adds the 2026-10-19 session. That covers the driver (`run.sh`), the style block and the scene paragraphs verbatim, each candidate's generator output file and sha256, and the 1:1 inspection result.

**Size.** The 7 shipped WebPs take about 3.8 MB. Adding 21 at about 0.55 MB each gives **about 15 MB** in all. They ship through the existing `data/interlude/*` export filter.

### H4. The website

- **Canon (above): tiers 13–15 stay off the site.** The concept-art page shows **every variant of tiers 0–12** (23 pictures). The tier-6 picture already public (old tier 6, now tier 13) **comes down**: its thumbnail and its `HOME` entry are removed. Its master stays in the bucket, because the game's `SOURCES` cites it.
- Thumbnails `website/static/img/concept/home-t<nn>-v<k>.jpg` (800 px wide, JPEG quality 0.85, under 1 MB each) are made by the headless Godot script `tools/concept_thumbs.gd`, because image I/O is Godot (CLAUDE.md §Python). The old `home-tier<n>.jpg` files are removed.
- `website/src/data/concept.js` `HOME`: one entry per variant, titled by time range only, with no captions (spoiler policy). The titles are "Less than a year", "A year or two", "Under ten years", "Under twenty years", "Under thirty-five years", "Under fifty-five years", "Under ninety years", "Under 130 years", "Under 250 years", "Under 500 years", "Under a thousand years", "Under 3,000 years" and "Under 10,000 years". A second variant takes the same title. The comment notes the canon cut-off.

### H5. Verify and land

- On the rig, per Mark's rule that merges ride on rig evidence: a green full `make test`. `make golden` only if anything visual in the 3D render changed (nothing does here).
- Crossing-review captures of the Home page at the guided tour's last crossing (recorded at 120.5 years: tier 7), plus one deep-tier fixture (tier ≥ 13), and every `art_tier<n>_v<k>`. **Open every frame and look at it.**
- A changelog fragment, the protocol 2.12 line in CHANGELOG, a PR (not a draft), and an independent evaluation by a different model before merge.

## Rulings (Mark, attended 2026-10-19)

| # | Question | Ruling |
|---|---|---|
| OQ1 | The 16 lines, words and crossing lines | Accepted as drafted |
| OQ2 | Picks for the nine new tiers | **No picks.** Every tier has a pool of variants, and each voyage picks one per tier from its seed. Mark: "we can just have random choices from the varients we have. good replayability. I think we may generate even more variations but these are all good for now." (ledger **D-86**) |
| OQ3 | Minor 12 against R2-SIMILAR-S0 (PR #272) | Whichever PR merges first takes 12 |
| OQ4 | The website | All variants, titled by time range, no captions. Amended the same day for canon: **tiers 0–12 only**; 13–15 stay off the site (see the canon note in H1) |
| OQ5 | Landing | One PR |

## Acceptance criteria

Each row is checked by its command. "Pinned" means `PATH=$PWD/runtime/bin:$PATH`.

| AC | Criterion | Command |
|---|---|---|
| AC1 | `homeTier16` puts every edge in the right tier. For each of the 15 edges e, `homeTier16(e) == k` and `homeTier16(e - d) == k-1`, where d = 1e-6 below 1,000 years and 1e-3 above. Also 0.0 → 0, a negative value → 0 and 1e9 → 15 | `make sim` (`sim/home_tiers_test.ail`) |
| AC2 | The 16 lines, words and crossing lines equal the approved text. No digits anywhere. One `%s` per line, except tier 0 and tier 1's singular. 16 distinct words; 16 distinct crossing lines, in-world, ≤ 280 characters, with no banned phrases; 80 distinct, digit-free keys | `make sim` |
| AC3 | Each line is pinned at its lower edge, its midpoint and just below its top | `make sim` |
| AC4 | VM == interpreter: `homeTiersTable` (ladder and variants) is byte-identical on the strict VM and the interpreter | `make home-tiers-vm` (in `make test`) |
| AC5 | The gate. Want 12 is answered 12. At 2.12, `time.tier` is 16-tier, `time.tier_count == 16`, `time.variant == homeVariant(seed, tier)`, and `narration.key` uses `tierWord16`. At 2.10 and 2.11 the digest is byte-identical to today's, with no `tier_count` and no `variant` | `make sim` (`sim/protocol_interlude_test.ail`, `sim/protocol_test.ail`) |
| AC6 | The variant pick. It is stable for one seed and tier (the same value on every call and from every digest of the voyage). It stays within `[0, count)`. It is 0 for single-variant tiers. Across 64 seeds every variant of every two-variant tier appears. Counts are 16 rows that match the files | `make sim` and `make home-art-check` |
| AC7 | Below 2.12 nothing moves. Every replay golden and every `tests/crew/*.ndjson` (`crossing_hold` included) is unchanged | `make replay parity parity-v2 crew-parity` and `git diff --exit-code origin/main -- tests/replays tests/crew` |
| AC8 | The core stays pure (strict VM) | `make strict` |
| AC9 | Pictures. 28 files `tier<n>_v<k>.webp`, each a 1536×1024 WebP, with no PNG in the tree. Each file's sha256 equals its `SOURCES` row. The 7 shipped shas are unchanged under their new names | `make home-art-check` (in `make test`) |
| AC10 | Picture choice. A 16-tier frame shows `tier<tier>_v<variant>.webp`. A 7-tier frame (the kept 2.10 fixture) shows `tier<PICTURE_OF_SEVEN[tier]>_v0.webp`. `PICTURE_OF_SEVEN` equals the sim's `pictureOfSeven` | `make crossing-review-test` |
| AC11 | Fallbacks. A missing variant falls back to v0, which is still shown. A missing tier, or an empty `home_dir`, gives the words alone across the page, with the bound tier line and `home_art_missing()` true | `make crossing-review-test` |
| AC12 | The crossing-review tests pass on fixtures re-recorded at 2.12. The guided voyage's last crossing is not the drowned town: recorded (seed 42, orders crew, critical_only) at 120.5 Earth years, tier 7 (see the H2 note) | `make crossing-review-fixtures` (reviewed diff), then `make crossing-review-test` |
| AC13 | Display audit: no entry is added to the known file | `make display-audit-interlude` |
| AC14 | Size and export. The WebPs total ≤ 20 MB, and the export audit stays green | `du -ck data/interlude/home/*.webp \| tail -1` (≤ 20480) and `make export-filter-audit` |
| AC15 | Website. `HOME` lists exactly the tier 0–12 variants (23) and no tier ≥ 13. Each thumbnail exists and is ≤ 1 MB. Each master URL answers 200. The site builds | `make site` and `make home-site-check` (new) |
| AC16 | Captures. The guided tour's last crossing (tier 7), a deep-tier fixture and every `art_tier<n>_v<k>` are written and opened (the report lists them) | `make crossing-review-capture` (GPU window) |
| AC17 | Full suite on the rig | `PATH=$PWD/runtime/bin:$PATH make test` |

## Sub-milestones and estimates

| ID | What | LOC | Depends on |
|---|---|---|---|
| H1 | `sim/home_tiers.ail`, `sim/data/home_variants.ail` and tests; `cruise_digest` switch; the 2.12 gate with `variant`; `home-tiers-vm` | ~380 | n/a |
| H2 | Bridge minor; sessions; `picture_index`, `picture_variant` and the v0 fallback; capture and fixture tools; fixtures re-recorded | ~200 | H1 |
| H3 | Renumber; 21 variants inspected, uploaded and converted; `SOURCES`; notes; `home-art-check` | ~60 (+ binaries) | H2 |
| H4 | Thumbnails (Godot), `concept.js` (tiers 0–12), `home-site-check` | ~80 | H3 |
| H5 | Rig gates, captures opened, changelog, PR | ~0 | H1–H4 |
| | **Total** | **~720** | |

All of it ships as one PR.

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| Minor 12 is claimed by R2-SIMILAR-S0 first | Re-check before merge. The second branch takes 13; only `homeTiersMinor()`, the bridge constant and the fixtures change |
| An older stream shows the wrong picture | `tier_count` and `variant` exist only at 2.12; `PICTURE_OF_SEVEN` and v0 cover everything older (AC10) |
| The variant pick consumes or shifts the world RNG | It has its own salted key and draws nothing (`Rng` unchanged; AC7 goldens) |
| A line overclaims somewhere in its range | Each line is checked at both ends (⚑ rows); AC3 |
| The late tiers spoil Earth's fate | 13–15 stay off the site; the follow-up fate design (canon note) |
| A variant has text-like marks | 1:1 inspection in quadrants before shipping; drop and list |
| The shipped size grows by about 11 MB | Within the 20 MB budget (AC14) |
| A file is overwritten during the renumber | Every move goes to a new `_v0` name; AC9 compares shas |

## Deliverables

- `sim/home_tiers.ail`, `sim/data/home_variants.ail`, `sim/home_tiers_test.ail` (added to `[exports].modules` in `sim/ailang.toml`).
- Edits to `sim/cruise_digest.ail`, `sim/cruise_digest_test.ail`, `sim/protocol.ail`, `sim/protocol_test.ail`, `sim/protocol_interlude.ail` and `sim/protocol_interlude_test.ail`.
- `bridge/sim_bridge.gd`, `main.gd`, `demos/ship_geometry_demo.gd`, `ui/loading_jump.gd`, `ui/crossing_review.gd`.
- `tools/crossing_review_capture.gd`, `tools/crossing_review_fixture.gd`, `tools/concept_thumbs.gd`, `tests/test_crossing_review.gd`.
- `tests/fixtures/crossing_review/*.ndjson`, re-recorded at 2.12, plus `legacy_2_10_trappist.ndjson`, which is today's `trappist.ndjson` kept as it is.
- `data/interlude/home/tier<n>_v<k>.webp` (28), `SOURCES` and `generation_notes.md`; the masters in `gs://stapledons-voyage-assets/site/`.
- `website/static/img/concept/home-t<nn>-v<k>.jpg` (tiers 0–12, 23 pictures), `website/src/data/concept.js`.
- Make targets `home-tiers-vm`, `home-art-check` and `home-site-check` (in `make test`).
- The ledger row D-86 in `design_docs/stapledon-mission.md`.
- `CHANGELOG.md` (protocol 2.12), `changelogs/unreleased/2026-10-<dd>-home-tiers.md`, and the design repo's roadmap row.
- `design_docs/implemented/r2/home-tiers-report.md` at landing.
