import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_service.dart';
import 'package:memento_mori_life_in_weeks/compass/life_phase.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/data/friends_import_export_screen.dart';
import 'package:memento_mori_life_in_weeks/friends_service.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:share_plus/share_plus.dart' show XFile;
import 'package:shared_preferences/shared_preferences.dart';

/// Records save requests; returns [savedTo] (null = the user cancelled).
class _FakeFilePicker extends FilePickerPlatform {
  Uri? savedTo;
  String? pickedJson;
  String? savedName;
  String? savedMime;
  Uint8List? savedBytes;
  int cleared = 0;

  @override
  Future<void> clearTemporaryFiles() async => cleared++;

  @override
  Future<Uri?> saveFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    String? dialogTitle,
    String? initialDirectory,
    Function(FilePickerStatus)? onFileSaving,
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    savedName = fileName;
    savedMime = mimeType;
    savedBytes = bytes;
    return savedTo;
  }

  @override
  Future<PlatformFile?> pickFile({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    final json = pickedJson;
    return json == null ? null : _JsonFile(json);
  }
}

final class _JsonFile extends PlatformFile {
  _JsonFile(this.json);

  final String json;

  @override
  String get name => 'backup.json';

  @override
  Uri get uri => Uri.file('/tmp/backup.json');

  @override
  XFile get xFile => throw UnimplementedError();

  @override
  int? lengthSync() => json.length;

  @override
  Future<int?> length() async => json.length;

  @override
  Future<Uint8List> readAsBytes() async => utf8.encode(json);

  @override
  Stream<Uint8List> readAsByteStream() => Stream.value(utf8.encode(json));
}

Friend _anna() => Friend(
      id: 'a',
      name: 'Anna',
      birthDate: DateTime(1990, 5, 1),
      createdDate: DateTime(2026),
      lastUpdated: DateTime(2026),
    );

Future<void> _pump(WidgetTester tester, {String lang = 'en'}) async {
  await tester.pumpWidget(MaterialApp(
    locale: Locale(lang),
    supportedLocales: const [Locale('en'), Locale('de')],
    localizationsDelegates: const [
      AppLocalizationsDelegate(),
      ...GlobalMaterialLocalizations.delegates,
    ],
    home: const FriendsImportExportScreen(),
  ));
  await tester.pump();
}

void main() {
  late _FakeFilePicker picker;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await FriendsService.clearCacheForTesting();
    CompassService.clearCacheForTesting();
    picker = _FakeFilePicker();
    FilePickerPlatform.instance = picker;
  });

  test('backup file name carries the date', () {
    expect(backupFileName(DateTime(2026, 3, 7, 22)), 'memento_backup_2026-03-07.json');
  });

  testWidgets('save to device writes the backup and reports it', (tester) async {
    await FriendsService.addFriend(_anna());
    picker.savedTo = Uri.parse('content://downloads/1');
    await _pump(tester);
    await tester.tap(find.text('Save to device'));
    await tester.pumpAndSettle();

    expect(picker.savedName, startsWith('memento_backup_'));
    expect(picker.savedMime, 'application/json');
    final decoded = FriendsService.decodeBackup(utf8.decode(picker.savedBytes!));
    expect(decoded.single.name, 'Anna');
    expect(find.text('Exported 1 person'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
  });

  testWidgets('cancelling the save dialog shows no success', (tester) async {
    await FriendsService.addFriend(_anna());
    await _pump(tester);
    await tester.tap(find.text('Save to device'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Exported'), findsNothing);
    expect(find.text('Export cancelled'), findsOneWidget);
  });

  testWidgets('import result is shown once', (tester) async {
    picker.pickedJson = FriendsService.encodeBackup([_anna()]);
    await _pump(tester);
    await tester.tap(find.text('Import people'));
    // The progress bar runs while the dialog is open: pump, don't settle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.widgetWithText(FilledButton, 'Import'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Import completed: 1 added'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(picker.cleared, 1, reason: 'picked backup copy removed');
  });

  testWidgets('a cancelled backup pick also clears the picker cache',
      (tester) async {
    await _pump(tester);
    await tester.tap(find.text('Import people'));
    await tester.pumpAndSettle();
    expect(find.text('No file selected'), findsOneWidget);
    expect(picker.cleared, 1);
  });

  testWidgets('German wording says Personen, not Freunde', (tester) async {
    await _pump(tester, lang: 'de');
    expect(find.text('Auf Gerät speichern'), findsOneWidget);
    expect(find.text('Personen importieren'), findsOneWidget);
    expect(find.textContaining('Freund'), findsNothing);
  });

  group('Compass data', () {
    CompassData compass() => CompassData(
          intentions: [
            Intention(id: 'i', title: 'Call Mum', createdAt: DateTime(2026)),
          ],
          moments: [
            Moment(id: 'm', title: 'Hike', date: DateTime(2025, 6, 1)),
          ],
        );

    testWidgets('a Compass-only export names moments, not 0 people',
        (tester) async {
      await CompassService.addMoment(title: 'Hike', date: DateTime(2025));
      picker.savedTo = Uri.parse('content://downloads/1');
      await _pump(tester);
      await tester.tap(find.text('Save to device'));
      await tester.pumpAndSettle();
      expect(find.text('Exported 1 moment'), findsOneWidget);
      expect(find.textContaining('0 people'), findsNothing);
    });

    testWidgets('people and Compass data are both listed', (tester) async {
      await FriendsService.addFriend(_anna());
      await CompassService.importData(compass());
      picker.savedTo = Uri.parse('content://downloads/1');
      await _pump(tester);
      await tester.tap(find.text('Save to device'));
      await tester.pumpAndSettle();
      expect(find.text('Exported 1 person, 1 intention and 1 moment'),
          findsOneWidget);
    });

    testWidgets('a Compass-only import reports the new entries',
        (tester) async {
      picker.pickedJson = FriendsService.encodeBackup([], compass: compass());
      await _pump(tester);
      await tester.tap(find.text('Import people'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Found 1 intention and 1 moment to import.'),
          findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Import'));
      await tester.pumpAndSettle();
      expect(find.text('Compass: added 1 intention and 1 moment'),
          findsOneWidget);
      expect(find.textContaining('Import completed'), findsNothing);
    });

    List<LifePhase> phases(int n) => [
          for (var i = 0; i < n; i++)
            LifePhase(id: 'p$i', name: 'Phase $i', start: DateTime(2000 + i)),
        ];

    testWidgets('the descriptions mention the Compass', (tester) async {
      await _pump(tester, lang: 'de');
      expect(
          find.textContaining(
              'Kompasses: Vorhaben, Momente und Lebensphasen'),
          findsOneWidget);
      expect(find.textContaining('Personen und Kompass-Daten'), findsOneWidget);
    });

    testWidgets('an export counts the life phases', (tester) async {
      await FriendsService.addFriend(_anna());
      await CompassService.importData(CompassData(phases: phases(5)));
      picker.savedTo = Uri.parse('content://downloads/1');
      await _pump(tester, lang: 'de');
      await tester.tap(find.text('Auf Gerät speichern'));
      await tester.pumpAndSettle();
      expect(find.text('Exportiert: 1 Person und 5 Lebensphasen'),
          findsOneWidget);
    });

    testWidgets('an import reports the new life phases', (tester) async {
      picker.pickedJson = FriendsService.encodeBackup([],
          compass: CompassData(phases: phases(5), moments: compass().moments));
      await _pump(tester, lang: 'de');
      await tester.tap(find.text('Personen importieren'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Zum Importieren gefunden: 1 Moment und 5 Lebensphasen.'),
          findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Importieren'));
      await tester.pumpAndSettle();
      expect(find.text('Kompass: 1 Moment und 5 Lebensphasen hinzugefügt'),
          findsOneWidget);
    });

    testWidgets('an import with nothing new says so', (tester) async {
      await CompassService.importData(compass());
      picker.pickedJson = FriendsService.encodeBackup([], compass: compass());
      await _pump(tester);
      await tester.tap(find.text('Import people'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.widgetWithText(FilledButton, 'Import'));
      await tester.pumpAndSettle();
      expect(find.text('Compass: 0 new entries added'), findsOneWidget);
    });
  });
}
