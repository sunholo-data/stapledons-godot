# Planet presentation follow-up

Approved by Mark's 5 October laptop/transition follow-up; tracked in
`design_docs/planned/r1/m4-tour-transition-followup.md`. This is presentation
work on existing AILANG positions, clocks, optics and photometry. No simulation
trajectory, radii, headings, package pins or SR formulas changed.

System preparation is cached separately from exposure. Exact source state,
velocity, pixel calibration, texture mode and LOD policy invalidate the cache.
Replacing planetary points performs one upload. CPU radiance rejects rays
outside a conservative package-derived rest cap before final sphere/ring
intersection; the final physical intersection and shading remain unchanged.

InteriorSky enables a smoothstep handoff from 1.5 to 3.5 apparent pixels. A
body's existing point flux receives 1-w and its resolved radiance receives w.
Planet points use a distinct additive material after discs so the point's own
PSF is not erased by the globe's unchanged opacity. Catalogue stars remain
under opaque globes. Other farther planet/moon points retain sphere/ring
transmission and depth gating, including night faces and the Sun. Solid-body
identification coverage remains physical and independent of emission LOD.
Legacy direct SystemView captures retain the original 2px policy.

The complementary host-body weights conserve the existing point/disc flux
model. Unresolved ring flux and ring shadow corrections to the host's integrated
point flux remain the previously documented M5 refinement; no claim that their
point approximation exactly includes resolved ring energy is made.

All nine existing 2k texture families are warmed before playable frames. CPU
source images are retained before mip upload, removing late GPU readback for
metering. Exact raw CPU image allocation is60MiB; mip upload source data is
about80MiB, with actual backend GPU allocation to be measured separately.
Repeated warmup adds no images. One-time observed preparation was0.11–0.75s
on this Mac Studio; this moves work before play, not a claim of zero startup
cost or measured M2 Air improvement.

CPU benchmark: `AILANG_BIN=$PWD/runtime/bin/ailang godot --headless --path .
--script tools/planet_cpu_bench.gd`. It records120samples for each of dark,
close Earth and Saturn, with forced preparation and reuse. Latest reuse median/
p95: dark3.27/3.44ms, Earth1.61/1.73ms, Saturn1.00/1.05ms. Before the conservative
ray rejection, corresponding medians were7.50,1.80,1.25ms. This excludes catalogue,
background and GPU frame cost. Output: `renders/perf/planet_cpu.json`.

The moving shader now bounds work by the package's apparentDisc enclosing cap,
including ring extent and a3pixel margin. The fragment still inverse-aberrates
and traces the original sphere/rings. Caps above60degrees and those crossing
the camera plane use the full-screen fallback. Camera direction does not change
physical observer state. InteriorSky.orient_basis changes only camera/glow
attitude; velocity heading and beta remain authoritative.

Focused CPU gates:800presentation checks,23meter,49legacy planet,585physics,
21ship planet integration and12occlusion checks passed. Actual normal-tour moon
lifecycle73checks pass: four Jovian moons and five unocculted Saturn moons retain
representation across braking, arrival and stationary epochs. Mimas remains
physically behind Saturn in all three samples. No arrival-specific array loss
was found; camera, geometry and adapted brightness still govern native visibility.
Native transition harness
`tools/planet_transition_golden.gd` records86actual integrated-flux samples and
adjacent transition steps at rest and beta0.9, plus five snapshots per velocity.
Final86linear floating-HDR samples pass the unchanged4%flux/2.5%step gates:
max flux error0.434%, max adjacent step0.506%. Tiny opt-in discs use16x16
quadrature, while legacy captures retain their8x8 policy. The earlier8-bit
readback showed3.44% steps from four-pixel quantization; increasing quadrature
alone did not remove them. Measuring physical flux before8-bit conversion
distinguishes that output limit from the handoff itself. Display PNG/metrics
are recorded separately; final window preview refresh remains pending.

Twelve package optics cases and Saturn radiometry/shadow goldens pass after
the bound change. Six additional moving FOV-edge/roll/large-Sun/Saturn-ring
cases compare bit-identically with the full-screen reference (nonempty diagnostic
coverage), including the large-cap fallback. Actual aggregate/native benchmark,
packaged tests and independent review remain required before publishing.
Existing user M2 Air baseline is retained separately; no Air performance claim
is made here.
