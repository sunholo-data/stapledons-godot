### Added

- The universe lab's statistics: averages with honest error bars, exact confidence intervals for the median and the 10th and 90th percentiles, and the rule that says whether a target is met, missed or still unsettled, so that no result is reported as settled before it is. Results run in batches of 64 seeds up to 1,024, and two scenarios can be compared seed by seed. Every number is checked against an independent reference written in a second language (R3-UNIVERSE-LAB UL3c, `sim/lab_stats.ail`, `tools/lab_stats_ref.py`, `make lab-test`). Nothing in the game uses it yet.
