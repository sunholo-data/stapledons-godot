# Sky exposure trial

User-approved display trial,2026-10-04. Baseline plus1,2,4,6stops (2×,4×,16×,64×),
using existing Exposure.bias, across the entire sky. Default2×; J/button comparisons.
No magnitude floor, new photons, angular compensation or simulation changes.
Geometry retains diagnostic lighting; this is not a full interior/naked-eye adaptation model.
At0.99c modest boosts leave side views very dark; strong gains brighten the diffuse
background and may saturate the forward view. No guarantee of rich side star fields.

Capture manifest retains heading, physical ship state, camera, metered EV and label.
GPU golden validates known-lux fixtures at all five gains (fainter fixtures for high
settings avoid display clipping); errors under1%. Headless journey47checks include
state/heading invariance, ratios, baseline restoration, benchmark lock and preservation
of metered EV during attitude-only camera synchronization. These are display checks;
existing full physics goldens remain unchanged and passed.
