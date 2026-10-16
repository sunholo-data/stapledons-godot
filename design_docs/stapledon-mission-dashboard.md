# Stapledon mission dashboard

Updated 2026-10-16, iteration 35.

- **Bar:** clauses 2/3 MET; 1/4 UNMET; 5 ongoing. Clause 4 moved: the 3D ship now has GPU goldens (AC10's ship form).
- **Outcome:** M4.6gR3 MERGED, PR #257 (merge `375e390`). `make golden` 363 → 373 ok: forward pole 0.030 px (limit 0.75), one tonemap worst 0.0000, glow within 0.34 % of the sim (limit 1 %). Drills D1, D2b and D3 were green at base and are now red. Independent Sonnet eval 88 PASS, 0 blocking. Local `make -k test` rc 0 on `658072a`.
- **Pending:** merge CI 38906220440 on `375e390` was in flight at record (about 2 h). PR CI was `success` on the identical tree.
- **Key find:** the unattended launchd session has the GPU window (`make golden` rc 0 in 25 s). GPU rows (M4.6rR3) are loop work now, still parking at S1 for render sign-off.
- **Upstream:** AILANG v0.54.12 is out and fixes ailang#1576. Every in-tree VM workaround is now retireable. Attended #255 bumps to v0.54.11; row 6d now names v0.54.12.
- **Next:** verify merge CI → LANDED; M4.6rR3 (build, upload renders, park at S1); D-83; row 7i(k); row 6d after #255/#248; row 7k (eval follow-ups); then L9.
- **Mark:** nothing new. D-83 (merge #252; recommended A), D-77 and D-78 are unchanged; their defaults hold.
- **Lanes:** codex gpt-6.1-sol is live (probes rc 0) and ran the planner and executor through Agent-tool roles. The quorum ran at 1 of 4: ollama ×2 and OpenAI were unreachable, and gemini passed.
- **Cost:** metered $0.019 (gemini quorum seat); quota buckets: opus, sonnet, codex.
- **Workspace:** sibling clones `.stapledon-loop-iter35`, `-eval-iter35` and `-record-iter35`. The main checkout was only fast-forwarded and read. Attended PRs #243, #248, #249, #254 and #255 were untouched; the record is stacked on #253.
