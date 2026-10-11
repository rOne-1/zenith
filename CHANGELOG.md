# Changelog

All notable changes to Zenith are documented here.

## [0.8.0] — 2026-10-11

### Platform Polish, Motion Ergonomics & Accessibility Resilience
- **Reduced Motion Architecture (PKG-10.1 / A11Y-4)** — introduced centralized `ZenithMotionContext` extension on `BuildContext` (`animationsDisabled`, `adaptiveDuration(Duration)`, `motionDuration`); suppressed infinite animation tickers and rendered static representations in `PixelPulseDot` and `PixelLoadingIndicator` under reduced motion; paused ambient video playback in `DistrictBackgroundMediaLayer`; and bypassed slide/fade route and modal animations in `ZenithPageTransitionsBuilder`, `ZenithDialog`, and `ZenithSheet`.
- **Dynamic Type Scale Clamping & Layout Resilience (PKG-10.2 / A11Y-5)** — applied selective font scale clamping via `MediaQuery.withClampedTextScaling(maxScaleFactor: 1.25)` across fixed chrome in `ZenithNavigationBar` and `withClampedTextScaling(maxScaleFactor: 1.3)` across RPE rating buttons in `RpeSelectorCard`; converted hard `SizedBox` height constraints in `PixelButton` to `ConstrainedBox(minHeight: ...)` to support vertical expansion on multiline labels without `RenderFlex` overflow at 2.0x system scale.
- **App Shell 4-Phase Gesture Discrimination (PKG-10.3 / UX-1)** — implemented 4-phase horizontal drag tracking (`onHorizontalDragStart`, `Update`, `Cancel`, `End`) in `ZenithAppShell`; gated tab transitions on dual displacement ($\ge 64$dp) and velocity ($\ge 500$px/s) thresholds with directional sign validation; and isolated nested horizontal scrolls (Grimoire pattern pills, illustration carousels) via gesture arena cancellation.
- **Abort Flow Navigation Sequencing (PKG-10.4 / POL-1)** — refactored `ActiveExpeditionScreen._handleAbort()` to pop the route from the navigator *before* awaiting `controller.abortSession()`, eliminating transient 1-2 frame flashes of the Warm-Up screen on workout cancellation.
- **Automated Testing Suite (PKG-10.5)** — added comprehensive automated test suites covering reduced motion behavior, Dynamic Type 2.0x scale resilience, shell gesture discrimination, and clean abort route pops, bringing the project test baseline to 283/283 tests passing (100%).

## [0.7.0] — 2026-10-11

### Design System Unification, Typography Resilience & Visual Rhythm
- **Silkscreen Typography Helper Suite (PKG-9.1 / DES-4)** — introduced centralized `zenithPixelDisplay(...)` helper suite alongside `pixelDisplaySm` (9dp), `pixelDisplayMd` (11dp), `pixelDisplayLg` (13dp), and `pixelDisplayXl` (16dp) presets in `lib/core/theme/zenith_text_styles.dart`; includes automatic fallback to `monospace` and synchronous local font evaluation under test environments (`isTestEnvironment`) to eliminate test runner font-loading hangs.
- **System-Wide Typography Sweep (PKG-9.2 / DES-4)** — eradicated all 176 raw `TextStyle` instantiations across 26 feature and core widget files, routing brand pixel display typography strictly through `zenithPixelDisplay` and monospaced body through `zenithBodyMono`.
- **Centralized Spacing Token Scale (PKG-9.3 / DES-6)** — introduced `ZenithSpacing` (`xxs: 2.0`, `xs: 4.0`, `sm: 8.0`, `md: 12.0`, `lg: 16.0`, `xl: 24.0`, `xxl: 32.0`) in `lib/core/theme/zenith_spacing.dart` with standard `EdgeInsets` and `SizedBox` gap presets; eliminated off-grid magic literals across high-density cards, sheets, and gutters.
- **Dynamic Grimoire Pattern Theming (PKG-9.4 / DES-8)** — bound Grimoire `_FilterPill` active and border colors dynamically to `MetroLineTheme.forPattern(pattern, colors).color`, ensuring instantaneous chromatic adaptation between District 01 ("Railside Outskirts") and District 02 ("Neon Alleys").
- **Stepped Pixel Border Elevation (PKG-9.5)** — upgraded 31 plain `Border.all()` vectors across 5 high-density card and chip files (`pattern_recovery_grid.dart`, `macrocycle_progress_card.dart`, `adaptation_ledger_card.dart`, `station_inspector_sheet.dart`, `expedition_portal_screen.dart`) to authentic `SteppedPixelBorder` 16-bit arcade staircases using `context.pixelMetrics.cornerStepSize`.

## [0.6.5] — 2026-10-10

### Fixed
- **Cryptographic master key overwrite prevention** — differentiated between clean key absence on fresh install and transient secure keystore read exceptions (locked device, daemon busy, channel error); rethrows wrapped in `SecureStorageException` rather than generating a new key and permanently destroying access to existing encrypted user records (PKG-HF.1, CRIT-1).
- **Concurrency-safe state hydration in user profile** — guarded `_persist` and all public mutation methods in `UserProfileNotifier` (`toggleEquipment`, `toggleJointProtection`, `toggleCycleAutoregulation`, `setExperienceLevel`, `setCycleDay`) with `await _initFuture;` so mutations immediately on cold-start wait for asynchronous secure hydration and apply on top of loaded state rather than wiping sensitive health telemetry with null (PKG-HF.2, BUG-1).
- **District 02 Neon Alleys typography alignment** — updated `neonAlleysPalette` tokens to canonical Japanese cyberpunk visual specification: `textPrimary` to `Color(0xFFEAF3FF)` (cool-white catching blue-violet mist), `textMuted` to `Color(0xFF7C8CB8)` (indigo-slate), and `signalRed` to `Color(0xFFFF4433)` (`emberSign`), eliminating residual District 01 teal text colors (PKG-HF.3, DES-7).

## [0.6.4] — 2026-10-10

### Security & Platform Hardening
- **Sensitive health telemetry encryption** — introduced pure-Dart AES-256-GCM encrypted storage for sensitive physiological fields (`femaleProfile`, `hasJointPain`) with automatic migration and purging of legacy plaintext preferences (SEC-1).
- **Disabled insecure Android application backup** — enforced `android:allowBackup="false"` in `AndroidManifest.xml` preventing local ADB database extraction (SEC-2).
- **Web Content Security Policy** — added restrictive Content Security Policy `<meta>` header for web builds supporting Drift SQLite WASM workers, Google Fonts, and local assets (SEC-3).

### Accessibility (WCAG AA)
- **Screen reader semantics** — added descriptive `Semantics` wrappers across navigation tabs, collapsible cards, gear inventory tiles, RPE buttons, and Miller variable gauges, eliminating raw glyph reading (A11Y-1).
- **WCAG AA contrast compliance** — inverted danger button text color to `backgroundVoid`, achieving 5.8:1 contrast against signal red (A11Y-2).
- **Expanded touch targets** — expanded RPE rating buttons to minimum 48dp height with responsive scaling for narrow 320px viewports (A11Y-3).

### Design Tokens & Theming
- **Official secondary accent token** — introduced `accentSecondary` to `ZenithDistrictColors` and `ZenithDistrictPalette`, replacing all 20 hardcoded `0xFF2EE6D6` literals across feature files (DES-1).
- **Semantic token aliases** — added `accentPrimary` and `accentGlow` getters aliasing `amberAccent` and `amberGlow` for cross-district semantic clarity (DES-3).
- **Canonical Neon Alleys palette** — wired authentic Japanese cyberpunk chromatic DNA for District 02 (deep indigo void `#060814`, vibrant fuchsia `#FF2FA0`, stairwell fern `#39C08A`) (DES-2).
- **Dynamic button bevels** — replaced hardcoded amber and red bevels with dynamic HSL lightness derivation matching active district themes (DES-5).

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
