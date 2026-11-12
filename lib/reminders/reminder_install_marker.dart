import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Tells whether this install has scheduled reminders before, through a
/// marker file that is never part of a backup or device transfer.
///
/// Scheduled notifications live in the OS (AlarmManager on Android,
/// UNUserNotificationCenter on iOS) and are never restored, but the app's
/// preferences are (Android Auto Backup / device transfer, iCloud backup,
/// third-party backup tools). Restored reminder fingerprints (and on Android
/// a restored plugin cache of "pending" notifications) would then make the
/// diff scheduler skip reminders that no longer exist. A missing marker
/// means the data may have been restored, so everything is rescheduled.
///
/// The marker sits in the cache directory (`getApplicationCacheDirectory`:
/// Android `cache/`, iOS `Library/Caches`), which neither platform backs up.
/// The OS may clear it when storage runs low; that only costs one extra
/// full reschedule, which is harmless.
class ReminderInstallMarker {
  static const String fileName = 'reminders_install_marker';

  final Future<Directory> Function() _directory;

  ReminderInstallMarker({Future<Directory> Function()? directory})
      : _directory = directory ?? getApplicationCacheDirectory;

  /// Whether the marker was missing (first launch, restored data or a
  /// cleared cache). Creates it, so the next call returns false.
  Future<bool> checkAndMark() async {
    final directory = await _directory();
    final marker = File('${directory.path}/$fileName');
    if (await marker.exists()) return false;
    await directory.create(recursive: true);
    await marker.writeAsString('1', flush: true);
    return true;
  }
}
