import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/friends_service.dart';
import 'package:memento_mori_life_in_weeks/life/visualization_settings.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/people_import/birthday_candidate.dart';
import 'package:memento_mori_life_in_weeks/people_import/import_applier.dart';
import 'package:memento_mori_life_in_weeks/people_import/picked_contacts_source.dart';
import 'package:memento_mori_life_in_weeks/people_import/ui/import_services.dart';
import 'package:memento_mori_life_in_weeks/people_import/vcard_source.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:memento_mori_life_in_weeks/theme/app_theme.dart';
import 'package:memento_mori_life_in_weeks/theme/theme_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_contacts_source.dart';
import '../../support/tours_seen.dart';

final DateTime importToday = DateTime(2026, 11, 2);

/// Picker that reports [supported] and returns [picked] plus
/// [withoutBirthday] picked contacts without a birthday.
class FakePickedContactsSource extends PickedContactsSource {
  FakePickedContactsSource({
    this.supported = false,
    this.picked = const [],
    this.withoutBirthday = 0,
  });

  final bool supported;
  final List<BirthdayCandidate> picked;
  final int withoutBirthday;
  int pickCount = 0;

  @override
  Future<bool> isSupported() async => supported;

  @override
  Future<PickedContacts> pickContacts() async {
    pickCount++;
    return PickedContacts(candidates: picked, withoutBirthday: withoutBirthday);
  }
}

BirthdayCandidate contactCandidate(
  String name,
  int month,
  int day, {
  int? year,
  bool photo = false,
  ImportSource source = ImportSource.contacts,
}) {
  return BirthdayCandidate(
    id: 'contact:$name',
    displayName: name,
    month: month,
    day: day,
    year: year,
    source: source,
    sourceId: 'src-$name',
    photo: photo ? CandidatePhoto.memory(Uint8List.fromList([1, 2])) : null,
  );
}

Friend savedFriend(String name, DateTime birthDate, {bool hasYear = true}) {
  return Friend(
    id: 'id-$name',
    name: name,
    birthDate: birthDate,
    hasBirthYear: hasYear,
    createdDate: DateTime(2020),
    lastUpdated: DateTime(2020),
  );
}

/// Services with fakes; the applier saves no photos (no file system).
ImportServices fakeServices({
  FakeContactsSource? contacts,
  FakePickedContactsSource? picker,
  VCardSource? vcard,
  Future<bool> Function()? requestNotificationPermission,
}) {
  return ImportServices(
    contacts: contacts ?? FakeContactsSource(),
    picker: picker ?? FakePickedContactsSource(),
    vcard: vcard ?? VCardSource(pickFile: () async => null),
    applier: ImportApplier(
      resizePhoto: (_) async => null,
      now: () => importToday,
    ),
    requestNotificationPermission:
        requestNotificationPermission ?? () async => true,
    today: importToday,
  );
}

Future<void> initImportPrefs(List<Friend> friends) async {
  const visual = VisualizationSettings(enableAnimations: false);
  SharedPreferences.setMockInitialValues({
    'birth_date': DateTime(1990, 11, 17).toIso8601String(),
    'language': 'en',
    'visualization_settings': jsonEncode(visual.toMap()),
    'friends_data': jsonEncode([for (final f in friends) f.toMap()]),
    ...toursSeenPrefs,
  });
  await SettingsService.initialize();
  await FriendsService.clearCacheForTesting();
  await reloadTourProgress();
}

/// [home] in a localized app below an [ImportServicesScope].
Future<void> pumpImportApp(
  WidgetTester tester,
  Widget home, {
  required ImportServices services,
  String lang = 'en',
  Size size = const Size(393, 851),
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.build(
        style: ThemeStyle.stoic,
        brightness: Brightness.light,
      ),
      locale: Locale(lang),
      supportedLocales: [
        for (final code in AppLocalizations.supportedLanguages) Locale(code),
      ],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        ...GlobalMaterialLocalizations.delegates,
      ],
      home: ImportServicesScope(services: services, child: home),
    ),
  );
  await tester.pumpAndSettle();
}

/// Lets futures that run outside the fake clock (SharedPreferences,
/// FriendsService) finish, then settles the frames.
Future<void> settleAsync(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 20)),
  );
  await tester.pumpAndSettle();
}
