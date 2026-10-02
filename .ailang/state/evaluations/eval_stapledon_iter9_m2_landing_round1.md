# Independent evaluation: M2 landing and P5 supplement (iteration 9, round 1)

- Judge: Anthropic claude-sonnet-5-5. The controller supplied no verdict.
- Game SHA: `25f3bf2458646ff7be3bab5075e26eb3baef9cfb` (PR #40). Design SHA: `1ef3bc96ace4aa7645a277825f0c81c75b5022a9` (design PR #3).
- Both evaluator worktree HEADs were confirmed equal to these SHAs.
- **Verdict: PASS, 91/100. No hard fails. P5 is SATISFIED.**

| Category | Score |
|---|---|
| Tests | 19/20 |
| Lint | 9/10 |
| Acceptance criteria | 28/30 |
| Code quality | 14/15 |
| Documentation | 12/15 |
| Design fidelity | 9/10 |

## Scope

Nothing in `6da03f8..25f3bf2` touches production code. `git diff --stat` outside docs, state and the changelog is empty. The landing is 12 files of docs, state and changelog.

The only production change since the M2.5 evaluation is M2.6b's additive change, in `b6efa8f^1..b6efa8f`:
- `sim/core.ail` gains the `cruisePhiMin`, `cruisePhiMax` and `cruisePhiDefault` exports.
- `sim/protocol.ail` gains the params echo and `ShipView.flown`.

Toolchain pin is v0.51.0 everywhere I checked:
- `runtime/bin/ailang` reports v0.51.0 (b99dd25).
- The Makefile, CI and `sim/ailang.lock` all say v0.51.0.
- The lockfile has relativity 0.4.0.

## P5 supplement: new evidence

1. **Golden diff after regeneration.** I compared the golden diffs from `b6efa8f` (arm64) and `1567f84` (x86_64) field by field.
   - Scope: `alpha_cen`, `godot_map_voyage` and `offaxis_v11_equiv`, on both architectures.
   - Result: the only additions are `params.cruise_phi_{min,max,default}` and `ship.flown`. No value changed or was removed, and line counts are unchanged (66, 73 and 17).
   - The sha256 goldens are digest-only, so I proved them by running the replay.
2. **Six case families on both architectures.**
   - arm64, run here: `tools/replay.py` at 10k ticks gave `alpha_cen`, `diag_thrust600`, `godot_map_voyage`, `offaxis_v11_equiv` and `session10k` all OK, VM == interpreter == golden, rc=0. The `--ticks 2000` run added `session2k`, also OK.
   - x86_64, CI log: run 36984203991 on 25f3bf2 (10k) has the five cases identical. Run 36981203047 on 80c29ae (PR, 2k) has `session2k` identical.
3. **Arch exception.** `alpha_cen` and `godot_map_voyage` are byte-identical across architectures. `offaxis_v11_equiv` differs only at tick 6, `ship.beta` `…098` vs `…0982`. That is 1 ulp (ailang#1465), as documented.
4. **Arrival residuals.**

   | Case | Tick | residual_x | residual_t | residual_phi |
   |---|---|---|---|---|
   | `alpha_cen` | 64 | 1.8e-15 | 8.0e-15 | 4.8e-11 |
   | `godot_map_voyage` | 68 | 8.9e-16 | 8.0e-15 | 4.8e-11 |

   Both architectures give the same values, all inside the AC5 bound of 1e-9·max(1,d).
5. **Design check rows.**
   - The `alpha_cen` golden equals design row 2 exactly: ship 0.6226958707592057 yr, Earth 4.414143655383168 yr, φ 2.6466524123622457, distance 4.37.
   - `cruise_phi_min` 1.4722194895832204 equals row 1 (0.9c).
   - `cruise_phi_max` 7.254328619262047 equals row 3 (the cap). I also got it independently as ½·ln((2−1e-6)/1e-6).
   - `cruise_phi_default` equals atanh(0.99).
   - The catalogue distance is distinct. `godot_map_voyage` plans Gl 559 at 4.35667304258651 ly, giving ship 0.6207968821769395 and Earth 4.400682082238228.
   - Independent closed-form check: Earth − d/0.99 is 2.2412417539641183e-06 for both distances, which is a constant boost correction. Ship time differs from (d/0.99)/γ by the same offset for both.
   - Not re-derived: the energy, ledger and ISM figures. They are package conventions and did not change in the golden diff.
6. **Mutations**, scoped to the M2.5 replay production diff (goldens and the `tools/replay.py` harness).
   - Changing the last digit of `residual_x` in the `alpha_cen` arm64 golden made the replay FAIL (rc=1).
   - Changing `87cd` to `87ce` in the `diag_thrust600` arm64 digest made it FAIL (rc=1).
   - Both files were restored byte-identically (`cmp`).
   - My first `alpha_cen` sed used the wrong whitespace pattern and changed nothing, so the replay stayed green. I redid it correctly.

## Prior evidence, not repeated

- Independent M2.5 and M2.6b evaluations scored 93 each.
- CI was green on `6da03f8` (run 36982239622) and on `25f3bf2` (run 36984203991, the headless suite with REPLAY_TICKS=10000).
- `make golden` and the GPU were not rerun. Nothing in the shaders or visuals changed since the M2.6b evaluation.

## Gates

- I did **not** run a full local `make test`.
- `/tmp/stapledon-iter9-baseline3.log` had no rc, and it ran in a different worktree for the superseded draft. I did not use it.
- My gate evidence is CI on the exact SHA, the empty production diff, and the local replay gate above.
- That costs 1 point under Tests.

## Documentation, state and links

- The three docs are under `implemented/r1`, and no `planned/r1/m2*` files remain. The remaining "planned/r1/m2" strings are historical.
- Relative `.md` links resolve. All 11 design-repo targets exist at `1ef3bc9`.
- The sprint JSON is valid. Status is `completed`, 10 of 10 features pass, and the `design_doc` and `sprint_plan` paths point to the implemented locations.
- `git diff --check` is clean.
- The design repo diff is the roadmap §M2 "Landed" status with game links, plus the superseded-maths note in `journey-system.md`. It is 20 insertions in 2 docs.

## Findings (all minor)

1. The sprint JSON `ailang.pin` is still `v0.50.0`, but the current toolchain is v0.51.0. The landing plan asked for the current pin with the history preserved.
2. The sprint JSON has `approved: null`, though `ca511a9` records the attended plan approval of 2026-10-01. `questions_for_mark` Q2 and Q3 are also not annotated as answered.
3. The P5 "yep approved" comment on PR #35 was posted by the bot account, quoting Mark. I could not verify the quote from the repo, so I treated it as source evidence per your instruction. The P5 verdict above rests on the technical evidence, not on the quote.

## Worktree

Mutations are restored. `git status` should show only this report pair as untracked.
