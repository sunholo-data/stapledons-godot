import React from 'react';
import clsx from 'clsx';
import Link from '@docusaurus/Link';
import useBaseUrl from '@docusaurus/useBaseUrl';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import Layout from '@theme/Layout';
import {
  ArrowRight,
  Atom,
  BookOpen,
  Clock,
  Cpu,
  Download,
  Lock,
  Orbit,
  Play,
  Repeat,
  Sparkles,
  Telescope,
} from 'lucide-react';
import Clip from '@site/src/components/Clip';
import GALLERY from '@site/src/data/gallery';
import styles from './index.module.css';

const GITHUB_URL = 'https://github.com/sunholo-data/stapledons-godot';
const DESIGN_URL = 'https://github.com/sunholo-data/stapledons-design';
const AILANG_URL = 'https://ailang.sunholo.com';

function GitHubMark({size = 18}) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" aria-hidden="true" fill="currentColor">
      <path d="M12 .5C5.65.5.5 5.65.5 12a11.5 11.5 0 0 0 7.86 10.92c.58.1.79-.25.79-.56v-2c-3.2.7-3.87-1.37-3.87-1.37-.53-1.33-1.28-1.69-1.28-1.69-1.05-.72.08-.7.08-.7 1.16.08 1.77 1.19 1.77 1.19 1.03 1.77 2.71 1.26 3.37.96.1-.75.4-1.26.73-1.55-2.56-.29-5.25-1.28-5.25-5.7 0-1.26.45-2.29 1.19-3.1-.12-.29-.52-1.47.11-3.06 0 0 .97-.31 3.17 1.18a11 11 0 0 1 5.77 0c2.2-1.49 3.17-1.18 3.17-1.18.63 1.59.23 2.77.11 3.06.74.81 1.19 1.84 1.19 3.1 0 4.43-2.7 5.4-5.26 5.69.41.36.78 1.06.78 2.14v3.17c0 .31.21.67.8.56A11.5 11.5 0 0 0 23.5 12C23.5 5.65 18.35.5 12 .5Z" />
    </svg>
  );
}

function Hero() {
  const logo = useBaseUrl('/img/ailang-logo.svg');
  return (
    <header className={styles.hero}>
      <Clip name="hero" className={styles.heroVideo} label="The sky ahead while the ship accelerates from rest to 0.99c" eager />
      <div className={styles.heroShade} aria-hidden="true" />
      <div className={styles.heroContent}>
        <p className={styles.kicker}>A hard-SF game in Godot 4 and AILANG</p>
        <h1 className={styles.wordmark}>
          <span className={styles.wordmarkSmall}>Stapledon's</span>
          <span className={styles.wordmarkBig}>Voyage</span>
        </h1>
        <p className={styles.tagline}>Travel as fast as you like. Live with the consequences.</p>
        <p className={styles.heroLead}>
          One hand-wave, the <strong>Higgs bubble</strong>. Everything else is real special and
          general relativity, rendered from the real nearby stars: aberration, Doppler colour and
          beaming, time dilation, and the cosmic background turned to fire ahead of you.
        </p>
        <div className={styles.heroActions}>
          <a href="#flight" className={clsx(styles.btn, styles.btnPrimary)}>
            <Play size={18} /> Watch the flight
          </a>
          <Link to="/docs/physics" className={clsx(styles.btn, styles.btnSecondary)}>
            <Atom size={18} /> The physics
          </Link>
          <a href={GITHUB_URL} className={clsx(styles.btn, styles.btnGhost)}>
            <GitHubMark /> GitHub
          </a>
        </div>
        <a href={AILANG_URL} className={styles.builtWith}>
          <img src={logo} alt="" width="22" height="22" /> Simulation built in <strong>AILANG</strong>
        </a>
      </div>
      <p className={styles.heroCaption}>
        Real capture: the forward view while the AILANG simulation accelerates the ship at 1 g, from
        rest to 0.99c (HUD hidden here; the clips below show it).
      </p>
    </header>
  );
}

function StatusBanner() {
  return (
    <section className={styles.statusWrap} aria-label="Project status">
      <Link to="/docs/roadmap" className={styles.status}>
        <span className={styles.statusPill}>Pre-alpha</span>
        <span className={styles.statusText}>
          <strong>Release 1 is under way.</strong> The relativistic sky and the journey core run
          today; black holes and the first playable journey come next.
        </span>
        <span className={styles.statusLink}>
          Roadmap <ArrowRight size={16} />
        </span>
      </Link>
    </section>
  );
}

const BUBBLE = [
  ['A wall', 'that stops every massive particle and lets light and neutrinos through.'],
  ['Tunable inertia', 'for the whole pocket, never quite zero, so the ship can cruise at 0.9c to 0.999999c.'],
  ['Its own frame', 'inside: the crew never feel the boost; a generator holds a steady 1 g.'],
];

const REAL = [
  'Aberration: the sky crowds toward the bow',
  'Relativistic Doppler colour and beaming',
  'Time dilation on two clocks, ship and Earth',
  'The forward CMB, a blackbody at T·γ(1+β)',
  'A photometric, naked-eye sky',
  '335,157 real stars: CNS5, Gaia GCNS, Hipparcos',
  'Black-hole shadows and lensing (next, M3)',
];

function OneHandWave() {
  return (
    <section className={styles.section}>
      <div className={styles.container}>
        <div className={styles.sectionHeader}>
          <h2 className={styles.sectionTitle}>
            One admitted hand-wave. <span className={styles.gradient}>Everything else is physics.</span>
          </h2>
          <p className={styles.sectionSubtitle}>
            “The Higgs bubble is the one hand-wavy non-physics bit which we admit, but then be as
            hard-core physics for the rest as possible.” The bubble is defined by three properties.
            Every consequence, from the drag of interstellar gas to the glow ahead, is derived
            from them with ordinary physics and given a check value.
          </p>
        </div>
        <div className={styles.split}>
          <div className={clsx(styles.card, styles.cardBubble)}>
            <h3 className={styles.cardTitle}>
              <Sparkles size={20} aria-hidden="true" /> The Higgs bubble
            </h3>
            <p className={styles.cardLead}>A 100 m pocket made by the ship's generator. It has:</p>
            <ul className={styles.plainList}>
              {BUBBLE.map(([t, d]) => (
                <li key={t}>
                  <strong>{t}</strong> {d}
                </li>
              ))}
            </ul>
            <Link to="/docs/higgs-bubble" className={styles.textLink}>
              The bubble canon <ArrowRight size={16} />
            </Link>
          </div>
          <div className={clsx(styles.card, styles.cardReal)}>
            <h3 className={styles.cardTitle}>
              <Telescope size={20} aria-hidden="true" /> Real, and tested
            </h3>
            <ul className={styles.checkList}>
              {REAL.map((t) => (
                <li key={t}>{t}</li>
              ))}
            </ul>
            <Link to="/docs/physics" className={styles.textLink}>
              How each effect is checked <ArrowRight size={16} />
            </Link>
          </div>
        </div>
      </div>
    </section>
  );
}

function Pill({kind, children}) {
  return <span className={clsx('sv-status', `sv-status--${kind}`)}>{children}</span>;
}

const SHOWCASE = [
  {
    id: 'flight',
    clip: 'voyage',
    icon: Orbit,
    title: 'Accelerate, and the sky folds forward',
    status: <Pill kind="done">Runs today</Pill>,
    body: (
      <>
        <p>
          At rest you see the Milky Way across the sky. Burn at 1 g and aberration drags every star
          toward the bow: at 0.9c a star that sits 90° to the side at rest appears just 25.84° off the nose. Ahead,
          light is Doppler shifted blue and beamed brighter; behind, it reddens past the visible
          band and goes out.
        </p>
        <p className={styles.small}>
          Each star is a blackbody at its own Gaia colour temperature, shifted to D·T and scaled by
          its point-source flux ratio. The GPU shader is checked against a float64 CPU reference to
          under 0.1 px.
        </p>
      </>
    ),
  },
  {
    id: 'lookaround',
    clip: 'lookaround',
    icon: Telescope,
    title: 'Look around at 0.99c',
    status: <Pill kind="done">Runs today</Pill>,
    body: (
      <>
        <p>
          A full turn of the camera while cruising at γ 7.09. The whole visible universe sits in a
          bright window ahead. Turn to the beam and the sky is nearly empty; astern it is black.
          Nothing is faked to keep it pretty.
        </p>
        <p className={styles.small}>
          The exposure is honest too: by default it is a dark-adapted eye, calibrated so the
          naked-eye limit lands at V 6.9 (Crumey's model gives 6.897). Camera metering and
          readability aids exist, and the HUD says when they are on.
        </p>
      </>
    ),
  },
  {
    id: 'cmb',
    clip: 'cmb',
    icon: Sparkles,
    title: 'The cosmic background, set on fire',
    status: <Pill kind="done">Runs today</Pill>,
    body: (
      <>
        <p>
          Push past γ 100 and something appears dead ahead that no star can explain: the 2.7 K
          microwave background, Doppler shifted into the visible. It shows faintly from γ ≈ 146,
          glows orange at γ ≈ 275 (1,500 K) and burns at 3,853.7 K at γ 707, the cruise cap.
        </p>
        <p className={styles.small}>
          Forward view through a 20° lens, γ 20 to 707 on a committed journey near Sol: first the
          stars crowd into a shrinking blue ball, then the CMB takes over the bow.
        </p>
      </>
    ),
  },
  {
    id: 'map',
    clip: 'map',
    icon: Clock,
    title: 'Plan a journey. Then you cannot take it back',
    status: <Pill kind="done">Runs today</Pill>,
    body: (
      <>
        <p>
          Pick a star, slide the cruise speed, and watch the two clocks part. α Centauri at 0.99c
          costs you 0.62 years and everyone at home 4.4. Faster costs you less and the galaxy
          more. Commit with a 1.5-second hold and the simulation refuses every attempt to cancel.
        </p>
        <p className={styles.small}>
          Every number on the panel comes from the AILANG simulation: the planner matches the closed
          form to 1e-9, with the boost, brake and interstellar-drag energy ledger beside it.
        </p>
      </>
    ),
  },
];

function Showcase() {
  return (
    <section className={clsx(styles.section, styles.sectionDark)}>
      <div className={styles.container}>
        <div className={styles.sectionHeader}>
          <h2 className={clsx(styles.sectionTitle, styles.onDark)}>Captured from the game</h2>
          <p className={clsx(styles.sectionSubtitle, styles.onDarkMuted)}>
            These clips are frame-exact captures of the Godot renderer driven by the AILANG
            simulation. No compositing, no grading: the HUD shows the simulation's own β, γ and
            clocks.
          </p>
        </div>
        <div className={styles.showcase}>
          {SHOWCASE.map(({id, clip, icon: Icon, title, status, body}, i) => (
            <article key={id} id={id} className={clsx(styles.show, i % 2 === 1 && styles.showFlip)}>
              <div className={styles.showMedia}>
                <Clip name={clip} className={styles.showVideo} label={title} />
              </div>
              <div className={styles.showCopy}>
                <div className={styles.showHead}>
                  <Icon size={22} className={styles.showIcon} aria-hidden="true" />
                  {status}
                </div>
                <h3 className={styles.showTitle}>{title}</h3>
                {body}
              </div>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}

const STATS = [
  ['335,157', 'stars drawn, from CNS5, Gaia GCNS and Hipparcos'],
  ['< 0.1 px', 'GPU shader against the float64 CPU reference'],
  ['10,000', 'ticks replayed byte-identical on the VM and the interpreter'],
  ['1e-9', 'journey planner against the closed-form equations'],
];

function Stats() {
  return (
    <section className={styles.statsWrap} aria-label="By the numbers">
      <div className={clsx(styles.container, styles.stats)}>
        {STATS.map(([n, t]) => (
          <div key={n} className={styles.stat}>
            <div className={styles.statNum}>{n}</div>
            <div className={styles.statText}>{t}</div>
          </div>
        ))}
      </div>
    </section>
  );
}

// Trimmed from tests/replays/alpha_cen.ndjson and its recorded state log
// (fields elided with …). Real protocol v2 lines, real numbers.
const SAMPLE = `→ {"v":2,"type":"input","tick":1,"dtau":0,"intents":[{"k":"plan",
    "target":{"id":"alpha Cen","pos":{"x":0,"y":0,"z":-4.37}},
    "cruise_phi":2.6466524123622457}]}
← {"v":2,"type":"state","tick":1,"status":"ok","changes":{"journey":{
    "state":"planned","plan":{"cruise_beta":0.99,
    "cruise_one_minus_beta":0.01000000000000001,
    "cruise_gamma":7.088812050083356,
    "ship_years":0.6226958707592057,
    "earth_years":4.414143655383168, …}}}}
→ {"v":2,"type":"input","tick":2,"dtau":0.01,
    "intents":[{"k":"commit","plan_id":1}]}`;

const AILANG_POINTS = [
  {
    icon: Cpu,
    title: 'The simulation is AILANG',
    text: 'Ship, clocks, journeys and the energy ledger run on the AILANG bytecode VM as a child process. Godot only draws what the simulation says.',
  },
  {
    icon: Repeat,
    title: 'Deterministic, byte for byte',
    text: 'No hidden state: seed plus input log gives the same output. A 10,000-tick session replays identically on the VM and the interpreter.',
  },
  {
    icon: Lock,
    title: 'Physics in one place',
    text: 'Every formula lives first in the sunholo/relativity package, with tests and check values. GDScript and the shaders mirror it.',
  },
];

function BuiltWithAilang() {
  return (
    <section className={styles.section}>
      <div className={clsx(styles.container, styles.sampleGrid)}>
        <div>
          <h2 className={styles.sectionTitle}>
            Built with <span className={styles.gradient}>AILANG</span>
          </h2>
          <p className={styles.sampleLead}>
            Godot 4 renders the game. The simulation is an AILANG program talking newline-delimited
            JSON over stdin and stdout, one request and one reply per tick. The game doubles as a
            stress test for the AILANG VM: whenever the VM and the interpreter disagree, it is an
            upstream bug, shrunk and reported.
          </p>
          <ul className={styles.points}>
            {AILANG_POINTS.map(({icon: Icon, title, text}) => (
              <li key={title}>
                <Icon size={20} className={styles.pointIcon} aria-hidden="true" />
                <div>
                  <strong>{title}.</strong> {text}
                </div>
              </li>
            ))}
          </ul>
          <Link to="/docs/built-with-ailang" className={styles.textLink}>
            The architecture <ArrowRight size={16} />
          </Link>
        </div>
        <div className={styles.terminal}>
          <div className={styles.terminalHeader}>
            <span className={clsx(styles.dot, styles.dotRed)} />
            <span className={clsx(styles.dot, styles.dotYellow)} />
            <span className={clsx(styles.dot, styles.dotGreen)} />
            <span className={styles.terminalName}>Godot ⇄ sim/ship.ail · protocol v2</span>
          </div>
          <pre className={styles.terminalBody}>
            <code>{SAMPLE}</code>
          </pre>
        </div>
      </div>
    </section>
  );
}

function GalleryTeaser() {
  const picks = ['sky-099c.jpg', 'cmb-gamma-275.jpg', 'map-commit.jpg', 'milky-way-destarred.jpg', 'sky-091c.jpg', 'map-transit.jpg'];
  const items = picks.map((f) => GALLERY.find((g) => g.file === f)).filter(Boolean);
  const base = useBaseUrl('/img/gallery/');
  return (
    <section className={clsx(styles.section, styles.sectionAlt)}>
      <div className={styles.container}>
        <div className={styles.sectionHeader}>
          <h2 className={styles.sectionTitle}>Gallery</h2>
          <p className={styles.sectionSubtitle}>Stills from the renderer and the galaxy map, each with what produced it.</p>
        </div>
        <div className={styles.thumbs}>
          {items.map((g) => (
            <Link key={g.file} to="/gallery" className={styles.thumb}>
              <img src={base + g.file} alt={g.title} loading="lazy" width="800" height="450" />
              <span className={styles.thumbTitle}>{g.title}</span>
            </Link>
          ))}
        </div>
        <div className={styles.center}>
          <Link to="/gallery" className={clsx(styles.btn, styles.btnPrimary)}>
            Open the gallery <ArrowRight size={18} />
          </Link>
        </div>
      </div>
    </section>
  );
}

const MILESTONES = [
  ['M0', 'Spike', 'done', 'AILANG sim + Godot starfield, tested relativity'],
  ['M1', 'The relativistic sky', 'progress', '335k stars, Milky Way, exposure, forward CMB; performance bar left'],
  ['M2', 'The journey core', 'done', 'Planner, commit, two clocks, deterministic replay'],
  ['M3', 'Black holes', 'planned', 'Shadow, lensing, Einstein rings, checked against GR'],
  ['M4', 'First playable journey', 'planned', 'Plan, commit, live through it, arrive changed'],
];
const LABEL = {done: 'Done', progress: 'In progress', planned: 'Planned'};

function Roadmap() {
  return (
    <section className={styles.section}>
      <div className={styles.container}>
        <div className={styles.sectionHeader}>
          <h2 className={styles.sectionTitle}>Release 1: foundations</h2>
          <p className={styles.sectionSubtitle}>
            What exists today, and what is still a plan. The full vision (civilisations rising and
            dying while you travel, a crew that ages, a legacy report at Year 1,000,000) comes after
            these foundations.
          </p>
        </div>
        <ol className={styles.milestones}>
          {MILESTONES.map(([id, title, state, text]) => (
            <li key={id} className={clsx(styles.milestone, styles[`ms_${state}`])}>
              <div className={styles.msHead}>
                <span className={styles.msId}>{id}</span>
                <Pill kind={state}>{LABEL[state]}</Pill>
              </div>
              <h3 className={styles.msTitle}>{title}</h3>
              <p className={styles.msText}>{text}</p>
            </li>
          ))}
        </ol>
        <div className={styles.center}>
          <Link to="/docs/roadmap" className={styles.textLink}>
            Detailed roadmap <ArrowRight size={16} />
          </Link>
        </div>
      </div>
    </section>
  );
}

function Closing() {
  return (
    <section className={clsx(styles.section, styles.closing)}>
      <div className={styles.container}>
        <h2 className={styles.closingTitle}>
          A game you can learn relativity from, <span className={styles.gradient}>because it never cheats.</span>
        </h2>
        <p className={styles.closingText}>
          Every visual effect is held to a normative physics spec with numbered check values,
          asserted in tests before it merges. Named after Olaf Stapledon, author of <em>Star Maker</em>.
        </p>
        <div className={styles.heroActions}>
          <Link to="/docs/intro" className={clsx(styles.btn, styles.btnPrimary)}>
            <BookOpen size={18} /> About the game
          </Link>
          <Link to="/docs/try-it" className={clsx(styles.btn, styles.btnSecondary)}>
            <Download size={18} /> Try the review build
          </Link>
          <a href={DESIGN_URL} className={clsx(styles.btn, styles.btnGhost)}>
            <GitHubMark /> Design docs
          </a>
        </div>
      </div>
    </section>
  );
}

export default function Home() {
  const {siteConfig} = useDocusaurusContext();
  return (
    <Layout title="Hard-SF at near light speed" description={siteConfig.tagline}>
      <Hero />
      <main>
        <StatusBanner />
        <OneHandWave />
        <Showcase />
        <Stats />
        <BuiltWithAilang />
        <GalleryTeaser />
        <Roadmap />
        <Closing />
      </main>
    </Layout>
  );
}
