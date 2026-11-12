# Mission dashboard — Stapledon

Updated 2026-11-12, iteration 88. LANDED: row 7am (PR #427, merge `39f98c99`).
R1 clauses 1–3 MET; clause 4 UNMET (7m AC1 → 7m-d → D-147); clause 5 ongoing; goal unmoved.
Latest release: no release tag this iteration; game/runtime pins unchanged (AILANG v0.56.1, Godot 4.7.2).
Current: every hand-copied star target in tests and tools now points at its real map index (alpha Cen A 2, Sirius A 9, Aldebaran 3158; 14 one-token fixes in 10 files). A new check in `replay-map-index` (in `ci-fast`) reads every hand-written index/id pair in tracked GDScript and Python, so a wrong one now fails at its PR. Nothing on screen changed.
Held for Mark: `tools/earth_link_capture.gd` still uses the old index, because fixing it changes one review frame's map subtitle (`CNS5:3627` → `CNS5:3627  ·  4.32 ly`). That is D-149 (default: no change).
Remaining nightly red on main (expected): `bridge-operator-test` (D-148).
Watch: Ollama cloud's weekly quota ran out this fire (429); the planner used the OpenRouter twin ($1.73). `current-ship-startup` first-run failures (Sonnet, iteration 83) still unexplained. Side clones made from the main checkout need `git remote set-head origin main`. In zsh, expand path lists with `${=P}`.
Next: read the nightly on main (expect 1 red); then 7an, 7ao, 7ap (all low priority); 7ad parked on iteration 80's Next; 7ac after 7ad; 7ab on its nightly-start predicate.
Critical path: 7m/7m-d parked on D-147 (default A); no routable UNMET-clause row.
Human gates (all OPEN): D-128 order; D-129 L4 defaults; D-145 sound ownership; D-146 designer rotation; D-147 7m-d S1; D-148 bridge working-point repair (the only nightly red); new D-149 earth-link capture index.
Action for Mark (not a ledger decision): codex login still reads "quota UNREADABLE" in the driver.
Routing this fire: controller Opus 5.5; designer Opus (Agent); planner kimi-k3 (pi; Ollama 429 → OpenRouter); executor Haiku (Agent); judges Sonnet (Agent) + MiniMax M3 (pi, cross-vendor).
Quorum: r1 BLOCKED 3/3 (designer revision); r2 BLOCKED 2/3, closed by the narrow-refinement carve-out (reviewers' fixes as written).
Review: Sonnet 90 PASS, MiniMax M3 96 PASS; non-blocking findings filed in row 7ap.
CI: fast tier green on PR heads `77c5b7b5` (AC13 lines in the job log) and `2e704cd7`; merge `39f98c99` fast tier in progress at record time; no GPU run waited on.
Issue sweep 2026-11-12: 0 orphans of 2 open issues.
Cadence: armed six-hour driver.
Metered cost: $3.21 of $5 (quorum $0.90, planner $1.73, MiniMax $0.58). Quota: Anthropic subscription (Opus, Haiku, Sonnet); Ollama cloud weekly bucket empty.
Canonical checkout untouched (attended `feat/captain-command`); record from clone `stapledons-godot-iter88-7am`, branch `mission/stapledon-iter88-record`.
Full history: stapledon-mission-log.md, entry 88.
