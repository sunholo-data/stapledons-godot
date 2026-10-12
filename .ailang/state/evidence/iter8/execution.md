# Iteration 8 executor evidence — M1.2b-T2_F32_RECORDS

Generator implements only the approved T2 child; independent judge pending. Child and parent `passes:null`. Approved runtime v0.50.0, commit 6abe1a5 (darwin/arm64); baseline 19f55bf, contract d4e9498. Designer scope review reported COVERED by controller.

## Changed hunks and LOC

- `sim/tools/catalogue_bytes.ail`: new pure Result[bytes,string] encodeRow/encodeRows. Existing Row and native std/embedding.encodeF32LE, field order x,y,z,teff,v,float(flags). Bounds and legal integer flags checked first; output collected as reversed byte chunks then concatList once, avoiding repeated full-buffer copies.
- `sim/tools/catalogue_bytes_test.ail`: new pure runnable oracle transport and nonfinite construction/check entry. Transport constructs Row from numeric arrays; no filesystem effects.
- `tools/test_catalogue_bytes.py`: independent Python struct.pack('<6f') bytes, 17 boundary values, every flag0..31, empty and exact48-byte sequence, every field +/-overflow, invalid flags, no-prefix and sticky-error rows. Interpreter and five full ordinary VM outputs each compared to independent bytes; NaN/+Inf/-Inf every field on both backends. Every subprocess timeout60s.
- `sim/tools/catalogue_test.ail`: new N1/N2 tests; transformVm requires both. Strict and interpreter gate retained.
- `sim/ailang.toml`: one export added for pure production codec module.
- `Makefile`: catalogue-bytes dependency in make test; new target invokes Python oracle.

Changed code/test/config LOC: **133** = new files22+21+74=117, tracked diff additions13+deletions3=16. This conservatively counts both deleted and inserted lines; docs/evidence/sprint-state excluded. Cap250. No FS writer, sidecars, tier builds, fallback, physics duplication or production data writes.

## Commands and outcomes

All run from `/Users/voightkampff/dev/sunholo-data/.stapledon-wt-iter8`:

1. `runtime/bin/ailang --version`: v0.50.0/6abe1a5.
2. `python3 tools/test_catalogue_bytes.py > .ailang/state/evidence/iter8/red.log 2>&1` before production module existed: FAIL (missing module/export). No implementation until captured red.
3. `runtime/bin/ailang check --package sim`: PASS12 files (check.log). Test modules unexported warnings follow existing convention.
4. `runtime/bin/ailang test --package sim`: PASS, zero failures (ailang-test.log).
5. `python3 tools/test_catalogue_bytes.py`: PASS2 tests, interpreter + five VM runs (oracle.log and final make log).
6. `make catalogue-vm catalogue-bytes AILANG=$PWD/runtime/bin/ailang`: PASS strict T1 transform-ok/selection-ok and oracle (gates.log).
7. `make test AILANG=$PWD/runtime/bin/ailang AILANG_BIN=$PWD/runtime/bin/ailang`: PASS before mutations (make-test.log); repeated after final implementation/restoration (make-test-restored.log).
8. `python3 .godot/tmp/catalogue-bytes/mutations.py` and `python3 .godot/tmp/catalogue-bytes/bigendian.py`: compiling mutation results in mutations.log and per-mutant logs. Source restored from byte copies; SHA256 verified every restoration. Temporary scripts copied with original backup bytes under .godot/tmp, never git checkout for source restoration.

## Mutation matrix

Every mutation was separately compiled by `runtime/bin/ailang check --package sim`, then tested; final matrix has **26 killed + 1 redundant survivor**. Detailed named subtest failures are preserved in `mutant-*.log`.

| Neutered/change | Named killer |
| --- | --- |
| bypass_x/y/z/teff/v separately | test_exact_bytes_and_refusals / reject_FIELD_+/-1e39 |
| finite/range predicate replaced true | test_nonfinite_each_field (NaN/Inf each field); range cases also fail |
| lower/upper bound separately | test_exact_bytes_and_refusals / reject_FIELD_-1e39/+1e39 |
| negative/high flag guard separately | test_exact_bytes_and_refusals / reject_flag_-1/32 |
| drop_previous_error (Err -> valid empty chunk) | test_exact_bytes_and_refusals / sticky_error_FIELD_VALUE |
| encodeRow Err -> Ok(previous bytes) | test_exact_bytes_and_refusals / no_prefix_FIELD_VALUE |
| final Err -> Ok(empty bytes) | test_exact_bytes_and_refusals / reject_FIELD_VALUE |
| swap_xy, swap_teff_v, flags_integer_bits, f64, big_endian | test_exact_bytes_and_refusals / two_records_source_order + boundary/flag cases |
| drop_row, duplicate_row | test_exact_bytes_and_refusals / two_records_source_order |
| lose_signed_zero, flush_subnormal, wrong_ties, wrong_carry | test_exact_bytes_and_refusals / named boundary_i_VALUE |
| N1 wrong dwarf predicate -> WD invertibility | strict transformVm N1 (transform-BAD) |
| N2 remove second final blank | strict transformVm N2 (transform-BAD) |
| remove only `v == v` | SURVIVED: redundant; remaining lower/upper bounds reject NaN on both consumed backends. Whole predicate neutering is killed. No false claim of mutation completeness. |

Transient first replacement of drop_previous_error returned literal Ok([]), rejected by STRICT_FALLBACK_001: **not counted as a killed mutant**. Replaced with compiling Ok([encodeF32LE([])]) and killed. N4/N5/N9 T1 redundant/dead branches remain unchanged (production catalogue.ail byte-identical); only N1/N2 test paths touched. Row-input transport fallback isn't a production refusal branch.

## Deviations / upstream reports

CLI `--args-json` could not decode imported exported `Row` alias (`unsupported type constructor: Row`), so oracle entry transports nested numeric lists and constructs existing Row. Flags transported as float values are converted to int; all tested flag stimuli are integers and production Row.flags stays int. GCP user report `inbox_1790876207432_e897bb14`, --from stapledons_godot. Existing native codec strict gate remains **N/A known Phase2E __embedding_encode gap**, previously reported `inbox_1790875803550_a044780b`. Ordinary VM and interpreter oracle pass; strict sim/core, WD and T1 remain mandatory and pass in make test. No duplicate strict-gap report.

Independent evaluation, not executor, may set child passes true. Parent remains null and downstream T3/T4 ownership is retained.
