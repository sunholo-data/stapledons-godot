# AI service foundation (sprint R1-AI-FOUNDATION, design ai-service-foundation).
# Included from the Makefile by its last line; every AI target lives here so the
# sprint changes one Makefile line. Uses AILANG and SCRATCH from the Makefile.

.PHONY: ai-test strict-ai markers-mutants deps-ai ai-pkg-test ai-stub ai-stub-record ai-mutants

test: ai-test

ai-test: strict-ai deps-ai ai-pkg-test ai-stub   ## AI foundation checks that run without a GPU window or a key

# AC7 (part): the pure marker grammar runs entirely on the bytecode VM and prints
# byte for byte what the interpreter prints; its last line is markers-ok. The
# emotion list it prints must equal the keys of data/ai/emotion_styles.json, in order.
strict-ai:         ## AI pure modules on the strict VM == interpreter (markersVm, aiVm)
	@mkdir -p $(SCRATCH)
	@$(AILANG) run --quiet --bytecode --strict-bytecode --package-dir sim --entry markersVm --args-json 0 sim/markers_test.ail > $(SCRATCH)/markers-vm.txt
	@$(AILANG) run --quiet --package-dir sim --entry markersVm --args-json 0 sim/markers_test.ail > $(SCRATCH)/markers-interp.txt
	@cmp $(SCRATCH)/markers-vm.txt $(SCRATCH)/markers-interp.txt && test "$$(tail -1 $(SCRATCH)/markers-vm.txt)" = "markers-ok" && \
	  echo "strict markersVm: $$(tail -1 $(SCRATCH)/markers-vm.txt), $$(wc -l < $(SCRATCH)/markers-vm.txt | tr -d ' ') lines, digest $$(shasum -a 256 $(SCRATCH)/markers-vm.txt | cut -c1-16) (strict VM = interpreter)"
	@want=$$(sed -n 's/^emotions //p' $(SCRATCH)/markers-vm.txt); \
	got=$$(python3 -c "import json; d=json.load(open('data/ai/emotion_styles.json')); assert all(isinstance(v, str) and v.strip() for v in d.values()); print(','.join(d))"); \
	echo "emotion_styles.json keys: $$got"; [ -n "$$want" ] && [ "$$got" = "$$want" ]
	@# aiVm (AI.2): open, cancel, expiry, ids and seeds over a scripted 2.1 session; last line ai-ok
	@$(AILANG) run --quiet --bytecode --strict-bytecode --package-dir sim --entry aiVm --args-json 0 sim/ai_test.ail > $(SCRATCH)/ai-vm.txt
	@$(AILANG) run --quiet --package-dir sim --entry aiVm --args-json 0 sim/ai_test.ail > $(SCRATCH)/ai-interp.txt
	@cmp $(SCRATCH)/ai-vm.txt $(SCRATCH)/ai-interp.txt && test "$$(tail -1 $(SCRATCH)/ai-vm.txt)" = "ai-ok" && \
	  echo "strict aiVm: $$(tail -1 $(SCRATCH)/ai-vm.txt), $$(wc -l < $(SCRATCH)/ai-vm.txt | tr -d ' ') lines, digest $$(shasum -a 256 $(SCRATCH)/ai-vm.txt | cut -c1-16) (strict VM = interpreter)"
	@# aiWireVm (AI.4): the service's pure modules (key, route, wire, stub handler); last line ai-wire-ok
	@$(AILANG) run --quiet --bytecode --strict-bytecode --package-dir ai --entry aiWireVm --args-json 0 ai/vm_test.ail > $(SCRATCH)/ai-wire-vm.txt
	@$(AILANG) run --quiet --package-dir ai --entry aiWireVm --args-json 0 ai/vm_test.ail > $(SCRATCH)/ai-wire-interp.txt
	@cmp $(SCRATCH)/ai-wire-vm.txt $(SCRATCH)/ai-wire-interp.txt && test "$$(tail -1 $(SCRATCH)/ai-wire-vm.txt)" = "ai-wire-ok" && \
	  echo "strict aiWireVm: $$(tail -1 $(SCRATCH)/ai-wire-vm.txt), $$(wc -l < $(SCRATCH)/ai-wire-vm.txt | tr -d ' ') lines, digest $$(shasum -a 256 $(SCRATCH)/ai-wire-vm.txt | cut -c1-16) (strict VM = interpreter)"

# ---------------------------------------------------------------- AI.4: the ai/ service package
# The service is its own package with its own lock (it imports nothing from sim/, ailang#1498).
deps-ai:           ## ai/ailang.lock is current (cd ai && ailang lock changes nothing but generated_at)
	cd ai && $(AILANG) lock
	@git diff --exit-code -I '"generated_at"' ai/ailang.lock; rc=$$?; git checkout -q ai/ailang.lock 2>/dev/null; exit $$rc

ai-pkg-test:       ## the service package type-checks and its tests pass (key, route, wire, stub); no sim import, no key text
	$(AILANG) check --package ai
	cd ai && $(AILANG) test --package .
	@! grep -nE '^import .*(\.\./sim|stapledons/sim)' ai/*.ail || { echo "ai/ must not import sim/ (ailang#1498)"; exit 1; }
	@! grep -rnE --exclude-dir=.ailang 'AIza|sk-or-' ai data/ai tests/ai || { echo "key-shaped text (AIza, sk-or-) in the AI service files"; exit 1; }
	@echo "ai-pkg-test: ai/ imports nothing from sim/; no AIza or sk-or- text in ai/, data/ai/, tests/ai/"

# AC8: the stub service with --caps IO,FS only (it cannot read env, reach the network or call a
# model) over tests/ai/requests.ndjson, once per key set: both keys, Gemini only, none, and both in
# text-only mode. Each run's stdout must equal its golden; VM and interpreter must print the same
# bytes and write the same cache; the cache must equal tests/ai/cache.SHA256SUMS with no extra file.
# AC6 part: every text blob's name is its body's sha256 by `shasum -a 256` (an independent
# reference), and every text result's sha256 names one of those blobs.
AI_S := $(SCRATCH)/ai
AI_SETS := both gemini none textonly
AI_RUN = $(AILANG) run --quiet --package-dir ai --caps IO,FS --entry main
ai_comma := ,
ai_keys = $(if $(filter both textonly,$(1)),"gemini"$(ai_comma)"openrouter",$(if $(filter gemini,$(1)),"gemini"))
ai_cfg = {"provider":"$(2)","keys_present":[$(call ai_keys,$(1))],"text_only":$(if $(filter textonly,$(1)),true,false),"cache_dir":"$(AI_S)/cache/$(1)","routing":"data/ai/routing.json","fixtures":"ai/fixtures"}
# Runs every key set on the VM (stdout, cache moved to vm/) then on the interpreter (cache/).
define ai_stub_runs
	@rm -rf $(AI_S) && mkdir -p $(AI_S)/vm
	@$(foreach s,$(AI_SETS),printf '%s' '$(call ai_cfg,$(s),stub)' > $(AI_S)/$(s).json;)
	@printf '%s' '$(call ai_cfg,both,gemini)' > $(AI_S)/live.json
	@for s in $(AI_SETS); do \
	  $(AI_RUN) --bytecode --args-file $(AI_S)/$$s.json ai/service.ail < tests/ai/requests.ndjson > $(AI_S)/$$s.vm.out || exit 1; \
	  mv $(AI_S)/cache/$$s $(AI_S)/vm/$$s; \
	  $(AI_RUN) --args-file $(AI_S)/$$s.json ai/service.ail < tests/ai/requests.ndjson > $(AI_S)/$$s.interp.out || exit 1; \
	done
endef
ai-stub:           ## AC8 + AC6 part: stub service over three key sets (+ text-only), goldens, cache sums, VM == interpreter
	$(ai_stub_runs)
	@for s in $(AI_SETS); do \
	  cmp $(AI_S)/$$s.vm.out $(AI_S)/$$s.interp.out && diff -r $(AI_S)/vm/$$s $(AI_S)/cache/$$s || { echo "ai-stub $$s: VM and interpreter differ"; exit 1; }; \
	  cmp $(AI_S)/$$s.vm.out tests/ai/results.$$s.golden.ndjson || { echo "ai-stub $$s: stdout differs from tests/ai/results.$$s.golden.ndjson"; exit 1; }; \
	  echo "ai-stub $$s: $$(wc -l < $(AI_S)/$$s.vm.out | tr -d ' ') lines == golden; routes $$(grep -o '"route":"[a-z]*"' $(AI_S)/$$s.vm.out | sort | uniq -c | tr -s ' ' | tr '\n' ' ')(VM = interpreter)"; \
	done
	@cd $(AI_S)/cache && shasum -a 256 -c --quiet "$(CURDIR)/tests/ai/cache.SHA256SUMS" && \
	  test "$$(find . -type f | wc -l | tr -d ' ')" = "$$(wc -l < "$(CURDIR)/tests/ai/cache.SHA256SUMS" | tr -d ' ')" && \
	  echo "ai-stub cache: $$(find . -type f | wc -l | tr -d ' ') files == tests/ai/cache.SHA256SUMS, no extra file"
	@n=0; for f in $$(find $(AI_S)/cache -name '*.txt'); do \
	  h=$$(shasum -a 256 "$$f" | cut -c1-64); test "$$h" = "$$(basename $$f .txt)" || { echo "AC6: $$f hashes to $$h"; exit 1; }; n=$$((n+1)); done; \
	for h in $$(cat $(AI_S)/*.vm.out | grep -o '"kind":"text","sha256":"[0-9a-f]*"' | cut -d'"' -f8 | sort -u); do \
	  test -n "$$(find $(AI_S)/cache -name "$$h.txt")" || { echo "AC6: text result $$h has no blob"; exit 1; }; done; \
	echo "ai-stub AC6: $$n text blobs: the service's sha256 == shasum -a 256 for every one, incl. non-ASCII"
	@out=$$(printf '' | $(AI_RUN) --args-file $(AI_S)/both.json ai/service.ail); test -z "$$out" || { echo "service printed before any input: $$out"; exit 1; }
	@out=$$(printf '{"v":1,"type":"hello","want":{"major":1}}\n' | $(AI_RUN) --args-file $(AI_S)/live.json ai/service.ail); \
	  test "$$out" = '{"v":1,"type":"fatal","code":"config","detail":"config: live provider gemini is not wired until AI.5"}' || { echo "live provider not refused: $$out"; exit 1; }; \
	  echo "ai-stub: silent until the first input; --provider gemini refused at start (AI.5 wires it)"

ai-stub-record:    ## regenerate the ai-stub goldens and cache sums (a reviewed diff; never in make test)
	$(ai_stub_runs)
	@for s in $(AI_SETS); do cp $(AI_S)/$$s.vm.out tests/ai/results.$$s.golden.ndjson; done
	@cd $(AI_S)/vm && find . -type f | sort | xargs shasum -a 256 > "$(CURDIR)/tests/ai/cache.SHA256SUMS"
	@echo "recorded: $$(ls tests/ai/results.*.golden.ndjson | tr '\n' ' ') and tests/ai/cache.SHA256SUMS ($$(wc -l < tests/ai/cache.SHA256SUMS | tr -d ' ') files)"

# AI.4 mutation check (as markers-mutants): each mutant of the service's pure modules, applied to a
# scratch copy of ai/, must fail its named test.
ai-mutants:        ## AI.4: route/key/stub mutants; each fails a named test
	@set -e; A=$$(command -v $(AILANG)); case "$$A" in /*) ;; *) A="$$PWD/$$A";; esac; \
	for m in \
	  'route.ail@else if !serves(h.provider, kind) then@else if false then@AI.4 routing config errors refused at start@route_test.ail' \
	  'route.ail@if member(h.provider, keys) && serves(h.provider, kind) then Via(h)@if serves(h.provider, kind) then Via(h)@AI.4 text routes to OpenRouter, else Gemini, else no_key@route_test.ail' \
	  'route.ail@if textOnly && isMedia(kind) then@if false then@AI.4 portrait, avatar and voice route to Gemini or no_key, never OpenRouter; text_only@route_test.ail' \
	  'key.ail@n >= 1 && n <= 32 &&@n >= 1 && n <= 33 &&@AI.4 cache key validation refuses each bad field@key_test.ail' \
	  'provider.ail@let n = if r.constraints.noNumerals then spelled(r.req) else r.req;@let n = r.req;@AI.4 stub text: words for numbers, first allowed emotion, trimmed, fixture cases@stub_test.ail' \
	  'provider.ail@meta(h: Hop, input: string) -> Meta = { provider: "stub", route: h.provider,@meta(h: Hop, input: string) -> Meta = { provider: "stub", route: "stub",@AI.4 stub answers every route and stamps meta.route@stub_test.ail'; do \
	  file=$${m%%@*}; rest=$${m#*@}; from=$${rest%%@*}; rest=$${rest#*@}; to=$${rest%%@*}; rest=$${rest#*@}; name=$${rest%%@*}; tfile=$${rest#*@}; \
	  rm -rf $(MUTANT_DIR) && mkdir -p $(MUTANT_DIR) && cp -R ai $(MUTANT_DIR)/ai; \
	  FROM="$$from" TO="$$to" perl -0pi -e 's/\Q$$ENV{FROM}\E/$$ENV{TO}/ or die "anchor not found: $$ENV{FROM}\n"' $(MUTANT_DIR)/ai/$$file; \
	  if (cd $(MUTANT_DIR)/ai && "$$A" test --no-color $$tfile > ../out.txt 2>&1); then \
	    echo "mutant SURVIVED: $$to"; exit 1; fi; \
	  grep -F "✗ $$name" $(MUTANT_DIR)/out.txt > /dev/null || { echo "mutant '$$to' did not fail '$$name'"; cat $(MUTANT_DIR)/out.txt; exit 1; }; \
	  echo "mutant killed: $$file '$$to' fails '$$name'"; \
	done

# AI.1 mutation check: each mutant of sim/markers.ail, applied to a scratch copy
# of sim/, must fail its named test. A mutant whose anchor no longer matches fails
# the target too, so the check cannot rot silently.
MUTANT_DIR := $(SCRATCH)/mutants
markers-mutants:   ## AI.1: drop the [ ] refusal, drop the merge, allow 17 segments; each fails a named test
	@set -e; A=$$(command -v $(AILANG)); case "$$A" in /*) ;; *) A="$$PWD/$$A";; esac; \
	for m in \
	  'if contains(line, "[") || contains(line, "]") then@if false then@AI.1 [ and ] refused anywhere' \
	  'if p.emotion == s.emotion then@if false then@AI.1 adjacent equal markers merge' \
	  'maxSegments() -> int = 16@maxSegments() -> int = 17@AI.1 at most 16 segments, counted after merging'; do \
	  from=$${m%%@*}; rest=$${m#*@}; to=$${rest%%@*}; name=$${rest#*@}; \
	  rm -rf $(MUTANT_DIR) && mkdir -p $(MUTANT_DIR) && cp -R sim $(MUTANT_DIR)/sim; \
	  FROM="$$from" TO="$$to" perl -0pi -e 's/\Q$$ENV{FROM}\E/$$ENV{TO}/ or die "anchor not found: $$ENV{FROM}\n"' $(MUTANT_DIR)/sim/markers.ail; \
	  if (cd $(MUTANT_DIR)/sim && "$$A" test --no-color markers_test.ail > ../out.txt 2>&1); then \
	    echo "mutant SURVIVED: $$to"; exit 1; fi; \
	  grep -F "✗ $$name" $(MUTANT_DIR)/out.txt > /dev/null || { echo "mutant '$$to' did not fail '$$name'"; cat $(MUTANT_DIR)/out.txt; exit 1; }; \
	  echo "mutant killed: '$$to' fails test '$$name' ($$(grep -c '✗ AI.1' $(MUTANT_DIR)/out.txt) AI.1 tests fail)"; \
	done
