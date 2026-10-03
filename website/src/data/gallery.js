// Gallery stills (static/img/gallery/). Every image is a real capture from the
// game; captions say what produced it and what it shows. An optional `status`
// marks captures from work still in review, so nothing reads as shipped early.
const GALLERY = [
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
