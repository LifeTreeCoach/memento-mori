import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_service.dart';
import 'package:memento_mori_life_in_weeks/compass/completion_story.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/phase_style.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/reflection/reflection_levels.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/onboarding/step_layout.dart';
import 'package:memento_mori_life_in_weeks/theme/motion.dart';

/// Fades the look back in over the Compass.
Future<void> showCompletionReflection(
  BuildContext context,
  CompletionReflectionScreen screen,
) {
  final duration = Motion.of(context, Motion.medium);
  return Navigator.of(context).push<void>(
    PageRouteBuilder<void>(
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      pageBuilder: (_, _, _) => screen,
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

/// A calm full-screen look back after completing [intention] (now
/// [moment]): how long it took and where in its phase, its place in the
/// whole life and the time that lies ahead, revealed one after another,
/// then a kind closing line and an optional gratitude note (saved on the
/// moment when leaving). "Not done yet after all" undoes the completion.
class CompletionReflectionScreen extends StatefulWidget {
  const CompletionReflectionScreen({
    super.key,
    required this.intention,
    required this.moment,
    required this.story,
  });

  /// The intention as it was before completing (for undo).
  final Intention intention;
  final Moment moment;
  final CompletionStory story;

  /// Time between the start of two levels, and the fade of one.
  static const Duration stagger = Duration(milliseconds: 450);
  static const Duration fade = Motion.long;

  @override
  State<CompletionReflectionScreen> createState() =>
      _CompletionReflectionScreenState();
}

class _CompletionReflectionScreenState extends State<CompletionReflectionScreen>
    with SingleTickerProviderStateMixin {
  final _note = TextEditingController();
  final _noteField = GlobalKey();
  late final int _levels = widget.story.life == null ? 2 : 4;
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: CompletionReflectionScreen.stagger * (_levels - 1) +
        CompletionReflectionScreen.fade,
  );
  late final List<CurvedAnimation> _steps = [
    for (var i = 0; i < _levels; i++) _step(i),
  ];
  bool _started = false;
  bool _undone = false;

  CurvedAnimation _step(int index) {
    final total = _reveal.duration!.inMilliseconds;
    final start =
        CompletionReflectionScreen.stagger.inMilliseconds * index / total;
    final end = start + CompletionReflectionScreen.fade.inMilliseconds / total;
    return CurvedAnimation(
      parent: _reveal,
      curve: Interval(start, end.clamp(0.0, 1.0), curve: Motion.standard),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!Motion.enabled(context)) {
      _reveal.value = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showNote());
      return;
    }
    _reveal.forward().whenComplete(() {
      if (!mounted) return;
      Haptics.light();
      _showNote();
    });
  }

  /// Brings the gratitude note fully into view (above the scroll area's
  /// fade) once every level is there, so it is not missed below the fold:
  /// a gentle scroll, or a jump when motion is off.
  void _showNote() {
    final field = _noteField.currentContext;
    if (!mounted || field == null) return;
    final scrollable = Scrollable.maybeOf(field);
    final box = field.findRenderObject() as RenderBox?;
    final viewport = scrollable?.context.findRenderObject() as RenderBox?;
    if (scrollable == null || box == null || viewport == null) return;
    final fieldBottom = box.localToGlobal(Offset(0, box.size.height)).dy;
    final visibleBottom = viewport.localToGlobal(Offset.zero).dy +
        viewport.size.height -
        StepLayout.fadeHeight;
    final hidden = fieldBottom - visibleBottom;
    if (hidden <= 0) return;
    final position = scrollable.position;
    final target = (position.pixels + hidden + StepLayout.actionGap).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (Motion.enabled(context)) {
      position.animateTo(target, duration: Motion.long, curve: Motion.standard);
    } else {
      position.jumpTo(target);
    }
  }

  @override
  void dispose() {
    for (final step in _steps) {
      step.dispose();
    }
    _reveal.dispose();
    _note.dispose();
    super.dispose();
  }

  /// Keeps a written note on the moment (on every way out but undo).
  void _saveNote() {
    final id = widget.moment.id;
    final exists = CompassService.data.moments.any((m) => m.id == id);
    if (_undone || !exists || _note.text.trim().isEmpty) return;
    CompassService.setMomentNote(id, _note.text);
  }

  Future<void> _notDone() async {
    _undone = true;
    await CompassService.undoComplete(widget.intention, widget.moment.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _saveNote();
      },
      child: Scaffold(
        key: const ValueKey('completion_reflection'),
        body: SafeArea(
          child: StepLayout(
            topPadding: 40,
            centerContent: true,
            action: FilledButton(
              key: const ValueKey('reflection_close'),
              onPressed: () => Navigator.of(context).maybePop(),
              child: Text(l10n.translate('reflection_close')),
            ),
            secondaryAction: TextButton(
              key: const ValueKey('reflection_not_done'),
              onPressed: _notDone,
              child: Text(l10n.translate('reflection_not_done')),
            ),
            children: [
              PhaseEyebrow(l10n.translate('reflection_eyebrow')),
              _title(context),
              ..._revealed(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _revealed() {
    final life = widget.story.life;
    final levels = [
      PhaseLevel(story: widget.story),
      if (life != null) LifeLevel(life: life),
      if (life != null) AheadLevel(life: life),
      ThanksLevel(story: widget.story, note: _note, fieldKey: _noteField),
    ];
    return [
      for (var i = 0; i < levels.length; i++)
        RevealLevel(animation: _steps[i], child: levels[i]),
    ];
  }

  /// The intention's title in Fraunces, lightly struck through in gold.
  Widget _title(BuildContext context) {
    final theme = Theme.of(context);
    final gold = PhaseStyle.readableGold(context);
    return Text(
      widget.moment.title,
      key: const ValueKey('reflection_title'),
      style: theme.textTheme.headlineMedium?.copyWith(
        decoration: TextDecoration.lineThrough,
        decorationColor: gold.withValues(alpha: 0.6),
        decorationThickness: 1.5,
      ),
    );
  }
}
