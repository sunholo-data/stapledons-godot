# R2-CAPTAIN-ANIMATION (design_docs/planned/r2/captain-animation.md, ledger D-102): the captain's
# animation state, the painted frames' consistency check and the review captures.
.PHONY: captain-anim-test
captain-anim-test: import ## AC1, AC2: CaptainAnim on scripted inputs (8-sector facing in Bow and Astern, hysteresis, distance-driven phase, transitions, reduced motion, determinism) and CaptainAvatar's frame and still choice
	@mkdir -p $(SCRATCH)
	@$(SCRIPT_GATE) captain-anim-test $(SCRATCH)/captain-anim-test.log 600 '^captain-anim: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT) --headless --path . --script tests/test_captain_anim.gd
test: captain-anim-test
.PHONY: bridge-operator-test
bridge-operator-test: import ## D-132: actual original-desk working points, capsule/route clearance, foot anchor and work-pose reset
	@mkdir -p $(SCRATCH)
	@$(SCRIPT_GATE) bridge-operator-test $(SCRATCH)/bridge-operator-test.log 600 '^bridge-operator-contact: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT) --headless --path . --script tests/test_bridge_operator_contact.gd -- --installed
test: bridge-operator-test
.PHONY: captain-frames-check captain-frames-ingest captain-anim-capture
captain-frames-check: import ## AC4, AC5: every painted frame against its guide (silhouette IoU) and the stage-0 stills (palette dE), scale consistency, cell geometry, disk and GPU budgets; then the seeded defects (recoloured, wrong pose, wrong scale) must fail
	@mkdir -p $(SCRATCH)
	@$(SCRIPT_GATE) captain-frames-check $(SCRATCH)/captain-frames.log 600 '^captain-frames: ok \([1-9][0-9]* frames\)$$' -- $(GODOT) --headless --path . --script tools/captain_frames.gd -- --json $(SCRATCH)/captain-frames.json
	@$(SCRIPT_GATE) captain-frames-selftest $(SCRATCH)/captain-frames-selftest.log 600 '^captain-frames: selftest ok \([1-9][0-9]* frames\)$$' -- $(GODOT) --headless --path . --script tools/captain_frames.gd -- --selftest
test: captain-frames-check
captain-frames-ingest: import ## authoring: RAW=<dir of painted 1024x1536 frames> GUIDES=<dir of full-size guides> -> assets/characters/captain/anim/y0/*.webp + the manifest's anim section
	@$(GODOT) --headless --path . --script tools/captain_frames.gd -- --ingest $(RAW) --guides $(GUIDES) --json $(SCRATCH)/captain-frames-ingest.json
captain-anim-capture: import ## AC6: the captain through the real Bow view at 1280x720: every clip and facing, the side-by-side, the moonwalk before/after, animated WebPs -> OUT (default build/captain_review; GPU window; open them)
	@sh tools/captain_review.sh $(or $(OUT),build/captain_review)
.PHONY: captain-chair-test
captain-chair-test: import ## CA2 (OQ9): the chair in the real demo: E in reach sits on the seat facing the bow, a move key or E stands first then walks, no chair below; arrival and starbow look-up cues
	@mkdir -p $(SCRATCH)
	@$(SCRIPT_GATE) captain-chair-test $(SCRATCH)/captain-chair-test.log 600 '^captain-chair: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT_SIM) --headless --path . --script tests/test_captain_chair.gd
test: captain-chair-test
