# M1: The relativistic sky

**Status:** Planned (design, awaiting sprint plan)
**Release:** r1 · **Milestone:** M1 of [R1 foundations](https://github.com/sunholo-data/stapledons-design/blob/main/roadmap/r1-foundations.md)
**Priority:** P0: every later milestone looks through this sky
**Implements:**
- [relativity spec §2](https://github.com/sunholo-data/stapledons-design/blob/main/physics/relativity-spec.md) (special relativity) and §4 (tests)
- [starmap-data-model](https://github.com/sunholo-data/stapledons-design/blob/main/features/phase1-data-models/starmap-data-model.md)
- [celestial-lod-system](https://github.com/sunholo-data/stapledons-design/blob/main/features/celestial-lod-system.md),
  **Point tier only** (its §"Point Batch Rendering"): every star is one
  instanced splat, with no runtime LOD switching. AC7 is the justification: if
  the large tier holds 60 fps as instanced splats, no LOD is needed for
  points. The Full3D, Billboard and Circle tiers are for planets and nearby
  objects, which are M4 or later.
- [sr-view-directions](https://github.com/sunholo-data/stapledons-design/blob/main/features/future/sr-view-directions.md)

**Depends on:** M0 spike (done: `CHANGELOG.md` "M0 spike, 2026-09-27"), `sunholo/relativity@0.2.0` (published in M1.1)
**Estimated:** ~2,930 LOC committed (≈1,730 code + 1,200 tests/tools), 6 sub-milestones; +~250 if the proposed M1.2d is accepted (open question 5)
**Evidence:** every codebase claim has a row in the [Verification log](#verification-log), pinned to `aabb82d`; external catalogue counts and URLs are re-verified at M1.2 download time by `download_stars.sh` checksums recorded in the binary JSON header.

## Game vision alignment

| Pillar | Relevance | Score | Notes |
|---|---|---|---|
| Choices Are Final | 0 | 0 | No choices yet; this is what the player sees while committed to a journey |
| The Game Doesn't Judge | 0 | 0 | |
| Time Has Emotional Weight | + | +1 | The sky astern going dark is the visual of leaving everything behind |
| The Ship Is Home | + | +1 | The windows in every deck show this sky |
| Grounded Strangeness | ++ | +2 | The universe looks as it really would at 0.99c; that is the strangeness |
| Hard sci-fi authenticity (spec) | ++ | +2 | Normative physics spec; every effect tested against closed forms |
| **Net** | | **+6** | **Go** |

## Problem

The M0 spike shows the architecture works. The sky it draws is still far from
what the spec asks for:

1. **Star colours are guesses.** (Corrected 2026-09-28 after the
   verification log; see rows V1–V5.)
   - The renderer takes a temperature from a single spectral letter
     (`sky/starfield.gd:25`).
   - The committed catalogue (`data/starmap/stars.json`, 3,802 stars) went
     through the old pipeline's quick path (`process_stars.sh`,
     `parse_cns5_votable`). That path copies the letter from the catalogue's
     `Sp` column and **defaults to "K"** when it is blank or not OBAFGKM
     (lines 158 and 202). Proxima Centauri (Gl 551) comes out as "K". This
     default, not a colour table, is the likely cause of the 2,294 K
     against 717 M split, when real M dwarfs dominate.
   - The GCNS path (medium and large tiers, never committed) has its own
     BP−RP threshold table (lines 280–288). It is miscalibrated: it puts the
     K/G boundary at 0.8, so the Sun (0.823) is "K", while the Mamajek table
     in `sunholo/relativity` 0.2.0 starts K0V at 0.983 and M0V at 1.84.
   - The GCNS path computes BP−RP (line 249) and then does not write it out
     (lines 262–270).
   - The GCNS path writes only Gaia G (`gmag`). The loader reads `vmag`, so a
     GCNS tier could not load at all. The old claim that "G is used as V"
     was wrong for the shipped data, which carries catalogue V.
2. **3,802 stars out to 204 ly (median 63 ly; 566 within 40 ly), and a black
   background.** (The earlier "within about 40 ly" was wrong; row V6.)
   - The design docs ask for about 100k visible stars (GCNS has 331,312 within
     100 pc) and a Milky Way.
   - At 0.99c, aberration pulls the entire forward hemisphere into a cone about
     8° wide. With only nearby stars that cone looks sparse, and there is no
     diffuse glow to shift colour.
3. **Motion is along one axis and the camera only yaws.** The velocity is the
   constant `HEADING := Vector3(0, 0, -1)` (`main.gd:11`). The golden run
   passes only that (`main.gd:193`) and sets only yaw (`main.gd:189`). The CPU
   tests use `fwd = (0, 0, −1)` as the only velocity (`tests/test_physics.gd:23`).
4. **Exposure is a hand-tuned constant (`EXPOSURE := 5.0`, `main.gd:12`).**
   Brightness has no physical anchor, so "how many stars can you see" is
   arbitrary.
5. **The bright naked-eye stars beyond 100 pc are in no layer.** GCNS stops at
   100 pc and CNS5 at 25 pc. Many of the brightest stars in the sky are
   farther away than that: Rigel, Deneb, Betelgeuse, Antares, Spica and
   others. Option A of M1.4a would mask them out of the panorama, and
   Option B never had them. Either way they vanish, and AC8 and the β = 0
   renders of AC9 would describe a sky with missing constellations. No
   bright-star catalogue is in the current source list (row V14). The fix is
   **proposed**, not committed: M1.2d and open question 5.

## Goals

- **G1.** Continuous stellar temperatures from Gaia photometry, and visual
  magnitudes converted from Gaia G. The conversions live in
  `sunholo/relativity` and are tested.
- **G2.** The GCNS catalogue (331k stars) renders at 60 fps at 1440p on M4 Max,
  together with the background.
- **G3.** A diffuse Milky Way background, with per-pixel inverse aberration and
  a Doppler colour and brightness shift from a per-texel spectral model. Point
  sources are not counted twice.
- **G4.** Free camera orientation and any velocity direction, with golden tests
  off-axis.
- **G5.** Photometric exposure: stars in lux and background in cd/m². Auto
  exposure that the player can clamp. The naked-eye limiting magnitude falls out
  of the physics.
- **G6.** Reference renders and golden tests in CI wherever a GPU isn't needed,
  and in `make golden` wherever it is.

**Non-goals:**
- Gravitational lensing (M3).
- Planets and nearby 3D objects, including Terrell rotation (M4 or later).
- Proper motion over deep time (M2, with the world clock).
- Interstellar extinction and reddening (a stretch item; see open questions).

## Design

### M1.1 Photometry in `sunholo/relativity` 0.2 (package first)

A new `photometry` module:

- **`teffFromBpRp(bpRp)`:** effective temperature by monotone interpolation of
  the Pecaut & Mamajek *Modern Mean Dwarf Stellar Color and Effective
  Temperature Sequence* (the version with the Gaia BP−RP column).
  - It covers B9V to M8.5V in BP−RP. *(Amended 2026-09-27, mission
    iteration 0: the table's BP−RP column has no O, B0–B8 or L rows, and
    M9V/M9.5V are dropped because their BP−RP reverses.)*
  - It's a table, not a polynomial, so it doesn't diverge outside its range.
    Outside the table, values clamp and a flag says so.
- **`gMinusV(bpRp)`:** from the **same Mamajek table**, which has a `G-V`
  column (G2V: Teff 5770, Bp−Rp 0.823, G−V −0.165; checked 2026-09-27). One
  source for both relations keeps them consistent. The Gaia DR3 cubic
  (Riello et al. 2021) is a *test-only* cross-check: the two must agree within
  0.05 mag over 0.4 ≤ BP−RP ≤ 3.0. *(Amended 2026-09-27, mission
  iteration 0: measured on the source data the two differ by 0.1015 mag at
  BP−RP 3.0, so the check is 0.11 mag over 0.4–3.0 and 0.05 mag over
  0.4–1.3. It guards transcription; it is not a physics bound.)*
- **`illuminanceFromV(v)`:** E = 10^(−0.4 (V + 13.98)) lux, so V = 0 gives
  about 2.5 µlx.
- **White dwarfs** (GCNS `WDprob > 0.5`): the dwarf sequence doesn't apply.
  The first version uses a blackbody temperature fitted to the source's BP−RP
  using approximate Gaia passbands, and marks the result as approximate. This
  is an open item (see below).

Tests cover known stars from the catalogue:

| Star | Class | Expected T_eff |
|---|---|---|
| Sun (BP−RP 0.82) | G2V | ~5770 K |
| Sirius A | A1V | ~9900 K |
| Proxima Centauri | M5.5V | ~3000 K |
| α Cen B | K1V | ~5200 K |
| Barnard's Star | M4V | ~3200 K |

Each must agree within 5% (colour-based temperatures scatter by about 2–3%).
Then `ailang pkg quality` with no gates, and publish 0.2.0.

### M1.2 Catalogue pipeline v2 (an AILANG stress test, with a Python fallback)

```
data/raw/ (gitignored)                    data/starmap/ (quick + medium committed; large built locally)
  CNS5  VizieR J/A+A/670/A19 cns5.dat (5,909 stars, G/BP/RP)
  GCNS  VizieR J/A+A/649/A6 table1c (331,312 stars, 75 MB)
                                ──►  tools/extract.py  ──►  compact CSV
                                        (parse only)          id,x,y,z,G,BP-RP,wd
                                                                  │
                                     sim/tools/catalogue.ail  ◄───┘
                                     (VM, pure transform +
                                      sunholo/relativity photometry)
                                                                  │
                                      stars_<tier>.bin  ◄─────────┘
                                      little-endian float32 records:
                                      x,y,z (ly, galactic), teff, v, flags
                                      + a JSON header (tier, count, source, version, checksums)
```

- **Python only parses.** It turns VOTable and fixed-width files into a compact
  CSV and does no physics.
- **AILANG does all the physics conversion,** so there is one copy of the maths.
  331k rows is a real VM workload: a long list or array transform with float
  maths. Measure it:
  - on the VM vs the interpreter, and check parity (`cmp` of the outputs);
  - how long it takes;
  - whether any call goes through the interpreter bridge.

  Report anything odd upstream.
- **Fallback:** if the AILANG path takes more than about 60 s or hits a VM bug
  that blocks it, add a CPU cross-check that runs the package on 1,000 sampled
  rows, and do the conversion in Python from a table the package exports.
  Record which path shipped.
- **Missing photometry** (quorum round 2, oc-glm-5-3's fix, verbatim): A
  row with null BP-RP or G is never defaulted. It carries flags bit
  MISSING_PHOT with teff = 0 and v = +99; the medium-tier 50,000-nearest
  rule extends past such rows to the next star with complete photometry;
  `tools/catalogue_stats.py` reports the per-tier excluded count; AC2 gains:
  and stats reports zero rows with defaulted photometry inside the tier.
- **Binary format:** 331k × 24 B ≈ 8 MB, loaded with
  `FileAccess.get_buffer` → `PackedFloat32Array`. JSON stays for CNS5 only
  (human-readable, used by tests).
- **Sources** (checked 2026-09-27): CNS5 from VizieR `J/A+A/670/A19`. The Gaia
  Sky URL in the old skill returns 404; the `starmap-manager` scripts get fixed
  in this milestone. The old quick parser reads a column layout (B1950
  coordinates, `Sp`, `Vmag`, `B−V`; `process_stars.sh:149–150`) that doesn't
  look like CNS5's Gaia G/BP/RP columns, and it yields 3,802 rows rather than
  5,909. M1.2 rebuilds the quick tier from the VizieR table, so the question of
  which file was parsed goes away.
- **Tiers** are defined here, not in the skill:
  - quick = CNS5 (≈5.9k)
  - medium = **the 50,000 nearest GCNS members** by distance, white dwarfs
    included and flagged (M1 default). *Changed 2026-09-28.* Today the skill
    keeps the first 50,000 non-white-dwarf rows in file order whose
    miscalibrated letter is G, K or M (`process_stars.sh:253,309–310`). That
    is not a volume, so AC3 would test an arbitrary selection. With a volume
    limit, AC3 (M dwarfs at least 60%) checks real demographics. **AC3 depends
    on this definition.**
  - large = full GCNS (331k)
- **Disposition of `process_stars.sh`:** superseded by `tools/extract.py` +
  `sim/tools/catalogue.ail`, and **removed in M1.2**. The `starmap-manager`
  skill then documents only the download scripts plus
  `make catalogue TIER=…`, with the tier table above. `download_stars.sh` gets
  the fixed URLs. `status.sh` reads the binary headers. This work is budgeted
  in the M1.2 row (+80 LOC).

**M1.2d, bright tier (ACCEPTED 2026-09-28, decision D-5: “Yes I accept those
stars”; committed scope).**
- **Source:** Hipparcos, new reduction (HIP2, van Leeuwen 2007, VizieR
  `I/311`), with `V < 7`, parallax > 0, and **not** matched to a GCNS or CNS5
  source. The match is by position within 1″ after propagating proper motion
  to the Gaia epoch, plus magnitude. That leaves roughly the few thousand
  bright stars beyond 100 pc.
- **Format and physics:** the same record format and binary file
  (`stars_bright.bin`), always loaded on top of whichever tier is active.
  - Hipparcos gives B−V, not BP−RP, so T_eff and V need a B−V relation. The
    rule is package first: `teffFromBV` goes into `sunholo/relativity`, using
    the B−V column of the same Mamajek table (next free minor: 0.4.0 went to M2.0, Mark 2026-10-01).
  - Distances beyond ~500 pc have large parallax errors. The direction is
    exact, and only the parallax (1/r²) rescale during travel is affected.
    The flux at Sol is V itself, not 1/r².
- **Check:** AC11 (drafted below).

**My recommendation:** accept M1.2d. Without it, M1's β = 0 sky has no Orion,
and the pillar "Grounded Strangeness" needs the familiar sky to be right
before it can be made strange.

### M1.3 Star rendering v2

- **Loader:** reads the binary tier. The instance custom data carries
  (T_eff, the V-band illuminance at Sol, a flags byte).
- **Distance:** positions are rebased on the ship every time it moves more than
  0.01 ly, keeping the inverse-square rescale from M0. When the ship moves, the
  CPU instance update for 331k stars must take under 4 ms. If it doesn't, move
  the rebasing into the vertex shader: pass the ship position as a uniform and
  compute the direction and 1/r² per vertex.
- **Brightness:** the splat energy is proportional to E_v (lux) ×
  `pointFluxRatio(T, D)`. The PSF sigma stays at 0.9 px, a stand-in for the
  eye's or camera's point-spread.
- **White-dwarf consumer contract (M1.2b-WD, package `sunholo/relativity`
  0.3.0 `blackbody_photometry`).** For a row with `wd = 1` and G and BP−RP
  both present: `teff = bbTeffFromBpRp(bprp)` (never computed in
  `catalogue.ail`), `v = bbVFromG(g, bprp)`, `flags = 1 (WD) | 4 (APPROX_TEFF)
  | (if bbBpRpInvertible(bprp) then 0 else 16)`. Bit 16 is `TEFF_CLAMPED`; it
  is also set on dwarf rows where `bpRpInTable` is false. `checkWDRow`: 0.30
  gives teff 8941.61808557, v = G + 0.064716662329, flags = 5; 2.5 gives teff
  3000.0, flags = 21. NaN BP−RP clamps to 3000 K and is not invertible. The
  Python fallback must reproduce these through the package's generated table,
  never a second physics copy.
- **Obligation O-1 (white-dwarf temperature range).** Raise `LUT_T_MAX` to at
  least 4.5 × 10⁶ K (proposed 10⁷ K, `LUT_SIZE` 1024 → 1320), extend the
  finite-LUT test, and add a 60 kK / D = 44.7 golden case. The 0.999c
  reference renders (AC9) must not be accepted before O-1 lands. M1.2d's
  bright tier must re-run the C3 saturation analysis when it lands (row C4).
- **UI acceptance (D-4 "and UI").** The first per-star temperature UI labels
  rows with flag bit 4 as "approximate (white dwarf, blackbody)". No UI
  exists yet.
- **Unchanged from M0:** the aberration and Doppler maths. The shader stays a
  mirror of the package's `optics`, and the golden tests enforce that.

### M1.4 Milky Way background

**M1.4a, data spike (research, timeboxed to 1 day). Pick the diffuse source:**
- **Option A:** an existing all-sky panorama (NOIRLab `noirlab2430b`, which the
  old repo used) with point sources removed offline. The masking rule is an
  explicit cross-match (*replaced 2026-09-28*; the old wording was "sources
  brighter than about 1.5 mag below the catalogue limit"):
  - Detect the point sources in the panorama.
  - Mask and inpaint (median filter) **only** the sources matched, by
    position and magnitude, to a star in the point-source layers that ship:
    the active GCNS tier, CNS5, and HIP2 if M1.2d is accepted.
  - **Unmatched sources stay in the panorama.** No star is dropped from both
    layers, and no star is drawn twice.
  - Without M1.2d, the bright stars beyond 100 pc stay as panorama pixels.
    They then aberrate and Doppler-shift per texel, with the background's
    colour model, not as splats.
- **Option B:** a star-free diffuse model built from Gaia source-density maps
  plus a dust map (Planck or SFD) for dark lanes.

The deliverable is a comparison render and a recommendation. **This is a
decision point for the user.**

**M1.4a outcome (attended, 2026-10-01): Option A on NOIRLab (D-10).** The
evidence is in [m1-4a-background-options.md](m1-4a-background-options.md).
Option B wasn't built: Mark ruled for the real photograph, and the Gaia flux
map, the nearest stand-in for B, has no nebulae and is made of stars. Facts
the spike established, which bind M1.4b/c:
- **Registration.** The panorama is plain galactic equirect: l = 0 at the
  centre, l increasing to the left. The 25 brightest HIP stars sit within
  about 1 px of their catalogue positions, so no fit is needed.
- **Tone curve.** The source is tone-mapped 8-bit sRGB, not linear radiance.
  M1.4b decodes sRGB and states that assumption. Fitting T_c to the
  photographer's curve is the dominant error in L_v, more than the blackbody
  approximation.
- **Emission nebulae.** H II regions (H-α at 656 nm) aren't thermal. A line
  leaves the visible band at D ≳ 1.7 (656/D < 380 nm) or D ≲ 0.84 (656/D > 780 nm), so a
  blackbody T_c brightens it ahead of the ship, where it should vanish. M1.4b
  flags line-dominated texels, defined as red excess over the best-fit Planck
  colour, and reports their count. Modelling the line is an escalation, not
  M1 scope.
- **Parallax validity.** A single panorama holds to about 50 ly from Sol.
  Beyond that, the nearest dust clouds (about 450 ly) shift by more than 6°.
  R1 (α Cen) is well inside. Longer voyages need a fade or guard, or a 3D
  diffuse model, which is post-R1.

**M1.4b, spectral model (offline, `tools/sky_model.py`):**
- For each texel of the chosen equirect (HEALPix is an option), fit a blackbody
  colour temperature T_c to its linear RGB, and store (log T_c, log L_v) in a
  float texture.
- This is honest about its limits: integrated starlight isn't a single
  blackbody. But composite stellar light is close enough that a colour
  temperature plus luminance reproduces the Doppler colour shift to first order,
  and it's the same model the stars use.
- The fit residual is recorded per texel and summarised in the M1 report.

**M1.4b/c as built (attended, 2026-10-01). Amends the two blocks below:**
- **The fitter is AILANG, not Python** (Mark: "this is an ailang showcase").
  `sim/tools/sky_model.ail` fits each distinct panorama colour (739,609) to the
  locus straight from `sunholo/relativity` `blackbody.chromaticity`, so no
  Planck/CMF copy exists outside the package. Its pure core is strict-VM gated,
  with interpreter parity (`make sky-vm`, in `make test`). Godot headless does the
  image I/O (`tools/sky_colours.gd`). `make sky-model` runs the whole chain in
  about 12 minutes. The core is list-only, because `std/array` and
  `std/list.range` are evaluator-only on the strict VM (reported upstream).
- **Storage.** A 10k float (log T_c, log L_v) texture would be about 400 MB. The
  model is instead an RGBA8 texture beside the 8-bit photo:
  - R is the T_c code, log-spaced over 1500–30000 K (≤0.6% per step);
  - G is the residual;
  - B is the line flag.

  The shader takes L_v from the decoded photo, and nothing is lost relative to
  the 8-bit source.
- **Tint carry.** The shader computes radiance = Y × surfaceBrightnessRatio(T_c, D)
  × rgb(D·T_c) × tint, where tint = photo / (Y·rgb(T_c)). At D = 1 this
  reproduces the photo exactly, off-locus colours included. For a Planck texel
  it is exactly the design's formula (AC6 tests that path).
- **Result** (`data/sky/sky_model_report.json`):
  - luminance-weighted median Δxy 0.0050, so no escalation;
  - 4.7% of the light is line-flagged;
  - light-weighted T_c median 6180 K. That is the photographer's white
    balance, not a measurement of integrated starlight.

**Frame (D-28, 2026-10-03).** Galactic → Godot world is the rotation
`(x, y, z) → (−y, z, −x)`, defined once in `sky/sky_frame.gd` and
`sky/sky_frame.gdshaderinc`. M1 shipped with `(y, z, −x)`, a mirror; see
[sky-frame-d28](../../implemented/r1/sky-frame-d28.md).

**M1.4c, sky shader (Godot `shader_type sky`):**
- Per pixel, take the view direction n' (EYEDIR), then:
  1. n = deaberrate(n', β) gives the galaxy-frame direction;
  2. sample (T_c, L_v) at n;
  3. D = dopplerApparent(n', β);
  4. radiance = L_v × `surfaceBrightnessRatio(T_c, D)`;
  5. colour = rgb(D·T_c).
- The same lookup-table texture as the stars. It's float, finite and monotonic,
  and tested.
- The background brightness scale comes from the calibration in M1.5, not a
  hand constant.

### M1.5 Photometric exposure

- **Scene units:**
  - star splats integrate to their illuminance in lux;
  - the background is luminance in cd/m², calibrated so a dark-sky patch reads
    about 22 mag/arcsec² (about 1.7×10⁻⁴ cd/m²).
- **Camera:** EV-based exposure. Auto exposure uses the log-average scene
  luminance, and the player can clamp the range and set a bias.
- **Consequence:** at a dark-adapted naked-eye setting, the faintest visible
  star comes out of the maths (about V 6–6.5). At 0.99c ahead of the ship,
  stars far below that limit become visible because of D and the band shift.
  That's the physics, not a tuning choice.
- **"Readability" aids** (the open question in the vision docs) are explicit,
  labelled settings: a magnitude floor and an exposure bias. **They are off by
  default.**

### M1.6 Free motion and orientation

**M1 limitation (unchanged):** the heading can only change at rest. Full
vector velocity with non-collinear acceleration (Thomas–Wigner rotation) is
M2 work.

**Current state and conflict surface** (at `aabb82d`; rows V9–V13, V16–V18):

| Thing | Today | M1.6 does |
|---|---|---|
| `Motion` (`sunholo/relativity` 0.2.0 `kinematics.ail:17`) | `{ phi, tau, t, x }`, 1-D along the heading | Reused unchanged. No package change. |
| `Vec3`, `norm`, `normalize` (`optics.ail:19–27`) | `optics` already takes 3-D direction vectors and a unit velocity direction (`doppler(n, bh, phi)`, `aberrate`, `deaberrate`) | Reused for the heading. No new maths. |
| `Ship` (`sim/core.ail:9`) | `{ tick, motion }` | Gains `heading: Vec3`, `origin: Vec3`, `x0: float` |
| `step` (`core.ail:14`) | `step(s, thrust, dtau)`, `requires dtau >= 0` | Signature unchanged. A new pure `turn(s, h) -> TurnResult` handles heading changes. |
| `scripted` (`core.ail:30`), the `make strict` entry | Returns total galaxy time; closed form `2 sinh(gT)/g` | Unchanged. A new `scriptedOffAxis` entry is added beside it. |
| Codec (`sim/ship.ail`) | `std/json`: `decode`, `getNumber`, `getString`, `encode`, `jo`, `kv`, `jnum`, `jint`. An unknown `cmd` or a line that won't decode **ends the loop** (`ship.ail:31,40`). | Still `std/json`. Adds `get` (nested object) and a `JObject` for `heading`/`pos`. **No hand-written codec.** |
| `SimBridge` (`bridge/sim_bridge.gd:100,115`) | Sends `step`, parses each line into the `state` dictionary; extra keys are harmless | Sends `hello` on start and an optional `heading` on `step` |
| `main.gd` | `HEADING` constant (`:11`); position from `s["x"]` (`:77`); golden and capture use `HEADING` | Reads `heading` and `pos` from the state |
| `tests/test_sim_bridge.gd` | v1.0 closed-form checks, `step` messages only | Stays **unmodified** as the compatibility test; new cases go in a new function |
| `make parity` input (`Makefile`) | 600 v1.0 `step` lines + `quit` | Unchanged (v1.0 compatibility). A new `parity-offaxis` target is added to `make test`. |
| Exported build (`_unpack_runtime`, `make runtime`) | Copies `res://sim` together with pinned ailang `v0.45.0` | Sim and client always ship together. `export-smoke` must pass. |

**No AILANG language or core change is needed.** Everything used exists
today: records, `std/json` (`get`, `getNumber`), `optics.Vec3`. One caveat:
`get` on a nested object was probed on the local v0.47 toolchain (row V17).
The exported build pins v0.45.0, so the first M1.6 task re-runs that probe
with `runtime/bin/ailang`. If `get` is missing there, bump `AILANG_RELEASE`
(a Makefile change, not a language change).

**Protocol v1.1.**
- `{"cmd":"hello"}` → `{"proto":"1.1", …state}`. `SimBridge.start()` sends
  it first and refuses to run unless `proto` is at least 1.1. Sent to a v1.0
  sim, `hello` would end the process (unknown command). The bridge sees EOF
  and fails with a clear error. That can only happen with a mismatched dev
  checkout, since the sim and the client ship together.
- **Bounded waits** (quorum round 2, gpt6-astra's fix, verbatim): Reuse
  existing bridge deadline and cleanup machinery where verified; otherwise
  implement it in SimBridge, without AILANG core changes. The hello response
  must arrive within 5 seconds of process launch, and each step response
  within 2 seconds of sending the command, measured with a monotonic clock.
  On timeout, stop simulation advancement, report an explicit
  `startup_timeout` or `step_timeout`, and terminate the child; allow at most
  1 second for graceful exit before forced termination. Never silently retry,
  downgrade the protocol, or substitute state. (V19: `SimBridge` has no
  deadline or cleanup machinery today, so M1.6 implements it. AC12 tests use
  children that stay alive without responding, emit an incomplete line, and
  ignore graceful shutdown, and assert bounded failure and cleanup.)
- **v1.0 messages stay valid.** A `step` without `heading` behaves exactly as
  in v1.0. Every state line keeps the v1.0 fields (`tick`, `beta`, `gamma`,
  `tau`, `t`, `x`) with the same meaning and adds three new ones:
  - `heading{x,y,z}`;
  - `pos{x,y,z}` (galactic ly);
  - `status`: `"ok"` or a reason code.

  `x` stays the cumulative 1-D coordinate along the path, so the v1.0 closed
  forms still hold for a single leg.
- **Line handling:**
  - An empty line (what `readLine` returns at EOF; M1.6 confirms this) and
    `quit` end the loop, as today.
  - A non-empty line that won't decode gets `status:"bad_json"` with the
    state unchanged. It no longer kills the sim.
  - An unknown `cmd` gets `status:"bad_cmd"`.

**`step` semantics.** The rules apply in this order. The first failure
rejects the whole command.

| Condition | Reason code |
|---|---|
| `thrust` or `dtau` present but not a finite number; `|thrust| > 1`; `dtau < 0` (today a contract failure) | `bad_step` |
| `heading` present, but not an object with three finite numbers `x`, `y`, `z` | `bad_heading` |
| `heading` supplied with `abs(‖h‖ − 1) > 1e-9` | `bad_heading` |
| `heading` differs from the current heading (any component by more than 1e-9) while β ≥ 1e-9 | `moving` |

- **Omitted heading:** the current heading is kept.
- **Missing `thrust` or `dtau`:** they default to 0, as in v1.0.
- **Finite:** the value equals itself and its magnitude is at most
  1.0e308. `std/json` treats `NaN` as a decode error (row V17). Since AILANG
  v0.52.0 it also refuses out-of-range literals such as `1e400` (`bad_json`);
  v0.51.0 decoded them to a non-finite value, refused per field.
- **Why 1e-9 for the norm:** the client must normalise in **float64
  scalars**, not with `Vector3.normalized()`. Godot's `Vector3` is float32,
  and its normalisation error of about 6e-8 would be rejected, which is the
  intent (CLAUDE.md precision rule). A float64 normalisation is good to about
  1e-16, so 1e-9 leaves seven orders of margin while still rejecting real
  mistakes. After accepting a heading, the sim divides it by its norm again,
  so the stored heading is unit to within rounding.
- **What a rejection does:** tick, motion, heading and position are all
  unchanged. The reply is the full current state with `status` set to the
  code. Re-sending the current heading while moving is accepted as a no-op.
- **An accepted change at rest** sets `origin := pos`, `x0 := motion.x`,
  `heading := h`, and snaps `motion.phi` to exactly 0. The velocity it
  discards is below 1e-9 c. After the turn, the step's thrust is applied.

**Position.** `pos = origin + heading × (motion.x − x0)`, in float64.
- Between turns, every step accelerates along a single axis, so the ship's
  displacement is exactly `heading × Δx`. Since a turn only happens at rest
  (φ snapped to 0), no transverse velocity is ever carried across a turn, and
  the formula is exact up to float rounding.
- Without the snap, a residual β < 1e-9 would move the ship at most 1e-9 ly
  per galaxy year along the wrong axis. The snap removes that error, and it
  is deterministic.

**Tests (all in `make test`, so AC10 and AC12):**
- **Codec round trip** (`test_sim_bridge.gd`, new function): state encode →
  GDScript parse → the values equal the sim's to the bit (`%.17g`). Send
  `heading`, then echo it back.
- **Old-message compatibility:**
  - the existing v1.0 test runs unmodified and green;
  - `make parity` keeps its v1.0 input.
- **Invalid inputs:** one case per reason code. Examples: heading
  `{x:1,y:0}`, `{x:1e400,…}`, a norm of 1 + 1e-8, `NaN` text, `dtau:-1`,
  `thrust:2`, `cmd:"warp"`. Each asserts the reason code and a
  byte-identical state apart from `status`.
- **Rejected update:** accelerate to 0.5c, send heading +X, get `moving`, and
  check that the state is unchanged. Then decelerate to rest, send +X again,
  and check it's accepted.
- **Deterministic off-axis parity** (`make parity-offaxis`): a scripted
  NDJSON file that mixes `hello`, turns, burns and every reject case. The VM
  output and the interpreter output are compared with `cmp`.
- **`make strict` stays green.** It keeps the existing `scripted` check and
  adds `scriptedOffAxis(n)`, under `--strict-bytecode`, compared against the
  interpreter and a closed form:
  - leg 1 along +X accelerates n ticks and decelerates n ticks, at
    dtau = 0.01;
  - turn at rest to +Y;
  - leg 2 repeats leg 1.
  - With T = n × 0.01 and D = 2(cosh(gT) − 1)/g, the result is
    `pos = (D, D, 0)`, and the entry returns `‖pos‖ = √2·D`, within 1e-9.

**Godot:** a free-look camera (yaw, pitch and roll), independent of the
velocity direction. The HUD shows the angle between the view and the
velocity. The camera orientation is client state and never goes to the sim.

## Acceptance criteria (all checkable by command)

| # | Criterion | Check |
|---|---|---|
| AC1 | `sunholo/relativity@0.2.0` is published with `photometry`: known-star T_eff within 5%, G−V cross-checked against published values, `pkg quality` with no gates | `ailang pkg info sunholo/relativity`; the package tests |
| AC2 | The pipeline produces the quick/medium/large tiers; the VM run matches the interpreter bit for bit on the medium tier; runtime and bridged calls are recorded; and stats reports zero rows with defaulted photometry inside the tier | `make catalogue TIER=medium && make catalogue-parity && tools/catalogue_stats.py` |
| AC3 | The share of M dwarfs in the medium tier (the 50,000 nearest GCNS members, as defined in M1.2) is at least 60% (sanity check against known stellar demographics) | `tools/catalogue_stats.py --tier medium` |
| AC4 | Every spec §2 check value passes on the CPU, now also with off-axis velocity (±X, ±Y, and a (1,1,−1)/√3 direction) and a rolled camera | `make test` |
| AC5 | GPU golden: synthetic stars at 12 directions × 4 speeds × 3 camera orientations land within 0.75 px of the reference. A background texel marker lands within 1 px of `deaberrate`'s prediction | `make golden` |
| AC6 | GPU colour golden: with a linear tonemapper, a synthetic star's rendered chromaticity is within 0.01 of rgb(D·T) at D ∈ {0.3, 1, 3} | `make golden` |
| AC7 | Frame time: 60 fps at 2560×1440 with the large tier plus the background on M4 Max; p99 frame time under 16.7 ms over a 30 s scripted flight | `make bench` |
| AC8 | Naked-eye limiting magnitude at the default dark-adapted exposure is between 6.0 and 6.8 | `make bench` report |
| AC9 | Reference renders at 0, 0.5, 0.9, 0.99 and 0.999c × forward, starboard and astern are committed, and reviewed by a human in the M1 report | `make capture` |
| AC10 | `make test` is green in CI; the pure simulation core still passes `--strict-bytecode`; the parity check still passes | GitHub Actions `CI` |
| AC11 | *Accepted 2026-09-28 per decision D-5.* At β = 0, at least 95% of HIP2 stars with V < 2.5 are rendered within 1 px of their predicted position; the number of rendered stars brighter than V = 6.5 is between 5,000 and 9,100 (Bright Star Catalogue range) | `make capture && tools/bright_star_audit.py renders/` |
| AC12 | Protocol v1.1: `hello` answers `proto` 1.1; the unmodified v1.0 bridge test passes; each reason code (`bad_json`, `bad_cmd`, `bad_step`, `bad_heading`, `moving`) leaves the state unchanged; a silent, a truncated-line and a shutdown-ignoring child each fail with `startup_timeout`/`step_timeout` within the stated bounds and leave no child process; the off-axis NDJSON script is bit-identical on the VM and the interpreter; `scriptedOffAxis` matches √2·D within 1e-9 under `--strict-bytecode` | `make sim parity parity-offaxis strict` |

## Sub-milestones and estimates

| ID | Scope | LOC (code + tests) | Depends on |
|---|---|---|---|
| M1.1 | Package `photometry` 0.2.0 | 250 + 250 | — |
| M1.2 | Catalogue pipeline v2 plus AILANG transform, parity and benchmark; `process_stars.sh` removed and `starmap-manager` scripts and skill fixed (+80) | 430 + 150 | M1.1 |
| M1.2d | ACCEPTED (D-5, 2026-09-28): HIP2 bright tier, GCNS cross-match, `teffFromBV` in the package (next free minor; 0.4.0 went to M2.0 on 2026-10-01), AC11 audit | 150 + 100 | M1.2 |
| M1.3 | Star rendering v2 (binary loader, 331k instances, rebasing) | 250 + 150 | M1.2 |
| M1.4 | Background: data spike, spectral model, sky shader | 400 + 200 | M1.1; **user decision after M1.4a** |
| M1.5 | Photometric exposure and bench mode | 150 + 100 | M1.3, M1.4 |
| M1.6 | Free motion and orientation (simulation, protocol v1.1 on `std/json`, reason codes, camera, golden cases, `parity-offaxis`, `scriptedOffAxis`) | 250 + 350 | — (parallel) |
| | **Committed total** (M1.1–M1.6) | **1,730 + 1,200 ≈ 2,930** | |

Suggested order: M1.1 → (M1.2 ∥ M1.6) → [M1.2d] → M1.3 → M1.4 → M1.5.

## Risks

| Risk | Mitigation |
|---|---|
| The AILANG pipeline is slow, or hits VM bugs on 331k rows | That's valuable too: report it upstream with repros. Python fallback with a cross-check, and the path that shipped is recorded |
| Point-source removal leaves artefacts | M1.4a compares options A and B before anything is committed; the residual map is reviewed. Spike result: clean except a faint flat patch at Sirius at 1:1 and a softened M42 core |
| The panorama is only valid near Sol (parallax) | Stated limit: about 50 ly. R1 stays inside it; post-R1 needs a guard or a 3D diffuse model |
| A single colour temperature can't represent the diffuse sky | Record the per-texel fit residual; if the median residual exceeds 0.02 Δxy, escalate to a two-component model in M1.4b |
| Rebasing 331k instances on the CPU is too slow | Plan B is computing directions in the vertex shader; AC7 decides |
| G−V or T_eff tables are mis-transcribed | Known-star tests; cite sources with table versions in the code |
| Bright stars beyond 100 pc are in no layer (Problem 5) | Option A masks only cross-matched sources, so unmatched bright stars stay in the panorama; the full fix is the proposed M1.2d (open question 5). If Option B is chosen, M1.2d becomes necessary |
| The pinned runtime (ailang v0.45.0) lacks a `std/json` function M1.6 uses | First M1.6 task re-runs the V17 probe with `runtime/bin/ailang`; `make export-smoke` gates it |
| The Godot golden image is post-tonemap (8-bit) | Colour golden uses the linear tonemapper and low exposure; positions use a centroid |

## Open questions (for the user)

1. **Background source (after M1.4a):** a star-removed panorama (A), or a
   synthetic diffuse model (B)? **ANSWERED 2026-10-01, D-10: A, on the NOIRLab
   `noirlab2430b` panorama** (Mark Edmondson, attended: "ok lets go with
   NOIRlab").
2. **Interstellar reddening:** apply E(BP−RP) from a 3D dust map to nearby
   stars? It's negligible within 100 pc (under 0.05 mag for most stars).
   Proposal: skip it in M1 and revisit for the distant background.
3. **White dwarfs:** is an approximate blackbody fit acceptable in M1 (they're
   faint, so it rarely shows)? Or is a proper Gaia-passband model worth a
   package item?
4. **Default exposure:** dark-adapted naked eye (physically faithful), or a
   camera-like setting? Either way it's a labelled setting.
5. **Bright-star tier (new, 2026-09-28). ANSWERED 2026-09-28, D-5: ACCEPTED
   (Mark Edmondson, attended: “Yes I accept those stars”).** Original
   question text kept for the record: accept the proposed M1.2d, a
   Hipparcos (HIP2, `I/311`) tier for stars with V < 7 that aren't in GCNS or
   CNS5, together with AC11 and `teffFromBV` in `sunholo/relativity` (next free minor; 0.4.0 went to M2.0 on 2026-10-01)
   (about +250 LOC)? Without it, stars like Rigel and Deneb exist only as
   panorama pixels (Option A) or not at all (Option B). **Recommendation:
   accept.** And if you pick Option B in question 1, treat M1.2d as required.

## Deliverables

- Package: `sunholo/relativity@0.2.0`.
- Game: `tools/extract.py`, `sim/tools/catalogue.ail`, the binary star tiers,
  loader and shader updates, `sky/background.gdshader`, `tools/sky_model.py`,
  exposure and bench mode, the simulation protocol v1.1 (`hello`, `heading`,
  `pos`, `status`), `make parity-offaxis`, and new tests and golden cases.
  `process_stars.sh` is removed.
- Report: `design_docs/implemented/r1/m1-report.md`, covering reference
  renders, bench numbers, pipeline VM measurements and upstream AILANG reports.

## Verification log

All rows were run on 2026-09-28 in the M1.6 worktree at
`aabb82ded3cb4943dd7e385730566c39ade5ac64` (`git rev-parse HEAD`), with the
local toolchain at AILANG v0.47.0-2 and `sunholo/relativity` 0.2.0 from the
package cache (`R=~/.ailang/cache/registry/sunholo/relativity/0.2.0`,
`S=.claude/skills/starmap-manager/scripts`). Output is trimmed. Negative
results are paired with a positive control.

| # | Claim | Command | Observed | Verdict |
|---|---|---|---|---|
| V1 | The committed catalogue has 3,802 stars, split 2,294 K to 717 M | `python3 -c` over `data/starmap/stars.json`: `len`, `Counter(spectral)` | `3802`; `K 2294, M 717, G 458, F 258, A 72, B 3`; header `source: cns5` | True |
| V2 | The letter comes from a miscalibrated BP−RP table | `grep -n "spectral =\|'K'" $S/process_stars.sh`; lookup of `Gl 551` in `stars.json` | quick path: `:158 … if cells[7].strip() else 'K'`, `:202 … else 'K'`; Proxima `Gl 551 … spectral 'K'` | **False for the committed data**: that came from the `Sp` column with a default of "K". Problem 1 corrected |
| V3 | The BP−RP table is miscalibrated (Sun → K) | `sed -n 280,288p $S/process_stars.sh`; `bpRpNodes`/`spectralTypes` from `$R/photometry_table.ail` | `if bp_rp < 0.8: return 'G'` / `< 1.4: 'K'`; package: G2V 0.823, K0V 0.983, M0V 1.84 | True, GCNS path only |
| V4 | The pipeline computes BP−RP and throws it away | `sed -n 249p;262,270p $S/process_stars.sh` | `:249 bp_rp = bp_mag - rp_mag …`; output dict has `id,x,y,z,dist_ly,gmag,spectral` (no `bp_rp`) | True, GCNS path |
| V5 | Brightness uses G as if it were V | `grep -n vmag sky/starfield.gd`; `grep -n "'gmag'\|'vmag'" $S/process_stars.sh` | loader `:26 flux_from_mag(s["vmag"])`; quick path writes `vmag` (`:187`, 10.0 if blank; 10 stars); GCNS path writes only `gmag` | **False as stated.** The shipped data is catalogue V; GCNS output couldn't load. Corrected |
| V6 | 3,802 stars within about 40 ly | `python3`: `max`, median of `dist_ly`, count ≤ 40 | max 203.85, median 62.72, 566 within 40 ly | **False.** Corrected to "out to 204 ly" |
| V7 | `EXPOSURE := 5.0` | `grep -rn EXPOSURE sky main.gd physics tests` | `main.gd:12 const EXPOSURE := 5.0` (used `:33`, `:172`); no hit in `sky/` | True |
| V8 | Golden tests cover velocity along −Z only | `grep -n "HEADING\|set_velocity\|camera.rotation" main.gd`; `grep -n "fwd\|side" tests/test_physics.gd` | `:11 HEADING := Vector3(0, 0, -1)`; golden `:193 set_velocity(HEADING, …)`, `:189 rotation = Vector3(0, yaw, 0)`; star directions vary in XZ (`:188`). CPU: `fwd` (0,0,−1) is the only velocity; `side` is a *source* direction | True (both GPU and CPU) |
| V9 | `Motion` is 1-D | `grep -n "type Motion" $R/kinematics.ail` | `:17 export type Motion = { phi: float, tau: float, t: float, x: float }` | True |
| V10 | Package optics take arbitrary direction vectors | `grep -n "export pure func" $R/optics.ail` | `doppler(n: Vec3, bh: Vec3, phi)`, `aberrate(n, bh, phi) -> Vec3`, `deaberrate(nSeen, bh, phi)`, `normalize`, `norm`; the GDScript mirror `set_velocity(direction, …)` normalises (`starfield.gd:75`) | True: already vectorial, no new maths for G4 |
| V11 | Current sim state, step and codec | `cat sim/core.ail sim/ship.ail` | `Ship = { tick, motion }`; `step(s, thrust, dtau) requires dtau >= 0.0`; `std/json (decode, encode, getNumber, getString, jo, kv, jnum, jint)`; unknown cmd → `"quit"`; `Err(_) => ()` ends the loop | True; conflict surface table |
| V12 | Consumers of the protocol | `grep -rln '"cmd"' . --exclude-dir=.git --exclude-dir=.godot`; `grep -n "sim\.\|\"x\"" main.gd` | `bridge/sim_bridge.gd`, `sim/ship.ail` only; `main.gd` uses `sim.state` (`:74–77`), `sim.step` (`:100,140`); `tests/test_sim_bridge.gd` reads `beta,gamma,t,x` | True |
| V13 | Baselines for strict and parity are green | `make parity`; `make strict` | `parity: identical (601 lines)`; `strict VM 21.392852753780428 \| interpreter 21.392852753780428 \| closed form 21.392852753780602` | True |
| V14 | No bright-star catalogue in the sources | `grep -rlic "hipparcos\|HIP2\|yale" .claude/skills/starmap-manager design_docs`; control `grep -c GCNS $S/download_stars.sh` | only `resources/data_sources.md` (`:73 ### 3. Hipparcos (Alternative)`, a note, not downloaded); control: 13 | True: nothing is downloaded or processed |
| V15 | The medium tier filter | `sed -n 305,315p $S/process_stars.sh`; `grep -n filter $S/download_stars.sh` | `filter_gkm = (tier == 'medium')`, `max_stars = 50000`, stop after 50k in file order; `:63 Filter: G/K/M stars (BP-RP > 0.5) … not white dwarfs` | Not a volume. Redefined in M1.2 |
| V16 | celestial-lod-system has no mechanism in M1 | `grep -n "^#" ../stapledons-design/features/celestial-lod-system.md` | tiers Full3D/Billboard/Circle/Point/Culled; `### 2. Point Batch Rendering` | M1 implements the Point tier only; Implements line narrowed |
| V17 | `std/json` supports nested `heading` without new machinery | `ailang docs std/json`; probe (`/tmp/jprobe/p2.ail`, `get(j,"heading")` then `getNumber(h,"x")`) on VM and interpreter | `get(Json,string) -> Option[Json]` exists; `x=0.6`; no key → `None`; `1e400` → `x=null finite=no`; `NaN` → `err invalid json`; VM = interpreter | True on v0.47; **to be rechecked on pinned v0.45.0** (Risks). A first probe using an `=`-bodied effectful `func` with `match` printed nothing, exit 0; to shrink and report upstream if it reproduces |
| V18 | M0 is done | `sed -n 5,9p CHANGELOG.md` | `### M0 spike, 2026-09-27 (~1,900 LOC including tests)` | True |
| V19 | `SimBridge` has no response deadline or child cleanup (quorum round 2) | `grep -c get_line bridge/sim_bridge.gd` (control); `grep -c -iE "timeout\|deadline\|ticks_msec\|ticks_usec\|OS.kill" bridge/sim_bridge.gd` | control `2`; `0` | True: M1.6 implements the bounded waits |
| V20 | The loader takes temperature from a single spectral letter (quorum round 2) | `sed -n 25p sky/starfield.gd` | `"t": Relativity.temperature_for_class(s["spectral"]),` | True |
| V21 | The design docs ask for about 100k visible stars (quorum round 2) | `grep -rn "100,000" ../stapledons-design/features/` | `celestial-lod-system.md:32 - Galaxy map: ~100,000 stars visible` (not in `starmap-data-model.md`) | True, source corrected |

## Quorum log

**Round 1, 2026-09-28:** reviewers oc-glm-5-3, oc-kimi-k3 and gpt6-astra all
rejected. The revision answers each objection as follows.

- **oc-kimi-k3, unverified codebase premises:** added the verification log.
  V2, V5 and V6 were wrong or overstated, and Problem 1–2 is corrected; the
  rest hold (V1, V3, V4, V7, V8, V18).
- **oc-kimi-k3, celestial-lod-system with no LOD:** scoped to the Point tier,
  with instanced splats and no runtime LOD, justified by AC7 (V16).
- **oc-kimi-k3, `process_stars.sh` disposition and the unbudgeted skill fix:**
  it is removed in M1.2, and the skill and script fix is +80 LOC in the M1.2
  row.
- **gpt6-astra, no inventory or conflict surface for M1.6:** added the
  current-state table (V9–V13), which reuses `std/json` and `Motion`, lists
  every consumer, and states that no AILANG core change is needed (with the
  v0.45 recheck).
- **gpt6-astra, undefined heading semantics and no version policy:** defined
  omission, the finite and norm checks (1e-9), rejection while moving, the
  reason codes, the unchanged state on rejection, `hello`/`proto` 1.1 and
  v1.0 compatibility. Tests are in M1.6 and AC12.
- **oc-glm-5-3, bright stars beyond 100 pc vanish:** stated in Problem 5 and
  Risks. The Option A mask is now a cross-match, so unmatched stars stay in
  the panorama. The HIP2 tier is only **proposed** (M1.2d, AC11), and gated on
  open question 5; it is not committed.
- **oc-glm-5-3, ambiguous masking threshold:** replaced by the cross-match
  rule.
- **oc-glm-5-3, medium-tier filter delegated to the skill (AC3
  undetermined):** stated in the doc as the 50,000 nearest GCNS members, and
  AC3 references it (V15).
- **oc-glm-5-3, verify `process_stars.sh` and vector optics:** V2–V5 and V10.

**Round 2, 2026-09-28:** the same three reviewers all rejected again. None
disputed the design direction, and each gave a concrete fix, so the
controller applied the reviewers' own fixes (the narrow-refinement
carve-out; no third round) and routed M1.6.

- **oc-kimi-k3, external catalogue claims have no rows:** took the
  reviewer's option (b) verbatim for the Evidence line. External counts and
  URLs are re-verified at M1.2 download time. The M1.2 executor directive
  carries kimi's V19–V22 commands as the first M1.2 task.
- **oc-glm-5-3, same class, plus the missing-photometry rule:** the rule is
  applied verbatim in M1.2, and AC2 gains the defaulted-photometry clause. The
  codebase rows glm named are added as V20 and V21. The "100k visible stars"
  line is in `celestial-lod-system.md`, not `starmap-data-model.md`.
- **oc-glm-5-3, V3 circularity (0.2.0 cited from the cache before it was
  published):** refuted by measurement. `ailang pkg info sunholo/relativity`
  returns the published `v0.2.0` (M1.1 landed 2026-09-27, iteration 0), so
  the cache holds the published artifact, not a dev build. No change.
- **gpt6-astra and oc-glm-5-3, unbounded `hello` and step waits:** astra's
  fix is applied verbatim (5 s hello, 2 s step, 1 s graceful exit, explicit
  `startup_timeout`/`step_timeout`), and it supersedes glm's 2 s variant. V19
  shows there is no existing machinery to reuse. AC12 gains the three
  non-responsive-child cases.

## M1.6a toolchain amendment (2026-09-30, iteration 3)

M1.6a was built on the v0.45.0 pin (iteration 1, `966ba3a`) and parked on two
AILANG VM defects, both reproduced first-party and reported upstream:

- **ailang#1354** — `--strict-bytecode` `GET_FIELD` reads the wrong slot when
  two record types share a field name at different positions (`make strict`
  off-axis red).
- **ailang#1355** — `--bytecode` nondeterministic on `parity-offaxis`
  (3 of 6 runs diverged from the interpreter on v0.45.0).

Both were closed as completed 2026-09-28, fixed by upstream PR #1371 and
released in **AILANG v0.47.2**, which this repo pins (CI, bundled runtime,
lockfile; commit `07d44e6`). First-party verification on the v0.47.2 runtime
(iteration 3): `make strict` green including strict off-axis; 30 consecutive
`make parity-offaxis` runs byte-identical (single sha256); full `make test`
rc=0. The V17 recheck ("to be rechecked on pinned v0.45.0") is superseded by
this note: the pin is now v0.47.2, on which the V17 probe's `=`-bodied
effectful `func` form is no longer used by M1.6a's shipped code path.

Evaluator (iteration 1, at `966ba3a` on v0.45.0): 59/100 FAIL, hard-fail only
on the two toolchain reds, both independently attributed to the toolchain.
Evaluator (iteration 3, at `91879a2` on v0.47.2): **87/100 PASS**
(`eval_R1-M1-SKY_M1.6a_iter3.json`).
