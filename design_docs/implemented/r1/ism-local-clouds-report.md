# Local-cloud ISM and dust: PR A completion report

**Scope:** PR A only. Local Interstellar Cloud, fourteen Redfield–Linsky warm clouds and the Local Bubble's hot gas, seeded dust impacts, wall glow, route columns, HUD and Archive. PR B's dense tomography and Local Leo Cold Cloud are deferred and unimplemented in the runtime.

**Landing:** https://github.com/sunholo-data/stapledons-godot/pull/199; reviewed feature source c5f0f6d76763dde6b0faef0e7c7944ba4babf569. Independent evaluation: 98/100 for PR A; 97/100 for the attended navigation recovery. Complete local `make -j4 -k test` exited zero, and matching CI https://github.com/sunholo-data/stapledons-godot/actions/runs/38085243443 passed. No test targets were skipped.

## Source and numerical checks

- The source-figure angular outlines recover 56/59 nearby sight lines (94.9%). Their near/far depths are approximate; the LIC numerical surface is an adopted model. The cloud layer does not claim measured three-dimensional filaments.
- `sunholo/celestial` 0.4.0 and `sunholo/relativity` 0.12.0 were published before the game pins changed. The specification and Archive landed in the public design repository. New ISM modules and package quality without gates pass. Historical whole-package audit failures are reproduced on the unchanged package base and are not represented as a clean whole-package audit.
- All changing-speed dust pieces, including high-acceleration short trips, are integrated. The exact inverse of the adopted log-linear efficacy table agrees with the original guarded solver; an independent 4,183-case oracle has zero failures and maximum relative difference 2.9744e-14. Invalid/nonmonotonic/subnormal cases retain the original fallback.
- Protocol 2.8 adds the local model. Frozen uniform/protocol 2.7 recordings retain their bytes. The 43-line local-cloud fixture is identical on repeated VM runs and the interpreter (SHA256 `7349a893b8dfeb7ceb5dfe7e762c92717d052cabd85f288173c8653fcb4cc8a4`).

## Visual and performance evidence

- Final GPU goldens pass, including CPU-vs-GPU impact intensity, colour, glitter and mask checks. The review inventory hashes 57 evidence items; independent review found zero hash mismatches. It includes the source/stream evidence, 36 flight renders, comparison sheets, maps and ten native HUD captures.
- Warm paired overhead medians on M4 Max: plan 3.098 ms (20 ms budget); coast 0.205990 ms, boost 0.401265 ms, brake 0.220180 ms (0.5 ms budget); 64 live flashes at 1440p Vulkan 0.023 ms GPU (0.3 ms budget). These are representative medians, not worst-case or universal hardware guarantees.
- Mark accepted P2's existing 0.5 m spot, 0.2 s decay, sensitivity/default dust assumptions, per-medium glow and Archive choices (D-62). The afterglow remains a labelled game approximation; the radar-meteor tail is off by default.
- Native videos show a Schwarzschild orbit at three horizon radii, actual Saturn arrival and six ordered cloud intervals toward Aldebaran. Captions disclose presentation compression and cuts. The black-hole background is the labelled Sol sky; Kerr and true Galactic-Centre imagery remain future work.

## Attended navigation recovery (D-63)

Free navigation begins at rest 50,000 km from Earth's centre using the existing Solar initializer. The fixed system list preserves button identities and places moons beside their parents. Live idle advances one second per real second; Earth remains resolved at its inertial arrival standoff through the checked one-minute dwell. Stops are not gravity-bound orbits.

Mouse motion looks around by default. Details, inspection, console, map and arrival panels release the pointer; their motion does not turn the view. Focus loss and exit release capture. P and visible Pause/Resume controls freeze elapsed simulation time and preserve the committed course; pending intents remain usable and commitment resumes time. Refusals explain a next action while preserving the simulator's raw reasons and commitment/clearance rules.

The map defaults to visible local clouds, exposes Interstellar medium [D] and Local ISM framing, and keeps approximate depth construction guides optional and off by default. These controls send no navigation intents.

Focused checks: recovery 28/28, host input/HUD 210/210, layer 16/16, no-twitch 24/24, ordinary/strict new-scenario 4/4, six valid new NDJSON replies byte-identical. Actual native Earth arrival/+60s and map frames were opened. Unmodified native motion and panel guards were checked, but pointer capture/resume could not be confirmed on the unattended desktop because its OS window lacked focus. The production focus guard remains intact; native capture is not falsely recorded as passing.

## Deferred work and next step

PR B's extraction plumbing passes 60 synthetic FITS assertions and 120 independent pixel references, but its threshold-clump model passes only 1/20 independent extinction directions, Taurus/Ophiuchus distance checks fail, and one Na I absorption sight line lies outside the adopted 21 cm LLCC outline. No failed dataset or scientific waiver ships here. Track it in the separate planned dense-cloud document.

The next R1 product target is the M4 console-based complete-journey audit: plan, commit, transit, arrival, return and consequences, with displayed-number and refusal checks. The D-52/D-56 amended scene plan retains its approval checkpoint before that execution. Remaining sky/ship visual gates, planet/flyby work, optional live crew AI and voice review remain on the roadmap.
