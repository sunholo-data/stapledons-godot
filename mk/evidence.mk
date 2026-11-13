# R3-REASONS RT2a: the ship's detector and the evidence ledger (sim/data/detect.ail, sim/evidence.ail).
# Headless and pure. These need sunholo/observe 0.2.0. Until it is published and pinned in
# sim/ailang.toml, run them against the development overlay:
#   OBSERVE_DEV_PACKAGE=$(tools/observe_dev.sh path) make evidence-test evidence-parity AILANG=tools/observe_ailang.sh
EVIDENCE_RUN = $(AILANG) run --quiet --package-dir sim
.PHONY: evidence-test evidence-parity
evidence-test:     ## R3-REASONS AC2, AC3: records trace to a world and an instrument; false positives; D-68 groundwork; the light cone; OB thresholds and reach (strict VM)
	@$(AILANG) test --strict-bytecode sim/evidence_test.ail
evidence-parity:   ## R3-REASONS AC9: evidenceVm and a whole ledger (ledgerVm), strict VM = interpreter byte for byte
	@mkdir -p $(SCRATCH)/evidence
	@for entry in evidenceVm ledgerVm; do \
	  env -u AI_LIVE $(EVIDENCE_RUN) --strict-bytecode --entry $$entry sim/evidence_test.ail > $(SCRATCH)/evidence/$$entry-vm.txt || { echo "evidence-parity: FAIL $$entry (strict VM)"; exit 1; }; \
	  env -u AI_LIVE $(EVIDENCE_RUN) --entry $$entry sim/evidence_test.ail > $(SCRATCH)/evidence/$$entry-interpreter.txt || { echo "evidence-parity: FAIL $$entry (interpreter)"; exit 1; }; \
	  cmp $(SCRATCH)/evidence/$$entry-vm.txt $(SCRATCH)/evidence/$$entry-interpreter.txt || { echo "evidence-parity: FAIL $$entry differs"; exit 1; }; \
	  echo "evidence-parity: $$entry $$(wc -c < $(SCRATCH)/evidence/$$entry-vm.txt | tr -d ' ') bytes (strict VM = interpreter)"; done
	@test "$$(cat $(SCRATCH)/evidence/evidenceVm-vm.txt)" = evidence-ok || { echo "evidence-parity: FAIL $$(cat $(SCRATCH)/evidence/evidenceVm-vm.txt)"; exit 1; }
strict parity: evidence-parity
test: evidence-test
