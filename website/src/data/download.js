// The current downloadable build. Update this one file when a new build is published
// (and add a News post for its release, see news/README.md).
const TAG = 'v0.4.0-dev.1';
const REPO = 'https://github.com/sunholo-data/stapledons-godot';
const ZIP = `StapledonsVoyage-${TAG}-macos.zip`;

const DOWNLOAD = {
  tag: TAG,
  title: 'Walkable bridge demo',
  label: 'Development build: macOS only (Apple Silicon)',
  zip: `${REPO}/releases/download/${TAG}/${ZIP}`,
  sha256: `${REPO}/releases/download/${TAG}/${ZIP}.sha256`,
  release: `${REPO}/releases/tag/${TAG}`,
  allReleases: `${REPO}/releases`,
  news: '/news/2026/10/03/walkable-bridge-demo-v0-4-0-dev-1',
  quarantine: 'xattr -dr com.apple.quarantine "Stapledons Voyage.app"',
};

export default DOWNLOAD;
