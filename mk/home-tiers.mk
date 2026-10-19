# R2-HOME-TIERS (design_docs/planned/r2/home-tiers.md): the sixteen home-time tiers and their
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
