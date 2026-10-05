// Gallery stills (static/img/gallery/). Every image is a real capture from the
// game; captions say what produced it and what it shows. An optional `status`
// marks captures from work still in review, so nothing reads as shipped early.
const GALLERY = [
  {file: 'manual-sky-rest', url: 'https://storage.googleapis.com/stapledons-voyage-assets/refs/manual_sky_v14/rest_side_ship.png', title: 'Manual exposure: stars at rest', caption: 'Current Sol startup with fixed dark-sky exposure and the approved 4× display aid. The captain chooses brightness; looking around no longer triggers automatic dimming.', group: 'ship', status: 'Dev14 review'},
  {file: 'manual-sky-cruise', url: 'https://storage.googleapis.com/stapledons-voyage-assets/refs/manual_sky_v14/cruise_forward_ship.png', title: 'SR during a committed journey', caption: 'An actual committed 0.99c voyage, looking forward at the same manually selected exposure. Aberration and spectral brightness changes retain the existing physical calculations.', group: 'ship', status: 'Dev14 review'},
  {file: 'manual-sky-jupiter-away', url: 'https://storage.googleapis.com/stapledons-voyage-assets/refs/manual_sky_v14/jupiter_stop_away.png', title: 'Stars beside the Jupiter stop', caption: 'Looking away from Jupiter at the actual close stop keeps the selected exposure. The starfield is no longer suppressed by the nearby planet.', group: 'ship', status: 'Dev14 review'},
  {file: 'manual-sky-jupiter-dim', url: 'https://storage.googleapis.com/stapledons-voyage-assets/refs/manual_sky_v14/jupiter_stop_dim.png', title: 'Manual dimming reveals Jupiter', caption: 'The same close Jupiter stop with a dimmer manual exposure. Surface detail is preserved; faint background stars fall below display visibility at this setting. No automatic brightness changes occur.', group: 'ship', status: 'Dev14 review'},
  {file: 'manual-sky-alpha', url: 'https://storage.googleapis.com/stapledons-voyage-assets/refs/manual_sky_v14/alpha_1au_pan_0.png', title: 'Alpha Centauri and its background', caption: 'Actual moving-primary intercept at one AU, viewed with the manual 4× star setting. The physical stellar disc stays visible against the starfield; its photosphere clips white at this exposure.', group: 'ship', status: 'Dev14 review'},
  {file: 'solar-alpha-a-one-au', url: 'https://storage.googleapis.com/stapledons-voyage-assets/refs/solar_departure_v3/acen-a_arrival.png', title: 'Alpha Centauri A at 1 AU', caption: 'The final committed leg stops 1 AU from the moving primary. Its measured 1.2234 solar radii produce a disc about 0.65 degrees wide. Both binary stars retain their catalogue identities; stellar surfaces are uniform photospheres. Gravity and thermal hazards remain outside this demo.', group: 'ship', status: 'Demo review'},
  {file: 'solar-jupiter-approach', url: 'https://storage.googleapis.com/stapledons-voyage-assets/refs/solar_departure_v3/jupiter_approach_80s.png', title: 'Jupiter grows during braking', caption: 'The guided tour brakes for 90 seconds of playback. Physical 1 g deceleration begins far out, so Jupiter grows gradually rather than appearing only at arrival. This capture is near the end of braking, before the stationary side-view turn.', group: 'ship', status: 'Demo review'},
  {"file": "solar-earth_start", "url": "https://storage.googleapis.com/stapledons-voyage-assets/refs/solar_departure_v3/earth_start.png", "title": "Earth beside the bridge", "caption": "The close tour starts at two measured Earth radii from its centre. The ship and sky share the standing observer. Earth uses the Earth–Moon barycentre approximation; this is an inertial stop.", "group": "ship", "status": "Demo review"},
  {"file": "solar-sun_arrival", "url": "https://storage.googleapis.com/stapledons-voyage-assets/refs/solar_departure_v3/sun_arrival.png", "title": "Close Sun stop", "caption": "The measured solar disc at three solar radii. This kinematic review omits gravity and thermal hazards; the Sun is a uniform blackbody emitter, and external ship illumination remains unfinished.", "group": "ship", "status": "Demo review"},
  {"file": "solar-jupiter_arrival", "url": "https://storage.googleapis.com/stapledons-voyage-assets/refs/solar_departure_v3/jupiter_arrival.png", "title": "Jupiter fills the outlook", "caption": "A continuous committed journey brakes to two measured Jupiter radii. A smooth stationary turn places the planet beside the bridge; the moons keep their ephemerides and may lie outside this view.", "group": "ship", "status": "Demo review"},
  {"file": "solar-saturn_arrival", "url": "https://storage.googleapis.com/stapledons-voyage-assets/refs/solar_departure_v3/saturn_arrival.png", "title": "Saturn’s close ring view", "caption": "The stop stays outside Saturn’s measured ring envelope. Ring tilt, opaque decks and the same perspective determine what the captain can see. This is a stop at rest, not a gravity-bound orbit.", "group": "ship", "status": "Demo review"},
  {"file": "ship-grounded-contact", "url": "https://storage.googleapis.com/stapledons-voyage-assets/refs/ship_grounded_v2/grounded_contact.png", "title": "Captain and bridge meet the floor", "caption": "The restored painted deck top is at +82 m. The captain casts a stationary three-dimensional shadow volume with both legs meeting the floor; the visible captain remains painted billboard art.", "group": "ship", "status": "Demo review"},
  {"file": "solar-outbound-v2", "url": "https://storage.googleapis.com/stapledons-voyage-assets/refs/solar_departure_v3/CNS5_3627_braking.png", "title": "Beyond Saturn toward Alpha Centauri", "caption": "The actual committed outbound leg gathers and shifts the star field ahead. The guided 1 g interstellar leg has acceleration and braking with a peak near 0.95c; this distance does not reach the requested 0.99c cap. The same heading carries through both phases.", "group": "ship", "status": "Demo review"},
  {"file": "solar-map_second_departure", "url": "https://storage.googleapis.com/stapledons-voyage-assets/refs/solar_departure_v1/map_second_departure.png", "title": "Navigation from the current ship", "caption": "A second route starts at the ship’s Alpha Centauri endpoint rather than resetting to Sol. Recenter, Fit route and Home frame the map; the destination list is the surveyed catalogue.", "group": "ship", "status": "Demo review"},

  {
    file: 'ship-lighting-bridge-inward',
    url: 'https://storage.googleapis.com/stapledons-voyage-assets/refs/ship_lighting_v1/bridge_inward_moody.png',
    title: 'Painted bridge: warm light and cool shadows',
    caption: 'Standing captain eye on the measured bridge. The painted surfaces receive real shadows from the spire, rails and fronds. This is a fixed internal lighting study; external sunlight is still being integrated. Sky exposure remains 4×.',
    group: 'ship', status: 'Lighting review',
  },
  {
    file: 'ship-lighting-bridge-outward',
    url: 'https://storage.googleapis.com/stapledons-voyage-assets/refs/ship_lighting_v1/bridge_outward_moody.png',
    title: 'Bridge outlook from the same observer',
    caption: 'The ship geometry and live sky use the same camera attitude and perspective. Decks remain opaque; changing the lighting does not change the star field.',
    group: 'ship', status: 'Lighting review',
  },
  {
    file: 'ship-lighting-commons',
    url: 'https://storage.googleapis.com/stapledons-voyage-assets/refs/ship_lighting_v1/commons_arcade_moody.png',
    title: 'Under the Commons arcade',
    caption: 'A warm reading light makes the shaded seating area readable. Teal ribs, painted terraces and the first planted bays are playable; further Commons detail and the other tiers remain unfinished.',
    group: 'ship', status: 'Lighting review',
  },
  {
    file: 'sky-rest.jpg',
    title: 'At rest, looking toward the galactic centre',
    caption:
      'The naked-eye sky from Sol at β = 0: 335,157 catalogue stars over the star-removed Milky Way panorama, exposed for a dark-adapted eye (EV −4.4).',
    group: 'sky',
  },
  {
    file: 'sky-060c.jpg',
    title: '0.60c: the sky starts to gather ahead',
    caption:
      'β 0.5955, γ 1.245, 0.665 ship-years into a 1 g burn. Aberration pulls the Milky Way forward and Doppler boosting brightens it. Same exposure as at rest.',
    group: 'sky',
  },
  {
    file: 'sky-091c.jpg',
    title: '0.91c: a blue-white crowd in front',
    caption:
      'β 0.9126, γ 2.446. Stars from the whole forward hemisphere squeeze toward the bow, shifted blue and brightened; the edges of the view go dark.',
    group: 'sky',
  },
  {
    file: 'sky-099c.jpg',
    title: '0.99c: the universe in a window',
    caption:
      'β 0.990000, γ 7.089: 2.564 years on the ship clock, 6.798 on Earth\'s. Most of the visible sky now sits in a cone a few tens of degrees across.',
    group: 'sky',
  },
  {
    file: 'cmb-gamma-275.jpg',
    title: 'The forward CMB disc at γ 275',
    caption:
      'The 2.7 K cosmic microwave background, Doppler shifted to 1,500 K straight ahead (check value HB-67), glows orange in the bow among the last crowded stars. The eye has light-adapted (EV +0.2).',
    group: 'cmb',
  },
  {
    file: 'cmb-gamma-707.jpg',
    title: 'γ 707, the cruise cap: the CMB at 3,854 K',
    caption:
      'At 0.999999c the forward CMB is a 3,853.7 K blackbody (check value HB-63), brighter than every star around it.',
    group: 'cmb',
  },
  {
    file: 'milky-way-destarred.jpg',
    title: 'The Milky Way, with the catalogue stars taken out',
    caption:
      'The NOIRLab all-sky panorama (E. Slawik / NOIRLab / NSF / AURA, CC BY 4.0) after the AILANG destar pass removed the photo stars the catalogue draws itself, so stars are not counted twice. The renderer recolours each texel as a blackbody.',
    group: 'sky',
  },
  {
    file: 'map-plan.jpg',
    title: 'Galaxy map: plan a journey',
    caption:
      'Every number on the panel comes from the AILANG simulation: ship-years, Earth-years, boost energy, drag, the forward CMB temperature. Here: α Centauri A at 0.999917c, 0.0556 ship-years against 4.321 Earth-years.',
    group: 'map',
  },
  {
    file: 'map-commit.jpg',
    title: 'Commit, and you cannot take it back',
    caption:
      '"A commitment cannot be undone. Hold for 1.5 s to commit." At 0.99c, 0.6157 years for you and 4.365 for everyone at home.',
    group: 'map',
  },
  {
    file: 'map-transit.jpg',
    title: 'In transit: Cancel is refused',
    caption:
      'The simulation, not the UI, owns the commit rule. Mid-cruise the ship clock reads +0.32 yr while Earth\'s reads +2.24 yr.',
    group: 'map',
  },
  {
    file: 'map-arrived.jpg',
    title: 'Arrival',
    caption:
      'Arrived at α Centauri A: +0.6212 years on the ship clock, +4.3702 on Earth\'s. The energy radiated over the whole trip equals the plan, 6.112e17 J.',
    group: 'map',
  },
  {
    file: 'map-overview.jpg',
    title: 'The neighbourhood, from the real catalogues',
    caption:
      'The galaxy map drawn from the binary catalogue tiers: the 5,687 stars within 25 pc, Sol at the centre (M1.7).',
    group: 'map',
  },
];

export default GALLERY;
