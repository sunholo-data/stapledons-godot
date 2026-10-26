# make sound-levels-parity: tools/sound_check.gd's offline measures (input: measure.json, dB snapped
# to 0.01) against sunholo/audio's (--slurpfile l levels.json, centi-dB). Prints one line per
# difference; nothing when they agree. Mixer entries (keys starting "_") are GDScript-only.
def c: if . == null then null else . * 100 | round end;
($l[0]) as $a
| (to_entries | map(select(.key | startswith("_") | not)) | from_entries) as $g
| ( ($g | keys) - ($a | keys) | map("\(.): measured by sound_check.gd only") )
+ ( ($a | keys) - ($g | keys) | map("\(.): measured by sound-levels only") )
+ [ $g | to_entries[] | .key as $k | .value as $v | ($a[$k] // empty) as $w
    | ["peak", ($v.peak_dbfs | c), $w.peak_cdb], ["rms", ($v.rms_dbfs | c), $w.rms_cdb],
      ["highpass150", ($v.highpass150_keep_db | c), $w.highpass150_keep_cdb], ["below_200hz", ($v.below_200hz_db | c), $w.below_200hz_cdb]
    | select(.[1] != .[2]) | "\($k) \(.[0]): sound_check.gd \(.[1]) sound-levels \(.[2]) (centi-dB)" ]
| .[]
