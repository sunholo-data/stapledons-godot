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
# make test. Later lab modules add their test file, their parity entries and, if any of their
# checks cannot run on the strict VM, the entry that names them.
LAB_TESTS := lab_scenario_test.ail lab_stats_test.ail
LAB_PARITY := lab_scenario_test:scenarioVm:scenario-ok lab_scenario_test:scenarioProbe: lab_stats_test:statsVm:stats-ok lab_stats_test:statsProbe:
LAB_NOT_STRICT := lab_scenario_test:scenarioNotStrict lab_stats_test:statsNotStrict
LAB_SCENARIOS := $(sort $(wildcard data/lab/scenarios/*.json))
LAB_DEPARTURES := data/lab/baseline_departures.json
LAB_RUN = $(AILANG) run --quiet --package-dir sim
.PHONY: lab-test lab-parity lab-scenarios lab-stats-oracle
lab-test: lab-parity lab-scenarios lab-stats-oracle ## R3-UNIVERSE-LAB UL3: the lab's named checks (scenario format; statistics), strict VM = interpreter, the committed scenario files (AC5) and the statistics oracle
	@mkdir -p $(SCRATCH)
	@cd sim && $(AILANG) test $(LAB_TESTS) > ../$(SCRATCH)/lab-test.log 2>&1; rc=$$?; cd ..; grep -E 'tests:' $(SCRATCH)/lab-test.log; test $$rc = 0 || { grep -B1 -A3 'expected' $(SCRATCH)/lab-test.log; exit 1; }
	@# The gap below is a test that passes today and fails at the bump; this line keeps it in sight.
	@grep -q 'KNOWN GAP (v0.56.1' $(SCRATCH)/lab-test.log && echo "lab-test: KNOWN GAP on the pinned AILANG v0.56.1: a scenario file with text after its closing brace is accepted and shares a digest (std/json decode; fixed upstream by v0.60.0; not worked around). Re-check at the next runtime bump: the KNOWN GAP test fails then and is flipped."
test: lab-test

# Each entry on the strict VM and on the interpreter, byte for byte; an entry with a third
# field must print exactly that. The last line names every check that is NOT in a strict-VM
# entry, with its upstream issue, read from the test modules. In make strict and make parity
# (so ci-fast).
lab-parity: ## R3-UNIVERSE-LAB UL3: the lab's pure modules run wholly on the strict VM and agree with the interpreter byte for byte; names the checks that cannot yet
	@mkdir -p $(SCRATCH)
	@for spec in $(LAB_PARITY); do \
	  f=$${spec%%:*}; rest=$${spec#*:}; e=$${rest%%:*}; want=$${rest#*:}; \
	  env -u AI_LIVE $(LAB_RUN) --bytecode --strict-bytecode --entry $$e --args-json 0 sim/$$f.ail > $(SCRATCH)/lab-$$e-vm.txt || { echo "lab-parity: FAIL $$e (strict VM)"; exit 1; }; \
	  env -u AI_LIVE $(LAB_RUN) --entry $$e --args-json 0 sim/$$f.ail > $(SCRATCH)/lab-$$e-interp.txt || { echo "lab-parity: FAIL $$e (interpreter)"; exit 1; }; \
	  cmp $(SCRATCH)/lab-$$e-vm.txt $(SCRATCH)/lab-$$e-interp.txt || { echo "lab-parity: FAIL $$e: strict VM != interpreter"; exit 1; }; \
	  test -s $(SCRATCH)/lab-$$e-vm.txt || { echo "lab-parity: FAIL $$e printed nothing"; exit 1; }; \
	  if [ -n "$$want" ]; then test "$$(cat $(SCRATCH)/lab-$$e-vm.txt)" = "$$want" || { echo "lab-parity: FAIL $$e: $$(cat $(SCRATCH)/lab-$$e-vm.txt)"; exit 1; }; fi; \
	  echo "lab-parity: $$e $${want:-$$(wc -c < $(SCRATCH)/lab-$$e-vm.txt | tr -d ' ') bytes} (strict VM = interpreter)"; \
	done
	@: > $(SCRATCH)/lab-not-strict.txt; for spec in $(LAB_NOT_STRICT); do \
	  env -u AI_LIVE $(LAB_RUN) --bytecode --strict-bytecode --entry $${spec#*:} --args-json 0 sim/$${spec%%:*}.ail >> $(SCRATCH)/lab-not-strict.txt || { echo "lab-parity: FAIL $${spec#*:}"; exit 1; }; \
	done; \
	n=$$(tr ',' '\n' < $(SCRATCH)/lab-not-strict.txt | grep -c 'ailang#'); \
	echo "lab-parity: $$n checks NOT on the strict VM (they run under ailang test only; add them back at the fix): $$(paste -sd';' $(SCRATCH)/lab-not-strict.txt | sed 's/;/; /g')"
strict parity: lab-parity

# The committed scenario files through the tool shell (sim/tools/lab_scenarios.ail). It prints
# the registry baseline's own departures from the literature first (the mirror in
# $(LAB_DEPARTURES)), then every scenario: each is accepted, the file name is the id, each names
# the mirror's departures table, and `baseline` has no departures of its own (AC5). Then two
# failing controls, each refused by its own sentence with exit 1: a departure with no reason,
# and a scenario that names another departures table. A tool that accepted everything would
# pass the first half and fail here.
lab-scenarios: ## R3-UNIVERSE-LAB UL3a: the registry baseline's departures, then every data/lab/scenarios/*.json accepted, baseline with none of its own; two refused controls
	@mkdir -p $(SCRATCH)
	@args=$$(printf '"%s",' $(LAB_DEPARTURES) $(LAB_SCENARIOS)); $(LAB_RUN) --caps IO,FS --entry main --args-json "[$${args%,}]" sim/tools/lab_scenarios.ail > $(SCRATCH)/lab-scenarios.txt \
	  || { cat $(SCRATCH)/lab-scenarios.txt; echo "lab-scenarios: FAIL a committed scenario or the departures mirror is refused"; exit 1; }
	@grep -qE '^baseline@[0-9]+ sha256=[0-9a-f]{64} departures=0 \[\]$$' $(SCRATCH)/lab-scenarios.txt || { cat $(SCRATCH)/lab-scenarios.txt; echo "lab-scenarios: FAIL baseline is missing or has departures of its own"; exit 1; }
	@grep -qE '^registry baseline-[0-9.]+: [1-9][0-9]* deliberate departures from the literature' $(SCRATCH)/lab-scenarios.txt || { echo "lab-scenarios: FAIL the registry's departures were not printed"; exit 1; }
	@test "$$(grep -c 'sha256=' $(SCRATCH)/lab-scenarios.txt)" = "$(words $(LAB_SCENARIOS))" || { echo "lab-scenarios: FAIL one line per scenario file expected"; exit 1; }
	@for c in 'no-reason:switch "lifetime_prior" departs from the registry baseline and has no reason' 'other-table:it names the departures table'; do \
	  f=tests/fixtures/lab/refused/$${c%%:*}.json; \
	  if $(LAB_RUN) --caps IO,FS --entry main --args-json "[\"$(LAB_DEPARTURES)\",\"$$f\"]" sim/tools/lab_scenarios.ail > $(SCRATCH)/lab-scenarios-control.txt; then echo "lab-scenarios: FAIL the control $$f was accepted"; exit 1; fi; \
	  grep -qF "REFUSED $$f: $${c#*:}" $(SCRATCH)/lab-scenarios-control.txt || { cat $(SCRATCH)/lab-scenarios-control.txt; echo "lab-scenarios: FAIL the control $$f was refused for another reason"; exit 1; }; \
	done
	@sed 's/^/lab-scenarios: /' $(SCRATCH)/lab-scenarios.txt | cut -c1-200; echo "lab-scenarios: $(words $(LAB_SCENARIOS)) scenarios accepted against the registry baseline's $$(grep -c '^registry departure' $(SCRATCH)/lab-scenarios.txt) listed departures; baseline has none of its own; 2 controls refused (a departure with no reason; another departures table)"

# UL3c: sim/lab_stats.ail against an independent reference in a second language
# (tools/lab_stats_ref.py, role oracle, standard library only): order-statistic ranks for every
# n from 1 to 1,024 at the 10th percentile, the median and the 90th by exact integer binomial
# tails; Student t by the incomplete beta function; mean, spread, standard error, intervals and
# the met / missed / unsettled verdicts on shared samples (n = 0, 1, 2, 5, 8, ties, all equal,
# 64, 128, 1,024); the stopping level (0.05 over the looks a rule allows) with its t points
# and ranks for two rules; and a seeded simulation of the WHOLE rule, 10,000 runs of 16 looks
# with the truth on a band's edge, which fails the gate if a wrong "met" or a wrong "missed"
# exceeds 2.5 %. It also fails if the committed reference is not what the oracle computes.
# The last line is the module's own smaller simulation (a 16-look rule of 8 seeds, 200 runs).
lab-stats-oracle: ## R3-UNIVERSE-LAB UL3c: the lab's statistics equal the Python oracle's committed reference (exact binomial ranks, Student t, verdicts, the stopping level) and the whole stopping rule keeps its error under 2.5 % each way in simulation
	@mkdir -p $(SCRATCH)
	@$(LAB_RUN) --bytecode --strict-bytecode --entry statsOracle --args-json 0 sim/lab_stats_test.ail > $(SCRATCH)/lab-stats-oracle.json || { echo "lab-stats-oracle: FAIL statsOracle (strict VM)"; exit 1; }
	@python3 -I tools/lab_stats_ref.py --check tests/fixtures/lab/stats_reference.json $(SCRATCH)/lab-stats-oracle.json
	@echo "lab-stats-oracle: in the module's own tests, a 16-look rule of 8 seeds: $$($(LAB_RUN) --bytecode --strict-bytecode --entry sequentialCounts --args-json 0 sim/lab_stats_test.ail)"
