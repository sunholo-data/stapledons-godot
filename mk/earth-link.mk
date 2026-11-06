# R3-EARTH-LINK (design_docs/implemented/r3/earth-link.md): Earth's link, the comms station.

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
	@$(GODOT_SIM) $(AUDIO_OFF) --path . --resolution 1280x720 --script tools/comms_station_capture.gd > $(SCRATCH)/comms-station-capture.log 2>&1; rc=$$?; grep -E '^comms-station-capture' $(SCRATCH)/comms-station-capture.log; \
	  test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/comms-station-capture.log && grep -q '^comms-station-capture: 4 frames, 0 failures$$' $(SCRATCH)/comms-station-capture.log || { echo "comms-station-capture: FAILED (log $(SCRATCH)/comms-station-capture.log)"; exit 1; }

# Gate2 for the shipped feed/strip and map beams. Preserves all407 existing main cases.
.PHONY: comms-golden
comms-golden: ## R3-COMMS-V2 G-CV (gate 2): the waterfall's trace, line and bracket and the frame diagram's events drawn by the GPU against CPU values (GPU window)
	@mkdir -p $(SCRATCH)
	@$(SCRIPT_GATE) comms-golden $(SCRATCH)/comms-golden.log 600 '^comms-golden: 17 passed, 0 failures$$' -- $(GODOT_SIM) $(AUDIO_OFF) --path . --log-file $(SCRATCH)/comms-golden-engine.log --script tools/comms_golden.gd
golden: comms-golden
.PHONY: earth-link-golden
earth-link-golden:
	@mkdir -p $(SCRATCH)
	@$(GODOT) $(AUDIO_OFF) --path . --log-file $(SCRATCH)/earth-link-golden-engine.log --script tools/earth_display_golden.gd > $(SCRATCH)/earth-link-golden.log 2>&1; rc=$$?; grep -E '^(ok|FAIL|earth-link-golden)' $(SCRATCH)/earth-link-golden.log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/earth-link-golden.log && grep -q '^earth-link-golden: 20 passed, 0 failures$$' $(SCRATCH)/earth-link-golden.log
golden: earth-link-golden
# EL4: Earth's beams on the galaxy map (tests/test_earth_beams.gd): every element from its earth.*
# field, the plan preview alone while planning (AC12), the projection, the real sim at 2.16 and below.
.PHONY: earth-beams-test
earth-beams-test: import ## R3-EARTH-LINK EL4: Earth's beams on the map (heard, pending, stale, window, silence, preview; AC12)
	@mkdir -p $(SCRATCH)
	@$(GODOT_SIM) --headless --path . --script tests/test_earth_beams.gd > $(SCRATCH)/earth-beams.log 2>&1; rc=$$?; grep -E '^(FAIL|earth-beams)' $(SCRATCH)/earth-beams.log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/earth-beams.log && grep -q '^earth-beams: [0-9]* passed, 0 failures$$' $(SCRATCH)/earth-beams.log
ui: earth-beams-test

# EL5 (gate 2): the real sim's earth.rate at 0.99c astern and ahead, the fixture tests/test_physics.gd
# asserts against RS-26 and RS-29. Authoring: regenerate and review the diff.
.PHONY: earth-rate-fixture
earth-rate-fixture: import
	@$(GODOT_SIM) --headless --path . --script tools/earth_rate_fixture.gd 2>&1 | grep -E '^earth-rate-fixture'

# EL5 (AC11): the comms station and the galaxy map at the design's five states from the real sim
# (renders/earth_link/, contact_sheet.png). GPU window; not in make test. Open every frame.
.PHONY: capture-earth-link
capture-earth-link: import
	@mkdir -p $(SCRATCH)
	@$(GODOT_SIM) $(AUDIO_OFF) --path . --script tools/earth_link_capture.gd > $(SCRATCH)/earth-link-capture.log 2>&1; rc=$$?; grep -E '^earth-link-capture' $(SCRATCH)/earth-link-capture.log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/earth-link-capture.log && grep -q '^earth-link-capture: 10 frames, 0 failures$$' $(SCRATCH)/earth-link-capture.log

# R3-COMMS-V2 CV1 (design_docs/planned/r3/comms-station-v2.md AC1-AC4): the received-frame log.
# The log's tests (sim/earth_log_test.ail: the merge, the split, the bound, a real flight's
# invariants every tick, earth_weeks clipping, the 2.18 wire), then earthLogVm on the strict VM and
# the interpreter (they must agree). In make test.
.PHONY: comms-log-test
comms-log-test: ## R3-COMMS-V2 CV1: the received-frame log (nothing from the future, the send event exact, VM = interpreter)
	@cd sim && $(AILANG) test earth_log_test.ail > ../$(SCRATCH)/comms-log-test.log 2>&1; rc=$$?; cd ..; grep -E 'tests:' $(SCRATCH)/comms-log-test.log; test $$rc = 0
	@got=$$($(AILANG) run --quiet --bytecode --strict-bytecode --package-dir sim --entry earthLogVm --args-json 0 sim/earth_log_test.ail); \
	interp=$$($(AILANG) run --quiet --package-dir sim --entry earthLogVm --args-json 0 sim/earth_log_test.ail); \
	echo "comms-log-test: VM $$got | interpreter $$interp"; [ "$$got" = "earth-log-ok" ] && [ "$$interp" = "earth-log-ok" ]
test: comms-log-test

# R3-COMMS-V2 CV1: the bridge keeps the 2.18 log (tail filing by from_frame; a real voyage's stored
# log contiguous, ending at the feed's frame, on the light cone at every tick). In make test.
.PHONY: comms-log-bridge-test
comms-log-bridge-test: import ## R3-COMMS-V2 CV1: the bridge's earth_log storage against the real sim at 2.18
	@mkdir -p $(SCRATCH)
	@$(SCRIPT_GATE) comms-log-bridge-test $(SCRATCH)/comms-log-bridge.log 600 '^comms-log-bridge: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT_SIM) --headless --path . --script tests/test_earth_log_bridge.gd
test: comms-log-bridge-test

# R3-COMMS-V2 CV2 (AC5, AC6): the history wall and the frame diagram on the real sim at 2.18
# (tests/test_earth_history.gd). In make ui.
.PHONY: comms-history-test
comms-history-test: import ## R3-COMMS-V2 CV2: the history wall (every week, along ship time) and the frame diagram (light at 45 degrees, bindings)
	@mkdir -p $(SCRATCH)
	@$(SCRIPT_GATE) comms-history-test $(SCRATCH)/comms-history.log 600 '^comms-history: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT_SIM) --headless --path . --script tests/test_earth_history.gd
ui: comms-history-test

# R3-COMMS-V2 CV3 (AC7): the waterfall of the signal from home: the measured True carrier at 400 x D,
# above/below hearing, the Receiver's line, silent analysis taps, the no-rate-times-frequency guard
# (tests/test_comms_waterfall.gd; headless, the Dummy driver mixes). In make test.
.PHONY: comms-waterfall-test
comms-waterfall-test: import ## R3-COMMS-V2 CV3: the waterfall (True carrier measured at 400 x D; hearing edges; silent taps)
	@mkdir -p $(SCRATCH)
	@$(SCRIPT_GATE) comms-waterfall-test $(SCRATCH)/comms-waterfall.log 600 '^comms-waterfall: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT_SIM) --headless --path . --script tests/test_comms_waterfall.gd
test: comms-waterfall-test

# R3-COMMS-V2 CV6 (AC8): the bridge's ambient monitors from the manifest (wall R): built at their
# anchors facing the deck, camera occluders, every number on every face a binding on the real sim at
# 2.18, faces following the world, rendering gated to on-screen (tests/test_bridge_monitors.gd).
.PHONY: bridge-monitors-test
.PHONY: monitor-rail-test
monitor-rail-test: import ## R3-COMMS-V2 (Mark 2026-11-03): no monitor frame, stalk or face crosses the bow rail or any other bridge prop; a monitor pushed into the rail is caught
	@mkdir -p $(SCRATCH)
	@$(SCRIPT_GATE) monitor-rail-test $(SCRATCH)/monitor-rail.log 600 '^monitor-rail: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT) --headless --path . --script tests/test_monitor_rail.gd
test: monitor-rail-test

bridge-monitors-test: import ## R3-COMMS-V2 CV6: the ambient bridge monitors (anchors, occluders, bound faces, gated rendering)
	@mkdir -p $(SCRATCH)
	@$(SCRIPT_GATE) bridge-monitors-test $(SCRATCH)/bridge-monitors.log 600 '^bridge-monitors: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT_SIM) --headless --path . --script tests/test_bridge_monitors.gd
test: bridge-monitors-test

# R3-COMMS-V2 review captures (AC12; GPU window): the bridge with the consoles under the screens and the
# monitor wall on the live 2.18 session, the console zooms and the station's detail view.
.PHONY: capture-comms-v2
COMMS_TAG ?= mid
capture-comms-v2: import ## R3-COMMS-V2: the bridge, monitors and comms station on the live sim -> renders/comms_v2/$(COMMS_TAG)/*.png (GPU window; open every frame)
	@mkdir -p $(SCRATCH)
	@$(SCRIPT_GATE) capture-comms-v2 $(SCRATCH)/comms-v2-capture.log 600 '^comms-v2-capture: done -> .+$$' -- $(GODOT_SIM) $(AUDIO_OFF) --path . --script tools/comms_v2_capture.gd -- --out=res://renders/comms_v2/$(COMMS_TAG)
	@$(SCRIPT_GATE) capture-comms-v2 $(SCRATCH)/comms-station-capture.log 600 '^comms-station-capture: [1-9][0-9]* frames, 0 failures$$' -- $(GODOT_SIM) $(AUDIO_OFF) --path . --script tools/comms_station_capture.gd -- --out=res://renders/comms_v2/$(COMMS_TAG)
