import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';

/// Taps on the home-screen widget, which open the app at the Life tab.
///
/// The widgets launch `mementomori://widget?homeWidget` (Android: home_widget's
/// launch action, iOS: `widgetURL`; the `homeWidget` query item is what
/// home_widget's iOS plugin looks for). Deep linking stays disabled, so the
/// URI is never pushed as a route.
abstract interface class WidgetLaunches {
  /// Calls [onLaunch] if the app was started by a widget tap and on every
  /// later tap while it runs. Cancel the subscription to stop listening.
  StreamSubscription<void> listen(VoidCallback onLaunch);
}

/// Android: [PendingWidgetLaunches] backed by `MainActivity`; elsewhere
/// [HomeWidgetLaunches].
class PlatformWidgetLaunches implements WidgetLaunches {
  const PlatformWidgetLaunches();

  @override
  StreamSubscription<void> listen(VoidCallback onLaunch) {
    final WidgetLaunches launches =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android
            ? PendingWidgetLaunches.android()
            : const HomeWidgetLaunches();
    return launches.listen(onLaunch);
  }
}

/// Widget taps recorded natively as a "pending launch" flag (Android
/// `MainActivity`), read and cleared by [consumePending].
///
/// The flag is checked when listening starts and on every [checks] event
/// (app resumed, native "widget launched" call), so a tap is never lost even
/// if it arrives before Flutter listens. Each recorded tap is reported once;
/// a failing check reports nothing.
class PendingWidgetLaunches implements WidgetLaunches {
  PendingWidgetLaunches({required this.consumePending, required this.checks});

  /// Wired to `MainActivity` over [channel] and to app resumes.
  factory PendingWidgetLaunches.android() {
    AppLifecycleListener? lifecycle;
    late final StreamController<void> checks;
    checks = StreamController<void>.broadcast(
      onListen: () {
        lifecycle = AppLifecycleListener(onResume: () => checks.add(null));
        channel.setMethodCallHandler((call) async {
          if (call.method == 'widgetLaunched') checks.add(null);
        });
      },
      onCancel: () {
        lifecycle?.dispose();
        channel.setMethodCallHandler(null);
      },
    );
    return PendingWidgetLaunches(
      consumePending: () async =>
          await channel.invokeMethod<bool>('consumeWidgetLaunch') ?? false,
      checks: checks.stream,
    );
  }

  static const MethodChannel channel = MethodChannel('memento/widget_launch');

  /// True once per recorded widget tap.
  final Future<bool> Function() consumePending;

  /// Moments at which a tap may have been recorded.
  final Stream<void> checks;

  /// Checks once now and on every [checks] event; cancelling the returned
  /// subscription stops the checks.
  @override
  StreamSubscription<void> listen(VoidCallback onLaunch) {
    Future<void> check() async {
      if (await _consume()) onLaunch();
    }

    final subscription = checks.listen((_) => check());
    check();
    return subscription;
  }

  Future<bool> _consume() async {
    try {
      return await consumePending();
    } catch (e) {
      debugPrint('Widget: launch check failed: $e');
      return false;
    }
  }
}

/// [WidgetLaunches] backed by the home_widget plugin (used on iOS).
class HomeWidgetLaunches implements WidgetLaunches {
  const HomeWidgetLaunches();

  @override
  StreamSubscription<void> listen(VoidCallback onLaunch) {
    return _launches().listen((_) => onLaunch());
  }

  /// The initial launch (if any), then every click. If the plugin cannot
  /// answer (no platform implementation, e.g. in tests) nothing is emitted
  /// and the click stream is never opened.
  Stream<void> _launches() async* {
    final Uri? initial;
    try {
      initial = await HomeWidget.initiallyLaunchedFromHomeWidget();
    } catch (e) {
      debugPrint('Widget: launch detection unavailable: $e');
      return;
    }
    if (initial != null) yield null;
    yield* HomeWidget.widgetClicked;
  }
}
