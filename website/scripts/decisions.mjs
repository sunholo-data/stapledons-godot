#!/usr/bin/env node
// Decisions page data (website/src/pages/decisions.js), generated at build time.
//
//   node scripts/decisions.mjs          parse the sources -> src/data/decisions.json
//                                       (+ scripts/decisions-excluded.txt, the spoiler audit)
//   node scripts/decisions.mjs --sync   fetch the design repo's vision/design-decisions.md at the
//                                       latest main commit into vendor/ and pin that commit
//
// Sources (never hand-copied):
//   1. the game repo's decision ledger: the `## Decision ledger` table in
//      design_docs/stapledon-mission.md, read from this checkout;
//   2. the design repo's vision/design-decisions.md, VENDORED at a pinned commit
//      (vendor/design-decisions.md + vendor/design-decisions.pin). The build stays offline and
//      reproducible; run --sync to pick up new design decisions, and commit the two files;
//   3. a few attended rulings recorded in other repo files (SUPPLEMENTARY below), located at build
//      time by a needle string so the source line stays exact. A missing needle fails the build.
//
// No spoilers (Mark, 2026-10-03): rows about story or narrative outcomes (endings, endgame,
// plot, crew fates, legacy-screen contents, scripted events, lore beyond physics) are excluded by
// a keyword heuristic plus explicit ALLOW / DENY maps (deny wins). Every exclusion is printed and
// written to scripts/decisions-excluded.txt for audit.
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const SITE = path.resolve(HERE, '..');
const REPO = path.resolve(SITE, '..');
const LEDGER = 'design_docs/stapledon-mission.md';
const VENDOR = path.join(SITE, 'vendor', 'design-decisions.md');
const PIN = path.join(SITE, 'vendor', 'design-decisions.pin');
const OUT = path.join(SITE, 'src', 'data', 'decisions.json');
const AUDIT = path.join(HERE, 'decisions-excluded.txt');
const GAME = 'https://github.com/sunholo-data/stapledons-godot';
const DESIGN = 'https://github.com/sunholo-data/stapledons-design';

// ---------------------------------------------------------------- overrides
// Short titles for ledger rows (the ledger has none; the text is the question).
const TITLES = {
  'D-1': 'Ratify the mission bar and guardrails',
  'D-2': 'Photometry amendments (Riello cross-check)',
  'D-3': 'Which star tiers live in git',
  'D-4': 'White dwarfs: approximate blackbody, flagged',
  'D-5': 'A bright-star tier from Hipparcos',
  'D-6': 'Interior: isometric three-layer view under the live sky',
  'D-7': 'Characters are generated portraits with voices and emotion markers',
  'D-8': 'Runtime AI: the player\'s own key, model-neutral, no live voice',
  'D-9': 'Queue the AI service foundation',
  'D-10': 'Milky Way background: the NOIRLab panorama',
  'D-11': 'The Higgs bubble is the one hand-wave',
  'D-12': 'Calendar, manual flight and the commit ritual',
  'D-13': 'Black-hole check values and the demo hole',
  'D-14': 'First-journey defaults (0.99c, 1,000 AU stand-off, art stop)',
  'D-15': 'Glazing, the γ range, boundary optics, bubble defaults',
  'D-16': 'Bridge v1 approved for build-out; Medic review stage closed',
  'D-17': 'Galaxy map shows catalogue distances and common star names',
  'D-18': 'Large assets and build distribution',
  'D-19': 'Remaining sky plan; the naked eye is the default exposure',
  'D-20': 'Who pays for AI, and the player\'s spend ceiling',
  'D-21': 'No digits in generated text; length caps 280/280/600',
  'D-22': 'Approve the first-journey sprint plan',
  'D-23': 'α Centauri at the catalogue distance, 4.32 ly',
  'D-24': 'CI reads the now-public design repo',
  'D-25': 'Exposure anchors: Milky Way 20.8, deep space 23.5 mag/arcsec²',
  'D-26': 'A new milestone: planets and flybys (M5)',
  'D-27': 'Forward CMB glare and auto-dimming glazing',
};

// Groups. Primary view: look (visual), sound (audio), words (text). Secondary: physics, gameplay,
// ai, planets, infra, process. An id may sit in several groups; the first is its home.
const GROUPS_BY_ID = {
  'D-1': ['process'], 'D-2': ['physics'], 'D-3': ['infra'], 'D-4': ['physics', 'visual'],
  'D-5': ['physics', 'visual'], 'D-6': ['visual', 'gameplay'], 'D-7': ['visual', 'audio', 'ai'],
  'D-8': ['ai', 'audio'], 'D-9': ['process', 'ai'], 'D-10': ['visual', 'physics'],
  'D-11': ['physics'], 'D-12': ['gameplay', 'text'], 'D-13': ['physics'],
  'D-14': ['gameplay', 'visual', 'text'], 'D-15': ['physics', 'visual'], 'D-16': ['visual'],
  'D-17': ['text', 'gameplay'], 'D-18': ['infra'], 'D-19': ['visual', 'physics', 'process'],
  'D-20': ['ai', 'infra'], 'D-21': ['text', 'ai'], 'D-22': ['process'],
  'D-23': ['physics', 'text'], 'D-24': ['infra'], 'D-25': ['visual', 'physics'],
  'D-26': ['planets', 'visual'], 'D-27': ['visual', 'physics'],
  // design repo (key: date + title slug prefix)
  'DD-2025-12-03-special-relativity-visual-effects': ['visual', 'physics'],
  'DD-2025-12-08-parallax-and-sr-visual-thresholds': ['visual', 'physics'],
  'DD-2025-12-08-boundary-glow-as-motion-cue': ['visual', 'physics'],
  'DD-2025-12-08-departure-cruise-arrival-parallax-lifecycle': ['visual', 'physics'],
  'DD-2025-12-08-higgs-bubble-ship-10-20-levels-around-spire': ['visual', 'gameplay'],
  'DD-2025-12-08-visual-aesthetic-french-70s-comic': ['visual'],
  'DD-2025-12-08-spire-monolithic-superstructure': ['visual', 'gameplay'],
  'DD-2025-12-08-ship-orientation-vertical-thrust-axis': ['physics', 'visual'],
  'DD-2025-12-08-open-levels-views-outward-through-bubble': ['visual'],
  'DD-2025-12-18-pivot-from-isometric-to-first-person-3d': ['visual'],
  'DD-2025-12-20-interior-ship-experience-scene-based': ['visual', 'gameplay'],
  'DD-2026-09-28-interior-isometric-three-layer-view': ['visual', 'gameplay'],
  'DD-2026-09-28-character-and-exterior-review': ['visual'],
  'DD-2026-09-28-runtime-ai-voices-emotion-markers': ['ai', 'audio', 'visual'],
  'DD-2026-09-28-runtime-ai-operating-model': ['ai'],
  'DD-2026-10-01-the-higgs-bubble-model-and-the-journey': ['physics'],
  'DD-2026-10-01-vertical-slice-0-99c-default': ['gameplay'],
  'DD-2026-10-01-shielding-range-boundary-optics': ['physics', 'visual'],
  'DD-2026-10-01-art-status-bridge-v1-approved': ['visual'],
  'DD-2026-10-03-art-handoffs-for-m4-2': ['visual', 'process'],
  'DD-2026-10-03-art-handoff-follow-ups': ['visual', 'audio'],
  'DD-2025-12-06-radiation-shielding-automatic': ['physics', 'visual'],
  'DD-2025-12-06-garden-cathedral': ['visual', 'gameplay'],
  'DD-2025-12-06-observation-deck-as-decision-hub': ['visual', 'gameplay'],
  'DD-2025-12-06-archive-reputation-dynamics': ['gameplay', 'ai'],
  'DD-2025-12-06-bubble-society-as-living-sim': ['gameplay'],
  'DD-2025-12-06-internal-tension-model': ['gameplay'],
  'DD-2025-12-06-captain-archive-authority-coupling': ['gameplay', 'ai'],
  'DD-2025-12-06-the-spire-as-universal-constant': ['physics', 'visual'],
  'DD-2025-11-29-core-pillars-established': ['process'],
  'DD-2025-12-02-detection-model-epistemic-gap': ['gameplay', 'planets'],
};

// Keyword fallback for ids not in GROUPS_BY_ID.
const KEYWORDS = [
  ['audio', /\b(voice|voices|audio|tts|sound|music|ogg|wav)\b/i],
  ['visual', /\b(visual|art|aesthetic|portrait|interior|render|panorama|palette|glow|parallax|style frame|exterior|camera|hud)\b/i],
  ['text', /\b(text|wording|lore|archive entry|codex|subtitle|names?)\b/i],
  ['ai', /\b(ai|generated|llm|model-neutral|gemini|openrouter)\b/i],
  ['planets', /\bplanet/i],
  ['physics', /\b(relativ|gamma|γ|bubble|physics|black hole|tid(e|al)|cmb|aberration|doppler|mass|radiation)\b/i],
  ['infra', /\b(bucket|gcp|ci|build|git|deploy)\b/i],
  ['process', /\b(sprint|queue|charter|plan)\b/i],
];

// Visual / audio / text sub-groups get a finer label for the chips.
const SUBTOPIC = {
  'D-6': 'Interior', 'D-7': 'Characters', 'D-10': 'Sky', 'D-14': 'Art stop', 'D-15': 'Glazing',
  'D-16': 'Bridge and Medic', 'D-19': 'Exposure', 'D-25': 'Exposure', 'D-27': 'CMB glare',
  'D-21': 'Generated text', 'D-17': 'Map labels', 'D-4': 'Sky', 'D-5': 'Sky',
};

// Explicit relations. [from, kind, to | {note}] — kind: supersedes | refines | records.
// Parsed relations (below) are added to these.
const RELATIONS = [
  ['D-6', 'supersedes', 'DD-2025-12-18-pivot-from-isometric-to-first-person-3d'],
  ['D-6', 'supersedes', 'DD-2025-12-20-interior-ship-experience-scene-based'],
  ['D-15', 'supersedes', 'DD-2025-12-06-radiation-shielding-automatic'],
  ['D-15', 'supersedes', 'DD-2025-12-02-gamma-cap-10-20-default'],
  ['D-23', 'refines', 'D-19'],
  ['D-25', 'refines', 'D-19'],
  ['D-27', 'refines', 'D-25'],
  ['DD-2026-10-03-art-handoff-follow-ups', 'refines', 'D-16'],
  ['DD-2026-10-03-art-handoff-follow-ups', 'refines', 'DD-2026-10-03-art-handoffs-for-m4-2'],
  ['DD-2026-10-03-art-handoffs-for-m4-2', 'supersedes', {note: 'the 2048 px portrait target in the character brief and the cast plan (now the generator\'s native ~1254 px, never upscaled)'}],
  ['DD-2026-10-03-art-handoffs-for-m4-2', 'supersedes', {note: 'the fixed +0/+25/+50/+75 age grid (now stages 0/20/40/60 years since departure)'}],
  ['SUP-captain-pick', 'refines', 'DD-2026-10-03-art-handoff-follow-ups'],
  ['SUP-swap-timing', 'refines', 'D-7'],
  ['SUP-voice-format', 'refines', 'D-7'],
  ['SUP-voice-aoede', 'refines', 'D-20'],
];

// Explicitly provisional: shown with a "Revisit" marker.
const REVISIT = {
  'D-16': 'Bridge v1 is demo art: approved for build-out, iterated as data; final bridge art (v2) is in progress.',
  'DD-2026-10-01-art-status-bridge-v1-approved': 'Bridge v1 is demo art; final art in progress.',
  'DD-2026-10-03-art-handoffs-for-m4-2': 'The filled-in details are proposals Mark can change on the PRs.',
  'SUP-voice-aoede': 'Pending: the Medic\'s voice waits for an audition of three voices (⏸ C).',
  'SUP-voice-format': 'The voice heard today is a stub placeholder, not a real voice.',
  'SUP-swap-timing': 'Tuned on the stub voice; recheck with the real voice.',
};

// Assets shown beside a decision (paths under static/).
const ASSETS = {
  'SUP-captain-pick': [{img: 'img/decisions/captain-sheet.jpg', caption: 'The Longline Navigator at 30, 50, 70 and 90, front and back (game PR #98).'}],
  'DD-2026-10-03-art-handoff-follow-ups': [{img: 'img/decisions/captain-sheet.jpg', caption: 'The captain sprite as ruled: stages 0/20/40/60 years since departure.'}],
  'D-16': [{img: 'img/decisions/bridge-v1.jpg', caption: 'Bridge v1 in the engine, live sky behind (demo art).'}, {img: 'img/decisions/bridge-v2-study.jpg', caption: 'Bridge v2 quality study: style study, final art in progress.'}],
  'DD-2026-10-01-art-status-bridge-v1-approved': [{img: 'img/decisions/bridge-v1.jpg', caption: 'Bridge v1 in the engine (demo art).'}],
  'D-6': [{img: 'img/decisions/bridge-v1.jpg', caption: 'The three layers in the engine: play area, ship structure, live relativistic sky.'}],
  'SUP-swap-timing': [{img: 'img/decisions/medic-swap.webp', poster: 'img/decisions/medic-swap-still.jpg', caption: 'The Medic rehearsal: portraits swap 150 ms ahead of each segment with a 120 ms crossfade (stub voice).'}],
  'D-7': [{img: 'img/decisions/medic-swap-still.jpg', caption: 'A generated portrait swapped by an emotion marker (Medic rehearsal, stub voice).'}],
  'SUP-voice-format': [{audio: ['audio/medic-line-stub.ogg', 'audio/medic-line-stub.mp3'], caption: 'Placeholder: the stub voice is a steady test tone, not a voice.'}],
  'SUP-voice-aoede': [{audio: ['audio/medic-line-stub.ogg', 'audio/medic-line-stub.mp3'], caption: 'Placeholder: stub tone until the audition picks a voice.'}],
  'D-25': [{img: 'img/decisions/exposure-sheet.jpg', caption: 'Starboard at rest (top) and at 0.99c (bottom): eye default, camera auto, camera fixed at the rest EV.'}],
  'D-19': [{img: 'img/decisions/exposure-sheet.jpg', caption: 'The default dark-adapted eye beside the labelled camera modes.'}],
  'D-10': [{img: 'img/gallery/milky-way-destarred.jpg', caption: 'The NOIRLab panorama with the catalogue stars removed.'}],
  'D-27': [{img: 'img/gallery/cmb-gamma-707.jpg', caption: 'The forward CMB at γ 707 today: a clean disc, no glare yet.'}],
  'D-17': [{img: 'img/gallery/map-plan.jpg', caption: 'The galaxy map with common star names and the catalogue id as subtitle.'}],
  'D-12': [{img: 'img/gallery/map-commit.jpg', caption: 'The commit ritual: both clocks, years left, a 1.5 s hold.'}],
};

// Supplementary attended rulings recorded outside the two ledgers.
const SUPPLEMENTARY = [
  {
    id: 'SUP-captain-pick', date: '2026-10-03', title: 'The captain: proposal A, the Longline Navigator',
    file: 'assets/characters/captain/generation_notes.md', needle: 'Mark picked proposal A',
    groups: ['visual'], subtopic: 'Characters', prs: [98],
    provenance: 'Recorded in the captain set\'s generation notes (game PR #98); the eight final views are proposed for visual review, the identity choice is picked.',
    question: 'Which of the three captain silhouette proposals becomes the captain?',
  },
  {
    id: 'SUP-swap-timing', date: '2026-10-03', title: 'Portrait swaps 150 ms early, 120 ms crossfade',
    file: 'design_docs/planned/r1/ai-service-foundation-sprint.md', needle: "Mark's rulings (attended 2026-10-03): swap timing",
    groups: ['audio', 'visual'], subtopic: 'Voice and portraits', prs: [91], until: '; keep the WAV',
    provenance: 'Attended ruling during the AI.10a Medic style frame, recorded in the sprint plan.',
    question: 'When should the portrait swap relative to the voice segment, and how long is the crossfade?',
  },
  {
    id: 'SUP-voice-format', date: '2026-10-03', title: 'Voice files: Ogg canonical, WAV playback copy',
    file: 'design_docs/planned/r1/ai-service-foundation-sprint.md', needle: 'keep the WAV playback copy, the Ogg canonical', prefix: "Mark's rulings (attended 2026-10-03): ",
    groups: ['audio'], subtopic: 'Voice format', prs: [91], until: ', and AI.10b',
    provenance: 'Attended ruling during the AI.10a Medic style frame, recorded in the sprint plan.',
    question: 'Godot 4.7 cannot play Ogg Opus; keep a WAV copy beside each voice blob?',
  },
  {
    id: 'SUP-voice-aoede', date: '2026-10-02', title: 'The Medic\'s voice: Aoede, after an audition',
    file: 'design_docs/planned/r1/ai-service-foundation-sprint.md', needle: '| 9 Voice | Aoede after an audition',
    groups: ['audio', 'ai'], subtopic: 'Voice casting', prs: [],
    provenance: 'D-20 ruling 9 (Mark, attended 2026-10-02), as applied in the AI sprint plan; the audition is pause point C.',
    question: 'Which generated voice speaks for the Medic?',
  },
  {
    id: 'SUP-ai-markers', date: '2026-10-02', title: 'Emotion markers are {emotion}; speech per segment',
    file: 'design_docs/planned/r1/ai-service-foundation-sprint.md', needle: '| 6 Marker syntax |', rows: 2,
    groups: ['text', 'audio', 'ai'], subtopic: 'Markers', prs: [],
    provenance: 'D-20 rulings 6 and 7 (Mark, attended 2026-10-02), as applied in the AI sprint plan.',
    question: 'How are emotion markers written in generated text, and how is speech generated?',
  },
];

// ------------------------------------------------------------- no spoilers
const SPOILER = /\b(end[- ]?screen|endgame|ending|legacy (report|screen)|year 1,?000,?000|new game\s*\+|new game plus|mutiny|death|dies|died|succession|memory loss|fate|salvation|mytholog|fermi|universe-hopper|narrative|story|plot|twist|secret|orchestrator|earth contact|earth return|wanderer|time-skip|time skip|crew fates?|drift hidden|game end|recursion|across universes|collapse|mystery)\b/i;
// deny wins over allow
const DENY = new Set([
  'D-13', // physics, but the ruling names where near-horizon dives lead (endgame mechanics)
  'DD-2026-10-01-demo-black-hole-sgr-a-because-of-tides',
  'DD-2026-09-28-generation-ship-casting-direction', // cast ages, families and succession
  'DD-2025-12-02-game-starts-post-black-hole', // the game's premise and backstory
  'DD-2025-12-02-human-incompatibility-theme', // a story theme
  'DD-2025-12-06-memory-health-hidden', // hidden state revealed later
  'DD-2025-12-06-archive-repair-as-player-choice', // Archive storyline
  'DD-2025-11-30-ocean-values-drift-over-time', // revealed on the end screen
  // parent review: Spire and Archive lore, and long-horizon society outcomes
  'DD-2025-12-06-the-spire-as-universal-constant',
  'DD-2025-12-08-spire-monolithic-superstructure',
  'DD-2025-12-06-archive-as-spire-interface',
  'DD-2025-12-06-archive-as-npc-with-individual-trust',
  'DD-2025-12-06-archive-reputation-dynamics',
  'DD-2025-12-06-archive-uses-ocean-personality',
  'DD-2025-12-06-captain-archive-authority-coupling',
  'DD-2025-12-08-archive-distributed-terminals-plus-robots',
  'DD-2025-12-06-internal-tension-model',
  'DD-2025-12-06-bubble-society-as-living-sim',
  'DD-2025-12-02-three-distance-regimes', // what is found at what distance
  'DD-2026-09-28-runtime-ai-voices-emotion-markers', // names the spire's mystery and the Archive's core
]);
const ALLOW = new Set([
  'DD-2026-09-28-character-and-exterior-review', // "the story prefers" a sphere: art only
  'D-11', // "in-game lore" refers to physics explainers
  'DD-2026-10-01-the-higgs-bubble-model-and-the-journey',
  'D-20', 'D-24', // "Secret Manager", not a story secret
  'DD-2025-12-08-boundary-glow-as-motion-cue', // "narrative opportunities" is a pillar note, no plot
]);

// ------------------------------------------------------------------ helpers
const slug = (s) => s.normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
const stripMd = (s) => s.replace(/\*\*/g, '').replace(/`/g, '').replace(/\s+/g, ' ').trim();
// keeps list structure: one line per paragraph or list item
const stripMdLines = (s) => s.replace(/\*\*/g, '').replace(/`/g, '').replace(/\[([^\]]+)\]\([^)]*\)/g, '$1')
  .replace(/\n(?!\s*(?:-|\d+\.|>)\s)\s*/g, ' ').replace(/[ \t]+/g, ' ').replace(/\n /g, '\n').trim();

function prRefs(text) {
  // #NN in the game repo; "stapledons-design PR #N" / "design-repo PR #N" point at the design repo
  const out = [];
  const seen = new Set();
  for (const m of text.matchAll(/(stapledons-design|design-repo)?\s*(?:PRs?\s*)?#(\d{1,4})\b/gi)) {
    const n = Number(m[2]);
    const repo = m[1] ? 'design' : 'game';
    const key = `${repo}${n}`;
    if (seen.has(key)) continue;
    seen.add(key);
    const kind = repo === 'game' && (n === 1 || n === 4 || n === 93) ? 'issue' : 'pr';
    out.push({repo, n, url: `${repo === 'design' ? DESIGN : GAME}/issues/${n}`, kind});
  }
  return out;
}

function quotes(text) {
  // Mark's words: quoted spans after "Mark ... :" or the verbatim blocks
  const q = [];
  for (const m of text.matchAll(/(?:(?:^|[\s(:])'([^'\n]{8,400}?)'(?=[\s),.;]|$)|"([^"\n]{8,400})"|“([^”]{8,600})”)/g)) {
    q.push((m[1] || m[2] || m[3]).trim());
  }
  return q;
}

function classify(id, text) {
  if (GROUPS_BY_ID[id]) return GROUPS_BY_ID[id];
  const g = KEYWORDS.filter(([, re]) => re.test(text)).map(([k]) => k);
  return g.length ? g.slice(0, 2) : ['gameplay'];
}

// ------------------------------------------------------------------ sources
function parseLedger() {
  const lines = fs.readFileSync(path.join(REPO, LEDGER), 'utf8').split('\n');
  const out = [];
  lines.forEach((line, i) => {
    if (!/^\| D-\d+ \|/.test(line)) return;
    const cells = line.split('|');
    const id = cells[1].trim();
    const status = cells[2].trim();
    const body = cells[3];
    const evidence = cells.slice(4, -1).join('|');
    const ans = body.match(/\*\*ANSWERED\s*—\s*(?:ANSWERED\s*—\s*)?([\s\S]*?)\*\*/);
    let question = (ans ? body.slice(0, ans.index) : body);
    question = stripMd(question.split(/\s+Recommendation:/)[0].split(/\s+Default if unanswered:/)[0]);
    const ruling = ans ? stripMd(ans[1]) : '';
    const date = (body.match(/attended (\d{4}-\d{2}-\d{2})/) || evidence.match(/(\d{4}-\d{2}-\d{2})/) || [])[1] || '';
    const ev = stripMd(evidence.split('**Attended ruling')[0]);
    // Mark's words: only quotes inside the "(Mark, attended DATE: '...')" attribution
    const attrib = (ruling.match(/\(Mark[^()]*?attended \d{4}-\d{2}-\d{2}[^()]*\)/) || [''])[0];
    const words = quotes(attrib).slice(0, 3);
    out.push({
      id, source: 'ledger', status: status.toLowerCase(), date, title: TITLES[id] || question.slice(0, 80),
      question, ruling, words, provenance: ev,
      link: `${GAME}/blob/main/${LEDGER}#L${i + 1}`, sourceLabel: `stapledon-mission.md, line ${i + 1}`,
      refs: prRefs(body + ' ' + evidence), text: body + ' ' + evidence,
    });
  });
  return out;
}

function parseDesign() {
  if (!fs.existsSync(VENDOR)) throw new Error(`missing ${VENDOR}: run node scripts/decisions.mjs --sync`);
  const sha = fs.readFileSync(PIN, 'utf8').trim();
  const lines = fs.readFileSync(VENDOR, 'utf8').split('\n');
  const heads = [];
  lines.forEach((l, i) => {
    const m = l.match(/^## \[(\d{4}-\d{2}-\d{2})\] (.+)$/);
    if (m) heads.push({i, date: m[1], title: m[2].trim()});
  });
  return heads.map((h, k) => {
    const end = k + 1 < heads.length ? heads[k + 1].i : lines.length;
    const body = lines.slice(h.i + 1, end).join('\n').replace(/<!--[\s\S]*?-->/g, '').trim();
    const field = (re, lines = false) => {
      const m = body.match(re);
      return m ? (lines ? stripMdLines(m[1]) : stripMd(m[1])) : '';
    };
    const ledgerRef = (h.title.match(/\(ledger (D-\d+)\)/) || [])[1];
    const titleClean = h.title.replace(/\s*\(ledger D-\d+\)/, '');
    const id = `DD-${h.date}-${slug(titleClean)}`.slice(0, 80).replace(/-$/, '');
    const verbatim = field(/\*\*(?:Mark(?:'s ruling)? \(verbatim\)|Mark's feedback):\*\*\s*([\s\S]*?)(?=\n\*\*|\n## |$)/);
    const decision = field(/\*\*(?:Decision|Accepted direction)[^*]*:\*\*\s*([\s\S]*?)(?=\n\*\*[A-Z][^*]*:\*\*|$)/, true);
    const context = field(/\*\*Context:\*\*\s*([\s\S]*?)(?=\n\n|\n\*\*)/);
    const rationale = field(/\*\*Rationale:\*\*\s*([\s\S]*?)(?=\n\n|\n\*\*)/);
    const firstPara = stripMd(body.split(/\n\n/)[0] || '');
    return {
      id, source: 'design', status: 'decided', date: h.date, title: titleClean,
      question: context || '', ruling: decision || firstPara, words: verbatim ? [verbatim.replace(/^>\s*/, '')] : [],
      provenance: rationale, ledgerRef,
      link: `${DESIGN}/blob/${sha}/vision/design-decisions.md#L${h.i + 1}`, sourceLabel: `design-decisions.md, line ${h.i + 1} (pinned ${sha.slice(0, 7)})`,
      // in the design repo, #1 and #93 are the game repo's issues; other numbers are design-repo PRs
      refs: prRefs(body).map((r) => (r.n === 1 || r.n === 93 ? {...r, repo: 'game', kind: 'issue', url: `${GAME}/issues/${r.n}`} : {...r, repo: 'design', kind: 'pr', url: `${DESIGN}/pull/${r.n}`})),
      text: h.title + '\n' + body,
    };
  });
}

function parseSupplementary() {
  return SUPPLEMENTARY.map((s) => {
    const lines = fs.readFileSync(path.join(REPO, s.file), 'utf8').split('\n');
    const i = lines.findIndex((l) => l.includes(s.needle));
    if (i < 0) throw new Error(`decisions: needle not found in ${s.file}: ${s.needle}`);
    // the ruling: the needle's paragraph (up to a blank line or the next list item / table row)
    let j = i;
    const para = [lines[i]];
    while (++j < lines.length && lines[j].trim() && !/^\s*(- |\| )/.test(lines[j])) para.push(lines[j]);
    let joined = para.join(' ');
    if (s.prefix) joined = s.prefix + joined.slice(joined.indexOf(s.needle));
    let ruling = stripMd(joined.replace(/^\s*-\s*/, ''));
    if (lines[i].trim().startsWith('|')) {
      // table rows: "| 9 Voice | Aoede after an audition | AI.10b |" -> "Voice: Aoede after an audition (lands in AI.10b)"
      ruling = lines.slice(i, i + (s.rows || 1)).map((row) => {
        const c = row.split('|').map((x) => stripMd(x)).filter(Boolean);
        return `${c[0].replace(/^\d+\s*/, '')}: ${c[1]} (lands in ${c[2]})`;
      }).join('. ') + '.';
    }
    if (s.until) ruling = ruling.split(s.until)[0].replace(/[;,\s]+$/, '') + '.';
    return {
      id: s.id, source: 'supplementary', status: 'decided', date: s.date, title: s.title,
      question: s.question, ruling, words: [], provenance: s.provenance || `Recorded in ${s.file}.`,
      link: `${GAME}/blob/main/${s.file}#L${i + 1}`, sourceLabel: `${path.basename(s.file)}, line ${i + 1}`,
      refs: s.prs.map((n) => ({repo: 'game', n, url: `${GAME}/issues/${n}`, kind: 'pr'})), groups: s.groups,
      subtopic: s.subtopic, text: ruling,
    };
  });
}

// ---------------------------------------------------------------- sync mode
async function sync() {
  const res = await fetch('https://api.github.com/repos/sunholo-data/stapledons-design/commits/main', {headers: {Accept: 'application/vnd.github+json'}});
  if (!res.ok) throw new Error(`GitHub API ${res.status}`);
  const sha = (await res.json()).sha;
  const raw = await fetch(`https://raw.githubusercontent.com/sunholo-data/stapledons-design/${sha}/vision/design-decisions.md`);
  if (!raw.ok) throw new Error(`raw fetch ${raw.status}`);
  fs.mkdirSync(path.dirname(VENDOR), {recursive: true});
  fs.writeFileSync(VENDOR, await raw.text());
  fs.writeFileSync(PIN, sha + '\n');
  console.log(`decisions: vendored design-decisions.md at ${sha}`);
}

// --------------------------------------------------------------------- main
function build() {
  const design = parseDesign();
  // override keys for design entries may be slug prefixes: adopt the key as the entry's id
  const keys = new Set([...Object.keys(GROUPS_BY_ID), ...Object.keys(REVISIT), ...Object.keys(ASSETS), ...DENY, ...ALLOW,
    ...RELATIONS.flatMap(([a, , b]) => [a, typeof b === 'string' ? b : ''])].filter((k) => k.startsWith('DD-')));
  for (const k of keys) {
    const d = design.find((x) => x.id === k || x.id.startsWith(k));
    if (!d) throw new Error(`decisions: override key ${k} matches no design-decisions.md entry`);
    d.id = k;
  }
  const all = [...parseLedger(), ...design, ...parseSupplementary()];
  const byId = new Map(all.map((d) => [d.id, d]));
  const excluded = [];
  const kept = [];
  for (const d of all) {
    const hit = d.text.match(SPOILER);
    const deny = DENY.has(d.id) || (hit && !ALLOW.has(d.id));
    if (deny) {
      excluded.push(`${d.id}\t${d.date}\t${d.title}\t${DENY.has(d.id) ? 'deny map' : `keyword "${hit[0]}"`}`);
      continue;
    }
    kept.push(d);
  }
  const keptIds = new Set(kept.map((d) => d.id));

  // relations: explicit map plus parsed ones
  const rel = [...RELATIONS];
  for (const d of kept) {
    if (d.ledgerRef) rel.push([d.id, 'records', d.ledgerRef]);
    if (d.source === 'design') {
      // "supersedes ... 'Title' (YYYY-MM-DD)" style references to other design entries
      for (const o of all) {
        if (o.source !== 'design' || o.id === d.id) continue;
        const t = o.title.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
        if (new RegExp(`[Ss]upersed\\w*[^.]{0,200}${t}|${t}[^.]{0,80}supersed`).test(d.text)) rel.push([d.id, 'supersedes', o.id]);
      }
    }
  }
  const relations = {};
  const add = (id, k, v) => ((relations[id] ||= {})[k] ||= []).push(v);
  for (const [from, kind, to] of rel) {
    if (!keptIds.has(from)) continue;
    if (typeof to === 'object') {
      add(from, kind, to);
      continue;
    }
    if (!byId.has(to)) throw new Error(`decisions: relation target ${to} not found`);
    const target = keptIds.has(to) ? {id: to, title: byId.get(to).title} : {note: `${to} (not shown here)`};
    add(from, kind, target);
    if (keptIds.has(to)) {
      const back = kind === 'supersedes' ? 'supersededBy' : kind === 'refines' ? 'refinedBy' : 'recordedAs';
      add(to, back, {id: from, title: byId.get(from).title});
    }
  }
  // dedupe relations
  for (const r of Object.values(relations)) for (const k of Object.keys(r)) r[k] = [...new Map(r[k].map((x) => [x.id || x.note, x])).values()];

  const decisions = kept.map((d) => {
    const groups = d.groups || classify(d.id, d.text);
    const {text, ...rest} = d;
    return {
      ...rest, groups, subtopic: d.subtopic || SUBTOPIC[d.id] || '',
      revisit: REVISIT[d.id] || '', assets: ASSETS[d.id] || [], relations: relations[d.id] || {},
      superseded: Boolean(relations[d.id]?.supersededBy?.length),
    };
  }).sort((a, b) => (b.date + b.id).localeCompare(a.date + a.id));

  const pin = fs.readFileSync(PIN, 'utf8').trim();
  fs.writeFileSync(OUT, JSON.stringify({generated: new Date().toISOString().slice(0, 10), designPin: pin, decisions}, null, 1) + '\n');
  const audit = `# Decisions excluded from the public site as possible spoilers (generated by scripts/decisions.mjs)\n# id\tdate\ttitle\treason\n${excluded.join('\n')}\n`;
  fs.writeFileSync(AUDIT, audit);
  const count = (s) => decisions.filter((d) => d.source === s).length;
  const groupCount = {};
  for (const d of decisions) for (const g of d.groups) groupCount[g] = (groupCount[g] || 0) + 1;
  console.log(`decisions: ${decisions.length} shown (ledger ${count('ledger')}, design ${count('design')}, supplementary ${count('supplementary')}); ${excluded.length} excluded as possible spoilers (scripts/decisions-excluded.txt)`);
  console.log(`decisions: groups ${JSON.stringify(groupCount)}`);
  for (const e of excluded) console.log(`  excluded  ${e}`);
}

if (process.argv.includes('--sync')) await sync();
build();
