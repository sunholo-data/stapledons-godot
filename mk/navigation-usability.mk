.PHONY: navigation-usability-test guided-highlights-strict
navigation-usability-test: import
	@$(GODOT_SIM) --headless --path . --script tests/test_navigation_usability.gd > $(SCRATCH)/navigation-usability.log 2>&1; rc=$$?; cat $(SCRATCH)/navigation-usability.log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/navigation-usability.log && grep -q '^navigation-usability: [1-9][0-9]* checks 0 failures$$' $(SCRATCH)/navigation-usability.log

guided-highlights-strict:
	@mkdir -p $(SCRATCH)
	@$(AILANG) run --quiet --bytecode --strict-bytecode --package-dir sim --entry directHighlightsVm --args-json 0 sim/solar_departure_test.ail > $(SCRATCH)/guided-highlights-vm.txt
	@$(AILANG) run --quiet --package-dir sim --entry directHighlightsVm --args-json 0 sim/solar_departure_test.ail > $(SCRATCH)/guided-highlights-interp.txt
	@cmp $(SCRATCH)/guided-highlights-vm.txt $(SCRATCH)/guided-highlights-interp.txt && grep -q '^guided-highlights: OK$$' $(SCRATCH)/guided-highlights-vm.txt && cat $(SCRATCH)/guided-highlights-vm.txt

test: navigation-usability-test guided-highlights-strict
