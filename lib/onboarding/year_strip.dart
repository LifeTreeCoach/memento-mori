import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/onboarding/year_of_life.dart';
import 'package:memento_mori_life_in_weeks/onboarding/year_strip_painter.dart';
import 'package:memento_mori_life_in_weeks/theme/breath.dart';
import 'package:memento_mori_life_in_weeks/theme/life_palette.dart';
import 'package:memento_mori_life_in_weeks/theme/motion.dart';

/// The current year of life as 52 week squares with a caption. Empty until
/// a [birthDate] is chosen; then the weeks since the last birthday fill
/// left to right once and the current week breathes a few times, then
/// rests. With motion off it shows the final state at once.
class YearStrip extends StatefulWidget {
  const YearStrip({super.key, required this.birthDate, required this.today});

  final DateTime? birthDate;
  final DateTime today;

  @override
  State<YearStrip> createState() => _YearStripState();
}

class _YearStripState extends State<YearStrip> with TickerProviderStateMixin {
  static const int _breaths = 3;
  static const BreathTween _breathTween = BreathTween(_breaths);

  late final AnimationController _fill = AnimationController(
    vsync: this,
    duration: Motion.long,
    value: 1,
  )..addStatusListener(_onFillStatus);

  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: Motion.pulse * _breaths,
    value: 1,
  );

  bool _motion = true;

  YearOfLife? get _year {
    final birth = widget.birthDate;
    return birth == null
        ? null
        : YearOfLife(birthDate: birth, today: widget.today);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _motion = Motion.enabled(context);
    if (!_motion) _settle();
  }

  @override
  void didUpdateWidget(YearStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.birthDate != null && widget.birthDate != oldWidget.birthDate) {
      _play();
    }
  }

  void _play() {
    Haptics.light();
    if (!_motion) return _settle();
    _breath.value = 1;
    _fill.forward(from: 0);
  }

  void _onFillStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _motion) {
      _breath.forward(from: 0);
    }
  }

  void _settle() {
    _fill
      ..stop()
      ..value = 1;
    _breath
      ..stop()
      ..value = 1;
  }

  @override
  void dispose() {
    _fill.dispose();
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final year = _year;
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final caption = year == null
        ? ''
        : l10n.translate(
            'onboarding_year_caption',
            replacements: {'n': '${year.week}'},
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(child: _strip(year)),
        const SizedBox(height: 8),
        Text(
          caption,
          key: const ValueKey('onboarding_year_caption'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _strip(YearOfLife? year) {
    final palette = LifePalette.of(context);
    final colors = YearStripColors(
      lived: palette.lived,
      remaining: palette.remaining,
      now: palette.now,
    );
    const last = YearStripGeometry.cells - 1;
    final lived = year == null ? 0 : year.completedWeeks.clamp(0, last);
    return LayoutBuilder(
      builder: (context, constraints) => AnimatedBuilder(
        animation: Listenable.merge([_fill, _breath]),
        builder: (context, _) => CustomPaint(
          key: const ValueKey('onboarding_year_strip'),
          size: Size(
            constraints.maxWidth,
            YearStripGeometry.heightFor(constraints.maxWidth),
          ),
          painter: YearStripPainter(
            filled: (_fill.value * lived).round(),
            nowIndex: year != null && _fill.isCompleted ? lived : null,
            nowGlow: _breathTween.transform(_breath.value),
            colors: colors,
          ),
        ),
      ),
    );
  }
}
