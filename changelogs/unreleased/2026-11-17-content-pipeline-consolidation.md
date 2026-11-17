### Added

- A four-bundle authoring catalog for the captain, painted NPCs and both painted decks, with retained provenance pins, explicit review status, runtime closure digests and independently measured byte/resource budgets. Existing runtime loaders and asset bytes are unchanged.
- Headless contract, budget, scratch-stage and pack-fixture checks. They reject missing/corrupt raw images, portrait witnesses, native resources and manifests, wrong import remaps, unsafe paths, exceeded budgets and leaked authoring records. The full authoring/runtime checks never generate, fetch, stage or re-pin assets.

### Fixed

- Classify the painted candidate's two authoring entry defaults and dynamic production resource directory in the existing export audit. The real-pack oracle now checks the dynamic content closure; authoring catalog/captain-guide directories are excluded from exports. Native export evidence remains pending until the separately prepared combined build runs the strict oracle.
