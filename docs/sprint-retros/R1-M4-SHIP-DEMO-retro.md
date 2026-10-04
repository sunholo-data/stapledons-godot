# Sprint retrospective: R1-M4-SHIP-DEMO

Approved and implemented in an attended session on2026-10-04. Four sequential milestones; geometry/view/lift pass, review instrumentation is delivered. SD4 remains partial: actual target-laptop measurement is pending, so the sprint is not complete and production landing is not claimed.

The generator and judge were separate agents. Geometry is authored in Blender metres and exported as visual and WALK domains; ordinary game presentation stays in Godot. The Blender generator is embedded in the editable master rather than adding a Python game pipeline.

SD1 produced a distinct master and genuine lift holes. SD2 preserved one perspective observer across finite geometry and infinite sky, with native materials and labelled external/reference views. SD3 implemented a guarded25m ride and safe lower landing. SD4 added an in-app four-view benchmark, packaged smoke check and CI headless regressions. Original planned1560LOC is an estimate, not generated-vertex velocity; no calendar/performance guarantee follows from this smoke test.

Test-first evidence: missing measured manifest, missing shared observer/lift/benchmark tool each failed before implementation. Independent review then exposed a travel-wheel escape and incomplete actual mesh height assertions; regressions failed before fixes, and mutated tier/tip negative controls prove the geometry checker. Lift tests repeat three roundtrips. The GPU optics judge checks actual catalogue/finite marker alignment and opaque occlusion, including a deliberately mismatched FOV control.

Review friction: Blender shared meshes had to be copied before demo Boolean cuts. The catalogue star shader disables depth testing, requiring a separate sky target composited behind finite geometry. Combining stacked WALK meshes would choose the highest floor, so only the active deck is sampled. Godot script parse errors may exit0 or leave a harness awaiting work; Makefile gates require explicit summaries, and dynamic-load tests check validity. The exported app executable must be read from Info.plist. A one-off native AVFoundation encoder produced the review recording; no encoder dependency ships in the game.

The main button opens a separate process so the voyage keeps running. The benchmark ignores mouse/key input and disables HUD buttons, records actual hardware and requires target confirmation. Close other game windows and repeat on the Air before making performance decisions.

Studio result at1920×1080, AppleM4Max/128GB,300samples/view after120warm-up frames: p95bridge28.579ms, overlook26.063ms, mid-lift26.777ms, overview28.503ms. Those results exceed the proposed16.67ms budget; they are neither an Air result nor a performance pass. Existing compatibility tests were running concurrently; repeat an isolated benchmark before diagnosing bottlenecks. No optimization was concealed by dressing the bare lower tiers with architecture.

Next: confirm the MacBookAirM2(2022),24GB report and profile exposure/sky versus geometry cost if it misses budget; author buildings/forests with explicit bubble-clearance and occlusion checks; replace the fixed-view paint/captain presentation for arbitrary close camera angles. GR needs its own source-relative observer and reference-tested tracing implementation.
