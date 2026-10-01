GODOT ?= godot
AILANG ?= ailang
SIM := sim/ship.ail
SIMFLAGS := --quiet --package-dir sim --caps IO --entry main
SCRATCH := .godot/tmp
AILANG_RELEASE ?= v0.50.0
RUNTIME := runtime
APP := build/macos/Stapledons Voyage.app

.PHONY: all test deps physics sim parity parity-offaxis parity-v2 offaxis-v11-equiv strict wd-vm sky-vm sky-model tools-test golden capture run import runtime export-macos export-smoke

all: test

import:            ## register class_name scripts (needed once after clone)
	$(GODOT) --headless --path . --import

deps:              ## fetch locked AILANG packages into the cache; fail if the resolution would change
	cd sim && $(AILANG) lock
	@# ailang.lock carries a generated_at timestamp (reported upstream); ignore it, then restore the file
	git diff --exit-code -I '"generated_at"' sim/ailang.lock; rc=$$?; git checkout -q sim/ailang.lock; exit $$rc

test: deps import physics sim parity parity-offaxis parity-v2 offaxis-v11-equiv strict wd-vm catalogue-vm catalogue-bytes sky-vm tools-test   ## everything that runs without a GPU window

tools-test:        ## catalogue parser unit tests (committed real-byte fixtures only; no data/raw needed)
	python3 tools/test_extract.py

physics:           ## CPU physics reference vs known values
	$(GODOT) --headless --path . --script tests/test_physics.gd

sim:               ## AILANG sim over the NDJSON bridge vs closed-form kinematics
	$(AILANG) check --package sim
	cd sim && $(AILANG) test --package .
	$(GODOT) --headless --path . --script tests/test_sim_bridge.gd

parity:            ## v2 diag session, 600 thrust ticks: bytecode VM and tree-walking interpreter must agree bit for bit
	@mkdir -p $(SCRATCH)
	@python3 -c "print('{\"v\":2,\"type\":\"hello\",\"want\":{\"major\":2,\"minor\":0}}'); print('{\"v\":2,\"type\":\"new_game\",\"seed\":0,\"scenario\":\"sol\",\"diag\":true}'); [print('{\"v\":2,\"type\":\"input\",\"tick\":%d,\"dtau\":0.01,\"intents\":[{\"k\":\"thrust\",\"thrust\":%s}]}' % (i + 1, 1 if i < 300 else -0.5)) for i in range(600)]; print('{\"v\":2,\"type\":\"quit\"}')" > $(SCRATCH)/parity_in.txt
	$(AILANG) run --bytecode $(SIMFLAGS) $(SIM) < $(SCRATCH)/parity_in.txt > $(SCRATCH)/vm.txt
	$(AILANG) run $(SIMFLAGS) $(SIM) < $(SCRATCH)/parity_in.txt > $(SCRATCH)/interp.txt
	cmp $(SCRATCH)/vm.txt $(SCRATCH)/interp.txt && test "$$(grep -c '"status":"ok"' $(SCRATCH)/vm.txt)" = 601 && echo "parity: identical ($$(wc -l < $(SCRATCH)/vm.txt) lines)"

parity-offaxis:     ## v2 off-axis log (turns, burns, refusals, malformed lines) must be VM/interpreter identical
	@mkdir -p $(SCRATCH)
	$(AILANG) run --bytecode $(SIMFLAGS) $(SIM) < tests/fixtures/offaxis.ndjson > $(SCRATCH)/offaxis_vm.txt
	$(AILANG) run $(SIMFLAGS) $(SIM) < tests/fixtures/offaxis.ndjson > $(SCRATCH)/offaxis_interp.txt
	cmp $(SCRATCH)/offaxis_vm.txt $(SCRATCH)/offaxis_interp.txt && echo "parity-offaxis: identical ($$(wc -l < $(SCRATCH)/offaxis_vm.txt) lines)"

parity-v2:          ## protocol v2 session through ship.ail (hello first, malformed, refused): VM/interpreter identical; nothing printed before the first input
	@mkdir -p $(SCRATCH)
	@for vm in --bytecode ""; do \
	  out=$$(printf '' | $(AILANG) run $$vm $(SIMFLAGS) $(SIM)); test -z "$$out" || { echo "ship printed before any input: $$out"; exit 1; }; \
	  out=$$(printf '{"v":2,"type":"quit"}\n' | $(AILANG) run $$vm $(SIMFLAGS) $(SIM)); test -z "$$out" || { echo "ship printed before hello: $$out"; exit 1; }; \
	  out=$$(printf '{"v":2,"type":"hello","want":{"major":2,"minor":0}}\n' | $(AILANG) run $$vm $(SIMFLAGS) $(SIM)); \
	  test "$$(printf '%s\n' "$$out" | wc -l | tr -d ' ')" = 1 && case "$$out" in '{"v":2,"type":"hello","proto":{"major":2,'*) ;; *) echo "first line is not the hello reply: $$out"; exit 1;; esac; \
	done; echo "parity-v2: silent until the first input; first output is the hello reply (VM and interpreter)"
	$(AILANG) run --bytecode $(SIMFLAGS) $(SIM) < tests/fixtures/v2_session.ndjson > $(SCRATCH)/v2_vm.txt
	$(AILANG) run $(SIMFLAGS) $(SIM) < tests/fixtures/v2_session.ndjson > $(SCRATCH)/v2_interp.txt
	cmp $(SCRATCH)/v2_vm.txt $(SCRATCH)/v2_interp.txt && echo "parity-v2: identical ($$(wc -l < $(SCRATCH)/v2_vm.txt) lines)"

offaxis-v11-equiv:  ## AC13 interim: v2 off-axis log reproduces v1.1 (e9d35c5) beta, gamma, tau, t, x, pos bit for bit (folds into make replay at M2.5)
	@mkdir -p $(SCRATCH)
	$(AILANG) run --bytecode $(SIMFLAGS) $(SIM) < tests/fixtures/offaxis.ndjson > $(SCRATCH)/offaxis_v2.txt
	python3 tests/offaxis_v11_equiv.py tests/fixtures/v11_offaxis.$$(uname -m | sed s/aarch64/arm64/).golden $(SCRATCH)/offaxis_v2.txt

strict:            ## pure sim core and protocol v2 codecs must run entirely on the bytecode VM (no evaluator fallback)
	@want=$$(python3 -c "import math; g=1.032295275553596; print(repr(2*math.sinh(g*3.0)/g))"); \
	got=$$($(AILANG) run --quiet --bytecode --strict-bytecode --package-dir sim --entry scripted --args-json 300 sim/core.ail); \
	interp=$$($(AILANG) run --quiet --package-dir sim --entry scripted --args-json 300 sim/core.ail); \
	echo "strict VM $$got | interpreter $$interp | closed form $$want"; \
	[ "$$got" = "$$interp" ] && python3 -c "import sys; sys.exit(0 if abs($$got - $$want) < 1e-9 else 1)"
	@want=$$(python3 -c "import math; g=1.032295275553596; print(repr(math.sqrt(2)*2*(math.cosh(g*3.0)-1)/g))"); \
	got=$$($(AILANG) run --quiet --bytecode --strict-bytecode --package-dir sim --entry scriptedOffAxis --args-json 300 sim/core.ail); \
	interp=$$($(AILANG) run --quiet --package-dir sim --entry scriptedOffAxis --args-json 300 sim/core.ail); \
	echo "strict off-axis VM $$got | interpreter $$interp | closed form $$want"; \
	[ "$$got" = "$$interp" ] && python3 -c "import sys; sys.exit(0 if abs($$got - $$want) < 1e-9 else 1)"
	@mkdir -p $(SCRATCH)
	@$(AILANG) run --quiet --bytecode --strict-bytecode --package-dir sim --entry protocolVm --args-json 0 sim/protocol_test.ail > $(SCRATCH)/protocol-vm.txt
	@$(AILANG) run --quiet --package-dir sim --entry protocolVm --args-json 0 sim/protocol_test.ail > $(SCRATCH)/protocol-interp.txt
	@cmp $(SCRATCH)/protocol-vm.txt $(SCRATCH)/protocol-interp.txt && test "$$(tail -1 $(SCRATCH)/protocol-vm.txt)" = "protocol-ok" && \
	  echo "strict protocolVm: $$(tail -1 $(SCRATCH)/protocol-vm.txt), $$(wc -l < $(SCRATCH)/protocol-vm.txt | tr -d ' ') lines, digest $$(shasum -a 256 $(SCRATCH)/protocol-vm.txt | cut -c1-16) (strict VM = interpreter)"
	@got=$$($(AILANG) run --quiet --bytecode --strict-bytecode --package-dir sim --entry worldVm --args-json 0 sim/core_test.ail); \
	interp=$$($(AILANG) run --quiet --package-dir sim --entry worldVm --args-json 0 sim/core_test.ail); \
	echo "strict worldVm: VM $$got | interpreter $$interp"; [ "$$got" = "world-ok" ] && [ "$$interp" = "world-ok" ]
	@got=$$($(AILANG) run --quiet --bytecode --strict-bytecode --package-dir sim --entry planVm --args-json 0 sim/core_test.ail); \
	interp=$$($(AILANG) run --quiet --package-dir sim --entry planVm --args-json 0 sim/core_test.ail); \
	echo "strict planVm: VM $$got | interpreter $$interp"; [ "$$got" = "plan-ok" ] && [ "$$interp" = "plan-ok" ]

wd-vm:             ## WD package NaN contract on the strict VM (ailang#1419: `ailang test` interpreter cannot see NaN-guard mutants)
	got=$$($(AILANG) run --quiet --bytecode --strict-bytecode --package-dir sim --entry wdVmNaN --args-json 0 sim/tools/catalogue_probe_test.ail); \
	echo "wd-vm: $$got"; [ "$$got" = "wd-nan-ok" ]

golden:            ## GPU shader vs CPU reference star positions (needs a GPU window)
	$(GODOT) --path . -- --golden

capture:           ## 1 g voyage through the AILANG sim, PNGs to renders/ (needs a GPU window)
	$(GODOT) --path . -- --capture=renders

run:               ## interactive: W/S thrust, arrows look, 1-4 views, +/- warp
	$(GODOT) --path .

runtime:           ## stage the bundled sim runtime: pinned ailang release + fetched package cache (no dotfiles)
	@rm -rf $(RUNTIME) && mkdir -p $(RUNTIME)/bin $(RUNTIME)/home
	gh release download $(AILANG_RELEASE) --repo sunholo-data/ailang -p 'darwin.arm64.ailang.tar.gz' -D $(SCRATCH)/ailang-rel --clobber
	tar xzf $(SCRATCH)/ailang-rel/darwin.arm64.ailang.tar.gz -C $(RUNTIME)/bin && chmod +x $(RUNTIME)/bin/ailang
	cd sim && HOME=$(CURDIR)/$(RUNTIME)/home $(CURDIR)/$(RUNTIME)/bin/ailang lock
	git checkout -q sim/ailang.lock
	mkdir -p $(RUNTIME)/cache && mv $(RUNTIME)/home/.ailang/cache/registry $(RUNTIME)/cache/registry && rm -rf $(RUNTIME)/home
	@echo "$(AILANG_RELEASE)" > $(RUNTIME)/VERSION
	@find $(RUNTIME) -type f | sed 's/^/  staged /'

export-macos: runtime import   ## build the macOS .app (arm64, ad-hoc signed) with the sim runtime bundled
	@mkdir -p build/macos
	$(GODOT) --headless --path . --export-release "macOS" "$(APP)"
	@du -sh "$(APP)"

export-smoke:      ## run the exported .app's capture with NO ailang on PATH; must produce the contact sheet
	@rm -rf $(SCRATCH)/export-smoke && mkdir -p $(SCRATCH)/export-smoke
	exe=$$(defaults read "$(CURDIR)/$(APP)/Contents/Info.plist" CFBundleExecutable); \
	env -i PATH=/usr/bin:/bin HOME="$$HOME" "$(APP)/Contents/MacOS/$$exe" -- --capture="$(CURDIR)/$(SCRATCH)/export-smoke"
	@test -s $(SCRATCH)/export-smoke/contact_sheet.png && echo "export-smoke: OK ($$(ls $(SCRATCH)/export-smoke | wc -l | tr -d ' ') files)"

.PHONY: catalogue-probe
catalogue-probe:   ## real-row pure CSV/normal-photometry probe; 5 strict VM parity runs
	AILANG=$(AILANG) python3 tools/catalogue_probe.py

.PHONY: catalogue-vm
catalogue-vm:     ## T1 pure transform and selection: strict VM, interpreter and exact anchors
	@mkdir -p $(SCRATCH)
	@set -e; for entry in transformVm selectionVm; do \
	  $(AILANG) run --quiet --bytecode --strict-bytecode --package-dir sim --entry $$entry --args-json 0 sim/tools/catalogue_test.ail > $(SCRATCH)/$$entry-vm.txt; \
	  $(AILANG) run --quiet --package-dir sim --entry $$entry --args-json 0 sim/tools/catalogue_test.ail > $(SCRATCH)/$$entry-interp.txt; \
	  cmp $(SCRATCH)/$$entry-vm.txt $(SCRATCH)/$$entry-interp.txt; \
	  case $$entry in transformVm) want=transform-ok;; selectionVm) want=selection-ok;; esac; \
	  test "$$(cat $(SCRATCH)/$$entry-vm.txt)" = "$$want"; cat $(SCRATCH)/$$entry-vm.txt; \
	done

.PHONY: sky-vm
sky-vm:           ## M1.4b sky-model fitter (pure core): strict VM and interpreter must both print sky-ok
	@mkdir -p $(SCRATCH)
	@$(AILANG) run --quiet --bytecode --strict-bytecode --package-dir sim --entry skyVm --args-json 0 sim/tools/sky_model_test.ail > $(SCRATCH)/sky-vm.txt
	@$(AILANG) run --quiet --package-dir sim --entry skyVm --args-json 0 sim/tools/sky_model_test.ail > $(SCRATCH)/sky-interp.txt
	@cmp $(SCRATCH)/sky-vm.txt $(SCRATCH)/sky-interp.txt && test "$$(cat $(SCRATCH)/sky-vm.txt)" = "sky-ok" && echo "sky-vm: $$(cat $(SCRATCH)/sky-vm.txt) (strict VM = interpreter)"

SKY := data/raw/background
.PHONY: sky-model
sky-model:        ## M1.4b offline: destarred panorama -> per-texel T_c model (Godot I/O, AILANG fit, ~12 min); report to data/sky/
	$(GODOT) --headless --path . --script tools/sky_colours.gd -- histogram $(SKY)/noirlab_10k_destarred.png $(SKY)/colours.csv
	$(AILANG) run --quiet --bytecode --caps IO,FS --package-dir sim --entry main \
	  --args-json '{"colours":"$(SKY)/colours.csv","fits":"$(SKY)/fits.csv","report":"data/sky/sky_model_report.json","size":"[10000, 5000]"}' \
	  sim/tools/sky_model.ail
	$(GODOT) --headless --path . --script tools/sky_colours.gd -- paint $(SKY)/noirlab_10k_destarred.png $(SKY)/fits.csv $(SKY)/noirlab_10k_skymodel.png

.PHONY: catalogue-bytes
catalogue-bytes:  ## native F32 bytes: independent Python oracle, interpreter and five ordinary VM runs
	AILANG=$(AILANG) python3 tools/test_catalogue_bytes.py
