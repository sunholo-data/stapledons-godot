# R2-SOUND (design_docs/planned/r2/sound.md): the cue table, the mix, the synthesised sounds and
# their checks. Every check here runs headless (the Dummy audio driver still mixes; design §Evidence).
.PHONY: sound-test sound-assets-check sound-synth sound-synth-check sound-levels sound-levels-parity sound-check sound-review sound-stage sound-stage-check sound-export-smoke ship-sound-test sound-archive-test

# AC1-AC5, AC8 (rules), §D2 layout: validators with negative controls, the clocks, deterministic
# variation; then the same scripted session in two separate processes must give the same cue log (AC2).
sound-test: import
	@mkdir -p $(SCRATCH)/sound
	@$(GODOT) --headless --path . --script tests/test_sound.gd -- --log-out=$(CURDIR)/$(SCRATCH)/sound/log1.txt > $(SCRATCH)/sound/test.log 2>&1; rc=$$?; grep -E '^(FAIL|sound:)' $(SCRATCH)/sound/test.log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/sound/test.log && grep -q '^sound: [0-9]* passed, 0 failures$$' $(SCRATCH)/sound/test.log
	@$(GODOT) --headless --path . --script tests/test_sound.gd -- --log-out=$(CURDIR)/$(SCRATCH)/sound/log2.txt > $(SCRATCH)/sound/test2.log 2>&1
	@test -s $(SCRATCH)/sound/log1.txt && cmp $(SCRATCH)/sound/log1.txt $(SCRATCH)/sound/log2.txt && echo "sound-test: cue log byte-identical in two processes ($$(wc -l < $(SCRATCH)/sound/log1.txt | tr -d ' ') cues)"
test: sound-test

# AC8: the shipped manifest (rows and files).
sound-assets-check: import
	@$(GODOT) --headless --path . --script tools/sound_assets_check.gd > $(SCRATCH)/sound-assets.log 2>&1; rc=$$?; grep -E '^(FAIL|sound-assets-check)' $(SCRATCH)/sound-assets.log; test $$rc = 0 && grep -q ', 0 failures$$' $(SCRATCH)/sound-assets.log
test: sound-assets-check

# S0b: recipes -> assets/audio/synth/*.wav + data/audio/assets_synth.json (authoring; review the diff).
# The synthesis is the sunholo/audio package pinned in tools/audio/ailang.toml (R2-SUNHOLO-AUDIO);
# each row's provenance is that package's version and locked content hash.
SOUND_PKG = --package-dir tools/audio
SOUND_SYNTH_ARGS = '{"recipes":"data/audio/recipes.json","out":"$(1)","part":"$(2)","lock":"tools/audio/ailang.lock"}'
sound-synth:
	@mkdir -p assets/audio/synth
	@$(AILANG) run --quiet --bytecode --caps IO,FS $(SOUND_PKG) --entry main --args-json $(call SOUND_SYNTH_ARGS,assets/audio/synth,data/audio/assets_synth.json) tools/audio/synth_main.ail | tee $(SCRATCH)/sound-synth.log | tail -1; ! grep -q FAIL $(SCRATCH)/sound-synth.log

# AC7: the authoring package type-checks (STRICT_FALLBACK), the game's pure levels module passes verify
# (the synthesis package's contracts are verified in its own repo), the game's pin on the package
# (synth_test: the reference loop's PCM sha256) gives byte-identical output on the strict VM and the
# interpreter, and regenerating every sound into scratch reproduces every sha256 in the manifest part.
sound-synth-check:
	@mkdir -p $(SCRATCH)/sound-synth
	@$(AILANG) check --package tools/audio > $(SCRATCH)/sound-synth/check.log 2>&1 || { cat $(SCRATCH)/sound-synth/check.log; exit 1; }
	@$(AILANG) verify tools/audio/levels.ail > $(SCRATCH)/sound-synth/verify.log 2>&1 || { cat $(SCRATCH)/sound-synth/verify.log; exit 1; }
	@$(AILANG) run --quiet --bytecode --strict-bytecode --caps IO $(SOUND_PKG) --entry main tools/audio/synth_test.ail > $(SCRATCH)/sound-synth/vm.txt
	@$(AILANG) run --quiet --caps IO $(SOUND_PKG) --entry main tools/audio/synth_test.ail > $(SCRATCH)/sound-synth/interp.txt
	@cmp $(SCRATCH)/sound-synth/vm.txt $(SCRATCH)/sound-synth/interp.txt && grep -q '^synth-ok ' $(SCRATCH)/sound-synth/vm.txt || { cat $(SCRATCH)/sound-synth/vm.txt $(SCRATCH)/sound-synth/interp.txt; exit 1; }
	@$(AILANG) run --quiet --bytecode --caps IO,FS $(SOUND_PKG) --entry main --args-json $(call SOUND_SYNTH_ARGS,$(SCRATCH)/sound-synth,$(SCRATCH)/sound-synth/part.json) tools/audio/synth_main.ail > $(SCRATCH)/sound-synth/regen.log; ! grep -q FAIL $(SCRATCH)/sound-synth/regen.log
	@want=$$(jq -r '.assets[] | .id + " " + .sha256' data/audio/assets_synth.json); got=$$(jq -r '.assets[] | .id + " " + .sha256' $(SCRATCH)/sound-synth/part.json); \
	  [ "$$want" = "$$got" ] && echo "sound-synth-check: $$(cut -c1-15 $(SCRATCH)/sound-synth/vm.txt) VM = interpreter; $$(echo "$$want" | wc -l | tr -d ' ') sounds regenerate byte for byte" || { echo "sound-synth-check: FAIL regenerated sounds differ from data/audio/assets_synth.json"; echo "$$got" > $(SCRATCH)/sound-synth/got.txt; echo "$$want" > $(SCRATCH)/sound-synth/want.txt; diff $(SCRATCH)/sound-synth/want.txt $(SCRATCH)/sound-synth/got.txt; exit 1; }
test: sound-synth-check

# R2-SUNHOLO-AUDIO: the offline loudness rules in AILANG (tools/audio/levels.ail over sunholo/audio's
# measures): each cue's band and peak, the laptop high-pass, the teacup guard, two negative controls;
# the rules' probe on the strict VM = the interpreter. Writes $(SCRATCH)/sound/levels.json (centi-dB).
SOUND_LEVELS_ARGS = '{"cues":"data/audio/cues.json","assets":"data/audio/assets.json","dir":"data/audio","out":"$(CURDIR)/$(SCRATCH)/sound/levels.json"}'
sound-levels:
	@mkdir -p $(SCRATCH)/sound
	@$(AILANG) run --quiet --bytecode --strict-bytecode $(SOUND_PKG) --entry levelsProbe --args-json 0 tools/audio/levels.ail > $(SCRATCH)/sound/levels-vm.txt
	@$(AILANG) run --quiet $(SOUND_PKG) --entry levelsProbe --args-json 0 tools/audio/levels.ail > $(SCRATCH)/sound/levels-interp.txt
	@cmp $(SCRATCH)/sound/levels-vm.txt $(SCRATCH)/sound/levels-interp.txt || { echo "sound-levels: FAIL levelsProbe differs between the strict VM and the interpreter"; exit 1; }
	@$(AILANG) run --quiet --bytecode --caps IO,FS $(SOUND_PKG) --entry main --args-json $(SOUND_LEVELS_ARGS) tools/audio/levels_main.ail > $(SCRATCH)/sound/levels.log; \
	  grep -E '^(FAIL|sound-levels)' $(SCRATCH)/sound/levels.log; grep -q '^sound-levels: [0-9]* passed, 0 failures$$' $(SCRATCH)/sound/levels.log
test: sound-levels

# The AILANG measures equal tools/sound_check.gd's (the second-language mirror) for every cue: peak,
# RMS and, where measured, the high-pass keep and the low band, in centi-dB (tools/audio/levels_parity.jq).
sound-levels-parity: sound-check sound-levels
	@diffs=$$(jq -r --slurpfile l $(SCRATCH)/sound/levels.json -f tools/audio/levels_parity.jq $(SCRATCH)/sound/measure.json) || exit 1; \
	  cues=$$(jq 'length' $(SCRATCH)/sound/levels.json); guards=$$(jq '[.[] | (.highpass150_keep_cdb, .below_200hz_cdb) | select(. != null)] | length' $(SCRATCH)/sound/levels.json); \
	  if [ -n "$$diffs" ]; then echo "$$diffs" | sed 's/^/FAIL /'; echo "sound-levels-parity: $$cues cues, $$guards guard values, $$(echo "$$diffs" | wc -l | tr -d ' ') differences"; exit 1; \
	  else echo "sound-levels-parity: $$cues cues, $$guards guard values, 0 differences"; fi
test: sound-levels-parity

# AC6: levels against the bands, the 150 Hz high-pass, ducking, headroom before the limiter (headless mixer).
sound-check: import
	@mkdir -p $(SCRATCH)/sound
	@$(GODOT) --headless --path . --script tools/sound_check.gd -- --out=$(CURDIR)/$(SCRATCH)/sound/measure.json > $(SCRATCH)/sound/check.log 2>&1; rc=$$?; grep -E '^(FAIL|sound-check)' $(SCRATCH)/sound/check.log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/sound/check.log && grep -q '^sound-check: [0-9]* passed, 0 failures$$' $(SCRATCH)/sound/check.log
test: sound-check

# The listening page: every cue (Ogg Opus + WAV), the bridge ambience mix and the spire at three
# degradation levels, sounds.json and index.html in $(SOUND_REVIEW_OUT). V1_REF=<git ref> also renders
# every sound that changed since that ref as <id>_v1 (its old recipe at its old level) for A/B.
# STAGE=<s> PUBLISH=1 uploads to gs://stapledons-voyage-assets/refs/sound/$(STAGE)/.
STAGE ?= s0b
V1_REF ?=
SOUND_REVIEW_OUT ?= $(CURDIR)/build/sound_review
sound-review: sound-check
	@rm -rf $(SOUND_REVIEW_OUT) $(SCRATCH)/sound/v1; mkdir -p $(SOUND_REVIEW_OUT) $(SCRATCH)/sound/v1
	@if [ -n "$(V1_REF)" ]; then git show $(V1_REF):data/audio/recipes.json > $(SCRATCH)/sound/v1/recipes_v1.json && git show $(V1_REF):data/audio/cues.json > $(SCRATCH)/sound/v1/cues_v1.json && git show $(V1_REF):data/audio/assets_synth.json > $(SCRATCH)/sound/v1/assets_synth_v1.json; fi
	@$(GODOT) --headless --path . --script tools/sound_review.gd -- --measure=$(CURDIR)/$(SCRATCH)/sound/measure.json --out=$(SOUND_REVIEW_OUT) --stage=$(STAGE) $(if $(V1_REF),--v1-dir=$(CURDIR)/$(SCRATCH)/sound/v1) 2>&1 | grep -E '^sound-review'
	@$(AILANG) run --quiet --bytecode --caps IO,FS $(SOUND_PKG) --entry main --args-json "$$(cat $(SOUND_REVIEW_OUT)/plan.json)" tools/audio/review_main.ail | tee $(SCRATCH)/sound/review.log | tail -1; ! grep -q FAIL $(SCRATCH)/sound/review.log
	@if [ -f $(SOUND_REVIEW_OUT)/plan_v1.json ]; then $(AILANG) run --quiet --bytecode --caps IO,FS $(SOUND_PKG) --entry main --args-json "$$(cat $(SOUND_REVIEW_OUT)/plan_v1.json)" tools/audio/review_main.ail | tee $(SCRATCH)/sound/review_v1.log | tail -1; ! grep -q FAIL $(SCRATCH)/sound/review_v1.log; fi
	@cp $(SCRATCH)/sound/measure.json $(SOUND_REVIEW_OUT)/measure.json
	@if [ "$(PUBLISH)" = 1 ]; then gcloud storage cp --cache-control=no-cache $(SOUND_REVIEW_OUT)/*.ogg $(SOUND_REVIEW_OUT)/*.wav $(SOUND_REVIEW_OUT)/sounds.json $(SOUND_REVIEW_OUT)/index.html gs://stapledons-voyage-assets/refs/sound/$(STAGE)/ && echo "sound-review: published https://storage.googleapis.com/stapledons-voyage-assets/refs/sound/$(STAGE)/index.html"; fi

# The export (D-112): assets/audio stays .gdignore'd, so the export carries each sound as Godot's own
# QOA-compressed resource, audio_bundle/<kind>/<file>.res (tools/sound_stage.gd); SoundDirector reads
# the bundle when the source WAV is absent. sound-stage-check stages into scratch, reloads every
# resource against its source and holds the bundle to the 6 MB export budget (AC13).
sound-stage: import
	@rm -rf audio_bundle
	@$(GODOT) --headless --path . --script tools/sound_stage.gd -- --out=res://audio_bundle 2>&1 | grep -E '^(FAIL|sound-stage)'
sound-stage-check: import
	@rm -rf $(SCRATCH)/audio_bundle
	@$(GODOT) --headless --path . --script tools/sound_stage.gd -- --out=$(CURDIR)/$(SCRATCH)/audio_bundle --check > $(SCRATCH)/sound-stage.log 2>&1; rc=$$?; grep -E '^(FAIL|sound-stage)' $(SCRATCH)/sound-stage.log; test $$rc = 0 && grep -q ', 0 failures$$' $(SCRATCH)/sound-stage.log
test: sound-stage-check

# The exported .app loads the cue table and plays from the staged bundle (AC13).
sound-export-smoke:
	@mkdir -p $(SCRATCH)/export-smoke $(SCRATCH)/export-smoke-home
	@exe=$$(defaults read "$(CURDIR)/$(APP)/Contents/Info.plist" CFBundleExecutable); \
	env -i PATH=/usr/bin:/bin HOME="$(CURDIR)/$(SCRATCH)/export-smoke-home" "$(APP)/Contents/MacOS/$$exe" --headless -- --sound-smoke > $(SCRATCH)/export-smoke/sound-smoke.log 2>&1; \
	grep -E '^sound-smoke' $(SCRATCH)/export-smoke/sound-smoke.log; grep -q '^sound-smoke: OK' $(SCRATCH)/export-smoke/sound-smoke.log
export-smoke: sound-export-smoke

# S1 (§D4, §D5; AC3, AC10): the bridge's sound through ShipSound on a mock ship, the listener through the mixer.
ship-sound-test: import
	@$(GODOT) --headless --path . --script tests/test_ship_sound.gd > $(SCRATCH)/ship-sound.log 2>&1; rc=$$?; grep -E '^(FAIL|ship-sound)' $(SCRATCH)/ship-sound.log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/ship-sound.log && grep -q '^ship-sound: [0-9]* passed, 0 failures$$' $(SCRATCH)/ship-sound.log
test: ship-sound-test

# D-113: the real sim at 2.15 drives the spire's degradation layer (end to end).
sound-archive-test: import
	@$(GODOT_SIM) --headless --path . --script tests/test_sound_archive.gd > $(SCRATCH)/sound-archive.log 2>&1; rc=$$?; grep -E '^(FAIL|sound-archive)' $(SCRATCH)/sound-archive.log; test $$rc = 0 && ! grep -q 'SCRIPT ERROR:' $(SCRATCH)/sound-archive.log && grep -q '^sound-archive: [0-9]* passed, 0 failures$$' $(SCRATCH)/sound-archive.log
test: sound-archive-test
