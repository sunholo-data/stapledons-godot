#!/bin/sh
# 7aw: check evidence for secret values before upload. The optional names file
# adds candidate names from the caller's environment.
set -eu
[ "$#" -ge 2 ] || { echo 'usage: evidence_publish.sh <remote-prefix> <file-or-dir>...' >&2; exit 2; }
remote=$1; shift
case "$remote" in
  ''|*..*|*[!abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789./_-]*)
    echo 'evidence-publish: unsafe remote prefix' >&2; exit 2 ;;
esac
command -v gsutil >/dev/null 2>&1 || { echo 'evidence-publish: gsutil required' >&2; exit 2; }
SELF=$(cd "$(dirname "$0")" && pwd -P)
rc=0
if [ -n "${EVIDENCE_GUARD_NAMES_FILE:-}" ]; then
  sh "$SELF/evidence_secret_guard.sh" --require-candidates --names-file "$EVIDENCE_GUARD_NAMES_FILE" -- "$@" || rc=$?
else
  sh "$SELF/evidence_secret_guard.sh" --require-candidates -- "$@" || rc=$?
fi
[ "$rc" = 0 ] || { echo "evidence-publish: refused (guard rc $rc); nothing uploaded" >&2; exit "$rc"; }
echo "evidence-publish: guard clean; uploading $# pack(s) to gs://$remote/"
gsutil -m cp -r -- "$@" "gs://$remote/"
