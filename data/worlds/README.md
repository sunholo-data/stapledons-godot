# Worlds calibration development evidence

W1.3 has a pure Monte Carlo and a detector interface. **W1.4 is not calibrated.**
Since R3-REASONS RT2a `configuredDetector()` returns a photon-budget detector
built from `sunholo/observe` 0.2.0 (`sim/data/detect.ail`); the production
calibration entry still stops, now for the attended preset ruling. The
development artifacts described below predate it and used the ideal detector.
No final preset, instrument reach, encounter-band achievement, or slice seed is
asserted here.

The named non-baseline presets in `sim/data/presets.ail` are **development grid
candidates**, with `calibrated=false`. They preserve increasing thresholds and
keep the baseline at zero. Their offsets must be replaced by the photon-budget
search output and Mark's ruling before W1.4 can pass.

`tools/calibration_dev.sh` stages an ignored package overlay through
`tools/worlds_dev.sh`, using local celestial/worlds source directories. It never
changes the game's registry pins. `WORLDS_PACKAGES_DIR` selects the directory
holding those packages. `AILANG=runtime/bin/ailang` selects the released v0.56.0.

- `... test`: targeted native tests on the strict VM; no numerical fallback.
- `... parity`: two baseline seeds, byte-identical strict VM/interpreter rows.
- `... smoke`: four seeds × four provisional presets × two binding strategies;
  reports a MISS above the planned 60-second VM budget. The development seed
  count was reduced from the proposed 16 after the 64-row four-strategy
  diagnostic took 88.82 seconds on the shared Studio. The production photon
  backend must receive its own budget probe.
- `... emit <file>`: strict-VM development matrix, both binding strategies.
- `... interpreter <file>`: the same matrix on the interpreter.
- `... emit-full <file>` / `... interpreter-full <file>`: include pilgrim/waiter.

The matrix defaults to four seeds (`CALIB_SEEDS`), Standard's 16,000-year doom
clock (`CALIB_DOOM_YR`), and a caller-selected 10-ly diagnostic support sphere
(`CALIB_SUPPORT_LY`). This ideal detector sees every eligible emission inside
that arbitrary sphere. **It is a development fixture, not a telescope model or
an upper bound on real counts:** changing the support changes what is sampled.
The JSON declares `photon_budget=false`, local packages, provisional status,
source digest, every row, and per-strategy lower medians and 10–90% quantiles.
The numeric arrays are generated in AILANG; shell only redirects JSON to disk.

The pure process samples technological lineages over the full observed-time
and remnant envelope, in fixed 100-ly shells to preserve interior worlds across
strategy ranges. Directions follow the adopted exponential-disc density, using
uniform-volume rejection; they are not incorrectly isotropic at fixed radius.
Biospheres outside that process are generated only in keyed 10-ly cells around
a query. Repeated queries regenerate identical cells. Poisson counts sum
independent inverse-CDF draws with means at most 20, avoiding celestial's
large-mean Gaussian approximation. Existing package physics supplies the
histories, light cone, and relativistic burn/coast/burn travel times at 1g.
Policies receive only detected candidate positions and strengths. Arrival
states are read only to count encounters, never to choose the next target.
Remnant worlds retain their background biosphere and count as visited life;
Ecocide does not. Transcended is post-biological with unclear ecological status,
so no detectable biosphere is assumed. Census background-life counts intentionally
include ended lineages and therefore differ from current, detected biospheres.

`calibrate_search.ail` implements quarter-dex grids and scores both binding
strategies against all five accepted bands, retaining every conflict. The
`searchDevelopment` entry in `sim/tools/calibrate_main.ail` can exercise it
with the ideal fixture. Such output cannot finalise a preset. Production
photon-budget runs, Gentle/Hard comparisons, the selected slice seed,
256-seed final matrix and pinned every-sixteenth-row replay remain open.

The companion `census-25pc-development.json` is the internal 64-seed census,
using the same provisional dials. It is not an encounter/detection forecast.
Every first-seed planet is included in its counts/digest; the statistical rows
use an exact biological marginal that skips deterministically sterile SAG13
extras. Both artifacts are pinned by `DEVELOPMENT.SHA256`.

For population, census and protocol development before the attended worlds
publication, use a fresh ignored overlay. The committed game manifest retains
registry pins and never points at a sibling directory:

```sh
export WORLDS_DEV_PACKAGE=$(AILANG=runtime/bin/ailang tools/worlds_dev.sh path)
make worlds-test worlds-parity census AILANG=tools/worlds_ailang.sh
make worlds-leak AILANG=tools/worlds_ailang.sh
```

The production dependency pin and normal `make ci-fast`/`rig/full` must follow
worlds 0.1.0 publication. Local overlay validation is not a replacement for those
landing gates. `make calibrate` explicitly refuses to finalise presets while
S2's photon-budget backend is unavailable.

The 2.17 leak fixture has 10,000 accepted ticks: two three-tick voyages expose
an actual catalogue target and a local synthesized system, followed by idle
clock and galaxy-stream draws. Full byte comparison covers four presets and
both engines; field allowlists and the encoder import/field-read lint supplement
it. Historical moving/adversarial replays remain separately frozen and checked.

The additional `census-100pc-development.json` records the full 331,311-system
GCNS census with the same provisional dials. All three JSON artifacts are
pinned by `DEVELOPMENT.SHA256`. [Census evidence](census-evidence.md) records
counts, identities, exact digests, the 862.43-second large run, and the distinction
between that measured implementation and the final exact draw-plan preparation.
The 100 pc input comes from pinned binary64 CSV/truth data, not the float32 sky
binary. Twenty-one snapshot planets are outside that registry or uncrossmatched;
complete positional cross-matching is not claimed.
