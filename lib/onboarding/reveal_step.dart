import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/core/life_calculator.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/onboarding/personal_address.dart';
import 'package:memento_mori_life_in_weeks/onboarding/reveal_controls.dart';
import 'package:memento_mori_life_in_weeks/onboarding/reveal_grid.dart';
import 'package:memento_mori_life_in_weeks/onboarding/step_layout.dart';
import 'package:memento_mori_life_in_weeks/theme/motion.dart';

/// Step 2: the weeks grid fills up to today, the current week starts to
/// breathe and the week number fades in, with life expectancy and
/// language below.
class RevealStep extends StatefulWidget {
  const RevealStep({
    super.key,
    required this.calculator,
    required this.alreadyRevealed,
    required this.onRevealed,
    required this.language,
    required this.onLanguageChanged,
    required this.onLifeExpectancyChanged,
    required this.onContinue,
    this.address = PersonalAddress.none,
  });

  final LifeCalculator calculator;

  /// Greets the user by name in the tagline when one was given.
  final PersonalAddress address;

  /// Skips the animation when coming back to this step.
  final bool alreadyRevealed;
  final VoidCallback onRevealed;
  final String language;
  final ValueChanged<String> onLanguageChanged;
  final ValueChanged<int> onLifeExpectancyChanged;
  final VoidCallback onContinue;

  /// Pause while the step fades in, before the grid starts filling.
  static const Duration leadIn = Motion.medium;

  @override
  State<RevealStep> createState() => _RevealStepState();
}

class _RevealStepState extends State<RevealStep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: RevealStep.leadIn + Motion.reveal,
  );
  late final CurvedAnimation _fill = CurvedAnimation(
    parent: _controller,
    curve: Interval(_leadInFraction, 1, curve: Motion.standard),
  );
  bool _started = false;
  bool _landed = false;

  static double get _leadInFraction =>
      RevealStep.leadIn.inMilliseconds /
      (RevealStep.leadIn + Motion.reveal).inMilliseconds;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (widget.alreadyRevealed || !Motion.enabled(context)) {
      _controller.value = 1;
      _landed = true;
      if (!widget.alreadyRevealed) widget.onRevealed();
    } else {
      _controller.forward().whenComplete(_land);
    }
  }

  void _land() {
    if (!mounted) return;
    Haptics.light();
    setState(() => _landed = true);
    widget.onRevealed();
  }

  @override
  void dispose() {
    _fill.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final calc = widget.calculator;
    final lived = calc.weeksLived.clamp(0, calc.totalWeeks);
    final fadeIn = Motion.of(context, Motion.long);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 20, 0),
            child: RevealGrid(
              progress: _fill,
              totalCells: calc.totalWeeks,
              livedCells: lived,
              landed: _landed,
              semanticsLabel: _semanticsLabel(context, lived, calc.totalWeeks),
            ),
          ),
        ),
        AnimatedOpacity(
          opacity: _landed ? 1 : 0,
          duration: fadeIn,
          curve: Motion.standard,
          child: IgnorePointer(
            ignoring: !_landed,
            child: _details(context, calc),
          ),
        ),
      ],
    );
  }

  Widget _details(BuildContext context, LifeCalculator calc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: StepLayout.padding.copyWith(top: 20),
          child: _WeekStatement(
            weekNumber: calc.currentWeekNumber,
            address: widget.address,
          ),
        ),
        Padding(
          padding: StepLayout.padding.copyWith(top: 12, bottom: 12),
          child: RevealControls(
            lifeExpectancyYears: calc.lifeExpectancyYears,
            onLifeExpectancyChanged: widget.onLifeExpectancyChanged,
            language: widget.language,
            onLanguageChanged: widget.onLanguageChanged,
          ),
        ),
        StepActions(
          action: FilledButton(
            onPressed: widget.onContinue,
            child: Text(
              AppLocalizations.of(context).translate('onboarding_continue'),
            ),
          ),
        ),
      ],
    );
  }

  String _semanticsLabel(BuildContext context, int lived, int total) {
    final l10n = AppLocalizations.of(context);
    final numbers = l10n.numberFormat;
    return l10n.translate(
      'onboarding_reveal_semantics',
      replacements: {
        'lived': numbers.format(lived),
        'total': numbers.format(total),
      },
    );
  }
}

/// "This is week 1,923 of your life." in serif, "Make it count." (with
/// the name when given) quietly beneath.
class _WeekStatement extends StatelessWidget {
  const _WeekStatement({required this.weekNumber, required this.address});

  final int weekNumber;
  final PersonalAddress address;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final numbers = l10n.numberFormat;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate(
            'onboarding_reveal_week',
            replacements: {'n': numbers.format(weekNumber)},
          ),
          style: theme.textTheme.headlineMedium?.copyWith(
            fontFeatures: const [FontFeature.liningFigures()],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          address.translate(l10n, 'onboarding_reveal_tagline'),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
