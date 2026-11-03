# R3-WORLDS W2.2 internal census, never on the protocol wire.
# WORLDS_RUN is supplied by the integration makefile: either the package-pinned
# runtime command or the explicitly local development overlay runner.
WORLDS_CENSUS_SEED ?= 0
WORLDS_CENSUS_SEEDS ?= 64
WORLDS_CENSUS_REGISTRY ?= data/starmap/stars.json
WORLDS_CENSUS_OUT ?= .godot/tmp/worlds/census.json
.PHONY: census census-large census-large-run census-smoke
census:
	@mkdir -p $$(dirname "$(WORLDS_CENSUS_OUT)")
	@$(WORLDS_RUN) --caps IO,FS --bytecode --entry main --args-json '{"registry":"$(WORLDS_CENSUS_REGISTRY)","output":"$(WORLDS_CENSUS_OUT)","seed":$(WORLDS_CENSUS_SEED),"seeds":$(WORLDS_CENSUS_SEEDS)}' sim/tools/census_main.ail
census-large:
	@sh tools/worlds_census_budget.sh 900 $(MAKE) --no-print-directory census-large-run
census-large-run: census-large-input
	@$(MAKE) census WORLDS_CENSUS_REGISTRY=.godot/tmp/worlds/gcns-registry.json WORLDS_CENSUS_OUT=.godot/tmp/worlds/census-large.json
census-smoke:
	@$(WORLDS_RUN) --strict-bytecode --entry censusVm sim/census_test.ail
.PHONY: census-large-input
census-large-input:
	@mkdir -p .godot/tmp/worlds
	@sh tools/sky_assets.sh fetch inputs 'data/raw/gcns\.csv$$'
	@sh tools/sky_assets.sh verify inputs 'data/raw/gcns\.csv$$'
	@$(WORLDS_RUN) --caps IO,FS --bytecode --entry largeInputMain --args-json '{"csv":"data/raw/gcns.csv","truth":"data/starmap/truth/positions.csv","companions":"data/starmap/companions/companions.csv","output":".godot/tmp/worlds/gcns-registry.json"}' sim/tools/census_main.ail
