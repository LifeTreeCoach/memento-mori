import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/calendar/serial_debouncer.dart';

void main() {
  test('a burst of requests runs the action once', () async {
    var runs = 0;
    final debouncer = SerialDebouncer(() async => runs++,
        delay: const Duration(milliseconds: 20));

    final requests = [for (var i = 0; i < 5; i++) debouncer.request()];
    await Future.wait(requests);

    expect(runs, 1);
  });

  test('a request during a run runs again afterwards, never concurrently', () async {
    var running = 0;
    var maxRunning = 0;
    var runs = 0;
    final gate = Completer<void>();
    final debouncer = SerialDebouncer(() async {
      running++;
      maxRunning = running > maxRunning ? running : maxRunning;
      if (runs++ == 0) await gate.future;
      running--;
    }, delay: Duration.zero);

    final first = debouncer.request();
    await Future<void>.delayed(const Duration(milliseconds: 5));
    final second = debouncer.request();
    await Future<void>.delayed(const Duration(milliseconds: 5));
    gate.complete();
    await Future.wait([first, second]);

    expect(runs, 2);
    expect(maxRunning, 1);
  });

  test('run waits for earlier work and returns its result', () async {
    final order = <String>[];
    final debouncer = SerialDebouncer(() async {}, delay: Duration.zero);

    final slow = debouncer.run(() async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      order.add('slow');
    });
    final fast = debouncer.run(() async {
      order.add('fast');
      return 42;
    });

    expect(await fast, 42);
    await slow;
    expect(order, ['slow', 'fast']);
  });

  test('a failing action is logged and later work still runs', () async {
    var calls = 0;
    final debouncer = SerialDebouncer(() async {
      if (calls++ == 0) throw StateError('boom');
    }, delay: Duration.zero);

    await debouncer.request();
    await debouncer.request();
    await debouncer.idle;

    expect(calls, 2);
  });

  test('a failing run does not block later work', () async {
    final debouncer = SerialDebouncer(() async {}, delay: Duration.zero);

    await expectLater(debouncer.run<void>(() async => throw StateError('x')), throwsStateError);
    expect(await debouncer.run(() async => 'ok'), 'ok');
  });
}
