import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sbee/sbee.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../districts/railside_outskirts/railside_atmosphere_backdrop.dart';
import '../controllers/active_session_controller.dart';
import 'expedition_debrief_screen.dart';
import 'rest_screen.dart';
import 'working_set_screen.dart';

/// Screen host managing the active expedition workout flow.
///
/// Switches dynamically based on SBEE FSM lifecycle:
/// `warmUp` ➔ `activeSet` ➔ `rest` ➔ `coolDown` ➔ `completed`.
class ActiveExpeditionScreen extends ConsumerWidget {
  const ActiveExpeditionScreen({super.key});

  Future<void> _handleAbort(BuildContext context, WidgetRef ref) async {
    final colors = context.colors;
    final confirm = await ZenithDialog.show<bool>(
      context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: PixelCard(
          backgroundColor: colors.surfaceDark,
          borderColor: colors.signalRed,
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ABORT EXPEDITION',
                style: TextStyle(
                  fontFamily: 'Silkscreen',
                  fontFamilyFallback: const ['monospace'],
                  fontSize: 14.0,
                  fontWeight: FontWeight.w900,
                  color: colors.signalRed,
                ),
              ),
              const SizedBox(height: 12.0),
              Text(
                'Are you sure you want to abort? All in-progress sets will be discarded from persistence.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Silkscreen',
                  fontFamilyFallback: const ['monospace'],
                  fontSize: 12.0,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 20.0),
              Row(
                children: [
                  Expanded(
                    child: PixelButton(
                      label: 'CONTINUE',
                      variant: PixelButtonVariant.secondary,
                      onPressed: () => Navigator.of(ctx).pop(false),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: PixelButton(
                      label: 'ABORT',
                      variant: PixelButtonVariant.danger,
                      onPressed: () => Navigator.of(ctx).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true && context.mounted) {
      await ref.read(activeSessionControllerProvider.notifier).abortSession();
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final state = ref.watch(activeSessionControllerProvider);
    final controller = ref.read(activeSessionControllerProvider.notifier);

    // If session completed, render debrief
    if (state.fsmState == SessionState.completed) {
      return const ExpeditionDebriefScreen();
    }

    // Active workout screens
    final Widget currentPhaseWidget = switch (state.fsmState) {
      SessionState.warmUp => _WarmUpView(
        onStart: () => controller.completeWarmUp(),
      ),
      SessionState.activeSet => const WorkingSetScreen(),
      SessionState.rest => const RestScreen(),
      SessionState.coolDown => _CoolDownView(
        isFinalizing: state.isFinalizing,
        onFinish: () => controller.completeCoolDown(),
      ),
      SessionState.completed => const ExpeditionDebriefScreen(),
    };

    return Scaffold(
      backgroundColor: colors.backgroundVoid,
      body: SafeArea(
        child: Column(
          children: [
            // Station Sign Header — matches the bespoke header pattern used
            // by every other screen (Portal/Working Set/Rest), rather than
            // a stock Material AppBar.
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 10.0,
              ),
              decoration: BoxDecoration(
                color: colors.surfaceDark,
                border: Border(
                  bottom: BorderSide(color: colors.borderBright, width: 2.0),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'ACTIVE EXPEDITION',
                      style: TextStyle(
                        fontFamily: 'Silkscreen',
                        fontFamilyFallback: const ['monospace'],
                        fontSize: 12.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: colors.amberAccent,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  PixelButton(
                    variant: PixelButtonVariant.secondary,
                    padding: const EdgeInsets.all(8.0),
                    onPressed: () => _handleAbort(context, ref),
                    child: Icon(
                      Icons.close,
                      color: colors.signalRed,
                      size: 18.0,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: currentPhaseWidget),
          ],
        ),
      ),
    );
  }
}

class _WarmUpView extends StatelessWidget {
  final VoidCallback onStart;

  const _WarmUpView({required this.onStart});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return RailsideAtmosphereBackdrop(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'WARM-UP MOBILIZATION',
                style: TextStyle(
                  fontFamily: 'Silkscreen',
                  fontFamilyFallback: const ['monospace'],
                  fontSize: 20.0,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: colors.amberAccent,
                ),
              ),
              const SizedBox(height: 6.0),
              Text(
                'DYNAMIC RANGE OF MOTION & TISSUE PREPARATION',
                style: TextStyle(
                  fontFamily: 'Silkscreen',
                  fontFamilyFallback: const ['monospace'],
                  fontSize: 11.0,
                  color: colors.textMuted,
                ),
              ),
              const SizedBox(height: 24.0),

              Expanded(
                child: PixelCard(
                  backgroundColor: colors.surfaceDark,
                  borderColor: colors.borderBright,
                  padding: const EdgeInsets.all(20.0),
                  child: ListView(
                    children: [
                      Text(
                        'PRE-EXPEDITION CHECKLIST:',
                        style: TextStyle(
                          fontFamily: 'Silkscreen',
                          fontFamilyFallback: const ['monospace'],
                          fontSize: 12.0,
                          fontWeight: FontWeight.w700,
                          color: colors.amberGlow,
                        ),
                      ),
                      const SizedBox(height: 14.0),
                      _checklistRow(
                        colors,
                        '2-3 min dynamic joint rotations (wrists, shoulders, hips)',
                      ),
                      _checklistRow(
                        colors,
                        '10 bodyweight hinges or cat-cow spinal unloads',
                      ),
                      _checklistRow(
                        colors,
                        'Core bracing test: draw in transverse abdominis',
                      ),
                      _checklistRow(
                        colors,
                        'Gear check: clear perimeter and secure floor anchor',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20.0),

              PixelButton(
                label: '▶ COMMENCE WORKING SETS',
                variant: PixelButtonVariant.primary,
                height: 52.0,
                onPressed: onStart,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _checklistRow(ZenithDistrictColors colors, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '✓ ',
            style: TextStyle(
              color: const Color(0xFF2EE6D6),
              fontWeight: FontWeight.w900,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Inter',
                fontFamilyFallback: const ['sans-serif'],
                fontSize: 12.0,
                height: 1.4,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoolDownView extends StatelessWidget {
  final bool isFinalizing;
  final VoidCallback onFinish;

  const _CoolDownView({required this.isFinalizing, required this.onFinish});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return RailsideAtmosphereBackdrop(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'COOL-DOWN DOWNSHIFT',
                style: TextStyle(
                  fontFamily: 'Silkscreen',
                  fontFamilyFallback: const ['monospace'],
                  fontSize: 20.0,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: colors.amberAccent,
                ),
              ),
              const SizedBox(height: 6.0),
              Text(
                'PARASYMPATHETIC RECOVERY & DIAPHRAGMATIC PACING',
                style: TextStyle(
                  fontFamily: 'Silkscreen',
                  fontFamilyFallback: const ['monospace'],
                  fontSize: 11.0,
                  color: colors.textMuted,
                ),
              ),
              const SizedBox(height: 24.0),

              Expanded(
                child: PixelCard(
                  backgroundColor: colors.surfaceDark,
                  borderColor: colors.borderBright,
                  padding: const EdgeInsets.all(20.0),
                  child: ListView(
                    children: [
                      Text(
                        'RESTORATIVE PROTOCOL:',
                        style: TextStyle(
                          fontFamily: 'Silkscreen',
                          fontFamilyFallback: const ['monospace'],
                          fontSize: 12.0,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2EE6D6),
                        ),
                      ),
                      const SizedBox(height: 14.0),
                      Text(
                        '1. 4-second box breathing to downregulate sympathetic tone.\n'
                        '2. Child’s pose or passive spinal decompression for 60s.\n'
                        '3. Hydrate with electrolyte-balanced water.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontFamilyFallback: const ['sans-serif'],
                          fontSize: 13.0,
                          height: 1.6,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20.0),

              PixelButton(
                label: isFinalizing
                    ? 'COMPILING DEBRIEF LEDGER...'
                    : 'CONCLUDE & VIEW DEBRIEF ➔',
                enabled: !isFinalizing,
                variant: PixelButtonVariant.primary,
                height: 52.0,
                onPressed: onFinish,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
