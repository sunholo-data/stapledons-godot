### Changed
- **Sound rework after the first listen (R2-SOUND, D-108).** The bridge's room tone is now barely
  there and the spire's hum leads. The consoles wake and sleep like a precise machine. The drive is
  lower and richer (beating partials, a noise band whose filter opens and closes) and the brake
  rougher, still with nothing felt (a new check keeps everything under 200 Hz at least 20 dB down).
  Arrival is an understated suspended chord. The Archive's reply is a small breathing figure.

### Added
- **The spire's degradation layer.** A second, much slower beat under the hum that rises as the
  Archive's Memory Health falls. The sim does not emit Memory Health yet, so in game it stays silent.
- Synthesis: vibrato, amplitude beats, filter sweeps, soft saturation and a true white noise.
- **The export carries the sounds QOA-compressed** (D-112): 2.3 MB instead of 11.4 MB, staged by
  `make sound-stage` and proven by `make sound-export-smoke` in the exported app. The room tone is
  another 6 dB lower.
