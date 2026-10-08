GODOT ?= godot
AILANG ?= ailang
# A path with a slash (make test AILANG=runtime/bin/ailang) is made absolute, so recipes that cd still find it
override AILANG := $(if $(findstring /,$(AILANG)),$(abspath $(AILANG)),$(AILANG))
# Godot runs that start the sim use the same ailang as the make line, never a stale one on PATH
GODOT_SIM = AILANG_BIN="$$(command -v $(AILANG))" $(GODOT)
SIM := sim/ship.ail
SIMFLAGS := --quiet --package-dir sim --caps IO --entry main
SCRATCH := .godot/tmp
# sunholo/relativity 0.10.0 _smoke digests, strict VM = interpreter (pinned from the package; the oracle must agree to 1e-9)
GEODESIC_LENS_DIGEST := 8.612720147193743
GEODESIC_SCHW_DIGEST := 92833.6848137945
AILANG_RELEASE ?= v0.52.0
RUNTIME := runtime
APP := build/macos/Stapledons Voyage.app

.PHONY: geodesic-oracle news-lint news-test all test splash transit-test deps area-test validate-areas m4-smoke interior-test glow-probe m4-physics-probe lint-precision glow-eps-sheet capture-m4 areas-stage physics sim ui map-capture replay replay-record parity parity-offaxis parity-v2 offaxis-v11-equiv strict rng-ref journey-replay wd-vm sky-vm sky-model tools-test extract-test extract destar-test destar golden bench capture run voyage publish-dev import runtime export-macos export-smoke starmap-assets starmap-publish sky-inputs sky-assets sky-regen sky-publish sky-bundle sky-verify

all: test

import:            ## register class_name scripts (needed once after clone)
	$(GODOT) --headless --path . --import

deps:              ## fetch locked AILANG packages into the cache; fail if the resolution would change
	cd sim && $(AILANG) lock
	@# ailang.lock carries a generated_at timestamp (reported upstream); ignore it, then restore the file
	git diff --exit-code -I '"generated_at"' sim/ailang.lock; rc=$$?; git checkout -q sim/ailang.lock; exit $$rc

test: python-guard lint-precision deps starmap-assets import physics sim ui lore-test codex-test lore-import-check lore-check news-lint news-test replay parity-v2 strict rng-ref wd-vm catalogue-vm catalogue-main catalogue-bytes catalogue-stats star-catalogue-test bright-test companions-test starmap-test truth-test starmap-truth-audit starmap-consistency starmap-consistency-large test-bright-audit sky-vm extract-test destar-test tools-test area-test validate-areas interior-test m4-smoke transit-test trappist1-test geodesic-oracle ## everything that runs without a GPU window

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

physics:           ## CPU physics reference vs known values; fails unless the run prints its '<n> passed, 0 failed' summary (a script that fails to parse exits 0 without one)
	@mkdir -p $(SCRATCH)
	@$(GODOT) --headless --path . --script tests/test_physics.gd > $(SCRATCH)/physics.txt 2>&1; rc=$$?; cat $(SCRATCH)/physics.txt; \
	  [ $$rc -eq 0 ] || { echo "physics: godot exited $$rc"; exit 1; }; \
	  grep -qE '^[0-9]+ passed, 0 failed$$' $(SCRATCH)/physics.txt || { echo "physics: no '<n> passed, 0 failed' summary line (parse error or early exit?)"; exit 1; }

# Gate 5: never compute 1 - beta near c. A hand-written 1 - beta (also 1.0-beta, 1 -beta) in code of a
# .gd or .gdshader outside physics/ and tests/ fails. String literals and comments are stripped first,
# so labels such as "1 - beta" never match. Hits that are not a live computation are listed in
# tests/fixtures/lint_precision/allowlist.txt as path<TAB>stripped code<TAB>reason, keyed on the code
# text and not the line number: edits that move lines keep the entry, and any other line in that file
# that matches is still reported. The fixture bad_one_minus_beta.gd MUST match all 4 planted lines (else
# the pattern matches nothing) and good_one_minus_beta.gd must match none. Plain shell, no Python.
LINT_OMB_DIR := tests/fixtures/lint_precision
LINT_OMB_RE := (^|[^A-Za-z0-9_.])1(\.0*)?[[:space:]]*-[[:space:]]*beta([^A-Za-z0-9_]|$$)
lint-precision:    ## no hand-computed 1 - beta in *.gd / *.gdshader outside physics/ and tests/ (positive control: tests/fixtures/lint_precision/bad_one_minus_beta.gd must fail)
	@hits_in() { sed -E -e 's/"[^"]*"/""/g' -e "s/'[^']*'/''/g" -e 's#(//|\#).*$$##' -e 's/^[[:space:]]+//' -e 's/[[:space:]]+$$//' "$$1" | grep -n -E '$(LINT_OMB_RE)' | sed "s|^|$$1:|"; }; \
	  bad=$$(hits_in $(LINT_OMB_DIR)/bad_one_minus_beta.gd | wc -l | tr -d ' '); \
	  [ "$$bad" -eq 4 ] || { echo "lint-precision: positive control matched $$bad of 4 planted lines; the pattern is broken"; exit 1; }; \
	  [ -z "$$(hits_in $(LINT_OMB_DIR)/good_one_minus_beta.gd)" ] || { echo "lint-precision: the clean control file matched; the pattern is too broad"; exit 1; }; \
	  hits=$$(git ls-files -co --exclude-standard -- '*.gd' '*.gdshader' | grep -v -E '^(physics|tests|runtime|addons)/' | while read -r f; do hits_in "$$f"; done \
	    | awk -F'\t' 'FILENAME == ARGV[1] { allow[$$1 "\t" $$2] = 1; next } { i = index($$0, ":"); p = substr($$0, 1, i - 1); r = substr($$0, i + 1); c = substr(r, index(r, ":") + 1); if (!((p "\t" c) in allow)) print }' $(LINT_OMB_DIR)/allowlist.txt -); \
	  if [ -n "$$hits" ]; then echo "$$hits"; echo "lint-precision: hand-computed 1 - beta outside physics/ and tests/ (take 1 - beta from the sim or sunholo/relativity, or allowlist it with a reason)"; exit 1; fi; \
	  echo "lint-precision: ok (positive control matched $$bad lines; $$(grep -c . $(LINT_OMB_DIR)/allowlist.txt) allowlisted non-computations; no live hand-computed 1 - beta)"

# M4.0 area bundles (brief §9). BUNDLE=dir checks one bundle; the default checks the blockout
# test fixture and the current shipping bundle (AC13, AC14 validation half).
BUNDLE ?= tests/fixtures/areas/bridge_blockout assets/areas/bridge
validate-areas:    ## M4.0 AC13/AC14: area bundle(s) valid: V17 schema, alpha 0 where space shows, camera round trip <= 1 px, GLB metres/Y-up with WALK_/SPAWN_/INTERACT_
	$(GODOT) --headless --path . --script tools/validate_area.gd -- $(BUNDLE)

area-test:         ## M4.0 bundle loader + validate-areas positive controls (each check must fail on a bundle broken its way)
	$(GODOT) --headless --path . --script tests/test_area_bundle.gd

m4-smoke:          ## M4.2 AC14 smoke half (headless, real sim): on each BUNDLE the captain walks to the nav console, it opens the map, alpha Cen A is committed, the sky follows the cruise to the arrival; walking sends no intents
	@mkdir -p $(SCRATCH)
	@for b in $(BUNDLE); do n=$$(echo $$b | tr '/' '_'); \
	  $(GODOT_SIM) --headless --path . -- --m4-smoke --bundle=$$b --record=$(CURDIR)/$(SCRATCH)/m4-smoke-$$n.ndjson > $(SCRATCH)/m4-smoke-$$n.log 2>&1; rc=$$?; \
	  grep -E '^(m4-smoke|interior):' $(SCRATCH)/m4-smoke-$$n.log; \
	  test $$rc = 0 && grep -q '^m4-smoke: OK$$' $(SCRATCH)/m4-smoke-$$n.log || { echo "m4-smoke: FAILED on $$b (exit $$rc; log $(SCRATCH)/m4-smoke-$$n.log)"; exit 1; }; done

interior-test:     ## M4.2 composite order and pan factors, one tonemap, glow CPU mirror vs the package probe, WALK_, the captain, bundle fields, parallax clamp, export staging
	@mkdir -p $(SCRATCH)
	@$(GODOT) --headless --path . --script tests/test_interior.gd > $(SCRATCH)/interior-test.log 2>&1; rc=$$?; cat $(SCRATCH)/interior-test.log | grep -v '^  ok'; \
	  test $$rc = 0 && grep -q '^interior: [0-9]* passed, 0 failures$$' $(SCRATCH)/interior-test.log || { echo "interior-test: FAILED (a parse error exits 0, so the summary line is required)"; exit 1; }

transit-test:      ## M4.3a: warp intent, 3 s burn pacing, HUD bindings + audit positive controls, phases, arrival card, standoff_au 1000 (real sim, headless); AC3 grep half
	@mkdir -p $(SCRATCH)
	@$(GODOT_SIM) --headless --path . --script tests/test_transit.gd > $(SCRATCH)/transit-test.log 2>&1; rc=$$?; grep -v '^  ok' $(SCRATCH)/transit-test.log | grep -v '^ERROR: .*leaked\|^   at: \|^Godot Engine\|^$$'; \
	  test $$rc = 0 && ! grep -q 'SCRIPT ERROR' $(SCRATCH)/transit-test.log && grep -q '^transit: [0-9]* passed, 0 failures$$' $(SCRATCH)/transit-test.log || { echo "transit-test: FAILED (a parse error exits 0, so the summary line is required; log $(SCRATCH)/transit-test.log)"; exit 1; }
	@! grep -rniE "save_game|load_game|ResourceSaver" interior ui || { echo "transit-test: AC3 grep half found a save/load path"; exit 1; }

glow-probe:        ## M4.2 check values: the forward-glow profile and efficacy from sunholo/relativity 0.8.0 (tools/glow_probe), VM = interpreter
	@mkdir -p $(SCRATCH)
	cd tools/glow_probe && $(AILANG) lock >/dev/null && git checkout -q ailang.lock 2>/dev/null || true
	$(AILANG) run --quiet --package-dir tools/glow_probe --caps IO --entry main tools/glow_probe/probe.ail > $(SCRATCH)/glow-probe.txt
	$(AILANG) run --quiet --bytecode --package-dir tools/glow_probe --caps IO --entry main tools/glow_probe/probe.ail > $(SCRATCH)/glow-probe-vm.txt
	diff $(SCRATCH)/glow-probe.txt $(SCRATCH)/glow-probe-vm.txt && cat $(SCRATCH)/glow-probe.txt

m4-physics-probe:  ## M4.6 check values: cruise (gammaOf, coastAt, planBurnCoastBurn), ISM load, glow profile, every guided-voyage stop (sim/tools/m4_physics_probe.ail), VM = interpreter
	@mkdir -p $(SCRATCH)
	$(AILANG) run --quiet --caps IO --package-dir sim --entry main sim/tools/m4_physics_probe.ail > $(SCRATCH)/m4-physics-probe.txt
	$(AILANG) run --quiet --bytecode --caps IO --package-dir sim --entry main sim/tools/m4_physics_probe.ail > $(SCRATCH)/m4-physics-probe-vm.txt
	diff $(SCRATCH)/m4-physics-probe.txt $(SCRATCH)/m4-physics-probe-vm.txt && cat $(SCRATCH)/m4-physics-probe.txt

capture-m4:        ## M4.2 S1 review captures to renders/m4/ (needs a GPU window): the captain walking on the bridge at rest, 0.99c and the cap, the nav console opening the map, pans, glow preview, contact sheet
	$(GODOT_SIM) --path . -- --interior-capture=renders/m4
	test -s renders/m4/contact_sheet.png

glow-eps-sheet:    ## D-29 follow-up: interior + forward sky at 0.99c..cap for each candidate eps through the eye exposure -> renders/glow/eps_compare.{png,jpg} + glow_eps_sheet.json (needs a GPU window)
	$(GODOT_SIM) --path . -- --glow-eps-sheet=renders/glow
	test -s renders/glow/eps_compare.jpg

areas-stage:       ## M4.2: stage assets/areas/<area>/ into areas_bundle/<area>/<file>.bin for the export (assets/areas is .gdignore'd; previews and review/ stay out)
	@rm -rf areas_bundle
	@for d in assets/areas/*/; do a=$$(basename $$d); mkdir -p areas_bundle/$$a; \
	  for f in $$d*; do [ -f "$$f" ] || continue; case "$$(basename $$f)" in preview_*|SHA256SUMS|validation.json) continue;; esac; \
	  cp "$$f" "areas_bundle/$$a/$$(basename $$f).bin"; done; done
	@echo "areas-stage: staged $$(ls areas_bundle | tr '\n' ' ')($$(du -sh areas_bundle | cut -f1))"

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
	@# scriptedRoundTrip (M4.1, AC1): Sol -> alpha Cen -> Sol, 0.99c, 1,000 AU stand-off, zero dwell; which = Earth yr, ship yr, news epoch at alpha Cen, end gap, tier at alpha Cen, tier at the return
	@for k in 0 1 2 3 4 5; do \
	  want=$$(python3 -c "import math,sys; a=750000*1.032295275553596; p=2.6466524123622457; s=1000*149597870700/9460730472580800; dl=4.37-s; db=2*math.sinh(p/2)**2/a; dc=dl-2*db; t=2*math.sinh(p)/a+dc/math.tanh(p); tau=2*p/a+dc/math.sinh(p); print(repr([2*t,2*tau,t-dl,2*t-2*tau,0.0,2.0][int(sys.argv[1])]))" $$k); \
	  got=$$($(AILANG) run --quiet --bytecode --strict-bytecode --package-dir sim --entry scriptedRoundTrip --args-json $$k sim/core.ail); \
	  interp=$$($(AILANG) run --quiet --package-dir sim --entry scriptedRoundTrip --args-json $$k sim/core.ail); \
	  echo "strict scriptedRoundTrip($$k): VM $$got | interpreter $$interp | closed form $$want"; \
	  [ "$$got" = "$$interp" ] && python3 -c "import sys; sys.exit(0 if abs($$got - $$want) < 1e-9 else 1)" || exit 1; \
	done
	@got=$$($(AILANG) run --quiet --bytecode --strict-bytecode --package-dir sim --entry consequenceVm --args-json 0 sim/consequence_test.ail); \
	interp=$$($(AILANG) run --quiet --package-dir sim --entry consequenceVm --args-json 0 sim/consequence_test.ail); \
	echo "strict consequenceVm: VM $$got | interpreter $$interp"; [ "$$got" = "consequence-ok" ] && [ "$$interp" = "consequence-ok" ]
	@got=$$($(AILANG) run --quiet --bytecode --strict-bytecode --package-dir sim --entry transitVm --args-json 0 sim/transit_test.ail); \
	interp=$$($(AILANG) run --quiet --package-dir sim --entry transitVm --args-json 0 sim/transit_test.ail); \
	echo "strict transitVm (M4.3a): VM $$got | interpreter $$interp"; [ "$$got" = "transit-ok" ] && [ "$$interp" = "transit-ok" ]
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

geodesic-oracle:   ## M3.1a/b: the Python oracle for sunholo/relativity 0.10.0 geodesics, tides and hover (design V9-V16) passes --check, and its digests equal the values the package pins
	python3 tools/geodesic_ref.py --check
	@smoke=runtime/cache/registry/sunholo/relativity/$$(sed -n 's/^"sunholo\/relativity" = "\(.*\)"/\1/p' sim/ailang.toml)/_smoke.ail; \
	  if [ -f "$$smoke" ]; then v=$$(AILANG_RELAX_MODULES=1 $(AILANG) run --quiet --bytecode --strict-bytecode --entry lensDigest --args-json 16 $$smoke 2>/dev/null); \
	  test "$$v" = "$(GEODESIC_LENS_DIGEST)" && echo "geodesic-oracle: pinned package lensDigest 16 on the strict VM = $$v" || { echo "geodesic-oracle: package lensDigest 16 = '$$v', pin $(GEODESIC_LENS_DIGEST)"; exit 1; }; \
	  else echo "geodesic-oracle: $$smoke not in the runtime cache (make runtime); package digest not rerun"; fi
	@d=$$(python3 tools/geodesic_ref.py digest 16); s=$$(python3 tools/geodesic_ref.py sdigest 64); echo "lensDigest 16 = $$d, schwarzschildDigest 64 = $$s"; \
	  python3 -c "import sys; d, s = float(sys.argv[1]), float(sys.argv[2]); ok = abs(d - $(GEODESIC_LENS_DIGEST)) <= 1e-9 and abs(s - $(GEODESIC_SCHW_DIGEST)) <= 1e-9 * abs(s); print('geodesic-oracle: digests ' + ('match' if ok else 'DIFFER from') + ' the package pins'); sys.exit(0 if ok else 1)" "$$d" "$$s"

journey-replay:    ## AC14: the alpha Cen replay runs headless (no Godot), arrives on its last input; VM == interpreter == golden (replay case alpha_cen)
	AILANG="$(AILANG)" python3 tools/replay.py --case alpha_cen

wd-vm:             ## WD package NaN contract on the strict VM (ailang#1419: `ailang test` interpreter cannot see NaN-guard mutants)
	got=$$($(AILANG) run --quiet --bytecode --strict-bytecode --package-dir sim --entry wdVmNaN --args-json 0 sim/tools/catalogue_probe_test.ail); \
	echo "wd-vm: $$got"; [ "$$got" = "wd-nan-ok" ]

golden:            ## GPU shader vs CPU reference star positions (needs a GPU window); M1.6b: 144 off-axis/rolled star cases + 16 background markers; M1.3: stand-off rebasing, 60 kK WD, cull; M1.5a: exposure (star lux, sky cd/m^2, display floor, AC8 ladder); M1.8: forward CMB (sharp, PSF, zeros); M4.2: interior G-M4-1..6 (composite position, one tonemap, forward pole, glow, plate6, spectral colour10)
	@mkdir -p $(SCRATCH)
	@$(GODOT) --path . -- --golden > $(SCRATCH)/golden.log 2>&1; rc=$$?; cat $(SCRATCH)/golden.log; \
	  test $$rc = 0 && grep -q '^off-axis golden: 144 cases .* 0 failures$$' $(SCRATCH)/golden.log && \
	  test "$$(grep -c 'background marker' $(SCRATCH)/golden.log)" = 16 && test "$$(grep -c '^ok    stand-off alpha Cen A' $(SCRATCH)/golden.log)" = 8 && \
	  grep -q '^ok    hot white dwarf 60 kK' $(SCRATCH)/golden.log && grep -q '^ok    faint-star cull' $(SCRATCH)/golden.log && \
	  grep -q '^ok    display floor' $(SCRATCH)/golden.log && grep -q '^ok    exposure golden (star)' $(SCRATCH)/golden.log && \
	  grep -q '^ok    exposure golden (sky)' $(SCRATCH)/golden.log && grep -q '^ok    limiting magnitude' $(SCRATCH)/golden.log && \
	  test "$$(grep -c '^ok    CMB golden' $(SCRATCH)/golden.log)" = 10 && \
	  grep -q '^ok    G-M4-1 composite position: 72 cases' $(SCRATCH)/golden.log && grep -q '^ok    G-M4-2 one tonemap' $(SCRATCH)/golden.log && \
	  test "$$(grep -c '^ok    G-M4-3 forward pole' $(SCRATCH)/golden.log)" = 6 && test "$$(grep -c '^ok    G-M4-4 glow' $(SCRATCH)/golden.log)" = 8 && test "$$(grep -c '^ok    G-M4-6 colour' $(SCRATCH)/golden.log)" = 10 && \
	  test "$$(grep -c '^ok    G-M4-5 plate' $(SCRATCH)/golden.log)" = 6 && \
	  grep -q '^interior golden: 0 failures$$' $(SCRATCH)/golden.log && grep -q '^golden: 0 failures$$' $(SCRATCH)/golden.log || \
	  { echo "golden: FAILED (exit $$rc, or the case counts changed: want 144 off-axis + 16 background markers + 8 stand-off + hot WD + cull + M1.5a display floor, star lux, sky cd/m^2, AC8 ladder + M1.8 10 CMB cases + M4.2 G-M4-1 72, G-M4-2, G-M4-3 6, G-M4-4 8, G-M4-5 plate6, G-M4-6 colour10)"; exit 1; }

# M1.3 bench: the default Metal driver gives the frame times the player gets; Godot 4.7's Metal
# driver reports no GPU timestamps, so a second run on Vulkan (MoltenVK) measures the star pass.
BENCH_SECONDS ?= 30
BENCH_TIER = $(if $(filter command line environment,$(origin TIER)),$(TIER),large)
BENCH_SIZE ?=
bench:             ## M1.3 AC7 (stars part): scripted flight at 2560x1440 (BENCH_SIZE=WxH), vsync off: p50/p99 frame ms, star-pass GPU ms, CPU rebase ms (GPU window; TIER=large default)
	@mkdir -p $(SCRATCH); for drv in metal vulkan; do echo "bench: host load $$(uptime | sed 's/.*load/load/')"; \
	  $(GODOT_SIM) --path . --rendering-driver $$drv -- --bench=$(BENCH_SECONDS) --tier=$(BENCH_TIER) $(if $(BENCH_SIZE),--bench-size=$(BENCH_SIZE)) > $(SCRATCH)/bench_$$drv.log 2>&1; rc=$$?; \
	  grep -E '^(bench|starfield):' $(SCRATCH)/bench_$$drv.log; \
	  test $$rc = 0 && grep -q '^bench: frame ms' $(SCRATCH)/bench_$$drv.log && grep -q '^bench: limiting magnitude .*: ok$$' $(SCRATCH)/bench_$$drv.log || { echo "bench: $$drv run FAILED (exit $$rc; log $(SCRATCH)/bench_$$drv.log)"; exit 1; }; done

splash:            ## compose the boot splash ui/splash/splash.png (Milky Way crop + wordmark + AILANG, like the site hero); needs a GPU window and data/raw/background/noirlab_10k_destarred.png
	$(GODOT) --path . --script tools/splash_compose.gd

capture:           ## 1 g voyage through the AILANG sim, PNGs to renders/ (needs a GPU window); M1.5a: + camera auto / fixed-EV starboard pairs, exposure_sheet.png; M1.8: gamma 275/707 CMB views, cmb_sheet.png
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

export-macos: runtime sky-bundle areas-stage starmap-assets import   ## build the macOS .app (arm64, ad-hoc signed) with the sim runtime, the pinned sky textures and the area bundles
	@mkdir -p build/macos
	@git describe --tags --always --dirty > runtime/build_version.txt # bundled (runtime/*): the audit's "build" field
	$(GODOT) --headless --path . --export-release "macOS" "$(APP)"
	@du -sh "$(APP)"

export-smoke:      ## run the exported .app's capture with NO ailang on PATH; must produce the contact sheet
	@rm -rf $(SCRATCH)/export-smoke $(SCRATCH)/export-smoke-home && mkdir -p $(SCRATCH)/export-smoke $(SCRATCH)/export-smoke-home
	exe=$$(defaults read "$(CURDIR)/$(APP)/Contents/Info.plist" CFBundleExecutable); \
	env -i PATH=/usr/bin:/bin HOME="$(CURDIR)/$(SCRATCH)/export-smoke-home" "$(APP)/Contents/MacOS/$$exe" -- --capture="$(CURDIR)/$(SCRATCH)/export-smoke"
	@test -s $(SCRATCH)/export-smoke/contact_sheet.png && echo "export-smoke: OK ($$(ls $(SCRATCH)/export-smoke | wc -l | tr -d ' ') files)"
	@# M4.2: the interior slice from inside the .app (the bridge bundle staged as areas_bundle/*.bin in the .pck)
	exe=$$(defaults read "$(CURDIR)/$(APP)/Contents/Info.plist" CFBundleExecutable); \
	env -i PATH=/usr/bin:/bin HOME="$(CURDIR)/$(SCRATCH)/export-smoke-home" "$(APP)/Contents/MacOS/$$exe" --headless -- --m4-smoke > $(SCRATCH)/export-smoke/m4-smoke.log 2>&1; \
	grep -E '^(m4-smoke|interior):' $(SCRATCH)/export-smoke/m4-smoke.log; grep -q 'interior: bundle res://areas_bundle/bridge' $(SCRATCH)/export-smoke/m4-smoke.log && grep -q '^m4-smoke: OK$$' $(SCRATCH)/export-smoke/m4-smoke.log && echo "export-smoke: interior OK from the staged bundle"

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
	  env -u AI_LIVE $(AILANG) run --quiet --bytecode --strict-bytecode --package-dir sim --entry $$entry --args-json 0 $$f > $(SCRATCH)/$$entry-vm.txt; \
	  env -u AI_LIVE $(AILANG) run --quiet --package-dir sim --entry $$entry --args-json 0 $$f > $(SCRATCH)/$$entry-interp.txt; \
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
bright_args = "{\"hip2\":\"data/raw/hip2.dat.gz\",\"hipMain\":\"data/raw/hip_main.dat\",\"cns5\":\"data/raw/cns5.dat\",\"gcns\":\"data/raw/gcns.csv\",\"companions\":\"$(COMPANIONS)\",\"lock\":\"sim/ailang.lock\",\"out\":\"$(1)\",\"ailang\":\"$(CAT_AILANG)\"}"
fill_args = "{\"tier\":\"quick\",\"csv\":\"data/raw/cns5.csv\",\"raw\":\"data/raw/cns5.dat\",\"lock\":\"sim/ailang.lock\",\"out\":\"$(1)\",\"ailang\":\"$(CAT_AILANG)\",\"hip\":\"data/raw/hip_main.dat\",\"companions\":\"$(COMPANIONS)\",\"truth\":\"$(TRUTH)\"}"
# The companion rule (design_docs/planned/r1/m1-companion-parallax.md): `make companions` writes the table, every
# tier and the map apply it (COMPANIONS picks the file; catalogue-verify uses its own rebuilt copy).
COMPANIONS ?= data/starmap/companions/companions.csv
gcns_args = "{\"tier\":\"$(1)\",\"csv\":\"data/raw/gcns.csv\",\"raw\":\"data/raw/table1c.dat.gz\",\"lock\":\"sim/ailang.lock\",\"out\":\"$(2)\",\"ailang\":\"$(CAT_AILANG)\",\"companions\":\"$(COMPANIONS)\",\"truth\":\"$(TRUTH)\"}"
.PHONY: catalogue catalogue-scan catalogue-main bright-test test-bright-audit companions companions-test
catalogue:        ## M1.2b-T3/M1.2d: data/raw -> $(CATALOGUE_OUT)/stars_$(TIER).bin + sidecar on the VM (TIER=quick|medium|large|bright; quick carries the HIP photometry fill)
	@case "$(TIER)" in \
	  quick) $(CAT_RUN) --bytecode --entry mainFill --args-json $(call fill_args,$(CATALOGUE_OUT)) sim/tools/bright_main.ail;; \
	  bright) $(CAT_RUN) --bytecode --entry brightMain --args-json $(call bright_args,$(CATALOGUE_OUT)) sim/tools/bright_main.ail;; \
	  medium|large) $(CAT_RUN) --bytecode --entry gcnsMain --args-json $(call gcns_args,$(TIER),$(CATALOGUE_OUT)) sim/tools/bright_main.ail;; \
	  *) echo "catalogue: TIER must be quick, medium, large or bright (got '$(TIER)')"; exit 2;; esac

# M1.7 (F6, Q7): the galaxy map catalogue, from the quick + bright tier rows within 25 pc (float64; ids
# "Gaia DR3 n" / "CNS5:n" / "HIP n"). STARMAP_OUT picks the file (catalogue-verify writes a scratch copy).
STARMAP_OUT ?= data/starmap/stars.json
map_args = "{\"csv\":\"data/raw/cns5.csv\",\"cns5\":\"data/raw/cns5.dat\",\"hip2\":\"data/raw/hip2.dat.gz\",\"hipMain\":\"data/raw/hip_main.dat\",\"gcns\":\"data/raw/gcns.csv\",\"companions\":\"$(COMPANIONS)\",\"truth\":\"$(TRUTH)\",\"lock\":\"sim/ailang.lock\",\"out\":\"$(1)\",\"ailang\":\"$(CAT_AILANG)\"}"
.PHONY: starmap starmap-test
starmap:          ## M1.7: data/raw -> $(STARMAP_OUT), the galaxy map catalogue (quick + bright within 25 pc) on the VM
	$(CAT_RUN) --bytecode --entry mapMain --args-json $(call map_args,$(STARMAP_OUT)) sim/tools/bright_main.ail

starmap-test:     ## M1.7 map catalogue (sim/tools/starmap.ail): named checks, strict VM = interpreter
	@mkdir -p $(SCRATCH)
	@$(AILANG) run --quiet --bytecode --strict-bytecode --package-dir sim --entry starmapVm --args-json 0 sim/tools/starmap_test.ail > $(SCRATCH)/starmap-vm.txt
	@$(AILANG) run --quiet --package-dir sim --entry starmapVm --args-json 0 sim/tools/starmap_test.ail > $(SCRATCH)/starmap-interp.txt
	@cmp $(SCRATCH)/starmap-vm.txt $(SCRATCH)/starmap-interp.txt && test "$$(cat $(SCRATCH)/starmap-vm.txt)" = "starmap-ok"
	@echo "starmap-test: $$(cat $(SCRATCH)/starmap-vm.txt) (strict VM = interpreter)"

# One position per star (design_docs/planned/r1/starmap-single-truth.md): the star-truth table that every
# tier and the map take positions from. TRUTH picks the table (catalogue-verify uses its own rebuilt copy).
TRUTH ?= data/starmap/truth/positions.csv
TRUTH_OUT ?= data/starmap/truth
truth_args = "{\"cns5\":\"data/raw/cns5.dat\",\"cns5Csv\":\"data/raw/cns5.csv\",\"gcnsRaw\":\"data/raw/table1c.dat.gz\",\"gcnsDat\":\"$(SCRATCH)/table1c.dat\",\"gcns\":\"data/raw/gcns.csv\",\"hip2\":\"data/raw/hip2.dat.gz\",\"hipMain\":\"data/raw/hip_main.dat\",\"companions\":\"$(COMPANIONS)\",\"out\":\"$(1)\",\"ailang\":\"$(CAT_AILANG)\"}"
.PHONY: starmap-truth starmap-truth-parity starmap-truth-audit starmap-consistency starmap-consistency-large truth-test
starmap-truth:    ## star truth: CNS5 x GCNS x cross-ids -> $(TRUTH_OUT)/positions.csv + positions.json on the VM (rule truth-1)
	@mkdir -p $(SCRATCH) $(TRUTH_OUT); test -f $(SCRATCH)/table1c.dat || gunzip -c data/raw/table1c.dat.gz > $(SCRATCH)/table1c.dat
	$(CAT_RUN) --bytecode --entry truthMain --args-json $(call truth_args,$(TRUTH_OUT)) sim/tools/bright_main.ail

starmap-truth-parity: ## star truth on the VM and the interpreter into scratch: byte-identical to each other and to the committed table
	@mkdir -p $(SCRATCH)/truth-vm $(SCRATCH)/truth-interp; test -f $(SCRATCH)/table1c.dat || gunzip -c data/raw/table1c.dat.gz > $(SCRATCH)/table1c.dat
	@$(CAT_RUN) --bytecode --entry truthMain --args-json $(call truth_args,$(SCRATCH)/truth-vm) sim/tools/bright_main.ail
	@$(CAT_RUN) --entry truthMain --args-json $(call truth_args,$(SCRATCH)/truth-interp) sim/tools/bright_main.ail
	@for f in positions.csv positions.json; do cmp $(SCRATCH)/truth-vm/$$f $(SCRATCH)/truth-interp/$$f && cmp $(SCRATCH)/truth-vm/$$f $(TRUTH_OUT)/$$f || exit 1; done
	@echo "starmap-truth-parity: VM = interpreter = committed ($$(shasum -a 256 $(TRUTH_OUT)/positions.csv | cut -c1-16))"

starmap-truth-audit: ## AC4: every truth disagreement over max(3 sigma, 1%) has a resolution and is listed in the audit doc
	@$(AILANG) run --quiet --bytecode --caps IO,FS --package-dir sim --entry auditMain --args-json '{"truth":"$(TRUTH)","doc":"design_docs/implemented/r1/starmap-truth-audit.md"}' sim/tools/bright_main.ail

starmap-consistency: ## AC3 (headless): every stars.json destination in the sky stack once, at the navigation position (<= 1e-9 ly); pins are no-ops (TIER=medium|large)
	@mkdir -p $(SCRATCH); $(GODOT) --headless --path . --script tools/starmap_consistency.gd -- --tier $(if $(filter command line environment,$(origin TIER)),$(TIER),medium) $(CONSISTENCY_ARGS) > $(SCRATCH)/starmap-consistency.log 2>&1; rc=$$?; \
	  grep -E '^(starmap-consistency|  )' $(SCRATCH)/starmap-consistency.log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/starmap-consistency.log && grep -q '^starmap-consistency: PASS$$' $(SCRATCH)/starmap-consistency.log

# The large tier is a gate too (eval R1-STARMAP-LARGE round 1): make test fetches it (starmap-assets, pinned)
# and checks the large stack; a missing or short file FAILS here (the game's runtime fallback is only a warning).
starmap-consistency-large: ## the consistency gate on the large stack: stars_large.bin present with 331,311 rows, every destination once, no identity twice
	@$(MAKE) --no-print-directory starmap-consistency TIER=large CONSISTENCY_ARGS="--expect-rows 331311"

truth-test:       ## star truth (sim/tools/truth.ail): named checks strict VM = interpreter; real-byte fixtures VM = interpreter
	@mkdir -p $(SCRATCH)
	@$(AILANG) run --quiet --bytecode --strict-bytecode --package-dir sim --entry truthVm --args-json 0 sim/tools/truth_test.ail > $(SCRATCH)/truth-vm.txt
	@$(AILANG) run --quiet --package-dir sim --entry truthVm --args-json 0 sim/tools/truth_test.ail > $(SCRATCH)/truth-interp.txt
	@cmp $(SCRATCH)/truth-vm.txt $(SCRATCH)/truth-interp.txt && test "$$(cat $(SCRATCH)/truth-vm.txt)" = "truth-ok"
	@$(AILANG) run --quiet --bytecode --caps FS --package-dir sim --entry truthFixtures --args-json '"tools/fixtures"' sim/tools/truth_test.ail > $(SCRATCH)/truth-fx-vm.txt
	@$(AILANG) run --quiet --caps FS --package-dir sim --entry truthFixtures --args-json '"tools/fixtures"' sim/tools/truth_test.ail > $(SCRATCH)/truth-fx-interp.txt
	@cmp $(SCRATCH)/truth-fx-vm.txt $(SCRATCH)/truth-fx-interp.txt && test "$$(cat $(SCRATCH)/truth-fx-vm.txt)" = "truth-fixtures-ok"
	@echo "truth-test: $$(cat $(SCRATCH)/truth-vm.txt), $$(cat $(SCRATCH)/truth-fx-vm.txt) (VM = interpreter)"

companions-test:  ## the companion rule (sim/tools/companions.ail): thresholds, Sirius B, alpha Cen B, Luyten 726-8 B, Wolf 424 B, false pairs; strict VM = interpreter, real-line fixtures VM = interpreter
	@mkdir -p $(SCRATCH)
	@$(AILANG) run --quiet --bytecode --strict-bytecode --package-dir sim --entry companionsVm --args-json 0 sim/tools/companions_test.ail > $(SCRATCH)/companions-vm.txt
	@$(AILANG) run --quiet --package-dir sim --entry companionsVm --args-json 0 sim/tools/companions_test.ail > $(SCRATCH)/companions-interp.txt
	@cmp $(SCRATCH)/companions-vm.txt $(SCRATCH)/companions-interp.txt && test "$$(cat $(SCRATCH)/companions-vm.txt)" = "companions-ok"
	@$(AILANG) run --quiet --bytecode --caps FS --package-dir sim --entry companionsFixtures --args-json '"tools/fixtures"' sim/tools/companions_test.ail > $(SCRATCH)/companions-fx-vm.txt
	@$(AILANG) run --quiet --caps FS --package-dir sim --entry companionsFixtures --args-json '"tools/fixtures"' sim/tools/companions_test.ail > $(SCRATCH)/companions-fx-interp.txt
	@cmp $(SCRATCH)/companions-fx-vm.txt $(SCRATCH)/companions-fx-interp.txt && test "$$(cat $(SCRATCH)/companions-fx-vm.txt)" = "companions-fixtures-ok"
	@echo "companions-test: $$(cat $(SCRATCH)/companions-vm.txt), $$(cat $(SCRATCH)/companions-fx-vm.txt) (VM = interpreter)"

test-bright-audit: ## M1.2d AC11 auditor (tools/bright_star_audit.gd) on synthetic renders; the render gate itself is M1.5b
	$(GODOT) --headless --path . --script tests/test_bright_audit.gd

bright-test:      ## M1.2d bright tier + CNS5 fill (sim/tools/bright.ail): named checks strict VM = interpreter; real-byte fixtures VM = interpreter
	@mkdir -p $(SCRATCH)
	@$(AILANG) run --quiet --bytecode --strict-bytecode --package-dir sim --entry brightVm --args-json 0 sim/tools/bright_test.ail > $(SCRATCH)/bright-vm.txt
	@$(AILANG) run --quiet --package-dir sim --entry brightVm --args-json 0 sim/tools/bright_test.ail > $(SCRATCH)/bright-interp.txt
	@cmp $(SCRATCH)/bright-vm.txt $(SCRATCH)/bright-interp.txt && test "$$(cat $(SCRATCH)/bright-vm.txt)" = "bright-vm-ok"
	@$(AILANG) run --quiet --bytecode --caps FS --package-dir sim --entry brightFixtures --args-json '"tools/fixtures"' sim/tools/bright_test.ail > $(SCRATCH)/bright-fx-vm.txt
	@$(AILANG) run --quiet --caps FS --package-dir sim --entry brightFixtures --args-json '"tools/fixtures"' sim/tools/bright_test.ail > $(SCRATCH)/bright-fx-interp.txt
	@cmp $(SCRATCH)/bright-fx-vm.txt $(SCRATCH)/bright-fx-interp.txt && test "$$(cat $(SCRATCH)/bright-fx-vm.txt)" = "bright-fixtures-ok"
	@echo "bright-test: $$(cat $(SCRATCH)/bright-vm.txt), $$(cat $(SCRATCH)/bright-fx-vm.txt) (VM = interpreter)"

companions:       ## the companion rule over CNS5 + GCNS + bright rows -> $(COMPANIONS) (std/gzip stops at 100 MB, so table1c is gunzipped into the scratch dir first)
	@mkdir -p $(SCRATCH)
	gunzip -c data/raw/table1c.dat.gz > $(SCRATCH)/table1c.dat
	$(CAT_RUN) --bytecode --entry companionsMain --args-json "{\"cns5\":\"data/raw/cns5.dat\",\"hip2\":\"data/raw/hip2.dat.gz\",\"hipMain\":\"data/raw/hip_main.dat\",\"gcns\":\"data/raw/gcns.csv\",\"gcnsRaw\":\"data/raw/table1c.dat.gz\",\"gcnsDat\":\"$(SCRATCH)/table1c.dat\",\"out\":\"$(COMPANIONS)\"}" sim/tools/bright_main.ail
	@rm -f $(SCRATCH)/table1c.dat

catalogue-scan:   ## M1.2b-T3: the conservative F32 bound on every real CNS5 and GCNS row (0 refusals; refused ids are listed for review)
	@for src in cns5 gcns; do $(CAT_RUN) --bytecode --entry scan --args-json "\"data/raw/$$src.csv\"" sim/tools/catalogue_main.ail || exit 1; done

# M1.2c: the committed quick + medium tiers (D-3) and the M1.2d bright tier (Q4); large stays ignored. The stats run in CI on the
# committed bins; verify rebuilds them from the pinned inputs and needs data/raw (make catalogue-inputs).
.PHONY: catalogue-stats star-catalogue-test catalogue-verify catalogue-inputs
catalogue-stats:  ## M1.2c AC2/AC3: count, excluded, M-dwarf share, defaulted-photometry check per committed tier (TIER=medium judges only medium)
	@$(GODOT) --headless --path . --script tools/catalogue_stats.gd -- $(if $(filter command line environment,$(origin TIER)),--tier $(TIER))

star-catalogue-test: ## M1.2c binary tier loader: 2-record LE fixture (stride, endianness), every refusal, stats breaches, committed tiers
	$(GODOT) --headless --path . --script tests/test_star_catalogue.gd

VERIFY_OUT := $(SCRATCH)/verify
catalogue-verify: catalogue-inputs ## M1.2c/M1.2d/M1.7 determinism: rebuild companions.csv, the star-truth table, quick, medium, bright and stars.json into .godot/tmp/verify and cmp with the committed files; then the Python companion oracle
	@rm -rf $(VERIFY_OUT); mkdir -p $(VERIFY_OUT); \
	$(MAKE) --no-print-directory companions COMPANIONS=$(VERIFY_OUT)/companions.csv AILANG=$(AILANG) >/dev/null || exit 1; \
	cmp data/starmap/companions/companions.csv $(VERIFY_OUT)/companions.csv || { echo "catalogue-verify: companions.csv DIFFERS from the committed table"; exit 1; }; \
	echo "companions.csv identical"; \
	$(MAKE) --no-print-directory starmap-truth TRUTH_OUT=$(VERIFY_OUT)/truth AILANG=$(AILANG) >/dev/null || exit 1; \
	for f in positions.csv positions.json; do cmp data/starmap/truth/$$f $(VERIFY_OUT)/truth/$$f || { echo "catalogue-verify: truth/$$f DIFFERS from the committed table"; exit 1; }; done; \
	echo "truth/positions.csv identical"; \
	for t in quick medium bright; do \
	  $(MAKE) --no-print-directory catalogue TIER=$$t CATALOGUE_OUT=$(VERIFY_OUT) AILANG=$(AILANG) >/dev/null || exit 1; \
	  cmp data/starmap/stars_$$t.bin $(VERIFY_OUT)/stars_$$t.bin && cmp data/starmap/stars_$$t.json $(VERIFY_OUT)/stars_$$t.json \
	    || { echo "catalogue-verify: $$t DIFFERS from the committed tier"; exit 1; }; \
	  echo "$$t identical"; done; \
	$(MAKE) --no-print-directory starmap STARMAP_OUT=$(VERIFY_OUT)/stars.json AILANG=$(AILANG) >/dev/null || exit 1; \
	cmp data/starmap/stars.json $(VERIFY_OUT)/stars.json || { echo "catalogue-verify: stars.json DIFFERS from the committed map"; exit 1; }; \
	echo "stars.json identical"; \
	python3 tools/check_companions.py

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

# M1.2c: the catalogue inputs (CNS5 cns5.dat + cns5.csv, GCNS table1c.dat.gz + gcns.csv; M1.2d: HIP2
# hip2.dat.gz + hip_main.dat), pinned in data/sky/SHA256SUMS: the bucket first, then VizieR
# (download_stars.sh) and extract.ail for whatever is absent.
CAT_INPUTS := data/raw/(cns5\.dat|cns5\.csv|table1c\.dat\.gz|gcns\.csv|hip2\.dat\.gz|hip_main\.dat)$$
catalogue-inputs: ## M1.2c: catalogue tier inputs into data/raw (bucket, else VizieR + extract.ail); check their pins
	@sh tools/sky_assets.sh fetch inputs '$(CAT_INPUTS)' || echo "catalogue-inputs: bucket incomplete; falling back to VizieR"
	@test -f data/raw/table1c.dat.gz || bash $(STARMAP_SCRIPTS)/download_stars.sh medium
	@test -f data/raw/cns5.dat || bash $(STARMAP_SCRIPTS)/download_stars.sh quick
	@test -f data/raw/hip2.dat.gz -a -f data/raw/hip_main.dat || bash $(STARMAP_SCRIPTS)/download_stars.sh bright
	@test -f data/raw/cns5.csv || $(AILANG) run --quiet --bytecode --caps IO,FS --package-dir sim --entry main --args-json '{"kind":"cns5","input":"data/raw/cns5.dat","output":"data/raw/cns5.csv"}' sim/tools/extract.ail
	@test -f data/raw/gcns.csv || { gunzip -kf data/raw/table1c.dat.gz && $(AILANG) run --quiet --bytecode --caps IO,FS --package-dir sim --entry main --args-json '{"kind":"gcns","input":"data/raw/table1c.dat","output":"data/raw/gcns.csv"}' sim/tools/extract.ail; }
	@sh tools/sky_assets.sh verify inputs '$(CAT_INPUTS)'

sky-assets:       ## M1.4d/D-18: pinned sky textures: from the public bucket in seconds, else regenerate (inputs -> destar -> sky model, ~15 min)
	@if sh tools/sky_assets.sh fetch textures; then $(MAKE) --no-print-directory sky-verify SKY_VERIFY=textures; \
	else echo "sky-assets: textures not in the bucket; regenerating"; $(MAKE) --no-print-directory sky-regen; fi

sky-regen: sky-inputs destar sky-model   ## M1.4d: full regeneration; outputs must match data/sky/SHA256SUMS
	@$(MAKE) --no-print-directory sky-verify SKY_VERIFY=all

# Starmap tiers too large for git (D-18; starmap-large-tier-and-reach.md L1): the large tier, pinned in
# data/starmap/SHA256SUMS, fetched from gs://stapledons-voyage-assets/starmap/<sha256>.<ext>.
.PHONY: starmap-assets starmap-publish
starmap-assets:   ## L1: the pinned large tier (331,311 GCNS stars, truth positions) from the public bucket in seconds, else rebuilt from the pinned inputs; sha256-checked
	@if sh tools/starmap_assets.sh fetch; then sh tools/starmap_assets.sh verify; \
	else echo "starmap-assets: not in the bucket; rebuilding (make catalogue-inputs + catalogue TIER=large)"; \
	  $(MAKE) --no-print-directory catalogue-inputs catalogue TIER=large AILANG=$(AILANG) && sh tools/starmap_assets.sh verify; fi

starmap-publish:  ## D-18 maintainers (gcloud auth): upload the pinned tiers to gs://stapledons-voyage-assets/starmap/<sha256>.<ext> (never overwrites)
	sh tools/starmap_assets.sh publish

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
include mk/site.mk
include mk/m5.mk

# Isolated seven-tier perspective/lift smoke test. Does not replace production rendering.
run-ship-demo:
	$(GODOT) --path . demos/ship_geometry_demo.tscn
validate-ship-demo:
	$(GODOT) --headless --path . --script tools/validate_ship_demo.gd
ship-demo-test:
	@mkdir -p $(SCRATCH)
	@$(GODOT) --headless --path . --script tests/test_ship_demo.gd > $(SCRATCH)/ship-demo-test.log 2>&1; rc=$$?; tail -3 $(SCRATCH)/ship-demo-test.log; test $$rc = 0 && grep -q '^ship-demo: [0-9]* passed, 0 failures$$' $(SCRATCH)/ship-demo-test.log
ship-demo-capture:
	$(GODOT) --path . --script tools/ship_demo_capture.gd
ship-demo-stage:
	@mkdir -p ship_demo_bundle
	@for f in assets/ship_demo/*.glb assets/ship_demo/*.json; do cp "$$f" "ship_demo_bundle/$$(basename "$$f").bin"; done
ship-commons-stage:
	@mkdir -p ship_commons_bundle
	@for name in manifest.json commons_painted.glb commons_coarse.glb collision.glb walk.glb; do cp "assets/ship_commons/$$name" "ship_commons_bundle/$$name.bin"; done
ship-commons-test:
	@$(GODOT) --headless --path . --script tests/test_ship_commons.gd > $(SCRATCH)/ship-commons-test.log 2>&1; rc=$$?; cat $(SCRATCH)/ship-commons-test.log; test $$rc = 0 && grep -q '^ship-commons: [0-9]* passed, 0 failures$$' $(SCRATCH)/ship-commons-test.log
ship-commons-assets-test:
	@$(GODOT) --headless --path . --script tests/test_ship_commons_assets.gd > $(SCRATCH)/ship-commons-assets.log 2>&1; rc=$$?; cat $(SCRATCH)/ship-commons-assets.log; test $$rc = 0 && grep -q '^ship-commons-assets: OK$$' $(SCRATCH)/ship-commons-assets.log
	@$(GODOT) --headless --path . --script tools/validate_ship_commons.gd -- bad-envelope > $(SCRATCH)/ship-commons-negative.log 2>&1; rc=$$?; test $$rc = 1 && grep -q '^validate-ship-commons: FAIL$$' $(SCRATCH)/ship-commons-negative.log
ship-commons-arcade-test:
	@$(GODOT) --headless --path . --script tests/test_ship_commons_arcade.gd > $(SCRATCH)/ship-commons-arcade.log 2>&1; rc=$$?; cat $(SCRATCH)/ship-commons-arcade.log; test $$rc = 0 && grep -q '^ship-commons-arcade: OK' $(SCRATCH)/ship-commons-arcade.log
.PHONY: ship-demo-live-test ship-demo-live-capture ship-commons-arcade-test
ship-demo-live-test: import
	@$(GODOT) --headless --path . --script tests/test_runtime_fingerprint.gd > $(SCRATCH)/ship-runtime-fingerprint.log 2>&1; rc=$$?; cat $(SCRATCH)/ship-runtime-fingerprint.log; test $$rc = 0 && grep -q '^ok nested module edit invalidates bundled cache$$' $(SCRATCH)/ship-runtime-fingerprint.log
	@$(GODOT_SIM) --headless --path . --script tests/test_live_journey.gd > $(SCRATCH)/ship-live-sim.log 2>&1; rc=$$?; cat $(SCRATCH)/ship-live-sim.log; test $$rc = 0 && grep -q '^ok both clocks match plan$$' $(SCRATCH)/ship-live-sim.log
	@$(GODOT_SIM) --headless --path . --script tests/test_ship_demo_live.gd > $(SCRATCH)/ship-live-demo.log 2>&1; rc=$$?; cat $(SCRATCH)/ship-live-demo.log; test $$rc = 0 && grep -q '^ok arrival stays rest$$' $(SCRATCH)/ship-live-demo.log
ship-demo-live-capture:
	$(GODOT_SIM) --path . --script tools/ship_demo_live_capture.gd
validate-ship-commons:
	$(GODOT) --headless --path . --script tools/validate_ship_commons.gd
ship-commons-capture:
	$(GODOT) --path . --script tools/ship_commons_capture.gd
ship-commons-bench: ship-demo-bench
ship-demo-assets-test:
	$(GODOT) --headless --path . --script tests/test_ship_demo_assets.gd
	$(GODOT) --headless --path . --script tools/validate_ship_demo.gd
	@$(GODOT) --headless --path . --script tools/validate_ship_demo.gd -- tests/fixtures/ship_demo/bad_height.json > $(SCRATCH)/ship-demo-negative.log 2>&1; rc=$$?; test $$rc = 1 && grep -q '^validate-ship-demo: FAIL$$' $(SCRATCH)/ship-demo-negative.log
ship-demo-lift-test:
	@$(GODOT) --headless --path . --script tests/test_ship_demo_lift.gd > $(SCRATCH)/ship-demo-lift.log 2>&1; rc=$$?; cat $(SCRATCH)/ship-demo-lift.log | grep -v '^  ok'; test $$rc = 0 && grep -q '^ship-demo-lift: [0-9]* passed, 0 failures$$' $(SCRATCH)/ship-demo-lift.log
ship-demo-smoke: validate-ship-demo ship-demo-test ship-demo-lift-test
ship-demo-movie:
	$(GODOT) --path . --script tools/ship_demo_movie.gd
	ffmpeg -y -framerate 24 -i renders/ship_demo/movie/%05d.png -c:v libx264 -crf 22 -pix_fmt yuv420p -movflags +faststart renders/ship_demo/bridge_lift_roundtrip.mp4
ship-demo-optics:
	$(GODOT) --path . --script tools/ship_demo_optics.gd
ship-demo-bench:
	$(GODOT) --path . --script tools/ship_demo_bench.gd
ship-demo-benchmark-test:
	@$(GODOT) --headless --path . --script tests/test_ship_demo_benchmark.gd > $(SCRATCH)/ship-demo-benchmark.log 2>&1; rc=$$?; cat $(SCRATCH)/ship-demo-benchmark.log; test $$rc = 0 && grep -q '^ship-demo-benchmark: OK$$' $(SCRATCH)/ship-demo-benchmark.log
ship-demo-geometry-negative-test:
	@for mutation in wrong-tier wrong-tip; do $(GODOT) --headless --path . --script tools/validate_ship_demo.gd -- assets/ship_demo/manifest.json $$mutation > $(SCRATCH)/ship-demo-$$mutation.log 2>&1; rc=$$?; test $$rc = 1 && grep -q '^validate-ship-demo: FAIL$$' $(SCRATCH)/ship-demo-$$mutation.log || exit 1; done
export-macos: ship-demo-stage ship-commons-stage
ship-demo-export-smoke:
	@mkdir -p $(SCRATCH)
	@exe=$$(defaults read "$(CURDIR)/$(APP)/Contents/Info.plist" CFBundleExecutable); "$(APP)/Contents/MacOS/$$exe" --headless -- --ship-demo-smoke > $(SCRATCH)/ship-demo-export.log 2>&1; rc=$$?; cat $(SCRATCH)/ship-demo-export.log; test $$rc = 0 && grep -q '^ship-demo-export-smoke: OK$$' $(SCRATCH)/ship-demo-export.log
ship-demo-launch-test:
	@$(GODOT) --headless --path . --script tests/test_ship_demo_launch.gd > $(SCRATCH)/ship-demo-launch.log 2>&1; rc=$$?; tail -5 $(SCRATCH)/ship-demo-launch.log; test $$rc = 0 && grep -q '^ship-demo-launch: OK$$' $(SCRATCH)/ship-demo-launch.log

# Headless demo regressions are part of the normal CI suite; GPU optics stays explicit.
test: ship-demo-ci
ship-demo-ci: import ship-demo-smoke ship-demo-assets-test ship-demo-geometry-negative-test ship-demo-benchmark-test ship-demo-launch-test ship-demo-input-test ship-demo-journey-test ship-commons-test ship-commons-assets-test validate-ship-commons ship-commons-arcade-test ship-demo-live-test

ship-demo-input-test:
	@$(GODOT) --headless --path . --script tests/test_ship_demo_input.gd > $(SCRATCH)/ship-demo-input.log 2>&1; rc=$$?; cat $(SCRATCH)/ship-demo-input.log; test $$rc = 0 && grep -q '^ship-demo-input: [0-9]* passed, 0 failures$$' $(SCRATCH)/ship-demo-input.log
ship-demo-journey-test:
	@$(GODOT) --headless --path . --script tests/test_ship_demo_journey.gd > $(SCRATCH)/ship-demo-journey.log 2>&1; rc=$$?; cat $(SCRATCH)/ship-demo-journey.log; test $$rc = 0 && grep -q '^ship-demo-journey: [0-9]* passed, 0 failures$$' $(SCRATCH)/ship-demo-journey.log
ship-demo-sky-states:
	AILANG_BIN=$$(command -v $(AILANG)) $(GODOT) --headless --path . --script tools/ship_demo_sky_states.gd
ship-demo-journey-capture:
	$(GODOT) --path . --script tools/ship_demo_journey_capture.gd

# Known-star identification: actual source, GPU and packaged interactions.
.PHONY: ship-star-identification-test ship-star-identification-capture ship-star-identification-bench ship-star-identification-export-smoke
ship-star-identification-test: import
	@$(GODOT_SIM) --headless --path . --script tests/test_ship_star_identification.gd > $(SCRATCH)/ship-star-identification.log 2>&1; rc=$$?; cat $(SCRATCH)/ship-star-identification.log; test $$rc = 0 && grep -q '^ship-star-identification: [0-9]* passed, 0 failures$$' $(SCRATCH)/ship-star-identification.log
ship-star-identification-capture:
	$(GODOT_SIM) --path . --script tools/ship_star_identification_capture.gd
ship-star-identification-bench:
	$(GODOT_SIM) --path . --script tools/ship_star_identification_bench.gd
ship-demo-ci: ship-star-identification-test
ship-star-identification-export-smoke:
	@mkdir -p $(SCRATCH)/identify-export-home
	@exe=$$(defaults read "$(CURDIR)/$(APP)/Contents/Info.plist" CFBundleExecutable); env -i PATH=/usr/bin:/bin HOME="$(CURDIR)/$(SCRATCH)/identify-export-home" "$(APP)/Contents/MacOS/$$exe" -- --ship-identification-smoke > $(SCRATCH)/ship-identification-export.log 2>&1; rc=$$?; cat $(SCRATCH)/ship-identification-export.log; test $$rc = 0 && grep -q '^ship-star-identification-export-smoke: OK$$' $(SCRATCH)/ship-identification-export.log
publish-dev: ship-star-identification-export-smoke
.PHONY: ship-demo-consolidation-test
ship-demo-consolidation-test: import
	@$(GODOT_SIM) --headless --path . --script tests/test_ship_demo_consolidation.gd > $(SCRATCH)/ship-demo-consolidation.log 2>&1; rc=$$?; cat $(SCRATCH)/ship-demo-consolidation.log; test $$rc = 0 && grep -q '^ship-demo-consolidation: [0-9]* passed, 0 failures$$' $(SCRATCH)/ship-demo-consolidation.log
ship-demo-ci: ship-demo-consolidation-test
.PHONY: current-ship-export-smoke
current-ship-export-smoke:
	@mkdir -p $(SCRATCH)/current-ship-export-home
	@exe=$$(defaults read "$(CURDIR)/$(APP)/Contents/Info.plist" CFBundleExecutable); env -i PATH=/usr/bin:/bin HOME="$(CURDIR)/$(SCRATCH)/current-ship-export-home" "$(APP)/Contents/MacOS/$$exe" --quit-after 180 > $(SCRATCH)/current-ship-export.log 2>&1; rc=$$?; cat $(SCRATCH)/current-ship-export.log; test $$rc = 0 && grep -q '^current-ship-startup: OK live-rest captain-eye single-navigation$$' $(SCRATCH)/current-ship-export.log
publish-dev: current-ship-export-smoke

.PHONY: ship-movement-test map-origin-test ship-planets-test ship-lighting-capture ship-lighting-test ship-lighting-bench
ship-movement-test: import
	@$(GODOT_SIM) --headless --path . --script tests/test_ship_movement.gd > $(SCRATCH)/ship-movement.log 2>&1; rc=$$?; cat $(SCRATCH)/ship-movement.log; test $$rc = 0 && grep -q '^ship-movement: [0-9]* passed, 0 failures$$' $(SCRATCH)/ship-movement.log
map-origin-test: import
	@$(GODOT_SIM) --headless --path . --script tests/test_map_origin.gd > $(SCRATCH)/map-origin.log 2>&1; rc=$$?; cat $(SCRATCH)/map-origin.log; test $$rc = 0 && grep -q '^map-origin: [0-9]* passed, 0 failures$$' $(SCRATCH)/map-origin.log
ship-planets-test: import
	@$(GODOT_SIM) --headless --path . --script tests/test_ship_planets.gd > $(SCRATCH)/ship-planets.log 2>&1; rc=$$?; cat $(SCRATCH)/ship-planets.log; test $$rc = 0 && grep -q '^ship-planets: [0-9]* passed, 0 failed$$' $(SCRATCH)/ship-planets.log
ship-lighting-capture:
	@$(GODOT_SIM) --path . --script tools/ship_lighting_capture.gd > $(SCRATCH)/ship-lighting-capture.log 2>&1; rc=$$?; cat $(SCRATCH)/ship-lighting-capture.log; test $$rc = 0 && grep -q '^ship-lighting-capture: OK$$' $(SCRATCH)/ship-lighting-capture.log
ship-lighting-test: ship-lighting-capture
ship-lighting-bench:
	$(GODOT_SIM) --path . --script tools/ship_lighting_bench.gd
ship-demo-ci: ship-movement-test map-origin-test ship-planets-test

# R1-SHIP-STAR-LIGHT: the real star's light on the ship (direction, colour, compressed energy).
.PHONY: ship-star-light-test ship-star-light-capture ship-star-light-bench
ship-star-light-test: import
	@$(GODOT) --headless --path . --script tests/test_ship_star_light.gd > $(SCRATCH)/ship-star-light.log 2>&1; rc=$$?; cat $(SCRATCH)/ship-star-light.log; test $$rc = 0 && grep -q '^ship-star-light: [0-9]* passed, 0 failures$$' $(SCRATCH)/ship-star-light.log
ship-star-light-capture:
	@$(GODOT_SIM) --path . --script tools/ship_star_light_capture.gd > $(SCRATCH)/ship-star-light-capture.log 2>&1; rc=$$?; cat $(SCRATCH)/ship-star-light-capture.log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/ship-star-light-capture.log && grep -q '^ship-star-light-capture: OK$$' $(SCRATCH)/ship-star-light-capture.log
ship-star-light-bench:
	@$(GODOT) --path . --script tools/ship_star_light_bench.gd > $(SCRATCH)/ship-star-light-bench.log 2>&1; rc=$$?; cat $(SCRATCH)/ship-star-light-bench.log; test $$rc = 0 && grep -q '^ship-star-light-bench: OK$$' $(SCRATCH)/ship-star-light-bench.log
ship-demo-ci: ship-star-light-test
.PHONY: trappist1-test
trappist1-test:    ## TRAPPIST-1 planets (trappist1-planets-sprint.md): snapshot pin, sim checks strict VM = interpreter, and the Python orbit/transcription oracle
	@mkdir -p $(SCRATCH)
	@tools/fetch_trappist1.sh --verify
	@$(AILANG) run --quiet --bytecode --strict-bytecode --package-dir sim --entry trappistVm --args-json 0 sim/trappist1_test.ail > $(SCRATCH)/trappist1-vm.txt
	@$(AILANG) run --quiet --package-dir sim --entry trappistVm --args-json 0 sim/trappist1_test.ail > $(SCRATCH)/trappist1-interp.txt
	@cmp -s $(SCRATCH)/trappist1-vm.txt $(SCRATCH)/trappist1-interp.txt || { echo "trappist1-test: strict VM != interpreter"; diff $(SCRATCH)/trappist1-vm.txt $(SCRATCH)/trappist1-interp.txt | head; exit 1; }
	@python3 tools/check_trappist1.py $(SCRATCH)/trappist1-vm.txt
.PHONY: trappist1-capture
trappist1-capture: ## TB6 renders at the TRAPPIST-1 habitable-zone stop -> renders/trappist1/*.png (GPU window; open them)
	@mkdir -p $(SCRATCH)
	@$(GODOT_SIM) --path . --script tools/trappist1_capture.gd > $(SCRATCH)/trappist1-capture.log 2>&1; rc=$$?; cat $(SCRATCH)/trappist1-capture.log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/trappist1-capture.log

.PHONY: catalogue-coverage-test solar-departure-test
catalogue-coverage-test: import
	@$(GODOT_SIM) --headless --path . --script tests/test_catalogue_coverage.gd > $(SCRATCH)/catalogue-coverage.log 2>&1; rc=$$?; cat $(SCRATCH)/catalogue-coverage.log; test $$rc = 0 && grep -q '^catalogue-coverage: [0-9]* passed, 0 failures$$' $(SCRATCH)/catalogue-coverage.log
solar-departure-test: import
	@$(GODOT_SIM) --headless --path . --script tests/test_solar_departure.gd > $(SCRATCH)/solar-departure.log 2>&1; rc=$$?; cat $(SCRATCH)/solar-departure.log; test $$rc = 0 && grep -q '^solar-departure: [0-9]* passed, 0 failures$$' $(SCRATCH)/solar-departure.log
ship-demo-ci: catalogue-coverage-test solar-departure-test

.PHONY: flyby-optics-test planet-rings-test ring-protocol-test planet-meter-test solar-departure-capture solar-departure-export-smoke
flyby-optics-test: import
	@$(GODOT_SIM) --headless --path . --script tests/test_flyby_optics.gd > $(SCRATCH)/flyby-optics.log 2>&1; rc=$$?; cat $(SCRATCH)/flyby-optics.log; test $$rc = 0 && grep -q '^flyby-optics: [0-9]* checks, 0 failures$$' $(SCRATCH)/flyby-optics.log
planet-rings-test: import
	@$(GODOT_SIM) --headless --path . --script tests/test_planet_rings.gd > $(SCRATCH)/planet-rings.log 2>&1; rc=$$?; cat $(SCRATCH)/planet-rings.log; test $$rc = 0 && grep -q '^planet-rings: [0-9]* checks 0 failures$$' $(SCRATCH)/planet-rings.log
ring-protocol-test: import
	@$(GODOT_SIM) --headless --path . --script tests/test_ring_protocol.gd > $(SCRATCH)/ring-protocol.log 2>&1; rc=$$?; cat $(SCRATCH)/ring-protocol.log; test $$rc = 0 && grep -q '^ring-protocol: 0 failures$$' $(SCRATCH)/ring-protocol.log
planet-meter-test: import
	@$(GODOT_SIM) --headless --path . --script tests/test_planet_meter.gd > $(SCRATCH)/planet-meter.log 2>&1; rc=$$?; cat $(SCRATCH)/planet-meter.log; test $$rc = 0 && grep -q '^planet-meter: [0-9]* checks 0 failures$$' $(SCRATCH)/planet-meter.log
ship-demo-ci: flyby-optics-test planet-rings-test ring-protocol-test planet-meter-test
solar-departure-capture:
	@$(GODOT_SIM) --path . --script tools/solar_departure_capture.gd > $(SCRATCH)/solar-departure-capture.log 2>&1; rc=$$?; cat $(SCRATCH)/solar-departure-capture.log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/solar-departure-capture.log && grep -q '^solar-departure-capture: OK$$' $(SCRATCH)/solar-departure-capture.log
.PHONY: solar-departure-bench
solar-departure-bench:
	@$(GODOT_SIM) --path . --script tools/solar_departure_bench.gd > $(SCRATCH)/solar-departure-bench.log 2>&1; rc=$$?; cat $(SCRATCH)/solar-departure-bench.log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/solar-departure-bench.log && grep -q '^solar-departure-bench: OK$$' $(SCRATCH)/solar-departure-bench.log
solar-departure-export-smoke:
	@mkdir -p $(SCRATCH)/solar-export-home
	@exe=$$(defaults read "$(CURDIR)/$(APP)/Contents/Info.plist" CFBundleExecutable); env -i PATH=/usr/bin:/bin HOME="$(CURDIR)/$(SCRATCH)/solar-export-home" "$(APP)/Contents/MacOS/$$exe" -- --solar-departure-smoke > $(SCRATCH)/solar-export.log 2>&1; rc=$$?; cat $(SCRATCH)/solar-export.log; test $$rc = 0 && grep -q '^solar-departure-smoke: OK$$' $(SCRATCH)/solar-export.log
publish-dev: solar-departure-export-smoke

# Large tier in the exported app (eval R1-STARMAP-LARGE round 1): the .app's default sky is the large tier
# (331,311 rows, bundled from data/starmap/ by export-macos -> starmap-assets); prints its peak RSS at the sky scene.
.PHONY: starmap-export-smoke
starmap-export-smoke:
	@mkdir -p $(SCRATCH)/starmap-export-home
	@exe=$$(defaults read "$(CURDIR)/$(APP)/Contents/Info.plist" CFBundleExecutable); env -i PATH=/usr/bin:/bin HOME="$(CURDIR)/$(SCRATCH)/starmap-export-home" /usr/bin/time -l "$(APP)/Contents/MacOS/$$exe" -- --starmap-smoke > $(SCRATCH)/starmap-export.log 2>&1; rc=$$?; \
	  grep -E '^starmap-smoke:' $(SCRATCH)/starmap-export.log; echo "starmap-export-smoke: peak RSS $$(awk '/maximum resident set size/{printf "%.0f MB", $$1/1048576}' $(SCRATCH)/starmap-export.log), app $$(du -sh "$(APP)" | cut -f1)"; \
	  test $$rc = 0 && grep -q '^starmap-smoke: OK$$' $(SCRATCH)/starmap-export.log
export-smoke: starmap-export-smoke

.PHONY: ship-attitude-test
ship-attitude-test: import
	@$(GODOT_SIM) --headless --path . --script tests/test_ship_attitude.gd > $(SCRATCH)/ship-attitude.log 2>&1; rc=$$?; cat $(SCRATCH)/ship-attitude.log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/ship-attitude.log && grep -q '^ship-attitude: 0 failures$$' $(SCRATCH)/ship-attitude.log
ship-demo-ci: ship-attitude-test
.PHONY: benchmark-upload-test
benchmark-upload-test: import
	@$(GODOT_SIM) --headless --path . --script tests/test_benchmark_upload.gd > $(SCRATCH)/benchmark-upload.log 2>&1; rc=$$?; cat $(SCRATCH)/benchmark-upload.log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/benchmark-upload.log && grep -q '^benchmark-upload: 0 failures$$' $(SCRATCH)/benchmark-upload.log
ship-demo-ci: benchmark-upload-test
.PHONY: shadow-contacts-test
shadow-contacts-test: import
	@$(GODOT_SIM) --headless --path . --script tests/test_shadow_contacts.gd > $(SCRATCH)/shadow-contacts.log 2>&1; rc=$$?; cat $(SCRATCH)/shadow-contacts.log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/shadow-contacts.log && grep -q '^shadow-contacts: 0 failures$$' $(SCRATCH)/shadow-contacts.log
ship-demo-ci: shadow-contacts-test
.PHONY: tour-attitude-test
tour-attitude-test: import
	@$(GODOT_SIM) --headless --path . --script tests/test_tour_attitude.gd > $(SCRATCH)/tour-attitude.log 2>&1; rc=$$?; cat $(SCRATCH)/tour-attitude.log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/tour-attitude.log && grep -q '^tour-attitude: 0 failures$$' $(SCRATCH)/tour-attitude.log
ship-demo-ci: tour-attitude-test
.PHONY: bridge-floor-test
bridge-floor-test: import
	@$(GODOT_SIM) --headless --path . --script tests/test_bridge_floor.gd > $(SCRATCH)/bridge-floor.log 2>&1; rc=$$?; cat $(SCRATCH)/bridge-floor.log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/bridge-floor.log && grep -q '^bridge-floor: [0-9]* passed, 0 failures$$' $(SCRATCH)/bridge-floor.log
ship-demo-ci: bridge-floor-test

include mk/planet-presentation.mk

.PHONY: sim-bootstrap-test
sim-bootstrap-test: import
	@$(GODOT_SIM) --headless --path . --script tests/test_sim_bootstrap.gd > $(SCRATCH)/sim-bootstrap.log 2>&1; rc=$$?; cat $(SCRATCH)/sim-bootstrap.log; test $$rc = 0 && grep -q '^sim-bootstrap: [0-9]* checks 0 failures$$' $(SCRATCH)/sim-bootstrap.log
ship-demo-ci: sim-bootstrap-test

.PHONY: tour-pacing-test
tour-pacing-test: import
	@$(GODOT) --headless --path . --script tests/test_tour_pacing.gd > $(SCRATCH)/tour-pacing.log 2>&1; rc=$$?; cat $(SCRATCH)/tour-pacing.log; test $$rc = 0 && grep -q "^tour-pacing: 0 failures$$" $(SCRATCH)/tour-pacing.log
	@$(GODOT) --headless --path . --script tests/test_destination_pin.gd > $(SCRATCH)/destination-pin.log 2>&1; rc=$$?; cat $(SCRATCH)/destination-pin.log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/destination-pin.log && grep -q "^destination-pin: 0 failures$$" $(SCRATCH)/destination-pin.log
	@$(GODOT) --headless --path . --script tests/test_cruise_interlude.gd > $(SCRATCH)/cruise-interlude.log 2>&1; rc=$$?; cat $(SCRATCH)/cruise-interlude.log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/cruise-interlude.log && grep -q "^cruise-interlude: 0 failures$$" $(SCRATCH)/cruise-interlude.log
ship-demo-ci: tour-pacing-test

# ---- M4.7: the Archive codex's lore (design m4-first-journey.md "M4.7")
D ?= ../stapledons-design
LORE_DATA ?= data/lore
LORE ?=
CHECK ?=
LORE_ENV = D=$(D) LORE_DATA=$(LORE_DATA) AILANG=$(AILANG) SCRATCH=$(SCRATCH) LORE=$(LORE)

.PHONY: lore-import lore-import-check lore-values lore-check lore-test lore-import-test

lore-import:       ## M4.7 AC17: copy the design repo's lore (git objects at D's HEAD) into data/lore + manifest; CHECK=1 verifies the manifest (fail-closed, offline) and, where D has its sha, the design repo
	@mkdir -p $(SCRATCH)
	@if [ "$(CHECK)" = 1 ]; then $(LORE_ENV) sh tools/lore_import.sh check; else $(LORE_ENV) sh tools/lore_import.sh import; fi

lore-import-check: ## M4.7 AC17 (in make test): lore-import CHECK=1
	@$(MAKE) --no-print-directory lore-import CHECK=1

lore-values:       ## M4.7 AC8/AC15: the check-value registry data/lore/check_values.json; fails unless package values equal their HB rows at printed s.f. and eps <= HB-61
	@$(AILANG) run --quiet --bytecode --caps IO,FS --package-dir sim --entry values --args-json '{"dir":"$(LORE_DATA)","out":"$(LORE_DATA)/check_values.json"}' sim/tools/lore_values.ail

lore-check: lore-values  ## M4.7 AC15: every entry's unlock is a known hint, every checks id resolves, every number binds (LORE=file|dir checks that instead, e.g. LORE=tests/fixtures/lore/drifted.md must fail)
	@$(LORE_ENV) sh tools/lore_check.sh

lore-test:         ## M4.7 lore binding, registry and checker: strict VM = interpreter, then the positive controls (drifted.md, unknown hint, unresolved id) on the real files
	@mkdir -p $(SCRATCH)
	@for m in lore_test:loreVm lore_check_test:loreCheckVm lore_values_test:loreValuesVm; do f=$${m%%:*}; e=$${m##*:}; \
	  env -u AI_LIVE $(AILANG) run --quiet --bytecode --strict-bytecode --package-dir sim --entry $$e --args-json 0 sim/tools/$$f.ail > $(SCRATCH)/$$f-vm.txt 2>&1; \
	  env -u AI_LIVE $(AILANG) run --quiet --package-dir sim --entry $$e --args-json 0 sim/tools/$$f.ail > $(SCRATCH)/$$f-interp.txt 2>&1; \
	  cmp $(SCRATCH)/$$f-vm.txt $(SCRATCH)/$$f-interp.txt && grep -q -- '-ok$$' $(SCRATCH)/$$f-vm.txt || { echo "lore-test: $$f FAILED"; cat $(SCRATCH)/$$f-vm.txt $(SCRATCH)/$$f-interp.txt; exit 1; }; \
	  echo "lore-test: $$f: $$(cat $(SCRATCH)/$$f-vm.txt) (strict VM = interpreter)"; done
	@$(AILANG) run --quiet --bytecode --caps FS --package-dir sim --entry loreValuesReal --args-json '"$(LORE_DATA)"' sim/tools/lore_values_test.ail | grep -q -- '-ok$$' || { echo "lore-test: the real HB rows disagree with the package"; exit 1; }
	@echo "lore-test: the ten AC8/AC15 HB rows (16 17 35 40 41 45 49 53 54 61) agree with the package at printed s.f."
	@$(MAKE) --no-print-directory lore-values
	@AILANG=$(AILANG) sh tests/test_lore_check.sh
	@AILANG=$(AILANG) SCRATCH=$(SCRATCH) sh tests/test_lore_import.sh

.PHONY: codex-test
news-lint:         ## M4.4 template lint: numerals only in {slots}, five tiers of four, 280 characters filled, fixed labels and reason phrases digit-free; the stray-digit fixture must fail
	@mkdir -p $(SCRATCH)
	@$(GODOT) --headless --path . --script tools/news_lint.gd > $(SCRATCH)/news-lint.log 2>&1; rc=$$?; grep '^news-lint' $(SCRATCH)/news-lint.log; \
	  test $$rc = 0 && grep -q '^news-lint: ok$$' $(SCRATCH)/news-lint.log || { echo "news-lint: FAILED on data/news (log $(SCRATCH)/news-lint.log)"; exit 1; }
	@$(GODOT) --headless --path . --script tools/news_lint.gd -- res://tests/fixtures/news/stray_digit.json > $(SCRATCH)/news-lint-bad.log 2>&1; rc=$$?; \
	  test $$rc = 1 && grep -q 'a numeral outside a slot' $(SCRATCH)/news-lint-bad.log || { echo "news-lint: the stray-digit fixture did NOT fail the lint (rc=$$rc)"; cat $(SCRATCH)/news-lint-bad.log; exit 1; }
	@echo "news-lint: the stray-digit fixture fails as it must"

news-test:         ## M4.4 news panel (template / ai / fallback renderings), reason table, return trip, legacy screen + Begin again, over the real sim (headless)
	@mkdir -p $(SCRATCH)
	@$(GODOT_SIM) --headless --path . --script tests/test_news.gd > $(SCRATCH)/news-test.log 2>&1; rc=$$?; grep -v '^  ok' $(SCRATCH)/news-test.log | grep -v '^ERROR: .*leaked\|^   at: \|^Godot Engine\|^$$'; \
	  test $$rc = 0 && ! grep -q 'SCRIPT ERROR' $(SCRATCH)/news-test.log && grep -q '^news: [0-9]* passed, 0 failures$$' $(SCRATCH)/news-test.log || { echo "news-test: FAILED (a parse error exits 0, so the summary line is required; log $(SCRATCH)/news-test.log)"; exit 1; }

codex-test:        ## M4.7 the Archive codex: lore loader + manifest refusal, Markdown subset, locked/greyed rows, toasts, LoreBinding, the real sim's minimum-path unlocks vs tests/expected_unlocks.json (headless)
	@mkdir -p $(SCRATCH)
	@$(GODOT_SIM) --headless --path . --script tests/test_codex.gd > $(SCRATCH)/codex-test.log 2>&1; rc=$$?; grep -v '^  ok' $(SCRATCH)/codex-test.log | grep -v '^ERROR: .*leaked\|^   at: \|^Godot Engine\|^$$'; \
	  test $$rc = 0 && ! grep -q 'SCRIPT ERROR' $(SCRATCH)/codex-test.log && grep -q '^codex: [0-9]* passed, 0 failures$$' $(SCRATCH)/codex-test.log || { echo "codex-test: FAILED (a parse error exits 0, so the summary line is required; log $(SCRATCH)/codex-test.log)"; exit 1; }
