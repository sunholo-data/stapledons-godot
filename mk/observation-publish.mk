# Maintainer-only immutable assets; no latest aliases or overwritten objects.
.PHONY: observation-publish observation-publish-verify observation-publish-test
observation-publish:
	@$(SCRIPT_GATE) observation-publish $(SCRATCH)/observations/publish.log 1200 '^observation-publish: [1-9][0-9]* immutable objects, 0 failures$$' -- GODOT="$(GODOT)" sh tools/observation_publish.sh publish
observation-publish-verify:
	@$(SCRIPT_GATE) observation-publish-verify $(SCRATCH)/observations/publish-verify.log 1200 '^observation-publish-verify: [1-9][0-9]* anonymous samples, 0 failures$$' -- GODOT="$(GODOT)" sh tools/observation_publish.sh verify
observation-publish-test:
	@$(SCRIPT_GATE) observation-publish-test $(SCRATCH)/observations/publish-test.log 180 '^observation-publish-test: [1-9][0-9]* passed, 0 failures$$' -- GODOT="$(GODOT)" sh tools/test_observation_publish.sh
