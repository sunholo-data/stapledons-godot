# R1-ISM-DUST (design_docs/planned/r1/ism-structure-and-dust.md): the lism-1 medium and the dust.
.PHONY: ism-data ism-data-verify ism-oracle-check ism-test ism-determinism ism-bench dust-flash-test map-ism-test ism-capture

ISM_RUN = env -u AI_LIVE $(AILANG) run --quiet --package-dir sim
ISM_TMP = $(SCRATCH)/ism

ism-data:          ## AC4: regenerate sim/data/ism.ail and data/ism/ism.json from data/ism/sources (interpreter and VM must agree byte for byte), then install them
	@mkdir -p $(ISM_TMP)/a $(ISM_TMP)/b
	$(ISM_RUN) --caps IO,FS --entry main --args-json '"$(ISM_TMP)/a"' sim/tools/ism_build.ail
	$(ISM_RUN) --caps IO,FS --bytecode --entry main --args-json '"$(ISM_TMP)/b"' sim/tools/ism_build.ail
	cmp $(ISM_TMP)/a/ism.ail $(ISM_TMP)/b/ism.ail && cmp $(ISM_TMP)/a/ism.json $(ISM_TMP)/b/ism.json
	cp $(ISM_TMP)/a/ism.ail sim/data/ism.ail && cp $(ISM_TMP)/a/ism.json data/ism/ism.json

ism-data-verify:   ## AC4: a fresh regeneration equals the committed sim/data/ism.ail and data/ism/ism.json byte for byte
	@mkdir -p $(ISM_TMP)/v
	@$(ISM_RUN) --caps IO,FS --bytecode --entry main --args-json '"$(ISM_TMP)/v"' sim/tools/ism_build.ail
	@cmp $(ISM_TMP)/v/ism.ail sim/data/ism.ail && cmp $(ISM_TMP)/v/ism.json data/ism/ism.json && \
	  echo "ism-data-verify: sim/data/ism.ail $$(shasum -a 256 sim/data/ism.ail | cut -c1-16), data/ism/ism.json $$(shasum -a 256 data/ism/ism.json | cut -c1-16) regenerate byte-identically"

ism-oracle-check:  ## the stdlib oracle (tools/ism_dust_ref.py) passes its relations and the design's acceptance numbers
	@mkdir -p $(ISM_TMP); python3 tools/ism_dust_ref.py --check > $(ISM_TMP)/oracle.log; rc=$$?; tail -1 $(ISM_TMP)/oracle.log; exit $$rc

ism-test:          ## AC6, AC7, AC9-AC12: the medium, the dust stream, the ledger by column, the hold limit and protocol 2.8 (also in make sim)
	cd sim && $(AILANG) test ism_test.ail && $(AILANG) test core_ism_test.ail && $(AILANG) test protocol_ism_test.ail

ism-determinism:   ## AC11, AC13: a 2.8 lism-1 session (plan, commit, 40 real-time ticks of dust): two runs and the strict VM vs the interpreter print the same bytes
	@mkdir -p $(ISM_TMP)
	@$(ISM_RUN) --bytecode --strict-bytecode --entry ismStream --args-json 40 sim/protocol_ism_test.ail > $(ISM_TMP)/det-vm1.txt
	@$(ISM_RUN) --bytecode --strict-bytecode --entry ismStream --args-json 40 sim/protocol_ism_test.ail > $(ISM_TMP)/det-vm2.txt
	@$(ISM_RUN) --entry ismStream --args-json 40 sim/protocol_ism_test.ail > $(ISM_TMP)/det-int.txt
	@cmp $(ISM_TMP)/det-vm1.txt $(ISM_TMP)/det-vm2.txt && cmp $(ISM_TMP)/det-vm1.txt $(ISM_TMP)/det-int.txt && grep -q '"impacts":\[{' $(ISM_TMP)/det-vm1.txt && \
	  echo "ism-determinism: $$(wc -l < $(ISM_TMP)/det-vm1.txt | tr -d ' ') lines with impacts, digest $$(shasum -a 256 $(ISM_TMP)/det-vm1.txt | cut -c1-16): run 1 = run 2 = interpreter"

ism-bench:         ## AC19: warm bytecode-service ISM plan/tick delta vs uniform, excluding bootstrap; pure core strictness is checked by make strict
	@mkdir -p $(ISM_TMP); rm -f $(ISM_TMP)/service-benchmark.json
	@env -u AI_LIVE $(GODOT_SIM) --headless --path . --quit-after 3 --script tools/ism_service_bench.gd > $(ISM_TMP)/service-benchmark.log 2>&1; rc=$$?; \
	  cat $(ISM_TMP)/service-benchmark.log; test $$rc = 0 && grep -q '^ism-service-bench:' $(ISM_TMP)/service-benchmark.log && \
	  jq -e '.passes == true' $(ISM_TMP)/service-benchmark.json >/dev/null

dust-flash-test:   ## AC15: the dust-flash CPU mirror vs the package values, lookups finite, the glitter sampler mirrors (headless)
	@mkdir -p $(SCRATCH)
	@$(GODOT) --headless --path . --script tests/test_dust_flash.gd > $(SCRATCH)/dust-flash-test.log 2>&1; rc=$$?; grep -v '^  ok' $(SCRATCH)/dust-flash-test.log; \
	  test $$rc = 0 && grep -q '^dust-flash: [1-9][0-9]* passed, 0 failures$$' $(SCRATCH)/dust-flash-test.log || { echo "dust-flash-test: FAILED"; exit 1; }

map-ism-test:      ## AC16: the galaxy map's medium layer draws every medium in ism.json, mirrors the LIC surface, cuts the route by medium; D is a display flag (headless)
	@mkdir -p $(SCRATCH)
	@$(GODOT) --headless --path . --script tests/test_ism_layer.gd > $(SCRATCH)/map-ism-test.log 2>&1; rc=$$?; grep -v '^  ok' $(SCRATCH)/map-ism-test.log; \
	  test $$rc = 0 && grep -q '^ism-layer: [1-9][0-9]* passed, 0 failures$$' $(SCRATCH)/map-ism-test.log || { echo "map-ism-test: FAILED"; exit 1; }

ism-capture:       ## AC18: renders/ism/ (flight frames per medium and speed, flash close-up, afterglow / eps / sensitivity sheets, map views, contact sheet; needs a GPU window)
	@mkdir -p $(ISM_TMP) renders/ism
	$(ISM_RUN) --bytecode --strict-bytecode --entry main sim/tools/ism_sensitivity.ail > $(ISM_TMP)/sensitivity.json
	$(GODOT_SIM) --path . -- --ism-capture=renders/ism

ism-lore-drafts: lore-values  ## AC21: the Archive drafts for Mark (design_docs/planned/r1/ism-archive-drafts) cite registered ids only (HB-, RS-, IS-) and every number binds
	@$(MAKE) --no-print-directory lore-check LORE=design_docs/planned/r1/ism-archive-drafts AILANG=$(AILANG)

.PHONY: ism-compat
ism-compat: ## frozen 2.7 inferred-star session from main 70c445c, interpreter and VM byte-identical
	@mkdir -p $(ISM_TMP)
	@$(ISM_RUN) --caps IO --bytecode --entry main sim/ship.ail < tests/fixtures/protocol_27_inferred.input.ndjson > $(ISM_TMP)/compat-vm.ndjson
	@$(ISM_RUN) --caps IO --entry main sim/ship.ail < tests/fixtures/protocol_27_inferred.input.ndjson > $(ISM_TMP)/compat-int.ndjson
	@cmp tests/fixtures/protocol_27_inferred.expected.ndjson $(ISM_TMP)/compat-vm.ndjson && cmp $(ISM_TMP)/compat-vm.ndjson $(ISM_TMP)/compat-int.ndjson
	@echo 'ism-compat: frozen 2.7 inferred-star plan, commit and flight = VM = interpreter'

.PHONY: ism-bright-oracle
ism-bright-oracle: ## independent dense midpoint integration in rapidity, 0.001-dex Planck efficacy
	@mkdir -p $(ISM_TMP)
	@python3 tools/ism_bright_ref.py > $(ISM_TMP)/bright-oracle.log
	@echo "ism-bright-oracle: four resolutions converge; core_ism_test binds the independent result"

test: ism-bright-oracle
