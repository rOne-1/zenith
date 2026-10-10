import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sbee/sbee.dart';

import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../controllers/active_session_controller.dart';
import '../widgets/rpe_selector_card.dart';
import 'expedition_debrief_screen.dart';
import 'rest_screen.dart';
import 'working_set_screen.dart';

/// Screen host managing the active expedition workout flow.
///
/// Switches dynamically based on SBEE FSM lifecycle:
/// `warmUp` ➔ `activeSet` ➔ `rest` ➔ `coolDown` ➔ `completed`.
class ActiveExpeditionScreen extends ConsumerStatefulWidget {
  const ActiveExpeditionScreen({super.key});

  @override
  ConsumerState<ActiveExpeditionScreen> createState() =>
      _ActiveExpeditionScreenState();
}

class _ActiveExpeditionScreenState
    extends ConsumerState<ActiveExpeditionScreen> {
  // An instance-scoped GlobalKey rather than a static one to prevent
  // duplicate GlobalKey collisions across route transitions: the host is
  // added as a *descendant* of this widget's own build() (wrapping the
  // Scaffold body below), so the outer `context` this build() receives is
  // never a descendant of it and .of(context) would always return null here.
  final _toastHostKey = GlobalKey<PixelToastHostState>();

  Future<void> _handleAbort() async {
    final colors = context.colors;
    final confirm = await ZenithDialog.showCard<bool>(
      context,
      borderColor: colors.signalRed,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'ABORT EXPEDITION',
            style: zenithPixelDisplay(
              fontSize: 14.0,
              fontWeight: FontWeight.w900,
              color: colors.signalRed,
            ),
          ),
          const SizedBox(height: 12.0),
          Text(
            'Are you sure you want to abort? All in-progress sets will be discarded from persistence.',
            textAlign: TextAlign.center,
            style: zenithBodyMono(
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
    );

    if (confirm == true && mounted) {
      final navigator = Navigator.of(context);
      final controller = ref.read(activeSessionControllerProvider.notifier);
      if (navigator.canPop()) {
        navigator.pop();
      }
      await controller.abortSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // finalizeSession() records failures on errorMessage but nothing was
    // ever reading it -- a failed finalize silently re-enabled the
    // CONCLUDE button with zero indication the workout wasn't actually
    // saved. Surface it as a toast the moment it appears.
    ref.listen(activeSessionControllerProvider, (previous, next) {
      final message = next.errorMessage;
      if (message != null && message != previous?.errorMessage) {
        _toastHostKey.currentState?.show(message);
      }
    });

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
        // The FSM reaches coolDown only by completing the session's last
        // set, which -- unlike every other set -- has no Rest screen after
        // it to show the Borg RPE selector during (SBEE's own FSM goes
        // straight activeSet -> coolDown on the final set). Without this,
        // the last set's reportedRpe would stay whatever placeholder value
        // was guessed at completion time, and autoregulation could never
        // progress/regress off it.
        targetRpe: state.currentSet?.targetRpe ?? 8,
        selectedRpe: state.selectedRpe ?? state.currentSet?.targetRpe ?? 8,
        onLogRpe: controller.logRpe,
        onFinish: () => controller.completeCoolDown(),
      ),
      SessionState.completed => const ExpeditionDebriefScreen(),
    };

    return Scaffold(
      backgroundColor: colors.backgroundVoid,
      body: PixelToastHost(
        key: _toastHostKey,
        child: SafeArea(
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
                        style: zenithPixelDisplay(
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
                      semanticLabel: 'Abort expedition',
                      onPressed: _handleAbort,
                      child: Text(
                        '✕',
                        style: zenithPixelDisplay(
                          fontSize: 16.0,
                          color: colors.signalRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: currentPhaseWidget),
            ],
          ),
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

    return DistrictAtmosphereBackdrop(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'WARM-UP MOBILIZATION',
                style: zenithPixelDisplay(
                  fontSize: 20.0,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: colors.amberAccent,
                ),
              ),
              const SizedBox(height: 6.0),
              Text(
                'DYNAMIC RANGE OF MOTION & TISSUE PREPARATION',
                style: zenithPixelDisplay(
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
                        style: zenithPixelDisplay(
                          fontSize: 12.0,
                          fontWeight: FontWeight.w700,
                          color: colors.amberGlow,
                        ),
                      ),
                      const SizedBox(height: 14.0),
                      _checklistRow(
                        colors,
                        '2-3 minutes of easy arm, shoulder, and hip circles',
                      ),
                      _checklistRow(
                        colors,
                        '10 slow hip hinges or gentle back stretches',
                      ),
                      _checklistRow(
                        colors,
                        'Tighten your stomach like you\'re about to be poked',
                      ),
                      _checklistRow(
                        colors,
                        'Clear the space around you and check your gear is secure',
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
            style: zenithBodyMono(
              fontSize: 12.0,
              color: colors.accentSecondary,
              fontWeight: FontWeight.w900,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: zenithBodyMono(
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
  final int targetRpe;
  final int selectedRpe;
  final ValueChanged<int> onLogRpe;
  final VoidCallback onFinish;

  const _CoolDownView({
    required this.isFinalizing,
    required this.targetRpe,
    required this.selectedRpe,
    required this.onLogRpe,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return DistrictAtmosphereBackdrop(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'COOL-DOWN DOWNSHIFT',
                style: zenithPixelDisplay(
                  fontSize: 20.0,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: colors.amberAccent,
                ),
              ),
              const SizedBox(height: 6.0),
              Text(
                'PARASYMPATHETIC RECOVERY & DIAPHRAGMATIC PACING',
                style: zenithPixelDisplay(
                  fontSize: 11.0,
                  color: colors.textMuted,
                ),
              ),
              const SizedBox(height: 24.0),

              Expanded(
                child: ListView(
                  children: [
                    RpeSelectorCard(
                      targetRpe: targetRpe,
                      selectedRpe: selectedRpe,
                      onSelect: onLogRpe,
                    ),
                    const SizedBox(height: 18.0),
                    PixelCard(
                      backgroundColor: colors.surfaceDark,
                      borderColor: colors.borderBright,
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RESTORATIVE PROTOCOL:',
                            style: zenithPixelDisplay(
                              fontSize: 12.0,
                              fontWeight: FontWeight.w700,
                              color: colors.accentSecondary,
                            ),
                          ),
                          const SizedBox(height: 14.0),
                          Text(
                            '1. 4-second box breathing to downregulate sympathetic tone.\n'
                            '2. Child’s pose or passive spinal decompression for 60s.\n'
                            '3. Hydrate with electrolyte-balanced water.',
                            style: zenithBodyMono(
                              fontSize: 13.0,
                              height: 1.6,
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
