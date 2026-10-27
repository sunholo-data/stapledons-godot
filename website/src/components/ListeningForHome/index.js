import React, {useEffect, useRef, useState} from 'react';
import styles from './styles.module.css';

// Figures for the "Listening for home" news post (R3 Signals and Contact, design stage).
// The Doppler factor mirrors sunholo/relativity: for a ship receding from Earth at rapidity phi
// (beta = tanh phi), the factor is D = e^-phi; approaching, D = e^phi. Nothing here feeds the game.

const PHI_MAX = Math.atanh(0.999999); // gamma 707, the cruise cap (D-15)

function duration(days) {
  if (days < 1 / 24) return `${(days * 1440).toPrecision(2)} minutes`;
  if (days < 1) return `${(days * 24).toPrecision(2)} hours`;
  if (days < 365.25) return `${days.toPrecision(3)} days`;
  return `${(days / 365.25).toPrecision(3)} years`;
}

function frequency(hz) {
  if (hz >= 1e12) return `${(hz / 1e12).toPrecision(3)} THz`;
  if (hz >= 1e9) return `${(hz / 1e9).toPrecision(3)} GHz`;
  if (hz >= 1e6) return `${(hz / 1e6).toPrecision(3)} MHz`;
  return `${(hz / 1e3).toPrecision(3)} kHz`;
}

function wavelength(m) {
  if (m >= 1e-3) return `${(m * 1e3).toPrecision(3)} mm`;
  if (m >= 1e-6) return `${(m * 1e6).toPrecision(3)} µm`;
  return `${(m * 1e9).toPrecision(3)} nm`;
}

function betaText(beta) {
  if (beta < 0.99) return `${beta.toFixed(3)}c`;
  const nines = Math.min(7, Math.floor(-Math.log10(1 - beta)));
  return `${beta.toFixed(nines + 1)}c`;
}

const PRESETS = [
  ['At rest', 0],
  ['0.5c', Math.atanh(0.5)],
  ['0.99c', Math.atanh(0.99)],
  ['0.999c', Math.atanh(0.999)],
  ['γ 707', PHI_MAX],
];

// The live Earth rate: how fast Earth's news plays aboard, by speed and direction.
export function EarthRate() {
  const [phi, setPhi] = useState(Math.atanh(0.99));
  const [home, setHome] = useState(false);
  const beta = Math.tanh(phi);
  const gamma = Math.cosh(phi);
  const D = home ? Math.exp(phi) : Math.exp(-phi);
  return (
    <figure className={styles.panel}>
      <div className={styles.controls}>
        <div className={styles.toggle} role="group" aria-label="Direction">
          <button type="button" aria-pressed={!home} onClick={() => setHome(false)}>Flying away from Earth</button>
          <button type="button" aria-pressed={home} onClick={() => setHome(true)}>Flying home</button>
        </div>
        <label className={styles.slider} htmlFor="earth-rate-speed">
          <span>Speed <b>{betaText(beta)}</b> · γ {gamma < 10 ? gamma.toFixed(2) : gamma.toFixed(0)}</span>
          <input id="earth-rate-speed" type="range" min="0" max="1000" value={Math.round((phi / PHI_MAX) * 1000)}
            onChange={(e) => setPhi((Number(e.target.value) / 1000) * PHI_MAX)} />
        </label>
        <div className={styles.presets}>
          {PRESETS.map(([label, p]) => (
            <button type="button" key={label} onClick={() => setPhi(p)} aria-pressed={Math.abs(p - phi) < 1e-9}>{label}</button>
          ))}
        </div>
      </div>
      <dl className={styles.readout}>
        <div><dt>Earth rate</dt><dd>{D >= 10 ? D.toFixed(0) : D.toPrecision(3)} Earth seconds per ship second</dd></div>
        <div>
          <dt>{D < 1 ? 'One day of Earth news takes' : 'One ship day brings'}</dt>
          <dd>{D < 1 ? duration(1 / D) : `${duration(D)} of Earth news`}</dd>
        </div>
        <div><dt>A 10 GHz radio carrier arrives at</dt><dd>{frequency(10e9 * D)}</dd></div>
        <div><dt>A 1 µm laser arrives at</dt><dd>{wavelength(1e-6 / D)}</dd></div>
      </dl>
      <figcaption>
        The slider runs from rest to the ship's cruise cap of 0.999999c. The Earth rate is the same Doppler factor
        that colours the sky: D = √((1 − β)/(1 + β)) flying away, and its inverse flying home.
      </figcaption>
    </figure>
  );
}

const W = 640, H = 132, EARTH_X = 34, SHIP_FAR = 606, C = 150, EVERY = 0.2;

function chaseState(t, beta, home) {
  // Earth emits a pulse every EVERY seconds. Light moves at C px/s; the ship at beta * C.
  const ship = home ? SHIP_FAR - beta * C * t : 64 + beta * C * t;
  const pulses = [];
  let received = 0;
  let sent = 0;
  const first = home ? -Math.ceil((SHIP_FAR - EARTH_X) / (C * EVERY)) : 0; // flying home, the backlog fills space
  const last = Math.floor(t / EVERY);
  for (let k = first; k <= last; k++) {
    const x = EARTH_X + C * (t - k * EVERY);
    if (k >= 0) sent++;
    if (x >= ship) { received++; continue; }
    pulses.push(x);
  }
  return {ship, pulses, received, sent};
}

// Earth's broadcasts chasing the ship: space holds what has not arrived yet.
export function Chase() {
  const [beta, setBeta] = useState(0.8);
  const [home, setHome] = useState(false);
  const [t, setT] = useState(1.6);
  const [running, setRunning] = useState(false);
  const raf = useRef(0);
  const end = home ? (SHIP_FAR - 70) / (beta * C) : (SHIP_FAR - 64) / (beta * C);

  useEffect(() => {
    const reduce = typeof window !== 'undefined' && window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    setRunning(!reduce);
  }, []);

  useEffect(() => {
    if (!running) return undefined;
    let start = performance.now() - t * 1000;
    const step = (now) => {
      let s = (now - start) / 1000;
      if (s > end + 0.8) { start = now; s = 0; }
      setT(Math.min(s, end));
      raf.current = requestAnimationFrame(step);
    };
    raf.current = requestAnimationFrame(step);
    return () => cancelAnimationFrame(raf.current);
  }, [running, beta, home]); // eslint-disable-line react-hooks/exhaustive-deps

  const {ship, pulses, received, sent} = chaseState(Math.min(t, end), beta, home);
  return (
    <figure className={styles.panel}>
      <div className={styles.controls}>
        <div className={styles.toggle} role="group" aria-label="Direction">
          <button type="button" aria-pressed={!home} onClick={() => { setHome(false); setT(0); }}>Leaving Earth</button>
          <button type="button" aria-pressed={home} onClick={() => { setHome(true); setT(0); }}>Coming home</button>
        </div>
        <div className={styles.presets} role="group" aria-label="Ship speed">
          {[0.5, 0.8, 0.95].map((b) => (
            <button type="button" key={b} aria-pressed={b === beta} onClick={() => { setBeta(b); setT(0); }}>{b}c</button>
          ))}
          <button type="button" onClick={() => setRunning(!running)}>{running ? 'Pause' : 'Play'}</button>
        </div>
      </div>
      <svg className={styles.chase} viewBox={`0 0 ${W} ${H}`} role="img"
        aria-label={`Earth's pulses chasing a ship at ${beta}c: ${received} of the pulses have reached it`}>
        <line x1={EARTH_X} y1={70} x2={W - 14} y2={70} className={styles.track} />
        <circle cx={EARTH_X} cy={70} r={11} className={styles.earth} />
        <text x={EARTH_X} y={104} className={styles.label} textAnchor="middle">Earth</text>
        {pulses.map((x, i) => <circle key={i} cx={x} cy={70} r={3.2} className={styles.pulse} />)}
        <g transform={`translate(${ship} 70)`}>
          <circle r={9} className={styles.ship} />
          <text y={34} className={styles.label} textAnchor="middle">ship</text>
        </g>
        <text x={W - 14} y={24} className={styles.label} textAnchor="end">
          {home ? `received ${received}` : `sent ${sent} · received ${received}`}
        </text>
      </svg>
      <figcaption>
        Each dot is one of Earth's daily broadcasts, moving at the speed of light. {home
          ? 'Flying home, the ship runs into everything Earth sent while it was away, far faster than one a day.'
          : 'Leaving, the ship is nearly as fast as the light, so the broadcasts gain on it slowly. Nothing is lost: what has not arrived is still on its way.'}
      </figcaption>
    </figure>
  );
}

// Earth's beams: the plan Earth has heard sets where it points.
export function Beams() {
  // Scale: 5 px per light-year. Sol at (50, 190); port A 40 ly out at (250, 190).
  const sol = [50, 190], a = [250, 190];
  const side = [250, 40];       // 30 ly sideways from A
  const near = [50, 140];       // a star 10 ly from Sol, off to the side
  return (
    <figure className={styles.panel}>
      <svg className={`${styles.beams} ${styles.big}`} viewBox="0 0 640 235" role="img"
        aria-label="Earth's beam runs from Sol through port A and beyond. A port 30 light-years to the side of A waits 60 years to hear Earth; a star 10 light-years from Sol off to the side waits 8.8 years; anywhere on the beam line waits nothing.">
        <polygon points={`${sol[0]},${sol[1]} 630,${sol[1] - 12} 630,${sol[1] + 12}`} className={styles.cone} />
        <line x1={sol[0]} y1={sol[1]} x2={630} y2={sol[1]} className={styles.beamline} />
        <line x1={a[0]} y1={a[1]} x2={side[0]} y2={side[1]} className={styles.leg} />
        <line x1={a[0]} y1={a[1]} x2={near[0]} y2={near[1]} className={styles.leg} />
        <circle cx={sol[0]} cy={sol[1]} r={8} className={styles.earth} />
        <text x={sol[0]} y={sol[1] + 28} className={styles.label} textAnchor="middle">Sol</text>
        <circle cx={a[0]} cy={a[1]} r={6} className={styles.port} />
        <text x={a[0]} y={a[1] + 26} className={styles.label} textAnchor="middle">port A, 40 ly</text>
        <circle cx={side[0]} cy={side[1]} r={6} className={styles.port} />
        <text x={side[0] + 12} y={side[1] + 4} className={styles.label}>30 ly sideways: wait 60 years</text>
        <circle cx={near[0]} cy={near[1]} r={6} className={styles.port} />
        <text x={near[0] - 8} y={near[1] - 14} className={styles.label} textAnchor="start">10 ly from Sol: wait 8.8 years</text>
        <circle cx={430} cy={sol[1]} r={6} className={styles.port} />
        <text x={430} y={sol[1] + 26} className={styles.label} textAnchor="middle">on the beam line: no wait</text>
        <text x={630} y={sol[1] - 20} className={styles.label} textAnchor="end">Earth's beam to port A</text>
      </svg>
      <figcaption>
        Earth aims where you told it you would be. Change course at port A and your new plan takes 40 years to reach
        Earth, and Earth's new beam then has to cross to the new port. You hear home there only if you stay for the
        difference: the distance from Earth to A, plus Earth to the new port, minus the leg you flew.
      </figcaption>
    </figure>
  );
}

// A star as a lens: light from a world behind it bends round the limb and meets on the far side.
export function Lens() {
  const rays = [-1, -0.55, 0.55, 1];
  return (
    <figure className={styles.panel}>
      <svg className={styles.beams} viewBox="0 0 640 180" role="img"
        aria-label="Light from a distant world passes either side of a star, bends, and meets on a focal line hundreds of AU beyond it, where the telescope sits.">
        <circle cx={40} cy={90} r={6} className={styles.port} />
        <text x={40} y={124} className={styles.label} textAnchor="middle">the world</text>
        {rays.map((r) => (
          <polyline key={r} points={`40,90 300,${90 + r * 34} 560,90`} className={styles.ray} />
        ))}
        <circle cx={300} cy={90} r={26} className={styles.star} />
        <text x={300} y={140} className={styles.label} textAnchor="middle">lens star</text>
        <line x1={560} y1={90} x2={630} y2={90} className={styles.beamline} />
        <rect x={552} y={82} width={16} height={16} rx={3} className={styles.ship} />
        <text x={560} y={124} className={styles.label} textAnchor="middle">telescope on the focal line</text>
        <text x={430} y={30} className={styles.label} textAnchor="middle">≥ F = R²c² / 4GM beyond the star</text>
      </svg>
      <figcaption>Not to scale. The world is light-years away; the focal line is light-days beyond the star.</figcaption>
    </figure>
  );
}
