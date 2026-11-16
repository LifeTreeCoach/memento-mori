import 'package:flutter/services.dart';

/// Asks the OS whether the alarm behind a scheduled notification still
/// exists. On Android a "force stop" cancels the app's alarms while the
/// notification plugin keeps its saved pending list, so that list alone
/// cannot tell (see [LostAlarmCheck]).
abstract interface class ScheduledAlarmProbe {
  /// Whether the alarm of the scheduled notification [id] is still armed.
  /// Throws when the platform cannot answer.
  Future<bool> hasScheduledAlarm(int id);
}

/// Android implementation: `ScheduledAlarmProbe.kt`, wired up in
/// android/.../MainActivity.kt on the `memento/app_settings` channel.
class MethodChannelScheduledAlarmProbe implements ScheduledAlarmProbe {
  const MethodChannelScheduledAlarmProbe();

  static const MethodChannel channel = MethodChannel('memento/app_settings');
  static const String method = 'hasScheduledAlarm';

  @override
  Future<bool> hasScheduledAlarm(int id) async {
    final armed = await channel.invokeMethod<bool>(method, id);
    if (armed == null) throw const FormatException('hasScheduledAlarm returned no answer');
    return armed;
  }
}
