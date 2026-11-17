# Approved PLAYABLE-SHIP-FINISH evidence slice; include after the project Makefile.
.PHONY: ship-finish-test ship-finish-profile-test ship-finish-review-report ship-finish-route-test ship-finish-route-live-test
ship-finish-test:
	@mkdir -p $(SCRATCH)
	@$(SCRIPT_GATE) ship-finish-ready $(SCRATCH)/ship-finish-ready.log 180 '^ship-review-readiness: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT) --headless --path . --log-file $(SCRATCH)/ship-finish-ready-engine.log --script tests/test_ship_review_readiness.gd
	@$(SCRIPT_GATE) ship-finish-invariants $(SCRATCH)/ship-finish-invariants.log 180 '^painted-levels-invariants: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT) --headless --path . --log-file $(SCRATCH)/ship-finish-invariants-engine.log --script tests/test_painted_levels.gd
ship-finish-profile-test:
	@mkdir -p $(SCRATCH)
	@$(SCRIPT_GATE) ship-finish-profile $(SCRATCH)/ship-finish-profile.log 60 '^ship-finish-profile: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT) --headless --path . --log-file $(SCRATCH)/ship-finish-profile-engine.log --script tests/test_ship_finish_profile.gd
	@$(SCRIPT_GATE) ship-finish-report $(SCRATCH)/ship-finish-report.log 60 '^ship-finish-report: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT) --headless --path . --log-file $(SCRATCH)/ship-finish-report-engine.log --script tests/test_ship_finish_report.gd
	@$(SCRIPT_GATE) ship-finish-headless-refusal $(SCRATCH)/ship-finish-headless.log 60 '^ship-finish-review: REFUSED .*headless performance measurement refused' 2 -- $(GODOT) --headless --path . --log-file $(SCRATCH)/ship-finish-headless-engine.log -- --ship-finish-review=/private/tmp/ship-finish-refused
ship-finish-route-test:
	@mkdir -p $(SCRATCH)
	@$(SCRIPT_GATE) ship-finish-route $(SCRATCH)/ship-finish-route.log 120 '^ship-finish-route: [1-9][0-9]* passed, 0 failures ' -- $(GODOT_SIM) --headless --path . --log-file $(SCRATCH)/ship-finish-route-engine.log --script tests/test_ship_finish_route.gd
ship-finish-route-live-test:
	@mkdir -p $(SCRATCH)
	@$(SCRIPT_GATE) ship-finish-route-live $(SCRATCH)/ship-finish-route-live.log 240 '^ship-finish-route: [1-9][0-9]* passed, 0 failures ' -- $(GODOT_SIM) --headless --path . --log-file $(SCRATCH)/ship-finish-route-live-engine.log --script tests/test_ship_finish_route.gd -- --live
ship-finish-review-report:
	@mkdir -p $(SCRATCH)
	@$(SCRIPT_GATE) ship-finish-report-check $(SCRATCH)/ship-finish-report-check.log 60 '^ship-finish-report-check: VALID ' -- $(GODOT) --headless --path . --log-file $(SCRATCH)/ship-finish-report-check-engine.log --script tools/ship_finish_report_check.gd -- --report='$(REPORT)'
