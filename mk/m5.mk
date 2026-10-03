# M5 planets and flybys (sprint R1-M5-PLANETS, design m5-planets).
# Included from the Makefile by one line (F4: M5 stays out of the Makefile hunks
# M4 edits). Uses AILANG and SCRATCH from the Makefile.

.PHONY: planet-bundle export-smoke-planets m5-test strict-m5 parity-v2-system hello-pin acen-snapshot acen-snapshot-verify \
  planets-test planet-textures-check lint-precision lint-precision-m5 planet-assets planet-verify planet-publish planet-textures golden-m5 capture-m5a

test: m5-test

m5-test: strict-m5 parity-v2-system hello-pin acen-snapshot-verify planets-test planet-textures-check lint-precision-m5   ## M5 checks that run without a GPU window

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

# ------------------------------------------------------------ M5.2a globes, photometry, textures
planets-test:      ## M5.2a: SystemView on the recorded system section, point/disc switch, placement, albedo table (headless)
	$(GODOT) --headless --path . --script tests/test_planets.gd

# The precision lint for the planet renderer (gate 5: gamma and 1 - beta come from the sim or the
# package, never by hand). M4.6's lint-precision absorbs this: until then `lint-precision` is this.
PRECISION_M5 := planets physics/planets.gd tools/m5_golden.gd tools/planet_textures.gd
lint-precision: lint-precision-m5
lint-precision-m5: ## M5.2a: no hand-computed gamma or 1 - beta in the planet renderer
	@if grep -rnE '1(\.0)? *- *(beta|b)\b|sqrt\( *1(\.0)? *- *(b|beta) *\* *(b|beta)' $(PRECISION_M5); then \
	  echo "lint-precision-m5: FAILED (take gamma and 1 - beta from the sim or Relativity)"; exit 1; fi
	@echo "lint-precision-m5: $(PRECISION_M5) clean (no hand-computed gamma or 1 - beta)"

# Planet albedo textures (D-18 pattern): pins and CREDITS tracked in data/planets/, files in the
# gitignored assets/planets/. planet-publish uploads to the public bucket (maintainers, gcloud):
# run only after Mark's licence check (sprint R1-M5-PLANETS, pause L-tex).
planet-assets:     ## M5.2a: pinned planet textures into assets/planets: the public bucket, else the original source, sha256-checked
	@sh tools/planet_assets.sh fetch && sh tools/planet_assets.sh verify | tail -1

planet-verify:     ## M5.2a: sha256-check assets/planets against data/planets/SHA256SUMS
	@sh tools/planet_assets.sh verify

planet-publish:    ## M5.2a maintainers (gcloud auth): upload the pinned textures to gs://stapledons-voyage-assets/planets/<sha256>.<ext> (never overwrites; after L-tex)
	sh tools/planet_assets.sh publish

planet-textures:   ## M5.2a: rewrite data/planets/ALBEDO from the fetched textures (a reviewed diff)
	$(GODOT) --headless --path . --script tools/planet_textures.gd -- --write

planet-textures-check: ## M5.2a: every texture's disc-integrated albedo with its ALBEDO mean = p_V within 1% (skipped if not fetched)
	@mkdir -p $(SCRATCH)
	@$(GODOT) --headless --path . --script tools/planet_textures.gd -- --check > $(SCRATCH)/planet-textures.log 2>&1; rc=$$?; \
	  grep -E '^(ok|FAIL|planet-textures)' $(SCRATCH)/planet-textures.log; test $$rc = 0

golden-m5:         ## M5 GPU goldens alone (needs a GPU window): G-M5-4 Jupiter photometry, G-M5-6 point/disc handoff
	@mkdir -p $(SCRATCH)
	@perl -e 'alarm 900; exec @ARGV' $(GODOT) --path . -- --golden-m5 > $(SCRATCH)/golden-m5.log 2>&1; rc=$$?; grep -E '^(ok|FAIL|skip|      G-M5|m5 golden)' $(SCRATCH)/golden-m5.log; \
	  test $$rc = 0 && grep -q '^ok    G-M5-4 Jupiter at opposition (uniform p_V' $(SCRATCH)/golden-m5.log && \
	  grep -q '^ok    G-M5-6 point/disc handoff' $(SCRATCH)/golden-m5.log && grep -q '^m5 golden: 0 failures$$' $(SCRATCH)/golden-m5.log || \
	  { echo "golden-m5: FAILED (exit $$rc, or a G-M5-4 / G-M5-6 line is missing)"; exit 1; }

capture-m5a:       ## M5.2a reference renders (needs a GPU window) -> renders/m5/m5.2a/: nine globes, Jupiter in EYE, the Sun, the crossover pair, a sheet
	perl -e 'alarm 900; exec @ARGV' $(GODOT) --path . -- --capture-m5=renders/m5/m5.2a

# ------------------------------------------------------------ planet textures in exported builds
# assets/planets is .gdignore'd, so Godot's export skips it (the sky_bundle / areas_bundle
# pattern): stage sha256-verified byte copies as planet_bundle/<file>.bin (gitignored; in the
# export's include_filter with data/planets/*). No textures = a FAILED build, never untextured globes.
export-macos: planet-bundle
publish-dev: export-smoke-planets

planet-bundle:     ## M5.2a: fetch + verify the pinned planet textures and stage them into planet_bundle/ for the export (fails if any is missing)
	@sh tools/planet_assets.sh fetch >/dev/null || { echo "planet-bundle: FAILED, pinned planet textures not fetched (bucket and source)"; exit 1; }
	@sh tools/planet_assets.sh verify >/dev/null || { echo "planet-bundle: FAILED, assets/planets does not match data/planets/SHA256SUMS"; exit 1; }
	@rm -rf planet_bundle && mkdir -p planet_bundle && n=0; \
	  for p in $$(awk '$$2 == "texture" { print $$3 }' data/planets/SHA256SUMS); do cp "$$p" "planet_bundle/$$(basename $$p).bin"; n=$$((n + 1)); done; \
	  test "$$n" -eq "$$(awk '$$2 == "texture"' data/planets/SHA256SUMS | wc -l | tr -d ' ')" && test "$$n" -gt 0 || { echo "planet-bundle: FAILED, staged $$n textures"; exit 1; }; \
	  echo "planet-bundle: staged $$n pinned textures ($$(du -sh planet_bundle | cut -f1))"

export-smoke-planets: export-macos   ## the exported .app loads all nine textures from its bundle and draws a textured Jupiter (GPU window)
	@mkdir -p $(SCRATCH)/export-smoke $(SCRATCH)/export-smoke-home
	@exe=$$(defaults read "$(CURDIR)/$(APP)/Contents/Info.plist" CFBundleExecutable); \
	  env -i PATH=/usr/bin:/bin HOME="$(CURDIR)/$(SCRATCH)/export-smoke-home" perl -e 'alarm 300; exec @ARGV' "$(APP)/Contents/MacOS/$$exe" -- --planet-smoke="$(CURDIR)/$(SCRATCH)/export-smoke/planet_smoke.png" > $(SCRATCH)/export-smoke/planet-smoke.log 2>&1; rc=$$?; \
	  grep '^planet-smoke:' $(SCRATCH)/export-smoke/planet-smoke.log; \
	  test $$rc = 0 && grep -q '^planet-smoke: 9/9 textured bodies (res://planet_bundle)$$' $(SCRATCH)/export-smoke/planet-smoke.log && \
	  grep -q '^planet-smoke: Jupiter disc textured$$' $(SCRATCH)/export-smoke/planet-smoke.log && test -s $(SCRATCH)/export-smoke/planet_smoke.png || \
	  { echo "export-smoke-planets: FAILED (exit $$rc)"; exit 1; }
	@echo "export-smoke-planets: OK, the exported app draws textured globes from its bundle ($(SCRATCH)/export-smoke/planet_smoke.png)"
