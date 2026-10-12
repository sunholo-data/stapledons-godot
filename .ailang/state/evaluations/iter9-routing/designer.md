# M2 landing review (iteration 9, designer role)

**Verdict: APPROVE THE EXISTING DESIGN.** Nothing in the design blocks landing, and no new design is needed. What remains is the P5 golden review and recording the landing. Both are controller tasks.

I used no tools for this review. I did not run tests, open renders or check CI. Everything below comes from the source bundle you gave me.

## Why the design is ready

1. **Scope matches the bar.** Clause 2 reads: *"There is a versioned protocol; the journey planner matches the rocket equations to 1e-9; commits are irreversible and enforced by the simulation; a 10k-tick replay is byte-identical on the VM and the interpreter."* Each part maps to recorded ACs:
   - versioned protocol: AC8 and AC9
   - planner to 1e-9: AC2 and AC3
   - irreversible commit: AC7
   - 10k-tick replay: AC12 and AC16

   The sprint JSON records all ten features as `"passes": true`. The M2.5 and M2.6b evaluations both report `"result": "pass"`, `"score": 93`, with `"blocking": []`.
2. **No design questions are open.** The design doc says OQ1–6 are *"RESOLVED"* by D-11, D-12 and D-15. The sprint plan says *"No design question is open."* D-17 ratified the parameter ranges: *"These ranges were executor-chosen (M2.1a) and are ratified by Mark (D-17, 2026-10-02)."*
3. **Physics gate 2 does not apply.** The design doc says: *"M2 adds no shader and no visual of SR, so physics gate 2 does not apply; `make golden` and `make capture` must keep passing."* The forward CMB disc is a separate queue item, row 6a.
4. **The executors' deviations were accepted by the evaluators and written back into the design doc** under *"As implemented in M2.3a/M2.3b/M2.4/M2.6b"*. So the doc already describes what was built.

## Remaining landing gates

1. **P5 golden review.** The sprint plan says: *"Every committed golden is a reviewed diff from `make replay-record`, never regenerated inside `make test`. The evaluator checks each golden against an independent expectation: the arrival residuals, and the α Cen plan numbers from the design's check rows."*
   - **The goldens changed after M2.5 was evaluated.** The M2.5 evaluation reviewed goldens from CI run 36974675400. Since then, commit `b6efa8f` *"regenerate arm64 goldens for M2.6b's additive fields"* and commit `1567f84` *"x86_64 goldens regenerated on CI (run 36980886121)"* have replaced them. P5 must review the goldens as they stand at `6da03f8`.
   - The M2.5 evaluation also notes: *"x86_64 goldens were produced on a throwaway CI run and are not reproducible locally."*
   - The cases to review are listed in the evaluation's `goldens_for_P5`: alpha_cen, godot_map_voyage, offaxis_v11_equiv (one beta differs by 1 ulp between architectures, ailang#1465), diag_thrust600, and session10k/2k.
2. **AC16 on `main` in CI.** AC16 requires *"`make test` … locally and in CI"*. PR runs use only 2k ticks: *"`REPLAY_TICKS` to 2000 on PRs and 10000 on `main`"*. So the **10k gate is proven only by a green `main` run at the merge commit `6da03f8`**, and that run still needs confirming.
3. **Landing record.** CLAUDE.md step 5: *"Move the design doc to `design_docs/implemented/<release>/`, update the design repo's roadmap status, and add a changelog entry."* The sprint plan adds the design-repo note: *"add the `journey-system.md` superseded-maths note"*. Concretely:
   - Move `m2-journey-core.md` and `m2-journey-core-sprint.md` to `implemented/r1/`.
   - Promote `m2-report-draft.md` to `implemented/r1/m2-report.md`. The deliverable is *"(10k timings, residuals, the PRNG algorithm used, upstream reports)"*, and the plan notes: *"`m2-report.md` does not exist yet."*
   - Add the changelog entry. Both evaluations flag it as outstanding: *"no_changelog: ACCEPT; due at landing."*
   - In the design repo, set the roadmap M2 status and add the `journey-system.md` note.
4. **Bookkeeping.**
   - **Sprint JSON:** it still says `"status": "in_progress"`; set it to complete. It also has `"approved": null`. P0 approval is not recorded there, so either point to where Mark's approval is recorded or note the gap. Don't backfill it.
   - **Charter:** queue row 1 still reads *"[NEXT] **M2**"*, so mark it LANDED. Add an iteration 9 STATUS stamp recording that clause 2 is met, and move older stamps out under the 3-stamp rotation rule.

## Non-blocking cleanup for landing or follow-up

- **Stale toolchain text in the design doc.** It still says *"The AILANG pin is now **v0.50.0**"* and *"`$A` is the pinned v0.50.0"*, but the pin is v0.51.0. Its status line, *"Planned (… awaiting sprint plan)"*, also needs updating when the doc moves.
- **Upstream deliverable already done.** The design's *"bitwise operators unwired on the VM"* report is resolved: *"ailang#1450 fixed in the pin"*. The report should say so.
- **Carry-over from the M2.6b evaluation:**
  - The `check_star_names.py` mirrored-longitude dependency (*"change l_mirror to l … in the same PR as the catalogue fix"*).
  - `TRANSIT_RATE` and the transit format are not pinned by tests.
  - The hold timer takes an unclamped frame delta.
  - `make ui` can time out on a cold start.
- **Carry-over from the M2.5 evaluation:** *"The generated session input is not committed"*. Committing the 2k input, or a digest of it, would help P5 and M4 reviewers inspect it.
