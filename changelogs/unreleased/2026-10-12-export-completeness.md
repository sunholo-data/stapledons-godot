### Added

- **Export completeness check** (sprint R1-L6-EXPORT-COMPLETENESS; charter L6, clause 5 hygiene). `make export-filter-audit` runs in `make test`: it reads every `res://` literal the shipped code uses and fails when `export_presets.cfg` would drop one. Dynamic prefixes and dev-only paths are declared in `tests/export_audit.gd` with a reason, and a stale row fails. Sixteen named mutants run on every `make test` to prove the audit catches a dropped lens table (the dev.23 failure), an empty scan and a missing extension.
- `make export-pack-check` (rig-only, no export templates): lists a real `--export-pack` zip and checks the measured pack forms, the witnesses and the excluded paths. `make export-pack-check-strict` is the `publish-dev` gate: an absent witness fails there instead of being skipped.

### Fixed

- `spike/` no longer ships in the pack. Its `res://data/raw/hip_v7.tsv` read was dropped by the export anyway, and nothing in the game loads `res://spike/` (`export_presets.cfg` `exclude_filter`).
