import React, {useEffect, useMemo, useState} from 'react';
import clsx from 'clsx';
import Link from '@docusaurus/Link';
import useBaseUrl from '@docusaurus/useBaseUrl';
import Layout from '@theme/Layout';
import {ArrowDownUp, ExternalLink, Eye, Volume2, Type, Search, RotateCcw, GitPullRequest, FileText} from 'lucide-react';
import data from '@site/src/data/decisions.json';
import styles from './decisions.module.css';

// Mark's decisions, generated at build time by scripts/decisions.mjs from the game repo's decision
// ledger, the design repo's design-decisions.md (vendored at a pinned commit) and a few rulings
// recorded in other repo files. Story and narrative decisions are left out (no spoilers).

const TABS = [
  {id: 'sense', label: 'Look, sound and words', groups: ['visual', 'audio', 'text']},
  {id: 'physics', label: 'Physics and sky', groups: ['physics']},
  {id: 'gameplay', label: 'Gameplay', groups: ['gameplay']},
  {id: 'ai', label: 'AI', groups: ['ai']},
  {id: 'planets', label: 'Planets', groups: ['planets']},
  {id: 'infra', label: 'Infrastructure', groups: ['infra']},
  {id: 'process', label: 'Process', groups: ['process']},
  {id: 'all', label: 'All', groups: null},
];
const SENSES = [
  {id: 'all', label: 'All', icon: null},
  {id: 'visual', label: 'Visual', icon: Eye},
  {id: 'audio', label: 'Audio', icon: Volume2},
  {id: 'text', label: 'Text', icon: Type},
];
const GROUP_LABEL = {
  visual: 'Visual', audio: 'Audio', text: 'Text', physics: 'Physics', gameplay: 'Gameplay',
  ai: 'AI', planets: 'Planets', infra: 'Infrastructure', process: 'Process',
};
const SOURCE_LABEL = {ledger: 'Decision ledger', design: 'Design log', supplementary: 'Recorded ruling'};
const REL_LABEL = {
  supersedes: 'Supersedes', supersededBy: 'Superseded by', refines: 'Refines', refinedBy: 'Refined by',
  records: 'Records ledger', recordedAs: 'Also recorded as',
};

function Asset({a}) {
  const src = useBaseUrl(`/${a.img || ''}`);
  const poster = useBaseUrl(`/${a.poster || ''}`);
  const ogg = useBaseUrl(`/${(a.audio || [])[0] || ''}`);
  const mp3 = useBaseUrl(`/${(a.audio || [])[1] || ''}`);
  if (a.audio) {
    return (
      <figure className={styles.asset}>
        <span className={clsx('sv-status', 'sv-status--progress')}>Placeholder</span>
        <audio controls preload="none" className={styles.audio}>
          <source src={ogg} type="audio/ogg" />
          <source src={mp3} type="audio/mpeg" />
        </audio>
        <figcaption>{a.caption}</figcaption>
      </figure>
    );
  }
  return (
    <figure className={styles.asset}>
      <a href={src} target="_blank" rel="noreferrer">
        <img src={src} alt={a.caption} loading="lazy" style={a.poster ? {backgroundImage: `url(${poster})`} : undefined} />
      </a>
      <figcaption>{a.caption}</figcaption>
    </figure>
  );
}

function Ruling({text}) {
  const long = text.length > 700;
  if (!long) return <p className={styles.ruling}>{text}</p>;
  return (
    <details className={styles.more}>
      <summary>
        <span className={styles.ruling}>{text.slice(0, 520).replace(/\s+\S*$/, '')}…</span>
        <span className={styles.moreLink}>Read the full ruling</span>
      </summary>
      <p className={styles.ruling}>{text}</p>
    </details>
  );
}

function Card({d, onJump}) {
  const rels = Object.entries(d.relations || {});
  return (
    <article id={d.id} className={clsx(styles.card, d.superseded && styles.superseded)}>
      <header className={styles.cardHead}>
        <span className={styles.id}>{d.source === 'ledger' ? d.id : SOURCE_LABEL[d.source]}</span>
        <time className={styles.date}>{d.date}</time>
        {d.groups.map((g) => (
          <span key={g} className={styles.group}>{GROUP_LABEL[g]}</span>
        ))}
        {d.subtopic && <span className={styles.sub}>{d.subtopic}</span>}
        {d.revisit && <span className={clsx('sv-status', 'sv-status--progress')} title={d.revisit}><RotateCcw size={11} /> Revisit</span>}
        {d.superseded && <span className={clsx('sv-status', 'sv-status--planned')}>Superseded</span>}
      </header>
      <h3 className={styles.title}>{d.title}</h3>
      {d.revisit && <p className={styles.revisit}><strong>Revisit:</strong> {d.revisit}</p>}
      <div className={styles.body}>
        <div className={styles.text}>
          {d.question && (
            <>
              <h4 className={styles.label}>{d.source === 'design' ? 'Context' : 'Question'}</h4>
              <p className={styles.question}>{d.question}</p>
            </>
          )}
          <h4 className={styles.label}>Ruling</h4>
          <Ruling text={d.ruling} />
          {d.words.length > 0 && (
            <>
              <h4 className={styles.label}>In Mark's words</h4>
              {d.words.map((w) => (
                <blockquote key={w} className={styles.words}>{w}</blockquote>
              ))}
            </>
          )}
          {d.provenance && (
            <>
              <h4 className={styles.label}>{d.source === 'design' ? 'Rationale' : 'Provenance'}</h4>
              <p className={styles.prov}>{d.provenance}</p>
            </>
          )}
          {rels.length > 0 && (
            <ul className={styles.rels}>
              {rels.map(([k, list]) => (
                <li key={k}>
                  <strong>{REL_LABEL[k] || k}:</strong>{' '}
                  {list.map((x, i) => (
                    <span key={x.id || x.note}>
                      {i > 0 && '; '}
                      {x.id ? (
                        <a href={`#${x.id}`} onClick={(e) => onJump(e, x.id)}>
                          {x.id.startsWith('D-') ? `${x.id}: ` : ''}{x.title}
                        </a>
                      ) : (
                        x.note
                      )}
                    </span>
                  ))}
                </li>
              ))}
            </ul>
          )}
          <p className={styles.links}>
            <a href={d.link}><FileText size={14} /> {d.sourceLabel} <ExternalLink size={12} /></a>
            {d.refs.map((r) => (
              <a key={`${r.repo}${r.n}`} href={r.url}>
                <GitPullRequest size={14} /> {r.repo === 'design' ? 'design ' : ''}{r.kind === 'issue' ? 'issue' : 'PR'} #{r.n}
              </a>
            ))}
          </p>
        </div>
        {d.assets.length > 0 && (
          <div className={styles.assets}>
            {d.assets.map((a) => (
              <Asset key={a.img || a.audio[0]} a={a} />
            ))}
          </div>
        )}
      </div>
    </article>
  );
}

export default function Decisions() {
  const [tab, setTab] = useState('sense');
  const [sense, setSense] = useState('all');
  const [query, setQuery] = useState('');
  const [newest, setNewest] = useState(true);
  const [pending, setPending] = useState(null);

  // a #id in the URL opens the "All" tab so the card is in view
  useEffect(() => {
    const h = decodeURIComponent(window.location.hash.slice(1));
    if (h && data.decisions.some((d) => d.id === h)) {
      setTab('all');
      setPending(h);
    }
  }, []);
  useEffect(() => {
    if (!pending) return;
    const el = document.getElementById(pending);
    if (el) {
      el.scrollIntoView({behavior: 'smooth', block: 'start'});
      el.classList.add(styles.flash);
      setTimeout(() => el.classList.remove(styles.flash), 1600);
    }
    setPending(null);
  }, [pending, tab, query, sense]);

  const onJump = (e, id) => {
    e.preventDefault();
    window.history.replaceState(null, '', `#${id}`);
    const visible = document.getElementById(id);
    if (!visible) {
      setTab('all');
      setSense('all');
      setQuery('');
    }
    setPending(id);
  };

  const shown = useMemo(() => {
    const t = TABS.find((x) => x.id === tab);
    const q = query.trim().toLowerCase();
    let list = data.decisions.filter((d) => {
      if (t.groups && !d.groups.some((g) => t.groups.includes(g))) return false;
      if (tab === 'sense' && sense !== 'all' && !d.groups.includes(sense)) return false;
      if (q) {
        const hay = `${d.id} ${d.title} ${d.question} ${d.ruling} ${d.words.join(' ')} ${d.provenance} ${d.subtopic}`.toLowerCase();
        if (!q.split(/\s+/).every((w) => hay.includes(w))) return false;
      }
      return true;
    });
    list = [...list].sort((a, b) => (a.date + a.id).localeCompare(b.date + b.id));
    return newest ? list.reverse() : list;
  }, [tab, sense, query, newest]);

  const counts = useMemo(() => {
    const c = {};
    for (const t of TABS) c[t.id] = data.decisions.filter((d) => !t.groups || d.groups.some((g) => t.groups.includes(g))).length;
    return c;
  }, []);

  return (
    <Layout title="Decisions" description="Every ruling Mark has made on Stapledon's Voyage: look, sound and words first, then physics, gameplay, AI and process. Generated from the project's decision records.">
      <header className={styles.header}>
        <div className={styles.container}>
          <h1>Decisions</h1>
          <p className={styles.lead}>
            Every ruling Mark has made on the game, in one place, so they can be reviewed, lived with
            and changed. Look, sound and words come first. Each card links to the line it came from.
          </p>
          <p className={styles.meta}>
            Generated {data.generated} from the game repo's{' '}
            <a href="https://github.com/sunholo-data/stapledons-godot/blob/main/design_docs/stapledon-mission.md">decision ledger</a>, the design repo's{' '}
            <a href={`https://github.com/sunholo-data/stapledons-design/blob/${data.designPin}/vision/design-decisions.md`}>design log</a> (pinned at{' '}
            <code>{data.designPin.slice(0, 7)}</code>) and rulings recorded in sprint plans and art notes.
            {' '}{data.decisions.length} decisions. Story and narrative decisions are left out, so nothing here spoils the game.
          </p>
          <details className={styles.how}>
            <summary>How to change a decision</summary>
            <p>
              Any decision can be revised. Mark states a new ruling in an attended session, and it is
              recorded straight into the{' '}
              <a href="https://github.com/sunholo-data/stapledons-godot/blob/main/design_docs/stapledon-mission.md">decision ledger</a>{' '}
              (with <code>mission_answer.sh</code>), or he comments on the{' '}
              <a href="https://github.com/sunholo-data/stapledons-godot/issues/93">art issue #93</a> or the{' '}
              <a href="https://github.com/sunholo-data/stapledons-godot/issues/1">mission issue #1</a>.
            </p>
            <p>
              The page rebuilds its data from those records on every deploy. The design-repo log is
              refreshed when someone runs <code>node scripts/decisions.mjs --sync</code> in{' '}
              <code>website/</code> and commits the new pin. The old ruling stays visible, marked
              superseded, with a link to the new one.
            </p>
            <p>
              <strong>Revisit</strong> marks rulings that are explicitly provisional: demo art, a
              voice still to be auditioned, placeholder audio.
            </p>
          </details>
        </div>
      </header>
      <main className={styles.container}>
        <div className={styles.tabs} role="tablist" aria-label="Decision groups">
          {TABS.map((t) => (
            <button key={t.id} type="button" role="tab" aria-selected={tab === t.id}
              className={clsx(styles.tab, tab === t.id && styles.tabOn, t.id === 'sense' && styles.tabPrimary)}
              onClick={() => setTab(t.id)}>
              {t.label} <span className={styles.count}>{counts[t.id]}</span>
            </button>
          ))}
        </div>
        <div className={styles.controls}>
          {tab === 'sense' && (
            <div className={styles.chips}>
              {SENSES.map(({id, label, icon: Icon}) => (
                <button key={id} type="button" className={clsx(styles.chip, sense === id && styles.chipOn)} onClick={() => setSense(id)}>
                  {Icon && <Icon size={14} />} {label}
                </button>
              ))}
            </div>
          )}
          <label className={styles.search}>
            <Search size={16} />
            <input type="search" placeholder="Search decisions" value={query} onChange={(e) => setQuery(e.target.value)} aria-label="Search decisions" />
          </label>
          <button type="button" className={styles.sort} onClick={() => setNewest(!newest)}>
            <ArrowDownUp size={14} /> {newest ? 'Newest first' : 'Oldest first'}
          </button>
        </div>
        <p className={styles.showing}>{shown.length} shown</p>
        <div className={styles.list}>
          {shown.map((d) => (
            <Card key={d.id} d={d} onJump={onJump} />
          ))}
          {shown.length === 0 && <p>No decision matches. Clear the search or pick another tab.</p>}
        </div>
        <p className={styles.foot}>
          See also the <Link to="/docs/roadmap">roadmap</Link>.
        </p>
      </main>
    </Layout>
  );
}
