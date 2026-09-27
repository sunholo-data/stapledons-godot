GODOT ?= godot
AILANG ?= ailang
SIM := sim/ship.ail
SIMFLAGS := --quiet --package-dir sim --caps IO --entry main
SCRATCH := .godot/tmp

.PHONY: all test deps physics sim parity strict golden capture run import

all: test

import:            ## register class_name scripts (needed once after clone)
	$(GODOT) --headless --path . --import

deps:              ## fetch locked AILANG packages into the cache; fail if the lock would change
	cd sim && $(AILANG) lock
	git diff --exit-code sim/ailang.lock

test: deps import physics sim parity strict   ## everything that runs without a GPU window

physics:           ## CPU physics reference vs known values
	$(GODOT) --headless --path . --script tests/test_physics.gd

sim:               ## AILANG sim over the NDJSON bridge vs closed-form kinematics
	$(AILANG) check --package sim
	$(GODOT) --headless --path . --script tests/test_sim_bridge.gd

parity:            ## bytecode VM and tree-walking interpreter must agree bit for bit
	@mkdir -p $(SCRATCH)
	@python3 -c "import sys; [print('{\"cmd\":\"step\",\"thrust\":%s,\"dtau\":0.01}' % (1 if i < 300 else -0.5)) for i in range(600)]; print('{\"cmd\":\"quit\"}')" > $(SCRATCH)/parity_in.txt
	$(AILANG) run --bytecode $(SIMFLAGS) $(SIM) < $(SCRATCH)/parity_in.txt > $(SCRATCH)/vm.txt
	$(AILANG) run $(SIMFLAGS) $(SIM) < $(SCRATCH)/parity_in.txt > $(SCRATCH)/interp.txt
	cmp $(SCRATCH)/vm.txt $(SCRATCH)/interp.txt && echo "parity: identical ($$(wc -l < $(SCRATCH)/vm.txt) lines)"

strict:            ## pure sim core must run entirely on the bytecode VM (no evaluator fallback)
	@want=$$(python3 -c "import math; g=1.032295275553596; print(repr(2*math.sinh(g*3.0)/g))"); \
	got=$$($(AILANG) run --quiet --bytecode --strict-bytecode --package-dir sim --entry scripted --args-json 300 sim/core.ail); \
	interp=$$($(AILANG) run --quiet --package-dir sim --entry scripted --args-json 300 sim/core.ail); \
	echo "strict VM $$got | interpreter $$interp | closed form $$want"; \
	[ "$$got" = "$$interp" ] && python3 -c "import sys; sys.exit(0 if abs($$got - $$want) < 1e-9 else 1)"

golden:            ## GPU shader vs CPU reference star positions (needs a GPU window)
	$(GODOT) --path . -- --golden

capture:           ## 1 g voyage through the AILANG sim, PNGs to renders/ (needs a GPU window)
	$(GODOT) --path . -- --capture=renders

run:               ## interactive: W/S thrust, arrows look, 1-4 views, +/- warp
	$(GODOT) --path .
