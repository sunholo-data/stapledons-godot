### Added

- **Hand-written catalogue targets are checked at their PR** (7am, sprint R1-7AM-ALPHA-INDEX). `make replay-map-index` (already in `ci-fast` and `make test`) now also scans tracked `*.gd` and `*.py` sources for hand-written `"index"`/`"id"` pairs. The scan is dictionary-aware and takes either key order, with `\"`, `\\` and `\uXXXX` decoding in id literals; any other escape fails by name. A new wrong pair fails at its PR. `tools/earth_link_capture.gd` stays at index 1 as the guard's one pending entry until Mark answers OQ1. The `ci-fast: replay-map-index` edge joins `SG_PREREQS` (pin 5), so dropping the edge fails `script-gate-lint` by name.

### Fixed

- **Every hand-copied catalogue target carries its real `stars.json` index** (7am). Fourteen literals in ten files were wrong: alpha Cen A at 1 or 0 (now 2, nine sites), Sirius A at 2 (now 9, four sites), and Aldebaran at 2 (now 3158, one site). Visible behaviour is unchanged. The sim echoes the index bytes only.
- The 7ai control in `tools/test_replay.py` derives its indices from `stars.json`, so a catalogue reorder no longer false-fails it.
