# AI service foundation (sprint R1-AI-FOUNDATION, design ai-service-foundation).
# Included from the Makefile by its last line; every AI target lives here so the
# sprint changes one Makefile line. Uses AILANG and SCRATCH from the Makefile.

.PHONY: ai-test strict-ai markers-mutants deps-ai ai-pkg-test ai-stub ai-stub-record ai-mutants ai-adapter ai-adapter-record ai-godot ai-bridge-mutants

test: ai-test

ai-test: deps-ai strict-ai ai-pkg-test ai-stub ai-adapter ai-godot   ## AI foundation checks that run without a GPU window or a key

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
	@# aiWireVm (AI.4, AI.5): the service's pure modules (key, route, wire, prompt, spend, reply, voice, stub handler); last line ai-wire-ok
	@$(AILANG) run --quiet --bytecode --strict-bytecode --package-dir ai --entry aiWireVm --args-json 0 ai/vm_test.ail > $(SCRATCH)/ai-wire-vm.txt
	@$(AILANG) run --quiet --package-dir ai --entry aiWireVm --args-json 0 ai/vm_test.ail > $(SCRATCH)/ai-wire-interp.txt
	@cmp $(SCRATCH)/ai-wire-vm.txt $(SCRATCH)/ai-wire-interp.txt && test "$$(tail -1 $(SCRATCH)/ai-wire-vm.txt)" = "ai-wire-ok" && \
	  echo "strict aiWireVm: $$(tail -1 $(SCRATCH)/ai-wire-vm.txt), $$(wc -l < $(SCRATCH)/ai-wire-vm.txt | tr -d ' ') lines, digest $$(shasum -a 256 $(SCRATCH)/ai-wire-vm.txt | cut -c1-16) (strict VM = interpreter)"

# ---------------------------------------------------------------- AI.4: the ai/ service package
# The service is its own package with its own lock (it imports nothing from sim/, ailang#1498).
# Runs first in ai-test: on a clean machine `ailang lock` also fills the package cache (gemini_live).
deps-ai:           ## ai/ailang.lock is current (cd ai && ailang lock changes nothing but generated_at)
	cd ai && $(AILANG) lock
	@git diff --exit-code -I '"generated_at"' ai/ailang.lock; rc=$$?; git checkout -q ai/ailang.lock 2>/dev/null; exit $$rc

ai-pkg-test:       ## the service package type-checks and its tests pass (key, route, wire, stub, spend, prompt, reply, voice, live); no sim import, no key text
	$(AILANG) check --package ai
	cd ai && $(AILANG) test --package .
	@! grep -nE '^import .*(\.\./sim|stapledons/sim)' ai/*.ail || { echo "ai/ must not import sim/ (ailang#1498)"; exit 1; }
	@! grep -rnE --exclude-dir=.ailang 'AIza|sk-or-' ai data/ai tests/ai || { echo "key-shaped text (AIza, sk-or-) in the AI service files"; exit 1; }
	@echo "ai-pkg-test: ai/ imports nothing from sim/; no AIza or sk-or- text in ai/, data/ai/, tests/ai/"

# AC8: the stub service with --caps IO,FS only (it cannot read env, reach the network or call a
# model) over tests/ai/requests.ndjson, once per key set: both keys, Gemini only, none, both in
# text-only mode, and both at the player's minimum ceiling (budget; entry `session`). Each run's
# stdout must equal its golden (the hello's cache_dir is written as $AI_S, so the goldens do not
# depend on SCRATCH); VM and interpreter must print the same bytes and write the same cache; the
# cache (blobs, index.ndjson, usage.ndjson) must equal tests/ai/cache.SHA256SUMS with no extra
# file. Cache invariants: no *.tmp left; one index line and one usage line (provider, route,
# model) per ok result. requests.ndjson holds two blank lines mid-stream: they are skipped.
# AC6 part: every text blob's name is its body's sha256 by `shasum -a 256` (an independent
# reference), and every text result's sha256 names one of those blobs.
AI_S := $(SCRATCH)/ai
AI_SETS := both gemini none textonly budget
AI_RUN = $(AILANG) run --quiet --package-dir ai --caps IO,FS
ai_comma := ,
ai_keys = $(if $(filter both textonly budget,$(1)),"gemini"$(ai_comma)"openrouter",$(if $(filter gemini,$(1)),"gemini"))
ai_cfg = {"provider":"$(2)","keys_present":[$(call ai_keys,$(1))],"text_only":$(if $(filter textonly,$(1)),true,false),"cache_dir":"$(AI_S)/cache/$(1)","routing":"data/ai/routing.json","fixtures":"ai/fixtures"$(if $(filter budget,$(1)),$(ai_comma)"ceiling_usd":0.05)}
# Runs every key set on the VM (stdout, cache moved to vm/) then on the interpreter (cache/).
define ai_stub_runs
	@rm -rf $(AI_S) && mkdir -p $(AI_S)/vm
	@$(foreach s,$(AI_SETS),printf '%s' '$(call ai_cfg,$(s),stub)' > $(AI_S)/$(s).json;)
	@printf '%s' '$(call ai_cfg,both,gemini)' > $(AI_S)/live.json
	@for s in $(AI_SETS); do \
	  e=main; [ $$s = budget ] && e=session; \
	  $(AI_RUN) --entry $$e --bytecode --args-file $(AI_S)/$$s.json ai/service.ail < tests/ai/requests.ndjson > $(AI_S)/$$s.vm.out || exit 1; \
	  mv $(AI_S)/cache/$$s $(AI_S)/vm/$$s; \
	  $(AI_RUN) --entry $$e --args-file $(AI_S)/$$s.json ai/service.ail < tests/ai/requests.ndjson > $(AI_S)/$$s.interp.out || exit 1; \
	  sed 's|"cache_dir":"$(AI_S)/|"cache_dir":"$$AI_S/|' $(AI_S)/$$s.vm.out > $(AI_S)/$$s.norm.out; \
	done
endef
ai-stub:           ## AC8 + AC6 part: stub service over five key sets, goldens, cache sums and invariants, VM == interpreter
	$(ai_stub_runs)
	@for s in $(AI_SETS); do \
	  cmp $(AI_S)/$$s.vm.out $(AI_S)/$$s.interp.out && diff -r $(AI_S)/vm/$$s $(AI_S)/cache/$$s || { echo "ai-stub $$s: VM and interpreter differ"; exit 1; }; \
	  cmp $(AI_S)/$$s.norm.out tests/ai/results.$$s.golden.ndjson || { echo "ai-stub $$s: stdout differs from tests/ai/results.$$s.golden.ndjson"; exit 1; }; \
	  echo "ai-stub $$s: $$(wc -l < $(AI_S)/$$s.vm.out | tr -d ' ') lines == golden; routes $$(grep -o '"route":"[a-z]*"' $(AI_S)/$$s.vm.out | sort | uniq -c | tr -s ' ' | tr '\n' ' ')(VM = interpreter)"; \
	  ok=$$(grep -c '"status":"ok"' $(AI_S)/$$s.vm.out); d=$(AI_S)/cache/$$s; \
	  test -z "$$(find $$d -name '*.tmp')" || { echo "ai-stub $$s: a .tmp file is left in the cache"; exit 1; }; \
	  test "$$(cat $$d/index.ndjson 2>/dev/null | wc -l | tr -d ' ')" = "$$ok" || { echo "ai-stub $$s: index lines != $$ok ok results"; exit 1; }; \
	  test "$$(cat $$d/usage.ndjson 2>/dev/null | grep -c '"provider":"stub","route":"[a-z]*","model":"[^"]*"')" = "$$ok" || { echo "ai-stub $$s: usage lines != $$ok ok results"; exit 1; }; \
	done
	@echo "ai-stub cache: no .tmp left; one index line and one usage line (provider, route, model) per ok result in every set"
	@b=$(AI_S)/budget.vm.out; grep -q '"code":"budget","meta":{"provider":"stub","route":"gemini"}' $$b || { echo "ai-stub budget: no budget refusal"; exit 1; }; \
	  echo "ai-stub budget: $$(grep -c '"code":"budget"' $$b) requests refused budget at the 0.05 USD ceiling; last usage $$(tail -1 $(AI_S)/cache/budget/usage.ndjson | grep -o '"totals":{[^}]*}')"
	@cd $(AI_S)/cache && shasum -a 256 -c --quiet "$(CURDIR)/tests/ai/cache.SHA256SUMS" && \
	  test "$$(find . -type f | wc -l | tr -d ' ')" = "$$(wc -l < "$(CURDIR)/tests/ai/cache.SHA256SUMS" | tr -d ' ')" && \
	  echo "ai-stub cache: $$(find . -type f | wc -l | tr -d ' ') files == tests/ai/cache.SHA256SUMS, no extra file ($$(find . -name '*.ogg' | wc -l | tr -d ' ') voice clips)"
	@n=0; for f in $$(find $(AI_S)/cache -name '*.txt'); do \
	  h=$$(shasum -a 256 "$$f" | cut -c1-64); test "$$h" = "$$(basename $$f .txt)" || { echo "AC6: $$f hashes to $$h"; exit 1; }; n=$$((n+1)); done; \
	for h in $$(cat $(AI_S)/*.vm.out | grep -o '"kind":"text","sha256":"[0-9a-f]*"' | cut -d'"' -f8 | sort -u); do \
	  test -n "$$(find $(AI_S)/cache -name "$$h.txt")" || { echo "AC6: text result $$h has no blob"; exit 1; }; done; \
	echo "ai-stub AC6: $$n text blobs: the service's sha256 == shasum -a 256 for every one, incl. non-ASCII"
	@out=$$(printf '' | $(AI_RUN) --entry main --args-file $(AI_S)/both.json ai/service.ail); test -z "$$out" || { echo "service printed before any input: $$out"; exit 1; }
	@out=$$(printf '\n\n' | $(AI_RUN) --entry main --args-file $(AI_S)/live.json ai/service.ail); test -z "$$out" || { echo "bad config printed with no input: $$out"; exit 1; }
	@out=$$(printf '{"v":1,"type":"hello","want":{"major":1}}\n' | $(AI_RUN) --entry main --args-file $(AI_S)/live.json ai/service.ail); \
	  test "$$out" = '{"v":1,"type":"fatal","code":"config","detail":"config: provider gemini needs the live entry (--entry live)"}' || { echo "live provider not refused by the stub entry: $$out"; exit 1; }; \
	  echo "ai-stub: silent until the first input (also on a bad config); the stub entry refuses --provider gemini"

ai-stub-record:    ## regenerate the ai-stub goldens and cache sums (a reviewed diff; never in make test)
	$(ai_stub_runs)
	@for s in $(AI_SETS); do cp $(AI_S)/$$s.norm.out tests/ai/results.$$s.golden.ndjson; done
	@cd $(AI_S)/vm && find . -type f | sort | xargs shasum -a 256 > "$(CURDIR)/tests/ai/cache.SHA256SUMS"
	@echo "recorded: $$(ls tests/ai/results.*.golden.ndjson | tr '\n' ' ') and tests/ai/cache.SHA256SUMS ($$(wc -l < tests/ai/cache.SHA256SUMS | tr -d ' ') files)"

# AC9 (AI.5): the adapters without a network or a key. The lane runs under --ai-stub with
# --caps IO,FS,AI (no Net, no Env) and no key in its environment: the Gemini text adapter turns
# {"kind":"Wait"} into bad_output after three attempts, the image adapter turns the 1x1 PNG into a
# valid descriptor, the OpenRouter and TTS parsers decode the committed fixtures. Its stdout must
# equal tests/ai/adapter.golden.txt, and the prompts it writes tests/ai/prompts/*.golden.txt.
# Then the live entry's refusals, each with --caps IO,FS,Env only (no Net, no AI: it could not
# spend even if a refusal were missing) and the keys cleared from the env: no GOOGLE_API_KEY, no
# OPENROUTER_API_KEY, neither, and a fixture key without AI_LIVE=1.
AI_A := $(SCRATCH)/ai-adapter
AI_PURPOSES := line news archive probe
AI_NOKEYS = env -u GOOGLE_API_KEY -u OPENROUTER_API_KEY -u AI_LIVE GOOGLE_APPLICATION_CREDENTIALS=/nonexistent
define ai_adapter_run
	@rm -rf $(AI_A) && mkdir -p $(AI_A)
	@printf '%s' '{"routing":"data/ai/routing.json","fixtures":"ai/fixtures","requests":"tests/ai/requests.ndjson","out":"$(AI_A)"}' > $(AI_A)/lane.json
	@$(AI_NOKEYS) $(AILANG) run --quiet --package-dir ai --caps IO,FS,AI --ai-stub --entry lane --args-file $(AI_A)/lane.json ai/adapter_lane.ail > $(AI_A)/lane.out
endef
ai_live = printf '{"v":1,"type":"hello","want":{"major":1}}\n' | $(AI_NOKEYS) $(1) $(AILANG) run --quiet --package-dir ai --caps IO,FS,Env --entry live --args-file $(AI_A)/$(2).json ai/service.ail
ai_fatal = {"v":1,"type":"fatal","code":"config","detail":"config: $(1)"}
ai-adapter:        ## AC9: adapters under --ai-stub (no Net), parsers on fixtures, prompt goldens, live refusals without keys
	$(ai_adapter_run)
	@cat $(AI_A)/lane.out; test "$$(tail -1 $(AI_A)/lane.out)" = "adapter-ok" && cmp $(AI_A)/lane.out tests/ai/adapter.golden.txt || { echo "ai-adapter: lane output differs from tests/ai/adapter.golden.txt"; exit 1; }
	@for p in $(AI_PURPOSES); do cmp $(AI_A)/prompts/$$p.txt tests/ai/prompts/$$p.golden.txt || { echo "ai-adapter: prompt $$p differs from its golden"; exit 1; }; done; \
	  echo "ai-adapter: prompts $(AI_PURPOSES) == tests/ai/prompts/*.golden.txt"
	@$(foreach p,gemini openrouter live,printf '%s' '{"provider":"$(p)","keys_present":[],"text_only":false,"cache_dir":"$(AI_A)/live","routing":"data/ai/routing.json","fixtures":"ai/fixtures","ceiling_usd":0.5}' > $(AI_A)/$(p).json;)
	@out=$$($(call ai_live,,gemini)); test "$$out" = '$(call ai_fatal,provider gemini refused: GOOGLE_API_KEY is empty)' || { echo "live gemini without GOOGLE_API_KEY: $$out"; exit 1; }
	@out=$$($(call ai_live,,openrouter)); test "$$out" = '$(call ai_fatal,provider openrouter refused: OPENROUTER_API_KEY is empty)' || { echo "live openrouter without OPENROUTER_API_KEY: $$out"; exit 1; }
	@out=$$($(call ai_live,,live)); test "$$out" = '$(call ai_fatal,live needs GOOGLE_API_KEY or OPENROUTER_API_KEY)' || { echo "live without keys: $$out"; exit 1; }
	@out=$$($(call ai_live,GOOGLE_API_KEY=fixture-not-a-key,gemini)); test "$$out" = '$(call ai_fatal,live provider refused: AI_LIVE=1 is not set (attended sessions only))' || { echo "live without AI_LIVE: $$out"; exit 1; }
	@test ! -e $(AI_A)/live || { echo "a refused live start created its cache"; exit 1; }
	@echo "ai-adapter: live refused before any call without GOOGLE_API_KEY, without OPENROUTER_API_KEY, without both, and without AI_LIVE=1 (caps IO,FS,Env; keys cleared)"

ai-adapter-record: ## regenerate tests/ai/adapter.golden.txt and the prompt goldens (a reviewed diff; never in make test)
	$(ai_adapter_run)
	@cp $(AI_A)/lane.out tests/ai/adapter.golden.txt; mkdir -p tests/ai/prompts
	@for p in $(AI_PURPOSES); do cp $(AI_A)/prompts/$$p.txt tests/ai/prompts/$$p.golden.txt; done
	@echo "recorded: tests/ai/adapter.golden.txt and tests/ai/prompts/{$(AI_PURPOSES)}.golden.txt"

# AI.4 and AI.5 mutation check (as markers-mutants): each mutant of the service's pure modules, applied to a
# scratch copy of ai/, must fail its named test.
ai-mutants:        ## AI.4, AI.5: route, key, stub, cache order, acts order, budget, wire, screen, prompt, live guard; each fails a named test
	@set -e; A=$$(command -v $(AILANG)); case "$$A" in /*) ;; *) A="$$PWD/$$A";; esac; \
	for m in \
	  'route.ail@else if !serves(h.provider, kind) then@else if false then@AI.4 routing config errors refused at start@route_test.ail' \
	  'route.ail@if member(h.provider, keys) && serves(h.provider, kind) then Via(h)@if serves(h.provider, kind) then Via(h)@AI.4 text routes to OpenRouter, else Gemini, else no_key@route_test.ail' \
	  'route.ail@if textOnly && isMedia(kind) then@if false then@AI.4 portrait, avatar and voice route to Gemini or no_key, never OpenRouter; text_only@route_test.ail' \
	  'key.ail@n >= 1 && n <= 32 &&@n >= 1 && n <= 33 &&@AI.4 cache key validation refuses each bad field@key_test.ail' \
	  'provider.ail@let n = if r.constraints.noNumerals then spelled(r.req) else r.req;@let n = r.req;@AI.4 stub text: words for numbers, first allowed emotion, trimmed, fixture cases@stub_test.ail' \
	  'provider.ail@pure func resultMeta(j: Job, prov: string, n: int, ms: int) -> Meta = { provider: prov, route: j.hop.provider,@pure func resultMeta(j: Job, prov: string, n: int, ms: int) -> Meta = { provider: prov, route: "stub",@AI.4 stub answers every route and stamps meta.route@stub_test.ail' \
	  'cache.ail@(if present then [] else [Write(tmp), Rename(tmp, path)])@(if present then [] else [Write(path)])@AI.5 blob writes: temp file, rename, then the index line@stub_test.ail' \
	  'provider.ail@{ acts: [blob, usage, result], ledger: after }@{ acts: [result, blob, usage], ledger: after }@AI.5 acts: blob and usage before the result@stub_test.ail' \
	  'provider.ail@if r.kind == "text" then 3 * cost(@if r.kind == "text" then cost(@AI.5 budget refused once the total would pass the ceiling@stub_test.ail' \
	  'spend.ail@total(l) + estimate <= l.ceiling@total(l) <= l.ceiling@AI.5 ledger per provider plus total; refused once the total would pass the ceiling@spend_test.ail' \
	  'wire.ail@"no_key", "text_only", "budget"@"no_key", "budget"@AI.4 ai/1 codecs round-trip every fixture both ways@wire_test.ail' \
	  'reply.ail@else if c.noNumerals && anyDigit(body) then Some("numeral")@else if false then Some("numeral")@AI.5 screen: grammar, palette, brackets, digits, display length@reply_test.ail' \
	  'prompt.ail@"Describe and feel; never judge the player'"'"'s choices or say whether a decision was right or wrong."@"Describe and feel."@AI.5 prompts carry the no-verdict guardrail, the palette, no_numerals and the cap@prompt_test.ail' \
	  'service.ail@else if !aiLive then Some(@else if false then Some(@AI.5 live refused without its key, without any key, or without AI_LIVE=1@live_test.ail'; do \
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

# ---------------------------------------------------------------- AI.6: AiBridge in Godot
# AC11 (bridge half): the real stub (--caps IO,FS) for the happy path, then the fake service
# (ai/tools/fake_service.ail, --caps IO) hanging, crashing, printing garbage or half lines, answering
# late or with the wrong major. Timeouts and backoffs are shortened in the test; defaults asserted.
ai-godot: import   ## AC11 bridge half: lazy launch, non-blocking relay, priority, timeouts, backoff, service_down
	$(GODOT_SIM) --headless --path . --script tests/test_ai_bridge.gd -- --faults

ai-bridge-mutants: import   ## AI.6: AiBridge mutants (priority, timeout kill, backoff, window, assembly, ...); each fails a named check
	AILANG_BIN="$$(command -v $(AILANG))" sh tests/ai_bridge_mutants.sh "$(GODOT)" "$(SCRATCH)/bridge-mutants"
