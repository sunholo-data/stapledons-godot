### Infrastructure

- **Merges no longer wait on a per-PR rig run (Mark, 2026-11-03).** A PR merges on the fast tier, its
  targeted gates, the cross-family evaluation and, for anything visual or audible, Mark's OK on a dev
  build. The full `make test` + `make golden` runs once a night on main (`tools/rig_nightly.sh`, launchd
  `dev.stapledon.rig-nightly`), only when the GPU and CPU are idle, and files a `nightly-rig` issue when
  main goes red. Per-PR runs took about 70 minutes each, one at a time, and mostly failed on host load.
- `tools/rig_check.sh` deletes its clone when a run ends and keeps the log (41 kept clones had filled 40 GB);
  `RIG_KEEP=1` keeps it.
