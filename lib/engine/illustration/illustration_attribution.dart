/// Attribution data for the exercise illustrations vendored from
/// bryllim/workout-guide (CC BY-SA 4.0) -- backs the in-app credits section
/// on the Depot screen. See `assets/exercises/ATTRIBUTION.md` for the full
/// per-exercise writeup this is kept in sync with (verified by
/// `test/engine/illustration/illustration_attribution_test.dart`), and
/// `local-notes/architecture/exercise_illustration_rig.md` §2.1 for why the
/// license applies to the art but not Zenith's own app code.
///
/// The exercise *names* shown in the credits UI are read live from
/// [Exercise.name] via [isSvgSourcedExercise] rather than duplicated here --
/// only data that doesn't already exist elsewhere in the app lives in this
/// file.
library;

const String kIllustrationCreatorName = 'Bryl Lim';
const String kIllustrationCreatorUrl = 'https://bryllim.com';
const String kIllustrationSourceRepoUrl =
    'https://github.com/bryllim/workout-guide';
const String kIllustrationLicenseName = 'CC BY-SA 4.0';
const String kIllustrationLicenseUrl =
    'https://creativecommons.org/licenses/by-sa/4.0/';

/// Exercise ids whose sourced frames are themselves adapted from
/// [Everkinetic](https://github.com/everkinetic/data) artwork (also
/// CC BY-SA 4.0), mapped to the specific upstream SVG. A subset of the
/// SVG-sourced set (see [isSvgSourcedExercise] in `exercise_illustration.dart`).
const Map<String, String> kEverkineticSources = {
  'good_morning':
      'https://github.com/everkinetic/data/blob/main/dist/svg/0101-tension.svg',
  'inverted_row':
      'https://github.com/everkinetic/data/blob/main/dist/svg/0086-tension.svg',
  'reverse_lunge':
      'https://github.com/everkinetic/data/blob/main/dist/svg/0129-tension.svg',
  'side_plank':
      'https://github.com/everkinetic/data/blob/main/dist/svg/0113-tension.svg',
  'standard_pullup':
      'https://github.com/everkinetic/data/blob/main/dist/svg/0087-tension.svg',
  'standard_pushup':
      'https://github.com/everkinetic/data/blob/main/dist/svg/0077-tension.svg',
};
