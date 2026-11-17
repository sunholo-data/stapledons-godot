# Playable foundations: approved batch integration

2026-11-17. Approved scope: SF0–SF1b, CP1–CP3, PV1–PV3. Three GPT-6.1 Sol executors; independent Anthropic Claude Sonnet 5.5 source/evidence review. Original art checkout preserved.

## What changed

- The review route waits for the actual installed painted bridge, Commons and residents, records their manifest identity, and writes local-only measurements. Reports distinguish window size, logical viewport, render targets and display scale. Headless runs cannot claim native timing.
- Four existing content bundles share provenance, dependency, budget and export checks through three type-specific adapters. Existing game loaders remain authoritative. Scratch staging and a small extension fixture exercise the addition path.
- The complete voyage checks both arrivals, phases, return-home news and the final log. Six rejection controls include missing return, missing home news and missing log. The harness waits for production installation before controlling the scene.

## Code and evidence pins

Final implementation code: `d10d0d20f03dc7efa6a99e6d886a8e051ee05ece`. Base candidate: `19e4a763`; remote main `ae5394dd` reconciled at `ec415f33`. Later documentation/evidence commits do not change this code pin.

| Check | Result and provenance |
|---|---|
| Fast-tier coverage | `make ci-fast` at `ab17b45d` passed every prerequisite except the final process-supervision self-test, whose `pgrep` could not see its child inside the sandbox. Exact isolated rerun with process visibility passed 18/0. Do not describe the initial command as green. [Initial log](playable-batch-evidence/ci-fast.log), [rerun](playable-batch-evidence/script-gate-selftest.log). |
| Final changed-area gates | Packed route 5/0, real committed transit 18/0, export classifier 163 literals/0 failures, UID 495, script-gate lint. [Log](playable-batch-evidence/final-targeted.log). Earlier readiness 14/0, deck invariants 1168/0, local profiler 15/0; final HiDPI report controls 20/0. |
| Final real resource pack | 2884 checked, zero skips/failures. SHA256 `529630a24fed5f77bddc9144cdfd00038a6d23e29ec12bda49f0a23a1966a0d8`. This is a resource-pack ZIP, not a newly published macOS app. [Log](playable-batch-evidence/final-pack.log). |
| Actual packed entry | The packed benchmark entry loads and reaches the expected headless refusal (rc 2, no script error). [Log](playable-batch-evidence/packed-entry.log). |
| Console compatibility | 136/0 after granting the existing test access to its Godot user-data recording/stub-cache directory. The sandbox attempt failed three assertions; no code change was needed. [Log](playable-batch-evidence/console.log). |
| Complete voyage | 143640/0; display audit 259146/0; completion unit 14/0; six declared negative cases pass. [Hashed evidence](../../art/playable-voyage-review/evidence.json). Twenty compatibility targets passed in the executor; console retry above closes the remaining environment issue. |
| Fresh recorded-session parity | PASS: both producers exit 0; `cmp` succeeds; 2425 identical lines, SHA256 `0eff93bec753264cbadd4c74dedd7c2a030ca8012eda59ea2ded351ea4a7d903`. [Receipt](playable-batch-evidence/fresh-parity.json). |
| Independent review | Round 2: 88/100, no remaining source defect. Its sole condition, fresh-session parity, is now discharged; local implementation accepted under the reviewer’s explicit rule. [Review](../../.ailang/state/evaluations/eval_PLAYABLE-BATCH_round_2_sonnet.json). |

## Defects found during qualification

The new pack auditor initially recognised `.remap` but not Godot texture `.import` metadata; real-pack evidence found and corrected that bug. The review route initially lived under excluded `tools/`; actual ZIP inspection caught its absence. Its runtime module now lives under `demos/`, with static and packed-script witnesses. The real lift phase initially froze its controller and now runs normal lift presentation. No missing resource, missing input or environment failure was waived into a pass.

## Remaining product work

SF2/PV4, actual laptop performance and appearance, reduced-motion review, captain visual/age coverage decisions, S3/S5 acceptance, remote CI, publication and merge remain open. No FPS improvement or finished-game claim follows from these harness changes. The practical next step is the combined native laptop review, using the recorded workload to select performance fixes.
