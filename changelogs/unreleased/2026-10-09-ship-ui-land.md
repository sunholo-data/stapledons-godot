### Changed

- **R1-SHIP-UI U6–U8 (landing PR).**
  - **Migration:** `tools/exposure_sky_recovery.gd` opens the helm before it plans. The free-navigation test and `tools/stops_capture.gd` already did so in PR 2.
  - **Helm readability:** the embedded map scales to fit the panel (minimum 0.62 of full size) and the panel's explanatory line moved into its title. Map text now reads at about 12 px at 1280×720.
  - **Dwell label:** names only named stars and resolved bodies; an unnamed catalogue row is the I card's job. It hides while the cruise interlude card shows and stays clear of the card column.
- **Renders:** `make ship-ui-capture` writes 24 frames to `renders/ship_ui/`, 12 states at 1280×720 and 2560×1440, plus `contact_sheet.png`. The states: strip at rest, the prompt at the navigation station, the helm, the chart, the Voyage console, the Archive terminal, transit in cruise, the cruise interlude, arrival, the guided voyage at a dwell, Sgr A* gravity, and the lower deck.
- **Docs:** the design-doc index row, and the M4.5 bot hook (`ShipConsoles.walk_to` and `use`) in `design_docs/planned/r1/m4.5s-inventory.md`.
