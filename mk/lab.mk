# R3-UNIVERSE-LAB (design_docs/planned/r3/universe-lab.md): the scenario runner's headless gates.

# UL0a: the speed probes that need no detector (sim/tools/lab_probe.ail), timed from outside by
# tools/lab_probe.py on whatever $(AILANG) is: use the pinned runtime
# (PATH=$$PWD/runtime/bin:$$PATH, or AILANG=runtime/bin/ailang). A few minutes; it starts up
# to 12 processes for a few seconds at a time. Never in make test or ci-fast: a timing is not
# a gate. Values that differ between runs, or between the strict VM and the interpreter, fail
# it; a missed budget is printed and recorded, and is a stop for the owner (sprint plan,
# pause 1), not a failure of this command.
.PHONY: lab-probe lab-probe-parity lab-probe-check
lab-probe: ## R3-UNIVERSE-LAB UL0a: draw loop, quadrature, order-statistic intervals, a 500,000-row filter and 1/4/8/12 processes, three runs each with the host load -> data/lab/probe.json
	@AILANG="$(AILANG)" python3 -I tools/lab_probe.py --out data/lab/probe.json

# The committed measurements say what their own runs say: each file's budgets are re-derived
# from its recorded runs under the harness's rules (every budget on its worst run, never the
# mean) and must equal what is stored, and each records the host's core layout. Measures
# nothing; in make test.
lab-probe-check: ## R3-UNIVERSE-LAB UL0a: data/lab/probe*.json carry the budgets their recorded runs give, each judged on its worst run
	@AILANG="$(AILANG)" python3 -I tools/lab_probe.py --verify $(sort $(wildcard data/lab/probe*.json))
test: lab-probe-check

# Every probe entry on the strict VM and on the interpreter, byte for byte, at small sizes.
# In make strict and make parity (so ci-fast): the probes stay strict-VM clean.
lab-probe-parity: ## R3-UNIVERSE-LAB UL0a: sim/tools/lab_probe.ail runs wholly on the strict VM and agrees with the interpreter byte for byte
	@mkdir -p $(SCRATCH)
	@for spec in 'draws 2000' 'quadrature 64' 'intervals 2' 'filterSmall 8'; do \
	  set -- $$spec; \
	  $(AILANG) run --quiet --bytecode --strict-bytecode --package-dir sim --entry $$1 --args-json $$2 sim/tools/lab_probe.ail > $(SCRATCH)/lab-probe-$$1-vm.txt || { echo "lab-probe-parity: FAIL $$1 (strict VM)"; exit 1; }; \
	  $(AILANG) run --quiet --package-dir sim --entry $$1 --args-json $$2 sim/tools/lab_probe.ail > $(SCRATCH)/lab-probe-$$1-interp.txt || { echo "lab-probe-parity: FAIL $$1 (interpreter)"; exit 1; }; \
	  cmp $(SCRATCH)/lab-probe-$$1-vm.txt $(SCRATCH)/lab-probe-$$1-interp.txt || { echo "lab-probe-parity: FAIL $$1: strict VM != interpreter"; exit 1; }; \
	  grep -q "^[a-z]* [a-z]*=" $(SCRATCH)/lab-probe-$$1-vm.txt || { echo "lab-probe-parity: FAIL $$1 printed $$(cat $(SCRATCH)/lab-probe-$$1-vm.txt)"; exit 1; }; \
	done; \
	echo "lab-probe-parity: draws, quadrature, intervals, filter identical (strict VM = interpreter)"
strict parity: lab-probe-parity

# UL3a: the scenario format (sim/lab_scenario.ail). lab-test is the lab's unit gate: the named
# checks, then the strict VM against the interpreter, then the committed scenario files. In
# make test. Later lab modules add their test file and their parity entries to the two lists.
LAB_TESTS := lab_scenario_test.ail
LAB_PARITY := lab_scenario_test:scenarioVm:scenario-ok lab_scenario_test:scenarioProbe:
LAB_SCENARIOS := $(sort $(wildcard data/lab/scenarios/*.json))
LAB_RUN = $(AILANG) run --quiet --package-dir sim
.PHONY: lab-test lab-parity lab-scenarios
lab-test: lab-parity lab-scenarios ## R3-UNIVERSE-LAB UL3: the lab's named checks (scenario format: refusals, round trip, digest), strict VM = interpreter, and the committed scenario files (AC5)
	@mkdir -p $(SCRATCH)
	@cd sim && $(AILANG) test $(LAB_TESTS) > ../$(SCRATCH)/lab-test.log 2>&1; rc=$$?; cd ..; grep -E 'tests:' $(SCRATCH)/lab-test.log; test $$rc = 0 || { grep -B1 -A3 'expected' $(SCRATCH)/lab-test.log; exit 1; }
test: lab-test

# Each entry on the strict VM and on the interpreter, byte for byte; an entry with a third
# field must print exactly that. In make strict and make parity (so ci-fast).
lab-parity: ## R3-UNIVERSE-LAB UL3: the lab's pure modules run wholly on the strict VM and agree with the interpreter byte for byte
	@mkdir -p $(SCRATCH)
	@for spec in $(LAB_PARITY); do \
	  f=$${spec%%:*}; rest=$${spec#*:}; e=$${rest%%:*}; want=$${rest#*:}; \
	  $(LAB_RUN) --bytecode --strict-bytecode --entry $$e --args-json 0 sim/$$f.ail > $(SCRATCH)/lab-$$e-vm.txt || { echo "lab-parity: FAIL $$e (strict VM)"; exit 1; }; \
	  $(LAB_RUN) --entry $$e --args-json 0 sim/$$f.ail > $(SCRATCH)/lab-$$e-interp.txt || { echo "lab-parity: FAIL $$e (interpreter)"; exit 1; }; \
	  cmp $(SCRATCH)/lab-$$e-vm.txt $(SCRATCH)/lab-$$e-interp.txt || { echo "lab-parity: FAIL $$e: strict VM != interpreter"; exit 1; }; \
	  test -s $(SCRATCH)/lab-$$e-vm.txt || { echo "lab-parity: FAIL $$e printed nothing"; exit 1; }; \
	  if [ -n "$$want" ]; then test "$$(cat $(SCRATCH)/lab-$$e-vm.txt)" = "$$want" || { echo "lab-parity: FAIL $$e: $$(cat $(SCRATCH)/lab-$$e-vm.txt)"; exit 1; }; fi; \
	  echo "lab-parity: $$e $${want:-$$(wc -c < $(SCRATCH)/lab-$$e-vm.txt | tr -d ' ') bytes} (strict VM = interpreter)"; \
	done
strict parity: lab-parity

# The committed scenario files through the tool shell (sim/tools/lab_scenarios.ail): every one
# is accepted, the file name is the id, and `literature` has no departures (AC5). Then the
# failing control: a file with a departure and no reason must be refused, by that sentence, with
# exit 1. A tool that accepted everything would pass the first half and fail here.
lab-scenarios: ## R3-UNIVERSE-LAB UL3a: every data/lab/scenarios/*.json is accepted and literature has no departures; a departure with no reason is refused (control)
	@mkdir -p $(SCRATCH)
	@args=$$(printf '"%s",' $(LAB_SCENARIOS)); $(LAB_RUN) --caps IO,FS --entry main --args-json "[$${args%,}]" sim/tools/lab_scenarios.ail > $(SCRATCH)/lab-scenarios.txt \
	  || { cat $(SCRATCH)/lab-scenarios.txt; echo "lab-scenarios: FAIL a committed scenario is refused"; exit 1; }
	@grep -qE '^literature@[0-9]+ sha256=[0-9a-f]{64} departures=0 \[\]$$' $(SCRATCH)/lab-scenarios.txt || { cat $(SCRATCH)/lab-scenarios.txt; echo "lab-scenarios: FAIL literature is missing or has departures"; exit 1; }
	@test "$$(wc -l < $(SCRATCH)/lab-scenarios.txt | tr -d ' ')" = "$(words $(LAB_SCENARIOS))" || { echo "lab-scenarios: FAIL one line per file expected"; exit 1; }
	@if $(LAB_RUN) --caps IO,FS --entry main --args-json '["tests/fixtures/lab/refused/no-reason.json"]' sim/tools/lab_scenarios.ail > $(SCRATCH)/lab-scenarios-control.txt; then echo "lab-scenarios: FAIL the control was accepted"; exit 1; fi
	@grep -qF 'REFUSED tests/fixtures/lab/refused/no-reason.json: switch "lifetime_prior" departs from the literature and has no reason' $(SCRATCH)/lab-scenarios-control.txt || { cat $(SCRATCH)/lab-scenarios-control.txt; echo "lab-scenarios: FAIL the control was refused for another reason"; exit 1; }
	@sed 's/^/lab-scenarios: /' $(SCRATCH)/lab-scenarios.txt; echo "lab-scenarios: $(words $(LAB_SCENARIOS)) scenarios accepted, literature has no departures; the control (a departure with no reason) is refused"
