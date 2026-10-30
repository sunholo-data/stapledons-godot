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

# EL3b.3: Earth's feed at the comms station (tests/test_earth_feed.gd): the week's picture from the
# sim's earth.feed, the band by D, the frozen last beamed week under static, the ring, the clocks.
.PHONY: earth-feed-test
earth-feed-test: import ## R3-EARTH-LINK EL3b: Earth's feed (picture by earth.feed, band by D, static and ring out of beam, clocks), every number bound
	@mkdir -p $(SCRATCH)
	@$(GODOT_SIM) --headless --path . --script tests/test_earth_feed.gd > $(SCRATCH)/earth-feed.log 2>&1; rc=$$?; grep -E '^(FAIL|earth-feed)' $(SCRATCH)/earth-feed.log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/earth-feed.log && grep -q '^earth-feed: [0-9]* passed, 0 failures$$' $(SCRATCH)/earth-feed.log
ui: earth-feed-test

# EL3b.2: the feed's picture library. The sim's catalogue (sim/data/feed_events.ail), events.json and
# data/feed/SOURCES name the same events, and every shipped picture matches its pin. In make test.
.PHONY: feed-art-check
feed-art-check: ## R3-EARTH-LINK EL3b: catalogue = events.json = SOURCES, and every feed picture matches its sha256 pin
	@set -e; sim=$$($(AILANG) run --quiet --package-dir sim --entry feedIdsText --args-json 0 sim/data/feed_events.ail | tr -d '"' | sed 's/\\n/\n/g' | sort); \
	json=$$(jq -r '.events[].id' data/feed/events.json | sort); \
	src=$$(sed -nE 's/^([a-z0-9-]+)_v[0-9]+\.webp sha256 .*/\1/p' data/feed/SOURCES | sort -u); \
	[ "$$sim" = "$$json" ] || { echo "feed-art-check: FAIL: events.json ids differ from sim/data/feed_events.ail"; exit 1; }; \
	[ "$$sim" = "$$src" ] || { echo "feed-art-check: FAIL: data/feed/SOURCES does not picture every catalogue event"; exit 1; }; \
	sed -nE 's/^([a-z0-9-]+_v[0-9]+\.webp) sha256 ([0-9a-f]{64}) .*/\2  \1/p' data/feed/SOURCES > $(SCRATCH)/feed-pins.txt; \
	(cd data/feed/pictures && shasum -a 256 -c --quiet $(abspath $(SCRATCH))/feed-pins.txt) || { echo "feed-art-check: FAIL: a picture differs from its pin"; exit 1; }; \
	live=$$(jq -r '.live_style' data/feed/events.json); ai=$$($(AILANG) run --quiet --package-dir ai --entry feedStyleText --args-json 0 ai/prompt.ail); \
	[ -n "$$live" ] && [ "$$live" = "$$ai" ] || { echo "feed-art-check: FAIL: ai/prompt.ail feedStyle differs from data/feed/events.json live_style"; exit 1; }; \
	echo "feed-art-check: ok ($$(echo "$$sim" | wc -l | tr -d ' ') events, $$(wc -l < $(SCRATCH)/feed-pins.txt | tr -d ' ') pictures)"
test: feed-art-check

# EL3b.5: the comms station at four moments of a real voyage (tools/comms_station_capture.gd), for
# Mark's render review. Needs a GPU window; never in make test.
.PHONY: capture-comms-station
capture-comms-station: import ## R3-EARTH-LINK EL3b.5: the comms station at home, away, waiting and homeward from the real sim -> renders/comms_station/*.png (GPU window; open every frame)
	@mkdir -p $(SCRATCH)
	@$(GODOT_SIM) --path . --resolution 1280x720 --script tools/comms_station_capture.gd > $(SCRATCH)/comms-station-capture.log 2>&1; rc=$$?; grep -E '^comms-station-capture' $(SCRATCH)/comms-station-capture.log; \
	  test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/comms-station-capture.log && grep -q '^comms-station-capture: 4 frames, 0 failures$$' $(SCRATCH)/comms-station-capture.log || { echo "comms-station-capture: FAILED (log $(SCRATCH)/comms-station-capture.log)"; exit 1; }

# Gate2 for the existing feed/strip. A separate family preserves all407 existing main cases.
.PHONY: earth-link-golden
earth-link-golden:
	@mkdir -p $(SCRATCH)
	@$(GODOT) --path . --log-file $(SCRATCH)/earth-link-golden-engine.log --script tools/earth_link_golden.gd > $(SCRATCH)/earth-link-golden.log 2>&1; rc=$$?; grep -E '^(ok|FAIL|earth-link-golden)' $(SCRATCH)/earth-link-golden.log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/earth-link-golden.log && grep -q '^earth-link-golden: 11 passed, 0 failures$$' $(SCRATCH)/earth-link-golden.log
golden: earth-link-golden
