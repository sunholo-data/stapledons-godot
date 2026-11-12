# D-150: the physical captain's chair hosts existing system controls.
.PHONY: captain-command-test captain-command-contact-test captain-command-parity-test captain-command-capture captain-command-layout-test captain-chair-contact-capture
captain-command-test: import
	@mkdir -p $(SCRATCH)
	@$(SCRIPT_GATE) captain-command-test $(SCRATCH)/captain-command-test.log 600 '^captain-command: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT_SIM) --headless --path . --script tests/test_captain_command.gd
captain-command-contact-test: import
	@mkdir -p $(SCRATCH)
	@$(SCRIPT_GATE) captain-command-contact-test $(SCRATCH)/captain-command-contact-test.log 120 '^captain-command-contact: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT) --headless --path . --script tests/test_captain_command_contact.gd
captain-command-parity-test: import
	@mkdir -p $(SCRATCH)
	@$(SCRIPT_GATE) captain-command-parity-test $(SCRATCH)/captain-command-parity-test.log 600 '^captain-command-parity: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT_SIM) --headless --path . --script tests/test_captain_command_parity.gd
test: captain-command-test captain-command-contact-test captain-command-parity-test
captain-command-layout-test: import
	@mkdir -p $(SCRATCH)
	@$(SCRIPT_GATE) captain-command-layout-test $(SCRATCH)/captain-command-layout-test.log 600 '^captain-command-layout: [1-9][0-9]* cases, 0 failures$$' -- $(GODOT_SIM) --headless --path . --script tools/captain_command_capture.gd -- --layout-only
test: captain-command-layout-test
.PHONY: chair-reading-viewport-test
chair-reading-viewport-test: import
	@mkdir -p $(SCRATCH)
	@$(SCRIPT_GATE) chair-reading-viewport-test $(SCRATCH)/chair-reading-viewport-test.log 120 '^chair-reading-viewport: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT) --headless --path . --script tests/test_chair_reading_viewport.gd
test: chair-reading-viewport-test
.PHONY: captain-command-guided-test
captain-command-guided-test: import
	@mkdir -p $(SCRATCH)
	@$(SCRIPT_GATE) captain-command-guided-test $(SCRATCH)/captain-command-guided-test.log 600 '^captain-command-guided: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT_SIM) --headless --path . --script tests/test_captain_command_guided.gd
test: captain-command-guided-test
.PHONY: chair-cockpit-test
chair-cockpit-test: import
	@mkdir -p $(SCRATCH)
	@$(SCRIPT_GATE) chair-cockpit-test $(SCRATCH)/chair-cockpit-test.log 120 '^chair-cockpit: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT) --headless --path . --script tests/test_chair_cockpit.gd
test: chair-cockpit-test
captain-command-capture: import
	@mkdir -p $(SCRATCH)
	@$(SCRIPT_GATE) captain-command-capture $(SCRATCH)/captain-command-capture.log 600 '^captain-command-capture: [1-9][0-9]* frames, 0 failures$$' -- $(GODOT_SIM) $(AUDIO_OFF) --path . --script tools/captain_command_capture.gd
captain-chair-contact-capture: import
	@mkdir -p $(SCRATCH)
	@$(SCRIPT_GATE) captain-chair-contact-capture $(SCRATCH)/captain-chair-contact-capture.log 180 '^captain-chair-capture: [1-9][0-9]* frames, 0 failures' -- $(GODOT) $(AUDIO_OFF) --path . --resolution 1280x720 --script tools/captain_chair_capture.gd
