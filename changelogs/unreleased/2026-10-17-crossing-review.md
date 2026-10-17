### Added

- **The crossing review (R2-INTERLUDE, protocol 2.10).**
  - The cruise is crossed in chunks the sim publishes (`cruise {next_stop_years, stop_kind}`).
  - A crew hold stops the crossing on its check-in day.
  - The crossing ends in a review the player reads at their own pace: the crossing, home (a picture per home tier), aboard, moments with faces, who changed, the medium, and who is waiting.
  - Every number comes from the pure sim's cruise digest. Streams below 2.10 are unchanged.
- **The Archive narrates.**
  - Authored, in-world framing lines appear on the crossing and aboard pages.
  - With live AI and a key, the Archive tells the crossing once in its own words. The telling is recorded as sim input and voiced once.

### Changed

- The 6-second interlude card is gone; no timer dismisses the review.
- After arriving, the view can be turned without first dismissing the card. While the review is open, right-drag or Alt/Option+move looks around, and one centred line says what to press.
- The HUD's Braking notice waits until the player brakes.

### Fixed

- News from home no longer says "Only 0.00 years have passed there since you left". `{elapsed_years}` is when the message left home, and a message sent right after departure says "within days of your departure".
