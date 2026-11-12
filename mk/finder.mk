# R3-REASONS (design_docs/planned/r3/reasons-to-travel.md): the destination finder's Godot side.
.PHONY: reason-card-test capture-reason-card

reason-card-test: import ## R3-REASONS RT5a: the reason card on the example fixture: every number bound, offers and needs, time-first cost, state bars, what is drawn in True and Processed, no judging word
	@mkdir -p $(SCRATCH)
	@$(SCRIPT_GATE) reason-card-test $(SCRATCH)/reason-card-test.log 120 '^reason-card: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT) --headless --path . --script tests/test_reason_card.gd
ui: reason-card-test

capture-reason-card: import ## R3-REASONS RT5a: the card for each example candidate, True and Processed -> renders/reason_card/*.png (GPU window; open every frame)
	@mkdir -p $(SCRATCH)
	@$(SCRIPT_GATE) capture-reason-card $(SCRATCH)/capture-reason-card.log 300 '^reason-card-capture: 8 frames$$' -- $(GODOT) $(AUDIO_OFF) --path . --resolution 1280x720 --script tools/reason_card_capture.gd

# RT3b (AC6): the finder's maths in the sim (sim/finder.ail). The prediction at arrival is one
# sunholo/worlds propagateExact call over light age + travel time, and a leg's Earth years, ship
# years and mass equal the journey core's plan exactly. The tests (sim/finder_test.ail), then
# finder-parity. In make test.
.PHONY: finder-test finder-parity
finder-test: finder-parity ## R3-REASONS RT3b: the prediction at arrival and a leg's cost (Earth years, ship years, mass) equal to the plan (AC6); VM = interpreter
	@mkdir -p $(SCRATCH)
	@cd sim && $(AILANG) test finder_test.ail > ../$(SCRATCH)/finder-test.log 2>&1; rc=$$?; cd ..; grep -E 'tests:' $(SCRATCH)/finder-test.log; test $$rc = 0
test: finder-test

# finderVm (every check) and finderProbe (every float the finder produces, on both legs) on the
# strict VM and on the interpreter: byte-identical. In make strict and make parity (so ci-fast).
finder-parity: ## R3-REASONS RT3b: sim/finder.ail runs wholly on the strict VM and agrees with the interpreter byte for byte
	@mkdir -p $(SCRATCH)
	@for e in finderVm finderProbe; do \
	  $(AILANG) run --quiet --bytecode --strict-bytecode --package-dir sim --entry $$e --args-json 0 sim/finder_test.ail > $(SCRATCH)/finder-$$e-vm.txt || { echo "finder-parity: FAIL $$e (strict VM)"; exit 1; }; \
	  $(AILANG) run --quiet --package-dir sim --entry $$e --args-json 0 sim/finder_test.ail > $(SCRATCH)/finder-$$e-interp.txt || { echo "finder-parity: FAIL $$e (interpreter)"; exit 1; }; \
	  cmp $(SCRATCH)/finder-$$e-vm.txt $(SCRATCH)/finder-$$e-interp.txt || { echo "finder-parity: FAIL $$e: strict VM != interpreter"; exit 1; }; \
	done; \
	test "$$(cat $(SCRATCH)/finder-finderVm-vm.txt)" = finder-ok || { echo "finder-parity: FAIL finderVm: $$(cat $(SCRATCH)/finder-finderVm-vm.txt)"; exit 1; }; \
	echo "finder-parity: finderVm finder-ok; finderProbe $$(wc -c < $(SCRATCH)/finder-finderProbe-vm.txt | tr -d ' ') bytes identical (strict VM = interpreter)"
strict parity: finder-parity
