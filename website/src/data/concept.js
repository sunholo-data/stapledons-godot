// Concept and work-in-progress art (src/pages/concept-art.js). Thumbnails are
// small JPGs in static/img/concept/; `full` is the full-size image in the public
// asset bucket (content-addressed under site/, or the shared refs/ folder).
// No spoilers: captions describe look, role and status, never story.
const B = 'https://storage.googleapis.com/stapledons-voyage-assets';

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
