# AI service foundation (sprint R1-AI-FOUNDATION, design ai-service-foundation).
# Included from the Makefile by its last line; every AI target lives here so the
# sprint changes one Makefile line. Uses AILANG and SCRATCH from the Makefile.

.PHONY: ai-test strict-ai markers-mutants

test: ai-test

ai-test: strict-ai   ## AI foundation checks that run without a GPU window or a key

# AC7 (part): the pure marker grammar runs entirely on the bytecode VM and prints
# byte for byte what the interpreter prints; its last line is markers-ok. The
# emotion list it prints must equal the keys of data/ai/emotion_styles.json, in order.
strict-ai:         ## AI pure modules on the strict VM == interpreter (markersVm)
	@mkdir -p $(SCRATCH)
	@$(AILANG) run --quiet --bytecode --strict-bytecode --package-dir sim --entry markersVm --args-json 0 sim/markers_test.ail > $(SCRATCH)/markers-vm.txt
	@$(AILANG) run --quiet --package-dir sim --entry markersVm --args-json 0 sim/markers_test.ail > $(SCRATCH)/markers-interp.txt
	@cmp $(SCRATCH)/markers-vm.txt $(SCRATCH)/markers-interp.txt && test "$$(tail -1 $(SCRATCH)/markers-vm.txt)" = "markers-ok" && \
	  echo "strict markersVm: $$(tail -1 $(SCRATCH)/markers-vm.txt), $$(wc -l < $(SCRATCH)/markers-vm.txt | tr -d ' ') lines, digest $$(shasum -a 256 $(SCRATCH)/markers-vm.txt | cut -c1-16) (strict VM = interpreter)"
	@want=$$(sed -n 's/^emotions //p' $(SCRATCH)/markers-vm.txt); \
	got=$$(python3 -c "import json; d=json.load(open('data/ai/emotion_styles.json')); assert all(isinstance(v, str) and v.strip() for v in d.values()); print(','.join(d))"); \
	echo "emotion_styles.json keys: $$got"; [ -n "$$want" ] && [ "$$got" = "$$want" ]

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
