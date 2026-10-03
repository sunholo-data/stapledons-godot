# Real-byte catalogue fixtures

Used by `sim/tools/extract_test.ail` (`make extract-test`), the AILANG port of the former
`tools/extract.py` tests. The fixtures are raw bytes cut straight out of the gitignored downloads in
`data/raw/`, never hand-typed or edited.

```
The fixtures in tools/fixtures/ are raw bytes cut straight out of the
gitignored downloads in data/raw/ - never hand-typed, never edited.  They were
produced by exactly these commands, from the repo root, after:

    bash .claude/skills/starmap-manager/scripts/download_stars.sh quick
    bash .claude/skills/starmap-manager/scripts/download_stars.sh medium

    # cns5.dat (VizieR J/A+A/670/A19, Lrecl 761, 5909 records)
    sed -n '1,20p' data/raw/cns5.dat > tools/fixtures/cns5_head.dat
    # alpha Cen: `grep -n 559 data/raw/cns5.dat | head` returns one row, line
    # 5103, CNS5=3627 GJ=559 Comp=AB - CNS5 carries the AB system, not separate
    # A/B rows (eyeballed against the ReadMe byte columns 1-4/6-11/13-16).
    sed -n '5103p' data/raw/cns5.dat > tools/fixtures/cns5_alpha_cen.dat
    # G present, BP blank, RP present (the one-sided-pair case)
    awk 'substr($0,362,10) ~ /[0-9]/ && substr($0,395,10) ~ /^ *$/ \
         && substr($0,428,10) ~ /[0-9]/' data/raw/cns5.dat | head -1 \
        > tools/fixtures/cns5_bp_blank_rp_set.dat
    # the single row with a blank parallax (CNS5=0, a placeholder record)
    awk 'substr($0,130,19) ~ /^ *$/' data/raw/cns5.dat \
        > tools/fixtures/cns5_null_plx.dat

    # table1c.dat (VizieR J/A+A/649/A6, Lrecl 760, 331312 records)
    sed -n '1,20p' data/raw/table1c.dat > tools/fixtures/gcns_head.dat
    awk 'substr($0,246,5)+0 > 0.5' data/raw/table1c.dat | head -1 \
        > tools/fixtures/gcns_wd.dat                    # WDprob 0.924 -> wd=1
    awk 'substr($0,246,5) == "1.000"' data/raw/table1c.dat | head -1 \
        > tools/fixtures/gcns_wd_1p000.dat              # WDprob 1.000 -> wd=1
    awk 'substr($0,246,5)+0 == 0.5' data/raw/table1c.dat | head -1 \
        > tools/fixtures/gcns_wdprob_050.dat            # WDprob 0.500 -> wd=0
    awk 'substr($0,246,5)+0 > 0.5 && substr($0,246,5)+0 <= 0.509' \
        data/raw/table1c.dat | head -1 \
        > tools/fixtures/gcns_wdprob_0506.dat           # WDprob 0.506 -> wd=1
    awk 'substr($0,123,8) ~ /^ *$/' data/raw/table1c.dat | head -1 \
        > tools/fixtures/gcns_missing_phot.dat          # blank Gmag, blank BP

The awk field numbers above are 1-based byte columns, i.e. the ReadMe's own
byte numbers; sim/tools/extract.ail converts them to 0-based half-open substrings.

Measured expectations (2026-09-28, planner's task-1 evidence reproduced
byte-for-byte):
  * A19 ReadMe 200 / 10530 B / cns5.dat Lrecl 761 Records 5909
```

## M1.2d bright tier (`sim/tools/bright_test.ail`, `make bright-test`)

Cut the same way (raw lines, never edited) after `download_stars.sh quick` and `download_stars.sh bright`.
`bright_test.ail` inlines the same lines, and `brightFixtures` fails if the files and the inline copies differ.

```
# HIP2 (VizieR I/311 hip2.dat.gz, Lrecl 276): Aldebaran, Rigel, Sirius, Groombridge 1830,
# Arcturus, alpha Cen B, alpha Cen A, Vega (HIP is bytes 1-6)
for h in 24436 32349 57939 69673 71681 71683 91262 21421; do
  gunzip -c data/raw/hip2.dat.gz | awk -v h=$h 'substr($0,1,6)+0==h'; done > tools/fixtures/hip2_bright.dat
# hip_main (VizieR I/239 hip_main.dat, Lrecl 450; HIP is bytes 9-14), same stars
for h in 21421 24436 32349 57939 69673 71681 71683 91262; do
  awk -v h=$h 'substr($0,9,6)+0==h' data/raw/hip_main.dat; done > tools/fixtures/hip_main_bright.dat
# CNS5 (cns5.dat): Aldebaran A/B (both HIP 21421), Sirius B/A, Groombridge 1830, Arcturus,
# alpha Cen AB, Vega (designation is bytes 1-4)
for d in 1142 1143 1675 1676 2914 3517 3627 4607; do
  awk -v d=$d 'substr($0,1,4)+0==d' data/raw/cns5.dat; done > tools/fixtures/cns5_bright.dat
```

## Companion rule (`sim/tools/companions_test.ail`, `make companions-test`)

Cut the same way after `make catalogue-inputs`. `companions_test.ail` inlines these lines plus the
Sirius, alpha Cen lines of the bright fixtures above, and `companionsFixtures` fails if the files and
the inline copies differ.

```
# CNS5: Luyten 726-8 A/B (GJ 65), Wolf 424 A/B (GJ 473), GJ 604 (the GCNS false pair's
# foreground star), GJ 13207 / GJ 13208 (a false pair: 102 arcsec, parallaxes 87% apart)
for d in 424 425 3092 3093 3925 5485 5486 252; do
  awk -v d=$d 'substr($0,1,4)+0==d' data/raw/cns5.dat; done > tools/fixtures/cns5_companions.dat
# (252 is GJ 10136, a CNS5 row without a Gaia id: the same star as GCNS 2371519626175864960)
# GCNS (J/A+A/649/A6 table1c.dat.gz, Lrecl 760; source_id bytes 3-21), in file order: GJ 10136's and
# HD 40409's own Gaia sources (cross-identifications), Luyten 726-8 A and B (EDR3 rows: the GCNS-tier
# root move), GJ 604 and the background star 43 arcsec from it at 307 ly (a false pair)
gunzip -c data/raw/table1c.dat.gz | awk '{id=substr($0,3,19)} id=="5994771079533026688"||id=="5994771148252505216"||
  id=="2371519626175864960"||id=="4756622820871136640"||id=="5140693571158739840"||id=="5140693571158946048"' \
  > tools/fixtures/table1c_companions.dat
# HIP 27890 (HD 40409), a bright row 1.03 arcsec from its own Gaia source
gunzip -c data/raw/hip2.dat.gz | awk 'substr($0,1,6)+0==27890' > tools/fixtures/hip2_companions.dat
awk 'substr($0,9,6)+0==27890' data/raw/hip_main.dat > tools/fixtures/hip_main_companions.dat
```
