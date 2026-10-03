### Added

- Sol and α Centauri as cited AILANG data, sprint R1-M5-PLANETS M5.1a (design `m5-planets.md` §M5.1, §M5.7). Both modules are pure and load on the strict VM.
  - `sim/data/sol.ail` covers the Sun, the 8 planets and the 12 moons named in the design, plus ring profiles for all four giants. The sources are:
    - Standish Table 2a/2b elements and rates;
    - the IAU WGCCRE 2015 poles, W and radii (from NAIF `pck00011.tpc`, including the periodic terms);
    - DE440 GMs;
    - Mallama 2017 p_V;
    - Minnaert k from Binder & McCarthy 1973 for Jupiter and Saturn, with Lambert assumed for the rest;
    - JPL SSD satellite mean elements;
    - NSSDC satellite albedos.

    The ring profiles are `[(r_in, r_out, tau, w0)]` bands with a tint, taken from PDS Rings Node (Saturn) and NSSDC (the others). Every row carries citation keys that resolve in `citations()`.
  - `sim/data/acen.ail` holds the AB orbit (Akeson 2021), Proxima b and d (confirmed in the NASA Exoplanet Archive snapshot of 2026-10-03), Proxima c (candidate) and α Cen A b (candidate, from one of Beichman 2025's four orbit families). Every number records its provenance: `measured`, `inferred` (the relation is named) or `assumed` (with the reason). No retracted row (α Cen B b) is loaded.
  - `sim/celestial_test.ail` holds the provenance half of AC6, 17 checks in all. They cover:
    - citation keys;
    - NSSDC orbit periods, obliquities and rotation periods;
    - each moon's return after its published sidereal period, which catches a misread JPL `P` column or a wrong rate sign;
    - synchronous rotation;
    - ring structure, and the design-repo ring table where it agrees with the published profiles, with an explicit list of the edges where it doesn't;
    - α Cen status and provenance, Kepler's third law for AB, and the recomputed inferred radii.
  - `make strict-m5` (in the new `mk/m5.mk`, part of `make test`) checks that the strict VM, the interpreter and `sol-data-ok` all agree. `make acen-snapshot` fetches the archive rows, and `make acen-snapshot-verify` checks them against `data/planets/EXOPLANETS.SHA256`.

### Changed

- `sim/ailang.toml` now pins `sunholo/relativity` 0.7.0, which carries M4.6a's `glowEmittanceAt` and M5.0b's `apparentDisc`, `angleSeen` and `hoverPower`. It also adds `sunholo/celestial` 0.1.0. The pin is its own commit, and the lockfile and bundled cache move with it.
