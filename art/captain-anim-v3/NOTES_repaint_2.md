# Captain walk profile frame 04

- Output: `out/walk_profile_04.png`.
- Generated with the built-in image generation tool, with all four requested references attached: captain identity, neighbours 03 and 05, and guide 04.
- Two candidates generated, as permitted by HANDOFF.md; retained candidate 2. Only the selected frame was copied into `out/`. No resizing, repainting, or background processing was performed.
- Selection: candidate 2 has a shorter stride than candidate 1, with the far left boot level and the near right boot advancing with its toe raised. The identity, costume, palette, and rendering follow the neighbours.
- Validation: native 1024 × 1536, 8-bit RGBA PNG. Alpha ranges from 0 to 254; 1,202,141 pixels have alpha zero.
- Limitations: boot spacing still exceeds the guide, and the near right boot does not clearly hover wholly above the far boot's ground level. A visible halo remains despite the transparency/no-halo instructions. Nonzero alpha bounds are x=0–1009, y=71–1437, so the strict 40 px transparent margin is not satisfied. This is the closer of the two allowed candidates, not a fully compliant pose/alpha result.
- Stopped after saving this frame and notes, per handoff.

## Final generation prompt

Use case: identity-preserve, pose transfer, animation frame.
Paint exactly ONE finished captain walking screen-RIGHT for Stapledon's Voyage D-115.
FOUR INPUTS: Image 1 = identity/costume. Images 2 and 3 = neighbouring walk frames, rendering references ONLY. Image 4 = authoritative colour-keyed pose guide. Transfer the pose from image 4 rather than copying either neighbouring stride.
Finished 1024 x 1536 RGBA image, genuinely transparent background with alpha zero everywhere outside the captain. NO opaque black background. NO brown or gold background glow, NO halo. The background glow in images 2 and 3 must not be copied.
Match the neighbours' face, short tousled brown hair, fine dark ink drawing, detailed gouache fabric shading, cream long coat with ochre collar/shoulder yoke/buttons/sash, violet trousers and brown wrap boots. 1970s European graphic-novel ink-and-gouache style. Palette cream #F2E3C7, ochre #D9A340, violet #3B2959, ink #423555.
Pose: tightly follow image 4 for both boot positions and body silhouette. This is a SHORT near-passing stride, NOT the large extended stride of image 3. Keep the boots close together as in image 4: far LEFT boot around x330–485, near RIGHT boot around x450–630. LEFT far boot is the STANDING boot, flat and horizontal at ground level, under and a little behind the hips (red boot position in guide), heel and toe both down. It is NOT lifting. RIGHT near boot is swinging FORWARD in front of the body, knee slightly bent, hovering only a few centimetres above that same invisible ground level (blue boot position in guide), and has NOT landed. Both boots point screen-right. Only the near RIGHT leg advances. Red/blue colours are guide keys and must not appear on finished costume.
Calm upright posture. Coat hangs downward and sways gently, not billowing out behind. Preserve character scale/head height consistent with guide and neighbours. Side profile, orthographic looking down 29 degrees. At least 40px clear margin to every canvas edge. No floor, shadow, scenery, text, watermark, guide marks or coloured anatomy.

