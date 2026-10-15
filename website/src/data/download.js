// The downloadable build. TAG is the fallback the static site is built with; the release workflow
// rewrites it on every tag (.github/workflows/release.yml), and the download card asks GitHub for
// the newest release with a macOS zip when the page loads, so the site never needs a redeploy for
// a new build.
const TAG = 'v0.4.0-dev.29-crew-console';
const REPO = 'https://github.com/sunholo-data/stapledons-godot';
export const RELEASES_API = 'https://api.github.com/repos/sunholo-data/stapledons-godot/releases?per_page=20';

export function downloadFor(tag) {
  const zip = `StapledonsVoyage-${tag}-macos.zip`;
  return {
    tag,
    title: titleOf(tag),
    label: 'Development build: macOS only (Apple Silicon)',
    zip: `${REPO}/releases/download/${tag}/${zip}`,
    sha256: `${REPO}/releases/download/${tag}/${zip}.sha256`,
    release: `${REPO}/releases/tag/${tag}`,
    allReleases: `${REPO}/releases`,
    news: '/news',
    quarantine: 'xattr -dr com.apple.quarantine "Stapledons Voyage.app"',
  };
}

// "v0.4.0-dev.29-crew-console" -> "Development build 29: crew console"
function titleOf(tag) {
  const m = /^v[\d.]+-dev\.(\d+)-?(.*)$/.exec(tag);
  if (!m) return tag;
  return m[2] ? `Development build ${m[1]}: ${m[2].replace(/-/g, ' ')}` : `Development build ${m[1]}`;
}

const DOWNLOAD = downloadFor(TAG);
export default DOWNLOAD;
