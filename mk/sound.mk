# R2-SOUND (design_docs/planned/r2/sound.md): the cue table, the mix, the synthesised sounds and
# their checks. Every check here runs headless (the Dummy audio driver still mixes; design §Evidence).
.PHONY: sound-test sound-assets-check sound-synth sound-synth-check sound-check sound-review

# AC1-AC5, AC8 (rules), §D2 layout: validators with negative controls, the clocks, deterministic
# variation; then the same scripted session in two separate processes must give the same cue log (AC2).
sound-test: import
	@mkdir -p $(SCRATCH)/sound
	@$(GODOT) --headless --path . --script tests/test_sound.gd -- --log-out=$(CURDIR)/$(SCRATCH)/sound/log1.txt > $(SCRATCH)/sound/test.log 2>&1; rc=$$?; grep -E '^(FAIL|sound:)' $(SCRATCH)/sound/test.log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/sound/test.log && grep -q '^sound: [0-9]* passed, 0 failures$$' $(SCRATCH)/sound/test.log
	@$(GODOT) --headless --path . --script tests/test_sound.gd -- --log-out=$(CURDIR)/$(SCRATCH)/sound/log2.txt > $(SCRATCH)/sound/test2.log 2>&1
	@test -s $(SCRATCH)/sound/log1.txt && cmp $(SCRATCH)/sound/log1.txt $(SCRATCH)/sound/log2.txt && echo "sound-test: cue log byte-identical in two processes ($$(wc -l < $(SCRATCH)/sound/log1.txt | tr -d ' ') cues)"
test: sound-test
