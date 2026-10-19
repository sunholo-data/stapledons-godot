### Added

- `make capture-m4` records the 3D ship's first journey from the captain's eye:
  seven real sim states, deck and forward views, a contact sheet, and world/PNG
  manifests, with blank, duplicate, state and stale-output checks.
- `make capture-m4-publish` verifies and uploads the 18-file S1 reference set.
- `make bench SCENE=bridge` measures live transit at 2560×1440 with vsync off
  and the medium star tier. It reports a docked control, nearest-rank frame
  percentiles and JSON evidence, rejecting invalid runs and p99 ≥16.7 ms.
  The default starfield benchmark remains unchanged; S1 review and the live
  transit performance gate still require measurements on the GPU host.
