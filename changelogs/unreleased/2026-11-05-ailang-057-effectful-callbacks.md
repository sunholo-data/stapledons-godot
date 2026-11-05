Build on AILANG v0.57: four `sim/tools` modules passed an effectful lambda to a pure `std/list`
callback, which AILANG v0.57.0 refuses (ailang#1958). Before, such a lambda's effects were lost at type
check. `crew_pack.generate` and `lore_import` read files in `map`, so they now use `mapE`.
`session_audit_test` reads fixtures in `foldl`, so it now uses `foldlE`. `crew_pack_check` read files
inside `any`, which has no effectful variant, so it now asks whether `filterE` finds no differing file;
the answer is the same. With AILANG v0.57.3, `check --package sim` passes 161/161, where 4 files failed
before. CI's pinned v0.56.1 has `mapE`, `filterE` and `foldlE`.
