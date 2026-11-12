# R3-REASONS (design_docs/planned/r3/reasons-to-travel.md): the destination finder's Godot side.
.PHONY: reason-card-test capture-reason-card

reason-card-test: import ## R3-REASONS RT5a: the reason card on the example fixture: every number bound, offers and needs, time-first cost, state bars, no judging word
	@mkdir -p $(SCRATCH)
	@$(GODOT_SIM) --headless --path . --script tests/test_reason_card.gd > $(SCRATCH)/reason-card.log 2>&1; rc=$$?; grep -E '^(FAIL|reason-card)' $(SCRATCH)/reason-card.log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/reason-card.log
ui: reason-card-test

capture-reason-card: import ## R3-REASONS RT5a: the card for each example candidate, True and Processed -> renders/reason_card/*.png (GPU window; open every frame)
	@mkdir -p $(SCRATCH)
	@$(GODOT_SIM) $(AUDIO_OFF) --path . --resolution 1280x720 --script tools/reason_card_capture.gd > $(SCRATCH)/reason-card-capture.log 2>&1; rc=$$?; grep -E '^reason-card-capture' $(SCRATCH)/reason-card-capture.log; \
	  test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/reason-card-capture.log
