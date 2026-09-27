GODOT ?= godot
AILANG ?= ailang
SIM := sim/ship.ail
SIMFLAGS := --quiet --package-dir sim --caps IO --entry main
SCRATCH := .godot/tmp

.PHONY: all test physics sim parity golden capture run import

all: test

import:            ## register class_name scripts (needed once after clone)
	$(GODOT) --headless --path . --import

test: import physics sim parity   ## everything that runs without a GPU window

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

golden:            ## GPU shader vs CPU reference star positions (needs a GPU window)
	$(GODOT) --path . -- --golden

capture:           ## 1 g voyage through the AILANG sim, PNGs to renders/ (needs a GPU window)
	$(GODOT) --path . -- --capture=renders

run:               ## interactive: W/S thrust, arrows look, 1-4 views, +/- warp
	$(GODOT) --path .
