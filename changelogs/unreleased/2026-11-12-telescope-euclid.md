### Added

- Visible Telescope and Inspect object controls in Navigation, the captain's chair and identified-object cards. Exact object focus is separate from journey planning; observing keeps the clocks running.
- Offline Euclid survey archive with pan/zoom, source picking on a registered Abell 3128 science image, dated facts and credits. M81, NGC 1291 and Abell 3128 colour plates are explicitly unregistered.
- Direction-only Euclid context in the existing map, with the local map camera restored on exit. Survey sources are observation records and cannot become journey targets.
- Hash-pinned image pyramids with bounded tile caches and export staging. Live stellar magnification reuses the existing renderer and honours an explicitly selected star.

Landing authorized by Mark on 2026-11-13 after the combined dev build was published. Independent code review: 80/100 pass; normal export checks and the actual offline app probe pass. New composed-UI GPU cases remain in nightly under the standing busy-GPU rule.
