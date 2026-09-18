# Changelog

All notable changes to Zenith are documented here.

## [0.6.1] — 2026-09-18

### Added
- **Swipe navigation** — Outpost, Atlas, Depot, and Sanctuary can now be
  navigated with a horizontal swipe, in addition to the bottom nav bar.

### Changed
- Interaction and route-transition motion (buttons, sheets, dialogs,
  toasts, collapsible cards, screen navigation) now uses a fast,
  continuous snap instead of the pixel-stepped motion introduced in
  0.6.0, after it read as stutter rather than deliberate retro motion on
  a real device.

### Fixed
- The back button on Atlas and Depot did nothing — it now returns you to
  the Outpost.

## [0.6.0] — 2026-09-18

### Added
- **Exercise illustrations** — every exercise in the Atlas now shows a
  themed position-sequence illustration (e.g. a push-up shows both the
  lying and pressed positions, a lunge shows both the stance and the
  standing return), tinted to match its movement pattern's color, in both
  the Atlas station inspector and the live workout screen.
- **The Outpost** — a new home dashboard: today's prescribed session,
  training streak, and lifetime session/set/tonnage stats.
- **CC BY-SA attribution section** — a credits panel in the Depot crediting
  the illustration sources under their license.

### Changed
- **Plain-language rewrite** — every exercise's form cues, the pre-workout
  warm-up checklist, the Depot's accommodation toggles, and the post-set
  effort ratings were rewritten from clinical/technical phrasing into
  everyday language.
- **Visual fidelity pass** — body copy now uses a monospace terminal font
  throughout instead of a sans-serif face; interaction motion (buttons,
  sheets, dialogs, toasts, route transitions) now uses a quantized,
  pixel-art-stepped curve instead of a smooth spring ease; the district
  backdrop gained CRT scanlines and a fuller scene (lamp post, rail
  plinths, more foreground grass); the Sanctuary's recovery bars now show
  green/amber/red by actual readiness state.
- Grimoire and Armory were renamed to **Atlas** and **Depot**.

### Fixed
- A web persistence race that could resurrect a session you'd just
  discarded, after a page reload.
- An Android build failure caused by a dependency conflict between the
  file picker plugin and a stale `win32` version pin.
- Several exercise illustrations rendering blank on certain Android
  devices (GPU-driver-specific rendering issue) — worked around by
  falling back to a more broadly compatible renderer, then reverted after
  it turned out to cause a worse regression (a launch crash) on at least
  one device; the underlying blank-illustration issue may resurface and
  needs a more targeted fix.
- A double-tap on the workout FSM that could double-advance a set.
- An abort/persist race that could leave a discarded session's data
  half-written.
- Assorted accessibility, layout-overflow, and code-review-flagged issues
  across the Outpost, Sanctuary, and expedition screens.

## Earlier versions

Versions 0.1.0 through 0.5.1 predate this changelog. See the git tag
history for that range.
