import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:memento_mori_life_in_weeks/security/personal_store.dart';
import 'package:timezone/timezone.dart' as tz;

/// A notification the scheduler wants pending: id, fire time and text.
@immutable
class DesiredNotification {
  final int id;

  /// Fire time; its ISO string (with zone offset) is part of the fingerprint.
  final tz.TZDateTime when;
  final String title;
  final String body;
  final String payload;

  const DesiredNotification({
    required this.id,
    required this.when,
    required this.title,
    required this.body,
    required this.payload,
  });

  /// Stable hash of fire time, title, body and payload.
  String get fingerprint =>
      ReminderFingerprints.hash('${when.toIso8601String()}\u0001$title\u0001$body\u0001$payload');
}

/// What a scheduling pass has to change.
@immutable
class ReminderDiff {
  /// Pending ids to cancel (no longer wanted).
  final Set<int> toCancel;

  /// Notifications to (re)schedule: new, changed or no longer pending.
  /// Scheduling an id that is still pending replaces it.
  final List<DesiredNotification> toSchedule;

  const ReminderDiff(this.toCancel, this.toSchedule);

  bool get isEmpty => toCancel.isEmpty && toSchedule.isEmpty;

  /// Compares [desired] with the [pending] ids and the fingerprints stored
  /// at the last pass ([stored]). Without stored fingerprints (missing or
  /// corrupt) nothing pending can be trusted: everything pending is
  /// cancelled and everything desired scheduled (full reschedule).
  static ReminderDiff compute({
    required List<DesiredNotification> desired,
    required Set<int> pending,
    required Map<int, String>? stored,
  }) {
    if (stored == null) return ReminderDiff({...pending}, [...desired]);
    final desiredIds = {for (final n in desired) n.id};
    return ReminderDiff(
      pending.difference(desiredIds),
      [
        for (final n in desired)
          if (!pending.contains(n.id) || stored[n.id] != n.fingerprint) n,
      ],
    );
  }
}

/// Persists the fingerprint (see [DesiredNotification.fingerprint]) of every
/// scheduled birthday notification, because the plugin's pending requests
/// don't expose the fire time. Kept in the [PersonalStore] (the texts hold
/// names).
class ReminderFingerprints {
  static const String key = PersonalKeys.birthdayScheduledFingerprints;

  /// The stored fingerprints, or null when missing or unreadable.
  Future<Map<int, String>?> load() async {
    try {
      final store = PersonalStore.instance;
      await store.reload();
      final json = store.getString(key);
      if (json == null) return null;
      return (jsonDecode(json) as Map<String, dynamic>)
          .map((id, fingerprint) => MapEntry(int.parse(id), fingerprint as String));
    } catch (_) {
      return null;
    }
  }

  Future<void> save(Iterable<DesiredNotification> scheduled) async {
    final encoded = jsonEncode({for (final n in scheduled) '${n.id}': n.fingerprint});
    await PersonalStore.instance.setString(key, encoded);
  }

  /// Forgets every fingerprint, so the next pass is a full reschedule
  /// (see [ReminderDiff.compute]).
  Future<void> clear() async {
    await PersonalStore.instance.remove(key);
  }

  /// 32-bit FNV-1a of [text] (UTF-8) as hex: stable across app runs,
  /// unlike [String.hashCode].
  static String hash(String text) {
    var hash = 0x811c9dc5;
    for (final byte in utf8.encode(text)) {
      hash = ((hash ^ byte) * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}
