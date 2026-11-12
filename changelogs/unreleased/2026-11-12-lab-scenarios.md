### Added

- The universe lab's scenario files: a scenario is a small named, versioned file that states every setting of a simulated universe, and each setting that departs from the registry's baseline must say why and where the value comes from, or the lab refuses to run it. The baseline is the registry's, not "the literature": it has 14 deliberate, reasoned departures of its own (the 10⁸-year lifetime bound is the first), and the lab prints them ahead of every scenario's own, so "no departures" is never read as "straight from the papers". Three first scenarios: `baseline`, pure physics, and Lonely, the fixed median universe (R3-UNIVERSE-LAB UL3a, `sim/lab_scenario.ail`, `data/lab/scenarios/`, `data/lab/baseline_departures.json`, `make lab-test`). Nothing in the game reads them yet.

### Known gaps

- On the pinned AILANG (v0.56.1) a scenario file with stray text after its closing brace is accepted, and it shares its digest with the clean file. This is the runtime's JSON reader, already fixed upstream in v0.60.0, and it is not worked around. A test states today's behaviour and fails at the next runtime bump, when it is flipped; `make lab-test` prints the gap every run.
- The table of the baseline's departures is a mirror of a design-repo change that is not merged yet (stapledons-design #64). It is re-pinned when that lands, and every scenario digest changes with it.
