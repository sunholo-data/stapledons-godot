### Fixed

`make sim-pipeline-test` (pipelined heartbeats end byte-identical to synchronous
ones) was red since `b42fc0e3`. The test's two runs shared CrewConsole's
process-wide offer-id counter, so they sent different offers. Each run now starts
the counter afresh. The gate goes through `$(SCRIPT_GATE)` with a counted
summary; joining the nightly waits for a timing measurement under the nightly's
idle conditions (row 7ab).
