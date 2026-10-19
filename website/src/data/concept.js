// Concept and work-in-progress art (src/pages/concept-art.js). Thumbnails are
// small JPGs in static/img/concept/; `full` is the full-size image in the public
// asset bucket (content-addressed under site/, or the shared refs/ folder).
// No spoilers: captions describe look, role and status, never story.
const B = 'https://storage.googleapis.com/stapledons-voyage-assets';

export const SHIP_LAYERS = {
  file: 'ship-layers-v1.jpg',
  full: `${B}/refs/ship_layers_v1/ship_layers_concept_v1.png`,
  title: 'Ship layers: whole-ship cutaway and bridge-rim roots',
  caption:
    'Style concept v1 for review, 4 October 2026. Proportions and sightlines are illustrative, not dimensionally reliable. One central spire inside a spherical bubble; the bridge is the highest occupied deck. Lower levels widen toward the equator, and the rim detail proposes attached supports rising from below. Zoning and mezzanines are proposals; the boundary outline is a reference aid, not a physics rendering.',
};

export const CAPTAIN = {
  sheet: {
    file: 'captain-sheet.jpg',
    full: `${B}/site/2c1a7fcf053ac09586eab3ff2025820a196526ef9fc0e1ee692f3d89cb849dde.jpg`,
    title: 'The captain: the Longline Navigator, life-stage sheet',
    caption:
      'Front and back at ages 30, 50, 70 and 90, with the small figure-height checks the isometric decks need. Cream longline coat, ochre shoulder yoke, violet trousers. Picked by Mark on 3 October 2026 from three silhouette proposals (game PR #98).',
  },
  stages: [30, 50, 70, 90].map((age) => ({
    file: `captain-age${age}.jpg`,
    full: {
      30: `${B}/site/518abff565570a9fdd5057fd7eb9e3342ffde724bbea5b459f1c0d9acc843114.jpg`,
      50: `${B}/site/6dbaa536e388f9c789581d9740ee3c6160289b575c2bae76c78c7c62ed87e959.jpg`,
      70: `${B}/site/bead1aee97a5987da94f760e10a1ea116f9b9fe75f719fb2fb1be903d7a2169b.jpg`,
      90: `${B}/site/1b68bb741386e1742e66904bcf0ec3593d7bde714491cf40cd13f1750cd9ca48.jpg`,
    }[age],
    title: `Age ${age}`,
  })),
};

export const MEDIC = ['neutral', 'loving', 'grieving'].map((emotion) => ({
  file: `medic-${emotion}.jpg`,
  full: `${B}/refs/characters_v1/portrait_medic_age0_${emotion}_v2.png`,
  title: emotion[0].toUpperCase() + emotion.slice(1),
}));

// The cast proposals: roles only. Names, ages and everything else are open.
const ROLES = [
  ['engineer', 'Engineer'],
  ['scientist', 'Scientist'],
  ['pilot', 'Pilot'],
  ['diplomat', 'Diplomat'],
  ['quartermaster', 'Quartermaster'],
  ['analyst', 'Analyst'],
  ['skeptic', 'Skeptic'],
  ['zealot', 'Zealot'],
  ['dreamer', 'Dreamer'],
  ['fantasist', 'Fantasist'],
];
export const CREW = ROLES.map(([id, role]) => ({
  file: `crew-${id}.jpg`,
  full: `${B}/refs/characters_v1/portrait_${id}_age0_neutral_v1.png`,
  title: role,
}));

export const BRIDGE_V1 = [
  {
    file: 'bridge-v1-rest.jpg',
    full: `${B}/site/db5eea7b5807c64406c59666a28df52bd0dab97fdff05911fdc5f3f6db0fcb5e.png`,
    title: 'Bridge v1 in the engine, at rest',
    caption:
      'The bridge disc at the top of the spire, rendered in Godot over the live sky: the Milky Way behind the railings is the real panorama, drawn through the same camera. Flat toon shading and contour ink; blockout figures.',
  },
  {
    file: 'bridge-v1-parallax.jpg',
    full: `${B}/site/8a19a25f28841c54febb04f5a579b02062372e67e810b0c16b8fd1bd694164d4.png`,
    title: 'Parallax check: rest and 0.99c',
    caption:
      'The camera pans 6 m left and right. The deck moves; the sky stays fixed at infinity. In the bottom row the ship cruises at 0.99c and the same window shows the sky crowded forward and blue-shifted, the physics from the sky flight composited behind the art.',
  },
  {
    file: 'bridge-v1-walk-map.jpg',
    full: `${B}/site/56c1a3b8e964a83e2afc6e237ec0faf1f9edd7453023e2791b2edb13266414a7.png`,
    title: 'Walk map',
    narrow: true,
    caption: 'The walkable floor (green) and the obstacles (red): consoles, benches and the spire at the centre, with the way off the bridge at the lower left.',
  },
];

export const BRIDGE_V2 = [
  {
    file: 'bridge-v2-study.jpg',
    full: `${B}/refs/bridge_v2_study/sheet_hero.jpg`,
    title: 'Bridge v2 quality study: four treatments',
    caption:
      'v1 as shipped (flat toon, contour ink) against three candidate finishes: textured with hatching, a richer kit, and an illustrated plate projected onto the geometry.',
  },
  {
    file: 'bridge-v2-vs-captain.jpg',
    full: `${B}/refs/bridge_v2_study/sheet_vs_captain.jpg`,
    title: 'Treatment c in the engine, beside the captain',
    caption:
      'A Godot capture of the illustrated treatment with the live sky and the captain sprite on deck, next to the captain sheet it has to match.',
  },
];

// The crossing review's Home page (game design home-tiers, ledger D-86): the same headland as Earth's
// time runs on, in sixteen home-time tiers, each a pool of variants (a voyage shows one per tier).
// Codex gpt-6.1-sol, 16 and 19 October 2026; prompts and every candidate are in the game repo's
// data/interlude/home/generation_notes.md. Spoiler policy (website/news/README.md): tiers 0-12 only,
// titled by time range, no captions; the later tiers are story (design_docs home-tiers.md, H4).
// Rows: [tier, variant, master sha256 (public bucket site/<sha>.png; the game's SOURCES row)].
const HOME_TITLES = [
  'Less than a year',
  'A year or two',
  'Under ten years',
  'Under twenty years',
  'Under thirty-five years',
  'Under fifty-five years',
  'Under ninety years',
  'Under 130 years',
  'Under 250 years',
  'Under 500 years',
  'Under a thousand years',
  'Under 3,000 years',
  'Under 10,000 years',
];
const HOME_ROWS = [
  [0, 0, '8513eb0ea5063524e0c0008b8781834a5953fabbb88848869334782d67911e1c'],
  [1, 0, 'e84b4c60618535859df1ed51059d31661cd94220be6dfd1fc11b8dac16ccf04c'],
  [1, 1, 'e21318eea283186e7d676e047b358a725d308d79e23f7d6912d20ec91fa61cf7'],
  [2, 0, '96e30bed8c7d2921809462c8c89eff59c00282ab3bd653ed9da5b6e1c8a6057b'],
  [3, 0, '025203d7aefe6f23f1e21bf341fcd22498082b00b43781584d33e831d9887a13'],
  [3, 1, 'ada1a11de6a3897ec27e71fcc5027fcd6faed079e0c6497cb36239ad0a69fc0e'],
  [4, 0, '0229d2d94f01c08dc96e96e957f3b6b6942003885a5aaa40c39b4e1a1f0b12c9'],
  [4, 1, 'befdf3afea8ba8e87cd8022e2e08e5b7f0a5f16cfe516975521cb858846e15e4'],
  [5, 0, '752c3d7f713858e8d5df136f6986ffcd175b1c0733c5fddaac03ee04f07a99da'],
  [5, 1, 'd2ffc831e5d5b15fc419aa1e67bea96fd11e7a8be438d8cf867a69b9bb568e8a'],
  [6, 0, '9f44e1145f389c5d3439b4dc67b75f8ae52f812433c1126a117e591e2b9e0ff8'],
  [6, 1, 'ef141b439650632df69c1f2c14f576796dd92b7519aab350a433a6b7b82b9b50'],
  [7, 0, 'a6cc3f8df55cdf397b4440ce6ba28328c15e2243b0c4617b9c303cdadd788f98'],
  [7, 1, '4bad13905b51de1fe3f58b68fc460432d0002fed6826d6aa0ee395a56fb5f557'],
  [8, 0, 'bfd69e924ea322aec5cc4fa2744ee19c9d2f57886acb8ae7bf2ea68f72e29e70'],
  [8, 1, 'acd42fd8df31169f18574a60974757cfa884ec21b67e2bd97d4a8b1894dded7d'],
  [9, 0, '58bce70d3280c407c642766016130d41ad1b5c7c46238d399188138e59a0164a'],
  [9, 1, '257cf9290a022a4bcfc2c5a21bc7c65df8818054c36e4a6a898096af63da00fc'],
  [10, 0, 'b55a3c62fde9c1dfe1719357093d50b1b7041b4e3570ccc26c070341e9229453'],
  [11, 0, 'e82a9dd41cc90fb0dc7d79092ad70b69f60390234c6b34988a5bce8878199fd8'],
  [11, 1, 'ff5fbc304faa10f18b47f993c8ff5d56c5e127b1dfa6d46fea93d40d10423e98'],
  [12, 0, '458bcb676e8c4c1ce8ba80adf0c13ad5fc9e038681f7e1d348318533f43ae6e3'],
  [12, 1, 'a175bc08ebdb89a1cd93849a1103802582de34514046e0e31c935c9b53615886'],
];
export const HOME = HOME_ROWS.map(([tier, variant, sha]) => ({
  file: `home-t${String(tier).padStart(2, '0')}-v${variant}.jpg`,
  full: `${B}/site/${sha}.png`,
  title: HOME_TITLES[tier],
}));
