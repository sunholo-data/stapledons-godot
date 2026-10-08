# Lightspeed loading view

| Pillar | Alignment | Reason |
|---|---:|---|
| Choices Are Final | 0 | A loading view; no change to commitments. |
| The Game Doesn't Judge | +1 | The overlay says what it is: the speed is illustrative, the optics are the game's renderer; the white-out is labelled in code and here as a transition effect, not physics. |
| Time Has Emotional Weight | 0 | No change to clocks or journeys. |
| The Ship Is Home | +1 | Boarding the ship no longer starts with a 7.9 s frozen frame; the ship arrives out of a jump to 0.99999c. |
| Grounded Strangeness | +2 | The loading screen is the real relativistic sky: aberration, Doppler colour and the starbow from the same `InteriorSky`, at β, γ and 1−β from the `sunholo/relativity` mirror. At 0.99999c it shows what the optics really give: the whole sky crushed into one blinding blue-white point (γ 223.6) with darkness around it. |
| We Are Not Built For This | 0 | No change. |

Net +4: aligned, go.

**Status:** Requested by Mark 2026-10-08 ("when we select something in the menu it takes some time to load - can we get a nice funky loading screen maybe the galaxy going to light speed and when we reach 0.999 its 100%?"; then, attended, "maybe 0.99999 so it goes white?"). Branch `feat/lightspeed-loading`.
**Release:** R1.
**Implements:** the title screen's routes (`design_docs/planned/r1/title-screen.md`). Physics: `stapledons-design/physics/relativity-spec.md` §1 (rapidity φ = atanh β, γ = 1/√(1−β²)) and §2 (aberration, Doppler) at β up to 0.99999, through the existing starfield and background shaders. Formulas: `sunholo/relativity` 0.10.0 `kinematics` (`rapidityOfBeta`, `betaOf`, `gammaOf`, `oneMinusBeta`), mirrored in `physics/relativity.gd`; no new formula.
**Depends on:** `TitleScreen` (its `InteriorSky`), `main.gd` `_on_title_route`, `SimBridge`, `GalaxyMap`, `CaptainAvatar`, `SkyBackground`, `Starfield`, `Blackbody`.
**Estimated LOC:** about 1,000 estimated; about 1,550 added (view 570, prefetch and sharing hooks 300, tests 400, tools 170, doc and changelog).

## Problem

Measured on the Mac Studio (M2 Ultra) at 1280×720 (`make loading-profile`, before this change): pressing a title button froze the title for the whole load, as **one frame**:

| Route | Press → destination ready | Where the time went |
|---|---:|---|
| Board the ship | 7.9 s | galaxy-map star colours 2.5 s (5,098 Blackbody integrals on the main thread), sky panorama 2 × 10k PNG decode + upload 2.1 s (already decoded by the title), star tiers 0.7 s (already loaded by the title), simulation spawn + hello 0.4 s, captain sprites 0.3 s (GPU read-back per sprite), star-occlusion BVHs 0.3 s, collision 0.2 s, rest of the scene build ~1 s |
| Guided voyage | 7.3 s | the same, the tour instead of live navigation |
| Galaxy map | 3.0 s | star colours 2.5 s, simulation 0.4 s |

## Goals and non-goals

Goals:
1. Board the ship, Guided voyage and Galaxy map go through a loading view: the title's real sky accelerates along the galactic centre (the title camera turns to face it over the first quarter) with rapidity φ = p · atanh(0.99999), where p is the real load progress; 100% is β = 0.99999 (γ 223.6, 1−β = 10⁻⁵).
2. Progress is real: weighted by measured stage times, finished stages count exactly (a running worker stage is estimated by elapsed over measured time, at most 95%); monotone; 1.0 exactly when the destination is built and has drawn its first frames.
3. As much loading as possible off the main thread or shared, without changing what the routes build; whatever still blocks is measured and reported.
4. A minimal overlay in the title's style: `LOADING · BOARD THE SHIP`, β (as many digits as the approach to c needs), γ, 1−β, the range "β 0.000c → 0.99999c", a progress line with the percentage, the stage being loaded, and the note that the speed is illustrative while the optics are the renderer.
5. At 100% only: the white-out (transition effect): the forward point blooms to full white, then fades to the destination.
6. Every command-line, capture, golden, smoke and export mode is unchanged (they never show the title); the title screen's own tests and `ui/title_screen.gd` are unchanged.

Non-goals: a loading view for command-line modes; loading screens elsewhere (navigation, tour legs); moving the ship's scene build to a thread (see Risks); new art.

## Design

- **`ui/loading_jump.gd` (`LoadingJump`, CanvasLayer 100).** `main.gd _on_title_route` creates it for ship / guided / map when the title shows its sky (`Main.loading_overrides` forces it in headless tests), hands it the title's `InteriorSky` (reparented, so the jump renders the same sky), freezes the title's input, and passes the route body (`_route_now`, the old `_on_title_route`, unchanged) as the build step.
- **Phases.** *prefetch* (worker threads, in parallel, while the jump animates): the galaxy map's star colours (`Blackbody.xyz_uncached` over the catalogue's distinct temperatures, a group task, handed over with `Blackbody.seed_cache`), the simulation (`SimBridge.warm`: spawn + hello on a worker; `offer_warm`; the route's next default `start()` with the same protocol minor adopts it), and on the main thread one a frame the captain's sprite textures (`CaptainAvatar.offer_texture`). *build*: the route itself, blocking. *frames*: three frames of the destination drawn under the jump. Phase weights are the measured times (the `STAGES` table names the measurement).
- **Shared loads.** The title's sky already holds the panorama and the star tiers. `SkyBackground.attach` reuses a live attach of the same pair (weak references to its textures plus its CPU calibration copy), and `Starfield.load_tiers` copies a live field's identical load (a snapshot taken at the end of its own load: copy-on-write packed arrays). With no live holder both load as before.
- **Faster colour integral.** `Blackbody.xyz_uncached` reads λ, the CMF (as float32, as `cmf()` returns it) and λ⁻⁵ from a table built once; bit-identical to the step-by-step loop (kept as `xyz_reference`, tested over 806 temperatures), ten times faster. This alone took the map's colours from 2.4 s to 0.2 s.
- **Optics.** Each frame: `Relativity.beta_of_rapidity`, `gamma_of_rapidity`, `one_minus_beta_of_rapidity` (new mirrors of the package's `betaOf`, `gammaOf`, `oneMinusBeta`, with its `tanh`/`atanh` forms; `1.0 - beta` is never formed) → `Starfield.set_velocity` and `SkyBackground.set_velocity` (which also runs the forward CMB). The CMB lookup (`CmbGlow.lut`, 45 ms) is built in the first frame.
- **Exposure.** Held at the title's fixed physical exposure (dark-sky EV − 4 stops), deliberately not metered: a meter would stop down on the forward point, whose Doppler factor reaches γ(1+β) = 447, and the frame would go black. Held fixed, the forward point clips into a blinding blue-white glare with the renderer's bloom, and the rest of the sky goes dark, as it physically does.
- **Displayed progress.** `shown` follows the real `progress` at most 1.6/s and never exceeds it, so a blocking build's jump in progress plays as a fast surge instead of a cut. The white-out starts when `shown` reaches 1.0, which implies the destination is ready.
- **White-out (transition effect, not physics).** 0.45 s: a radial blue-white bloom grows from the forward point to cover the screen, full white from 55%; 0.12 s hold (the jump's sky and backdrop hidden); 0.7 s fade to the destination. Then the layer, and with it the title's sky, is freed.

## Acceptance criteria

| # | Criterion | Command |
|---|---|---|
| A1 | Each title route goes through the jump and arrives at the same destination as before (ship live rest captain eye; guided tour; standalone map); Esc / Main menu still return to the title | `make loading-jump-test` (in `make test`) |
| A2 | Real progress and displayed progress are monotone, displayed never ahead; progress reaches 1.0 exactly when the destination is ready | `make loading-jump-test` |
| A3 | β at 100% = `Relativity.beta_of_rapidity(atanh 0.99999)` = 0.99999 (1e-15); γ, 1−β from the mirror; the white-out starts at 100% | `make loading-jump-test` |
| A4 | The routes run on the prefetched simulation; no warm sim left over; an unused warm sim is stopped | `make loading-jump-test` |
| A5 | Command-line modes bypass the title and the jump; a sky-less title routes at once (the title screen's tests unchanged) | `make loading-jump-test`, `make title-screen-test` |
| A6 | Shared loads equal fresh loads (star rows, identities, counters; panorama textures and calibration); the colour table is bit-identical to the reference integral | `make loading-jump-test`, `make physics` |
| A7 | Rapidity mirror = `sunholo/relativity` 0.10.0 values at φ = atanh 0.99999 and φ/2; spec §2 aberration and Doppler at 0.99999c | `make physics` |
| A8 | GPU = CPU star positions at the jump's 50% and 100% speeds (0.165 px at 0.99999c) | `make golden` |
| A9 | Reference renders at 0, 50, 90, 99, 100%, white-out and fade, opened and reviewed | `make loading-jump-capture` → `renders/loading_jump/*_700.png` |
| A10 | Load time and frame times per route reported (before / after) | `make loading-profile` |

## Results (Mac Studio M2 Ultra, 1280×720, 2026-10-08)

| Route | Before: press → ready (frozen) | After: press → ready | Main thread blocked (build) | Jump frames (median / p95) |
|---|---:|---:|---:|---:|
| Board the ship | 7.9 s, one frame | 2.0 s | 1.36 s | 13–16 ms / 30–57 ms |
| Guided voyage | 7.3 s, one frame | 2.0 s | 1.33 s | 12.6 ms / 22 ms |
| Galaxy map | 3.0 s, one frame | 0.7 s | 0.04 s | 9.8 ms / 24 ms |

The white-out and fade add 1.27 s after "ready". Still blocking in the ship's build (one 1.3 s hold of the jump's frame, at about 27%): the star-occlusion BVHs (0.3 s), the navigation map and its first tick (0.24 s), collision shapes (0.18 s), planet texture preload (0.13 s), the sky state, the GLBs and the scene itself. They build nodes, meshes and GPU resources inside the ship's `setup()`; splitting that function across frames or onto a thread would change its contract for every other caller, so it stays one step here.

## Risks and mitigations

- *A warm simulation adopted by the wrong caller.* Only a default `start()` (no launch override, no record path) with the same protocol minor takes it; the loader discards it after the build; tests cover all three.
- *Shared loads drifting from fresh loads.* Snapshots are taken at the end of a load (copy-on-write), never from live, mutated fields; tests compare shared against fresh row for row.
- *Thread safety.* Workers never touch shared statics: each task writes its own dictionary; caches are seeded on the main thread; the wavelength table is built on the main thread before workers start; `SimBridge.warm` never adopts.
- *The blocking build.* Reported, not hidden; the displayed progress holds at the last real value and then surges.

## Open questions for the user

None blocking. If the 1.3 s hold in the ship's build should go too, that needs `demos/ship_geometry_demo.gd setup()` split into steps (a separate change).

## Deliverables

`ui/loading_jump.gd`; hooks in `main.gd`, `bridge/sim_bridge.gd`, `sky/background.gd`, `sky/starfield.gd`, `interior/captain_avatar.gd`, `physics/blackbody.gd`, `physics/relativity.gd`; `tests/test_loading_jump.gd`, `tests/test_physics.gd` (rapidity, colour table), two golden cases in `main.gd`; `tools/loading_jump_capture.gd`, `tools/loading_profile.gd`; Makefile targets `loading-jump-test`, `loading-jump-capture`, `loading-profile`.
