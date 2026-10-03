# AI service foundation (sprint R1-AI-FOUNDATION, design ai-service-foundation).
# Included from the Makefile by its last line; every AI target lives here so the
# sprint changes one Makefile line. Uses AILANG and SCRATCH from the Makefile.

.PHONY: ai-loopback ai-relay replay-noai ai-session-record ai-test strict-ai markers-mutants deps-ai ai-pkg-test ai-stub ai-stub-record ai-mutants ai-adapter ai-adapter-record replay-compat record-mutants ai-godot ai-bridge-mutants

test: ai-test

ai-test: deps-ai strict-ai ai-pkg-test ai-stub ai-adapter ai-loopback replay-compat ai-godot ai-relay replay-noai   ## AI foundation checks that run without a GPU window or a key

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
	@# aiVm (AI.2, AI.3): open, cancel, expiry, ids, seeds and record validation over a scripted 2.1 session; last line ai-ok
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

# AI.7 (carried from the AI.5 evaluation): the std/net halves of the adapters, OpenRouter
# chat completions and Gemini TTS, against tests/fixtures/ai_loopback.py on 127.0.0.1 with fake
# keys in the env (cleared of anything real) and --caps IO,FS,Net,Env --net-allow-localhost
# --net-allow-http: no AI capability, no provider host allowed. The harness checks the URL paths,
# the Bearer and x-goog-api-key headers, the bodies, one retry after the "Wait" fixture, and
# that neither key reached the lane's stdout, stderr or any cache file (blobs, index, usage).
AI_L := $(SCRATCH)/ai-loopback
AI_FAKE_G := loopback-fake-gemini-7f3a
AI_FAKE_O := loopback-fake-openrouter-c41d
ai-loopback:       ## AI.5 leftover: OpenRouter + TTS POST halves against a loopback fixture server, fake keys never logged
	@rm -rf $(AI_L) && mkdir -p $(AI_L)
	@python3 tests/fixtures/ai_loopback.py serve $(AI_L) & \
	for i in $$(seq 100); do [ -f $(AI_L)/port ] && break; sleep 0.1; done; \
	printf '{"routing":"data/ai/routing.json","fixtures":"ai/fixtures","requests":"tests/ai/requests.ndjson","out":"$(AI_L)","base":"http://127.0.0.1:%s"}' "$$(cat $(AI_L)/port)" > $(AI_L)/lane.json; \
	env -u AI_LIVE GOOGLE_APPLICATION_CREDENTIALS=/nonexistent GOOGLE_API_KEY=$(AI_FAKE_G) OPENROUTER_API_KEY=$(AI_FAKE_O) \
	  $(AILANG) run --quiet --package-dir ai --caps IO,FS,Net,Env --net-allow-localhost --net-allow-http --entry loopback --args-file $(AI_L)/lane.json ai/loopback_lane.ail > $(AI_L)/lane.out 2> $(AI_L)/lane.err; rc=$$?; \
	touch $(AI_L)/stop; wait; cat $(AI_L)/lane.out | cut -c1-160; test $$rc = 0 && test "$$(tail -1 $(AI_L)/lane.out)" = "loopback-done"
	@python3 tests/fixtures/ai_loopback.py check $(AI_L) $(AI_FAKE_G) $(AI_FAKE_O)

ai-adapter-record: ## regenerate tests/ai/adapter.golden.txt and the prompt goldens (a reviewed diff; never in make test)
	$(ai_adapter_run)
	@cp $(AI_A)/lane.out tests/ai/adapter.golden.txt; mkdir -p tests/ai/prompts
	@for p in $(AI_PURPOSES); do cp $(AI_A)/prompts/$$p.txt tests/ai/prompts/$$p.golden.txt; done
	@echo "recorded: tests/ai/adapter.golden.txt and tests/ai/prompts/{$(AI_PURPOSES)}.golden.txt"

# AI.4 and AI.5 mutation check (as markers-mutants): each mutant of the service's pure modules, applied to a
# scratch copy of ai/, must fail its named test.
ai-mutants:        ## AI.4, AI.5, AI.8, AI.9: route, key, stub, cache order, acts order, budget, wire, screen, prompt, live guard, core verify; each fails a named test
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
	  'service.ail@else if !aiLive then Some(@else if false then Some(@AI.5 live refused without its key, without any key, or without AI_LIVE=1@live_test.ail' \
	  'provider.ail@{ acts: used ++ [Say(errOut(j.r, code, prov, j.hop.provider))], ledger: after }@{ acts: used ++ [Say(errOut(j.r, code, prov, j.hop.provider))], ledger: l }@AI.5 a failed live call is charged and logged before its error@stub_test.ail' \
	  'spend.ail@usd * 1000000000.0 + 0.5@usd * 1000000000.0@AI.5 prices and ceilings round to the nearest nano-dollar@spend_test.ail' \
	  'spend.ail@x * scale + 0.5@x * scale@AI.5 prices and ceilings round to the nearest nano-dollar@spend_test.ail' \
	  'reply.ail@ || contains(s, "7")@@AI.5 screen: grammar, palette, brackets, digits, display length@reply_test.ail' \
	  'reply.ail@Ok(j) => match get(j, "error") { Some(_) => None, None => Some({ tokensIn: inputTokensOf(body)@Ok(j) => match get(j, "error") { Some(_) => Some({ tokensIn: 0, tokensOut: 0 }), None => Some({ tokensIn: inputTokensOf(body)@AI.9 an unparsable but billed reply reports its tokens; error bodies are not billed@reply_test.ail' \
	  'tools/core_import.ail@cf("width", intToStr(a.w)), cf("height", intToStr(a.h))@cf("width", intToStr(a.h)), cf("height", intToStr(a.w))@AI.8 an index line from a fixture PNG: key, sha256, bytes, size, prompt hash, pinned source@tools/core_import_test.ail' \
	  'tools/core_import.ail@w: s.w, h: s.h,@w: s.h, h: s.w,@AI.8 an index line from a fixture PNG: key, sha256, bytes, size, prompt hash, pinned source@tools/core_import_test.ail' \
	  'tools/core_import.ail@else if e.n <= 0 then@else if e.n < 0 then@AI.8 verify: each bad index line is refused with its line and reason@tools/core_import_test.ail' \
	  'tools/core_import.ail@(coreNat(j, "width") <= 0 || coreNat(j, "height") <= 0)@(coreNat(j, "width") <= 0)@AI.8 verify: each bad index line is refused with its line and reason@tools/core_import_test.ail' \
	  'tools/core_import.ail@length(s) > 50 &&@length(s) > 49 &&@AI.8 verify: each bad index line is refused with its line and reason@tools/core_import_test.ail' \
	  'tools/core_import.ail@isLowerHex(substring(s, 8, 48), 40) &&@true &&@AI.8 verify: each bad index line is refused with its line and reason@tools/core_import_test.ail' \
	  'tools/core_import.ail@Some(x) => Err(x),@Some(_) => Ok(e),@AI.8 verify: each bad index line is refused with its line and reason@tools/core_import_test.ail' \
	  'tools/core_import.ail@if member(canonical(e.key), seen) then@if false then@AI.8 verify: each bad index line is refused with its line and reason@tools/core_import_test.ail' \
	  'tools/core_import.ail@else if coreStr(j, "origin") != "core" then@else if false then@AI.8 verify: each bad index line is refused with its line and reason@tools/core_import_test.ail' \
	  'tools/core_import.ail@Ok(es) => if sums == concat(@Ok(es) => if true || sums == concat(@AI.8 verify: SHA256SUMS must list exactly the index blobs and the index@tools/core_import_test.ail' \
	  'tools/core_import.ail@cf("input_sha256", cq(a.inputSha))@cf("input_sha256", cq(a.sha))@AI.8 an index line from a fixture PNG: key, sha256, bytes, size, prompt hash, pinned source@tools/core_import_test.ail'; do \
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
markers-mutants:   ## AI.1/AI.3: drop the [ ] refusal, the merge, the 16-segment cap, the invisible-only check; each fails a named test
	@set -e; A=$$(command -v $(AILANG)); case "$$A" in /*) ;; *) A="$$PWD/$$A";; esac; \
	for m in \
	  'if contains(line, "[") || contains(line, "]") then@if false then@AI.1 [ and ] refused anywhere' \
	  'if p.emotion == s.emotion then@if false then@AI.1 adjacent equal markers merge' \
	  'maxSegments() -> int = 16@maxSegments() -> int = 17@AI.1 at most 16 segments, counted after merging' \
	  'if tt == "" || invisibleOnly(tt) then@if tt == "" then@AI.3 a segment of invisible characters only is empty_segment'; do \
	  from=$${m%%@*}; rest=$${m#*@}; to=$${rest%%@*}; name=$${rest#*@}; \
	  rm -rf $(MUTANT_DIR) && mkdir -p $(MUTANT_DIR) && cp -R sim $(MUTANT_DIR)/sim; \
	  FROM="$$from" TO="$$to" perl -0pi -e 's/\Q$$ENV{FROM}\E/$$ENV{TO}/ or die "anchor not found: $$ENV{FROM}\n"' $(MUTANT_DIR)/sim/markers.ail; \
	  if (cd $(MUTANT_DIR)/sim && "$$A" test --no-color markers_test.ail > ../out.txt 2>&1); then \
	    echo "mutant SURVIVED: $$to"; exit 1; fi; \
	  grep -F "✗ $$name" $(MUTANT_DIR)/out.txt > /dev/null || { echo "mutant '$$to' did not fail '$$name'"; cat $(MUTANT_DIR)/out.txt; exit 1; }; \
	  echo "mutant killed: '$$to' fails test '$$name' ($$(grep -c '✗ AI.' $(MUTANT_DIR)/out.txt) AI tests fail)"; \
	done

# AC13 (AI.3): protocol 2.1 changed only the first lines of every 2.0 golden.
# Every log whose input is unchanged since the freeze (tests/replays/compat-2.0/)
# runs on the VM and the interpreter; with exactly the new fields stripped (hello
# minor, the params keys ai_max_open/ai_ttl_ticks, the full state's ai section)
# its bytes must equal the frozen 2.0 golden. Harness: tools/replay.py --compat.
replay-compat:     ## AC13: 2.1 output minus the new fields == the frozen 2.0 goldens (TICKS=2000 for the PR-sized session)
	AILANG="$(AILANG)" python3 tools/replay.py --compat $(if $(TICKS),--ticks $(TICKS))

# AI.3 mutation check (not in make test): each mutant of sim/ai.ail, applied to a
# scratch copy of sim/, must fail its named test in sim/ai_test.ail.
AI3_REFUSALS := AC3 record refusals fire on their fixtures and close the request (ai_unknown_req closes nothing)
record-mutants:    ## AI.3: voice variant compared, no numeral check, 65 lines, no dedupe, offsets not strict; each fails a named test
	@set -e; A=$$(command -v $(AILANG)); case "$$A" in /*) ;; *) A="$$PWD/$$A";; esac; \
	for m in \
	  'if want.kind == "voice" then getString(k, "variant") != None else@if false then true else@$(AI3_REFUSALS)' \
	  'c.noNumerals && hasDigit(r.body)@false@$(AI3_REFUSALS)' \
	  'contains(s, "5") || @@$(AI3_REFUSALS)' \
	  ' || contains(s, "9")@@$(AI3_REFUSALS)' \
	  'segments: x.segments})}, _ => st }@segments: x.segments})}, _ => {st | lines: keepLine(st.lines, {req: o.req, entityId: o.key.entityId, segments: []})} }@ai.lines keeps the last 64 accepted lines; ai_stale past them' \
	  'maxLines() -> int = 64@maxLines() -> int = 65@ai.lines keeps the last 64 accepted lines; ai_stale past them' \
	  'Some(es) => dedupe(es, [])@Some(es) => es@ai_open refusal order holds with a full queue; emotions deduplicated' \
	  'v > prev && v < dur@v >= prev && v < dur@$(AI3_REFUSALS)'; do \
	  from=$${m%%@*}; rest=$${m#*@}; to=$${rest%%@*}; name=$${rest#*@}; \
	  rm -rf $(MUTANT_DIR) && mkdir -p $(MUTANT_DIR) && cp -R sim $(MUTANT_DIR)/sim; \
	  FROM="$$from" TO="$$to" perl -0pi -e 's/\Q$$ENV{FROM}\E/$$ENV{TO}/ or die "anchor not found: $$ENV{FROM}\n"' $(MUTANT_DIR)/sim/ai.ail; \
	  if (cd $(MUTANT_DIR)/sim && "$$A" test --no-color ai_test.ail > ../out.txt 2>&1); then \
	    echo "mutant SURVIVED: $$to"; exit 1; fi; \
	  grep -F "✗ $$name" $(MUTANT_DIR)/out.txt > /dev/null || { echo "mutant '$$to' did not fail '$$name'"; tail -20 $(MUTANT_DIR)/out.txt; exit 1; }; \
	  echo "mutant killed: '$$to' fails test '$$name'"; \
	done

# ---------------------------------------------------------------- AI.6: AiBridge in Godot
# AC11 (bridge half): the real stub (--caps IO,FS) for the happy path, then the fake service
# (ai/tools/fake_service.ail, --caps IO) hanging, crashing, printing garbage or half lines, answering
# late or with the wrong major. Timeouts and backoffs are shortened in the test; defaults asserted.
ai-godot: import   ## AC11 bridge half: lazy launch, non-blocking relay, priority, timeouts, backoff, service_down
	$(GODOT_SIM) --headless --path . --script tests/test_ai_bridge.gd -- --faults

ai-bridge-mutants: import   ## AI.6: AiBridge mutants (priority, timeout kill, backoff, window, assembly, ...); each fails a named check
	AILANG_BIN="$$(command -v $(AILANG))" sh tests/ai_bridge_mutants.sh "$(GODOT)" "$(SCRATCH)/bridge-mutants"

# ---------------------------------------------------------------- AI.7: AiRelay, AiCache, end to end
# AC10, AC14, AC18 and the routes check: the sim, AiRelay and the stub service (--caps IO,FS) record
# tests/replays/ai_stub_session.ndjson again through the tee and must reproduce it byte for byte; a
# cache hit records with no launch; the live launch (key files, no AI_LIVE) refuses at hello and no
# fixture key text reaches argv (ps), stdout, stderr, the session log or the library.
ai-relay: import   ## AC10/AC14/AC18: relay + cache end to end on the stub, key hygiene, routes
	$(GODOT_SIM) --headless --path . --script tests/test_ai_relay.gd -- --news --key-hygiene --routes

# AC12 part: the visual replay path. Godot replays ai_stub_session through SimBridge with the relay in
# replay mode; every state line must equal this arch's golden and no AI process may start.
replay-noai: import   ## AC12 part: ai_stub_session through Godot, relay in replay mode, AiBridge.launch_count == 0
	$(GODOT_SIM) --headless --path . --script tests/test_ai_relay.gd -- --replay-noai

ai-session-record: import   ## re-record tests/replays/ai_stub_session.ndjson through Godot (then make replay-record LOG=ai_stub_session; a reviewed diff)
	$(GODOT_SIM) --headless --path . --script tools/record_ai_session.gd -- "$(CURDIR)/tests/replays/ai_stub_session.ndjson"

# ---------------------------------------------------------------- AI.8: the core layer
# Design (a4). The accepted Medic set (4 portraits, 1 avatar) is a pinned, content-addressed layer:
# data/ai/core/{index.ndjson,SHA256SUMS} in git, the blobs in the public bucket as
# gs://stapledons-voyage-assets/ai/<sha256>.<ext> (immutable, like sky/, D-18), locally under
# data/raw/ai_core/blobs/ab/<sha256>.<ext> (gitignored). ai_core, the new_game value, is the
# sha256 of index.ndjson ($(AI_CORE)).
AI_CORE_DIR := data/ai/core
AI_CORE_BLOBS := data/raw/ai_core
AI_CORE_BASE ?= https://storage.googleapis.com/stapledons-voyage-assets/ai
AI_CORE_GS ?= gs://stapledons-voyage-assets/ai
AI_CORE_SRC := assets/stapledon/characters/medic_v2
BLENDER ?= $(HOME)/dev/blender
AI_CORE_COMMIT ?= $(shell sed -n '1s/.*"source":"blender@\([0-9a-f]*\):.*/\1/p' $(AI_CORE_DIR)/index.ndjson)
AI_CORE = $(shell shasum -a 256 $(AI_CORE_DIR)/index.ndjson | cut -c1-64)
AI_CORE_RUN = $(AILANG) run --quiet --package-dir ai --caps IO,FS
AI_C := $(SCRATCH)/ai-core
ai_core_import = $(AI_CORE_RUN) --entry main --args-json '{"src":"$(1)","commit":"$(2)","dir":"$(3)","out":"$(4)","blobs":"$(5)"}' ai/tools/core_import.ail
ai_core_verify = $(AI_CORE_RUN) --entry verify --args-json '{"dir":"$(1)","blobs":"$(2)"}' ai/tools/core_import.ail
# Pinned blob lines of a SHA256SUMS: "<sha256> <layer path>".
ai_core_blobs = grep '  blobs/' $(1)

.PHONY: ai-core-import ai-core-verify ai-core-assets ai-core-bundle ai-core-publish
ai-test: ai-core-verify

ai-core-import:    ## AI.8 maintainers: re-import the Medic set from $(BLENDER) at AI_CORE_COMMIT (git archive, not the working tree) into data/ai/core + data/raw/ai_core
	@rm -rf $(AI_C)/src && mkdir -p $(AI_C)/src
	git -C "$(BLENDER)" archive "$(AI_CORE_COMMIT)" "$(AI_CORE_SRC)" | tar -x -C $(AI_C)/src
	$(call ai_core_import,$(AI_C)/src/$(AI_CORE_SRC),$(AI_CORE_COMMIT),$(AI_CORE_SRC),$(AI_CORE_DIR),$(AI_CORE_BLOBS))

# AC17. Offline: the import over tests/ai/core_fixture equals its expected index and sums, its blobs
# verify, and a corrupted blob is refused; the committed index and SHA256SUMS are consistent with
# valid keys (and blob hashes when data/raw/ai_core has the blobs: AILANG, then shasum as an
# independent reference); with the Blender checkout at hand, a fresh import from the pinned commit
# equals the committed files. AI_CORE_FETCH=1 fetches the blobs from the bucket first.
ai-core-verify:    ## AC17: core index <-> SHA256SUMS, keys, fixture import, blob hashes if present, pinned Blender re-import if available
	@$(if $(filter 1,$(AI_CORE_FETCH)),$(MAKE) --no-print-directory ai-core-assets,true)
	@rm -rf $(AI_C)/fx && $(call ai_core_import,tests/ai/core_fixture,0000000000000000000000000000000000000000,tests/ai/core_fixture,$(AI_C)/fx,$(AI_C)/fx/layer) > /dev/null
	@cmp $(AI_C)/fx/index.ndjson tests/ai/core_fixture/expected/index.ndjson && cmp $(AI_C)/fx/SHA256SUMS tests/ai/core_fixture/expected/SHA256SUMS
	@$(call ai_core_verify,$(AI_C)/fx,$(AI_C)/fx/layer) | grep -q '^core-verify: 5 blobs in' || { echo "ai-core-verify: fixture blobs did not verify"; exit 1; }
	@f=$$(find $(AI_C)/fx/layer -name '*.png' | head -1); printf 'x' >> "$$f"; \
	  if $(call ai_core_verify,$(AI_C)/fx,$(AI_C)/fx/layer) > $(AI_C)/fx/bad.out; then echo "ai-core-verify: a corrupted fixture blob passed"; exit 1; fi; \
	  grep -q '^core: blob [0-9a-f]* does not match its index line' $(AI_C)/fx/bad.out || { cat $(AI_C)/fx/bad.out; exit 1; }
	@echo "ai-core-verify: fixture import == tests/ai/core_fixture/expected (index, SHA256SUMS); its 5 blobs verify; a corrupted blob is refused"
	@$(call ai_core_verify,$(AI_CORE_DIR),$(AI_CORE_BLOBS)) > $(AI_C)/verify.out; rc=$$?; cat $(AI_C)/verify.out; test $$rc = 0
	@test "$$(tail -1 $(AI_C)/verify.out)" = "ai_core $(AI_CORE)" && grep -qx '$(AI_CORE)  index.ndjson' $(AI_CORE_DIR)/SHA256SUMS || { echo "ai-core-verify: ai_core differs from shasum -a 256 of index.ndjson"; exit 1; }
	@if [ -d $(AI_CORE_BLOBS)/blobs ]; then (cd $(AI_CORE_BLOBS) && $(call ai_core_blobs,"$(CURDIR)/$(AI_CORE_DIR)/SHA256SUMS") | shasum -a 256 -c --quiet) && echo "ai-core-verify: shasum -a 256 agrees on every blob in $(AI_CORE_BLOBS)"; fi
	@if git -C "$(BLENDER)" cat-file -e "$(AI_CORE_COMMIT)^{commit}" 2>/dev/null; then \
	  rm -rf $(AI_C)/pin && mkdir -p $(AI_C)/pin/src && git -C "$(BLENDER)" archive "$(AI_CORE_COMMIT)" "$(AI_CORE_SRC)" | tar -x -C $(AI_C)/pin/src && \
	  $(call ai_core_import,$(AI_C)/pin/src/$(AI_CORE_SRC),$(AI_CORE_COMMIT),$(AI_CORE_SRC),$(AI_C)/pin,) > /dev/null && \
	  cmp $(AI_C)/pin/index.ndjson $(AI_CORE_DIR)/index.ndjson && cmp $(AI_C)/pin/SHA256SUMS $(AI_CORE_DIR)/SHA256SUMS && \
	  echo "ai-core-verify: a fresh import from blender@$(AI_CORE_COMMIT) == data/ai/core"; \
	else echo "ai-core-verify: no Blender checkout with $(AI_CORE_COMMIT) at $(BLENDER); pinned re-import skipped"; fi

ai-core-assets:    ## AI.8: fetch the pinned core blobs from the public bucket (anonymous HTTPS), sha-checked, into data/raw/ai_core
	@mkdir -p $(AI_C) && $(call ai_core_blobs,$(AI_CORE_DIR)/SHA256SUMS) > $(AI_C)/fetch.lst
	@missing=0; while read -r sum path; do \
	  dst=$(AI_CORE_BLOBS)/$$path; \
	  if [ -f "$$dst" ] && [ "$$(shasum -a 256 "$$dst" | cut -c1-64)" = "$$sum" ]; then echo "  have     $$path"; continue; fi; \
	  mkdir -p "$$(dirname "$$dst")"; url="$(AI_CORE_BASE)/$$sum.$${path##*.}"; \
	  if ! curl -fsSL --max-time 300 -o "$$dst.part" "$$url"; then rm -f "$$dst.part"; echo "  absent   $$url"; missing=$$((missing + 1)); continue; fi; \
	  if [ "$$(shasum -a 256 "$$dst.part" | cut -c1-64)" != "$$sum" ]; then rm -f "$$dst.part"; echo "  CORRUPT  $$url"; missing=$$((missing + 1)); continue; fi; \
	  mv "$$dst.part" "$$dst"; echo "  fetched  $$path  <- $$url"; \
	done < $(AI_C)/fetch.lst; \
	test $$missing -eq 0 || { echo "ai-core-assets: $$missing pinned blob(s) not fetched"; exit 1; }

# Stages res://ai_core/ (gitignored) for the export: index.ndjson plus the pinned blobs, verified.
# Each PNG gets a "keep" .import (AI.9), so the export ships its bytes, not a texture.
# AI.9 makes export-macos depend on it. No blobs -> a warning and no core layer (the game falls
# back to text and the library).
ai-core-bundle:    ## AI.8: stage the verified core layer into ai_core/ for the export
	@rm -rf ai_core
	@if [ -d $(AI_CORE_BLOBS)/blobs ]; then \
	  $(call ai_core_verify,$(AI_CORE_DIR),$(AI_CORE_BLOBS)) > /dev/null || exit 1; mkdir -p ai_core && cp $(AI_CORE_DIR)/index.ndjson ai_core/ && \
	  $(call ai_core_blobs,$(AI_CORE_DIR)/SHA256SUMS) | while read -r sum path; do mkdir -p "ai_core/$$(dirname $$path)" && cp "$(AI_CORE_BLOBS)/$$path" "ai_core/$$path"; done && \
	  (cd ai_core && grep -v '  index.ndjson$$' ../$(AI_CORE_DIR)/SHA256SUMS | shasum -a 256 -c --quiet && shasum -a 256 index.ndjson | grep -q '^$(AI_CORE) ') && \
	  for f in $$(find ai_core -name '*.png'); do printf '[remap]\n\nimporter="keep"\n' > "$$f.import"; done && \
	  echo "ai-core-bundle: staged $$(find ai_core -type f | wc -l | tr -d ' ') files ($$(du -sh ai_core | cut -f1)), ai_core $(AI_CORE)"; \
	else echo "ai-core-bundle: WARNING no core blobs in $(AI_CORE_BLOBS); this build has no core layer (run make ai-core-assets)"; fi

ai-core-publish:   ## AI.8 maintainers (gcloud auth): upload the pinned core blobs to gs://stapledons-voyage-assets/ai/<sha256>.<ext> (never overwrites)
	@command -v gcloud > /dev/null || { echo "ai-core-publish: needs gcloud (maintainers only)"; exit 1; }
	@$(call ai_core_verify,$(AI_CORE_DIR),$(AI_CORE_BLOBS)) | grep -q '^core-verify: 5 blobs in' || { echo "ai-core-publish: blobs missing or not matching; run make ai-core-import first"; exit 1; }
	@$(call ai_core_blobs,$(AI_CORE_DIR)/SHA256SUMS) | while read -r sum path; do \
	  obj="$(AI_CORE_GS)/$$sum.$${path##*.}"; \
	  if gcloud storage objects describe "$$obj" > /dev/null 2>&1; then echo "  exists   $$obj"; continue; fi; \
	  gcloud storage cp --no-clobber --cache-control="public, max-age=31536000, immutable" "$(AI_CORE_BLOBS)/$$path" "$$obj" && echo "  uploaded $$obj"; \
	done

# ---------------------------------------------------------------- AI.9: key and cost UX, live guard, export
# Design (a5). AC15: no automation can start a live provider. tools/ai_live_guard.sh holds the
# static rules (A-E, in its header); the target then proves each rule fires on a mutated scratch
# copy (a test target passing --provider gemini, one passing --provider openrouter, AI_LIVE=1 in
# CI, AI_LIVE set by a test other than tests/test_ai_relay.gd, live_allowed = true in a test,
# live_allowed defaulting to true, no --ai-no-adc, live in automation runs), and runs the launch
# builder with AI_LIVE and the keys unset (tests/test_ai_settings.gd --launch-default).
.PHONY: ai-live-guard ai-settings ai-runtime ai-export-smoke ai-loopback-mutants
ai-test: ai-live-guard ai-settings

AI_G := $(SCRATCH)/ai-live-guard
ai_guard_scan = Makefile mk .github tests tools bridge/ai_bridge.gd ui/settings/ai_settings.gd
ai-live-guard: import   ## AC15: no target, test, CI job or launch path can start a live provider; each rule's mutant is caught
	@sh tools/ai_live_guard.sh .
	@set -e; for m in \
	  'mk/ai.mk@\z@\nai-mutant:\n\t$$(AILANG) run --quiet --package-dir ai --provider gemini ai/service.ail\n@A mk/ai.mk' \
	  'mk/ai.mk@\z@\nai-mutant:\n\t$$(AILANG) run --quiet --package-dir ai --provider openrouter ai/service.ail\n@A mk/ai.mk' \
	  'mk/ai.mk@\z@\nai-mutant:\n\tprintf x | $$(AILANG) run --caps IO,FS,Env,Net,AI --entry live ai/service.ail\n@A mk/ai.mk' \
	  '.github/workflows/ci.yml@\z@\n      - run: AI_LIVE=1 make ai-relay\n@C .github/workflows/ci.yml' \
	  'tests/test_ai_bridge.gd@\z@\n\tOS.set_environment("AI_LIVE", "1")\n@B tests/test_ai_bridge.gd' \
	  'tests/test_ai_settings.gd@\z@\n\tb.live_allowed = true\n@B tests/test_ai_settings.gd' \
	  'bridge/ai_bridge.gd@^var live_allowed := false$$@var live_allowed := true@D bridge/ai_bridge.gd: live_allowed' \
	  'bridge/ai_bridge.gd@, "--ai-no-adc"\]@]@D bridge/ai_bridge.gd: Gemini' \
	  'bridge/ai_bridge.gd@\[ "\$$a" = 1 \] && l=AI_LIVE=1; @l=AI_LIVE=1; @D bridge/ai_bridge.gd: LIVE_WRAP' \
	  'ui/settings/ai_settings.gd@return opt_in and not automation and@return opt_in and@E ui/settings/ai_settings.gd: live_on'; do \
	  file=$${m%%@*}; rest=$${m#*@}; from=$${rest%%@*}; rest=$${rest#*@}; to=$${rest%%@*}; want=$${rest#*@}; \
	  rm -rf $(AI_G) && mkdir -p $(AI_G) && git ls-files $(ai_guard_scan) | grep -v '^tests/replays/\|^tests/ai/\|^tests/fixtures/\|\.uid$$' | tar -cf - -T - | tar -xf - -C $(AI_G); \
	  FROM="$$from" TO="$$to" perl -0pi -e '$$t = $$ENV{TO}; $$t =~ s/\\n/\n/g; $$t =~ s/\\t/\t/g; s/$$ENV{FROM}/$$t/m or die "anchor not found: $$ENV{FROM}\n"' $(AI_G)/$$file; \
	  if sh tools/ai_live_guard.sh $(AI_G) > $(AI_G)/out.txt; then echo "guard mutant SURVIVED: $$file $$to"; exit 1; fi; \
	  grep -qF "ai-live-guard: $$want" $(AI_G)/out.txt || { echo "guard mutant in $$file did not fail '$$want':"; cat $(AI_G)/out.txt; exit 1; }; \
	  echo "guard mutant caught: $$file ($$want)"; \
	done
	env -u AI_LIVE -u GOOGLE_API_KEY -u OPENROUTER_API_KEY $(GODOT_SIM) --headless --path . --script tests/test_ai_settings.gd -- --launch-default

ai-settings: import   ## AI.9: settings (opt-in, keys 0600, kinds, ceiling, text-only), panel, indicator + budget, wired AC14 path
	env -u AI_LIVE -u GOOGLE_API_KEY -u OPENROUTER_API_KEY $(GODOT_SIM) --headless --path . --script tests/test_ai_settings.gd

# AI.9 must-fix 2: a billed but unparsable reply is charged. Each mutant of ai/adapters.ail drops
# the charge on one parse failure and must fail make ai-loopback's billed check.
ai-loopback-mutants:   ## AI.9: OpenRouter and TTS parse failures uncharged; each fails ai-loopback
	@set -e; cp ai/adapters.ail $(SCRATCH)/adapters.ail.orig; trap 'cp $(SCRATCH)/adapters.ail.orig ai/adapters.ail' EXIT; \
	for m in 'units: billed(u, billedOpenRouter(resp.body))@billed openrouter failure not charged' 'units: billed(u, billedTts(resp.body))@billed tts failure not charged'; do \
	  from=$${m%%@*}; want=$${m#*@}; cp $(SCRATCH)/adapters.ail.orig ai/adapters.ail; \
	  FROM="$$from" perl -0pi -e 's/\Q$$ENV{FROM}\E/units: u/ or die "anchor not found\n"' ai/adapters.ail; \
	  if $(MAKE) --no-print-directory ai-loopback > $(SCRATCH)/loopback-mutant.txt 2>&1; then echo "mutant SURVIVED: $$from"; exit 1; fi; \
	  grep -qF "FAIL $$want" $(SCRATCH)/loopback-mutant.txt || { tail -5 $(SCRATCH)/loopback-mutant.txt; exit 1; }; \
	  echo "mutant killed: adapters.ail '$$from' -> 'units: u' fails '$$want'"; \
	done
ai-mutants: ai-loopback-mutants

# Export: the AI service runs from the bundled runtime with ai/ and data/ai/ unpacked beside the
# sim. ai-runtime locks ai/ (sunholo/gemini_live) into the bundled package cache, beside the sim's.
AI_RT_HOME := $(SCRATCH)/ai-runtime-home
ai-runtime: runtime   ## AI.9: add ai/'s locked packages to the bundled runtime's package cache
	@rm -rf $(AI_RT_HOME) && mkdir -p $(AI_RT_HOME)
	cd ai && HOME=$(CURDIR)/$(AI_RT_HOME) $(CURDIR)/$(RUNTIME)/bin/ailang lock
	@git checkout -q ai/ailang.lock
	cp -R $(AI_RT_HOME)/.ailang/cache/registry/. $(RUNTIME)/cache/registry/
	@find $(RUNTIME)/cache/registry -mindepth 3 -maxdepth 3 -type d | sed 's/^/  cached /'
export-macos: ai-runtime ai-core-bundle

# export-smoke gains the stub AI hello (no ailang on PATH): the app starts the bundled stub
# service, writes its hello and quits.
ai-export-smoke:   ## AI.9: the exported .app's AI service says hello in stub mode with no ailang on PATH
	@rm -rf $(SCRATCH)/ai-export-smoke && mkdir -p $(SCRATCH)/ai-export-smoke
	exe=$$(defaults read "$(CURDIR)/$(APP)/Contents/Info.plist" CFBundleExecutable); \
	env -i PATH=/usr/bin:/bin HOME="$$HOME" "$(APP)/Contents/MacOS/$$exe" -- --map --ai-hello="$(CURDIR)/$(SCRATCH)/ai-export-smoke/hello.json"
	@h=$(SCRATCH)/ai-export-smoke/hello.json; cat $$h; grep -q '"type":"hello"' $$h && grep -q '"provider":"stub"' $$h && grep -q '"live":false' $$h && \
	  echo "ai-export-smoke: OK (stub hello from the bundled runtime)"
export-smoke: ai-export-smoke
