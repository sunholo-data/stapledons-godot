import {useEffect, useState} from 'react';
import DOWNLOAD, {RELEASES_API, downloadFor} from '@site/src/data/download';

// The download to offer: the build-time fallback (download.js) first, then the newest published
// release GitHub reports with a macOS zip, so a new build shows up without redeploying the site.
// `sha256` is null when that release has no .sha256 file.
export default function useDownload() {
  const [d, setD] = useState(DOWNLOAD);
  useEffect(() => {
    let live = true;
    fetch(RELEASES_API, {headers: {Accept: 'application/vnd.github+json'}})
      .then((r) => (r.ok ? r.json() : []))
      .then((releases) => {
        const rel = releases.find((x) => !x.draft && (x.assets || []).some((a) => a.name.endsWith('-macos.zip')));
        if (!live || !rel) return;
        const next = downloadFor(rel.tag_name);
        if (!rel.assets.some((a) => a.name.endsWith('-macos.zip.sha256'))) next.sha256 = null;
        setD(next);
      })
      .catch(() => {});
    return () => {
      live = false;
    };
  }, []);
  return d;
}
