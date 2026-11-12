import 'package:flutter/widgets.dart';

/// Registry of the widgets a tour can spotlight, by anchor id.
///
/// [TourAnchor]s register themselves; the tour resolves them to a
/// [BuildContext] (for scrolling) and a [Rect] (for the hole).
class TourAnchors {
  final Map<String, BuildContext> _contexts = <String, BuildContext>{};

  void register(String id, BuildContext context) => _contexts[id] = context;

  /// Removes [id] only while it still belongs to [context], so a newer
  /// anchor with the same id survives an older one's dispose.
  void unregister(String id, BuildContext context) {
    if (identical(_contexts[id], context)) _contexts.remove(id);
  }

  /// The mounted context of [id], or null.
  BuildContext? contextOf(String id) {
    final context = _contexts[id];
    return context != null && context.mounted ? context : null;
  }

  /// Whether [id] is registered, mounted and laid out.
  bool contains(String id) => _boxOf(id) != null;

  /// The anchor's bounds in [ancestor]'s coordinates (global without one),
  /// or null when it is missing.
  Rect? rectOf(String id, {RenderBox? ancestor}) {
    final box = _boxOf(id);
    if (box == null) return null;
    final transform = box.getTransformTo(ancestor);
    return MatrixUtils.transformRect(transform, Offset.zero & box.size);
  }

  RenderBox? _boxOf(String id) {
    final object = contextOf(id)?.findRenderObject();
    if (object is! RenderBox || !object.attached || !object.hasSize) {
      return null;
    }
    return object;
  }
}

/// Provides a [TourAnchors] registry to the [TourAnchor]s below.
class TourAnchorScope extends InheritedWidget {
  const TourAnchorScope({
    super.key,
    required this.anchors,
    required super.child,
  });

  final TourAnchors anchors;

  static TourAnchors? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<TourAnchorScope>()
      ?.anchors;

  @override
  bool updateShouldNotify(TourAnchorScope oldWidget) =>
      !identical(anchors, oldWidget.anchors);
}
