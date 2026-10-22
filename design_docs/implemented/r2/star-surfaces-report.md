# R2-STAR-SURFACES: implementation report

**Landed** 2026-10-21. Design: [star-surfaces.md](star-surfaces.md). Sprint: [star-surfaces-sprint.md](star-surfaces-sprint.md).
Decisions: D-99 (spike), D-105 (approved), D-111 (show more), D-114 (round 2 approved).

| Step | PR | What |
|---|---|---|
| SS0 | #297 | design and spike |
| SS-1..SS2 | #302 | `sunholo/celestial` 0.5.0 `stellar` module (limb-darkening laws and tables, Baumbach, differential rotation, line shifts); protocol 2.13 `surface` record; the renderer's temperature map (cells, spots, faculae) gated by real resolution and normalised to the star's flux |
| D-111 + SS3 | #315 | telescope (T at the helm close-up), close pass of Sun-like stars (twice the D-54 tangent), per-star activity and flares; eclipse layers (Baumbach corona with streamers, H-alpha prominences, the diamond-ring sliver) |
| SS4 | this PR | evaluation, landing, cited activity values corrected, telescope scale tested |

## Evidence

- Rig `make test` + `make golden` green on d09bad78 (62 min): sim tests 539, replay 11 identical, physics 925, goldens G-SS-1..8 ok.
- Flux = `e_v_lux` within 0.3 %; the unresolved Sun is byte-identical; the corona matches Baumbach to 0.6 %.
- Bench: +0.039 ms at Aldebaran (Vulkan; Metal reports no GPU time).
- Independent evaluation (Sonnet, read-only): **77/100 PASS**, `.ailang/state/evaluations/eval_R2-STAR-SURFACES_round_1.json`. Both of its blockers are resolved in SS4. Two of its non-blocking gaps are closed: the telescope scale (`TelescopeView.scale_for`) and the cited cycle lengths now have tests.
- Reference frames: `gs://stapledons-voyage-assets/refs/star_surfaces/{,ss2/,d111/}`.

## Citations opened in SS4

- Ayres 2014, arXiv 1401.0847: α Cen B's cycle is 8.2 ± 0.2 yr; α Cen A's is 19.1 ± 0.7 yr (tentative, a Maunder-like low state since 2005). B's 8.1 yr and A's 19.0 yr were corrected to these values.
- Toledo-Padrón et al. 2019, MNRAS 488, 5145: Barnard's Star has P_rot 145 ± 15 d and a cycle of 10 ± 2 yr, as modelled.
- Not opened: Vida 2017 (TRAPPIST-1's flare rate) and Kowalski 2013 (the flare kernel's temperature). Both are marked in the sprint JSON.

## Follow-ups

These are listed in the sprint JSON's `follow_ups`:

- an Archive entry (attended canon text);
- inspector labels drawn from `surface.prov`;
- a per-stop texel check for AC8;
- adapting the corona to the eye meter in a real sim eclipse;
- the `Planets.body_basis` NCP pole case;
- a GPU-time bench on Metal.
