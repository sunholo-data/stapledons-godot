GODOT ?= godot
AILANG ?= ailang
# Godot runs that start the sim use the same ailang as the make line, never a stale one on PATH
GODOT_SIM = AILANG_BIN="$$(command -v $(AILANG))" $(GODOT)
SIM := sim/ship.ail
SIMFLAGS := --quiet --package-dir sim --caps IO --entry main
SCRATCH := .godot/tmp
AILANG_RELEASE ?= v0.51.0
RUNTIME := runtime
APP := build/macos/Stapledons Voyage.app

.PHONY: all test deps physics sim ui map-capture replay replay-record parity parity-offaxis parity-v2 offaxis-v11-equiv strict rng-ref journey-replay wd-vm sky-vm sky-model tools-test extract-test extract destar-test destar golden capture run voyage publish-dev import runtime export-macos export-smoke sky-inputs sky-assets sky-regen sky-publish sky-bundle sky-verify

all: test

import:            ## register class_name scripts (needed once after clone)
	$(GODOT) --headless --path . --import

deps:              ## fetch locked AILANG packages into the cache; fail if the resolution would change
	cd sim && $(AILANG) lock
	@# ailang.lock carries a generated_at timestamp (reported upstream); ignore it, then restore the file
	git diff --exit-code -I '"generated_at"' sim/ailang.lock; rc=$$?; git checkout -q sim/ailang.lock; exit $$rc

test: python-guard deps import physics sim ui replay parity-v2 strict rng-ref wd-vm catalogue-vm catalogue-main catalogue-bytes catalogue-stats star-catalogue-test sky-vm extract-test destar-test tools-test   ## everything that runs without a GPU window

tools-test:        ## replay harness unit tests, the star-name oracle, sky_assets.sh fetch on a file:// fake bucket (no network)
	python3 tools/test_replay.py
	python3 tools/check_star_names.py
	sh tools/test_sky_assets.sh

extract-test:      ## VizieR parser (sim/tools/extract.ail): pure checks strict VM = interpreter; real-byte fixtures VM = interpreter
	@mkdir -p $(SCRATCH)
	@$(AILANG) run --quiet --bytecode --strict-bytecode --package-dir sim --entry extractVm --args-json 0 sim/tools/extract_test.ail > $(SCRATCH)/extract-vm.txt
	@$(AILANG) run --quiet --package-dir sim --entry extractVm --args-json 0 sim/tools/extract_test.ail > $(SCRATCH)/extract-interp.txt
	@cmp $(SCRATCH)/extract-vm.txt $(SCRATCH)/extract-interp.txt && test "$$(cat $(SCRATCH)/extract-vm.txt)" = "extract-vm-ok"
	@$(AILANG) run --quiet --bytecode --caps FS --package-dir sim --entry extractFixtures --args-json '"tools/fixtures"' sim/tools/extract_test.ail > $(SCRATCH)/extract-fx-vm.txt
	@$(AILANG) run --quiet --caps FS --package-dir sim --entry extractFixtures --args-json '"tools/fixtures"' sim/tools/extract_test.ail > $(SCRATCH)/extract-fx-interp.txt
	@cmp $(SCRATCH)/extract-fx-vm.txt $(SCRATCH)/extract-fx-interp.txt && test "$$(cat $(SCRATCH)/extract-fx-vm.txt)" = "extract-fixtures-ok"
	@echo "extract-test: $$(cat $(SCRATCH)/extract-vm.txt), $$(cat $(SCRATCH)/extract-fx-vm.txt) (VM = interpreter)"

extract:           ## data/raw/{cns5,table1c}.dat -> data/raw/{cns5,gcns}.csv (AILANG; GCNS takes ~4.5 min on the VM)
	$(AILANG) run --quiet --bytecode --caps IO,FS --package-dir sim --entry main --args-json '{"kind":"cns5","input":"data/raw/cns5.dat","output":"data/raw/cns5.csv"}' sim/tools/extract.ail
	$(AILANG) run --quiet --bytecode --caps IO,FS --package-dir sim --entry main --args-json '{"kind":"gcns","input":"data/raw/table1c.dat","output":"data/raw/gcns.csv"}' sim/tools/extract.ail

physics:           ## CPU physics reference vs known values
	$(GODOT) --headless --path . --script tests/test_physics.gd

sim:               ## AILANG sim over the NDJSON bridge vs closed-form kinematics
	$(AILANG) check --package sim
	cd sim && $(AILANG) test --package .
	$(GODOT_SIM) --headless --path . --script tests/test_sim_bridge.gd

ui:                ## galaxy map + plan panel against the real sim (headless, fake 800x600 viewport; AC15 part)
	$(GODOT_SIM) --headless --path . --script tests/test_galaxy_map.gd

map-capture:       ## galaxy map PNGs + panel dump (alpha Cen A at 0.9c / cap / 0.99c) to renders/ (needs a GPU window; AC17 map part)
	$(GODOT_SIM) --path . -- --map-capture=renders --map-commit
	test -s renders/galaxy_map.png && test -s renders/galaxy_map_panel.json && test -s renders/galaxy_map_commit.png && test -s renders/galaxy_map_transit.png && test -s renders/galaxy_map_arrived.png

replay:            ## AC12/AC13: every tests/replays log + the generated 10k session: VM == interpreter, then == this arch's golden (SESSION=log for one log, TICKS=2000 for the PR-sized session)
	AILANG="$(AILANG)" python3 tools/replay.py $(if $(SESSION),--session $(SESSION)) $(if $(TICKS),--ticks $(TICKS))

replay-record:     ## P5: regenerate this arch's golden for LOG=path|case|session10k|all (a reviewed diff; never in make test)
	@test -n "$(LOG)" || { echo "usage: make replay-record LOG=tests/replays/NAME.ndjson|NAME|session10k|all"; exit 2; }
	AILANG="$(AILANG)" python3 tools/replay.py --record $(LOG)

parity:            ## v2 diag session, 600 thrust ticks: VM == interpreter == golden (replay case diag_thrust600)
	AILANG="$(AILANG)" python3 tools/replay.py --case diag_thrust600

parity-offaxis:     ## v2 off-axis log (turns, burns, refusals, malformed lines): VM == interpreter == golden, and == v1.1 (replay case offaxis_v11_equiv)
	AILANG="$(AILANG)" python3 tools/replay.py --case offaxis_v11_equiv

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
	@# M1.6b: rest-tolerance edge through the protocol (ticks 6-9): a turn at phi 0.9e-9 is accepted, at 1.1e-9 refused moving
	@grep -q '"tick":7,"status":"ok".*"heading":{"x":0,"y":1,"z":0}.*"refused":\[\]' $(SCRATCH)/v2_vm.txt && \
	  grep -q '"tick":9,"status":"ok".*"heading":{"x":0,"y":1,"z":0}.*"refused":\[{"i":1,"reason":"moving"}\]' $(SCRATCH)/v2_vm.txt && \
	  echo "parity-v2: rest tolerance edge (turn at phi 0.9e-9 accepted, 1.1e-9 refused moving)" || { echo "parity-v2: rest tolerance edge FAILED"; exit 1; }

offaxis-v11-equiv:  ## AC13: v2 off-axis log reproduces v1.1 (e9d35c5) beta, gamma, tau, t, x, pos bit for bit (replay case offaxis_v11_equiv)
	AILANG="$(AILANG)" python3 tools/replay.py --case offaxis_v11_equiv

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
	@# journeyVm: alpha Cen 0.99c, commit, 70 ticks of 0.01 yr; arrived, then at rest. Closed form: galaxyTime + (0.7 - tauTotal)
	@want=$$(python3 -c "import math; a=750000*1.032295275553596; p=2.6466524123622457; d=4.37; db=2*math.sinh(p/2)**2/a; dc=d-2*db; print(repr(2*math.sinh(p)/a + dc/math.tanh(p) + 0.7 - (2*p/a + dc/math.sinh(p))))"); \
	got=$$($(AILANG) run --quiet --bytecode --strict-bytecode --package-dir sim --entry journeyVm --args-json 70 sim/core.ail); \
	interp=$$($(AILANG) run --quiet --package-dir sim --entry journeyVm --args-json 70 sim/core.ail); \
	echo "strict journeyVm VM $$got | interpreter $$interp | closed form $$want"; \
	[ "$$got" = "$$interp" ] && python3 -c "import sys; sys.exit(0 if abs($$got - $$want) < 1e-9 else 1)"
	@got=$$($(AILANG) run --quiet --bytecode --strict-bytecode --package-dir sim --entry voyageVm --args-json 0 sim/core_test.ail); \
	interp=$$($(AILANG) run --quiet --package-dir sim --entry voyageVm --args-json 0 sim/core_test.ail); \
	echo "strict voyageVm: VM $$got | interpreter $$interp"; [ "$$got" = "voyage-ok" ] && [ "$$interp" = "voyage-ok" ]
	@# rngVm (M2.4): vectors, independence, then a digest of 10,000 draws per stream (integers only); strict VM = interpreter = tools/rng_ref.py
	@for seed in 7 9007199254740991; do \
	  want="rng-ok $$(python3 tools/rng_ref.py --digest $$seed 10000)"; \
	  got=$$($(AILANG) run --quiet --bytecode --strict-bytecode --package-dir sim --entry rngVm --args-json $$seed sim/rng_test.ail); \
	  interp=$$($(AILANG) run --quiet --package-dir sim --entry rngVm --args-json $$seed sim/rng_test.ail); \
	  echo "strict rngVm seed $$seed: VM $$got | interpreter $$interp | reference $$want"; \
	  [ "$$got" = "$$want" ] && [ "$$interp" = "$$want" ] || exit 1; \
	done

rng-ref:           ## AC11: SplitMix64 vectors, chi-square on 1e5 draws per stream, first 1,000 values per stream (3 seeds) from strict VM and interpreter vs tools/rng_ref.py
	AILANG=$(AILANG) python3 tools/rng_ref.py --check

journey-replay:    ## AC14: the alpha Cen replay runs headless (no Godot), arrives on its last input; VM == interpreter == golden (replay case alpha_cen)
	AILANG="$(AILANG)" python3 tools/replay.py --case alpha_cen

wd-vm:             ## WD package NaN contract on the strict VM (ailang#1419: `ailang test` interpreter cannot see NaN-guard mutants)
	got=$$($(AILANG) run --quiet --bytecode --strict-bytecode --package-dir sim --entry wdVmNaN --args-json 0 sim/tools/catalogue_probe_test.ail); \
	echo "wd-vm: $$got"; [ "$$got" = "wd-nan-ok" ]

golden:            ## GPU shader vs CPU reference star positions (needs a GPU window); M1.6b: 144 off-axis/rolled star cases + 16 background markers
	@mkdir -p $(SCRATCH)
	@$(GODOT) --path . -- --golden > $(SCRATCH)/golden.log 2>&1; rc=$$?; cat $(SCRATCH)/golden.log; \
	  test $$rc = 0 && grep -q '^off-axis golden: 144 cases .* 0 failures$$' $(SCRATCH)/golden.log && \
	  test "$$(grep -c 'background marker' $(SCRATCH)/golden.log)" = 16 && grep -q '^golden: 0 failures$$' $(SCRATCH)/golden.log || \
	  { echo "golden: FAILED (exit $$rc, or the case counts changed: want 144 off-axis + 16 background markers)"; exit 1; }

capture:           ## 1 g voyage through the AILANG sim, PNGs to renders/ (needs a GPU window)
	$(GODOT_SIM) --path . -- --capture=renders

run:               ## interactive galaxy map (the default launch): click a star, set the speed, hold Commit 1.5 s
	$(GODOT_SIM) --path .

voyage:            ## the M0/M1 sky flight: W/S thrust, arrows look, 1-4 views, +/- warp
	$(GODOT_SIM) --path . -- --voyage

runtime:           ## stage the bundled sim runtime: pinned ailang release + fetched package cache (no dotfiles)
	@rm -rf $(RUNTIME) && mkdir -p $(RUNTIME)/bin $(RUNTIME)/home
	gh release download $(AILANG_RELEASE) --repo sunholo-data/ailang -p 'darwin.arm64.ailang.tar.gz' -D $(SCRATCH)/ailang-rel --clobber
	tar xzf $(SCRATCH)/ailang-rel/darwin.arm64.ailang.tar.gz -C $(RUNTIME)/bin && chmod +x $(RUNTIME)/bin/ailang
	cd sim && HOME=$(CURDIR)/$(RUNTIME)/home $(CURDIR)/$(RUNTIME)/bin/ailang lock
	git checkout -q sim/ailang.lock
	mkdir -p $(RUNTIME)/cache && mv $(RUNTIME)/home/.ailang/cache/registry $(RUNTIME)/cache/registry && rm -rf $(RUNTIME)/home
	@echo "$(AILANG_RELEASE)" > $(RUNTIME)/VERSION
	@find $(RUNTIME) -type f | sed 's/^/  staged /'

export-macos: runtime sky-bundle import   ## build the macOS .app (arm64, ad-hoc signed) with the sim runtime and the pinned sky textures bundled
	@mkdir -p build/macos
	$(GODOT) --headless --path . --export-release "macOS" "$(APP)"
	@du -sh "$(APP)"

export-smoke:      ## run the exported .app's capture with NO ailang on PATH; must produce the contact sheet
	@rm -rf $(SCRATCH)/export-smoke && mkdir -p $(SCRATCH)/export-smoke
	exe=$$(defaults read "$(CURDIR)/$(APP)/Contents/Info.plist" CFBundleExecutable); \
	env -i PATH=/usr/bin:/bin HOME="$$HOME" "$(APP)/Contents/MacOS/$$exe" -- --capture="$(CURDIR)/$(SCRATCH)/export-smoke"
	@test -s $(SCRATCH)/export-smoke/contact_sheet.png && echo "export-smoke: OK ($$(ls $(SCRATCH)/export-smoke | wc -l | tr -d ' ') files)"

DEV_BUCKET ?= stapledons-voyage-dev-builds

publish-dev: export-macos export-smoke   ## upload this build to the private dev bucket (needs gcloud auth); install with tools/install_review_build.sh --dev
	@ver=$$(git describe --tags --always --dirty); zip="$(SCRATCH)/StapledonsVoyage-$$ver-macos.zip"; \
	rm -f "$$zip"; (cd build/macos && ditto -c -k --keepParent "Stapledons Voyage.app" "$(CURDIR)/$$zip"); \
	sum=$$(shasum -a 256 "$$zip" | cut -d' ' -f1); name=$$(basename "$$zip"); \
	gcloud storage cp "$$zip" "gs://$(DEV_BUCKET)/macos/builds/$$name" && \
	printf '%s  %s\n' "$$sum" "$$name" | gcloud storage cp - "gs://$(DEV_BUCKET)/macos/builds/$$name.sha256" && \
	printf '{"version":"%s","zip":"macos/builds/%s","sha256":"%s","commit":"%s","built":"%s"}\n' "$$ver" "$$name" "$$sum" "$$(git rev-parse HEAD)" "$$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
	  | gcloud storage cp --cache-control="no-cache" - "gs://$(DEV_BUCKET)/macos/latest.json" && \
	echo "publish-dev: $$name ($$sum) -> gs://$(DEV_BUCKET)/macos/latest.json"

.PHONY: catalogue-probe
catalogue-probe:   ## real-row pure CSV/normal-photometry probe; 5 strict VM parity runs
	AILANG=$(AILANG) python3 tools/catalogue_probe.py

.PHONY: catalogue-vm
catalogue-vm:     ## T1 transform/selection + T3 validation, T4 N3 (exact 50,000 quota with missing rows between), first-error order, writer plan: strict VM, interpreter and exact anchors
	@mkdir -p $(SCRATCH)
	@set -e; for entry in transformVm selectionVm quotaVm mainVm; do \
	  case $$entry in mainVm) f=sim/tools/catalogue_main_test.ail;; *) f=sim/tools/catalogue_test.ail;; esac; \
	  $(AILANG) run --quiet --bytecode --strict-bytecode --package-dir sim --entry $$entry --args-json 0 $$f > $(SCRATCH)/$$entry-vm.txt; \
	  $(AILANG) run --quiet --package-dir sim --entry $$entry --args-json 0 $$f > $(SCRATCH)/$$entry-interp.txt; \
	  cmp $(SCRATCH)/$$entry-vm.txt $(SCRATCH)/$$entry-interp.txt; \
	  case $$entry in transformVm) want=transform-ok;; selectionVm) want=selection-ok;; quotaVm) want=quota-ok;; mainVm) want=main-ok;; esac; \
	  test "$$(cat $(SCRATCH)/$$entry-vm.txt)" = "$$want"; cat $(SCRATCH)/$$entry-vm.txt; \
	done

# M1.2b-T3 tier writer. TIER picks the source; the AILANG shell validates, encodes and hashes
# (std/crypto sha256), then writes temp files and renames them, so a refusal ships nothing.
TIER ?= quick
CATALOGUE_OUT ?= data/starmap
CAT_RUN = $(AILANG) run --quiet --caps IO,FS --package-dir sim
CAT_AILANG = $$($(AILANG) --version | head -1 | cut -d' ' -f2)
cat_args = "{\"tier\":\"$(1)\",\"csv\":\"$(2)\",\"raw\":\"$(3)\",\"lock\":\"sim/ailang.lock\",\"out\":\"$(4)\",\"ailang\":\"$(CAT_AILANG)\"}"
.PHONY: catalogue catalogue-scan catalogue-main
catalogue:        ## M1.2b-T3: data/raw CSV -> $(CATALOGUE_OUT)/stars_$(TIER).bin + stars_$(TIER).json sidecar on the VM (TIER=quick|medium|large)
	@case "$(TIER)" in quick) src=cns5 raw=cns5.dat;; medium|large) src=gcns raw=table1c.dat.gz;; \
	  *) echo "catalogue: TIER must be quick, medium or large (got '$(TIER)')"; exit 2;; esac; \
	$(CAT_RUN) --bytecode --entry main --args-json $(call cat_args,$(TIER),data/raw/$$src.csv,data/raw/$$raw,$(CATALOGUE_OUT)) sim/tools/catalogue_main.ail

catalogue-scan:   ## M1.2b-T3: the conservative F32 bound on every real CNS5 and GCNS row (0 refusals; refused ids are listed for review)
	@for src in cns5 gcns; do $(CAT_RUN) --bytecode --entry scan --args-json "\"data/raw/$$src.csv\"" sim/tools/catalogue_main.ail || exit 1; done

# M1.2c: the committed quick + medium tiers (D-3; large stays ignored). The stats run in CI on the
# committed bins; verify rebuilds them from the pinned inputs and needs data/raw (make catalogue-inputs).
.PHONY: catalogue-stats star-catalogue-test catalogue-verify catalogue-inputs
catalogue-stats:  ## M1.2c AC2/AC3: count, excluded, M-dwarf share, defaulted-photometry check per committed tier (TIER=medium judges only medium)
	@$(GODOT) --headless --path . --script tools/catalogue_stats.gd -- $(if $(filter command line environment,$(origin TIER)),--tier $(TIER))

star-catalogue-test: ## M1.2c binary tier loader: 2-record LE fixture (stride, endianness), every refusal, stats breaches, committed tiers
	$(GODOT) --headless --path . --script tests/test_star_catalogue.gd

VERIFY_OUT := $(SCRATCH)/verify
catalogue-verify: catalogue-inputs ## M1.2c determinism: rebuild quick + medium into .godot/tmp/verify and cmp bin + sidecar with the committed files
	@rm -rf $(VERIFY_OUT); for t in quick medium; do \
	  $(MAKE) --no-print-directory catalogue TIER=$$t CATALOGUE_OUT=$(VERIFY_OUT) AILANG=$(AILANG) >/dev/null || exit 1; \
	  cmp data/starmap/stars_$$t.bin $(VERIFY_OUT)/stars_$$t.bin && cmp data/starmap/stars_$$t.json $(VERIFY_OUT)/stars_$$t.json \
	    || { echo "catalogue-verify: $$t DIFFERS from the committed tier"; exit 1; }; \
	  echo "$$t identical"; done

.PHONY: catalogue-parity
PARITY_TIER ?= medium
catalogue-parity: ## M1.2b-T4: real tier (PARITY_TIER=medium) on the interpreter once + ordinary VM 5x, cmp bin + sidecar, wall time and peak RSS per run
	@sh tools/catalogue_parity.sh $(AILANG) $(PARITY_TIER) $(SCRATCH)/catalogue-parity 5

CAT_FIX := tests/fixtures/catalogue
catalogue-main:   ## M1.2b-T3 writer on committed fixtures: VM bytes == interpreter bytes, sizes, independent shasum of every digest, atomic refusal
	@set -e; d=$(SCRATCH)/catalogue-main; rm -rf $$d; mkdir -p $$d/atomic; \
	for t in quick medium; do \
	  $(CAT_RUN) --bytecode --entry main --args-json $(call cat_args,$$t,$(CAT_FIX)/rows.csv,$(CAT_FIX)/raw.dat,$$d/vm) sim/tools/catalogue_main.ail >/dev/null; \
	  $(CAT_RUN) --entry main --args-json $(call cat_args,$$t,$(CAT_FIX)/rows.csv,$(CAT_FIX)/raw.dat,$$d/interp/) sim/tools/catalogue_main.ail >/dev/null; \
	  cmp $$d/vm/stars_$$t.bin $$d/interp/stars_$$t.bin; cmp $$d/vm/stars_$$t.json $$d/interp/stars_$$t.json; \
	  j=$$d/vm/stars_$$t.json; b=$$d/vm/stars_$$t.bin; \
	  case $$t in quick) n=5;; medium) n=3;; esac; \
	  test "$$(wc -c < $$b | tr -d ' ')" = $$((n * 24)); grep -q "\"count\":$$n," $$j; \
	  for k in "raw:$(CAT_FIX)/raw.dat" "csv:$(CAT_FIX)/rows.csv" "bin:$$b"; do \
	    grep -q "\"$${k%%:*}\":\"$$(shasum -a 256 $${k#*:} | cut -d' ' -f1)\"" $$j || { echo "catalogue-main: $$t sha256.$${k%%:*} wrong"; exit 1; }; done; \
	  echo "catalogue-main $$t: $$n rows, $$((n * 24)) B, VM = interpreter, digests match shasum"; \
	done; \
	printf keep > $$d/atomic/stars_quick.bin; \
	if $(CAT_RUN) --bytecode --entry main --args-json $(call cat_args,quick,$(CAT_FIX)/bad_row.csv,$(CAT_FIX)/raw.dat,$$d/atomic) sim/tools/catalogue_main.ail 2>$$d/refusal.txt; \
	then echo "catalogue-main: invalid row was accepted"; exit 1; fi; \
	test "$$(cat $$d/atomic/stars_quick.bin)" = keep; test "$$(ls -A $$d/atomic)" = stars_quick.bin; \
	echo "catalogue-main atomic: refused ($$(cat $$d/refusal.txt)); existing file untouched, no sidecar or temp left"; \
	$(CAT_RUN) --bytecode --entry main --args-json $(call cat_args,quick,$(CAT_FIX)/rows.csv,$(CAT_FIX)/raw.dat,$$d/vm) sim/tools/catalogue_main.ail >/dev/null; \
	cmp $$d/vm/stars_quick.bin $$d/interp/stars_quick.bin; cmp $$d/vm/stars_quick.json $$d/interp/stars_quick.json; \
	test "$$(ls -A $$d/vm | tr '\n' ' ')" = "stars_medium.bin stars_medium.json stars_quick.bin stars_quick.json "; \
	echo "catalogue-main replace: rewrite over an existing tier is identical, no .tmp or .bak left"; \
	for old in keep none; do m=$$d/mid-$$old; mkdir -p $$m/stars_quick.json; printf old > $$m/stars_quick.json/inside; \
	  if [ $$old = keep ]; then printf keep > $$m/stars_quick.bin; want="stars_quick.bin stars_quick.json "; else want="stars_quick.json "; fi; \
	  if $(CAT_RUN) --bytecode --entry main --args-json $(call cat_args,quick,$(CAT_FIX)/rows.csv,$(CAT_FIX)/raw.dat,$$m) sim/tools/catalogue_main.ail 2>$$d/mid.txt; \
	  then echo "catalogue-main: sidecar rename into a directory succeeded"; exit 1; fi; \
	  test "$$(ls -A $$m | tr '\n' ' ')" = "$$want" || { echo "catalogue-main mid-$$old: left $$(ls -A $$m)"; exit 1; }; \
	  if [ $$old = keep ]; then test "$$(cat $$m/stars_quick.bin)" = keep; fi; test "$$(cat $$m/stars_quick.json/inside)" = old; \
	  grep -q "nothing changed" $$d/mid.txt; ! grep -q "nothing written" $$d/mid.txt; \
	  echo "catalogue-main mid-commit ($$old bin): sidecar rename failed after the bin landed; rolled back, no temp left ($$(cat $$d/mid.txt))"; \
	done; \
	m=$$d/tmpfail; mkdir -p $$m/stars_quick.bin.tmp; printf x > $$m/stars_quick.bin.tmp/inside; printf keep > $$m/stars_quick.bin; \
	if $(CAT_RUN) --bytecode --entry main --args-json $(call cat_args,quick,$(CAT_FIX)/rows.csv,$(CAT_FIX)/raw.dat,$$m) sim/tools/catalogue_main.ail 2>$$d/tmpfail.txt; \
	then echo "catalogue-main: unwritable bin temp was accepted"; exit 1; fi; \
	test "$$(ls -A $$m | tr '\n' ' ')" = "stars_quick.bin stars_quick.bin.tmp "; test "$$(cat $$m/stars_quick.bin)" = keep; \
	grep -q "cannot write .*stars_quick.bin.tmp.*nothing changed" $$d/tmpfail.txt; \
	echo "catalogue-main bin-temp write: checked Err, old bin untouched ($$(cat $$d/tmpfail.txt))"

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

# M1.4d: the sky textures are generated, not committed (two ~80 MB PNGs). `make sky-assets`
# rebuilds them byte for byte from pinned downloads; data/sky/SHA256SUMS pins inputs AND outputs.
STARMAP_SCRIPTS := .claude/skills/starmap-manager/scripts
.PHONY: sky-inputs destar sky-assets sky-verify sky-bundle
sky-inputs: catalogue-inputs   ## M1.4d: sky pipeline inputs into data/raw: the public bucket first (D-18), then the original sources; check pins
	@sh tools/sky_assets.sh fetch inputs || echo "sky-inputs: bucket incomplete; falling back to the original sources"
	@test -f $(SKY)/noirlab_10k.tif || bash $(STARMAP_SCRIPTS)/download_background.sh raw
	@test -f data/raw/hip_v7.tsv || bash $(STARMAP_SCRIPTS)/download_stars.sh hip
	@$(MAKE) --no-print-directory sky-verify SKY_VERIFY=inputs

# M1.2c: the four catalogue inputs (CNS5 cns5.dat + cns5.csv, GCNS table1c.dat.gz + gcns.csv), pinned in
# data/sky/SHA256SUMS: the bucket first, then VizieR (download_stars.sh) and extract.ail for whatever is absent.
CAT_INPUTS := data/raw/(cns5\.dat|cns5\.csv|table1c\.dat\.gz|gcns\.csv)$$
catalogue-inputs: ## M1.2c: catalogue tier inputs into data/raw (bucket, else VizieR + extract.ail); check their pins
	@sh tools/sky_assets.sh fetch inputs '$(CAT_INPUTS)' || echo "catalogue-inputs: bucket incomplete; falling back to VizieR"
	@test -f data/raw/table1c.dat.gz || bash $(STARMAP_SCRIPTS)/download_stars.sh medium
	@test -f data/raw/cns5.dat || bash $(STARMAP_SCRIPTS)/download_stars.sh quick
	@test -f data/raw/cns5.csv || $(AILANG) run --quiet --bytecode --caps IO,FS --package-dir sim --entry main --args-json '{"kind":"cns5","input":"data/raw/cns5.dat","output":"data/raw/cns5.csv"}' sim/tools/extract.ail
	@test -f data/raw/gcns.csv || { gunzip -kf data/raw/table1c.dat.gz && $(AILANG) run --quiet --bytecode --caps IO,FS --package-dir sim --entry main --args-json '{"kind":"gcns","input":"data/raw/table1c.dat","output":"data/raw/gcns.csv"}' sim/tools/extract.ail; }
	@sh tools/sky_assets.sh verify inputs '$(CAT_INPUTS)'

sky-assets:       ## M1.4d/D-18: pinned sky textures: from the public bucket in seconds, else regenerate (inputs -> destar -> sky model, ~15 min)
	@if sh tools/sky_assets.sh fetch textures; then $(MAKE) --no-print-directory sky-verify SKY_VERIFY=textures; \
	else echo "sky-assets: textures not in the bucket; regenerating"; $(MAKE) --no-print-directory sky-regen; fi

sky-regen: sky-inputs destar sky-model   ## M1.4d: full regeneration; outputs must match data/sky/SHA256SUMS
	@$(MAKE) --no-print-directory sky-verify SKY_VERIFY=all

sky-publish:      ## D-18 maintainers (gcloud auth): upload pinned sky inputs + textures to gs://stapledons-voyage-assets/sky/<sha256>.<ext> (never overwrites)
	sh tools/sky_assets.sh publish

# Godot's export skips data/raw (it has a .gdignore), so the textures are staged as byte
# copies in sky_bundle/ (gitignored). Pinned outputs only: a texture that does not match
# data/sky/SHA256SUMS never ships. No textures -> a warning and a black-sky build.
sky-bundle:       ## M1.4d: stage the pinned sky textures into sky_bundle/ for the export (.png.bin, not imported)
	@rm -rf sky_bundle
	@if [ -f $(SKY)/noirlab_10k_destarred.png ] && [ -f $(SKY)/noirlab_10k_skymodel.png ]; then \
	  $(MAKE) --no-print-directory sky-verify SKY_VERIFY=textures && mkdir -p sky_bundle && \
	  cp $(SKY)/noirlab_10k_destarred.png sky_bundle/noirlab_10k_destarred.png.bin && \
	  cp $(SKY)/noirlab_10k_skymodel.png sky_bundle/noirlab_10k_skymodel.png.bin && \
	  echo "sky-bundle: staged $$(du -sh sky_bundle | cut -f1) of pinned sky textures"; \
	else echo "sky-bundle: WARNING no sky textures in $(SKY); this build renders a black sky (run make sky-assets)"; fi

SKY_VERIFY ?= all
sky-verify:       ## M1.4d: sha256-check the sky inputs and generated textures against data/sky/SHA256SUMS (SKY_VERIFY=inputs|textures|all)
	@case "$(SKY_VERIFY)" in inputs) k='input';; textures) k='texture';; *) k='input|output|texture';; esac; \
	grep -E "^[0-9a-f]{64} +($$k) " data/sky/SHA256SUMS \
	  | while read -r sum kind path; do \
	      if [ "$$path" = data/raw/hip_v7.tsv ]; then got=$$(grep -v '^#' "$$path" | shasum -a 256 | cut -d' ' -f1); \
	      else got=$$(shasum -a 256 "$$path" 2>/dev/null | cut -d' ' -f1); fi; \
	      if [ "$$got" = "$$sum" ]; then echo "  ok      $$path"; else echo "  MISMATCH $$path (got $${got:-missing})"; exit 1; fi; \
	    done && echo "sky-verify: $(SKY_VERIFY) match data/sky/SHA256SUMS"

.PHONY: catalogue-bytes
catalogue-bytes:  ## native F32 bytes: independent Python oracle, interpreter and five ordinary VM runs
	AILANG=$(AILANG) python3 tools/test_catalogue_bytes.py

.PHONY: python-guard
python-guard:     ## Python policy: every *.py allowlisted with a role (CLAUDE.md "Python")
	@sh tools/python_guard.sh

.PHONY: destar-test destar
destar-test:      ## star removal core (sim/tools/destar.ail) on a synthetic panorama: strict VM = interpreter
	@mkdir -p $(SCRATCH)
	@$(AILANG) run --quiet --bytecode --strict-bytecode --package-dir sim --entry destarVm --args-json 0 sim/tools/destar_test.ail > $(SCRATCH)/destar-vm.txt
	@$(AILANG) run --quiet --package-dir sim --entry destarVm --args-json 0 sim/tools/destar_test.ail > $(SCRATCH)/destar-interp.txt
	@cmp $(SCRATCH)/destar-vm.txt $(SCRATCH)/destar-interp.txt && test "$$(cat $(SCRATCH)/destar-vm.txt)" = "destar-ok" && echo "destar-test: $$(cat $(SCRATCH)/destar-vm.txt) (strict VM = interpreter)"

destar:           ## M1.4a offline: NOIRLab 10k -> catalogue-matched stars removed (Godot I/O, AILANG core); needs data/raw/{hip_v7.tsv,gcns.csv,cns5.csv}
	@if [ ! -f $(SKY)/noirlab_10k.png ] || [ $(SKY)/noirlab_10k.tif -nt $(SKY)/noirlab_10k.png ]; then sips -s format png $(SKY)/noirlab_10k.tif --out $(SKY)/noirlab_10k.png; fi
	$(GODOT) --headless --path . --script tools/destar_io.gd -- dump $(SKY)/noirlab_10k.png $(SKY)/noirlab_10k.rgb
	$(AILANG) run --quiet --bytecode --caps IO,FS --package-dir sim --entry main \
	  --args-json '{"rgb":"$(SKY)/noirlab_10k.rgb","w":10000,"h":5000,"hip":"data/raw/hip_v7.tsv","gcns":"data/raw/gcns.csv","cns5":"data/raw/cns5.csv","patches":"$(SKY)/destar_patches.bin","report":"data/sky/destar_report.json"}' \
	  sim/tools/destar.ail
	$(GODOT) --headless --path . --script tools/destar_io.gd -- apply $(SKY)/noirlab_10k.png $(SKY)/destar_patches.bin $(SKY)/noirlab_10k_destarred.png

include mk/ai.mk
