# Ship lighting study

The approved camera direction is painted 3D geometry with a movable camera.
This pass restores warm highlights, cool shade and real spire/rail/frond shadows.
The measured Blender geometry and embedded pigments are unchanged; their hashes,
standing eyes, projection and full light recipe are in `capture-manifest.json`.

Native screenshots are published in the [game gallery](https://www.sunholo.com/stapledons-godot/gallery)
and [ship reference](https://www.sunholo.com/stapledons-godot/docs/ship-layer-reference).
The selected files live under
`https://storage.googleapis.com/stapledons-voyage-assets/refs/ship_lighting_v1/`:
`bridge_inward_moody.png`, `bridge_inward_baseline.png`,
`bridge_outward_moody.png`, `commons_arcade_moody.png`.

This is a ship-fixed internal lighting study. The broad key does not represent
the Sun. Simulation-driven starlight on the ship geometry is now
`demos/ship_star_light.gd` (`StarLight`, design
`design_docs/planned/r1/ship-star-light.md`): it comes from the star's apparent
direction with its Doppler-shifted blackbody colour and a log-compressed
brightness, and it fades this broad key out as it takes over. The ambient, fill
and practical of this study stay as the base. The planet/sky renderer keeps its
own physical radiometry.

`make ship-lighting-capture` reproduces four poses with baseline, moody and
shadow-disabled profiles. The paired 1920×1080 benchmark used 120 warmup and
300 measured frames for each profile. The p95 increments were 0.018–0.090 ms
on the Studio, with presentation/vsync included. This is not isolated GPU cost
or approval of performance on Mark's M2 Air; laptop measurement remains pending.
