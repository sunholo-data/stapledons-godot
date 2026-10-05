# Known-star identification review

Hold **I** to show rings around currently rendered sources with exact records in
the existing map catalogue. Hover names them; click opens a factual card. Blended
hits show individual exact-ID choices. Release I hides rings and keeps the card;
Escape or Close dismisses it. Open in map explicitly selects the same ID in the
existing navigation session. Inspection itself does not plan, commit or pause it.

The AILANG catalogue producers retain `Row.id` after companion adjustment and final
tier selection. Those ordered IDs are written into the existing atomic JSON
sidecar, alongside the binary SHA256 and count. The binary record layout and all
three regenerated binaries remain unchanged. The renderer carries identity through
missing-photometry filtering, HIP-only fill and tier stacking. A missing, malformed
or duplicate identity list disables identification for that tier; bad binary hashes
still refuse the tier itself. Duplicate IDs across the active stack and absent map
metadata are ineligible. There is no nearest-position identification heuristic.

The overlay uses actual uploaded float32 hi/lo positions and shader uniforms,
including the stable uploaded one-minus-beta. Its LUT/floor/peak checks mirror the
existing shader. Apparent rays can be cached only while uploaded observer,
photometry and identity state remain unchanged; turning the camera reprojects and
rechecks occlusion every update. Opaque GLB/primitive/custom-shader surfaces use
physicsless triangle BVHs even without colliders. Current transforms, camera layers
and detailed/coarse visibility are refreshed; freed references are ignored.
The captain's current billboard plane and cached bilinear mip alpha mask block
opaque body pixels while preserving transparent padding. Position, camera-facing
orientation, anchor, frame, flip and current age/facing texture are respected.
Standard alpha surfaces and explicitly tagged custom cutouts are not solid
rectangles. Unknown custom shaders conservatively occlude; accurate future custom
cutout masks require an explicit mask integration. Diagnostic sky-only mode shows
stars because the ship render itself is deliberately hidden.

`StarInfo` supplies read-only exact-ID facts and the map's catalogue subtitle.
Distances are labelled **catalogue distance from Sol**, not distance from the ship.
Missing data is unavailable; no planets or classifications are invented. Current
scope is the finite-geometry ship demo. The original painted-plate interior needs
its plate-alpha occlusion integration before this overlay can be enabled there.
No new physics or GR is implemented.

Evidence:

- `producer-first-failure.txt`: expected `main-BAD` before preserving IDs.
- `producer-checks.txt`: all four strict VM/interpreter catalogue markers pass.
- `sprite-first-failure.txt`: expected opaque-body refusal failure before adding
  the sprite mask (39 passing checks, one failure).
- `source-checks.txt`: 40 identity/input/floor/cache/mesh/sprite checks pass.
- `source-smoke.txt`: real application smoke route, viewport I/click/card/release
  and exact-ID map handoff; no developer-only script is needed by the app.
- `capture-manifest.json`: 276 GPU/native cases, worst 0.5058 pixels
  against a 1-pixel limit; resolutions 1920×1080, 1280×800, 900×600. Includes default
  GPU and CPU rebasing near 100000 light-years, beta 0/.99/.9999, tilt/roll/FOV,
  an isolated exact binary Sirius row and real AILANG boost/cruise/brake states.
  A deliberate 4-pixel error is detected; non-collider opaque composite and native
  physical viewport clicks and actual captain opaque-body/transparent-padding
  GPU alpha masks are checked. Isolated live centroid measurements
  explicitly increase exposure for resolution; physical review screenshots retain
  the current 4× display trial. This final run also exercises the apparent-ray cache.

Captures live in `renders/ship_identification`: `bridge_identify.png`,
`rest_identify.png`, `cruise_identify.png`, `native_900_card.png`,
`opaque_mesh.png`, `captain_body.png`, `captain_padding.png`, `live_boosting.png`,
`live_cruising.png`, `live_braking.png`.
These are reviewed artifacts, not checked-in runtime textures. Packaged smoke,
paired benchmark and independent approval are tracked in
the sprint JSON. Studio measurements are not MacBook Air measurements; actual
2022 M2 Air / 24GB performance remains pending.
