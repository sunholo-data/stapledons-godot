### Changed

- **Session-minor guard, lexical edges (row 7ao).** The fast tier now refuses what it let through before: a `SESSION_MINOR` below any floor a test asserts, a floor that names `SESSION_MINOR` itself, a floor put behind a comment, a test that names another constant in constant-first, tab-spaced or parenthesised form, and a ternary wrapped around the prefetch call. The orphan control's minor is derived from the bridge, not hardcoded to 99.
- **Warm-sim adoption checks.** `test_sim_warm` now checks each `_adopt_warm` refusal on its own: another protocol minor, and a launch override. Each check fails when its single condition is removed.
- **7ah similar-main guard (row 7ao).** `similar-main-guard` reads `_run_map` to the next top-level line and fails when there is none, as the session-minor guard does.
- Nothing a player sees or hears changes: every edit is in a Makefile guard recipe, a controls script or a test.
