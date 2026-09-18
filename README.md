# Zenith

A bodyweight-only calisthenics training app with a neo-pixel, Japanese
train-station aesthetic. No gym, no equipment required by default — just a
structured path from your first wall push-up to a strict one-arm push-up,
pull-up, and pistol squat.

## What it does

- **The Atlas** — a metro-map view of 31 exercises across 5 movement
  patterns (Push, Pull, Bend & Lift, Single Leg, Rotation), each laid out as
  a "line" of 6 progressively harder tiered "stations." Every exercise ships
  with an illustrated position sequence, plain-language form cues, and five
  progression variables (load, body position, range of motion, limb
  elevation, tempo) so you always know exactly what changed between one tier
  and the next.
- **The Outpost** — your daily briefing: today's prescribed session,
  training streak, and lifetime stats.
- **The Depot** — an equipment inventory. Toggle what you actually have
  access to (a pull-up bar, resistance bands, a bench) and the Atlas
  unlocks only the routes those unlock.
- **The Sanctuary** — recovery tracking per movement pattern. A hard set
  (RPE 8+) locks that pattern's line for 48 hours, visualized as a
  readiness bar per pattern, plus a 5-week training cycle tracker.
- **Guided sessions** — a live workout screen with per-set rep logging, a
  rest timer, and an RPE check-in after every set that tells you whether
  your next session should get harder, ease off, or hold steady.

All training data stays on your device — there's no account, no server,
no tracking.

## Running it locally

Requires the [Flutter SDK](https://docs.flutter.dev/get-started/install)
(stable channel) and two sibling repositories checked out next to this one:

```
GitHub/
├── zenith/               (this repo)
├── SBEE/                 (progression/exercise engine)
└── flutter-refined-kit/  (shared UI physics & theming kit)
```

Then, from this repo:

```bash
flutter pub get
flutter run
```

## Tech

Flutter/Dart, [Riverpod](https://riverpod.dev) for state management,
[Drift](https://drift.simonbinder.eu) (SQLite) for local persistence, and a
hand-built pixel-art design system (stepped-corner borders, hard offset
shadows, discrete segment bars, CRT scanline/grain overlay) rather than
Material defaults.
