### Added
- The relativistic sky's reference renders now include 0.999c (forward, starboard, astern, port, off-axis, rolled); `make capture` shoots 0, 0.5, 0.9, 0.99 and 0.999c. The 15 reviewed frames and the contact sheet are pinned in `data/refs/m1_sky_manifest.sha256` and served from the public bucket (`make m1-refs`). (M1.5b, AC9)
- The bright-star render gate runs on real renders: `make capture` also writes six rest-frame cube faces with the predicted pixel of every V < 6.5 star, and `make bright-audit` checks them (M1.5b, AC11).

### Changed
- M1, the relativistic sky, is landed: design and both sprint plans moved to `design_docs/implemented/r1/`, with the evidence in `m1-report.md`.
