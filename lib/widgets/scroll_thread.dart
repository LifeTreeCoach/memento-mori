import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:memento_mori_life_in_weeks/theme/life_palette.dart';
import 'package:memento_mori_life_in_weeks/theme/motion.dart';
import 'package:memento_mori_life_in_weeks/widgets/scroll_thread_geometry.dart';

/// "Lebensfaden": a thin accent thread at the right edge of a vertical
/// scroll view that shows the scroll position. Visible while more content
/// lies below, fades out at the end, hidden while a dialog, sheet or tour
/// covers it. Not interactive and not announced.
class ScrollThread extends StatefulWidget {
  const ScrollThread({
    super.key,
    required this.child,
    this.enabled = true,
    this.bottomInset = 0,
  });

  /// Key of the thread's [AnimatedOpacity], for tests.
  static const Key threadKey = ValueKey('scroll_thread');

  /// The scroll view whose position the thread shows.
  final Widget child;

  /// False hides the thread.
  final bool enabled;

  /// Space kept free below the track (e.g. for a floating button).
  final double bottomInset;

  /// Distance of the thread from the right edge.
  static const double rightInset = 6;

  /// Thread width.
  static const double width = 2;

  /// Alpha of the accent colour.
  static const double alpha = 0.85;

  @override
  State<ScrollThread> createState() => _ScrollThreadState();
}

class _ScrollThreadState extends State<ScrollThread> {
  ScrollMetrics? _metrics;

  bool _onMetrics(ScrollMetricsNotification notification) {
    _update(notification.depth, notification.metrics);
    return false;
  }

  bool _onScroll(ScrollNotification notification) {
    _update(notification.depth, notification.metrics);
    return false;
  }

  void _update(int depth, ScrollMetrics metrics) {
    if (depth != 0 || metrics.axis != Axis.vertical) return;
    final previous = _metrics;
    if (previous != null && _sameMetrics(previous, metrics)) return;
    final snapshot = metrics.copyWith();
    final binding = SchedulerBinding.instance;
    if (binding.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      // Sent during layout (e.g. a ballistic scroll restarted by new content
      // dimensions), where setState is not allowed: apply after the frame.
      binding.addPostFrameCallback((_) => _apply(snapshot));
      return;
    }
    _apply(snapshot);
  }

  void _apply(ScrollMetrics metrics) {
    if (mounted) setState(() => _metrics = metrics);
  }

  static bool _sameMetrics(ScrollMetrics a, ScrollMetrics b) =>
      a.pixels == b.pixels &&
      a.maxScrollExtent == b.maxScrollExtent &&
      a.minScrollExtent == b.minScrollExtent &&
      a.viewportDimension == b.viewportDimension;

  bool get _visible {
    final metrics = _metrics;
    return widget.enabled && metrics != null && hasMoreBelow(metrics.extentAfter);
  }

  /// False while a dialog, sheet or tour lies above this screen: the
  /// thread steps back under their scrim. Rebuilds when that changes.
  static bool _routeOnTop(BuildContext context) =>
      ModalRoute.isCurrentOf(context) ?? true;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: _onMetrics,
      child: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: Stack(children: [
          widget.child,
          Positioned(
            right: ScrollThread.rightInset,
            // Below the status bar when the scroll view extends under it.
            top: MediaQuery.paddingOf(context).top,
            bottom: widget.bottomInset,
            width: ScrollThread.width,
            child: _threadLayer(context),
          ),
        ]),
      ),
    );
  }

  Widget _threadLayer(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(
        child: AnimatedOpacity(
          key: ScrollThread.threadKey,
          opacity: _visible && _routeOnTop(context) ? 1 : 0,
          duration: Motion.of(context, Motion.medium),
          curve: Motion.standard,
          child: LayoutBuilder(
            builder: (context, constraints) =>
                _thread(context, constraints.maxHeight),
          ),
        ),
      ),
    );
  }

  Widget _thread(BuildContext context, double trackHeight) {
    final metrics = _metrics;
    if (metrics == null) return const SizedBox.shrink();
    final geometry = scrollThreadGeometry(
      pixels: metrics.pixels,
      maxScrollExtent: metrics.maxScrollExtent,
      viewportDimension: metrics.viewportDimension,
      trackHeight: trackHeight,
    );
    final color = LifePalette.of(context)
        .accent
        .withValues(alpha: ScrollThread.alpha);
    return Stack(children: [
      Positioned(
        top: geometry.top,
        height: geometry.length,
        left: 0,
        right: 0,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(ScrollThread.width / 2),
          ),
        ),
      ),
    ]);
  }
}
