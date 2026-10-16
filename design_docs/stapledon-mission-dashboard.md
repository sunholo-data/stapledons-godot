# Stapledon mission dashboard

Updated 2026-10-16, iteration 36.

- **Bar:** clauses 2/3 MET; 1/4 UNMET; 5 ongoing. Clause 4 moved: the 3D ship's S1 reference set exists, from real sim states, and waits for Mark (D-84).
- **Outcome:** M4.6rR3 BUILT, PR #265, parked unmerged at S1. `make capture-m4` shoots 7 states × deck/forward + a contact sheet aboard the 3D ship; the set is public at `refs/m4_ship_s1/`. `make bench SCENE=bridge` gates AC12. Eval Sonnet 85 PASS, 0 blocking. M4.6gR3 (#257) LANDED: merge CI `success`.
- **Key find:** AC12 misses at HEAD. In live transit the bridge runs p50 41 / p99 85 ms (2560×1440, vsync off, medium tier) against p99 15 ms with journey ticks stopped. The cost sits in the frame after `GalaxyMap.tick()`. Row 7m; it blocks P-land, not S1.
- **S1 notes for Mark:** flat white Earth and α Cen A discs; dust flashes at rest in the home frame; faded card ghosts; a hull spire in every forward view; cards over ~30 % of transit frames; no separate glow at 3.35e-5 W/m².
- **Next:** D-84 (S1; then merge #265, re-capturing first if #264 has landed); row 7m after #264 lands; D-83; rows 7i(k), 7k, 7l; then L9.
- **Mark:** D-84 new (sign off the S1 set; recommended A). D-83 (merge #252), D-77 and D-78 unchanged; defaults hold.
- **Attended in flight:** #262 (AILANG v0.54.13 bump, blocked on a getEnvOr VM regression) holds row 6d; #264 (R2-INTERLUDE) holds the ship scene files.
- **Lanes:** codex gpt-6.1-sol live (probe rc 0) for planner and executor through Agent-tool roles. Quorum at 1 of 3: ollama ×2 and OpenAI unreachable, gemini passed.
- **Cost:** metered $0.036 (gemini quorum seat); quota buckets: opus, sonnet, codex.
- **Workspace:** sibling clones `.stapledon-loop-iter36`, `-eval-iter36` and `-record-iter36`. The main checkout was only fast-forwarded and read. Record stacked on #258.
