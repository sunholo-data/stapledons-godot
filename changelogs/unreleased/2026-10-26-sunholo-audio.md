### Changed

- **The sound tools use the `sunholo/audio` package** (R2-SUNHOLO-AUDIO, D-119). The game's
  synthesised sounds are now rendered by the published AILANG package (pinned 0.5.0) instead of a
  copy in the game; every sound is byte-identical. The loudness checks (bands, the laptop-speaker
  high-pass, the teacup rule) also run in AILANG now (`make sound-levels`), and agree with the
  Godot-side checks on every cue.
