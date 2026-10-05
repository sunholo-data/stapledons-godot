# Published review — 5 October 2026

Review build `v0.4.0-dev.10-unified-painted-ship` uses frozen source
`ec34d583a8689b83f8bae964cb5622f26c10b813`. The uploaded ZIP was downloaded again;
SHA256 `758dfb75a71614a52ad15ff83292212bda7dcb4b4522101240712bb92370385d`
matches the manifest, and ZIP integrity passes. See `review-build.json`.

Normal native app startup opens the live ship at rest, at the captain eye. Native
packaged I-click, persistent card and exact-ID map handoff pass with empty system
PATH. Existing bundled sky/interior checks pass. Full source tests and GPU goldens
pass locally; independent technical review scores unified ship 94/100 and known-star
inspection 96/100. Source CI at this freeze is tracked by GitHub run 37280637427.
Godot reports existing shutdown resource diagnostics; these do not alter the
positive functional markers or actual exit-zero results.

The [reference page](https://www.sunholo.com/stapledons-godot/docs/ship-layer-reference)
was built from website commit `56c7e4b`, deployed as `5cd8337`, Pages run
37277483458 succeeded. The downloaded website assembly matches SHA256
`0501920091f062e4c749a77c7fd8a9770acb8b37c7a2cd685cb259f371687058`.
Selected native images, GLB and packed editable Blender masters are public review
assets; raw benchmark hardware profiles and build logs were not uploaded.

This is a technical draft review. Final ink detail and art approval, actual 2022
M2 Air performance, remaining ship districts, GR and Solar System flyby are pending.
No production merge was performed.
