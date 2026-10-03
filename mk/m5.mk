# M5 planets and flybys (sprint R1-M5-PLANETS, design m5-planets).
# Included from the Makefile by one line (F4: M5 stays out of the Makefile hunks
# M4 edits). Uses AILANG and SCRATCH from the Makefile.

.PHONY: m5-test strict-m5 acen-snapshot acen-snapshot-verify

test: m5-test

m5-test: strict-m5 acen-snapshot-verify   ## M5 checks that run without a GPU window

# M5.1a: the cited Sol and alpha Cen data modules load and pass every provenance
# check on the strict VM, printing the same bytes as the interpreter (AC6 data half).
strict-m5:         ## sim/data/{sol,acen}.ail checks (celestial_test dataVm): strict VM == interpreter == sol-data-ok
	@mkdir -p $(SCRATCH)
	@$(AILANG) run --quiet --bytecode --strict-bytecode --package-dir sim --entry dataVm --args-json 0 sim/celestial_test.ail > $(SCRATCH)/m5-data-vm.txt
	@$(AILANG) run --quiet --package-dir sim --entry dataVm --args-json 0 sim/celestial_test.ail > $(SCRATCH)/m5-data-interp.txt
	@cmp $(SCRATCH)/m5-data-vm.txt $(SCRATCH)/m5-data-interp.txt && test "$$(cat $(SCRATCH)/m5-data-vm.txt)" = "sol-data-ok" && \
	  echo "strict-m5 dataVm: $$(cat $(SCRATCH)/m5-data-vm.txt) (strict VM = interpreter)"

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
