import 'package:flutter/widgets.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_anchors.dart';

/// Marks [child] as a spot a tour can point at, under [id].
///
/// Registers with the nearest [TourAnchorScope] and unregisters on
/// dispose. Adds no layout and keeps [child] (and its key) as it is.
class TourAnchor extends StatefulWidget {
  const TourAnchor({super.key, required this.id, required this.child});

  final String id;
  final Widget child;

  @override
  State<TourAnchor> createState() => _TourAnchorState();
}

class _TourAnchorState extends State<TourAnchor> {
  TourAnchors? _anchors;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _register(TourAnchorScope.maybeOf(context), widget.id);
  }

  @override
  void didUpdateWidget(TourAnchor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      _anchors?.unregister(oldWidget.id, context);
      _anchors?.register(widget.id, context);
    }
  }

  void _register(TourAnchors? anchors, String id) {
    if (!identical(anchors, _anchors)) _anchors?.unregister(id, context);
    _anchors = anchors;
    _anchors?.register(id, context);
  }

  @override
  void dispose() {
    _anchors?.unregister(widget.id, context);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
