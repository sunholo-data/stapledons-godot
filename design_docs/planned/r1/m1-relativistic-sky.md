# M1: The relativistic sky

**Status:** Planned (design, awaiting sprint plan)
**Release:** r1 · **Milestone:** M1 of [R1 foundations](https://github.com/sunholo-data/stapledons-design/blob/main/roadmap/r1-foundations.md)
**Priority:** P0: every later milestone looks through this sky
**Implements:**
- [relativity spec §2](https://github.com/sunholo-data/stapledons-design/blob/main/physics/relativity-spec.md) (special relativity) and §4 (tests)
- [starmap-data-model](https://github.com/sunholo-data/stapledons-design/blob/main/features/phase1-data-models/starmap-data-model.md)
- [celestial-lod-system](https://github.com/sunholo-data/stapledons-design/blob/main/features/celestial-lod-system.md)
- [sr-view-directions](https://github.com/sunholo-data/stapledons-design/blob/main/features/future/sr-view-directions.md)

**Depends on:** M0 spike (done), `sunholo/relativity@0.1.0` (published)
**Estimated:** ~2,600 LOC (≈1,500 code + 1,100 tests/tools), 6 sub-milestones

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

1. **Star colours are guesses.**
   - Temperatures come from a spectral letter, and that letter came from a
     miscalibrated Gaia BP−RP threshold table in the old pipeline
     (`process_stars.sh`). The Sun (BP−RP ≈ 0.82) gets labelled "K", which is
     why the catalogue shows 2,294 K stars against 717 M stars, when real M
     dwarfs dominate.
   - The pipeline computed BP−RP and then threw it away.
   - Brightness uses Gaia G as if it were V.
2. **3,802 stars within about 40 ly and a black background.**
   - The design docs ask for about 100k visible stars (GCNS has 331,312 within
     100 pc) and a Milky Way.
   - At 0.99c, aberration pulls the entire forward hemisphere into a cone about
     8° wide. With only nearby stars that cone looks sparse, and there is no
     diffuse glow to shift colour.
3. **Motion is along one axis and the camera only yaws.** Golden tests cover
   the velocity along −Z only.
4. **Exposure is a hand-tuned constant (`EXPOSURE := 5.0`).** Brightness has
   no physical anchor, so "how many stars can you see" is arbitrary.

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
  - It covers O to L dwarfs.
  - It's a table, not a polynomial, so it doesn't diverge outside its range.
    Outside the table, values clamp and a flag says so.
- **`gMinusV(bpRp)`:** the Gaia DR3 photometric relation G−V as a cubic in
  BP−RP (Riello et al. 2021, Gaia EDR3 documentation §5.5.1). **The exact
  coefficients get checked against the published table during the sprint**
  and recorded with their source in the code.
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
data/raw/ (gitignored)                    data/starmap/ (committed or LFS)
  cns5 VOTable / GCNS table1c   ──►  tools/extract.py  ──►  compact CSV
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
- **Binary format:** 331k × 24 B ≈ 8 MB, loaded with
  `FileAccess.get_buffer` → `PackedFloat32Array`. JSON stays for CNS5 only
  (human-readable, used by tests).
- **Tiers** come from the `starmap-manager` skill:
  - quick = CNS5 (≈5.9k)
  - medium = GCNS filtered to about 50k (M1 default)
  - large = full GCNS (331k)

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
- **Unchanged from M0:** the aberration and Doppler maths. The shader stays a
  mirror of the package's `optics`, and the golden tests enforce that.

### M1.4 Milky Way background

**M1.4a, data spike (research, timeboxed to 1 day). Pick the diffuse source:**
- **Option A:** an existing all-sky panorama (NOIRLab `noirlab2430b`, which the
  old repo used) with point sources removed offline: detect sources brighter
  than about 1.5 mag below the catalogue limit, mask them, and inpaint with a
  median filter.
- **Option B:** a star-free diffuse model built from Gaia source-density maps
  plus a dust map (Planck or SFD) for dark lanes.

The deliverable is a comparison render and a recommendation. **This is a
decision point for the user.**

**M1.4b, spectral model (offline, `tools/sky_model.py`):**
- For each texel of the chosen equirect (HEALPix is an option), fit a blackbody
  colour temperature T_c to its linear RGB, and store (log T_c, log L_v) in a
  float texture.
- This is honest about its limits: integrated starlight isn't a single
  blackbody. But composite stellar light is close enough that a colour
  temperature plus luminance reproduces the Doppler colour shift to first order,
  and it's the same model the stars use.
- The fit residual is recorded per texel and summarised in the M1 report.

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

**Simulation (AILANG `sim/core.ail`):**
- The ship state gains a `heading` unit vector and a 3D galactic position.
  Thrust acts along the heading.
- In M1 the heading can only change while at rest (β < 1e-9). Full vector
  velocity with non-collinear acceleration (Thomas–Wigner rotation) is M2 work.
- **Protocol:** `step` gains `heading` (optional). `state` gains
  `heading{x,y,z}` and `pos{x,y,z}`. Hand-written codecs, with round-trip tests.

**Godot:** a free-look camera (yaw, pitch and roll), independent of the
velocity direction. The HUD shows the angle between the view and the velocity.

## Acceptance criteria (all checkable by command)

| # | Criterion | Check |
|---|---|---|
| AC1 | `sunholo/relativity@0.2.0` is published with `photometry`: known-star T_eff within 5%, G−V cross-checked against published values, `pkg quality` with no gates | `ailang pkg info sunholo/relativity`; the package tests |
| AC2 | The pipeline produces the quick/medium/large tiers; the VM run matches the interpreter bit for bit on the medium tier; runtime and bridged calls are recorded | `make catalogue TIER=medium && make catalogue-parity` |
| AC3 | The share of M dwarfs in the medium tier is at least 60% (sanity check against known stellar demographics) | `tools/catalogue_stats.py` |
| AC4 | Every spec §2 check value passes on the CPU, now also with off-axis velocity (±X, ±Y, and a (1,1,−1)/√3 direction) and a rolled camera | `make test` |
| AC5 | GPU golden: synthetic stars at 12 directions × 4 speeds × 3 camera orientations land within 0.75 px of the reference. A background texel marker lands within 1 px of `deaberrate`'s prediction | `make golden` |
| AC6 | GPU colour golden: with a linear tonemapper, a synthetic star's rendered chromaticity is within 0.01 of rgb(D·T) at D ∈ {0.3, 1, 3} | `make golden` |
| AC7 | Frame time: 60 fps at 2560×1440 with the large tier plus the background on M4 Max; p99 frame time under 16.7 ms over a 30 s scripted flight | `make bench` |
| AC8 | Naked-eye limiting magnitude at the default dark-adapted exposure is between 6.0 and 6.8 | `make bench` report |
| AC9 | Reference renders at 0, 0.5, 0.9, 0.99 and 0.999c × forward, starboard and astern are committed, and reviewed by a human in the M1 report | `make capture` |
| AC10 | `make test` is green in CI; the pure simulation core still passes `--strict-bytecode`; the parity check still passes | GitHub Actions `CI` |

## Sub-milestones and estimates

| ID | Scope | LOC (code + tests) | Depends on |
|---|---|---|---|
| M1.1 | Package `photometry` 0.2.0 | 250 + 250 | — |
| M1.2 | Catalogue pipeline v2 plus AILANG transform, parity and benchmark | 350 + 150 | M1.1 |
| M1.3 | Star rendering v2 (binary loader, 331k instances, rebasing) | 250 + 150 | M1.2 |
| M1.4 | Background: data spike, spectral model, sky shader | 400 + 200 | M1.1; **user decision after M1.4a** |
| M1.5 | Photometric exposure and bench mode | 150 + 100 | M1.3, M1.4 |
| M1.6 | Free motion and orientation (simulation, protocol, camera, golden cases) | 200 + 250 | — (parallel) |

Suggested order: M1.1 → (M1.2 ∥ M1.6) → M1.3 → M1.4 → M1.5.

## Risks

| Risk | Mitigation |
|---|---|
| The AILANG pipeline is slow, or hits VM bugs on 331k rows | That's valuable too: report it upstream with repros. Python fallback with a cross-check, and the path that shipped is recorded |
| Point-source removal leaves artefacts | M1.4a compares options A and B before anything is committed; the residual map is reviewed |
| A single colour temperature can't represent the diffuse sky | Record the per-texel fit residual; if the median residual exceeds 0.02 Δxy, escalate to a two-component model in M1.4b |
| Rebasing 331k instances on the CPU is too slow | Plan B is computing directions in the vertex shader; AC7 decides |
| G−V or T_eff tables are mis-transcribed | Known-star tests; cite sources with table versions in the code |
| The Godot golden image is post-tonemap (8-bit) | Colour golden uses the linear tonemapper and low exposure; positions use a centroid |

## Open questions (for the user)

1. **Background source (after M1.4a):** a star-removed panorama (A), or a
   synthetic diffuse model (B)?
2. **Interstellar reddening:** apply E(BP−RP) from a 3D dust map to nearby
   stars? It's negligible within 100 pc (under 0.05 mag for most stars).
   Proposal: skip it in M1 and revisit for the distant background.
3. **White dwarfs:** is an approximate blackbody fit acceptable in M1 (they're
   faint, so it rarely shows)? Or is a proper Gaia-passband model worth a
   package item?
4. **Default exposure:** dark-adapted naked eye (physically faithful), or a
   camera-like setting? Either way it's a labelled setting.

## Deliverables

- Package: `sunholo/relativity@0.2.0`.
- Game: `tools/extract.py`, `sim/tools/catalogue.ail`, the binary star tiers,
  loader and shader updates, `sky/background.gdshader`, `tools/sky_model.py`,
  exposure and bench mode, the simulation protocol v1.1, and new tests and
  golden cases.
- Report: `design_docs/implemented/r1/m1-report.md`, covering reference
  renders, bench numbers, pipeline VM measurements and upstream AILANG reports.
