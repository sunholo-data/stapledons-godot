// THE galactic <-> Godot world map for shaders (D-28). Mirrors sky/sky_frame.gd (SkyFrame), the
// one definition; tests/test_physics.gd test_sky_frame checks this file against it.
// galactic (x to the centre, y to l 90, z to the NGP) -> world (Y up, -Z forward, +X right):
// (x, y, z) -> (-y, z, -x), det +1 (a rotation; the pre-D-28 (y, z, -x) was a mirror).
vec3 sky_galactic_to_world(vec3 g) { return vec3(-g.y, g.z, -g.x); }
vec3 sky_world_to_galactic(vec3 w) { return vec3(-w.z, -w.x, w.y); }
