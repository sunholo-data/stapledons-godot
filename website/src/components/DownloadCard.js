import React from 'react';
import Link from '@docusaurus/Link';
import {Download} from 'lucide-react';
import DOWNLOAD from '@site/src/data/download';
import styles from './DownloadCard.module.css';

// The download box for the current build (src/data/download.js).
export default function DownloadCard({compact = false}) {
  const d = DOWNLOAD;
  return (
    <div className={styles.card}>
      <div className={styles.head}>
        <span className="sv-status sv-status--progress">{d.label}</span>
        <span className={styles.tag}>{d.tag}</span>
      </div>
      <p className={styles.title}>{d.title}</p>
      <a className={styles.button} href={d.zip}>
        <Download size={18} aria-hidden="true" /> Download for macOS
      </a>
      <p className={styles.small}>
        Pre-alpha and <strong>unsigned</strong>. After unzipping, clear the quarantine flag once:
      </p>
      <pre className={styles.code}>
        <code>{d.quarantine}</code>
      </pre>
      {!compact && (
        <p className={styles.small}>
          <a href={d.sha256}>sha256</a> · <a href={d.release}>release notes</a> ·{' '}
          <Link to={d.news}>what's in it</Link>
        </p>
      )}
    </div>
  );
}
