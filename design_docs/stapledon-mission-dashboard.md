# Stapledon mission dashboard

Updated 2026-10-17, iteration 37.

- **Bar:** clauses 2/3 MET; 1/4 UNMET; 5 ongoing. Clause 4 moved: AC12's live-transit frame cost is found and fixed; the quiet-rig number is still to be measured.
- **Outcome:** M4.6pR3 BUILT, PR #268, stacked on #265. Every sim tick, the hidden navigation window's ISM map layer redrew 905 faces in GDScript (~24 ms per tick). An 8-line guard in `ui/ism_layer.gd` takes bench frames from ~1500 to ~3100 per 30 s. Eval Sonnet 88 PASS, 0 blocking. `make test` rc 0.
- **Key find:** #264 does not change AC12 or its cause, and the fix touches no attended file.
- **Open:** AC1 (quiet-rig p99 < 16.7) is unmeasured. A resident Ollama model held the GPU at 85–98 % all morning. Contended runs on the fix: p99 16.4–19.9 ms.
- **Next:** AC1 when the GPU is quiet; D-84 (S1; then #265 merges and #268 retargets to main); D-83; rows 7n, 7l, 7k, 7i(k); then L9.
- **Mark:** no new decisions. D-84 (S1 sign-off), D-83 (merge #252), D-77 and D-78 are unchanged; defaults hold.
- **Attended in flight:** #262 (AILANG bump; v0.54.14 now fixes its getEnvOr blocker), #264 (R2-INTERLUDE) and #267 (crew console v2) hold the ship scene, `ui/galaxy_map.gd` and the sim.
- **Lanes:** codex gpt-6.1-sol live (probe rc 0) through Agent-tool roles. Quorum at 1 of 3: gemini passed; the OpenAI API seat is out of credits (429); the two ollama seats are unreachable.
- **Cost:** metered $0.025 (gemini quorum seat); quota buckets: opus, sonnet, codex.
- **Workspace:** sibling clones `.stapledon-loop-iter37`, `-probe-iter37-264`, `-eval-iter37` and `-record-iter37`. The main checkout was only fast-forwarded and read. The record is stacked on #266.
