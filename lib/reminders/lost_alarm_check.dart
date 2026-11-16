import 'package:flutter/foundation.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_fingerprints.dart';
import 'package:memento_mori_life_in_weeks/reminders/scheduled_alarm_probe.dart';

/// Detects birthday reminders whose OS alarms are gone although the
/// notification plugin still lists them as pending (Android "force stop"
/// cancels the alarms but not the plugin's saved list). Then the stored
/// fingerprints are cleared, so the next pass is a full reschedule
/// (see [ReminderDiff.compute]).
class LostAlarmCheck {
  /// How many reminders are probed: a force stop removes every alarm, so a
  /// few samples are enough.
  static const int maxProbes = 3;

  final ScheduledAlarmProbe probe;

  /// Ids of the birthday reminders in the plugin's pending list.
  final Future<Set<int>> Function() pendingIds;
  final ReminderFingerprints fingerprints;

  LostAlarmCheck({
    required this.probe,
    required this.pendingIds,
    ReminderFingerprints? fingerprints,
  }) : fingerprints = fingerprints ?? ReminderFingerprints();

  /// Probes up to [maxProbes] reminders that are both pending and
  /// fingerprinted; clears the fingerprints if any alarm is missing.
  /// Returns whether they were cleared. Errors leave everything as is.
  Future<bool> run() async {
    try {
      final samples = await _probedIds();
      for (final id in samples) {
        if (!await probe.hasScheduledAlarm(id)) {
          await fingerprints.clear();
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Scheduled alarm check skipped: ${e.runtimeType}');
      return false;
    }
  }

  /// The smallest ids that are pending and have a stored fingerprint
  /// (without fingerprints the next pass reschedules everything anyway).
  Future<List<int>> _probedIds() async {
    final stored = await fingerprints.load();
    if (stored == null) return const [];
    final pending = await pendingIds();
    final candidates = pending.where(stored.containsKey).toList()..sort();
    return candidates.take(maxProbes).toList();
  }
}
