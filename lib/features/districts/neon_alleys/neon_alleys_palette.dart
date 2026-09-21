import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import 'neon_alleys_atmosphere_backdrop.dart';

/// Canonical palette definition for District 02: "Neon Alleys".
///
/// First cut: reuses District 01's exact color tokens -- only the backdrop
/// changes (a looping video instead of the procedural rail scene). The
/// dedicated Neon Alleys color story (fuchsia accent, indigo-navy
/// structure) is drafted in
/// `local-notes/visual_identity/visual_identity_anchor.md` §4 but not
/// wired in yet.
const neonAlleysPalette = ZenithDistrictPalette(
  id: 'neon_alleys',
  nameEn: 'Neon Alleys',
  description:
      'A rain-slicked back-alley stairwell, stacked neon signage glowing through the mist.',
  backgroundVoid: Color(0xFF070E10),
  surfaceDark: Color(0xFF0C181A),
  surfaceElevated: Color(0xFF152B2C),
  surfaceHighlight: Color(0xFF1F3E3D),
  borderMuted: Color(0xFF1A3332),
  borderBright: Color(0xFF2D5552),
  amberAccent: Color(0xFFFFAE34),
  amberGlow: Color(0xFFFFD269),
  signalRed: Color(0xFFFF493A),
  foliageVibrant: Color(0xFF4B8E62),
  textPrimary: Color(0xFFE8F5F2),
  textMuted: Color(0xFF7D9B98),
  atmosphericMotif: _buildNeonAlleysBackdrop,
);

Widget _buildNeonAlleysBackdrop(BuildContext context) {
  return const NeonAlleysAtmosphereBackdrop();
}
