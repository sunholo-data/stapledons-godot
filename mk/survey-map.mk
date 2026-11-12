# R3-TELESCOPE TS7: package-derived registered sky directions, no survey depth.
.PHONY: survey-map-test survey-footprint-test survey-footprints survey-footprint-parity
survey-map-test:
	@$(SCRIPT_GATE) survey-map-test $(SCRATCH)/observations/survey-map.log 180 '^survey-map: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT) --headless --path . --script tests/test_survey_map.gd
survey-footprint-test:
	@$(SCRIPT_GATE) survey-footprint-test $(SCRATCH)/observations/footprint-test.log 180 '^survey-footprint-test: [1-9][0-9]* passed, 0 failures$$' -- sh -c 'set -eu; observation_log="$$2"; if (cd sim && "$$1" test --no-color tools/observation_footprint_test.ail) > "$$observation_log" 2>&1; then cat "$$observation_log"; else cat "$$observation_log"; exit 1; fi; observation_count=$$(awk '"'"'/^[0-9]+ tests:/ && $$1 == $$3 && $$5 == 0 && $$7 == 0 {print $$1}'"'"' "$$observation_log"); test -n "$$observation_count"; echo "survey-footprint-test: $$observation_count passed, 0 failures"' sh '$(AILANG)' '$(CURDIR)/$(SCRATCH)/observations/footprint-native.log'
survey-footprints:
	@$(AILANG) run --quiet --bytecode --package-dir sim --caps FS,IO --entry main --args-json '{"input":"data/observations/euclid_dr1/manifest.json","output":"data/observations/euclid_dr1/footprints.json"}' sim/tools/observation_footprint.ail
survey-footprint-parity:
	@$(SCRIPT_GATE) survey-footprint-parity $(SCRATCH)/observations/footprint-parity.log 180 '^survey-footprint-parity: 1 real registered field, 0 mismatches$$' -- sh -c 'set -eu; observation_cli="$$1"; observation_out="$$2"; mkdir -p "$$observation_out"; \
	  observation_args=$$(jq -cn --arg input data/observations/euclid_dr1/manifest.json --arg output "$$observation_out/footprint.vm.json" "{input:\$$input,output:\$$output}"); \
	  "$$observation_cli" run --quiet --bytecode --package-dir sim --caps FS,IO --entry main --args-json "$$observation_args" sim/tools/observation_footprint.ail; \
	  observation_args=$$(jq -cn --arg input data/observations/euclid_dr1/manifest.json --arg output "$$observation_out/footprint.interp.json" "{input:\$$input,output:\$$output}"); \
	  "$$observation_cli" run --quiet --package-dir sim --caps FS,IO --entry main --args-json "$$observation_args" sim/tools/observation_footprint.ail; \
	  cmp "$$observation_out/footprint.vm.json" "$$observation_out/footprint.interp.json"; cmp "$$observation_out/footprint.vm.json" data/observations/euclid_dr1/footprints.json; \
	  test "$$(jq -r ".fields | length" "$$observation_out/footprint.vm.json")" = 1; \
	  observation_raw=$$(jq -Rs . data/observations/euclid_dr1/manifest.json); \
	  "$$observation_cli" run --quiet --bytecode --strict-bytecode --package-dir sim --entry build --args-json "$$observation_raw" sim/tools/observation_footprint.ail > "$$observation_out/footprint.pure.vm"; \
	  "$$observation_cli" run --quiet --package-dir sim --entry build --args-json "$$observation_raw" sim/tools/observation_footprint.ail > "$$observation_out/footprint.pure.interp"; \
	  cmp "$$observation_out/footprint.pure.vm" "$$observation_out/footprint.pure.interp"; \
	  echo "survey-footprint-parity: 1 real registered field, 0 mismatches"' sh '$(AILANG)' '$(SCRATCH)/observations'
