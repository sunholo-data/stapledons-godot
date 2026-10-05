import React from 'react';
import clsx from 'clsx';
import Link from '@docusaurus/Link';
import useBaseUrl from '@docusaurus/useBaseUrl';
import Layout from '@theme/Layout';
import Clip from '@site/src/components/Clip';
import {BRIDGE_V1, BRIDGE_V2, CAPTAIN, CREW, MEDIC, SHIP_LAYERS} from '@site/src/data/concept';
import styles from './concept-art.module.css';

function Pill({kind, children}) {
  return <span className={clsx('sv-status', `sv-status--${kind}`, styles.pill)}>{children}</span>;
}

function Img({it, base, className, sizes}) {
  return (
    <a href={it.full} className={clsx(styles.img, className)} target="_blank" rel="noopener noreferrer" title="Open full size">
      <img src={base + it.file} alt={it.title} loading="lazy" sizes={sizes} />
    </a>
  );
}

function Wide({it, base}) {
  return (
    <figure className={clsx(styles.wide, it.narrow && styles.narrow)}>
      <Img it={it} base={base} />
      <figcaption>
        <strong>{it.title}.</strong> {it.caption}
      </figcaption>
    </figure>
  );
}

export default function ConceptArt() {
  const base = useBaseUrl('/img/concept/');
  return (
    <Layout title="Concept art" description="Concept and work-in-progress art for Stapledon's Voyage: the captain, the crew, and the bridge of the bubble ship.">
      <header className={styles.header}>
        <div className={styles.container}>
          <p className={styles.kicker}>Concept and work-in-progress art</p>
          <h1 className={styles.title}>Concept art</h1>
          <p className={styles.lead}>
            The faces and the rooms of the ship. Everything here is <strong>concept or work in progress</strong>,
            and each piece says how far along it is. The sky behind the bridge is not painted: it is the game's
            live relativistic sky. Click any image for the full-size file.
          </p>
        </div>
      </header>

      <main className={styles.container}>
        <section className={styles.block}>
          <h2>Art direction</h2>
          <div className={styles.prose}>
            <p>
              The look comes from French 1970s science-fiction comics, the <em>ligne claire</em> and{' '}
              <em>Métal Hurlant</em> tradition of Moebius and Philippe Druillet. The brief takes their qualities,
              never their images: technology that looks grown, organic and mechanical blended; saturated colour
              against vast emptiness; tiny humans in huge structures; clean, flowing curves; cathedral-like spaces.
            </p>
            <p>
              The ship is a sphere, the Higgs bubble, about 100 m in radius. A spire runs through its
              centre. The <strong>bridge</strong> is a disc at the very top of the spire, right under the bubble's
              forward pole, which is its dome, and it is the smallest level. Below it, open levels radiate from
              the spire, widening toward the sphere's equator and narrowing again below.
            </p>
            <p>
              Interiors are seen in an <strong>isometric, layered view</strong>. The play area is a toon-shaded,
              ink-outlined 3D scene; behind it sits a painted panorama with every patch of space left transparent;
              behind that is the live sky, rendered through exactly the same camera. As the camera pans, the
              foreground moves fastest, the deck 1:1, the panorama slowly, and the sky not at all. One rule binds
              the artists: <em>never paint space</em>. So when the ship runs at 0.99c, the stars outside the
              bridge railings crowd forward and turn blue, exactly as in the sky flight.
            </p>
          </div>
        </section>

        <section id="ship-layers" className={styles.block}>
          <div className={styles.blockHead}>
            <h2>The whole ship</h2>
            <Pill kind="progress">Style concept proposal</Pill>
          </div>
          <Wide it={SHIP_LAYERS} base={base} />
          <p className={styles.note}>
            Compare two measured Blender layouts, rotate the models, download the source files,
            and inspect bridge sightlines on the{' '}
            <Link to="/docs/ship-layer-reference">bubble-ship geometry and style review page</Link>
            {' '}. Use those models for dimensions; this drawing guides style.
          </p>
        </section>

        <section className={styles.block}>
          <div className={styles.blockHead}>
            <h2>The captain</h2>
            <Pill kind="done">Picked, final quality</Pill>
          </div>
          <Wide it={CAPTAIN.sheet} base={base} />
          <div className={styles.stages}>
            {CAPTAIN.stages.map((it) => (
              <figure key={it.file} className={styles.stage}>
                <Img it={it} base={base} />
                <figcaption>{it.title}</figcaption>
              </figure>
            ))}
          </div>
          <p className={styles.note}>
            The game runs across a 100-year career, so the captain ages on deck: the same figure at 30, 50, 70
            and 90.
          </p>
        </section>

        <section className={styles.block}>
          <div className={styles.blockHead}>
            <h2>The Medic</h2>
            <Pill kind="done">Accepted portrait set</Pill>
          </div>
          <div className={styles.portraits}>
            {MEDIC.map((it) => (
              <figure key={it.file} className={styles.portrait}>
                <Img it={it} base={base} />
                <figcaption>{it.title}</figcaption>
              </figure>
            ))}
          </div>
          <figure className={styles.wide}>
            <Clip name="medic" className={styles.video} label="The Medic conversation scene" sound />
            <figcaption>
              <strong>The conversation scene, rehearsed on the stub.</strong> The portrait cross-fades as emotion
              markers in the line arrive, and the subtitles build segment by segment.{' '}
              <Pill kind="planned">Placeholder voice</Pill> The voice is the stub's test tone, not a performance:
              no live AI call has been made yet.
            </figcaption>
          </figure>
        </section>

        <section className={styles.block}>
          <div className={styles.blockHead}>
            <h2>Crew cast</h2>
            <Pill kind="progress">Proposals</Pill>
          </div>
          <p className={styles.note}>
            Proposed faces for the rest of the crew, one neutral portrait each, labelled by role. Names and
            everything else about them are still open.
          </p>
          <div className={styles.crew}>
            {CREW.map((it) => (
              <figure key={it.file} className={styles.portrait}>
                <Img it={it} base={base} />
                <figcaption>{it.title}</figcaption>
              </figure>
            ))}
          </div>
        </section>

        <section className={styles.block}>
          <div className={styles.blockHead}>
            <h2>The bridge, v1</h2>
            <Pill kind="done">Demo art, merged</Pill>
          </div>
          <p className={styles.note}>
            The first real interior, merged as demo art for the playable journey, replacing the blockout
            (game <a href="https://github.com/sunholo-data/stapledons-godot/pull/97">PR #97</a>). The v2 work
            below will revisit it.
          </p>
          {BRIDGE_V1.map((it) => (
            <Wide key={it.file} it={it} base={base} />
          ))}
        </section>

        <section className={styles.block}>
          <div className={styles.blockHead}>
            <h2>The bridge, v2</h2>
            <Pill kind="progress">Style study: final art in progress</Pill>
          </div>
          {BRIDGE_V2.map((it) => (
            <Wide key={it.file} it={it} base={base} />
          ))}
        </section>

        <section className={clsx(styles.block, styles.credit)}>
          <h2>Credit</h2>
          <p>
            AI-generated art, made with image models and Blender under Sunholo's art direction. No copyright
            is claimed. See <Link to="/docs/credits">Credits and licences</Link>.
          </p>
        </section>
      </main>
    </Layout>
  );
}
