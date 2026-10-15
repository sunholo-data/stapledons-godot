# Unreleased changelog fragments

Each change adds one fragment here, `YYYY-MM-DD-<slug>.md`, holding `### Added`, `### Changed`,
`### Fixed` (and similar) sections. Fragments never conflict; edits to CHANGELOG.md did.

When a build is tagged (`v*`), the release workflow runs `tools/changelog_fold.sh rebuild`. That
files every fragment the tag contains under a `## <tag> (<date>)` section in CHANGELOG.md, removes
the folded fragments, and commits to main. The section becomes the GitHub release notes
(`tools/changelog_fold.sh notes <tag>`). Fragments not yet in any tag stay here.
