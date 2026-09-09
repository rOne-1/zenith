import 'package:sbee/sbee.dart';

/// Shared formatting for presenting a [DayType] as compact, user-facing
/// copy -- used by both the Expedition Portal's full itinerary and the
/// Outpost dashboard's condensed summary, so the two screens never describe
/// the same session differently (EP-3: fix the description once).

/// The plain-language day-type name (e.g. "MODERATE DAY").
String formatDayTypeHeader(DayType? dayType) {
  switch (dayType) {
    case DayType.veryHeavy:
      return 'HEAVY DAY';
    case DayType.moderate:
      return 'MODERATE DAY';
    case DayType.power:
      return 'POWER DAY';
    case DayType.veryLight:
      return 'LIGHT DAY';
    case DayType.highLactic:
      return 'METABOLIC DAY';
    case null:
      return 'CUSTOM EXPEDITION';
  }
}

/// The science-term subtitle for a day type (e.g. "MUSCLE-BUILDING (HYPERTROPHY)").
String formatDayTypeSubtitle(DayType? dayType) {
  switch (dayType) {
    case DayType.veryHeavy:
      return 'NEUROMUSCULAR STRENGTH';
    case DayType.moderate:
      return 'MUSCLE-BUILDING (HYPERTROPHY)';
    case DayType.power:
      return 'EXPLOSIVE SPEED';
    case DayType.veryLight:
      return 'MUSCULAR ENDURANCE';
    case DayType.highLactic:
      return 'EMOM CONDITIONING';
    case null:
      return 'CUSTOM PRESCRIPTION';
  }
}

/// The rep-max zone badge text for a day type (e.g. "8-12 RM").
String formatRmZone(DayType? dayType) {
  switch (dayType) {
    case DayType.veryHeavy:
      return '1-5 RM';
    case DayType.moderate:
      return '8-12 RM';
    case DayType.power:
      return '3-5 RM';
    case DayType.veryLight:
      return '15-20 RM';
    case DayType.highLactic:
      return 'EMOM';
    case null:
      return 'VARIABLE';
  }
}

/// Number of distinct exercises in [session] (sets grouped by exercise ID).
int exerciseCountFor(WorkoutSession session) {
  return session.sets.map((s) => s.exerciseId).toSet().length;
}
