# Changelog

All notable changes to Zenith are documented here.

## [0.6.3] — 2026-10-10

### Fixed
- **Session finalization atomicity** — wrapped progression logging and session persistence in an atomic SQLite transaction (`db.transaction(...)`), preventing partial commits or replay on retry.
- **GlobalKey duplication** — converted `ActiveExpeditionScreen` to a stateful widget with an instance-scoped toast host key, eliminating route-transition duplicate GlobalKey crashes.
- **Streak calculation across DST boundaries** — replaced 24-hour duration subtraction with calendar-date arithmetic (`DateTime(y, m, d - 1)`), preventing false streak resets across Daylight Saving Time shifts.
- **Static hold telemetry** — recorded actual elapsed hold seconds clamped to prescribed duration instead of defaulting unconditionally to target duration when completing sets early.
- **Cold-start resume probe race condition** — guarded Expedition Portal initiate button against pending resume probe states, preventing concurrent session instantiation.
- **Same-day session detection** — normalized `WarningTranslator` range query to an exclusive `[startOfDay, nextDay)` interval, resolving microsecond-boundary omissions near midnight.

### Performance & Architectural Hygiene
- **Backdrop repaint boundary isolation** — isolated background layers of `RailsideAtmosphereBackdrop` and `NeonAlleysAtmosphereBackdrop` inside dedicated `RepaintBoundary` widgets, preventing expensive repaints of complex backdrop media, noise grain, and scanlines during foreground timer ticks.
- **Volume metric parity** — excluded static hold sets from weekly rep and tonnage totals in `MacrocycleService`, aligning weekly telemetry with session debrief metrics.
- **Core storage decoupling** — relocated `sharedPreferencesProvider` from the UI theme layer to `lib/core/storage/preferences_provider.dart`, removing architectural inversion for non-UI domain providers.
- **Desktop video controller guard** — guarded `districtVideoControllerProvider` against unsupported Windows and Linux desktop platforms, falling back cleanly to still art without unhandled platform-channel exceptions.
- **Test ticker hygiene** — suppressed `PixelLoadingIndicator` infinite animation sweep during widget test execution to prevent test timeout hangs.
- **Redundant logic cleanup** — cleaned redundant conditionals in `MacrocycleState` and eliminated duplicate catalog loops in `AdaptationLedgerService`.

## [0.6.2] — 2026-09-21

### Added
- **Onboarding** — new installs now get a short first-launch setup (gear,
  physical accommodations, training experience) so day one is built for
  you instead of defaulting silently. Every question is optional and can
  be changed later in the Depot; a self-declared beginner gets an
  easier starting band of exercises until the app's own automatic
  progression tracking takes over.
- **A second district** — a theme toggle (top right of the Outpost) now
  switches between two fully-realized backdrops, Railside Outskirts and
  Neon Alleys.
- **Timers for hold exercises** — a static hold (like a side plank) now
  shows a real countdown instead of a rep counter.

### Changed
- Tightened the exercise form cues throughout the Atlas so every
  instruction describes the complete movement, start to finish, instead
  of stopping partway through.

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
