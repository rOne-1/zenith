import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sbee/sbee.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../services/adaptation_ledger_service.dart';

/// Card widget presenting the Kenneth Miller Adaptation History Ledger, displaying
/// current 5-variable progression status, competency tiers, and autoregulation promotions.
class AdaptationLedgerCard extends ConsumerWidget {
  const AdaptationLedgerCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final ledgerAsync = ref.watch(adaptationLedgerProvider);

    return PixelCard(
      backgroundColor: colors.surfaceDark,
      borderColor: colors.borderBright,
      bevelColor: colors.borderMuted,
      padding: const EdgeInsets.all(16.0),
      child: ledgerAsync.when(
        data: (state) => _buildContent(context, state),
        loading: () => _buildLoading(colors),
        error: (error, _) => _buildError(colors, error.toString()),
      ),
    );
  }

  Widget _buildLoading(ZenithDistrictColors colors) {
    return SizedBox(
      height: 160.0,
      child: Center(
        child: Text(
          'LOADING ADAPTATION LEDGER...',
          style: TextStyle(
            fontFamily: 'Silkscreen',
            fontFamilyFallback: const ['monospace'],
            fontSize: 11.0,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: colors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildError(ZenithDistrictColors colors, String message) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Text(
        'ERROR READING ADAPTATION LEDGER: $message',
        style: TextStyle(
          fontFamily: 'Silkscreen',
          fontFamilyFallback: const ['monospace'],
          fontSize: 11.0,
          color: colors.signalRed,
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, AdaptationLedgerState state) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(
                    Icons.military_tech_outlined,
                    color: colors.amberAccent,
                    size: 18.0,
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'YOUR PROGRESS LOG',
                          style: TextStyle(
                            fontFamily: 'Silkscreen',
                            fontFamilyFallback: const ['monospace'],
                            fontSize: 12.0,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            color: colors.amberAccent,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'KENNETH MILLER ADAPTATION LEDGER',
                          style: TextStyle(
                            fontFamily: 'Silkscreen',
                            fontFamilyFallback: const ['monospace'],
                            fontSize: 8.0,
                            letterSpacing: 0.5,
                            color: colors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8.0),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 2.0,
              ),
              decoration: BoxDecoration(
                color: colors.backgroundVoid,
                border: Border.all(
                  color: colors.borderMuted,
                  width: 1.0,
                ),
              ),
              child: Text(
                'MAX TIER 0${state.highestCompetencyTier}',
                style: TextStyle(
                  fontFamily: 'Silkscreen',
                  fontFamilyFallback: const ['monospace'],
                  fontSize: 10.0,
                  fontWeight: FontWeight.w800,
                  color: colors.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12.0),

        // Recent Promotions Callout (if any exist)
        if (state.recentPromotions.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: colors.backgroundVoid,
              border: Border.all(
                color: colors.borderBright,
                width: 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '>> RECENT AUTOREGULATION PROMOTIONS',
                  style: TextStyle(
                    fontFamily: 'Silkscreen',
                    fontFamilyFallback: const ['monospace'],
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: colors.amberGlow,
                  ),
                ),
                const SizedBox(height: 6.0),
                ...state.recentPromotions.map(
                  (promo) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            promo.exerciseName.toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'Silkscreen',
                              fontFamilyFallback: const ['monospace'],
                              fontSize: 10.0,
                              fontWeight: FontWeight.w800,
                              color: colors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          promo.variableDelta,
                          style: TextStyle(
                            fontFamily: 'Silkscreen',
                            fontFamilyFallback: const ['monospace'],
                            fontSize: 9.0,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2EE6D6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14.0),
        ],

        // Active Exercise Adaptation List
        ...state.adaptations.map((item) => _buildAdaptationTile(context, item)),
      ],
    );
  }

  Widget _buildAdaptationTile(BuildContext context, MillerAdaptationItem item) {
    final colors = context.colors;
    final patternColor = _patternColor(item.pattern, colors);

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: colors.backgroundVoid,
        border: Border.all(
          color: colors.borderMuted,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Station Title & Competency Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 8.0,
                      height: 8.0,
                      decoration: BoxDecoration(
                        color: patternColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Flexible(
                      child: Text(
                        item.exerciseName.toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'Silkscreen',
                          fontFamilyFallback: const ['monospace'],
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          color: colors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8.0),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6.0,
                  vertical: 2.0,
                ),
                decoration: BoxDecoration(
                  color: patternColor.withAlpha(30),
                  border: Border.all(
                    color: patternColor,
                    width: 1.0,
                  ),
                ),
                child: Text(
                  '${item.tierLabel} // ${item.masteryTitle}',
                  style: TextStyle(
                    fontFamily: 'Silkscreen',
                    fontFamilyFallback: const ['monospace'],
                    fontSize: 9.0,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: patternColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),

          // 5-Variable Progress Meters
          Row(
            children: [
              Expanded(
                child: _buildVariableMeter(
                  label: 'LOAD',
                  level: item.variables.load,
                  maxLevel: 5,
                  colors: colors,
                ),
              ),
              const SizedBox(width: 6.0),
              Expanded(
                child: _buildVariableMeter(
                  label: 'POS',
                  level: item.variables.bodyPosition,
                  maxLevel: 5,
                  colors: colors,
                ),
              ),
              const SizedBox(width: 6.0),
              Expanded(
                child: _buildVariableMeter(
                  label: 'ROM',
                  level: item.variables.rom,
                  maxLevel: 5,
                  colors: colors,
                ),
              ),
              const SizedBox(width: 6.0),
              Expanded(
                child: _buildVariableMeter(
                  label: 'ELEV',
                  level: item.variables.height,
                  maxLevel: 5,
                  colors: colors,
                ),
              ),
              const SizedBox(width: 6.0),
              Expanded(
                child: _buildTempoMeter(
                  tempoLevel: item.variables.tempo,
                  colors: colors,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVariableMeter({
    required String label,
    required int level,
    required int maxLevel,
    required ZenithDistrictColors colors,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        border: Border.all(
          color: colors.borderMuted,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '$label L$level',
            style: TextStyle(
              fontFamily: 'Silkscreen',
              fontFamilyFallback: const ['monospace'],
              fontSize: 8.0,
              fontWeight: FontWeight.w700,
              color: level > 1 ? colors.amberAccent : colors.textMuted,
            ),
          ),
          const SizedBox(height: 2.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(maxLevel, (i) {
              final isFilled = i < level;
              return Container(
                width: 3.5,
                height: 5.0,
                margin: const EdgeInsets.symmetric(horizontal: 0.5),
                color: isFilled
                    ? (level > 1 ? colors.amberAccent : colors.textPrimary)
                    : colors.borderMuted,
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTempoMeter({
    required int tempoLevel,
    required ZenithDistrictColors colors,
  }) {
    final isSlow = tempoLevel == 2;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        border: Border.all(
          color: colors.borderMuted,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'TEMPO',
            style: TextStyle(
              fontFamily: 'Silkscreen',
              fontFamilyFallback: const ['monospace'],
              fontSize: 8.0,
              fontWeight: FontWeight.w700,
              color: isSlow ? const Color(0xFF2EE6D6) : colors.textMuted,
            ),
          ),
          const SizedBox(height: 2.0),
          Text(
            isSlow ? '6s SLOW' : '4s STD',
            style: TextStyle(
              fontFamily: 'Silkscreen',
              fontFamilyFallback: const ['monospace'],
              fontSize: 7.0,
              fontWeight: FontWeight.w800,
              color: isSlow ? const Color(0xFF2EE6D6) : colors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Color _patternColor(MovementPattern pattern, ZenithDistrictColors colors) {
    switch (pattern) {
      case MovementPattern.pushing:
        return const Color(0xFFFF9500); // Ginza Orange
      case MovementPattern.pulling:
        return const Color(0xFF00BB85); // Chiyoda Green
      case MovementPattern.bendAndLift:
        return const Color(0xFFE60012); // Marunouchi Red
      case MovementPattern.singleLeg:
        return const Color(0xFF9B51E0); // Hanzomon Purple
      case MovementPattern.rotation:
        return const Color(0xFF00A7E1); // Tozai Blue
    }
  }
}
