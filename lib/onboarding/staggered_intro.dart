import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/theme/motion.dart';

/// Fades its [children] in once when it mounts, each rising [rise] dp and
/// starting a little after the one above. Nothing repeats; with motion off
/// the children show in place from the first frame.
class StaggeredIntro extends StatefulWidget {
  const StaggeredIntro({
    super.key,
    required this.children,
    this.spacing = 12,
    this.rise = 8,
  });

  final List<Widget> children;

  /// Gap between two children.
  final double spacing;

  /// How far each child rises while it fades in.
  final double rise;

  /// Whole intro; every child takes [_childShare] of it.
  static const Duration duration = Duration(milliseconds: 750);
  static const double _childShare = 0.75;

  @override
  State<StaggeredIntro> createState() => _StaggeredIntroState();
}

class _StaggeredIntroState extends State<StaggeredIntro>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: StaggeredIntro.duration,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (Motion.enabled(context)) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// The share of the intro in which child [index] of [count] appears.
  Animation<double> _progressOf(int index, int count) {
    const share = StaggeredIntro._childShare;
    final start = count < 2 ? 0.0 : (1 - share) * index / (count - 1);
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(start, start + share, curve: Motion.standard),
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.children.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) SizedBox(height: widget.spacing),
          _Rising(
            progress: _progressOf(i, count),
            rise: widget.rise,
            child: widget.children[i],
          ),
        ],
      ],
    );
  }
}

class _Rising extends AnimatedWidget {
  const _Rising({
    required Animation<double> progress,
    required this.rise,
    required this.child,
  }) : super(listenable: progress);

  final double rise;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = (listenable as Animation<double>).value;
    return Opacity(
      opacity: t,
      child: Transform.translate(
        offset: Offset(0, (1 - t) * rise),
        child: child,
      ),
    );
  }
}
