### Fixed

- Bound the raw crew-console command to 300 seconds by default, retaining its
  original exit, script-error and exact-summary checks and import prerequisite.
- Use a monotonic shell/Perl supervisor for script gates and crew-console, retaining
  observed descendant birth identities across process-group changes and reparenting.
  Cancellation and normal exit attempt cleanup of retained, observed children
  within a three-second budget. Each signal requires fresh identity inspection;
  persistent inspection failures are reported and can prevent cleanup.
- Relay directed HUP, INT and TERM through the calling shells, independently of
  prior summaries or expected exit codes. Add an independent test guardian and
  permanent bounded-run controls, with targeted mutation, real-runtime and scope drills.

Polling cannot contain a child that escapes before observation, and portable
second-resolution process birth tokens leave an observation-to-signal race.
Runtime acceptance is controller-owned; static checks alone do not establish it.

The independent guardian retains arbitrary observed command descendants. Process
inspection drains available nonblocking bytes within the unchanged 200 ms bound.
Wrapper readiness confirms the inner worker and held command before publication.
Real-runtime drills isolate HOME, XDG directories, temporary files and engine logs,
and verify actual OS directory locations before using the caller's original test
(normal mode) or a restored private project copy (synthetic modes).
