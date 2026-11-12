# Evidence candidate counts: the funnel from truth to record (R3-REASONS RT2a)

**Measured 2026-11-12** with `sim/tools/evidence_probe.ail` at commit `1d373713` (branch `feat/r3-reasons-rt2a`), AILANG v0.56.1 (`runtime/bin/ailang`, bytecode VM), `sunholo/observe` 0.2.0 from ailang-packages main `a95aabe` through the development overlay (`tools/observe_dev.sh`), `sunholo/worlds` 0.1.0. Seeds 0 to 4. Diagnostic only: nothing here is on the wire. No number was tuned.

## What was run

The probe populates **every system of the play-area registry** (`data/starmap/stars.json`: 5,685 systems within 25 pc, 81.5 ly, of Sol), measured and synthesised planets alike, with the same `worlds_model.systemFrom` that `census.populate` uses. For each preset in `sim/data/presets.ail` (lonely, scattered, stapledon, teeming) and each seed it reads the true state at the emitted time, the emission draws, and every gate of the ship's 30-day stop look through `evidence.stagesOf`. The `record:` rows count the records `evidence.observeTarget` actually makes, as a cross-check. Nothing was sampled: all 5,685 systems, about 11,600 planets per seed.

```sh
export PATH=$PWD/runtime/bin:$PATH
O=$(tools/observe_dev.sh path)
ailang run --quiet --bytecode --caps IO,FS --package-dir $O --entry funnel --args-json \
  '{"registry":"data/starmap/stars.json","planets":"data/planets/exoplanets.json","firstSeed":0,"seeds":5,<POSITION AND APERTURE>,"shellLy":60}' \
  $O/tools/evidence_probe.ail
```

| Run | `<POSITION AND APERTURE>` | Wall time (5 seeds, 4 presets) |
|---|---|---|
| Sol, the ship's suite | `"x":0,"y":0,"z":0,"year":0,"apertureM":10` | 43 s |
| alpha Centauri A (4.3 ly), the ship's suite | `"x":3.094521,"y":-3.015404,"z":-0.051608,"year":0,"apertureM":10` | 41 s |
| TRAPPIST-1 (40.6 ly), the ship's suite | `"x":7.742,"y":20.946483,"z":-33.930598,"year":0,"apertureM":10` | 45 s |
| **What-if:** Sol, 30 m telescope | `"x":0,"y":0,"z":0,"year":0,"apertureM":30` | 44 s |
| **What-if:** Sol, 100 m telescope | `"x":0,"y":0,"z":0,"year":0,"apertureM":100` | 48 s |

Cells are **mean (min-max) over the five seeds**. The other positions use year 0 too: they show what the instruments would record from there, not a voyage (no travel time is added).

**Limits of the measurement.**
- **There is no 170 ly shell.** The registry the worlds model populates ends at 81.5 ly. The dish's radar reach (168 ly, OB-51) is larger than the play area, so "inside the dish's reach" is every radar-class world the registry holds. The tables give two shells: within 60 ly of the ship, and the whole registry.
- The registry is a sphere around Sol. From 40 ly out, part of the ship's 60 ly neighbourhood lies outside it and is empty in this measurement.
- Ecocide and Transcended worlds are counted in their own truth row, not as living.
- The probe ran on the bytecode VM only; it was not repeated on the interpreter.

## Reading it in plain language

**What a player starting at Sol would see.** The map is not empty. After the first stop look the ledger holds, within 81.5 ly:

| Preset | Worlds truly alive | Worlds with an oxygen record | of which false positives (sterile) | Worlds with a red-edge record | Worlds with any biosignature record | Radio leakage records |
|---|---|---|---|---|---|---|
| lonely | 630.8 (587-704) | 22.4 (20-26) | 2.6 (0-4) | 10.8 (8-16) | 26.8 (23-31) | 0.0 (0-0) |
| scattered | 622.6 (581-696) | 38.8 (32-44) | 2.6 (0-4) | 28.2 (24-31) | 44.2 (37-51) | 0.0 (0-0) |
| stapledon | 589.2 (554-660) | 37.8 (32-42) | 2.6 (0-4) | 27.0 (24-30) | 43.0 (37-49) | 0.0 (0-0) |
| teeming | 887.6 (845-950) | 57.0 (49-63) | 2.2 (0-4) | 40.4 (35-45) | 62.8 (53-69) | 0.0 (0-0) |

- **Tens of candidates, not zero and not hundreds.** Roughly 25 to 60 worlds carry a biosignature record, most of them within 60 ly. The earlier count of zero (seed 0) covered only the 241 hosts with catalogued planets, so at that seed every one of them is a synthesised planet.
- **The ship reads about one living world in seventeen** (stapledon: 34 of 589). Life is common near Sol in every preset, the "Lonely" one included (about 630 living worlds within 81.5 ly, about 200 of them complex).
- **No minds.** In 20 preset-seed runs there is not one Technological or PreTech world in the registry, and at most one Remnant. The radio dish records nothing, and that is the truth, not the dish: its radar reach covers the whole play area.
- **The nearest living world is 4 to 10 ly away** in every preset and seed (the last table of each raw output). In several seeds it is at 4.2 ly, Proxima's distance, and shows oxygen, yet it is not among the records.
- **Dead worlds are near too.** Under stapledon about 42 worlds within 81.5 ly are Ecocide or Transcended (teeming: about 120), while none is Technological now.

## Where the worlds are lost (Sol, the ship's suite, whole registry)

Causes marked "inferred" follow from the budgets but were not separately measured.

| Stage | lonely | scattered | stapledon | teeming | Cause of the loss at this stage |
|---|---|---|---|---|---|
| a. living at the emitted time | 630.8 (587-704) | 622.6 (581-696) | 589.2 (554-660) | 887.6 (845-950) | (the truth) |
| b. shows oxygen | 309.4 (273-343) | 563.8 (523-626) | 532.0 (498-592) | 799.4 (758-849) | the emission draw. A microbial world shows oxygen 3 times in 10 (belief table); lonely loses half here because most of its life is microbial, the other presets about a tenth |
| c. outside the inner working angle | 37.2 (30-43) | 66.2 (59-69) | 61.8 (57-65) | 97.4 (88-110) | **the biggest loss, about 88 %.** The planet is closer to its star than 55 mas (OB-22). Inferred: these are mostly M-dwarf habitable-zone planets, and Sun-like systems beyond 59 ly (OB-24) |
| c. and above the noise floor | 27.4 (20-32) | 50.0 (41-54) | 46.2 (39-49) | 70.0 (60-83) | contrast below 2.5e-11 (OB-6). Inferred: Earth-sized planets on wide orbits |
| d. SNR 5 in the 30-day look (an oxygen record) | 19.8 (16-24) | 36.2 (32-40) | 34.0 (31-37) | 51.8 (43-61) | photons: the 30-day look is too short |
| d. SNR 10 (strong) | 11.0 (10-13) | 19.8 (16-24) | 19.4 (16-24) | 27.6 (25-31) | photons |
| c'. instead, in transit as seen from Sol | 3.2 (2-5) | 6.4 (4-8) | 6.2 (4-7) | 8.8 (7-11) | geometry: about 1 orbit in 85 is edge-on enough |
| c'. transit seen (a census record, no spectrum) | 2.0 (1-4) | 4.4 (1-7) | 4.4 (1-7) | 5.8 (3-8) | no whole orbit inside the look, or photon noise |
| e. Technological | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | none exists in the registry at year 0 |
| e. radar class, inside the dish's reach | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | (nothing to lose) |
| e. inside the TV-carrier reach | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | (nothing to lose) |

The single biggest cause at each stage: **(a to b)** microbial worlds that show no oxygen; **(b to c)** the inner working angle; **(c to d)** integration time; **(e)** there are no technological worlds in the play area to hear.

## Does moving change it? (stapledon, whole registry)

| stage | from Sol | from alpha Centauri A | from TRAPPIST-1 |
|---|---|---|---|
| truth: living (Microbial or better) | 589.2 (554-660) | 589.2 (554-660) | 587.0 (551-659) |
| living, shows oxygen (O2, with or without CH4) | 532.0 (498-592) | 532.0 (498-592) | 530.0 (495-591) |
| living + oxygen: outside the inner working angle | 61.8 (57-65) | 63.4 (58-68) | 55.2 (53-58) |
| living + oxygen: outside it and above the noise floor | 46.2 (39-49) | 47.8 (40-51) | 39.6 (36-43) |
| living + oxygen: imaged at SNR >= 5 (an oxygen record) | 34.0 (31-37) | 35.6 (32-39) | 28.0 (24-31) |
| living + oxygen: imaged at SNR >= 10 | 19.4 (16-24) | 20.2 (16-26) | 15.4 (13-18) |
| living + oxygen: orbit transits as seen from here | 6.2 (4-7) | 4.8 (4-6) | 6.4 (5-9) |
| living + oxygen: transit seen (census record only) | 4.4 (1-7) | 3.2 (1-6) | 3.2 (2-4) |
| truth: Technological | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| record: planets imaged | 356.2 (328-377) | 355.6 (333-378) | 296.4 (276-305) |
| record: planets seen in transit | 282.6 (263-294) | 253.6 (235-276) | 228.0 (203-245) |
| record: oxygen detections, all worlds | 37.8 (32-42) | 40.2 (33-45) | 30.2 (26-35) |
| record: worlds with a biosignature or leakage detection | 43.0 (37-49) | 45.8 (39-53) | 35.4 (30-40) |

Moving 4 ly changes nothing that matters. From 40 ly out the count is a little lower (28 living worlds read, against 34). The registry's edge accounts for at least part of that: 3868.6 (3812-3947) populated planets lie within 60 ly of TRAPPIST-1, against 4641.8 (4582-4708) around Sol. The probe did not measure how many of the worlds read from there are different worlds from those read from Sol.

## What-ifs (probe only; `shipSuite()` is unchanged)

**These are not the ship's instruments.** The aperture what-ifs change the telescope's diameter and nothing else. The transit-spectrum row is a crude upper bound: it supposes the spectrum of a transiting planet could be read at the direct-imaging continuum SNR with the inner working angle and the noise floor ignored. A proper transit-spectroscopy budget is being added to the registry separately.

| stage (stapledon, whole registry, from Sol) | 10 m (the ship) | WHAT-IF 30 m | WHAT-IF 100 m |
|---|---|---|---|
| living, shows oxygen (O2, with or without CH4) | 532.0 (498-592) | 532.0 (498-592) | 532.0 (498-592) |
| living + oxygen: outside the inner working angle | 61.8 (57-65) | 192.4 (176-205) | 362.8 (342-411) |
| living + oxygen: outside it and above the noise floor | 46.2 (39-49) | 176.8 (162-186) | 347.2 (324-392) |
| living + oxygen: imaged at SNR >= 5 (an oxygen record) | 34.0 (31-37) | 176.8 (162-186) | 347.2 (324-392) |
| living + oxygen: imaged at SNR >= 10 | 19.4 (16-24) | 176.6 (162-185) | 347.2 (324-392) |
| WHAT-IF transit spectrum: living + oxygen, transit seen, continuum SNR >= 5 with the working angle and noise floor ignored | 0.4 (0-1) | 4.4 (1-7) | 4.4 (1-7) |
| record: planets imaged | 356.2 (328-377) | 2431.8 (2375-2476) | 6568.2 (6463-6697) |
| record: oxygen detections, all worlds | 37.8 (32-42) | 247.6 (234-261) | 797.4 (772-839) |
| record: oxygen detections on sterile worlds (false positives) | 2.6 (0-4) | 66.0 (62-71) | 441.4 (426-472) |
| record: red-edge detections, all worlds | 27.0 (24-30) | 141.2 (130-148) | 267.4 (249-298) |
| record: red-edge detections on sterile worlds (false positives) | 2.4 (1-5) | 24.8 (16-32) | 88.6 (81-102) |

- A 30 m telescope reads about five times as many living worlds (177 against 34) and a 100 m one ten times (347): the inner working angle shrinks with aperture.
- **Bigger telescopes bring false positives with them.** At 100 m more than half of the oxygen records are on sterile worlds (441 of 797).
- **Reading spectra in transit would add almost nothing under this bound**: under one world at 10 m, about four at 30 m or 100 m. The limit is geometry: about 6 living oxygen worlds in the registry transit as seen from Sol.

## Sanity checks

1. **Living worlds exist near Sol.** In every preset and seed the nearest living world is between 4.2 and 10.3 ly away, and there are 215 to 383 living worlds within 60 ly.
2. **The code path does produce oxygen records.** `sim/evidence_test.ail`, test "sanity: a living Earth twin at 10 pc gives a strong oxygen record in the 30-day stop look", places an Earth twin of a Sun twin at 10 pc and gets strong planet, oxygen-methane and red-edge records through `observeAtStop` with the ship's suite (`make evidence-test`: 20 passed).
3. **The funnel and the ledger agree.** For lonely, scattered and stapledon the mean oxygen records are within 1.2 of the living worlds imaged at SNR 5 plus the sterile false positives; teeming has about 3 more. The remainder is consistent with Ecocide or Transcended worlds that still show oxygen (the belief table gives them a chance), which the probe does not count separately.

## Things to look at (nothing was tuned or changed)

- **The abiotic-oxygen draw applies to every rocky sterile planet**, not only to desiccated ones: `evidence.emissionAt` has no desiccation property, so it uses the belief table's Sterile value (0.20 around M dwarfs, 0.02 around FGK stars) for all of them. This is the likely reason false positives outnumber life at 100 m.
- **Every preset but lonely makes all life complex.** The minds dial also scales the complex-life fraction (`sunholo/worlds` `applyDial`), which saturates at 1: "Complex or better" equals "living" under scattered, stapledon and teeming.
- **No world in the play area is technological at year 0** under any preset in these 20 runs, so nothing in the registry exercises the radio path. The calibration's technological process (`sim/calibrate.ail`) is a separate synthetic population out to thousands of light-years; it is not in the play-area registry.
- **"Lonely" has about 630 living worlds within 81.5 ly.** This is the worlds baseline (the census already shows 634 biospheres at seed 0), stated here because the name suggests otherwise.

## Raw output of each run

### Sol, the ship's suite

evidence-probe: telescope coronagraph-10m (10.0 m), receiver dish-100m, look 30.0 days; from (0.0, 0.0, 0.0) ly at year 0.0; 5685 registry systems; seeds 0..4; cells are mean (min-max) over seeds

**Within 60.0 ly of the ship**

| stage | lonely | scattered | stapledon | teeming |
|---|---|---|---|---|
| planets populated (outside the ship's own system) | 4641.8 (4582-4708) | 4641.8 (4582-4708) | 4641.8 (4582-4708) | 4641.8 (4582-4708) |
| planets habitable or debated | 400.8 (385-435) | 400.8 (385-435) | 400.8 (385-435) | 400.8 (385-435) |
| truth: living (Microbial or better) | 250.6 (230-278) | 247.4 (226-277) | 235.6 (215-263) | 351.4 (336-383) |
| truth: Complex or better | 75.8 (69-94) | 247.4 (226-277) | 235.6 (215-263) | 351.4 (336-383) |
| truth: PreTech | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| truth: Technological | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| truth: Remnant | 0.0 (0-0) | 0.0 (0-0) | 0.2 (0-1) | 0.2 (0-1) |
| truth: Ecocide or Transcended | 0.2 (0-1) | 3.4 (1-6) | 15.2 (11-18) | 49.4 (34-56) |
| living, shows oxygen (O2, with or without CH4) | 124.6 (118-130) | 224.0 (206-250) | 213.4 (196-236) | 317.2 (304-338) |
| living, shows O2 + CH4 | 88.6 (76-97) | 170.6 (154-191) | 162.0 (145-180) | 238.0 (223-254) |
| living, shows the red edge | 37.2 (32-50) | 104.0 (94-108) | 98.8 (89-103) | 150.2 (140-161) |
| living + oxygen: star and planet sizes known | 124.6 (118-130) | 224.0 (206-250) | 213.4 (196-236) | 317.2 (304-338) |
| living + oxygen: outside the inner working angle | 21.6 (17-25) | 38.6 (35-41) | 36.2 (35-38) | 55.6 (50-62) |
| living + oxygen: outside it and above the noise floor | 18.2 (13-20) | 32.6 (28-37) | 30.4 (28-34) | 45.4 (39-52) |
| living + oxygen: imaged at SNR >= 5 (an oxygen record) | 16.4 (13-18) | 30.4 (28-33) | 28.8 (27-31) | 42.8 (37-49) |
| living + oxygen: imaged at SNR >= 10 | 11.0 (10-13) | 19.8 (16-24) | 19.4 (16-24) | 27.6 (25-31) |
| living + oxygen: orbit transits as seen from here | 1.8 (1-2) | 3.8 (2-6) | 3.6 (2-5) | 4.8 (3-6) |
| living + oxygen: transit seen (census record only) | 1.4 (1-2) | 3.0 (1-4) | 3.0 (1-4) | 4.0 (3-5) |
| WHAT-IF transit spectrum: living + oxygen, transit seen, continuum SNR >= 5 with the working angle and noise floor ignored | 0.2 (0-1) | 0.2 (0-1) | 0.2 (0-1) | 1.0 (0-2) |
| living (any): outside the inner working angle | 43.0 (39-47) | 42.8 (39-46) | 40.0 (37-44) | 62.0 (57-68) |
| living (any): imaged at SNR >= 5 | 33.8 (29-40) | 33.8 (29-40) | 32.0 (28-38) | 48.4 (43-54) |
| Technological: radar class (beam crosses the ship) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| Technological, radar class, inside the dish's hint reach | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| Technological, inside the dish's TV-carrier hint reach | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| record: planets imaged | 289.6 (265-303) | 289.6 (265-303) | 289.6 (265-303) | 289.6 (265-303) |
| record: planets seen in transit | 124.6 (113-141) | 124.6 (113-141) | 124.6 (113-141) | 124.6 (113-141) |
| record: oxygen detections, all worlds | 18.8 (17-22) | 32.8 (28-37) | 32.4 (28-36) | 47.4 (43-51) |
| record: oxygen detections on sterile worlds (false positives) | 2.4 (0-4) | 2.4 (0-4) | 2.4 (0-4) | 2.2 (0-4) |
| record: red-edge detections, all worlds | 9.0 (6-11) | 23.4 (20-27) | 22.6 (20-26) | 33.2 (31-38) |
| record: red-edge detections on sterile worlds (false positives) | 2.4 (1-5) | 2.4 (1-5) | 2.4 (1-5) | 1.4 (0-4) |
| record: leakage detections | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| record: worlds with a biosignature or leakage detection | 22.8 (19-27) | 37.2 (33-44) | 36.6 (33-43) | 52.0 (45-57) |

**Whole registry (25 pc, 81.5 ly, around Sol)**

| stage | lonely | scattered | stapledon | teeming |
|---|---|---|---|---|
| planets populated (outside the ship's own system) | 11647.2 (11515-11800) | 11647.2 (11515-11800) | 11647.2 (11515-11800) | 11647.2 (11515-11800) |
| planets habitable or debated | 1007.2 (951-1085) | 1007.2 (951-1085) | 1007.2 (951-1085) | 1007.2 (951-1085) |
| truth: living (Microbial or better) | 630.8 (587-704) | 622.6 (581-696) | 589.2 (554-660) | 887.6 (845-950) |
| truth: Complex or better | 197.4 (178-222) | 622.6 (581-696) | 589.2 (554-660) | 887.6 (845-950) |
| truth: PreTech | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| truth: Technological | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| truth: Remnant | 0.0 (0-0) | 0.0 (0-0) | 0.4 (0-1) | 0.4 (0-1) |
| truth: Ecocide or Transcended | 0.2 (0-1) | 8.4 (6-11) | 41.8 (33-47) | 119.6 (106-135) |
| living, shows oxygen (O2, with or without CH4) | 309.4 (273-343) | 563.8 (523-626) | 532.0 (498-592) | 799.4 (758-849) |
| living, shows O2 + CH4 | 229.0 (209-267) | 437.8 (410-495) | 412.4 (387-466) | 612.4 (582-656) |
| living, shows the red edge | 97.8 (88-114) | 265.0 (242-287) | 253.0 (231-272) | 384.6 (367-414) |
| living + oxygen: star and planet sizes known | 309.4 (273-343) | 563.8 (523-626) | 532.0 (498-592) | 799.4 (758-849) |
| living + oxygen: outside the inner working angle | 37.2 (30-43) | 66.2 (59-69) | 61.8 (57-65) | 97.4 (88-110) |
| living + oxygen: outside it and above the noise floor | 27.4 (20-32) | 50.0 (41-54) | 46.2 (39-49) | 70.0 (60-83) |
| living + oxygen: imaged at SNR >= 5 (an oxygen record) | 19.8 (16-24) | 36.2 (32-40) | 34.0 (31-37) | 51.8 (43-61) |
| living + oxygen: imaged at SNR >= 10 | 11.0 (10-13) | 19.8 (16-24) | 19.4 (16-24) | 27.6 (25-31) |
| living + oxygen: orbit transits as seen from here | 3.2 (2-5) | 6.4 (4-8) | 6.2 (4-7) | 8.8 (7-11) |
| living + oxygen: transit seen (census record only) | 2.0 (1-4) | 4.4 (1-7) | 4.4 (1-7) | 5.8 (3-8) |
| WHAT-IF transit spectrum: living + oxygen, transit seen, continuum SNR >= 5 with the working angle and noise floor ignored | 0.2 (0-1) | 0.4 (0-1) | 0.4 (0-1) | 1.0 (0-2) |
| living (any): outside the inner working angle | 74.8 (65-81) | 73.8 (65-79) | 68.8 (63-73) | 108.8 (97-121) |
| living (any): imaged at SNR >= 5 | 41.4 (34-47) | 41.0 (33-47) | 38.4 (32-44) | 59.0 (51-66) |
| Technological: radar class (beam crosses the ship) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| Technological, radar class, inside the dish's hint reach | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| Technological, inside the dish's TV-carrier hint reach | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| record: planets imaged | 356.2 (328-377) | 356.2 (328-377) | 356.2 (328-377) | 356.2 (328-377) |
| record: planets seen in transit | 282.6 (263-294) | 282.6 (263-294) | 282.6 (263-294) | 282.6 (263-294) |
| record: oxygen detections, all worlds | 22.4 (20-26) | 38.8 (32-44) | 37.8 (32-42) | 57.0 (49-63) |
| record: oxygen detections on sterile worlds (false positives) | 2.6 (0-4) | 2.6 (0-4) | 2.6 (0-4) | 2.2 (0-4) |
| record: red-edge detections, all worlds | 10.8 (8-16) | 28.2 (24-31) | 27.0 (24-30) | 40.4 (35-45) |
| record: red-edge detections on sterile worlds (false positives) | 2.4 (1-5) | 2.4 (1-5) | 2.4 (1-5) | 1.4 (0-4) |
| record: leakage detections | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| record: worlds with a biosignature or leakage detection | 26.8 (23-31) | 44.2 (37-51) | 43.0 (37-49) | 62.8 (53-69) |

**Nearest, light-years from the ship, per seed**

| preset | nearest living world | nearest living world showing oxygen | nearest Technological world | planets in the ship's own system (not observed remotely) |
|---|---|---|---|---|
| lonely | 8.3, 4.2, 9.7, 7.9, 4.2 | 8.3, 4.2, 10.3, 7.9, 11.4 | none, none, none, none, none | 0, 0, 0, 0, 0 |
| scattered | 8.3, 4.2, 9.7, 7.9, 4.2 | 8.3, 4.2, 9.7, 7.9, 7.9 | none, none, none, none, none | 0, 0, 0, 0, 0 |
| stapledon | 8.3, 4.2, 10.3, 7.9, 4.2 | 8.3, 4.2, 10.3, 7.9, 7.9 | none, none, none, none, none | 0, 0, 0, 0, 0 |
| teeming | 4.2, 4.2, 4.2, 4.2, 4.2 | 4.2, 4.2, 4.2, 4.2, 7.9 | none, none, none, none, none | 0, 0, 0, 0, 0 |

### alpha Centauri A, the ship's suite

evidence-probe: telescope coronagraph-10m (10.0 m), receiver dish-100m, look 30.0 days; from (3.094521, -3.015404, -0.051608) ly at year 0.0; 5685 registry systems; seeds 0..4; cells are mean (min-max) over seeds

**Within 60.0 ly of the ship**

| stage | lonely | scattered | stapledon | teeming |
|---|---|---|---|---|
| planets populated (outside the ship's own system) | 4672.0 (4620-4745) | 4672.0 (4620-4745) | 4672.0 (4620-4745) | 4672.0 (4620-4745) |
| planets habitable or debated | 403.4 (390-433) | 403.4 (390-433) | 403.4 (390-433) | 403.4 (390-433) |
| truth: living (Microbial or better) | 250.0 (234-277) | 247.0 (231-276) | 235.6 (221-263) | 352.6 (338-381) |
| truth: Complex or better | 76.0 (68-93) | 247.0 (231-276) | 235.6 (221-263) | 352.6 (338-381) |
| truth: PreTech | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| truth: Technological | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| truth: Remnant | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| truth: Ecocide or Transcended | 0.2 (0-1) | 3.2 (1-6) | 14.6 (10-19) | 50.8 (33-57) |
| living, shows oxygen (O2, with or without CH4) | 125.4 (120-133) | 223.8 (211-249) | 213.6 (200-236) | 318.6 (304-335) |
| living, shows O2 + CH4 | 89.6 (78-98) | 170.8 (159-192) | 162.6 (151-182) | 239.4 (219-253) |
| living, shows the red edge | 36.0 (30-48) | 101.8 (92-109) | 97.2 (87-105) | 149.6 (139-159) |
| living + oxygen: star and planet sizes known | 125.4 (120-133) | 223.8 (211-249) | 213.6 (200-236) | 318.6 (304-335) |
| living + oxygen: outside the inner working angle | 22.6 (19-27) | 40.6 (37-43) | 38.2 (36-40) | 57.8 (52-62) |
| living + oxygen: outside it and above the noise floor | 19.0 (15-21) | 33.6 (29-38) | 31.4 (28-36) | 46.4 (40-51) |
| living + oxygen: imaged at SNR >= 5 (an oxygen record) | 17.0 (15-18) | 31.4 (29-35) | 29.6 (28-33) | 44.0 (38-48) |
| living + oxygen: imaged at SNR >= 10 | 11.8 (10-14) | 21.0 (16-27) | 20.2 (16-26) | 28.4 (25-35) |
| living + oxygen: orbit transits as seen from here | 1.4 (0-3) | 2.2 (0-5) | 2.2 (0-5) | 3.0 (1-6) |
| living + oxygen: transit seen (census record only) | 0.6 (0-3) | 1.2 (0-5) | 1.2 (0-5) | 1.4 (0-5) |
| WHAT-IF transit spectrum: living + oxygen, transit seen, continuum SNR >= 5 with the working angle and noise floor ignored | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| living (any): outside the inner working angle | 45.2 (41-48) | 45.0 (41-47) | 42.2 (40-44) | 64.6 (59-70) |
| living (any): imaged at SNR >= 5 | 35.0 (31-40) | 35.0 (31-40) | 33.0 (30-37) | 49.8 (44-54) |
| Technological: radar class (beam crosses the ship) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| Technological, radar class, inside the dish's hint reach | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| Technological, inside the dish's TV-carrier hint reach | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| record: planets imaged | 286.8 (271-304) | 286.8 (271-304) | 286.8 (271-304) | 286.8 (271-304) |
| record: planets seen in transit | 105.2 (92-129) | 105.2 (92-129) | 105.2 (92-129) | 105.2 (92-129) |
| record: oxygen detections, all worlds | 20.4 (18-23) | 34.8 (29-39) | 34.0 (29-37) | 48.8 (45-51) |
| record: oxygen detections on sterile worlds (false positives) | 3.4 (0-6) | 3.4 (0-6) | 3.4 (0-6) | 2.6 (0-5) |
| record: red-edge detections, all worlds | 8.8 (7-11) | 23.6 (21-27) | 22.6 (21-25) | 32.8 (31-36) |
| record: red-edge detections on sterile worlds (false positives) | 2.4 (1-5) | 2.4 (1-5) | 2.4 (1-5) | 1.2 (0-4) |
| record: leakage detections | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| record: worlds with a biosignature or leakage detection | 24.4 (23-29) | 39.2 (34-47) | 38.4 (34-45) | 53.4 (48-56) |

**Whole registry (25 pc, 81.5 ly, around Sol)**

| stage | lonely | scattered | stapledon | teeming |
|---|---|---|---|---|
| planets populated (outside the ship's own system) | 11643.4 (11511-11795) | 11643.4 (11511-11795) | 11643.4 (11511-11795) | 11643.4 (11511-11795) |
| planets habitable or debated | 1007.0 (951-1085) | 1007.0 (951-1085) | 1007.0 (951-1085) | 1007.0 (951-1085) |
| truth: living (Microbial or better) | 630.8 (587-704) | 622.6 (581-696) | 589.2 (554-660) | 887.4 (845-950) |
| truth: Complex or better | 197.4 (178-222) | 622.6 (581-696) | 589.2 (554-660) | 887.4 (845-950) |
| truth: PreTech | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| truth: Technological | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| truth: Remnant | 0.0 (0-0) | 0.0 (0-0) | 0.4 (0-1) | 0.4 (0-1) |
| truth: Ecocide or Transcended | 0.2 (0-1) | 8.4 (6-11) | 41.8 (33-47) | 119.6 (106-135) |
| living, shows oxygen (O2, with or without CH4) | 309.4 (273-343) | 563.8 (523-626) | 532.0 (498-592) | 799.2 (758-849) |
| living, shows O2 + CH4 | 229.0 (209-267) | 437.8 (410-495) | 412.4 (387-466) | 612.2 (582-656) |
| living, shows the red edge | 97.8 (88-114) | 265.0 (242-287) | 253.0 (231-272) | 384.4 (367-414) |
| living + oxygen: star and planet sizes known | 309.4 (273-343) | 563.8 (523-626) | 532.0 (498-592) | 799.2 (758-849) |
| living + oxygen: outside the inner working angle | 37.8 (30-45) | 67.6 (61-72) | 63.4 (58-68) | 99.6 (90-112) |
| living + oxygen: outside it and above the noise floor | 28.0 (22-33) | 51.4 (43-55) | 47.8 (40-51) | 72.2 (62-85) |
| living + oxygen: imaged at SNR >= 5 (an oxygen record) | 20.6 (18-24) | 37.8 (33-42) | 35.6 (32-39) | 54.0 (45-61) |
| living + oxygen: imaged at SNR >= 10 | 11.8 (10-14) | 21.0 (16-27) | 20.2 (16-26) | 28.4 (25-35) |
| living + oxygen: orbit transits as seen from here | 3.0 (1-4) | 5.0 (4-7) | 4.8 (4-6) | 7.6 (6-9) |
| living + oxygen: transit seen (census record only) | 1.8 (1-3) | 3.2 (1-6) | 3.2 (1-6) | 3.8 (3-5) |
| WHAT-IF transit spectrum: living + oxygen, transit seen, continuum SNR >= 5 with the working angle and noise floor ignored | 0.2 (0-1) | 0.2 (0-1) | 0.2 (0-1) | 0.2 (0-1) |
| living (any): outside the inner working angle | 76.6 (67-82) | 75.6 (67-80) | 70.8 (64-75) | 111.4 (99-124) |
| living (any): imaged at SNR >= 5 | 43.4 (37-49) | 43.0 (36-49) | 40.4 (35-45) | 61.6 (53-68) |
| Technological: radar class (beam crosses the ship) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| Technological, radar class, inside the dish's hint reach | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| Technological, inside the dish's TV-carrier hint reach | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| record: planets imaged | 355.6 (333-378) | 355.6 (333-378) | 355.6 (333-378) | 355.6 (333-378) |
| record: planets seen in transit | 253.6 (235-276) | 253.6 (235-276) | 253.6 (235-276) | 253.6 (235-276) |
| record: oxygen detections, all worlds | 24.2 (21-27) | 41.4 (33-48) | 40.2 (33-45) | 59.4 (52-63) |
| record: oxygen detections on sterile worlds (false positives) | 3.6 (0-6) | 3.6 (0-6) | 3.6 (0-6) | 2.6 (0-5) |
| record: red-edge detections, all worlds | 10.8 (7-16) | 29.0 (26-33) | 27.6 (26-31) | 40.6 (36-45) |
| record: red-edge detections on sterile worlds (false positives) | 2.4 (1-5) | 2.4 (1-5) | 2.4 (1-5) | 1.2 (0-4) |
| record: leakage detections | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| record: worlds with a biosignature or leakage detection | 28.6 (25-33) | 47.0 (39-56) | 45.8 (39-53) | 65.2 (57-70) |

**Nearest, light-years from the ship, per seed**

| preset | nearest living world | nearest living world showing oxygen | nearest Technological world | planets in the ship's own system (not observed remotely) |
|---|---|---|---|---|
| lonely | 10.4, 0.2, 8.1, 8.1, 0.2 | 10.4, 0.2, 9.4, 8.3, 14.4 | none, none, none, none, none | 2, 5, 5, 4, 3 |
| scattered | 10.4, 0.2, 8.1, 8.1, 0.2 | 10.4, 0.2, 8.1, 8.1, 8.1 | none, none, none, none, none | 2, 5, 5, 4, 3 |
| stapledon | 10.4, 0.2, 9.4, 8.1, 0.2 | 10.4, 0.2, 9.4, 8.1, 8.1 | none, none, none, none, none | 2, 5, 5, 4, 3 |
| teeming | 0.2, 0.2, 0.2, 0.2, 0.2 | 0.2, 0.2, 0.2, 0.2, 8.1 | none, none, none, none, none | 2, 5, 5, 4, 3 |

### TRAPPIST-1, the ship's suite

evidence-probe: telescope coronagraph-10m (10.0 m), receiver dish-100m, look 30.0 days; from (7.742, 20.946483, -33.930598) ly at year 0.0; 5685 registry systems; seeds 0..4; cells are mean (min-max) over seeds

**Within 60.0 ly of the ship**

| stage | lonely | scattered | stapledon | teeming |
|---|---|---|---|---|
| planets populated (outside the ship's own system) | 3868.6 (3812-3947) | 3868.6 (3812-3947) | 3868.6 (3812-3947) | 3868.6 (3812-3947) |
| planets habitable or debated | 334.0 (313-348) | 334.0 (313-348) | 334.0 (313-348) | 334.0 (313-348) |
| truth: living (Microbial or better) | 206.8 (196-223) | 203.6 (193-222) | 193.0 (181-213) | 294.0 (270-317) |
| truth: Complex or better | 62.6 (52-77) | 203.6 (193-222) | 193.0 (181-213) | 294.0 (270-317) |
| truth: PreTech | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| truth: Technological | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| truth: Remnant | 0.0 (0-0) | 0.0 (0-0) | 0.2 (0-1) | 0.2 (0-1) |
| truth: Ecocide or Transcended | 0.0 (0-0) | 3.2 (1-5) | 13.8 (10-20) | 40.0 (31-48) |
| living, shows oxygen (O2, with or without CH4) | 101.4 (92-115) | 183.8 (170-195) | 173.6 (161-186) | 264.8 (239-274) |
| living, shows O2 + CH4 | 73.2 (68-83) | 140.4 (134-149) | 132.2 (123-143) | 197.6 (191-206) |
| living, shows the red edge | 33.2 (27-43) | 92.4 (84-99) | 88.8 (79-95) | 133.4 (119-141) |
| living + oxygen: star and planet sizes known | 101.4 (92-115) | 183.8 (170-195) | 173.6 (161-186) | 264.8 (239-274) |
| living + oxygen: outside the inner working angle | 18.8 (16-24) | 35.2 (30-39) | 33.4 (28-37) | 51.2 (47-55) |
| living + oxygen: outside it and above the noise floor | 15.2 (10-20) | 28.6 (23-34) | 26.8 (21-32) | 40.8 (37-44) |
| living + oxygen: imaged at SNR >= 5 (an oxygen record) | 13.8 (10-17) | 26.6 (22-32) | 25.0 (20-30) | 39.2 (37-41) |
| living + oxygen: imaged at SNR >= 10 | 8.4 (5-11) | 16.4 (15-17) | 15.2 (13-17) | 25.0 (22-28) |
| living + oxygen: orbit transits as seen from here | 1.0 (0-3) | 2.0 (0-4) | 1.8 (0-3) | 4.0 (0-8) |
| living + oxygen: transit seen (census record only) | 0.8 (0-3) | 1.0 (0-3) | 0.8 (0-2) | 2.0 (0-5) |
| WHAT-IF transit spectrum: living + oxygen, transit seen, continuum SNR >= 5 with the working angle and noise floor ignored | 0.8 (0-3) | 1.0 (0-3) | 0.8 (0-2) | 1.6 (0-4) |
| living (any): outside the inner working angle | 38.6 (31-43) | 38.4 (31-43) | 36.4 (29-41) | 55.8 (52-58) |
| living (any): imaged at SNR >= 5 | 29.8 (23-36) | 29.6 (23-36) | 27.8 (21-34) | 43.4 (41-46) |
| Technological: radar class (beam crosses the ship) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| Technological, radar class, inside the dish's hint reach | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| Technological, inside the dish's TV-carrier hint reach | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| record: planets imaged | 244.4 (220-258) | 244.4 (220-258) | 244.4 (220-258) | 244.4 (220-258) |
| record: planets seen in transit | 71.6 (64-79) | 71.6 (64-79) | 71.6 (64-79) | 71.6 (64-79) |
| record: oxygen detections, all worlds | 15.4 (14-18) | 28.2 (23-34) | 27.2 (22-32) | 42.6 (39-46) |
| record: oxygen detections on sterile worlds (false positives) | 1.6 (0-4) | 1.6 (0-4) | 1.6 (0-4) | 1.4 (0-4) |
| record: red-edge detections, all worlds | 8.6 (5-11) | 22.2 (19-25) | 21.8 (18-25) | 31.2 (26-36) |
| record: red-edge detections on sterile worlds (false positives) | 2.6 (0-5) | 2.6 (0-5) | 2.6 (0-5) | 2.2 (0-5) |
| record: leakage detections | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| record: worlds with a biosignature or leakage detection | 19.2 (17-21) | 32.8 (29-37) | 31.8 (28-35) | 47.2 (45-49) |

**Whole registry (25 pc, 81.5 ly, around Sol)**

| stage | lonely | scattered | stapledon | teeming |
|---|---|---|---|---|
| planets populated (outside the ship's own system) | 11640.2 (11508-11793) | 11640.2 (11508-11793) | 11640.2 (11508-11793) | 11640.2 (11508-11793) |
| planets habitable or debated | 1004.2 (948-1082) | 1004.2 (948-1082) | 1004.2 (948-1082) | 1004.2 (948-1082) |
| truth: living (Microbial or better) | 628.6 (584-703) | 620.4 (578-695) | 587.0 (551-659) | 885.0 (842-947) |
| truth: Complex or better | 196.4 (176-221) | 620.4 (578-695) | 587.0 (551-659) | 885.0 (842-947) |
| truth: PreTech | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| truth: Technological | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| truth: Remnant | 0.0 (0-0) | 0.0 (0-0) | 0.4 (0-1) | 0.4 (0-1) |
| truth: Ecocide or Transcended | 0.2 (0-1) | 8.4 (6-11) | 41.8 (33-47) | 119.2 (106-135) |
| living, shows oxygen (O2, with or without CH4) | 308.4 (271-342) | 561.8 (520-625) | 530.0 (495-591) | 797.0 (755-846) |
| living, shows O2 + CH4 | 228.0 (207-266) | 436.2 (408-494) | 410.8 (385-465) | 610.2 (579-653) |
| living, shows the red edge | 97.6 (88-114) | 264.4 (241-286) | 252.4 (230-271) | 384.2 (366-413) |
| living + oxygen: star and planet sizes known | 308.4 (271-342) | 561.8 (520-625) | 530.0 (495-591) | 797.0 (755-846) |
| living + oxygen: outside the inner working angle | 33.0 (27-43) | 59.4 (56-63) | 55.2 (53-58) | 86.2 (82-90) |
| living + oxygen: outside it and above the noise floor | 23.2 (18-31) | 43.2 (38-47) | 39.6 (36-43) | 58.8 (54-63) |
| living + oxygen: imaged at SNR >= 5 (an oxygen record) | 15.6 (13-18) | 29.8 (26-33) | 28.0 (24-31) | 43.2 (41-45) |
| living + oxygen: imaged at SNR >= 10 | 8.4 (5-11) | 16.6 (15-18) | 15.4 (13-18) | 25.2 (22-28) |
| living + oxygen: orbit transits as seen from here | 3.6 (2-5) | 6.6 (5-9) | 6.4 (5-9) | 9.2 (4-14) |
| living + oxygen: transit seen (census record only) | 2.4 (1-4) | 3.4 (2-4) | 3.2 (2-4) | 4.6 (2-6) |
| WHAT-IF transit spectrum: living + oxygen, transit seen, continuum SNR >= 5 with the working angle and noise floor ignored | 0.8 (0-3) | 1.0 (0-3) | 0.8 (0-2) | 1.6 (0-4) |
| living (any): outside the inner working angle | 66.8 (62-70) | 66.0 (62-70) | 61.4 (60-66) | 95.6 (89-101) |
| living (any): imaged at SNR >= 5 | 33.4 (27-38) | 33.2 (27-38) | 31.2 (25-36) | 47.8 (44-50) |
| Technological: radar class (beam crosses the ship) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| Technological, radar class, inside the dish's hint reach | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| Technological, inside the dish's TV-carrier hint reach | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| record: planets imaged | 296.4 (276-305) | 296.4 (276-305) | 296.4 (276-305) | 296.4 (276-305) |
| record: planets seen in transit | 228.0 (203-245) | 228.0 (203-245) | 228.0 (203-245) | 228.0 (203-245) |
| record: oxygen detections, all worlds | 17.2 (15-19) | 31.4 (27-35) | 30.2 (26-35) | 46.6 (45-49) |
| record: oxygen detections on sterile worlds (false positives) | 1.6 (0-4) | 1.6 (0-4) | 1.6 (0-4) | 1.4 (0-4) |
| record: red-edge detections, all worlds | 8.8 (6-11) | 24.4 (19-29) | 24.0 (18-29) | 34.4 (31-38) |
| record: red-edge detections on sterile worlds (false positives) | 2.8 (1-5) | 2.8 (1-5) | 2.8 (1-5) | 2.4 (1-5) |
| record: leakage detections | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| record: worlds with a biosignature or leakage detection | 21.2 (19-24) | 36.6 (31-40) | 35.4 (30-40) | 51.8 (50-54) |

**Nearest, light-years from the ship, per seed**

| preset | nearest living world | nearest living world showing oxygen | nearest Technological world | planets in the ship's own system (not observed remotely) |
|---|---|---|---|---|
| lonely | 8.3, 12.2, 12.2, 8.3, 7.9 | 19.6, 12.2, 18.6, 8.3, 12.3 | none, none, none, none, none | 7, 7, 7, 7, 7 |
| scattered | 8.3, 12.2, 12.2, 8.3, 7.9 | 8.3, 12.2, 12.2, 8.3, 7.9 | none, none, none, none, none | 7, 7, 7, 7, 7 |
| stapledon | 8.3, 12.2, 12.2, 8.3, 7.9 | 8.3, 12.2, 12.2, 8.3, 7.9 | none, none, none, none, none | 7, 7, 7, 7, 7 |
| teeming | 8.3, 12.2, 12.2, 7.5, 7.9 | 8.3, 12.2, 12.2, 7.5, 7.9 | none, none, none, none, none | 7, 7, 7, 7, 7 |

### WHAT-IF: Sol, 30 m telescope

evidence-probe: WHAT-IF telescope WHAT-IF-coronagraph-30.0m (30.0 m), receiver dish-100m, look 30.0 days; from (0.0, 0.0, 0.0) ly at year 0.0; 5685 registry systems; seeds 0..4; cells are mean (min-max) over seeds

**Within 60.0 ly of the ship**

| stage | lonely | scattered | stapledon | teeming |
|---|---|---|---|---|
| planets populated (outside the ship's own system) | 4641.8 (4582-4708) | 4641.8 (4582-4708) | 4641.8 (4582-4708) | 4641.8 (4582-4708) |
| planets habitable or debated | 400.8 (385-435) | 400.8 (385-435) | 400.8 (385-435) | 400.8 (385-435) |
| truth: living (Microbial or better) | 250.6 (230-278) | 247.4 (226-277) | 235.6 (215-263) | 351.4 (336-383) |
| truth: Complex or better | 75.8 (69-94) | 247.4 (226-277) | 235.6 (215-263) | 351.4 (336-383) |
| truth: PreTech | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| truth: Technological | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| truth: Remnant | 0.0 (0-0) | 0.0 (0-0) | 0.2 (0-1) | 0.2 (0-1) |
| truth: Ecocide or Transcended | 0.2 (0-1) | 3.4 (1-6) | 15.2 (11-18) | 49.4 (34-56) |
| living, shows oxygen (O2, with or without CH4) | 124.6 (118-130) | 224.0 (206-250) | 213.4 (196-236) | 317.2 (304-338) |
| living, shows O2 + CH4 | 88.6 (76-97) | 170.6 (154-191) | 162.0 (145-180) | 238.0 (223-254) |
| living, shows the red edge | 37.2 (32-50) | 104.0 (94-108) | 98.8 (89-103) | 150.2 (140-161) |
| living + oxygen: star and planet sizes known | 124.6 (118-130) | 224.0 (206-250) | 213.4 (196-236) | 317.2 (304-338) |
| living + oxygen: outside the inner working angle | 55.0 (47-62) | 96.0 (91-100) | 91.0 (87-98) | 134.0 (129-139) |
| living + oxygen: outside it and above the noise floor | 51.6 (45-57) | 90.0 (86-96) | 85.2 (80-94) | 123.8 (119-129) |
| living + oxygen: imaged at SNR >= 5 (an oxygen record) | 51.6 (45-57) | 90.0 (86-96) | 85.2 (80-94) | 123.8 (119-129) |
| living + oxygen: imaged at SNR >= 10 | 51.6 (45-57) | 90.0 (86-96) | 85.2 (80-94) | 123.8 (119-129) |
| living + oxygen: orbit transits as seen from here | 1.8 (1-2) | 3.8 (2-6) | 3.6 (2-5) | 4.8 (3-6) |
| living + oxygen: transit seen (census record only) | 1.4 (1-2) | 3.0 (1-4) | 3.0 (1-4) | 4.0 (3-5) |
| WHAT-IF transit spectrum: living + oxygen, transit seen, continuum SNR >= 5 with the working angle and noise floor ignored | 1.4 (1-2) | 3.0 (1-4) | 3.0 (1-4) | 4.0 (3-5) |
| living (any): outside the inner working angle | 106.4 (101-113) | 105.8 (101-111) | 99.8 (94-108) | 148.8 (141-159) |
| living (any): imaged at SNR >= 5 | 99.4 (93-108) | 99.0 (93-107) | 93.4 (86-104) | 137.8 (130-148) |
| Technological: radar class (beam crosses the ship) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| Technological, radar class, inside the dish's hint reach | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| Technological, inside the dish's TV-carrier hint reach | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| record: planets imaged | 1352.2 (1320-1377) | 1352.2 (1320-1377) | 1352.2 (1320-1377) | 1352.2 (1320-1377) |
| record: planets seen in transit | 124.6 (113-141) | 124.6 (113-141) | 124.6 (113-141) | 124.6 (113-141) |
| record: oxygen detections, all worlds | 102.6 (96-114) | 141.2 (138-143) | 138.6 (136-142) | 179.0 (174-187) |
| record: oxygen detections on sterile worlds (false positives) | 51.0 (46-57) | 51.0 (46-57) | 51.0 (46-57) | 47.8 (42-53) |
| record: red-edge detections, all worlds | 34.4 (30-39) | 68.2 (66-74) | 66.8 (64-71) | 91.6 (86-96) |
| record: red-edge detections on sterile worlds (false positives) | 14.8 (11-22) | 14.8 (11-22) | 14.8 (11-22) | 12.6 (9-19) |
| record: leakage detections | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| record: worlds with a biosignature or leakage detection | 118.4 (112-126) | 158.6 (154-166) | 156.4 (152-163) | 198.4 (191-214) |

**Whole registry (25 pc, 81.5 ly, around Sol)**

| stage | lonely | scattered | stapledon | teeming |
|---|---|---|---|---|
| planets populated (outside the ship's own system) | 11647.2 (11515-11800) | 11647.2 (11515-11800) | 11647.2 (11515-11800) | 11647.2 (11515-11800) |
| planets habitable or debated | 1007.2 (951-1085) | 1007.2 (951-1085) | 1007.2 (951-1085) | 1007.2 (951-1085) |
| truth: living (Microbial or better) | 630.8 (587-704) | 622.6 (581-696) | 589.2 (554-660) | 887.6 (845-950) |
| truth: Complex or better | 197.4 (178-222) | 622.6 (581-696) | 589.2 (554-660) | 887.6 (845-950) |
| truth: PreTech | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| truth: Technological | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| truth: Remnant | 0.0 (0-0) | 0.0 (0-0) | 0.4 (0-1) | 0.4 (0-1) |
| truth: Ecocide or Transcended | 0.2 (0-1) | 8.4 (6-11) | 41.8 (33-47) | 119.6 (106-135) |
| living, shows oxygen (O2, with or without CH4) | 309.4 (273-343) | 563.8 (523-626) | 532.0 (498-592) | 799.4 (758-849) |
| living, shows O2 + CH4 | 229.0 (209-267) | 437.8 (410-495) | 412.4 (387-466) | 612.4 (582-656) |
| living, shows the red edge | 97.8 (88-114) | 265.0 (242-287) | 253.0 (231-272) | 384.6 (367-414) |
| living + oxygen: star and planet sizes known | 309.4 (273-343) | 563.8 (523-626) | 532.0 (498-592) | 799.4 (758-849) |
| living + oxygen: outside the inner working angle | 114.2 (94-132) | 204.4 (185-220) | 192.4 (176-205) | 293.2 (269-311) |
| living + oxygen: outside it and above the noise floor | 104.4 (88-120) | 188.2 (171-200) | 176.8 (162-186) | 265.8 (242-284) |
| living + oxygen: imaged at SNR >= 5 (an oxygen record) | 104.4 (88-120) | 188.2 (171-200) | 176.8 (162-186) | 265.8 (242-284) |
| living + oxygen: imaged at SNR >= 10 | 104.4 (88-120) | 188.0 (171-199) | 176.6 (162-185) | 265.6 (242-283) |
| living + oxygen: orbit transits as seen from here | 3.2 (2-5) | 6.4 (4-8) | 6.2 (4-7) | 8.8 (7-11) |
| living + oxygen: transit seen (census record only) | 2.0 (1-4) | 4.4 (1-7) | 4.4 (1-7) | 5.8 (3-8) |
| WHAT-IF transit spectrum: living + oxygen, transit seen, continuum SNR >= 5 with the working angle and noise floor ignored | 2.0 (1-4) | 4.4 (1-7) | 4.4 (1-7) | 5.8 (3-8) |
| living (any): outside the inner working angle | 229.0 (213-246) | 226.8 (212-242) | 213.6 (201-227) | 327.2 (304-348) |
| living (any): imaged at SNR >= 5 | 211.2 (195-226) | 209.2 (194-222) | 196.8 (184-208) | 298.0 (274-319) |
| Technological: radar class (beam crosses the ship) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| Technological, radar class, inside the dish's hint reach | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| Technological, inside the dish's TV-carrier hint reach | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| record: planets imaged | 2431.8 (2375-2476) | 2431.8 (2375-2476) | 2431.8 (2375-2476) | 2431.8 (2375-2476) |
| record: planets seen in transit | 282.8 (263-294) | 282.8 (263-294) | 282.8 (263-294) | 282.8 (263-294) |
| record: oxygen detections, all worlds | 170.4 (158-186) | 255.0 (241-266) | 247.6 (234-261) | 341.0 (321-362) |
| record: oxygen detections on sterile worlds (false positives) | 66.0 (62-71) | 66.0 (62-71) | 66.0 (62-71) | 61.0 (57-65) |
| record: red-edge detections, all worlds | 67.6 (60-74) | 144.6 (133-153) | 141.2 (130-148) | 198.8 (190-207) |
| record: red-edge detections on sterile worlds (false positives) | 24.8 (16-32) | 24.8 (16-32) | 24.8 (16-32) | 20.2 (14-28) |
| record: leakage detections | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| record: worlds with a biosignature or leakage detection | 200.0 (184-216) | 289.6 (278-305) | 283.2 (272-299) | 381.2 (367-406) |

**Nearest, light-years from the ship, per seed**

| preset | nearest living world | nearest living world showing oxygen | nearest Technological world | planets in the ship's own system (not observed remotely) |
|---|---|---|---|---|
| lonely | 8.3, 4.2, 9.7, 7.9, 4.2 | 8.3, 4.2, 10.3, 7.9, 11.4 | none, none, none, none, none | 0, 0, 0, 0, 0 |
| scattered | 8.3, 4.2, 9.7, 7.9, 4.2 | 8.3, 4.2, 9.7, 7.9, 7.9 | none, none, none, none, none | 0, 0, 0, 0, 0 |
| stapledon | 8.3, 4.2, 10.3, 7.9, 4.2 | 8.3, 4.2, 10.3, 7.9, 7.9 | none, none, none, none, none | 0, 0, 0, 0, 0 |
| teeming | 4.2, 4.2, 4.2, 4.2, 4.2 | 4.2, 4.2, 4.2, 4.2, 7.9 | none, none, none, none, none | 0, 0, 0, 0, 0 |

### WHAT-IF: Sol, 100 m telescope

evidence-probe: WHAT-IF telescope WHAT-IF-coronagraph-100.0m (100.0 m), receiver dish-100m, look 30.0 days; from (0.0, 0.0, 0.0) ly at year 0.0; 5685 registry systems; seeds 0..4; cells are mean (min-max) over seeds

**Within 60.0 ly of the ship**

| stage | lonely | scattered | stapledon | teeming |
|---|---|---|---|---|
| planets populated (outside the ship's own system) | 4641.8 (4582-4708) | 4641.8 (4582-4708) | 4641.8 (4582-4708) | 4641.8 (4582-4708) |
| planets habitable or debated | 400.8 (385-435) | 400.8 (385-435) | 400.8 (385-435) | 400.8 (385-435) |
| truth: living (Microbial or better) | 250.6 (230-278) | 247.4 (226-277) | 235.6 (215-263) | 351.4 (336-383) |
| truth: Complex or better | 75.8 (69-94) | 247.4 (226-277) | 235.6 (215-263) | 351.4 (336-383) |
| truth: PreTech | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| truth: Technological | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| truth: Remnant | 0.0 (0-0) | 0.0 (0-0) | 0.2 (0-1) | 0.2 (0-1) |
| truth: Ecocide or Transcended | 0.2 (0-1) | 3.4 (1-6) | 15.2 (11-18) | 49.4 (34-56) |
| living, shows oxygen (O2, with or without CH4) | 124.6 (118-130) | 224.0 (206-250) | 213.4 (196-236) | 317.2 (304-338) |
| living, shows O2 + CH4 | 88.6 (76-97) | 170.6 (154-191) | 162.0 (145-180) | 238.0 (223-254) |
| living, shows the red edge | 37.2 (32-50) | 104.0 (94-108) | 98.8 (89-103) | 150.2 (140-161) |
| living + oxygen: star and planet sizes known | 124.6 (118-130) | 224.0 (206-250) | 213.4 (196-236) | 317.2 (304-338) |
| living + oxygen: outside the inner working angle | 94.4 (81-105) | 166.6 (154-189) | 158.2 (144-177) | 239.0 (223-253) |
| living + oxygen: outside it and above the noise floor | 91.0 (79-100) | 160.6 (147-181) | 152.4 (137-170) | 228.8 (212-243) |
| living + oxygen: imaged at SNR >= 5 (an oxygen record) | 91.0 (79-100) | 160.6 (147-181) | 152.4 (137-170) | 228.8 (212-243) |
| living + oxygen: imaged at SNR >= 10 | 91.0 (79-100) | 160.6 (147-181) | 152.4 (137-170) | 228.8 (212-243) |
| living + oxygen: orbit transits as seen from here | 1.8 (1-2) | 3.8 (2-6) | 3.6 (2-5) | 4.8 (3-6) |
| living + oxygen: transit seen (census record only) | 1.4 (1-2) | 3.0 (1-4) | 3.0 (1-4) | 4.0 (3-5) |
| WHAT-IF transit spectrum: living + oxygen, transit seen, continuum SNR >= 5 with the working angle and noise floor ignored | 1.4 (1-2) | 3.0 (1-4) | 3.0 (1-4) | 4.0 (3-5) |
| living (any): outside the inner working angle | 186.4 (175-211) | 184.0 (172-210) | 174.4 (162-198) | 264.6 (249-288) |
| living (any): imaged at SNR >= 5 | 179.4 (167-203) | 177.2 (164-202) | 168.0 (154-191) | 253.6 (237-277) |
| Technological: radar class (beam crosses the ship) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| Technological, radar class, inside the dish's hint reach | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| Technological, inside the dish's TV-carrier hint reach | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| record: planets imaged | 2972.0 (2898-3060) | 2972.0 (2898-3060) | 2972.0 (2898-3060) | 2972.0 (2898-3060) |
| record: planets seen in transit | 124.6 (113-141) | 124.6 (113-141) | 124.6 (113-141) | 124.6 (113-141) |
| record: oxygen detections, all worlds | 306.2 (285-328) | 376.2 (363-387) | 371.0 (360-381) | 440.0 (429-451) |
| record: oxygen detections on sterile worlds (false positives) | 215.0 (201-234) | 215.0 (201-234) | 215.0 (201-234) | 199.0 (187-210) |
| record: red-edge detections, all worlds | 71.0 (67-76) | 120.4 (110-134) | 118.2 (107-131) | 156.6 (144-174) |
| record: red-edge detections on sterile worlds (false positives) | 43.6 (30-53) | 43.6 (30-53) | 43.6 (30-53) | 39.6 (26-50) |
| record: leakage detections | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| record: worlds with a biosignature or leakage detection | 347.2 (329-365) | 419.2 (408-444) | 414.8 (406-437) | 486.4 (475-512) |

**Whole registry (25 pc, 81.5 ly, around Sol)**

| stage | lonely | scattered | stapledon | teeming |
|---|---|---|---|---|
| planets populated (outside the ship's own system) | 11647.2 (11515-11800) | 11647.2 (11515-11800) | 11647.2 (11515-11800) | 11647.2 (11515-11800) |
| planets habitable or debated | 1007.2 (951-1085) | 1007.2 (951-1085) | 1007.2 (951-1085) | 1007.2 (951-1085) |
| truth: living (Microbial or better) | 630.8 (587-704) | 622.6 (581-696) | 589.2 (554-660) | 887.6 (845-950) |
| truth: Complex or better | 197.4 (178-222) | 622.6 (581-696) | 589.2 (554-660) | 887.6 (845-950) |
| truth: PreTech | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| truth: Technological | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| truth: Remnant | 0.0 (0-0) | 0.0 (0-0) | 0.4 (0-1) | 0.4 (0-1) |
| truth: Ecocide or Transcended | 0.2 (0-1) | 8.4 (6-11) | 41.8 (33-47) | 119.6 (106-135) |
| living, shows oxygen (O2, with or without CH4) | 309.4 (273-343) | 563.8 (523-626) | 532.0 (498-592) | 799.4 (758-849) |
| living, shows O2 + CH4 | 229.0 (209-267) | 437.8 (410-495) | 412.4 (387-466) | 612.4 (582-656) |
| living, shows the red edge | 97.8 (88-114) | 265.0 (242-287) | 253.0 (231-272) | 384.6 (367-414) |
| living + oxygen: star and planet sizes known | 309.4 (273-343) | 563.8 (523-626) | 532.0 (498-592) | 799.4 (758-849) |
| living + oxygen: outside the inner working angle | 212.0 (183-245) | 384.2 (363-439) | 362.8 (342-411) | 548.6 (532-586) |
| living + oxygen: outside it and above the noise floor | 202.2 (177-233) | 368.0 (345-419) | 347.2 (324-392) | 521.2 (505-559) |
| living + oxygen: imaged at SNR >= 5 (an oxygen record) | 202.2 (177-233) | 368.0 (345-419) | 347.2 (324-392) | 521.2 (505-559) |
| living + oxygen: imaged at SNR >= 10 | 202.2 (177-233) | 368.0 (345-419) | 347.2 (324-392) | 521.2 (505-559) |
| living + oxygen: orbit transits as seen from here | 3.2 (2-5) | 6.4 (4-8) | 6.2 (4-7) | 8.8 (7-11) |
| living + oxygen: transit seen (census record only) | 2.0 (1-4) | 4.4 (1-7) | 4.4 (1-7) | 5.8 (3-8) |
| WHAT-IF transit spectrum: living + oxygen, transit seen, continuum SNR >= 5 with the working angle and noise floor ignored | 2.0 (1-4) | 4.4 (1-7) | 4.4 (1-7) | 5.8 (3-8) |
| living (any): outside the inner working angle | 430.4 (404-494) | 424.4 (400-488) | 401.2 (377-458) | 608.2 (590-656) |
| living (any): imaged at SNR >= 5 | 412.6 (385-474) | 406.8 (381-468) | 384.4 (358-439) | 579.0 (560-627) |
| Technological: radar class (beam crosses the ship) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| Technological, radar class, inside the dish's hint reach | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| Technological, inside the dish's TV-carrier hint reach | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| record: planets imaged | 6568.2 (6463-6697) | 6568.2 (6463-6697) | 6568.2 (6463-6697) | 6568.2 (6463-6697) |
| record: planets seen in transit | 282.8 (263-294) | 282.8 (263-294) | 282.8 (263-294) | 282.8 (263-294) |
| record: oxygen detections, all worlds | 643.8 (603-672) | 811.0 (781-853) | 797.4 (772-839) | 958.0 (932-996) |
| record: oxygen detections on sterile worlds (false positives) | 441.4 (426-472) | 441.4 (426-472) | 441.4 (426-472) | 411.2 (397-436) |
| record: red-edge detections, all worlds | 156.4 (145-168) | 272.8 (252-305) | 267.4 (249-298) | 355.8 (343-392) |
| record: red-edge detections on sterile worlds (false positives) | 88.6 (81-102) | 88.6 (81-102) | 88.6 (81-102) | 79.4 (71-94) |
| record: leakage detections | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) | 0.0 (0-0) |
| record: worlds with a biosignature or leakage detection | 729.6 (687-762) | 901.8 (870-960) | 889.8 (862-947) | 1057.4 (1032-1112) |

**Nearest, light-years from the ship, per seed**

| preset | nearest living world | nearest living world showing oxygen | nearest Technological world | planets in the ship's own system (not observed remotely) |
|---|---|---|---|---|
| lonely | 8.3, 4.2, 9.7, 7.9, 4.2 | 8.3, 4.2, 10.3, 7.9, 11.4 | none, none, none, none, none | 0, 0, 0, 0, 0 |
| scattered | 8.3, 4.2, 9.7, 7.9, 4.2 | 8.3, 4.2, 9.7, 7.9, 7.9 | none, none, none, none, none | 0, 0, 0, 0, 0 |
| stapledon | 8.3, 4.2, 10.3, 7.9, 4.2 | 8.3, 4.2, 10.3, 7.9, 7.9 | none, none, none, none, none | 0, 0, 0, 0, 0 |
| teeming | 4.2, 4.2, 4.2, 4.2, 4.2 | 4.2, 4.2, 4.2, 4.2, 7.9 | none, none, none, none, none | 0, 0, 0, 0, 0 |

