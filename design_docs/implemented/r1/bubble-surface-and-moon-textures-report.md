# R1-BUBBLE-MOONS completion evidence

Status: complete. Validated and merged into main in [PR #201](https://github.com/sunholo-data/stapledons-godot/pull/201), merge commit `6c956c0bb83eeee539a166bafa4b489d76302732`. Gallery, news and roadmap publication is verified. Runtime source: `56ea60cb3953daae7ae9bcc5cf053e81162ecc8a`. D-64 and D-65 are attended rulings; no new mission iteration is credited.

## Result

Callisto and nine other moons have pinned USGS/NASA maps. G-AG marks attach to the spherical wall as short incidence-oriented curved patches. The map displays source-based false-colour gas density with approximate-depth labels. Manual navigation starts stationary and exposes zoom, review and keyboard confirmation. The guided trip has seven real legs, with one close arrival each at Alpha Centauri A, TRAPPIST-1 and Aldebaran. Sgr A* remains an explicitly separate optional GR demo.

The new wall geometry preserves emitting area; package rates, energy, temperature, decay and all source data remain unchanged. Local gas surfaces are instrument data, not eye-visible nebular fog. Titan radar/IR is excluded from ordinary visible terrain. Enhanced colour and missing coverage remain disclosed for the source mosaics.

## Evidence

| Gate | Evidence |
|---|---|
| Wall CPU checks | 16 checks, zero failures; independent spherical quadrature and bounds. |
| GPU goldens | Complete `make golden` exit 0; G5 covers centred and off-centre observers, grazing shapes, overlap and integrated emission. Legacy G1–4 retain circles. |
| Native wall references | Eleven seeded/geometry frames; repeated seeded capture hashes match. 60° flight and explicitly labelled 3° magnification share the actual simulation event stream. |
| GPU budget | 64 uploaded marks at 2560×1440, three alternating 300-frame pairs after warmup. Quiet on/off deltas −0.029, −0.025, +0.146 ms: median indistinguishable from measurement noise, all pairs within the 0.3 ms budget. This is representative M4 Max evidence, not a universal latency guarantee. |
| Moon assets | 20 pinned images verified; 121 checks; all 19 declared bodies within 1% disc-integrated adopted albedo. Cold Callisto fallback retrieves the exact pinned source hash. |
| Export | Final native app draws all 19 textured bodies; actual exported Callisto image opened. Ship, star identification, title, guided, large catalogue and offline AI smokes pass. |
| Source gas surfaces | 18 checks, zero failures; 15 media in native map capture, unchanged simulation tick when toggling shading. No radial Sol fan is used as a filled cloud surface. |
| Manual flow | 17 actual navigation checks: 600/450-pixel windows, visible zoom/review, wheel input, real Mars plan and commit, Enter focus precedence, hold/release, press-twice arming and Esc backout. Original footer fails against the same logical viewport bounds. |
| Menu handoff | 89 title checks, zero failures; actual map → Sgr A* → Main menu route. Prior source fails the menu-access assertion. |
| Guided controller | 134 checks, zero failures; one initialization, continuous clocks, seven exact endpoints, no eighth leg. Legacy rule-zero ten-leg replay behavior retained. |
| Guided VM | `directHighlightsVm` strict bytecode output byte-identical to interpreter; mandatory `guided-highlights-strict` target in complete test suite. |
| Guided native references | 18 actual final-braking/arrival frames and nine TRAPPIST planet views, zero failures, inspected. Alpha A ≈11.05°, TRAPPIST ≈3.46°, Aldebaran ≈60.93°. TRAPPIST no longer claims the former specially placed beside-e/HZ stop. |
| Complete local tests | Complete final serial `make test` on `56ea60cb` exits 0. Log SHA-256 `b7a2e5f83e51789eadf52caddd2488e9120ff8c2406da9509476c8e8ccf882bc`. All five AI fault-harness p99 values pass unchanged budgets (0.256/1.014/0.922/0.113/0.152 ms). Historical integration failures remain recorded; no thresholds or acceptance values relaxed. |
| Matching CI | [Run 38164128167](https://github.com/sunholo-data/stapledons-godot/actions/runs/38164128167) succeeds on the exact final runtime source, completed 20:45:59 UTC, 11 October 2026. All preflights and complete `make test` pass. |
| Independent judge | Formal independent PASS, 98/100, merge-ready for the exact runtime source; generator and judge are separate agents. [Evaluation](../../../.ailang/state/evaluations/eval_R1-BUBBLE-MOONS_round_1.md). |
| Review build | Published `v0.4.0-dev.25-free-nav-83-g56ea60cb`, exact runtime source, ZIP SHA-256 `11bcf7776bd4c893e684cc531e7657f0a5178e135e25809ba4efab3194362521`. The approved private bucket's latest metadata independently matches. Install with `tools/install_review_build.sh --dev`. |
| Website | Final isolated Docusaurus build succeeds. [Pages deployment](https://github.com/sunholo-data/stapledons-godot/actions/runs/38173974688) succeeds; public [gallery](https://www.sunholo.com/stapledons-godot/gallery), [news](https://www.sunholo.com/stapledons-godot/news/2026/10/11/callisto-and-the-bubble-wall) and [roadmap](https://www.sunholo.com/stapledons-godot/docs/roadmap) return HTTP 200 with the new captures and latest mission status. Native screenshots are uploaded by content hash. |

## Distance audit

The former outer stops were real 1,000-AU endpoints. Their inward legs were about 5.8 Earth light-days, explaining the long second approach. Direct D-54 star stops remove those redundant legs rather than changing coordinate mathematics. Successive interstellar legs are approximately 4.321, 41.756 and 74.422 light-years from their actual prior endpoints. Representative complete-tour clocks are Earth +120.507874 years and ship +0.889 years.

## References and remaining R1 work

Public design [#14](https://github.com/sunholo-data/stapledons-design/pull/14) records the equal-area footprint; [#15](https://github.com/sunholo-data/stapledons-design/pull/15) records the accepted guided itinerary; [#16](https://github.com/sunholo-data/stapledons-design/pull/16) records their landed status. Vendored physics lore remains pinned to `8895503` and cross-repo hash checks pass; D-65 introduces no new physics formula or lore value.

This follow-up does not close the entire M4/M5 or sky acceptance. Next product work remains the console-based complete-journey audit and remaining visual/performance acceptance. Dense-cloud/LLCC PR B is deferred while scientific comparisons fail. The latest mission report, [11 October 20:10 UTC](https://github.com/sunholo-data/stapledons-godot/issues/119#issuecomment-6113222904), parked on unavailable/out-of-quota controller lanes. Attended work is reported separately.

## Retrospective

The source manifest replaces the earlier hardcoded original-nine texture check, so a missing new moon can no longer pass export acceptance unnoticed. The independent judge caught a recording assertion reading the old path; the controller test now inspects its actual per-process NDJSON file. The complete suite caught the lost footer hint; a genuine route check caught the black-hole menu handoff. Timing-sensitive checks retain their original thresholds and are rerun with native export finished. No scientific check values, frozen replay digests or package formula were changed to fit the new pictures.
