**Score: 66/100 (not passing).** The physics framing is honest and the spike is useful. But there is a spec ID collision, a contradiction between the bit-identity criteria and the limb-darkening change, an unsolved corona exposure path, and acceptance gates that aren't wired into `make test`. All are cheap to fix on paper.

## BLOCKING

1. **RS-19 and RS-20 already exist.** *Doc §D7, AC3 and AC7; sprint SS4; JSON.* `relativity-spec.md:176-177` defines RS-19 and RS-20 as the static-observer factors at 2 r_s and 1.5 r_s, and the table runs to RS-23. The proposed IDs would collide, and every "RS-19" or "RS-20" in tests and logs would be ambiguous. Fix: take fresh IDs (RS-24 and RS-25, or a new `RS-SS` family) after checking the current spec tail, and change them everywhere.

2. **AC5's bit-identity contradicts the limb-darkening change.** *§D1 "replaces linear u", §D2, AC5, AC4.*
   - The shader's Sun branch uses `limb_u` 0.6, linear (`planet.gdshader:86`). The Sun at home is 8.9 px, above the 2 px floor, so the nonlinear Neckel & Labs / Claret law would apply.
   - That would change the Sun's pixels, so "Sun from 1 AU bit-identical to origin/main" fails.
   - Every catalogue star changes the same way: `starBodyObj` sends `limb_u` 0 (`protocol.ail:376-379`) and Claret turns that into a darkened disc. Aldebaran, α Cen A and the other stars lose their flat look at any size, so "the other 393 lines byte-identical" needs the star-lux and sky cd/m² goldens to be shown unchanged.
   - Fix: decide explicitly. Either (a) the Sun keeps linear u = 0.6 so bit-identity holds, and AC5 covers only "gated layers contribute 0", or (b) drop bit-identity for the Sun and replace AC5 with "flux unchanged, a pixel diff bounded and published". State which stars get a new LD law, and add a golden showing the existing lux and cd/m² cases are unaffected.

3. **The corona exposure path is unsolved and contradicts the fader.** *§D6, §D5, AC9, AC12.*
   - The corona is 1e-6 of the disc, drawn in the same quad. The Auto fader multiplies that quad by `fader_gain` (target 1.2 over the disc peak), so the corona lands near 1e-6, invisible.
   - `fader_gain` is explicitly "never a brightening" (`system_view.gd`, near line 512), yet §D6 says "the Auto view raises the exposure".
   - The spike only worked because it hand-set exposure so the corona at 2 R sits at 0.3.
   - AC9 tests Baumbach radiance in the shader, not whether the corona is visible in a real Auto or Realistic frame.
   - Fix: specify the mechanism. Give the corona and prominence layers a separate gain, or make `_displayed_peak` switch to the corona peak when occlusion is ≥ 1 and blend continuously through partial phases. Say how the global `k` relates to other bodies in the frame. Add an AC with a real-game eclipse frame (the Moon stop) whose corona luminance at 2 R is within a stated band after the real pipeline.

4. **New gates aren't wired into `make test`.** *AC2–AC11, sprint SS1/SS2.* `star-surface-test`, `stellar-protocol-test`, `star-surface-bench` and `star-surface-capture` don't exist. The `test:` and `ci-fast:` lists (`Makefile:37,39`) would not run them, so AC13's "make test green" proves nothing about this work. Also, `golden` pins exactly 393 ok lines (`Makefile:451,460`), and adding G-SS-1..5 changes that count. Fix: add to the plan an explicit task to define the targets, add the non-GPU ones to `test:` and (where pure) to `ci-fast`, and bump the golden count and message. Add a `python-guard` note that none of this is Python. Put those edits under SS1/SS2 in the doc, the sprint and the JSON.

5. **Time precision and the double-D risk.** *§D4, AC7, gate 5.*
   - `t_e = t_sim − light_age_s` is in seconds and about 1e9 to 3e9 after years of voyage. Passed as a float32 uniform, the ulp is 64–256 s, which is coarse against the Sun's 8-minute granule lifetime and any "phase advances" check.
   - `t_e` already carries the factor D. Approaching at β, `dt_e/dt_ship = γ(1+β) = D`, because light_age shrinks as the ship closes. Applying `Δt_e = D·Δt_ship` on top (§D4 bullet 3) would double-count it.
   - Fix: send the phase reduced in float64 on the CPU (`fract(t_e / lifetime)`, or `t_e` mod a period). State plainly that D enters only through `light_age_s`. Make AC7 measure via `t_e(t)` from the sim, not a separate D multiplication.

6. **Per-sample colour needs the blackbody LUT at rest, and the flux normaliser has no cost or definition.** *§D2, §D5.*
   - `bb_lut` is only bound when `moving` (`system_view.gd`, `_draw_disc`), and the shader only reads it when `beta_mag > 0` (`planet.gdshader:169`). A temperature map needs `Y(T(x))` and `rgb(T(x))` at rest, so it needs the LUT always, plus a replacement for the uniform `tint`.
   - `N` is a CPU float64 hemisphere quadrature of a noise field with a μ-dependent gate. It runs per star and per view. Nothing says how many quadrature points, how often it is recomputed (every camera move?), or that its sampling matches the GPU's `ss` supersample.
   - "4 random views" in AC3 is undefined.
   - Fix: add both to SS2, and give the budget and cache key for `N` (star, view direction quantum, gate state). Define the AC3 views as seeds and directions.

7. **Citations are from memory and unverified.** *§D1, §D3, Risks.* The doc admits its numbers may be wrong. The Claret & Bloemen 2011 coverage for a 2,566 K dwarf (TRAPPIST-1) is not checked. If the table stops at about 3,500 K, the "clamped" ldCoeffs makes a flat clamp the TRAPPIST-1 law. Fix: add a pre-SS0 verification step to the plan (one day at most) that pins each cited number, with a table row per value in `stellar_test.ail`. Mark the Teff range per source.

## Non-blocking suggestions

1. AC3's "to 1e-6" tests the mirror's own normalisation, which is tautological. Add an independent oracle (a one-off Python quadrature allowed under "oracle" in `tools/python-allowlist.txt`) or a closed-form check for a single spot.
2. §D2 says "D-scaling as today". Write the exact expression. Today it is `seen.rgb/rest.rgb * 10^(seen.a−rest.a)` with a fixed `emitter_temp_k`. Make clear that per-element `T(x)` replaces `emitter_temp_k`, and that RS-5 / spec §2 band behaviour is preserved.
3. Moving flux: D varies across the disc, so RS-19 (flux preservation) holds only at β = 0. Say so.
4. The JSON branch is `feat/star-surfaces` but the work branch is `design/star-surfaces`. Align them.
5. AC11 admits the spike's GPU timing failed on this rig. Name the method (the `make bench` star-pass GPU ms route) in the AC and in SS2, rather than leaving it to be found at execution.
6. Check that `lineColour(λ, D)` is valid for D from 1e-4 to 1e4, i.e. a λ range of 0.066 nm to 6.6 mm. A CIE monochromatic line is zero outside 360–830 nm, so "finite" means black outside it. Test what the player sees at 0.9c (Hα at 150 nm or 2.9 µm is invisible), and decide whether the line disappears or clamps.
7. The Archive and inspector labels ("chosen pattern, real size") need `surface` fields marking which values are chosen. Add that to the protocol record.
8. Estimates: SS2 at 600 LOC and 2.5 days (noise, normaliser, mirror, five goldens, bench, captures) is thin. Hold 3.5 days, or move the bench and capture work to a separate day.
9. OQ2 "procedural unless the bench misses" leaves a late rewrite risk. Decide the fallback trigger at the SS2 midpoint, not at the end.
10. OQ3 is good and OQ8 is reasonable. Add the missing question: whether Auto-view-only structure is acceptable, given that Realistic clips white. The doc notes this but doesn't ask it.
11. SS0 publishing (Mark's go) blocks SS1. The plan names a local-path fallback; add an AC saying the merge is blocked until the pin is a published version.
