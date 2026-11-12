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
