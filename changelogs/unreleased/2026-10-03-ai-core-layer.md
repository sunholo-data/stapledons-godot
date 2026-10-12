### Added

- The AI core layer (sprint R1-AI-FOUNDATION AI.8, design (a4)). The accepted Medic set (4 portraits and 1 avatar) is now pinned and content-addressed:
  - `data/ai/core/index.ndjson` and `data/ai/core/SHA256SUMS` hold the set, imported from `blender@8f04dfc` by `ai/tools/core_import.ail` (AILANG, `std/crypto.sha256Bytes`).
  - `ai_core`, the `new_game` value, is the sha256 of the index: `$(AI_CORE)` in `mk/ai.mk`.
- `make ai-core-verify` runs offline as part of `make test`. It checks:
  - the fixture import against its expected files, and that a corrupted blob is refused;
  - that the committed index and sums are consistent and every key is valid;
  - the blob hashes, when `data/raw/ai_core` has the blobs (AILANG, plus `shasum` as an independent check);
  - with the Blender checkout present, that a fresh import from the pinned commit matches.

  `AI_CORE_FETCH=1` fetches the blobs first.
- `make ai-core-assets` fetches the blobs from `gs://stapledons-voyage-assets/ai/` over anonymous HTTPS and checks each sha.
- `make ai-core-bundle` stages `ai_core/` for the export.
- `make ai-core-publish` uploads the blobs `--no-clobber` (maintainers, gcloud).
- `make ai-core-import` re-imports the set from the Blender repo at `AI_CORE_COMMIT` (maintainers).
- `make ai-mutants` gains 5 mutants of the core import and verifier.

### Changed

- `infra/gcp/README.md` documents the bucket's `ai/` prefix, and that the `openrouter-api-key` secret is created empty and Mark adds its value.
