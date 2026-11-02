### Fixed
- **S1 capture publish checks** (row 7l(a)). `capture-m4-publish` checks all 18 files for presence and content, validates the PNG manifest and requires 14 world hashes before its first upload. A private-fixture test with a fake `gcloud` covers complete, missing, empty, truncated and changed files through each available GNU Make version, and runs in `make test` and `ci-fast`.
