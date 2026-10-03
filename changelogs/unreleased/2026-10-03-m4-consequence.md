### Added

- `sim/consequence.ail` and the consequence state in the world, sprint R1-M4-JOURNEY M4.1 (step 1; the design doc is `m4-first-journey.md` §M4.1). Pure, so it runs on the strict VM; I/O stays in `sim/ship.ail`.
  - Stand-off: the new scenario param `standoff_au` (default 0, so M2 plans are unchanged; the M4 client sends 1000) plans to `d - s` along the same heading, `s = 1000 AU = 0.0158125 ly`. Sol (star index 0) never has one, and a star inside the stand-off is `out_of_range`.
  - Displayed quantities as sim fields: `gap_years = t - tau`, `news_epoch = t - |p - Sol|`, `news_age_years`, `progress`. At rest the clock runs at the host rate and the gap does not change.
  - News at arrival: a tier (`<1`, `1-5`, `5-15`, `15-50`, `>=50` Earth-years since departure at the news epoch) and a template id seeded from the `news` stream. alpha Cen is tier `<1`, the return `5-15`.
  - News provenance: `body_source` is `template`, `ai` or `fallback`, with a `fallback_reason` (`ai_numeral`, `ai_length`, `expired`, ...). It follows the existing `ai_request` / `ai_accepted` / `ai_fallback` events; the record validation already in `sim/ai.ail` is reused, not duplicated.
  - Live `ship.ism{load_w_m2, drag_n, glow_w_m2, drag_energy_j}` at the current rapidity (package calls at the current pin, zero at rest), `drag_energy_j` being the ledger's `drag_j` since the latest commit.
  - An append-only legacy log (`commit`, `departure`, `boost`, `cruise`, `brake`, `arrival`, `news`, `return`, `archive_unlock`) and the six README archive hint predicates. `new_game` may carry `archive: [{id, unlock}]`; rows unlock once, in table order.
- Protocol 2.2 (additive): a client that asks for minor 2 is answered minor 2 and receives the `consequence` change set and `ship.ism`. Clients asking for 2.0 or 2.1 get the 2.1 stream byte for byte, so every M2 and AI test and golden is unchanged.
- `make strict` runs `scriptedRoundTrip` (Sol, alpha Cen, Sol at 0.99c with the stand-off, zero dwell) against a closed form, and `consequenceVm` (the whole new battery) on the strict VM.

### Not yet

- `glow_pole_w_m2` is step 2: it waits on M4.6a's `glowEmittanceAt` package release; the sim never computes 4 x `glowInwardFlux` itself.
- The design-repo canon (HB-4 at 4.37 ly) is not yet regenerated at the catalogue 4.32 ly (D-23). The target distance is a parameter; the tests assert the verified 4.37 ly check values and a 4.32 ly case computed from the package.
