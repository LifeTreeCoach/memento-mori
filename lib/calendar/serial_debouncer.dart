import 'dart:async';

import 'package:flutter/foundation.dart';

/// Runs work one piece at a time ([run]) and coalesces bursts of requests
/// for the same action into one debounced run ([request]).
///
/// Failures are logged and swallowed for [request]ed runs, so a background
/// sync never surfaces as an unhandled error.
class SerialDebouncer {
  SerialDebouncer(this._action, {this.delay = const Duration(milliseconds: 500)});

  final Future<void> Function() _action;

  /// Quiet time after the last [request] before the action runs.
  Duration delay;

  Timer? _timer;
  Completer<void>? _queued;
  Future<void> _tail = Future.value();

  /// Runs the action [delay] after the last of a burst of requests, after
  /// any work already running; completes once that run finished.
  Future<void> request() {
    final queued = _queued ??= Completer<void>();
    _timer?.cancel();
    _timer = Timer(delay, _fire);
    return queued.future;
  }

  /// Runs [work] after everything queued before it (never concurrently).
  Future<T> run<T>(Future<T> Function() work) {
    final result = _tail.then((_) => work());
    _tail = result.then<void>((_) {}, onError: (_) {});
    return result;
  }

  /// Completes when no request is waiting and nothing is running.
  Future<void> get idle async {
    for (var queued = _queued; queued != null; queued = _queued) {
      await queued.future;
    }
    await _tail;
  }

  void _fire() {
    _timer = null;
    final queued = _queued;
    _queued = null;
    unawaited(run(_runLogged).whenComplete(() => queued?.complete()));
  }

  Future<void> _runLogged() async {
    try {
      await _action();
    } catch (e) {
      debugPrint('SerialDebouncer: action failed: $e');
    }
  }
}
