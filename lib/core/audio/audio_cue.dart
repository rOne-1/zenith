/// The canonical 16-bit arcade audio cues for live workout sessions.
enum AudioCue {
  /// Subtle retro blip / woodblock click for 3..2..1 rest countdown ticks.
  tick('audio/tick.wav'),

  /// Energetic neo-pixel arcade chirp for set commencement ("GO").
  start('audio/start.wav'),

  /// Descending harmonic chime signaling the start of a rest interval.
  rest('audio/rest.wav'),

  /// Triumphant 16-bit arpeggiated fanfare for expedition debrief completion.
  complete('audio/complete.wav');

  final String assetPath;
  const AudioCue(this.assetPath);
}
