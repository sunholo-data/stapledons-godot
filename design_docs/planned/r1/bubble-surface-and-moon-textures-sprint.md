# R1-BUBBLE-MOONS

Approved: Mark's attended 2026-10-11 follow-up; design [bubble-surface-and-moon-textures.md](bubble-surface-and-moon-textures.md). Scope is the approved restrained comparison and reported moon defect, with data-based instrument map presentation. No additional approval is inferred necessary for routine geometry/asset choices. Estimated implementation/test/documentation ~700 LOC; no measured completion-time promise. Source baseline 62eae17 has full local/matching feature CI pass and independently reviewed ISM/nav; this follow-up must run its own final gates.

- [ ] S: Equal-area, incidence-aligned wall smear; legacy circles; CPU/GPU, conservative bounds and native comparison. Registry reuse: depend on published relativity0.12 dust emission unchanged; none for new renderer footprint geometry.
- [ ] M: Missing real moon maps, sources/pins/albedo/bundles, dynamic smoke coverage and native Callisto evidence. Registry reuse: depend on existing celestial/relativity body metadata; none for image I/O/source pinning.
- [ ] C: Subtle source-based filled gas surfaces and uncertainty/instrument legend; map interaction checks and capture. Registry reuse: depend on celestial0.4 geometry; no new cloud inference.
- [ ] Q: Full local/CI, independent judge, dev build, docs/changelog and main/gallery landing.

S and M are independent file scopes and run in parallel per sprint-executor; root owns S/C and integration. M owns planet texture inputs/tools/tests/smoke only. First write failing meaningful tests for missing maps/footprint bounds; do not alter old scientific check values to fit images. Inspect actual native output before selecting default. Templates/math are not new production AILANG code; syntax gate applies if .ail changes become necessary.
