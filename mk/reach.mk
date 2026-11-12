# R3-REACH RE0 (design_docs/planned/r3/reach-sprint.md): measurement probes on the pinned runtime.
# Headless and CPU only. They measure and record; they fail on a count that does not repeat, a row
# count that is not the catalogue's, or a VM/interpreter difference, never on a budget (RE1b3 gates those).
# Run them one at a time on a quiet host when you can: the report states the load it ran under.
REACH_RUNS ?= 3
.PHONY: reach-probe reach-probe-io reach-probe-inputs gaia-counts
reach-probe-inputs:
	@test -f data/raw/gcns.csv || sh tools/sky_assets.sh fetch inputs 'data/raw/gcns\.csv$$'
	@sh tools/sky_assets.sh verify inputs 'data/raw/gcns\.csv$$'
reach-probe: reach-probe-inputs   ## RE0a: keyed-draw rate, the one-draw gate, full population and the rare query, timed on the VM -> data/reach/probe.json
	@AILANG="$(AILANG)" python3 tools/reach_probe.py vm --runs $(REACH_RUNS) --out data/reach/probe.json
reach-probe-io: reach-probe-inputs   ## RE0b: reading a 14.5 MB float64 registry stand-in, leaf-cell star counts, the pinned Gaia counts -> data/reach/probe_io.json
	@AILANG="$(AILANG)" python3 tools/reach_probe.py io --runs $(REACH_RUNS) --out data/reach/probe_io.json
gaia-counts:   ## RE0b: re-count Gaia DR3 beyond 100 pc at the public archive (network; anonymous) -> data/reach/gaia_counts.json
	@mkdir -p data/reach $(SCRATCH) && sh tools/gaia_count.sh > $(SCRATCH)/gaia_counts.json && mv $(SCRATCH)/gaia_counts.json data/reach/gaia_counts.json
