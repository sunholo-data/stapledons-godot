### Added

- Pure AILANG CSV catalogue transform using the locked dwarf and white-dwarf
  photometry package, preserving coordinates, missing/clamped flags and counters.
- Stable nearest-complete selection for medium (50,000 rows), with quick/large
  preserving source order. Binary writing and full-catalogue integration remain pending.
- Ten exact fixture tests and `make catalogue-vm`, which checks transform and
  selection anchors on the strict VM and compares interpreter output byte for byte.
