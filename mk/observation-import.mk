# R3-TELESCOPE TS2: strict source import and exact-ID presentation adapter.
.PHONY: observation-import-test observation-import-parity observation-index-test
observation-import-test:
	@$(SCRIPT_GATE) observation-import-test $(SCRATCH)/observations/import-test.log 180 '^observation-import-test: [1-9][0-9]* passed, 0 failures$$' -- sh -c 'set -eu; observation_log="$$2"; if (cd sim && "$$1" test --no-color tools/observations_test.ail) > "$$observation_log" 2>&1; then cat "$$observation_log"; else cat "$$observation_log"; exit 1; fi; observation_count=$$(awk '"'"'/^[0-9]+ tests:/ && $$1 == $$3 && $$5 == 0 && $$7 == 0 {print $$1}'"'"' "$$observation_log"); test -n "$$observation_count"; echo "observation-import-test: $$observation_count passed, 0 failures"' sh '$(AILANG)' '$(CURDIR)/$(SCRATCH)/observations/native-test.log'

observation-index-test:
	@$(SCRIPT_GATE) observation-index-test $(SCRATCH)/observations/index-test.log 180 '^observation-index: [1-9][0-9]* passed, 0 failures$$' -- $(GODOT) --headless --path . --script tests/fixtures/observations/index_probe.gd

# Compare the real 40-row index, its checked-in bytes and a strict pure probe.
# The source URL comes from the pinned registration/source evidence, not a new query.
observation-import-parity:
	@$(SCRIPT_GATE) observation-import-parity $(SCRATCH)/observations/parity.log 180 '^observation-import-parity: 40 real sources, 0 mismatches$$' -- sh -c 'set -eu; \
	  observation_cli="$$1"; observation_out="$$2"; mkdir -p "$$observation_out"; \
	  observation_url=$$(jq -er .catalogue_url data/observations/euclid_dr1/registration-evidence.json); \
	  observation_args=$$(jq -cn --arg input data/observations/euclid_dr1/sources.csv --arg output "$$observation_out/objects.vm.json" --arg sourceUrl "$$observation_url" "{input:\$$input,output:\$$output,sourceUrl:\$$sourceUrl,plateId:\"abell3128-vis\"}"); \
	  "$$observation_cli" run --quiet --bytecode --package-dir sim --caps FS,IO --entry main --args-json "$$observation_args" sim/tools/observations.ail; \
	  observation_args=$$(jq -cn --arg input data/observations/euclid_dr1/sources.csv --arg output "$$observation_out/objects.interp.json" --arg sourceUrl "$$observation_url" "{input:\$$input,output:\$$output,sourceUrl:\$$sourceUrl,plateId:\"abell3128-vis\"}"); \
	  "$$observation_cli" run --quiet --package-dir sim --caps FS,IO --entry main --args-json "$$observation_args" sim/tools/observations.ail; \
	  cmp "$$observation_out/objects.vm.json" "$$observation_out/objects.interp.json"; \
	  cmp "$$observation_out/objects.vm.json" data/observations/euclid_dr1/objects.json; \
	  test "$$(jq -r ".objects | length" "$$observation_out/objects.vm.json")" = 40; \
	  "$$observation_cli" run --quiet --bytecode --strict-bytecode --package-dir sim --entry observationProbe --args-json 40 sim/tools/observations.ail > "$$observation_out/probe.vm"; \
	  "$$observation_cli" run --quiet --package-dir sim --entry observationProbe --args-json 40 sim/tools/observations.ail > "$$observation_out/probe.interp"; \
	  cmp "$$observation_out/probe.vm" "$$observation_out/probe.interp"; \
	  grep -Eq "^observation-probe 40 [0-9a-f]{64}$$" "$$observation_out/probe.vm"; \
	  echo "observation-import-parity: 40 real sources, 0 mismatches"' sh '$(AILANG)' '$(SCRATCH)/observations'
