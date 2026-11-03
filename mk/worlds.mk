# R3-WORLDS headless gates. Registry dependencies must be published/pinned for
# production. For local development see data/worlds/README.md (ignored overlay).
WORLDS_RUN = $(AILANG) run --quiet --package-dir sim
WORLDS_PACKAGE ?= sim
include mk/worlds_census.mk
include mk/worlds_calibration.mk
.PHONY: worlds-test worlds-parity worlds-leak world-hosts world-hosts-check calib-smoke calibrate
worlds-test:
	@$(AILANG) test --strict-bytecode $(WORLDS_PACKAGE)/worlds_test.ail $(WORLDS_PACKAGE)/protocol_worlds_test.ail $(WORLDS_PACKAGE)/census_test.ail $(WORLDS_PACKAGE)/calibrate_test.ail $(WORLDS_PACKAGE)/calibrate_search_test.ail
worlds-parity:
	@for spec in 'worlds_test worldsVm worlds-ok' 'protocol_worlds_test protocolWorldsVm protocol-worlds-ok' 'census_test censusVm census-ok'; do \
	  set -- $$spec; vm=$$(env -u AI_LIVE $(WORLDS_RUN) --strict-bytecode --entry $$2 sim/$$1.ail); \
	  interp=$$(env -u AI_LIVE $(WORLDS_RUN) --entry $$2 sim/$$1.ail); \
	  test "$$vm" = "$$3" && test "$$vm" = "$$interp" || { echo "worlds-parity: FAIL $$1: $$vm | $$interp"; exit 1; }; \
	  echo "worlds-parity: $$2 $$vm (strict VM = interpreter)"; done
	@mkdir -p $(SCRATCH)/worlds
	@$(WORLDS_RUN) --strict-bytecode --caps IO --entry calibVm sim/calibrate_test.ail > $(SCRATCH)/worlds/calib-vm.jsonl
	@$(WORLDS_RUN) --caps IO --entry calibVm sim/calibrate_test.ail > $(SCRATCH)/worlds/calib-interpreter.jsonl
	@cmp $(SCRATCH)/worlds/calib-vm.jsonl $(SCRATCH)/worlds/calib-interpreter.jsonl && echo 'worlds-parity: calibVm 2 development seeds byte-identical'
worlds-leak:
	@AILANG="$(AILANG)" python3 tools/worlds_leak.py
world-hosts:
	@$(WORLDS_RUN) --caps IO,FS --entry main --args-json '{"registry":"data/starmap/stars.json","planets":"data/planets/exoplanets.json","output":"sim/data/world_hosts.ail"}' sim/tools/world_hosts_main.ail
world-hosts-check:
	@mkdir -p $(SCRATCH)/worlds
	@$(WORLDS_RUN) --caps IO,FS --entry main --args-json '{"registry":"data/starmap/stars.json","planets":"data/planets/exoplanets.json","output":"$(SCRATCH)/worlds/world_hosts.ail"}' sim/tools/world_hosts_main.ail
	@cmp sim/data/world_hosts.ail $(SCRATCH)/worlds/world_hosts.ail && echo 'world-hosts-check: measured host facts byte-identical'
# Backend-independent fixture, not W1.4 photon-budget/preset acceptance.
# Probe fixed 4 seeds after measuring 32 binding-strategy rows in <60 seconds.
calib-smoke:
	@$(WORLDS_RUN) --strict-bytecode --caps IO --entry smoke --args-json '{"seeds":4,"supportLy":10}' sim/tools/calibrate_main.ail
calibrate:
	@$(WORLDS_RUN) --caps IO --entry main sim/tools/calibrate_main.ail
strict parity: worlds-parity
test: worlds-test worlds-leak world-hosts-check census calib-smoke
