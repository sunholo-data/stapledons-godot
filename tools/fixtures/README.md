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
