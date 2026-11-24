#!/bin/sh
# 7aw: exercise the guard and publisher on synthetic evidence with cloud commands stubbed.
set -eu
if [ "${1:-}" != --isolated ]; then
  exec env -i PATH=/usr/bin:/bin TMPDIR="${TMPDIR:-/tmp}" sh "$0" --isolated "$@"
fi
shift
SELF=$(cd "$(dirname "$0")" && pwd -P)
G="$SELF/evidence_secret_guard.sh"
P="$SELF/evidence_publish.sh"
T=$(mktemp -d "${TMPDIR:-/tmp}/evidence-guard-control.XXXXXX")
trap 'rm -rf "$T"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM HUP
mkdir "$T/bin" "$T/home" "$T/tmp" "$T/dirty files" "$T/clean dir"
cat > "$T/bin/gcloud" <<'STUB'
#!/bin/sh
echo 'unexpected cloud command in guard control' >&2
exit 99
STUB
cat > "$T/bin/gsutil" <<'STUB'
#!/bin/sh
printf '%s\n' "$@" >> "${PUBLISH_TEST_LOG:?}"
STUB
chmod +x "$T/bin/gsutil" "$T/bin/gcloud"
PATH="$T/bin:$PATH" HOME="$T/home" TMPDIR="$T/tmp"
PUBLISH_TEST_LOG="$T/gsutil.log"
export PATH HOME TMPDIR PUBLISH_TEST_LOG

tok='sp-synthetic-[token].canary'
private='sp-synthetic-private.canary'
first='synthetic-first-line'
second='synthetic-second-line'
multi=$(printf '%s\r\n \t%s\t\r' "$first" "$second")
short=$(printf '1234567\r\n \t\nabc')
pem=$(printf '%s\n%s\n%s\n' '-----BEGIN PRIVATE KEY-----' 'synthetic-long-body' '-----END PRIVATE KEY-----')
printf 'rc=0\n' > "$T/clean.txt"
printf 'rc=0\n' > "$T/clean dir/profile.tsv"
dirty="$T/dirty files/.database copy.txt"
printf 'SP_FAKE_TOKEN=%s\n' "$tok" > "$dirty"
( cd "$T/dirty files" && tar -czf "$T/evidence pack.tgz" . )
printf 'invalid gzip archive\n' > "$T/bad.tar.gz"

fails=0; cases=0
check() {
  label=$1; shift
  cases=$((cases + 1))
  if "$@"; then return 0; fi
  fails=$((fails + 1))
  printf 'evidence-guard control: FAIL: %s\n' "$label" >&2
}
run_guard() {
  mode=$1; shift
  rc=0
  (
    case "$mode" in
      token) export SP_FAKE_TOKEN="$tok" ;;
      private) export PRIVATE_STUFF="$private" ;;
      multi) export SP_FAKE_TOKEN="$multi" ;;
      short) export SP_FAKE_TOKEN="$short" ;;
      pem) export SP_FAKE_TOKEN="$pem" ;;
      GIT_PAT|X_AUTH|MY_CREDENTIAL) export "$mode=$name_canary" ;;
      none) ;;
    esac
    exec sh "$G" "$@"
  ) > "$T/out" 2> "$T/err" || rc=$?
}
expect_rc() {
  if [ "$rc" = "$1" ]; then return 0; fi
  printf 'evidence-guard control: expected rc %s, got %s\n' "$1" "$rc" >&2
  return 1
}
reports() { grep -Fq -- "$1" "$T/out" "$T/err"; }
no_output_value() {
  if reports "$1"; then return 1; else [ "$?" = 1 ]; fi
}
clean_tmp() {
  for temp in "$T/tmp"/evidence-guard.*; do
    if [ -e "$temp" ]; then return 1; fi
  done
}
hit() { expect_rc 1 && reports "$1" && no_output_value "$2"; }

run_guard token "$dirty"
check 'dirty file refusal' expect_rc 1
check 'dirty file attribution' reports "SP_FAKE_TOKEN value is in $dirty"
check 'dirty file output omits value' no_output_value "$tok"
if [ "${1:-}" = dirty-file ]; then
  printf 'evidence-guard control: %s checks, %s failures\n' "$cases" "$fails"
  test "$fails" = 0
  exit
fi

run_guard token "$T/clean dir" "$T/dirty files"
check 'directory recursion and whitespace path' hit "SP_FAKE_TOKEN value is in $dirty" "$tok"
run_guard token "$T/clean.txt"
check 'clean file' expect_rc 0
run_guard token "$T/clean dir"
check 'clean directory' expect_rc 0
run_guard token "$T/evidence pack.tgz"
archive_attribution() { expect_rc 1 && reports "$1"; }
check 'archive member attribution and refusal' archive_attribution "SP_FAKE_TOKEN value is in $T/evidence pack.tgz:.database copy.txt"
check 'archive output omits value' no_output_value "$tok"
chmod 000 "$T/clean.txt"
run_guard token "$T/clean.txt"
check 'unreadable input' expect_rc 2
chmod 600 "$T/clean.txt"
run_guard none "$T/nonexistent"
check 'missing input with no candidates' expect_rc 2
run_guard token "$T/bad.tar.gz"
check 'bad archive' expect_rc 2

mkdir "$T/packs" "$T/layers"
cp "$T/evidence pack.tgz" "$T/packs/dirty pack.tar.gz"
run_guard token "$T/packs"
check 'directory archive refusal and member attribution' hit "SP_FAKE_TOKEN value is in $T/packs/dirty pack.tar.gz:.database copy.txt" "$tok"
rm "$T/packs/dirty pack.tar.gz"
tar -czf "$T/packs/clean.tgz" -C "$T/clean dir" profile.tsv
# A clean result alone cannot distinguish extraction from scanning compressed bytes.
cat > "$T/bin/tar" <<'STUB'
#!/bin/sh
printf '%s\n' "$1" >> "$(dirname "$0")/tar.calls"
PATH=/usr/bin:/bin exec tar "$@"
STUB
chmod +x "$T/bin/tar"
: > "$T/bin/tar.calls"
run_guard token "$T/packs"
clean_nested_archive() { expect_rc 0 && grep -Fxq -- '-xzf' "$T/bin/tar.calls"; }
check 'clean directory archive unpacked and accepted' clean_nested_archive
rm "$T/bin/tar" "$T/packs/clean.tgz"
cp "$T/bad.tar.gz" "$T/packs/bad.tgz"
run_guard token "$T/packs"
check 'corrupt directory archive' expect_rc 2

cp "$T/evidence pack.tgz" "$T/layers/inner.tar.gz"
tar -czf "$T/middle.tgz" -C "$T/layers" inner.tar.gz
tar -czf "$T/outer.tgz" -C "$T" middle.tgz
run_guard token "$T/outer.tgz"
check 'three archive levels scanned' hit "SP_FAKE_TOKEN value is in $T/outer.tgz:middle.tgz:inner.tar.gz:.database copy.txt" "$tok"
tar -czf "$T/too-deep.tgz" -C "$T" outer.tgz
run_guard token "$T/too-deep.tgz"
check 'fourth archive level refused' expect_rc 2

for name in GIT_PAT X_AUTH MY_CREDENTIAL; do
  name_canary="synthetic-$name.canary"
  printf '%s\n' "$name_canary" > "$T/name-leak.txt"
  run_guard "$name" "$T/name-leak.txt"
  check "default name filter matches $name" hit "$name value is in $T/name-leak.txt" "$name_canary"
done

run_guard none --require-candidates "$T/clean.txt"
check 'zero candidates with requirement' expect_rc 2
run_guard none "$T/clean.txt"
check 'zero candidates without requirement' expect_rc 0
check 'temp trees gone after all three outcomes' clean_tmp

printf '%s\n' "$private" > "$T/innocent-leak.txt"
printf 'PRIVATE_STUFF\n' > "$T/names.txt"
printf '# synthetic op template\r\nPRIVATE_STUFF=op://v/i/f\r\n' > "$T/names-template.txt"
printf 'PRIVATELY_ABSENT\n' > "$T/names-hint.txt"
printf '# only comments, blanks and an invalid name\n\nPRIVATE STUFF\n' > "$T/names-empty.txt"
run_guard private "$T/innocent-leak.txt"
check 'AC12 bare guard with innocently named value' expect_rc 0
run_guard private --names-file "$T/names.txt" "$T/innocent-leak.txt"
check 'AC12 plain names-file refusal' expect_rc 1
check 'AC12 names-file attribution' reports "PRIVATE_STUFF value is in $T/innocent-leak.txt"
check 'AC12 names-file output omits value' no_output_value "$private"
run_guard private --names-file "$T/names-template.txt" "$T/innocent-leak.txt"
check 'AC12 template names-file refusal' hit "PRIVATE_STUFF value is in $T/innocent-leak.txt" "$private"
run_guard private --names-file "$T/names.txt" --names-file "$T/names-hint.txt" "$T/innocent-leak.txt"
repeated_names() {
  hit "PRIVATE_STUFF value is in $T/innocent-leak.txt" "$private" &&
    grep -Fq 'names-file name absent from environment (hint, no value to guard): PRIVATELY_ABSENT' "$T/err"
}
check 'AC12 repeatable names files' repeated_names
run_guard private --names-file "$T/names-template.txt" "$T/names-template.txt"
check 'AC12 names file stays clean' expect_rc 0
run_guard private --names-file "$T/nonexistent-names.txt" "$T/clean.txt"
check 'AC12 missing names file' expect_rc 2
run_guard private --names-file "$T/names-empty.txt" "$T/clean.txt"
check 'AC12 no valid names in file' expect_rc 2
chmod 000 "$T/names.txt"
run_guard private --names-file "$T/names.txt" "$T/clean.txt"
check 'AC12 unreadable names file' expect_rc 2
chmod 600 "$T/names.txt"
run_guard none --names-file "$T/names-hint.txt" "$T/clean.txt"
absent_name() {
  expect_rc 0 &&
    grep -Fq 'names-file name absent from environment (hint, no value to guard): PRIVATELY_ABSENT' "$T/err"
}
check 'AC12 absent name is hinted on stderr' absent_name
printf '%s\n' "$second" > "$T/multi-leak.txt"
run_guard multi "$T/multi-leak.txt"
split_lines() {
  hit "SP_FAKE_TOKEN value is in $T/multi-leak.txt" "$second" && no_output_value "$first"
}
check 'AC13 trimmed second line refusal' split_lines
run_guard short --require-candidates "$T/clean.txt"
short_rc=$rc
run_guard short "$T/clean.txt"
short_candidates() { [ "$short_rc" = 2 ] && expect_rc 0; }
check 'AC13 short and blank lines contribute zero candidates' short_candidates
printf '%s\n' '-----BEGIN PRIVATE KEY-----' '-----END PRIVATE KEY-----' > "$T/armour-only.txt"
run_guard pem --require-candidates "$T/armour-only.txt"
armour_only() {
  expect_rc 0 &&
    reports 'clean (1 candidate value line(s)' &&
    no_output_value '-----BEGIN PRIVATE KEY-----' &&
    no_output_value '-----END PRIVATE KEY-----'
}
check 'revision 3 PEM armour stays clean with a usable body line' armour_only

run_publish() {
  : > "$PUBLISH_TEST_LOG"
  mode=$1; shift
  rc=0
  (
    case "$mode" in
      token) export SP_FAKE_TOKEN="$tok" ;;
      named)
        export SP_FAKE_TOKEN="$tok" PRIVATE_STUFF="$private"
        export EVIDENCE_GUARD_NAMES_FILE="$T/publish names.txt" ;;
      none) ;;
    esac
    exec sh "$P" "$@"
  ) > "$T/out" 2> "$T/err" || rc=$?
}
no_upload() { test -f "$PUBLISH_TEST_LOG" && test ! -s "$PUBLISH_TEST_LOG"; }
wrapper_refusal() {
  expect_rc "$1" &&
    grep -Fxq "evidence-publish: refused (guard rc $1); nothing uploaded" "$T/err"
}
upload_args() {
  printf '%s\n' -m cp -r -- "$@" 'gs://benchmarks/probe/' > "$T/expected-argv"
  cmp -s "$T/expected-argv" "$PUBLISH_TEST_LOG"
}
run_publish token benchmarks/probe "$dirty"
check 'wrapper dirty refusal' wrapper_refusal 1
check 'dirty wrapper never calls gsutil' no_upload
run_publish token benchmarks/probe "$T/clean.txt" "$T/clean dir"
check 'wrapper clean' expect_rc 0
check 'wrapper clean calls gsutil exactly once with expected argv' upload_args "$T/clean.txt" "$T/clean dir"
run_publish none benchmarks/probe "$T/clean.txt"
check 'wrapper instrument failure with zero candidates' wrapper_refusal 2
check 'instrument failure never calls gsutil' no_upload
run_publish token 'benchmarks/../probe' "$T/clean.txt"
unsafe_remote() {
  expect_rc 2 && grep -Fq 'evidence-publish: unsafe remote prefix' "$T/err"
}
check 'wrapper unsafe remote' unsafe_remote
check 'unsafe remote never calls gsutil' no_upload

printf 'PRIVATE_STUFF=op://v/i/f\nPRIVATELY_ABSENT\n' > "$T/publish names.txt"
run_publish named benchmarks/probe "$T/innocent-leak.txt"
named_refusal() {
  wrapper_refusal 1 && hit "PRIVATE_STUFF value is in $T/innocent-leak.txt" "$private"
}
check 'names-file wrapper refusal' named_refusal
check 'names-file wrapper never calls gsutil' no_upload
run_publish named benchmarks/probe "$T/clean.txt"
check 'names-file wrapper clean' expect_rc 0
check 'names-file wrapper calls gsutil exactly once with expected argv' upload_args "$T/clean.txt"
check 'names-file wrapper reports absent name hint' absent_name

printf 'evidence-guard control: %s checks, %s failures\n' "$cases" "$fails"
test "$fails" = 0
