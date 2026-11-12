# R3-REASONS (design_docs/planned/r3/reasons-to-travel.md): the destination finder's Godot side.
.PHONY: reason-card-test capture-reason-card

reason-card-test: import ## R3-REASONS RT5a: the reason card on the example fixture: every number bound, offers and needs, time-first cost, state bars, what is drawn in True and Processed, no judging word
	@mkdir -p $(SCRATCH)
	@$(SCRIPT_GATE) reason-card-test $(SCRATCH)/reason-card-test.log 120 '^reason-card: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT) --headless --path . --script tests/test_reason_card.gd
ui: reason-card-test

capture-reason-card: import ## R3-REASONS RT5a: the card for each example candidate, True and Processed -> renders/reason_card/*.png (GPU window; open every frame)
	@mkdir -p $(SCRATCH)
	@$(SCRIPT_GATE) capture-reason-card $(SCRATCH)/capture-reason-card.log 300 '^reason-card-capture: 8 frames$$' -- $(GODOT) $(AUDIO_OFF) --path . --resolution 1280x720 --script tools/reason_card_capture.gd
