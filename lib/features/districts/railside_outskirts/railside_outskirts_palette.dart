import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';
import 'railside_atmosphere_backdrop.dart';

/// Canonical palette definition for District 01: "Railside Outskirts" (郊外の線路).
///
/// Ground truth defined in `local-notes/visual_identity/visual_identity_anchor.md`.
const railsideOutskirtsPalette = ZenithDistrictPalette(
  id: 'railside_outskirts',
  nameEn: 'Railside Outskirts',
  nameJp: '郊外の線路',
  description:
      'Suburban train tracks at night, flickering streetlights, and windblown weeds.',
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
  atmosphericMotif: _buildRailsideBackdrop,
);

Widget _buildRailsideBackdrop(BuildContext context) {
  return const RailsideAtmosphereBackdrop();
}
