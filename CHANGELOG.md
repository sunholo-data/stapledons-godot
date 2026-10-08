# Changelog

## Unreleased

### Lightspeed loading view, 2026-10-08

- Board the ship, Guided voyage and Galaxy map no longer freeze the title while they load. The title's own sky accelerates toward the galactic centre as the load progresses, through the game's real relativistic optics (aberration, Doppler colour, the starbow), to 0.99999c at 100% (γ 223.6): the whole sky collapses into one blinding blue-white point. Then a white-out (a transition effect, not physics) blooms from that point and fades into the destination.
- The overlay shows β, γ and 1 − β (from the `sunholo/relativity` mirror; never 1.0 − β), the percentage, the stage being loaded, and says the speed is illustrative while the optics are the renderer's. Progress is real: stages weighted by measured time and counted when they finish, monotone, 100% only when the destination is built and drawn.
- Faster: press to ready, Board the ship 7.9 s → 2.0 s, Guided voyage 7.3 s → 2.0 s, Galaxy map 3.0 s → 0.7 s (Mac Studio). The simulation starts on a worker thread; the galaxy map's star colours are computed on workers and ten times faster (a table form of the colour integral, bit-identical); the ship reuses the title's decoded sky panorama and loaded star tiers; the captain's sprites are built one a frame. The ship's scene build still holds the jump for about 1.3 s.
- Command-line, capture, golden, smoke and export modes are unchanged. `make loading-jump-test` (in `make test`), `make loading-jump-capture` (renders to `renders/loading_jump/`), `make loading-profile`; two golden cases at the jump's 50% and 100% speeds. Design: `design_docs/planned/r1/lightspeed-loading.md`.

### Title screen, 2026-10-08

- A plain launch (a double-click on the app) now opens a title screen over the real sky: the NOIRLab panorama and the catalogue stars, rendered at rest by the game's own sky stack with a slow pan along the Milky Way. Buttons: **Board the ship** (the 3D ship at live rest, as before), **Guided voyage** (the ship, straight into the solar-departure tour), **Galaxy map**, **Settings**, **Credits**, **Quit**. Mouse or keyboard (Up/Down wrap, Enter, Esc closes a panel, PageUp/PageDown scroll the credits). The footer shows the build id and "dev build".
- Esc aboard the ship, or the new "Main menu [Esc]" HUD button, returns to the menu when the ship was opened from it; Esc on the map does too. Every command-line launch (`--ship-demo`, `--voyage`, `--interior`, `--map`, captures, goldens, benches, smokes) is unchanged and keeps Esc = quit.
- Settings: the ship's view, Realistic (default) or Auto (D-38), saved in `user://settings.cfg`; text-only AI (D-8), saved as the AI settings' own `text_only` in `user://ai_settings.cfg`, so the AI tick and ceiling are kept.
- Credits: the NOIRLab CC BY 4.0 panorama, Solar System Scope textures, CNS5, Gaia/DPAC, Hipparcos, the NASA Exoplanet Archive, Godot and AILANG, plus every paper and table the simulation cites, read at runtime from the citation lists in `sim/data/*.ail`.
- `make export-macos` stamps `runtime/build_version.txt` (`git describe`). `make title-screen-test` (in `make test`), `make title-capture` (renders to `renders/title_screen/`), `make title-export-smoke` (in `publish-dev`); `current-ship-export-smoke` now launches with `-- --ship-demo`. Design: `design_docs/planned/r1/title-screen.md`.
### Inspect the system you are in (I key), 2026-10-08

- Holding I now rings the Sun, planets, moons, finite stars and exoplanets as well as catalogue stars, at the size they are drawn. Clicking one opens its card: distance from the ship, size and apparent size, temperature for stars, how long ago its light left, its catalogue identity ("Open in map") and its data source.
- Planets and moons of a distant system are not offered (they are invisible from there), and a body behind a nearer one is hidden, as stars are.
### Fix: the dev.20 lag with the 100 pc sky, 2026-10-08

- Every frame, the sky checked each finite star against all 335,189 star identities with a linear scan: 13.7 ms a frame on an M4 Max at the Aldebaran stop, enough to drop Mark's M2 Air from 60 to about 53 fps (30 fps in the overview). It now uses the starfield's hash index: 0.01 ms. With the large sky, Studio frames went from 16.1–30.3 ms to 8.3–8.5 ms, the same as the medium sky.
- A regression test checks that the unchanged per-frame call costs no more at 300,000 stars than at 3,000; it fails on the old scan (3.3 ms against 0.03 ms).
- Performance audits record the exported build's real version (written into the bundle at export) instead of a stale "dev.14" constant.

### The ship lit by the real star, 2026-10-07

- The ship's geometry is lit by the star the player sees (dev.20). A new `StarLight` comes from the dominant finite star's apparent direction, the same aberrated disc centre the sky draws, turned into ship axes by the sky camera's attitude, so the light comes from where the Sun is seen through the bubble. Turning the ship sweeps the Sun's shadows across the bridge; when the star is below the deck, the floors shade it.
- Its colour is the star's blackbody at T × D (the renderer's lookup, Doppler at the apparent angle): TRAPPIST-1's light is red, Aldebaran's orange, the Sun's white.
- Its brightness is **log-compressed, not physical**: each decade of the illuminance at the ship (sim `e_v_lux`, Doppler flux ratio, eclipses) is an equal step from 1 lx (off) to 10⁵ lx (full). Earth is full, Jupiter about 73%, interstellar cruise off. The HUD details (Tab) and the lighting manifest say so.
- The moody ambient, cool fill and Commons practical stay; the ship-fixed broad key dims as the star takes over, never below a 25% readability floor (ship light, not physical, shadowless), and is fully back between the stars. Exactly one light casts shadows at a time; the handover fades through zero opacity. Changes ease over 0.5 s; a second star must be 1.5× brighter to take over.
- `make ship-star-light-test` (in `make test`), `make ship-star-light-capture`, `make ship-star-light-bench`.
### TRAPPIST-1's seven planets, 2026-10-07

- TRAPPIST-1 b–h are real bodies at the voyage's habitable-zone stop (Sprint B part 2, D-41). They come from a pinned NASA Exoplanet Archive snapshot (`data/planets/trappist1_ps.csv`, sha256 in `EXOPLANETS.SHA256`, fetched by `tools/fetch_trappist1.sh`), transcribed with citations into `sim/data/trappist1.ail`.
  - Size and orbit are from Agol et al. 2021. Orbital phase is from Ducrot et al. 2020's mean transit ephemeris, which predicts JWST's 2024 transits of b and c within 15 minutes.
  - Circular orbits, the sky-plane node and the albedos are stated assumptions.
- Each planet is where it really is when the ship arrives: Kepler orbits from `sunholo/celestial`, phased by the transit epochs less the 40.6-year light-time. Each is lit by TRAPPIST-1's own light: the wire carries the host's `teff_k` and `e1_au_lux`, so `SystemView` no longer lights every planet with the Sun.
- The stop keeps D-47 (√L = 0.0235 AU from the star) but now sits on that sphere beside the best-lit planet. At the voyage's arrival that is e, 0.72° across. c (crescent), d (half lit) and f are resolved discs too. Every orbit stays more than 30 radii from the resting ship; d, just inside the HZ, comes nearest at 192,000 km. The voyage keeps its 10 stops.
- `make trappist1-test` (in `make test`) checks the pin, runs the sim checks with the strict VM equal to the interpreter, and runs a Python oracle that recomputes every row and position (worst 2e-12 AU). `make trappist1-capture` renders the stop to `renders/trappist1/`.
### Star colours in Auto view, and a longer approach to a giant (D-49), 2026-10-07

- In Auto view a star is dimmed just enough to keep its hue and its own blackbody colour is lifted: Aldebaran is golden orange, TRAPPIST-1 red-orange, the Sun a warm white. Realistic view is unchanged; the HUD says "star colours enhanced".
- Aldebaran's final approach lasts 90 s from where it is 25° across, so the giant grows from the starbow into a 40° disc instead of appearing in the last seconds. Other stops keep 25 s.
- The voyage capture takes approach frames at the start, middle and 85% of each leg's own approach.
### The full 100 pc sky (large tier), 2026-10-07

- The ship's sky draws every GCNS star within 100 pc. The large tier has 331,311 rows: all of GCNS minus HIP 27890's duplicate. Of these, 324,306 have photometry and are drawn. With 170 CNS5-only stars and 10,713 bright Hipparcos stars added, the sky draws 335,189 stars, against 60,883 on the medium stack. All are at truth positions.
- `make starmap-assets` fetches the pinned tier (`data/starmap/SHA256SUMS`) from `gs://stapledons-voyage-assets/starmap/` in under a second. `make test` (and so CI) and `make export-macos` run it. `make starmap-consistency-large` fails if the file is missing or not 331,311 rows. The game falls back to medium with a warning naming the missing file, and the galaxy map's coverage tooltip shows the active sky tier.
- Benchmarked first on the M4 Max, 3 runs per tier.
  - GPU timestamps (Vulkan): the star pass costs +0.25 to 0.30 ms at p50 (0.32 ms against 0.02 to 0.07 ms).
  - Wall time (Metal): frame p99 is 10.6 to 10.8 ms on both tiers.
  - Loading takes +0.45 s.
  - Exported app: +15.2 MB, and about +240 MB peak RSS at the sky scene (`make starmap-export-smoke`).
  - M2 Air: an estimate of about +1.3 to 1.8 ms, not measured.
  - Destinations to 100 pc wait for the galaxy map's level-of-detail design (the design's default: sky first).
- `tools/starmap_sky_capture.gd` renders medium and large side by side. At rest and 50 ly out, the large tier adds about 20 % more visible faint stars. These are GCNS stars that the destarred panorama had already removed. At γ 707 the boosted CMB fills the forward cone; with the CMB off the starbow gains 3 % in light.

### One position per star, 2026-10-07

- A new star-truth table, `data/starmap/truth/positions.csv`, gives one position for each of the 5,212 stars that more than one catalogue lists. It is built in AILANG by `make starmap-truth` (VM = interpreter). Navigation and every sky tier take positions from it, so a map journey to a Gaia-only star arrives with the star 1,000 AU ahead. TRAPPIST-1 was 3,650 AU away on arrival, 10 UMa 8.7 ly beyond its stop, and GJ 10940 6 ly *behind* the ship.
- Rule `truth-1`: CNS5's adopted parallax wherever CNS5 evaluated the star. That is Gaia EDR3 with the Lindegren zero-point correction, or Hipparcos/DR2 for the 69 stars whose EDR3 solution is poor. Gaia EDR3 is used for CNS5 stars without a Gaia id, when its solution is good. The design's "posterior vs 1/ϖ" diagnosis was wrong: every catalogue already uses 1/ϖ, and the offsets were the zero-point correction plus CNS5's per-star source choices. The 14 disagreements over max(3σ, 1 %) are all "better parallax" cases, each one documented in `design_docs/implemented/r1/starmap-truth-audit.md` (`make starmap-truth-audit`).
- The sky stack now adds every CNS5 star that GCNS lacks (26 destinations were missing from the sky). It restores destinations to their float64 navigation positions and draws no star twice. `make starmap-consistency` checks all 5,685 destinations. `pin_destination` is now an assertion, and a no-op for every destination.
- Navigation is unchanged apart from CNS5:138, which has no photometry. The medium tier moves about 5,100 stars onto the navigation positions.

### Finite destination stars, 2026-10-07

- Every star the voyage visits has its real size (D-47/D-48). Aldebaran (45 R☉, 3,927 K; Richichi & Roccatagliata 2005, Heiter 2015) and TRAPPIST-1 (0.119 R☉, 2,566 K; Agol 2021) become cited finite stars, replacing their catalogue points.
- Stops follow one rule. Main-sequence stars stop in their habitable zone (√L AU), where they look like the Sun from Earth: α Cen A at 1.233 AU, TRAPPIST-1 at 0.0235 AU (2.7° across). Giants stop where they fill 40° of sky: Aldebaran at 0.615 AU.
- Each star's final hop uses the even-leg rhythm: 30 s accelerating, about 60 s cruising, then the 25 s final approach. The voyage now has 10 stops.
- A finite star named by its Gaia id also hides the sky's bare-number catalogue row, so its light isn't counted twice even without a destination pin.

### Even legs, a gentle final approach and skip-to-next-stage, 2026-10-06

- Every in-system leg of the guided voyage has the same rhythm: 30 s accelerating, about 60 s cruising, braking, then a 25 s final approach. The sim solves each leg's thrust and cruise speed (0.07c to the Callisto hop, above 0.999c to Jupiter and Saturn); Sun → Jupiter takes about 2¼ minutes instead of 6½ (D-46).
- Arrivals ease in: a new trip profile brakes hard, then approaches gently from where the body is 4° across. It's in `sunholo/relativity` 0.9.0 (published; existing outputs bit-identical), and the ship reports a new `approaching` phase.
- **Skip stage [K]** jumps exactly to the next stage of the leg (accelerating → cruise → braking → approach → arrival). The HUD shows "FINAL APPROACH" and this leg's thrust, and labels how many stages were skipped.
- The HUD also shows the distance to the destination, from the last stop, and from Earth.
### News from home, the AI path, the return trip and the legacy screen, 2026-10-06

- M4.4. The Archive terminal's news tab is a panel: "Transmission received", a header built from sim fields ("Latest news from Earth: Earth-year +0.04, already 4.31 years old."), and one paragraph from `data/news/templates.json` (five tiers of four, numerals only inside `{slots}`, at most 280 characters), or the accepted AI text. What it shows follows the sim's `news.body_source`: `template` has no notice, `ai` a small "generated" tag, `fallback` the template under "Live transmission unavailable: archived text shown", the reason in words from a fixed digit-free table and a diagnostics entry. Nothing is asked of the AI service without AI on and a key (D-8).
- The map's return trip opens with Sol planned and highlighted (`GalaxyMap.plan_home`, `R` in the interior); the hold-to-commit ritual is unchanged and the sim still refuses a stale plan. Arriving at Sol shows the legacy screen: the sim's log, the closing line from `clock.tau` and `clock.t` ("You were away 1.24 years. Home is 8.80 years older.") and "Begin again" (a new voyage with a new seed on the running sim; no save or load).
- `make news-lint` (template lint, with the stray-digit fixture as a positive control) and `make news-test` (renderings, reason table, return trip, legacy screen over the real sim) are part of `make test`. `make sim` asserts `body_source` template / ai / fallback(`ai_numeral`) on one arrival. S4 copy approved (D-45 B, Mark attended 2026-10-06): at the Sol return the header drops the age clause (", just arrived.") and the body shows the no-age phrase, so the panel never reads "0.00 years old" (`data/news/copy.json` labels; review sheet `design_docs/planned/r1/m4.4-s4-copy-review.md`).

### Real-time voyage to Aldebaran, 2026-10-06

- The guided tour runs in real time: one ship second per wall second, with no time compression (D-39). A single drive is used for the whole voyage: 3,000,000 g, cap 1 − β = 5 × 10⁻⁷, m_eff 10 kg. It passes the unchanged brake-vs-drag check. Solar System legs cruise at 0.99c (Earth → Jupiter is about 6 ship minutes and 39 Earth minutes).
- The voyage continues past α Cen to TRAPPIST-1 at 0.9999c and Aldebaran at 0.999999c (D-41). It is measured at 0.891 ship years against 120.47 Earth years.
- Cruises longer than 10 minutes of ship time play 10 s in real time, then hand over to a cruise interlude (`ui/cruise_interlude.gd`), the seam for in-ship gameplay. The demo's interlude is a card (`ui/card_interlude.gd`, `ui/interlude_card.gd`). It shows speed, γ, both clocks and the age of news from home, all read from simulation fields, and a line of scale chosen from the cumulative Earth time: "…Everyone you knew is gone." The clock lands exactly on the braking boundary, and braking plays in real time.
- Ordinary map journeys keep their pacing, checked byte-identical against a recorded golden.
- The ship demo HUD is compact: destination and phase, speed (β from the sim's exact 1 − β, γ, km/s) and both clocks; the review and debug details are behind Tab.
- Destination stars render where the simulation navigates (`Starfield.pin_destination`). The sky's GCNS tier placed some stars thousands of AU from the navigation catalogue (TRAPPIST-1 by 0.042 ly), which showed at a 1,000 AU stand-off. A pinned destination later drawn as a physical emitter is suppressed with its identity, so its light is not counted twice.

### Realistic and Auto views, 2026-10-06

- Ship demo: a View button `[V]` switches between **Realistic** (default: one manual exposure; sunlit planets clip, as for a real observer) and **Auto** (each resolved body faded on its own to fit the display, labelled as a composite on the HUD). The manual exposure presets work in both; the sky exposure, star photometry and SR maths are unchanged (D-38).
- `tools/exposure_auto_view.gd` renders Earth and Jupiter stops in both views.
- Auto view: stars (the Sun, Alpha Centauri A/B) fade to a higher target than lit bodies, so the Sun stays the brightest thing on screen: white with its warm channel order kept (255, 254, 254), not a grey star. `tools/exposure_auto_view.gd` checks it.

### Boot splash, 2026-10-06

- Replace Godot's default boot logo with a Stapledon's Voyage splash in the style of the website hero: the destarred Milky Way around the galactic centre, the wordmark and tagline, and "Simulation built in AILANG" with the AILANG logo. `make splash` recomposes it in Godot from the panorama (`tools/splash_compose.gd`). Exported builds hold it for at least 1.5 s; editor and headless runs are not delayed.

### Manual sky exposure correction, 2026-10-05

- Remove automatic exposure changes from the current ship demo, following laptop review. Camera motion, bright planets and nearby stars no longer dim the background automatically. Keep physical source brightness and SR calculations unchanged; manual brightness settings control the display.
- Withdraw dev13 as the default private download after its unresolved-star anticipation caused missing starfields. Retain dev12 as the fallback until the manual-exposure replacement is visually verified.
- Initialize the tour camera from the new session heading, removing a one-frame old-heading jump. Ease guided departure time compression over three seconds so nearby planets do not leap on the first compressed tick; simulation motion and ordinary navigation remain unchanged.

### Laptop sky and approach follow-up, 2026-10-05

- Meter the final shared camera view rather than temporary simulation headings, preventing Earth/Jupiter and Sun exposure from alternating between updates. Interactive brightness adaptation is a labelled display policy; fixed EV and physical reference paths stay explicit.
- Set the guided tour to 1 g so braking starts farther out, then give approaches 90 wall seconds with progressively less time compression near arrival. Ordinary map sessions retain their acceleration and pacing.
- Add measured Alpha Centauri A/B radii and temperatures, continuous exact-ID rendering and star inspection, and a final moving-A intercept at 1 AU after the system stand-off. Binary motion uses the existing package orbit/light-time functions; the stellar surface is a uniform emitter.

### Solar departure and moody ship review, 2026-10-05

- Increase collision-safe walking to 3.5 m/s and restore warm internal light, cool fill and geometry shadows on the painted ship. Retain the movable camera and shared observer; simulation-driven external ship sunlight remains pending.
- Add a guided Earth → Jupiter → Saturn → Alpha Centauri journey with actual acceleration, cruise, braking and continuous positions/clocks. Planet stops are inertial; Earth uses the Earth–Moon barycentre approximation.
- Render moving planet discs and Saturn rings through package-backed inverse aberration, radiometry and shared metering. Opaque planet faces also mask known-star inspection.
- Start subsequent map routes from the current ship endpoint; add recenter/fit controls and honest surveyed-catalogue coverage.
- Publish selected native lighting, planet-stop, outbound and navigation screenshots in the gallery. M2 Air performance and further ship art remain pending.


### One current ship and known-star identification, 2026-10-05

- Normal launch opens one current expanded ship at the captain’s measured eye, with live navigation at rest. Scrolling reveals a labelled third-person view. Original painted/capture modes remain explicit reference tools.
- Add genuine UV-painted bridge surfaces and packed editable Blender masters; preserve exact geometry, walk meshes and the existing Commons paint. This first texture interpretation remains open for art review.
- In the current ship, hold I to highlight known visible stars, hover for a name and click for catalogue facts. The details card persists after release; Esc closes it. Overlapping sources offer individual choices.
- Open the same exact catalogue ID in navigation explicitly. Inspection leaves the running voyage and irreversible commitment unchanged.
- Carry producer IDs through the sky renderer, and place highlights on apparent star directions while respecting opaque ship geometry. Catalogue distance is labelled from Sol; unavailable fields remain unavailable.


### Open Commons arcade and live journey review, 2026-10-04

- Replace the generic pavilion with the first section of the approved Commons layout: an open curved arcade, planted plaza and guarded walking link. This remains a bounded prototype; other districts and final painting are still to come.
- Committed review journeys now show actual simulation acceleration, coast and braking aboard ship, with about 20 seconds per phase using labelled time compression. Navigation remains reachable at laptop window sizes.
- Refresh the bundled simulation cache when its contents change, including nested modules, so updates do not reuse an older simulation.
- Retain 4× exposure. Target MacBook Air performance remains to be measured.

### Commons architectural review and 4× default, 2026-10-04

- Set the review demo sky exposure to 4× by default, as requested; physical sky inputs remain unchanged.
- Record that the generic pavilion is a prototype, not a faithful build of the approved Commons concept. Add an unbuilt zoning proposal and finish-only paint study for review before replacing its architecture.

### Commons expansion and exposure trial, 2026-10-04

- Add reusable planted terrace canopy, seating, reading tables and pavilion details within the current playable Commons.
- Trial labelled sky exposure at baseline,2×,4×,16× and64× (default2×), with physical sky inputs unchanged. J cycles settings.
- Preserve the sky meter while turning the camera; record the active exposure in captures and benchmarks.

### Commons and journey sky review, 2026-10-04

- Add the first painted Commons pavilion and courtyard, with collision, lift access and a coarse distance model.
- Open the ship review in an actual frozen 0.99c simulation snapshot, with rest and forward/side/aft comparisons.
- Include native export checks and five-view profiling. MacBook Air performance remains pending.

### Seven-tier geometry review demo,2026-10-04

- Trackpad controls: Option plus one-finger movement looks without a held click; two-finger scrolling zooms. Mouse right-drag and wheel still work. Whole-ship zoom keeps its overview, with zoom disabled during lift travel and benchmark sampling.
- Separate review window preserves the running voyage. One perspective observer aligns native bridge geometry, lower tiers and the existing live star/sky renderer; opaque floor/rail occlusion is preserved. GR remains unimplemented.
- Demo-only guarded lift openings support a physical25m descent to the first tier, a bounded landing walk and return with separate active WALK regions. Production bridge art stays unchanged.
- In-app1920×1080 benchmark and packaged smoke checks added. StudioM4Max frame-time p95 measured26–29ms in this run; this does not meet the proposed60fps budget and does not establish MacBookAirM2 performance. Actual target-laptop measurements remain pending.


### Companion stars take their system's distance, 2026-10-03 (Mark's ruling; M1.7 evaluation follow-ups)

- **Companion rule** (`sim/tools/companions.ail`, design
  `design_docs/planned/r1/m1-companion-parallax.md`): a star within 60″ and
  2,000 AU of a brighter star, with parallaxes within 20% (and 5% or 3σ) and
  proper motions within the orbital bound, takes the system root's parallax.
  `make companions` writes `data/starmap/companions/companions.csv` (20,515 companions over
  CNS5 + GCNS + the bright tier; 9 cross-identifications, e.g. GJ 10136 = CNS5:252,
  dropped as the same star); every tier and `stars.json` apply it, the GCNS tiers move
  CNS5-record roots with their companions, and every build refuses a split pair. Sirius B
  now 8.601 ly (was 8.709), Luyten 726-8 B 8.817 (was 8.724), Wolf 424 B 14.112
  (was 14.593). α Cen B is the old rule (c) case: its bytes are unchanged;
  `bright_overrides.json` is retired. No primary row moves in quick, bright or the map; every non-companion
  row is byte-identical (the GCNS tiers also move 488 root rows).
- **Tests:** `make companions-test` (thresholds just inside/outside, real-line
  fixtures, strict VM = interpreter); `tools/check_companions.py` (oracle) in
  `make catalogue-verify`.
- **`make catalogue-verify` green again:** tier sidecars regenerated on v0.52.0 /
  relativity 0.5.2 (they still said v0.51.0 / 0.5.1 after the bump).
- **`tools/check_star_names.py`:** negative controls for direction (5°),
  distance (10%) and a name row repeated.
- **Galaxy map labels** skip a name whose box overlaps a drawn label;
  `docs/m1.7/destar_before_after.png` labelled before/after.

### Review-build polish, 2026-10-02 (Mark's feedback on `v0.3.1-m2-journey`)

- **Trackpad zoom on the galaxy map:** pinch (magnify gesture) and two-finger
  scroll (pan gesture, one unit = one wheel notch) zoom, clamped like the
  wheel; `+`/`=` and `-` zoom by a notch. Two-finger scroll never orbits.
- **HiDPI and UI size:** `allow_hidpi`, canvas-items stretch (aspect expand)
  so the panel scales while 3D renders at full resolution; on a HiDPI screen
  the window opens at base × screen scale. Cmd/Ctrl `+`/`-`/`0` change the UI
  size (0.75–3.0). Captures and goldens keep the 1:1 window: committed
  `docs/m2.6a`, `docs/m2.6b` PNGs are byte-identical.
- **Footer hint** "Pinch or scroll to zoom · drag to orbit · ⌘+/− UI size"
  (hidden in `--map-capture`).
- **Missing sky background is loud:** the sky flight warns on startup and
  shows "sky background not bundled in this build" when the M1.4 panorama is
  absent (HUD note hidden in `--capture`).

### M2 journey core, 2026-10-01 – 2026-10-02 (sprint R1-M2-JOURNEY, landed; bar clause 2 met)

Ten milestones, PRs #22–#35, each independently evaluated (89–96/100).
Report: `design_docs/implemented/r1/m2-report.md`.

- **M2.0 package (96):** `sunholo/relativity@0.4.0` published (ailang-packages
  #84): boost–cruise–brake and flip-and-burn trip plans, `phaseAt`,
  `motionAt`, `acosh1p`, `rapidityOfOneMinusBeta`, ISM `medium`, forward CMB
  temperature; 101/101 tests.
- **M2.1a protocol codecs (92), M2.1b bridge v2 (93):** protocol v2 with
  hand-written codecs and float-text repairs (−0.0, large/small floats);
  `SimBridge` v2 with a `record_path` tee and bit-exact float64 echo; v1.1
  removed.
- **M2.2 world (94):** `World`, scenario params, clock, ship phases, closed
  energy ledger; game pins relativity 0.4.0.
- **M2.3a planner + commit (95), M2.3b autopilot (96):** planner equals the
  closed form to 1e-9; the sim refuses every intent against a committed
  journey; stepped voyages match `motionAt` at every phase boundary, arrival
  residuals ≤ 4.8e-13 ly.
- **M2.6a galaxy map (89), M2.6b commit ritual (93):** galaxy map with a
  sim-bounded cruise slider and a panel of sim numbers only (review build
  `v0.2.0-m2-map`, R1 accepted by Mark, D-17); commit dialog with both clocks,
  years left and a 1.5 s hold, transit readout, refusal display, 54 common
  star names. Map → plan → commit → transit now runs end to end.
- **M2.4 PRNG (94):** SplitMix64 with six named streams (`splitmix64-1`),
  checked against published vectors and a reference on both runtimes.
- **M2.5 replay (93):** `make replay` / `make replay-record`; a 10,000-tick
  session is byte-identical on the VM and the interpreter and matches its
  golden. Goldens are per architecture (ailang#1465); P5 approved by Mark.
- **Toolchain:** AILANG pinned to v0.50.0 (#18), then v0.51.0 (#30).
  Thirteen AILANG issues filed or tracked during M2 (see the report).

### Fix: mirrored galactic longitudes in stars.json, 2026-10-02

- Every longitude in `data/starmap/stars.json` was mirrored, l = 245.86° − l_true
  (`process_stars.sh` added the IAU atan2 term to l_NCP instead of subtracting
  it). Fixed and regenerated from the same VizieR V/70A votable (the unfixed
  script reproduces the old file byte for byte): same 3,802 rows and order,
  only x, y change. 16 literature (l, b) check values in `tests/test_physics.gd`.
  The M1.4a destar mask (D-10) was built from the mirrored positions and needs
  a rerun.

### M1 sky, 2026-09-27 – 2026-09-30 (in progress; 3 of 12 milestones)

- **M1.1 photometry (iteration 0):** `sunholo/relativity@0.2.0`
  (BP−RP → T_eff, G−V, V → lux); game pin `b258222`.
- **M1.2a catalogue (iteration 2):** CNS5 + GCNS acquired from VizieR and
  parsed to galactic CSV (5,908 + 331,312 rows), 15 real-byte-fixture tests
  in `make test`; merge `77d3f04`.
- **M1.6a turns at rest (iteration 3):** pure ship turns at rest with phi
  snap and `origin + heading*(x−x0)`; `std/json` protocol v1.1 with reason
  codes; bounded bridge waits (5 s hello, 2 s step, 1 s graceful exit);
  off-axis parity and strict `scriptedOffAxis`; default-heading render
  unchanged (601-line v1.0 parity byte-identical). Requires AILANG v0.47.2
  (fixes the two VM bugs that parked this milestone; see the design doc's
  toolchain amendment).

- **M1.2b preflight (iteration 4):** bounded AILANG CSV and published normal
  photometry probe, real-byte fixture checks, strict VM/interpreter parity
  and real 5,000-row timing. WD fitting, production tiers and binary
  writing remain incomplete and depend on the package prerequisite.

- **M1.2b white-dwarf photometry (iterations 5–6):** `sunholo/relativity@0.3.0`
  published (blackbody WD Teff and V from Gaia BP−RP); the game pins it,
  `checkWDPackage` pins the fixture WD row, and `make wd-vm` checks the
  package's NaN contract on the strict VM (ailang#1419 hides NaN-guard
  mutants from the interpreter-only `ailang test`). PR #12, merge `68575d9`.

- **M1.2b pure transform (iteration7):** package-backed normal/white-dwarf
  photometry, explicit missing/clamped flags and independent counters; stable
  nearest-complete medium selection with quick/large source order preserved.
  Ten new tests and strict-VM/interpreter anchors run in `make test`.
  Independent Sonnet5.5 review: 88/100 PASS. Binary writer and full-tier
  parity/performance remain pending; full M1.2b is incomplete.

### Catalogue F32 records (M1.2b-T2, iteration 8)

- Pure AILANG Row/list encoding uses the bundled native little-endian F32 codec;
  invalid fields or flags refuse the whole output before any writer is involved.
- Independent Python byte oracle runs interpreter and five ordinary VM passes in
  `make test`; strict T1 tests now pin dwarf clamps and exactly one final newline.
- Filesystem writing, sidecars and production catalogue tiers remain downstream.

### M0 spike, 2026-09-27 (~1,900 LOC including tests)

- **Simulation:** AILANG sidecar over NDJSON stdio, about 50 µs per tick
  round trip.
  - Pure core on the bytecode VM, checked under `--strict-bytecode`.
  - I/O shell bridged to the interpreter.
- **Physics:**
  - GDScript reference: 27 checks.
  - GPU starfield: aberration, blackbody Doppler colour, point-source beaming,
    HDR.
  - 9 golden cases at under 0.1 px.
- **`sunholo/relativity@0.1.0`:** published (about 600 LOC, 40 tests); the
  simulation depends on it.
- **Tooling:** `make test` (physics, sim, parity, strict) and CI.
- **Process:** the design-doc → sprint → execute → evaluate cycle, the
  `game-vision-designer` and `starmap-manager` skills, and the M1 design doc.
- **Upstream reports:** 11 AILANG bug and DX reports.
