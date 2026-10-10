import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import 'neon_alleys_atmosphere_backdrop.dart';

/// Canonical palette definition for District 02: "Neon Alleys".
///
/// Ground truth defined in `local-notes/visual_identity/visual_identity_anchor.md` §4:
/// Deep indigo surfaces, bright fuchsia primary accent, and stairwell fern secondary accent.
const neonAlleysPalette = ZenithDistrictPalette(
  id: 'neon_alleys',
  nameEn: 'Neon Alleys',
  description:
      'A rain-slicked back-alley stairwell, stacked neon signage glowing through the mist.',
  backgroundVoid: Color(0xFF060814),
  surfaceDark: Color(0xFF0D1424),
  surfaceElevated: Color(0xFF182140),
  surfaceHighlight: Color(0xFF232C52),
  borderMuted: Color(0xFF1E2A4A),
  borderBright: Color(0xFF3C4E88),
  amberAccent: Color(0xFFFF2FA0),
  amberGlow: Color(0xFFFF8EC9),
  accentSecondary: Color(0xFF39C08A),
  signalRed: Color(0xFFFF493A),
  foliageVibrant: Color(0xFF4B8E62),
  textPrimary: Color(0xFFE8F5F2),
  textMuted: Color(0xFF7D9B98),
  atmosphericMotif: _buildNeonAlleysBackdrop,
);

Widget _buildNeonAlleysBackdrop(BuildContext context) {
  return const NeonAlleysAtmosphereBackdrop();
}
