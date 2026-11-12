import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_fingerprints.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_install_marker.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory cache;

  ReminderInstallMarker marker() => ReminderInstallMarker(directory: () async => cache);

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    cache = Directory('${(await Directory.systemTemp.createTemp('marker')).path}/cache');
    SharedPreferences.setMockInitialValues({ReminderFingerprints.key: '{"100004":"abcd1234"}'});
  });

  tearDown(() async {
    if (await cache.parent.exists()) await cache.parent.delete(recursive: true);
  });

  group('ReminderInstallMarker.checkAndMark', () {
    test('reports a missing marker once and creates it (incl. the directory)', () async {
      expect(await marker().checkAndMark(), isTrue);
      expect(File('${cache.path}/${ReminderInstallMarker.fileName}').existsSync(), isTrue);
      expect(await marker().checkAndMark(), isFalse);
    });

    test('a cleared cache counts as missing again', () async {
      await marker().checkAndMark();
      await cache.delete(recursive: true);
      expect(await marker().checkAndMark(), isTrue);
    });
  });

  group('ReminderService.forgetScheduledRemindersIfRestored', () {
    test('without the marker (restored data) the fingerprints are cleared', () async {
      expect(await ReminderService.forgetScheduledRemindersIfRestored(marker: marker()), isTrue);
      expect(await ReminderFingerprints().load(), isNull);
    });

    test('with the marker (same install) the fingerprints stay', () async {
      await marker().checkAndMark();
      expect(await ReminderService.forgetScheduledRemindersIfRestored(marker: marker()), isFalse);
      expect(await ReminderFingerprints().load(), {100004: 'abcd1234'});
    });

    test('an unreadable cache directory keeps the fingerprints', () async {
      final failing = ReminderInstallMarker(directory: () async => throw const FileSystemException());
      expect(await ReminderService.forgetScheduledRemindersIfRestored(marker: failing), isFalse);
      expect(await ReminderFingerprints().load(), isNotNull);
    });
  });
}
