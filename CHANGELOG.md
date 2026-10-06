# Changelog

## Unreleased

### Real-time voyage to Aldebaran, 2026-10-06

- The guided tour runs in real time: one ship second per wall second, with no time compression (D-39). A single drive is used for the whole voyage: 3,000,000 g, cap 1 − β = 5 × 10⁻⁷, m_eff 10 kg. It passes the unchanged brake-vs-drag check. Solar System legs cruise at 0.99c (Earth → Jupiter is about 6 ship minutes and 39 Earth minutes).
- The voyage continues past α Cen to TRAPPIST-1 at 0.9999c and Aldebaran at 0.999999c (D-41). It is measured at 0.891 ship years against 120.47 Earth years.
- Cruises longer than 10 minutes of ship time play 10 s in real time, then hand over to a cruise interlude (`ui/cruise_interlude.gd`), the seam for in-ship gameplay. The demo's interlude is a card (`ui/card_interlude.gd`, `ui/interlude_card.gd`). It shows speed, γ, both clocks and the age of news from home, all read from simulation fields, and a line of scale chosen from the cumulative Earth time: "…Everyone you knew is gone." The clock lands exactly on the braking boundary, and braking plays in real time.
- Ordinary map journeys keep their pacing, checked byte-identical against a recorded golden.

### Realistic and Auto views, 2026-10-06

- Ship demo: a View button `[V]` switches between **Realistic** (default: one manual exposure; sunlit planets clip, as for a real observer) and **Auto** (each resolved body faded on its own to fit the display, labelled as a composite on the HUD). The manual exposure presets work in both; the sky exposure, star photometry and SR maths are unchanged (D-38).
- `tools/exposure_auto_view.gd` renders Earth and Jupiter stops in both views.

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
