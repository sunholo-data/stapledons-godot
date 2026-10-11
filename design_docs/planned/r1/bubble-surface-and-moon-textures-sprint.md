# R1-BUBBLE-MOONS

Approved: Mark's attended 2026-10-11 follow-up; design [bubble-surface-and-moon-textures.md](bubble-surface-and-moon-textures.md). Scope is the approved restrained comparison and reported moon defect, with data-based instrument map presentation. No additional approval is inferred necessary for routine geometry/asset choices. Estimated implementation/test/documentation ~1,100 LOC; no measured completion-time promise. Source baseline 62eae17 has full local/matching feature CI pass and independently reviewed ISM/nav; this follow-up must run its own final gates.

- [x] S: Equal-area, incidence-aligned wall smear; legacy circles; CPU/GPU, conservative bounds and native comparison. Registry reuse: depend on published relativity0.12 dust emission unchanged; none for new renderer footprint geometry.
- [x] M: Missing real moon maps, sources/pins/albedo/bundles, dynamic smoke coverage and native Callisto evidence. Registry reuse: depend on existing celestial/relativity body metadata; none for image I/O/source pinning.
- [x] C: Subtle source-based filled gas surfaces and uncertainty/instrument legend; map interaction checks and capture. Registry reuse: depend on celestial0.4 geometry; no new cloud inference.
- [x] N: Stationary standalone map, scrollable details, visible zoom/review and Enter/Space/Esc through actual Mars journey; 17 checks and native captures.
- [x] T: Seven true guided legs at existing D-54 finite-star stops; 134 controller checks, strict/interpreter parity and 18 native references.
- [ ] Q: Full local/CI, independent judge, dev build, docs/changelog and main/gallery landing.

S and M are independent file scopes and run in parallel per sprint-executor; root owns S/C and integration. M owns planet texture inputs/tools/tests/smoke only. First write failing meaningful tests for missing maps/footprint bounds; do not alter old scientific check values to fit images. Inspect actual native output before selecting default. Templates/math are not new production AILANG code; syntax gate applies if .ail changes become necessary.

Attended expansion, 2026-10-11: Mark reports standalone-map local travel, hidden commitment/zoom controls and redundant guided system arrivals. N fixes actual stationary startup, reachable footer and keyboard confirmation/zoom, and the separate Sgr A* demo entry. T audits actual distances and uses the existing D-54 finite-star stop composition to remove redundant outer-system/inward-hop pairs. No new physics or teleportation; Mark accepted the seven retained highlights and the separate optional Sgr A* demo. N/T are independent source scopes and run in parallel under sprint-executor; root owns N, delegated T owns only guided authoring/tests. Q expands to final matching gates after integration.
