### Changed
- The star-name gate is AILANG now (`make star-names`, `sim/tools/star_names.ail`): names.json against stars.json, run on the VM and the interpreter and compared byte for byte with `tools/check_star_names.py`, which is now an independent cross-check rather than the only copy. Both measure the angle with atan2 rather than acos, so tiny angles keep their digits.
- The Crew console's "strained" mark reads its threshold from the scenario pack (`overextended.threshold`), not a hard-coded 70.
- `make python-guard` also checks the Python that `mk/*.mk` and the shell scripts run, not only the Makefile.

### Removed
- `tools/catalogue_probe.py` and `make catalogue-probe`, a dead M1.2b preflight that imported the deleted `tools/extract.py`.
- `Relativity.temperature_for_class`, unused since the binary star loader.
