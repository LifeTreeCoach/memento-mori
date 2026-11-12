import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/theme/motion.dart';

/// Pinch-zoom (1–[maxScale]x) around [child]; double tap zooms toward the
/// tapped point and back.
///
/// While unzoomed only a two-finger pinch is claimed, so one-finger drags
/// always scroll the surrounding page. Once zoomed, [InteractiveViewer]
/// takes over panning; [onZoomChanged] lets the page stop scrolling then.
/// [onTap] receives positions in the child's (unzoomed) coordinates.
class ZoomableArea extends StatefulWidget {
  const ZoomableArea({
    super.key,
    required this.child,
    this.maxScale = 6,
    this.doubleTapScale = 3,
    this.onZoomChanged,
    this.onTap,
  });

  final Widget child;
  final double maxScale;
  final double doubleTapScale;
  final ValueChanged<bool>? onZoomChanged;
  final ValueChanged<Offset>? onTap;

  @override
  State<ZoomableArea> createState() => _ZoomableAreaState();
}

class _ZoomableAreaState extends State<ZoomableArea>
    with SingleTickerProviderStateMixin {
  final TransformationController _transform = TransformationController();
  late final AnimationController _zoomAnimation =
      AnimationController(vsync: this)..addListener(_onZoomTick);
  Animation<Matrix4>? _zoomTween;
  Offset _doubleTapPosition = Offset.zero;
  Offset _pinchScenePoint = Offset.zero;
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransformChanged);
  }

  @override
  void dispose() {
    _zoomAnimation.dispose();
    _transform.dispose();
    super.dispose();
  }

  void _onTransformChanged() {
    final zoomed = _transform.value.getMaxScaleOnAxis() > 1.01;
    if (zoomed == _zoomed) return;
    setState(() => _zoomed = zoomed);
    widget.onZoomChanged?.call(zoomed);
  }

  void _onZoomTick() {
    final tween = _zoomTween;
    if (tween != null) _transform.value = tween.value;
  }

  void _onDoubleTap() {
    final size = context.size;
    if (size == null) return;
    final target = _zoomed
        ? Matrix4.identity()
        : _zoomAround(_transform.toScene(_doubleTapPosition), _doubleTapPosition,
            widget.doubleTapScale, size);
    _animateTo(target);
  }

  void _onPinchStart(ScaleStartDetails details) {
    _zoomAnimation.stop();
    _pinchScenePoint = _transform.toScene(details.localFocalPoint);
  }

  void _onPinchUpdate(ScaleUpdateDetails details) {
    final size = context.size;
    if (size == null) return;
    final scale = details.scale.clamp(1.0, widget.maxScale);
    _transform.value =
        _zoomAround(_pinchScenePoint, details.localFocalPoint, scale, size);
  }

  /// Matrix scaling by [scale] that puts [scenePoint] under [viewportPoint],
  /// clamped so the content still covers the viewport.
  Matrix4 _zoomAround(
      Offset scenePoint, Offset viewportPoint, double scale, Size size) {
    final dx = (viewportPoint.dx - scenePoint.dx * scale)
        .clamp(size.width * (1 - scale), 0.0);
    final dy = (viewportPoint.dy - scenePoint.dy * scale)
        .clamp(size.height * (1 - scale), 0.0);
    return Matrix4.identity()
      ..translateByDouble(dx, dy, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);
  }

  void _animateTo(Matrix4 target) {
    final duration = Motion.of(context, Motion.medium);
    if (duration == Duration.zero) {
      _transform.value = target;
      return;
    }
    _zoomTween = Matrix4Tween(begin: _transform.value, end: target).animate(
      CurvedAnimation(parent: _zoomAnimation, curve: Motion.standard),
    );
    _zoomAnimation
      ..duration = duration
      ..forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      gestures: {
        TapGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
          TapGestureRecognizer.new,
          (r) => r.onTapUp = (d) => widget.onTap?.call(_transform.toScene(d.localPosition)),
        ),
        DoubleTapGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<DoubleTapGestureRecognizer>(
          DoubleTapGestureRecognizer.new,
          (r) => r
            ..onDoubleTapDown = ((d) => _doubleTapPosition = d.localPosition)
            ..onDoubleTap = _onDoubleTap,
        ),
        if (!_zoomed)
          _PinchGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<_PinchGestureRecognizer>(
            _PinchGestureRecognizer.new,
            (r) => r
              ..onStart = _onPinchStart
              ..onUpdate = _onPinchUpdate,
          ),
      },
      child: IgnorePointer(
        ignoring: !_zoomed,
        child: InteractiveViewer(
          transformationController: _transform,
          minScale: 1,
          maxScale: widget.maxScale,
          child: widget.child,
        ),
      ),
    );
  }
}

/// A scale recognizer that only wins the arena with two or more fingers,
/// leaving one-finger drags to the enclosing scroll view.
class _PinchGestureRecognizer extends ScaleGestureRecognizer {
  @override
  void resolve(GestureDisposition disposition) {
    if (disposition == GestureDisposition.accepted && pointerCount < 2) return;
    super.resolve(disposition);
  }
}
