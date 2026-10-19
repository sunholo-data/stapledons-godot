# R2-HOME-TIERS (design_docs/implemented/r2/home-tiers.md): the sixteen home-time tiers and their
# picture variants (ledger D-86).
.PHONY: home-tiers-vm
HOME_TIERS_SEEDS ?= 64
home-tiers-vm: ## AC4: the 16-tier ladder, words, lines and per-seed variants: strict VM == interpreter, byte for byte
	@mkdir -p $(SCRATCH)/home-tiers
	@$(AILANG) run --quiet --bytecode --strict-bytecode --package-dir sim --entry homeTiersTable --args-json $(HOME_TIERS_SEEDS) sim/home_tiers_test.ail > $(SCRATCH)/home-tiers/vm.txt
	@$(AILANG) run --quiet --package-dir sim --entry homeTiersTable --args-json $(HOME_TIERS_SEEDS) sim/home_tiers_test.ail > $(SCRATCH)/home-tiers/interp.txt
	@cmp -s $(SCRATCH)/home-tiers/vm.txt $(SCRATCH)/home-tiers/interp.txt || { echo "home-tiers-vm: FAIL: VM and interpreter differ"; exit 1; }
	@test "$$(wc -l < $(SCRATCH)/home-tiers/vm.txt | tr -d ' ')" -ge "$$((16 + $(HOME_TIERS_SEEDS) - 1))" || { echo "home-tiers-vm: FAIL: short table"; exit 1; }
	@echo "home-tiers-vm: 16 tiers, $(HOME_TIERS_SEEDS) seeds, strict VM == interpreter"
test: home-tiers-vm

# AC9 (D-86): the shipped pool agrees with the sim's counts (sim/data/home_variants.ail) and with SOURCES:
# every tier<n>_v<k>.webp for k < count exists and no other picture does; every file's sha256 is its
# SOURCES row; every master URL is a sha-named file in the public bucket; no PNG in the tree (D-18).
# (1536x1024 is checked by crossing-review-test, which decodes every file.)
.PHONY: home-art-check
HOME_ART := data/interlude/home
home-art-check: ## AC9: home picture pool == variant counts == SOURCES (sha256), no PNG master in the tree
	@mkdir -p $(SCRATCH)/home-tiers
	@$(AILANG) run --quiet --package-dir sim --entry countsTable --args-json 0 sim/home_tiers_test.ail > $(SCRATCH)/home-tiers/counts.txt
	@fail=0; want=0; \
	while read t n; do k=0; while [ $$k -lt $$n ]; do want=$$((want + 1)); f=$(HOME_ART)/tier$${t}_v$${k}.webp; \
	  if [ ! -f $$f ]; then echo "home-art-check: FAIL missing $$f"; fail=1; \
	  else s=$$(shasum -a 256 $$f | cut -c1-64); grep -q "^tier$${t}_v$${k}.webp sha256 $$s <- master sha256 [0-9a-f]\{64\} https://storage.googleapis.com/stapledons-voyage-assets/site/[0-9a-f]\{64\}.png$$" $(HOME_ART)/SOURCES || { echo "home-art-check: FAIL $$f sha $$s is not its SOURCES row"; fail=1; }; fi; \
	  k=$$((k + 1)); done; done < $(SCRATCH)/home-tiers/counts.txt; \
	have=$$(ls $(HOME_ART) | grep -c '\.webp$$'); rows=$$(grep -c '^tier[0-9]*_v[0-9]*\.webp sha256' $(HOME_ART)/SOURCES); \
	[ "$$have" = "$$want" ] || { echo "home-art-check: FAIL $$have pictures, the counts say $$want"; fail=1; }; \
	[ "$$rows" = "$$want" ] || { echo "home-art-check: FAIL $$rows SOURCES rows, the counts say $$want"; fail=1; }; \
	! ls $(HOME_ART) | grep -qi '\.png$$' || { echo "home-art-check: FAIL a PNG in $(HOME_ART) (D-18)"; fail=1; }; \
	grep '^tier' $(HOME_ART)/SOURCES | awk '{ if ($$8 != "https://storage.googleapis.com/stapledons-voyage-assets/site/" $$7 ".png") { print "home-art-check: FAIL url is not the master sha: " $$1; exit 1 } }' || fail=1; \
	[ $$fail = 0 ] && echo "home-art-check: $$want pictures, 16 tiers, SOURCES and counts agree"
test: home-art-check

# AC15 (spoiler policy, D-86 amendment): the concept-art page lists every variant of tiers 0-12 and
# nothing later; each row is the game's SOURCES master; each thumbnail exists and is under 1 MB.
# HOME_SITE_URLS=1 also asks the bucket for every master (network).
.PHONY: home-site-check
HOME_SITE_LAST := 12
home-site-check: ## AC15: website HOME == every tier 0-12 variant (no later tier), SOURCES masters, thumbnails <= 1 MB
	@mkdir -p $(SCRATCH)/home-tiers
	@$(AILANG) run --quiet --package-dir sim --entry countsTable --args-json 0 sim/home_tiers_test.ail > $(SCRATCH)/home-tiers/counts.txt
	@fail=0; want=$$(awk '$$1 <= $(HOME_SITE_LAST) {s += $$2} END {print s}' $(SCRATCH)/home-tiers/counts.txt); \
	grep -E "^  \[[0-9]+, [0-9]+, '[0-9a-f]{64}'\],$$" website/src/data/concept.js | tr -d "[]'," | sed -E 's/^ +//' > $(SCRATCH)/home-tiers/site.txt; \
	have=$$(wc -l < $(SCRATCH)/home-tiers/site.txt | tr -d ' '); \
	[ "$$have" = "$$want" ] || { echo "home-site-check: FAIL $$have HOME rows, tiers 0-$(HOME_SITE_LAST) have $$want pictures"; fail=1; }; \
	while read t k sha; do \
	  [ $$t -le $(HOME_SITE_LAST) ] || { echo "home-site-check: FAIL tier $$t is on the site (spoiler policy: 0-$(HOME_SITE_LAST) only)"; fail=1; }; \
	  grep -q "^tier$${t}_v$${k}.webp sha256 [0-9a-f]* <- master sha256 $$sha " data/interlude/home/SOURCES || { echo "home-site-check: FAIL tier$${t}_v$${k} is not its SOURCES master"; fail=1; }; \
	  j=website/static/img/concept/home-t$$(printf %02d $$t)-v$$k.jpg; \
	  if [ ! -f $$j ]; then echo "home-site-check: FAIL missing $$j"; fail=1; elif [ $$(wc -c < $$j) -gt 1048576 ]; then echo "home-site-check: FAIL $$j over 1 MB"; fail=1; fi; \
	  if [ "$(HOME_SITE_URLS)" = 1 ]; then curl -sfI -o /dev/null https://storage.googleapis.com/stapledons-voyage-assets/site/$$sha.png || { echo "home-site-check: FAIL master $$sha not in the bucket"; fail=1; }; fi; \
	done < $(SCRATCH)/home-tiers/site.txt; \
	extra=$$(ls website/static/img/concept | grep -E '^home-' | while read f; do grep -q "^$$(echo $$f | sed -E 's/^home-t0*([0-9]+)-v([0-9]+)\.jpg$$/\1 \2 /')" $(SCRATCH)/home-tiers/site.txt || echo $$f; done); \
	[ -z "$$extra" ] || { echo "home-site-check: FAIL thumbnails not on the page: $$extra"; fail=1; }; \
	[ $$fail = 0 ] && echo "home-site-check: $$want pictures of tiers 0-$(HOME_SITE_LAST) on the page, none later"
test: home-site-check
