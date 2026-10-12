#!/bin/sh
# make site-deploy: publish website/build to the gh-pages branch of the origin remote.
# No git worktree and no branch switch in this checkout: the build is copied into a
# temporary clone of gh-pages (or a new orphan branch the first time), committed, pushed.
#   SITE_REMOTE  remote URL to push to (default: this checkout's origin)
#   DRY=1        build the commit in the temporary clone, print it, and stop before the push
set -eu

BUILD=website/build
REMOTE=${SITE_REMOTE:-$(git remote get-url origin)}
BASE=${SITE_BASE:-/stapledons-godot/}

[ -f "$BUILD/index.html" ] || { echo "site-deploy: no $BUILD/index.html (run make site)" >&2; exit 1; }
# Check generated assets, not ordinary content links which can contain the
# project path even when the build itself used the wrong base URL.
asset_prefix="${BASE}assets/"
grep -q "href=\"${asset_prefix}css/" "$BUILD/index.html" &&
    grep -q "src=\"${asset_prefix}js/" "$BUILD/index.html" || {
    echo "site-deploy: CSS/JS assets were not built for base $BASE; run make site" >&2
    exit 1
}

src=$(git rev-parse --short HEAD)
dirty=$(git status --porcelain -- website | head -1)
tmp=$(mktemp -d "${TMPDIR:-/tmp}/site-deploy.XXXXXX")
trap 'rm -rf "$tmp"' EXIT

if git clone --quiet --depth 1 --branch gh-pages "$REMOTE" "$tmp/pages" 2>/dev/null; then
    echo "site-deploy: updating gh-pages from $REMOTE"
else
    echo "site-deploy: no gh-pages branch on $REMOTE yet; starting an orphan branch"
    git init --quiet -b gh-pages "$tmp/pages"
    git -C "$tmp/pages" remote add origin "$REMOTE"
fi

# replace the tree with the build (keep .git), then make sure Jekyll stays off
find "$tmp/pages" -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +
cp -R "$BUILD"/. "$tmp/pages"/
touch "$tmp/pages/.nojekyll"

cd "$tmp/pages"
git add -A
if git diff --cached --quiet; then
    echo "site-deploy: gh-pages already matches the build; nothing to push"
    exit 0
fi
msg="site: deploy from $src${dirty:+ (uncommitted website changes)}"
git -c user.name="$(git -C "$OLDPWD" config user.name || echo site-deploy)" \
    -c user.email="$(git -C "$OLDPWD" config user.email || echo site-deploy@localhost)" \
    commit --quiet -m "$msg"
git --no-pager log --oneline -1
git --no-pager show --stat --oneline HEAD | tail -3
if [ "${DRY:-0}" = 1 ]; then
    echo "site-deploy: DRY=1, not pushing"
    exit 0
fi
git push origin gh-pages
echo "site-deploy: pushed. Pages serves it at https://www.sunholo.com$BASE once the Pages source is gh-pages / root."
