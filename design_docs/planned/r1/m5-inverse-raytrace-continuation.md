# M5 resolved-body inverse raytrace continuation

| Pillar | Alignment | Reason |
|---|---:|---|
| Choices Are Final | +1 | Observer rendering preserves committed simulation trajectories. |
| The Game Doesn't Judge | +1 | Approximate ephemerides and display policies are explicit. |
| Time Has Emotional Weight | +2 | Changing appearance follows continuous authoritative acceleration. |
| The Ship Is Home | +1 | The same sky is visible from the physical standing eye. |
| Grounded Strangeness | +2 | Package-owned optics, photometry and ring data govern the view. |
| We Are Not Built For This | 0 | No new crew mechanic. |

Implements the [relativity specification](https://github.com/sunholo-data/stapledons-design/blob/main/physics/relativity-spec.md), [journey system](https://github.com/sunholo-data/stapledons-design/blob/main/features/phase3-gameplay/journey-system.md) and approved [M5 planets](m5-planets.md) within the approved [Solar departure sprint](m4-ship-lighting-and-solar-departure-sprint.md).

Approved within R1-M4-SOLAR-DEPARTURE by the user and delegated to the planet renderer executor. Root explicitly approved the bounded direct inverse-raytrace variation on 5 October 2026.

The existing rest-body renderer already computes exact per-sample sphere intersections and Minnaert surface colour. M5.3 will inverse-aberrate each observed ray using the pinned relativity0.7 optics.deaberrate, then trace that same rest sphere and apply the existing photopic blackbody LUT's surface-brightness/chromaticity ratio. This replaces planned rest-frame tiles with direct sampling, avoiding tile interpolation/4096-cap errors. Gamma and one_minus_beta come only from simulation state. At rest the current draw path remains unchanged. Full-screen resolved-body quads require measured performance before approval.

Tests first: CPU operation-for-operation mirror against actual package probes for apparentDisc, inverse rays and Doppler; beta0 identity; at least1000 direction roundtrips. GPU apparent limb circles at beta0/.5/.9/.99 and theta30/90/150, and spatially varying radiance at edges/centre against CPU LUT references. No moving resolved body is enabled until these pass and actual images are inspected. Ring/shadow support separately mirrors celestial0.1.0 radiometry, transmission and ringPlaneHit with the source sim/data/sol.ail profiles; a Saturn globe is not a completed Saturn view.

This continuation does not invent orbits, itinerary positions, Earth-Moon barycentre corrections, atmospheric scatter or GR. Celestial0.1.1 was checked in an isolated registry manifest and is not published; game pins remain0.1.0. Normal new_game is currently Sun-centred. Near-Earth scenario and successive physical legs remain separately owned simulation/navigation work.

## Executed gates and limits

The implementation now enables the inverse-ray renderer in InteriorSky. Normal world state supplies heading, gamma, one_minus_beta, positions, clocks and epoch; the renderer never changes them. Minor5 ring tables are serialized directly from the AILANG data authority. Earlier protocol minors remain unchanged. All image textures use existing published surface maps.

Commands: pinned `AILANG_BIN=$PWD/runtime/bin/ailang godot --headless --path . --script tests/test_{ship_planets,flyby_optics,planet_rings,ring_protocol,planet_meter,planet_occlusion}.gd` (run each script separately). Actual results: 21 integration,1061 optics,28 ring mirror,9 protocol,16 meter and12 occlusion checks passed. Native `tools/flyby_golden.gd` passes all12 package-probed cases (beta0/.5/.9/.99,30/90/150 degrees) with <0.75px limb/centre error and <1% leading/centre/trailing radiance error. Native `tools/ring_golden.gd` passes918lit+263unlit interior radiometry samples (<1.15%),40 globe-shadow boundaries (<0.134px) and90 ring-shadow boundaries (<0.174px). Shadow boundaries are isolated, unsaturated analytic contours; overlapping edges are tested separately by interior radiometry. Final images in `renders/m5/{flyby,rings}` were opened and inspected. The parent owns Makefile integration, real tour screenshots, performance, export and independent evaluation.

Metering extends the existing package-backed mean with physical ray luminance and a32x18P99.5 field highlight policy. Compact discs (<2degrees diameter) integrate authoritative illuminance through the existing point-source limit so sparse grids cannot miss the Sun; they are excluded from extended-disc mean samples to avoid double counting. FixedEV, bias and clamps remain explicit policies. The conservative pre-AgX scene-linear highlight target is1.0, not a claimed AgX hard white point: [Godot4.7.2 tonemap source](https://github.com/godotengine/godot/blob/4.7.2-stable/servers/rendering/renderer_rd/shaders/effects/tonemap.glsl) uses a shoulder. Bright compact Sun highlights may still saturate at the existing EV20 clamp; no universal unclipped highlight claim is made. Looking away restores the original dark sky exactly.

Ring scattering uses celestial0.1.0's single-scattering functions with an explicitly isotropic phase function P=1. Producer optical depths, albedos and tint remain authoritative. Unresolved ring flux is not separately integrated beyond the host's existing point flux. Atmosphere, multiple scattering and Earth/Moon centre correction remain future refinements. Identification masking reuses inverse rays and opaque sphere coverage; partial rings retain stars, while ring alpha that rounds to1 in renderer float32 masks them. Internal ship key/fill lighting remains the parent's separately labelled approximation; planet radiometry does not drive it.
