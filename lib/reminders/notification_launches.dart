import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:memento_mori_life_in_weeks/reminders/birthday_reminder_scheduler.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_service.dart';
import 'package:memento_mori_life_in_weeks/reminders/weekly_reflection_planner.dart';

/// Payloads of tapped notifications, reported by [NotificationService]
/// (taps while the app runs and the tap that launched it).
///
/// Taps that arrive before anyone listens (e.g. the launching tap, reported
/// while the first screen is still being set up) are kept and delivered to
/// the next listener, so none is lost.
class NotificationTaps {
  NotificationTaps._();

  static StreamController<String> _taps = StreamController<String>.broadcast();
  static final List<String> _pending = [];

  /// Reports the tap of a notification with [payload] (null/empty ignored).
  static void report(String? payload) {
    if (payload == null || payload.isEmpty) return;
    if (_taps.hasListener) {
      _taps.add(payload);
    } else {
      _pending.add(payload);
    }
  }

  /// Calls [onTap] for every tap: first the pending ones (asynchronously,
  /// so it is safe to call from `initState`), then each new one.
  static StreamSubscription<String> listen(void Function(String) onTap) {
    final pending = List.of(_pending);
    _pending.clear();
    final subscription = _taps.stream.listen(onTap);
    if (pending.isNotEmpty) {
      scheduleMicrotask(() => pending.forEach(_taps.add));
    }
    return subscription;
  }

  @visibleForTesting
  static void resetForTesting() {
    _pending.clear();
    _taps.close();
    _taps = StreamController<String>.broadcast();
  }
}

/// Where a tapped notification leads (see [NotificationLaunch.fromPayload]).
sealed class NotificationLaunch {
  const NotificationLaunch();

  /// The screen for a notification [payload]; null when the tap only opens
  /// the app.
  ///
  /// - Compass: the weekly reflection and the phase check-in (bare or
  ///   dated, `compass:yyyy-MM-dd`, see [CompassLaunch.reminderDay]) and the
  ///   former weekly reminder.
  /// - People: a birthday reminder (`birthday:<friend id>`, also the test
  ///   one), which opens that friend, and the "open the app" refresh note.
  static NotificationLaunch? fromPayload(String payload) {
    if (_compassPayloads.contains(payload)) return const CompassLaunch();
    if (payload.startsWith(_compassPrefix)) {
      return CompassLaunch(
          reminderDay: _parseDay(payload.substring(_compassPrefix.length)));
    }
    if (payload == BirthdayReminderScheduler.refreshPayload) {
      return const PeopleLaunch();
    }
    for (final prefix in _birthdayPrefixes) {
      if (payload.startsWith(prefix)) {
        final id = payload.substring(prefix.length);
        return PeopleLaunch(friendId: id.isEmpty ? null : id);
      }
    }
    return null;
  }

  static const Set<String> _compassPayloads = {
    ReminderService.compassPayload,
    ReminderService.weeklyReminderPayload,
  };

  static const String _compassPrefix = WeeklyReflectionPlanner.payloadPrefix;

  static final RegExp _dayPattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  /// The local date of a `yyyy-MM-dd` [text]; null unless it is a real
  /// calendar day (e.g. not `2026-13-40`).
  static DateTime? _parseDay(String text) {
    if (!_dayPattern.hasMatch(text)) return null;
    final parts = text.split('-').map(int.parse).toList();
    final day = DateTime(parts[0], parts[1], parts[2]);
    final roundTrips =
        day.year == parts[0] && day.month == parts[1] && day.day == parts[2];
    return roundTrips ? day : null;
  }

  static const List<String> _birthdayPrefixes = [
    BirthdayReminderScheduler.payloadPrefix,
    BirthdayReminderScheduler.testPayloadPrefix,
  ];
}

/// Opens the Compass tab; [reminderDay] is the local date (date only) the
/// tapped reminder was meant for, null for payloads without a valid date.
final class CompassLaunch extends NotificationLaunch {
  const CompassLaunch({this.reminderDay});

  final DateTime? reminderDay;

  @override
  bool operator ==(Object other) =>
      other is CompassLaunch && other.reminderDay == reminderDay;

  @override
  int get hashCode => Object.hash(CompassLaunch, reminderDay);
}

/// Opens the People tab and, with a [friendId], that friend's detail.
final class PeopleLaunch extends NotificationLaunch {
  const PeopleLaunch({this.friendId});

  final String? friendId;

  @override
  bool operator ==(Object other) =>
      other is PeopleLaunch && other.friendId == friendId;

  @override
  int get hashCode => Object.hash(PeopleLaunch, friendId);
}

/// Taps on notifications that open a tab (Compass, People).
abstract interface class NotificationLaunches {
  /// Calls [onLaunch] if the app was started by tapping such a
  /// notification and on every later tap. Cancel to stop listening.
  StreamSubscription<void> listen(void Function(NotificationLaunch) onLaunch);
}

/// [NotificationLaunches] fed by [NotificationTaps].
class PlatformNotificationLaunches implements NotificationLaunches {
  const PlatformNotificationLaunches();

  @override
  StreamSubscription<void> listen(void Function(NotificationLaunch) onLaunch) {
    return NotificationTaps.listen((payload) {
      final launch = NotificationLaunch.fromPayload(payload);
      if (launch != null) onLaunch(launch);
    });
  }
}
