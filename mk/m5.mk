# M5 planets and flybys (sprint R1-M5-PLANETS, design m5-planets).
# Included from the Makefile by one line (F4: M5 stays out of the Makefile hunks
# M4 edits). Uses AILANG and SCRATCH from the Makefile.

.PHONY: m5-test strict-m5 parity-v2-system hello-pin acen-snapshot acen-snapshot-verify

test: m5-test

m5-test: strict-m5 parity-v2-system hello-pin acen-snapshot-verify   ## M5 checks that run without a GPU window

# M5.1a: the cited Sol and alpha Cen data modules load and pass every provenance
# check on the strict VM, printing the same bytes as the interpreter (AC6 data half).
strict-m5:         ## sim/data/{sol,acen}.ail checks (celestial_test dataVm): strict VM == interpreter == sol-data-ok
	@mkdir -p $(SCRATCH)
	@$(AILANG) run --quiet --bytecode --strict-bytecode --package-dir sim --entry dataVm --args-json 0 sim/celestial_test.ail > $(SCRATCH)/m5-data-vm.txt
	@$(AILANG) run --quiet --package-dir sim --entry dataVm --args-json 0 sim/celestial_test.ail > $(SCRATCH)/m5-data-interp.txt
	@cmp $(SCRATCH)/m5-data-vm.txt $(SCRATCH)/m5-data-interp.txt && test "$$(cat $(SCRATCH)/m5-data-vm.txt)" = "sol-data-ok" && \
	  echo "strict-m5 dataVm: $$(cat $(SCRATCH)/m5-data-vm.txt) (strict VM = interpreter)"
	@# M5.1b (AC4 system half): systemAt checks, two encoded system sections and a protocol 2.3 session, strict VM = interpreter
	@$(AILANG) run --quiet --bytecode --strict-bytecode --package-dir sim --entry systemVm --args-json 0 sim/celestial_test.ail > $(SCRATCH)/m5-system-vm.txt
	@$(AILANG) run --quiet --package-dir sim --entry systemVm --args-json 0 sim/celestial_test.ail > $(SCRATCH)/m5-system-interp.txt
	@cmp $(SCRATCH)/m5-system-vm.txt $(SCRATCH)/m5-system-interp.txt && test "$$(tail -1 $(SCRATCH)/m5-system-vm.txt)" = "system-ok" && \
	  echo "strict-m5 systemVm: $$(tail -1 $(SCRATCH)/m5-system-vm.txt), $$(wc -l < $(SCRATCH)/m5-system-vm.txt | tr -d ' ') lines, digest $$(shasum -a 256 $(SCRATCH)/m5-system-vm.txt | cut -c1-16) (strict VM = interpreter)"
	@# M5.5a (AC4 planner half): body targets, intercept, refusals and a protocol 2.4 session, strict VM = interpreter
	@$(AILANG) run --quiet --bytecode --strict-bytecode --package-dir sim --entry navigationVm --args-json 0 sim/navigation_test.ail > $(SCRATCH)/m5-nav-vm.txt
	@$(AILANG) run --quiet --package-dir sim --entry navigationVm --args-json 0 sim/navigation_test.ail > $(SCRATCH)/m5-nav-interp.txt
	@cmp $(SCRATCH)/m5-nav-vm.txt $(SCRATCH)/m5-nav-interp.txt && test "$$(tail -1 $(SCRATCH)/m5-nav-vm.txt)" = "navigation-ok" && \
	  echo "strict-m5 navigationVm: $$(tail -1 $(SCRATCH)/m5-nav-vm.txt), $$(wc -l < $(SCRATCH)/m5-nav-vm.txt | tr -d ' ') lines, digest $$(shasum -a 256 $(SCRATCH)/m5-nav-vm.txt | cut -c1-16) (strict VM = interpreter)"

# M5.5a: from protocol 2.4 the hello reports relativityPin(); it must be the pin in sim/ailang.toml.
hello-pin:         ## protocol.ail relativityPin() == the sunholo/relativity pin in sim/ailang.toml
	@pin=$$(sed -n 's/^"sunholo\/relativity" = "\(.*\)"/\1/p' sim/ailang.toml); \
	said=$$(sed -n 's/^export pure func relativityPin() -> string = "\(.*\)"/\1/p' sim/protocol.ail); \
	test -n "$$pin" && test "$$pin" = "$$said" && echo "hello-pin: 2.4 hello reports relativity $$said = sim/ailang.toml pin" || \
	  { echo "hello-pin FAILED: sim/ailang.toml pins relativity '$$pin', protocol.ail relativityPin() says '$$said'"; exit 1; }

# M5.1b (AC4 system half): the protocol 2.3 tail of tests/fixtures/v2_session.ndjson.
# parity-v2 has already compared the whole session VM = interpreter byte for byte;
# here: before the minor-3 hello no line carries `system`; after it the full state and
# the three ticks that move the clock carry it, the dtau-0 tick does not.
parity-v2-system: parity-v2   ## v2 session's 2.3 tail: system lines where the clock moved (VM = interpreter via parity-v2)
	@awk -v want=4 'BEGIN { seen = 0; bad = 0; n = 0 } \
	  /"type":"hello","proto":\{"major":2,"minor":3\}/ { seen = 1; next } \
	  { has = index($$0, "\"system\":{\"jd\":") > 0; if (!seen && has) bad = 1; if (seen && has) n++ } \
	  END { if (!seen || bad || n != want) { printf "parity-v2-system FAILED (seen %d, system before 2.3 %d, system lines %d)\n", seen, bad, n; exit 1 } \
	        printf "parity-v2-system: no system below 2.3; %d system lines after the 2.3 hello (dtau-0 tick silent)\n", n }' $(SCRATCH)/v2_vm.txt
	@grep -c '"system":{"jd":2460251.5,"ephemeris":"jpl-approx","frame":"galactic","bodies":\[{"id":"sun"' $(SCRATCH)/v2_vm.txt | grep -qx 1

# The NASA Exoplanet Archive snapshot behind sim/data/acen.ail's statuses
# (the starmap-manager source, narrowed to alpha Cen). The archive changes, so
# the sha256 pin records the snapshot the data was checked against; a new
# snapshot is a reviewed change to both the pin and acen.ail.
ACEN_SNAPSHOT := data/raw/exoplanets_acen.csv
ACEN_QUERY := select+pl_name,hostname,default_flag,pl_orbper,pl_orbsmax,pl_orbeccen,pl_bmasse,pl_msinie,pl_bmassprov,pl_rade,pl_orbincl,disc_year,discoverymethod,pl_refname,rowupdate+from+ps+where+hostname+in+('Proxima+Cen','alf+Cen+A','alf+Cen+B')
acen-snapshot:     ## fetch the alpha Cen rows of the archive's ps table to data/raw (network; not in make test)
	@mkdir -p data/raw
	curl -sL --fail -o $(ACEN_SNAPSHOT) "https://exoplanetarchive.ipac.caltech.edu/TAP/sync?query=$(ACEN_QUERY)&format=csv"
	@shasum -a 256 $(ACEN_SNAPSHOT)

acen-snapshot-verify: ## the local snapshot matches data/planets/EXOPLANETS.SHA256 and lists Proxima b and d as defaults (skipped if not fetched)
	@test -s data/planets/EXOPLANETS.SHA256 && grep -q ' $(ACEN_SNAPSHOT)$$' data/planets/EXOPLANETS.SHA256
	@if [ -f $(ACEN_SNAPSHOT) ]; then \
	  shasum -a 256 -c data/planets/EXOPLANETS.SHA256 && \
	  grep -q '^"Proxima Cen b","Proxima Cen",1,11.18465' $(ACEN_SNAPSHOT) && grep -q '^"Proxima Cen d","Proxima Cen",1,5.12338' $(ACEN_SNAPSHOT) && \
	  ! grep -q '"Proxima Cen c"\|"alf Cen' $(ACEN_SNAPSHOT) && echo "acen-snapshot-verify: pinned snapshot; Proxima b, d listed; Proxima c and alpha Cen A b absent (candidates)"; \
	else echo "acen-snapshot-verify: $(ACEN_SNAPSHOT) not fetched (make acen-snapshot); pin present, check skipped"; fi
