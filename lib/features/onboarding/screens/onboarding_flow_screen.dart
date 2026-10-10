import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app_shell.dart';
import '../../../core/storage/storage.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../armory/armory.dart';
import '../providers/onboarding_provider.dart';

/// First-launch setup: equipment, physical accommodations, and self-declared
/// experience level, each feeding the exact same [userProfileProvider] the
/// Depot screen edits later -- onboarding is just a guided first pass over
/// the same settings, not a separate data path. Every data-collecting step
/// is individually skippable (today's silent defaults apply to whatever's
/// skipped); only the welcome step has no data to skip.
class OnboardingFlowScreen extends ConsumerStatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  ConsumerState<OnboardingFlowScreen> createState() =>
      _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends ConsumerState<OnboardingFlowScreen> {
  static const int _stepCount = 4;
  int _step = 0;

  void _goTo(int step) {
    setState(() => _step = step.clamp(0, _stepCount - 1));
  }

  Future<void> _finish() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(kHasCompletedOnboardingKey, true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ZenithAppShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final Widget stepContent = switch (_step) {
      0 => _WelcomeStep(onNext: () => _goTo(1)),
      1 => _EquipmentStep(onNext: () => _goTo(2), onSkip: () => _goTo(2)),
      2 => _PhysiologyStep(onNext: () => _goTo(3), onSkip: () => _goTo(3)),
      _ => _ExperienceStep(onFinish: _finish, onSkip: _finish),
    };

    return Scaffold(
      backgroundColor: colors.backgroundVoid,
      body: DistrictAtmosphereBackdrop(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_step > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20.0, 14.0, 20.0, 0.0),
                  child: Row(
                    children: [
                      Text(
                        'SETUP ${_step + 1}/$_stepCount',
                        style: zenithPixelDisplay(
                          fontSize: 10.0,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(child: stepContent),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared step chrome: title, subtitle, scrollable body, and a bottom
/// button row -- every step after the welcome one is built from this.
class _StepScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget body;
  final Widget footer;

  const _StepScaffold({
    required this.title,
    required this.subtitle,
    required this.body,
    required this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 0.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: zenithPixelDisplay(
                  fontSize: 20.0,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: colors.amberAccent,
                ),
              ),
              const SizedBox(height: 6.0),
              Text(
                subtitle,
                style: zenithBodyMono(
                  fontSize: 13.0,
                  height: 1.4,
                  color: colors.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16.0),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: body,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
          decoration: BoxDecoration(
            color: colors.surfaceDark,
            border: Border(
              top: BorderSide(color: colors.borderMuted, width: 2.0),
            ),
          ),
          child: footer,
        ),
      ],
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  final VoidCallback onNext;

  const _WelcomeStep({required this.onNext});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'WELCOME TO ZENITH',
              style: zenithPixelDisplay(
                fontSize: 26.0,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: colors.amberAccent,
              ),
            ),
            const SizedBox(height: 16.0),
            Text(
              'A few quick questions about your gear, your body, and your '
              'experience -- so your very first session is built for you, '
              'not for everyone. Every question is optional and can be '
              'changed later in the Depot.',
              style: zenithBodyMono(
                fontSize: 14.0,
                height: 1.5,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 32.0),
            PixelButton(label: 'GET STARTED', onPressed: onNext),
          ],
        ),
      ),
    );
  }
}

class _EquipmentStep extends ConsumerWidget {
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _EquipmentStep({required this.onNext, required this.onSkip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider);
    final notifier = ref.read(userProfileProvider.notifier);

    return _StepScaffold(
      title: 'WHAT GEAR DO YOU HAVE?',
      subtitle:
          'Select everything you have access to. You can change this '
          'anytime in the Depot.',
      body: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 20.0),
        itemCount: kArmoryEquipmentGrid.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12.0,
          mainAxisSpacing: 12.0,
          mainAxisExtent: 140.0,
        ),
        itemBuilder: (context, index) {
          final equipment = kArmoryEquipmentGrid[index];
          final isEquipped = userProfile.availableEquipment.contains(equipment);
          return GearTile(
            equipment: equipment,
            isEquipped: isEquipped,
            onToggle: () => notifier.toggleEquipment(equipment),
          );
        },
      ),
      footer: Row(
        children: [
          Expanded(
            child: PixelButton(
              label: 'SKIP',
              variant: PixelButtonVariant.secondary,
              onPressed: onSkip,
            ),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            flex: 2,
            child: PixelButton(label: 'NEXT', onPressed: onNext),
          ),
        ],
      ),
    );
  }
}

class _PhysiologyStep extends ConsumerWidget {
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _PhysiologyStep({required this.onNext, required this.onSkip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final userProfile = ref.watch(userProfileProvider);
    final notifier = ref.read(userProfileProvider.notifier);

    return _StepScaffold(
      title: 'ANY PHYSICAL CONSIDERATIONS?',
      subtitle:
          'This only changes which exercises show up -- you can change it '
          'later in the Depot.',
      body: PixelCard(
        backgroundColor: colors.surfaceDark,
        borderColor: userProfile.hasJointPain
            ? colors.amberAccent
            : colors.borderMuted,
        bevelColor: colors.borderMuted,
        onTap: () {
          HapticFeedback.selectionClick();
          notifier.toggleJointProtection();
        },
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'JOINT PROTECTION',
                    style: zenithPixelDisplay(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w900,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    'Skips jumping and other hard-impact moves.',
                    style: zenithBodyMono(
                      fontSize: 11.0,
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              userProfile.hasJointPain ? 'ON  ●' : 'OFF ○',
              style: zenithPixelDisplay(
                fontSize: 11.0,
                fontWeight: FontWeight.w700,
                color: userProfile.hasJointPain
                    ? colors.amberAccent
                    : colors.textMuted,
              ),
            ),
          ],
        ),
      ),
      footer: Row(
        children: [
          Expanded(
            child: PixelButton(
              label: 'SKIP',
              variant: PixelButtonVariant.secondary,
              onPressed: onSkip,
            ),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            flex: 2,
            child: PixelButton(label: 'NEXT', onPressed: onNext),
          ),
        ],
      ),
    );
  }
}

class _ExperienceStep extends ConsumerStatefulWidget {
  final Future<void> Function() onFinish;
  final Future<void> Function() onSkip;

  const _ExperienceStep({required this.onFinish, required this.onSkip});

  @override
  ConsumerState<_ExperienceStep> createState() => _ExperienceStepState();
}

class _ExperienceStepState extends ConsumerState<_ExperienceStep> {
  ExperienceLevel? _selected;

  static const _options = [
    (
      level: ExperienceLevel.beginner,
      label: 'NEW TO TRAINING',
      description: 'Never trained before, or it has been a very long time.',
    ),
    (
      level: ExperienceLevel.intermediate,
      label: 'SOME EXPERIENCE',
      description: 'You have trained before and know the basic movements.',
    ),
    (
      level: ExperienceLevel.advanced,
      label: 'EXPERIENCED',
      description: 'You train regularly and know your limits well.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return _StepScaffold(
      title: 'HOW EXPERIENCED ARE YOU?',
      subtitle:
          'This sets how demanding your first sessions are. It adjusts '
          'automatically after that, so you can\'t get this wrong.',
      body: Column(
        children: [
          for (final option in _options) ...[
            PixelCard(
              backgroundColor: colors.surfaceDark,
              borderColor: _selected == option.level
                  ? colors.amberAccent
                  : colors.borderMuted,
              bevelColor: colors.borderMuted,
              padding: const EdgeInsets.all(16.0),
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selected = option.level);
              },
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option.label,
                          style: zenithPixelDisplay(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w900,
                            color: _selected == option.level
                                ? colors.amberAccent
                                : colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          option.description,
                          style: zenithBodyMono(
                            fontSize: 11.0,
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_selected == option.level)
                    Text(
                      '●',
                      style: zenithPixelDisplay(
                        fontSize: 16.0,
                        color: colors.amberAccent,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12.0),
          ],
        ],
      ),
      footer: Row(
        children: [
          Expanded(
            child: PixelButton(
              label: 'SKIP',
              variant: PixelButtonVariant.secondary,
              onPressed: () => widget.onSkip(),
            ),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            flex: 2,
            child: PixelButton(
              label: 'FINISH',
              onPressed: _selected == null
                  ? null
                  : () async {
                      await ref
                          .read(userProfileProvider.notifier)
                          .setExperienceLevel(_selected!);
                      await widget.onFinish();
                    },
            ),
          ),
        ],
      ),
    );
  }
}
