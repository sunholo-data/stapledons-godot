import React, {useCallback, useEffect, useState} from 'react';
import clsx from 'clsx';
import Link from '@docusaurus/Link';
import useBaseUrl from '@docusaurus/useBaseUrl';
import Layout from '@theme/Layout';
import {X, ChevronLeft, ChevronRight} from 'lucide-react';
import Clip from '@site/src/components/Clip';
import GALLERY from '@site/src/data/gallery';
import styles from './gallery.module.css';

const CLIPS = [
  {name: 'ism_transit', title: 'Weather between the stars', text: 'At 0.999c the actual Aldebaran route crosses LIC, Aur, LIC again, hot gas, Hyades and hot gas again. This 24-second capture cuts between the real route intervals; each displayed dust tick advances 1/30 ship second. The wall glow, grain impacts and medium notices come from the simulation.'},
  {name: 'black_hole_orbit', title: 'Orbiting Sagittarius A*', text: 'A stable orbit at three horizon radii: the real simulation advances 1,800 ship seconds in 20 seconds of video. The lensed background is the labelled Sol sky; the clocks and orbit count come from the simulation.'},
  {name: 'saturn_arrival', title: 'Arriving beside Saturn', text: 'The guided voyage\'s final approach reaches a real at-rest stop, with Saturn and its rings in the same physical view. The approach is compressed to 16 screen seconds, followed by six seconds beside the planet; earlier stops are omitted.'},
  {name: 'voyage', title: 'Rest to 0.99c, looking forward', text: 'A 1 g burn through the AILANG simulation, rapidity eased over 18 s. 24 s loop.'},
  {name: 'lookaround', title: 'One full turn at 0.99c', text: 'Bow, beam, stern and back at γ 7.09: the bright window ahead and the dark behind. 20 s loop.'},
  {name: 'cmb', title: 'The forward CMB disc, γ 20 to 707', text: '20° lens, on a committed journey near Sol: the stars crowd into a shrinking ball, then the CMB warms from deep red to near white. 20 s loop.'},
  {name: 'map', title: 'Galaxy map, cruise slider 0.9c to the cap', text: 'The planner panel recomputed by the simulation every tick as the camera orbits Sol and α Centauri. 24 s loop.'},
];

const GROUPS = [
  ['ism', 'Weather between the stars'],
  ['ship', 'The painted ship'],
  ['sky', 'The relativistic sky'],
  ['cmb', 'The forward CMB'],
  ['map', 'The galaxy map and the journey'],
];

export default function Gallery() {
  const base = useBaseUrl('/img/gallery/');
  const [open, setOpen] = useState(-1);
  const close = useCallback(() => setOpen(-1), []);
  const step = useCallback((d) => setOpen((i) => (i + d + GALLERY.length) % GALLERY.length), []);

  useEffect(() => {
    if (open < 0) return undefined;
    const onKey = (e) => {
      if (e.key === 'Escape') close();
      if (e.key === 'ArrowRight') step(1);
      if (e.key === 'ArrowLeft') step(-1);
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [open, close, step]);

  const cur = open >= 0 ? GALLERY[open] : null;
  return (
    <Layout title="Gallery" description="Native captures and videos from Stapledon's Voyage: black-hole orbits, Saturn arrival, local interstellar clouds, dust and the relativistic sky.">
      <header className={styles.header}>
        <div className={styles.container}>
          <h1 className={styles.title}>Gallery</h1>
          <p className={styles.lead}>
            Every image and clip here is a capture from the game: the Godot renderer, driven by the
            AILANG simulation. Captions say what produced each one, and the <Link to="/docs/roadmap">roadmap</Link> says
            what is built and what is planned.
          </p>
        </div>
      </header>
      <main className={styles.container}>
        <section className={styles.block}>
          <h2>Video</h2>
          <div className={styles.clips}>
            {CLIPS.map((c) => (
              <figure key={c.name} className={styles.clip}>
                <Clip name={c.name} className={styles.video} label={c.title} controls />
                <figcaption>
                  <strong>{c.title}.</strong> {c.text}
                </figcaption>
              </figure>
            ))}
          </div>
        </section>
        {GROUPS.map(([g, label]) => (
          <section key={g} className={styles.block}>
            <h2>{label}</h2>
            <div className={styles.grid}>
              {GALLERY.map((it, i) =>
                it.group === g ? (
                  <figure key={it.file} className={styles.item}>
                    <button type="button" className={styles.open} onClick={() => setOpen(i)} aria-label={`Open: ${it.title}`}>
                      <img src={it.url || base + it.file} alt={it.title} loading="lazy" width="800" height="450" />
                    </button>
                    <figcaption>
                      <strong>{it.title}</strong>
                      {it.status && <span className={clsx('sv-status', 'sv-status--review', styles.pill)}>{it.status}</span>}
                      <span className={styles.cap}>{it.caption}</span>
                    </figcaption>
                  </figure>
                ) : null,
              )}
            </div>
          </section>
        ))}
      </main>
      {cur && (
        <div className={styles.lightbox} role="dialog" aria-modal="true" aria-label={cur.title} onClick={close}>
          <button type="button" className={clsx(styles.lbBtn, styles.lbClose)} onClick={close} aria-label="Close">
            <X size={22} />
          </button>
          <button type="button" className={clsx(styles.lbBtn, styles.lbPrev)} onClick={(e) => { e.stopPropagation(); step(-1); }} aria-label="Previous">
            <ChevronLeft size={26} />
          </button>
          <figure className={styles.lbFigure} onClick={(e) => e.stopPropagation()}>
            <img src={cur.url || base + cur.file} alt={cur.title} />
            <figcaption>
              <strong>{cur.title}.</strong> {cur.caption}
            </figcaption>
          </figure>
          <button type="button" className={clsx(styles.lbBtn, styles.lbNext)} onClick={(e) => { e.stopPropagation(); step(1); }} aria-label="Next">
            <ChevronRight size={26} />
          </button>
        </div>
      )}
    </Layout>
  );
}
