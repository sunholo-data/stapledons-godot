# AI service foundation (sprint R1-AI-FOUNDATION, design ai-service-foundation).
# Included from the Makefile by its last line; every AI target lives here so the
# sprint changes one Makefile line. Uses AILANG and SCRATCH from the Makefile.

.PHONY: ai-test strict-ai markers-mutants replay-compat ai-mutants

test: ai-test

ai-test: strict-ai replay-compat   ## AI foundation checks that run without a GPU window or a key

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
ai-mutants:        ## AI.3: voice variant compared, no numeral check, 65 lines, no dedupe, offsets not strict; each fails a named test
	@set -e; A=$$(command -v $(AILANG)); case "$$A" in /*) ;; *) A="$$PWD/$$A";; esac; \
	for m in \
	  'if want.kind == "voice" || want.kind == "text" then getString(k, "variant") != None else@if false then true else@$(AI3_REFUSALS)' \
	  'c.noNumerals && hasDigit(r.body)@false@$(AI3_REFUSALS)' \
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
