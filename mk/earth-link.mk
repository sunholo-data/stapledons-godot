# R3-EARTH-LINK (design_docs/planned/r3/earth-link.md): Earth's link, the comms station.

# EL3 (K1): the comms station on the spare console: the console, both panes, the rate bands and the
# out-of-beam reasons (tests/test_comms_station.gd). In make ui.
.PHONY: comms-station-test
comms-station-test: import ## R3-EARTH-LINK EL3: the Comms station, its Listen pane and Exchange log, every label bound to earth.*
	@mkdir -p $(SCRATCH)
	@$(GODOT_SIM) --headless --path . --script tests/test_comms_station.gd > $(SCRATCH)/comms-station.log 2>&1; rc=$$?; grep -E '^(FAIL|comms-station)' $(SCRATCH)/comms-station.log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/comms-station.log && grep -q '^comms-station: [0-9]* passed, 0 failures$$' $(SCRATCH)/comms-station.log
ui: comms-station-test

# EL3 (AC9): the comms playthrough (tests/playthrough_comms.json: the Listen pane at Sol, a commit,
# the Exchange log and the Listen pane under way and on arrival) and the display audit of every
# sampled frame against the shared known file (no entry added): every digit on the panes is an
# earth.* binding. In make test through ship-demo-ci.
.PHONY: display-audit-comms
COMMS_OUT := $(SCRATCH)/playthrough/comms
display-audit-comms: import display-audit-controls ## R3-EARTH-LINK AC9: the comms station's panes sampled through a voyage and audited (every digit an earth.* binding)
	@$(MAKE) --no-print-directory AILANG=$(AILANG) playthrough SCRIPT=tests/playthrough_comms.json PLAYTHROUGH_OUT=$(COMMS_OUT)
	@mkdir -p $(SCRATCH)/display-audit/comms
	@$(GODOT_SIM) --headless --path . --script tests/display_audit.gd -- $(COMMS_OUT)/display_samples.ndjson comms $(DISPLAY_KNOWN) > $(SCRATCH)/display-audit/comms/display-audit.log 2>&1; rc=$$?; grep -E '^(FAIL|display-audit)' $(SCRATCH)/display-audit/comms/display-audit.log; test $$rc = 0 && if grep -q 'SCRIPT ERROR:' $(SCRATCH)/display-audit/comms/display-audit.log; then echo "display audit $(SCRATCH)/display-audit/comms/display-audit.log script error"; exit 1; fi && grep -q '^display-audit: .* new=0 .* failures=0$$' $(SCRATCH)/display-audit/comms/display-audit.log && grep -Eq '^ac4: MET \(5 accepted by D-77/D-78\)$$' $(SCRATCH)/display-audit/comms/display-audit.log
ship-demo-ci: display-audit-comms
