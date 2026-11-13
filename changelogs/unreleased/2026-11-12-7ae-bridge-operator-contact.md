### Fixed
- Row 7ae: the bridge-operator contact test and its record now describe the R3-COMMS-V2 desks (56
  checks, the count pinned; each station's facing derived from its desk's scene basis), closing
  main's nightly red at `bridge-operator-test` (30/14 since #379).
- The Voyage and Crew working points step 0.275 m back to the D-132 snug point (1.50 m from the
  desk origin), so the 1.8 m operator capsule is clear of the desk frame (D-148 A); the manifest,
  the deck layout and the asset pins move together.
### Added
- `make bridge-operator-drills`: the contact test's 16 kill drills, enforced against an expected
  table (mutates tracked files; not part of `make test`).
