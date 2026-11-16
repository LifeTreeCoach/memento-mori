import 'package:device_calendar_plus_platform_interface/device_calendar_plus_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/calendar/calendar_service.dart';
import 'package:memento_mori_life_in_weeks/calendar/calendar_settings_screen.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/friends_service.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-memory stand-in for the native device_calendar_plus side.
class _FakeCalendarPlatform extends DeviceCalendarPlusPlatform
    with MockPlatformInterfaceMixin {
  final events = <String, Map<String, dynamic>>{};
  final calls = <String>[];
  String permission = 'granted';
  bool failCreates = false;
  int _nextId = 1;

  @override
  Future<String?> hasPermissions() async => permission;

  @override
  Future<String?> requestPermissions(bool writeOnly) async {
    calls.add('request permission');
    return permission;
  }

  @override
  Future<List<Map<String, dynamic>>> listCalendars() async => [
        {'id': 'cal', 'name': 'Local', 'readOnly': false, 'accountName': 'local'},
        {'id': 'ro', 'name': 'Holidays', 'readOnly': true},
        ...extraCalendars,
      ];

  /// Further calendars a test adds (e.g. a second writable one).
  final extraCalendars = <Map<String, dynamic>>[];

  @override
  Future<String> createEvent(
    String? calendarId,
    String title,
    DateTime startDate,
    DateTime endDate,
    bool isAllDay,
    String? description,
    String? location,
    String? url,
    String? timeZone,
    String availability,
    String? recurrenceRule,
    List<int>? reminders, {
    EventOptionsAndroid? android,
  }) async {
    if (failCreates) throw PlatformException(code: 'UNKNOWN', message: 'create failed');
    final id = '${_nextId++}';
    calls.add('create $id');
    events[id] = {
      'eventId': id,
      'instanceId': id,
      'calendarId': calendarId,
      'title': title,
      'description': description,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'isAllDay': isAllDay,
      'availability': availability,
      'status': 'confirmed',
      'isRecurring': recurrenceRule != null,
      'recurrenceRule': recurrenceRule,
      'reminders': reminders,
    };
    return id;
  }

  @override
  Future<Map<String, dynamic>?> getEvent(String eventId, int? timestamp) async =>
      events[eventId];

  @override
  Future<String> updateRecurring(
    String eventId,
    int? timestamp,
    String span, {
    String? title,
    DateTime? start,
    int? durationMinutes,
    Patch<String>? description,
    Patch<String>? location,
    Patch<String>? url,
    bool? isAllDay,
    String? timeZone,
    String? availability,
    Patch<String>? recurrenceRule,
    Patch<List<int>>? reminders,
    EventUpdateOptionsAndroid? android,
  }) async {
    calls.add('update $eventId $span');
    final event = events[eventId]!;
    if (title != null) event['title'] = title;
    if (start != null) {
      event['startDate'] = start.millisecondsSinceEpoch;
      event['endDate'] =
          start.add(Duration(minutes: durationMinutes!)).millisecondsSinceEpoch;
    }
    if (description case PatchSet(:final value)) event['description'] = value;
    if (recurrenceRule case PatchSet(:final value)) event['recurrenceRule'] = value;
    if (isAllDay != null) event['isAllDay'] = isAllDay;
    return eventId;
  }

  @override
  Future<void> deleteRecurring(String eventId, int? timestamp, String span) async {
    calls.add('delete $eventId $span');
    if (events.remove(eventId) == null) {
      throw PlatformException(code: 'NOT_FOUND', message: 'no event $eventId');
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

Friend _friend(String id, String name, DateTime birthDate) {
  final now = DateTime(2026, 1, 1);
  return Friend(
    id: id,
    name: name,
    birthDate: birthDate,
    createdDate: now,
    lastUpdated: now,
  );
}

DateTime _start(Map<String, dynamic> event) =>
    DateTime.fromMillisecondsSinceEpoch(event['startDate'] as int);

DateTime _end(Map<String, dynamic> event) =>
    DateTime.fromMillisecondsSinceEpoch(event['endDate'] as int);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _FakeCalendarPlatform platform;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'language': 'en'});
    await SettingsService.initialize();
    await FriendsService.clearCacheForTesting();
    platform = _FakeCalendarPlatform();
    DeviceCalendarPlusPlatform.instance = platform;
    await CalendarService.resetForTesting();
    CalendarService.autoSyncDelay = Duration.zero;
  });

  tearDown(() async {
    await CalendarService.autoSyncIdle;
    FriendsService.onFriendsRemoved = null;
  });

  /// Grants access and selects the writable calendar (after any automatic
  /// sync a friend change before it scheduled).
  Future<void> setUpSync() async {
    await CalendarService.autoSyncIdle;
    expect(await CalendarService.initialize(), isTrue);
    expect(await CalendarService.selectCalendar('cal'), isTrue);
  }

  /// Sets up sync for [friends] with a full sync and forgets those calls.
  Future<void> setUpSyncedFriends(List<Friend> friends) async {
    await FriendsService.addFriends(friends);
    await setUpSync();
    expect(await CalendarService.syncAllBirthdays(), isTrue);
    platform.calls.clear();
  }

  Future<Map<String, int>> stats() => CalendarService.getSyncStats();

  test('lists only writable calendars once access is granted', () async {
    expect(await CalendarService.initialize(), isTrue);
    expect(CalendarService.hasPermissions, isTrue);
    expect(CalendarService.availableCalendars.map((c) => c.id), ['cal']);
  });

  test('creates a yearly all-day birthday event with a reminder a day ahead', () async {
    await FriendsService.addFriend(_friend('a', 'Anna', DateTime(1990, 5, 1)));
    await setUpSync();

    expect(await CalendarService.syncAllBirthdays(), isTrue);

    final event = platform.events.values.single;
    final next = _friend('a', 'Anna', DateTime(1990, 5, 1)).getNextBirthday();
    expect(event['calendarId'], 'cal');
    expect(event['title'], "🎂 Anna's birthday");
    expect(event['description'], startsWith('Born 1990'));
    expect(event['isAllDay'], isTrue);
    expect(event['recurrenceRule'], 'FREQ=YEARLY');
    expect(event['reminders'], [1440]);
    expect(_start(event), DateTime(next.year, next.month, next.day));
    expect(_end(event), DateTime(next.year, next.month, next.day + 1));
    expect(CalendarService.syncStatus, CalendarSyncStatus.synced);
  });

  test('a renamed friend updates the whole series in place', () async {
    await FriendsService.addFriend(_friend('a', 'Anna', DateTime(1990, 5, 1)));
    await setUpSync();

    await FriendsService.updateFriend(_friend('a', 'Annie', DateTime(1990, 8, 15)));
    await CalendarService.autoSyncIdle;

    expect(platform.calls, ['create 1', 'update 1 allEvents']);
    final event = platform.events['1']!;
    final next = _friend('a', 'Annie', DateTime(1990, 8, 15)).getNextBirthday();
    expect(event['title'], "🎂 Annie's birthday");
    expect(event['recurrenceRule'], 'FREQ=YEARLY');
    expect(_start(event), DateTime(next.year, next.month, next.day));
    expect(_end(event).difference(_start(event)).inHours, inInclusiveRange(23, 25));
  });

  test('an event deleted outside the app is created anew', () async {
    await FriendsService.addFriend(_friend('a', 'Anna', DateTime(1990, 5, 1)));
    await setUpSync();
    platform.events.clear();

    expect(await CalendarService.syncAllBirthdays(), isTrue);
    expect(platform.calls, ['create 1', 'create 2']);
    expect(platform.events.keys, ['2']);
  });

  test('deleting a friend deletes the whole series', () async {
    await FriendsService.addFriends([
      _friend('a', 'Anna', DateTime(1990, 5, 1)),
      _friend('b', 'Ben', DateTime(1985, 2, 3)),
    ]);
    await setUpSync();
    await CalendarService.syncAllBirthdays();

    await FriendsService.deleteFriend('a');

    expect(platform.calls.last, 'delete 1 allEvents');
    expect(platform.events.keys, ['2']);
    expect((await CalendarService.getSyncStats())['syncedFriends'], 1);
  });

  test('clearing counts an event that is already gone as removed', () async {
    await FriendsService.addFriend(_friend('a', 'Anna', DateTime(1990, 5, 1)));
    await setUpSync();
    await CalendarService.syncAllBirthdays();
    platform.events.clear();

    expect(await CalendarService.clearAllBirthdayEvents(), isTrue);
    expect(CalendarService.selectedCalendarId, isNull);
    expect(CalendarService.syncStatus, CalendarSyncStatus.notConfigured);
  });

  test('unreadable synced events: no sync and never overwritten that session',
      () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('calendar_synced_events', '{oops');
    await FriendsService.addFriend(_friend('a', 'Anna', DateTime(1990, 5, 1)));
    await setUpSync();

    expect(await CalendarService.syncAllBirthdays(), isFalse);
    await CalendarService.syncChanges();

    expect(platform.events, isEmpty);
    expect(CalendarService.syncStatus, CalendarSyncStatus.error);
    expect(prefs.getString('calendar_synced_events'), '{oops');
    expect(prefs.getString('calendar_sync_calendar_id'), 'cal');
  });

  test('readable synced events are saved', () async {
    await FriendsService.addFriend(_friend('a', 'Anna', DateTime(1990, 5, 1)));
    await setUpSync();
    await CalendarService.syncAllBirthdays();

    final prefs = await SharedPreferences.getInstance();
    final stored = CalendarService.decodeSyncedEvents(
        prefs.getString('calendar_synced_events'));
    expect(stored.single.friendId, 'a');
  });

  group('selecting a calendar', () {
    final anna = _friend('a', 'Anna', DateTime(1990, 5, 1));
    final ben = _friend('b', 'Ben', DateTime(1985, 2, 3));

    test('selecting a calendar syncs right away', () async {
      await FriendsService.addFriends([anna, ben]);
      await CalendarService.autoSyncIdle;
      expect(await CalendarService.initialize(), isTrue);
      final revision = CalendarService.revision.value;

      expect(await CalendarService.selectCalendar('cal'), isTrue);

      expect(platform.calls, ['create 1', 'create 2']);
      expect(platform.events.values.map((e) => e['calendarId']), ['cal', 'cal']);
      expect(await stats(), containsPair('unsyncedFriends', 0));
      expect(CalendarService.syncStatus, CalendarSyncStatus.synced);
      expect(CalendarService.revision.value, greaterThan(revision));
    });

    test('switching calendars moves the events', () async {
      platform.extraCalendars.add(
          {'id': 'other', 'name': 'Family', 'readOnly': false, 'accountName': 'local'});
      await setUpSyncedFriends([anna, ben]);

      expect(await CalendarService.selectCalendar('other'), isTrue);

      expect(platform.calls,
          ['delete 1 allEvents', 'create 3', 'delete 2 allEvents', 'create 4']);
      expect(platform.events.keys, ['3', '4']);
      expect(platform.events.values.map((e) => e['calendarId']), ['other', 'other']);
      expect(await stats(), containsPair('unsyncedFriends', 0));
    });

    test('without calendar access selecting syncs nothing and never asks', () async {
      await FriendsService.addFriend(anna);
      await setUpSync();
      platform.calls.clear();
      platform.events.clear();
      platform.permission = 'denied';

      expect(await CalendarService.selectCalendar('cal'), isTrue);

      expect(platform.calls, isEmpty);
      expect(platform.events, isEmpty);
    });
  });

  group('automatic sync', () {
    final anna = _friend('a', 'Anna', DateTime(1990, 5, 1));
    final ben = _friend('b', 'Ben', DateTime(1985, 2, 3));

    test('adding a friend creates the event without a manual sync', () async {
      await setUpSyncedFriends([anna]);

      await FriendsService.addFriend(ben);
      await CalendarService.autoSyncIdle;

      expect(platform.calls, ['create 2']);
      expect(platform.events['2']!['title'], "🎂 Ben's birthday");
      expect(await stats(), containsPair('unsyncedFriends', 0));
      expect(CalendarService.syncStatus, CalendarSyncStatus.synced);
    });

    test('renaming updates only that friend\'s title', () async {
      await setUpSyncedFriends([anna, ben]);

      await FriendsService.updateFriend(anna.copyWith(name: 'Annie'));
      await CalendarService.autoSyncIdle;

      expect(platform.calls, ['update 1 allEvents']);
      expect(platform.events['1']!['title'], "🎂 Annie's birthday");
      expect(platform.events['2']!['title'], "🎂 Ben's birthday");
    });

    test('a new birth date moves the event', () async {
      await setUpSyncedFriends([anna]);
      final moved = anna.copyWith(birthDate: DateTime(1991, 9, 20));

      await FriendsService.updateFriend(moved);
      await CalendarService.autoSyncIdle;

      final next = moved.getNextBirthday();
      expect(platform.calls, ['update 1 allEvents']);
      expect(_start(platform.events['1']!), DateTime(next.year, next.month, next.day));
      expect(platform.events['1']!['description'], startsWith('Born 1991'));
    });

    test('delete removes the event and undo brings it back', () async {
      await setUpSyncedFriends([anna, ben]);

      await FriendsService.deleteFriend('a');
      await CalendarService.autoSyncIdle;
      expect(platform.calls, ['delete 1 allEvents']);
      expect(platform.events.keys, ['2']);

      // Undo, as FriendActions does it: the same friend is added again.
      await FriendsService.addFriend(anna);
      await CalendarService.autoSyncIdle;
      expect(platform.calls, ['delete 1 allEvents', 'create 3']);
      expect(platform.events['3']!['title'], "🎂 Anna's birthday");
      expect(await stats(), containsPair('unsyncedFriends', 0));
    });

    test('imported friends get their events', () async {
      await setUpSyncedFriends([anna]);

      await FriendsService.importFriends([ben, _friend('c', 'Cleo', DateTime(2000, 1, 9))]);
      await CalendarService.autoSyncIdle;

      expect(platform.calls, ['create 2', 'create 3']);
      expect(await stats(), {
        'totalFriends': 3,
        'syncedFriends': 3,
        'unsyncedFriends': 0,
        'skippedFriends': 0,
        'events': 3,
      });
    });

    test('a language change retitles every event', () async {
      await setUpSyncedFriends([anna, ben]);

      SettingsService.setLanguage('de');
      expect(await stats(), containsPair('unsyncedFriends', 2));
      await CalendarService.requestSync();

      expect(platform.calls, ['update 1 allEvents', 'update 2 allEvents']);
      expect(platform.events['1']!['title'], '🎂 Geburtstag von Anna');
      expect(await stats(), containsPair('unsyncedFriends', 0));
    });

    test('does nothing while no calendar is selected', () async {
      await FriendsService.addFriend(anna);
      await FriendsService.updateFriend(anna.copyWith(name: 'Annie'));
      await CalendarService.autoSyncIdle;

      expect(platform.calls, isEmpty);
      expect(platform.events, isEmpty);
    });

    test('a revoked permission is not requested; changes stay pending', () async {
      await setUpSyncedFriends([anna]);
      platform.permission = 'denied';

      await FriendsService.addFriend(ben);
      await FriendsService.updateFriend(anna.copyWith(name: 'Annie'));
      await CalendarService.autoSyncIdle;

      expect(platform.calls, isEmpty);
      expect(CalendarService.hasPermissions, isFalse);
      expect(await stats(), containsPair('unsyncedFriends', 2));

      platform.permission = 'granted';
      await CalendarService.requestSync();
      expect(platform.calls, ['update 1 allEvents', 'create 2']);
      expect(await stats(), containsPair('unsyncedFriends', 0));
    });

    test('a burst of edits is coalesced into one sync', () async {
      await setUpSyncedFriends([]);
      CalendarService.autoSyncDelay = const Duration(milliseconds: 50);

      await FriendsService.addFriend(anna);
      for (final name in ['Ann', 'Annie', 'Anni']) {
        await FriendsService.updateFriend(anna.copyWith(name: name));
      }
      await CalendarService.autoSyncIdle;

      expect(platform.calls, ['create 1']);
      expect(platform.events['1']!['title'], "🎂 Anni's birthday");
    });

    test('rapid edits without debounce end consistent', () async {
      await setUpSyncedFriends([anna]);

      final edits = [
        for (final name in ['A1', 'A2', 'A3'])
          FriendsService.updateFriend(anna.copyWith(name: name)),
        FriendsService.addFriend(ben),
        FriendsService.deleteFriend('b'),
        FriendsService.addFriend(ben.copyWith(name: 'Benny')),
      ];
      await Future.wait(edits);
      await CalendarService.autoSyncIdle;

      final titles = platform.events.values.map((e) => e['title']).toSet();
      expect(titles, {"🎂 A3's birthday", "🎂 Benny's birthday"});
      expect(await stats(), containsPair('unsyncedFriends', 0));
      expect(CalendarService.syncStatus, CalendarSyncStatus.synced);
    });

    test('a failing write is reported as a sync error, then retried', () async {
      await setUpSyncedFriends([anna]);
      platform.events.clear();
      platform.failCreates = true;

      await FriendsService.updateFriend(anna.copyWith(name: 'Annie'));
      await CalendarService.autoSyncIdle;
      expect(CalendarService.syncStatus, CalendarSyncStatus.error);
      expect(await stats(), containsPair('unsyncedFriends', 1));

      platform.failCreates = false;
      await FriendsService.addFriend(ben);
      await CalendarService.autoSyncIdle;
      expect(CalendarService.syncStatus, CalendarSyncStatus.synced);
      expect(await stats(), containsPair('unsyncedFriends', 0));
    });
  });

  group('people imported from contacts', () {
    final anna = _friend('a', 'Anna', DateTime(1990, 5, 1));
    final carl = _friend('c', 'Carl', DateTime(1980, 7, 4))
        .copyWith(importSource: Friend.importSourceContacts);
    final vera = _friend('v', 'Vera', DateTime(1995, 3, 8))
        .copyWith(importSource: Friend.importSourceVcard);

    Set<Object?> syncedTitles() => platform.events.values.map((e) => e['title']).toSet();

    test('are skipped by default; vCard and manual people still sync', () async {
      await setUpSyncedFriends([anna, carl, vera]);

      expect(CalendarService.skipImportedContacts, isTrue);
      expect(syncedTitles(), {"🎂 Anna's birthday", "🎂 Vera's birthday"});
      expect(await stats(), {
        'totalFriends': 3,
        'syncedFriends': 2,
        'unsyncedFriends': 0,
        'skippedFriends': 1,
        'events': 2,
      });
    });

    test('people = synced + pending + skipped, with the setting on and off', () async {
      void expectCountsAddUp(Map<String, int> s) => expect(
          s['totalFriends'], s['syncedFriends']! + s['unsyncedFriends']! + s['skippedFriends']!);

      await setUpSyncedFriends([anna]);
      await FriendsService.importFriends([carl, vera]);
      // Vera is pending (no automatic sync ran yet), Carl skipped.
      final skipOn = await stats();
      expectCountsAddUp(skipOn);
      expect(skipOn['skippedFriends'], 1);

      await CalendarService.setSkipImportedContacts(false);
      final skipOff = await stats();
      expectCountsAddUp(skipOff);
      expect(skipOff['skippedFriends'], 0);
    });

    test('an automatic sync after a contacts import creates nothing', () async {
      await setUpSyncedFriends([anna]);

      await FriendsService.importFriends([carl]);
      await CalendarService.autoSyncIdle;

      expect(platform.calls, isEmpty);
      expect(await stats(), containsPair('unsyncedFriends', 0));
    });

    test('turning the setting off syncs them, turning it on removes them', () async {
      await setUpSyncedFriends([anna, carl]);

      await CalendarService.setSkipImportedContacts(false);
      expect(platform.calls, ['create 2']);
      expect(syncedTitles(), {"🎂 Anna's birthday", "🎂 Carl's birthday"});
      expect(await stats(), containsPair('skippedFriends', 0));

      platform.calls.clear();
      await CalendarService.setSkipImportedContacts(true);
      expect(platform.calls, ['delete 2 allEvents']);
      expect(syncedTitles(), {"🎂 Anna's birthday"});
      expect(await stats(), containsPair('events', 1));
    });

    test('the choice is persisted', () async {
      await CalendarService.setSkipImportedContacts(false);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(CalendarService.skipImportedContactsKey), isFalse);

      await CalendarService.resetForTesting();
      expect(await CalendarService.loadSkipImportedContacts(), isFalse);
    });

    test('the pure rule only skips contacts imports while on', () {
      bool skipped(Friend f, bool on) =>
          CalendarService.isSkippedBySetting(f, skipImportedContacts: on);
      expect(skipped(carl, true), isTrue);
      expect(skipped(carl, false), isFalse);
      expect(skipped(vera, true), isFalse);
      expect(skipped(anna, true), isFalse);
    });

    testWidgets('the calendar screen switch turns the setting off', (tester) async {
      await tester.runAsync(() => setUpSyncedFriends([anna, carl]));
      await tester.pumpWidget(const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: [
          AppLocalizationsDelegate(),
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: CalendarSettingsScreen(),
      ));
      await tester.pumpAndSettle();

      const skippedLine = '1\u00A0person left out – from your contacts';
      expect(find.text(skippedLine), findsOneWidget);

      final tile = find.widgetWithText(SwitchListTile, 'Leave out people from contacts');
      await tester.scrollUntilVisible(tile, 200);
      expect(tester.widget<SwitchListTile>(tile).value, isTrue);

      // Tap in the real zone, where the setup started the service's queue.
      await tester.runAsync(() async {
        await tester.tap(tile);
        await CalendarService.autoSyncIdle;
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });
      await tester.pump();

      expect(tester.widget<SwitchListTile>(tile).value, isFalse);
      expect(CalendarService.skipImportedContacts, isFalse);
      expect(syncedTitles(), contains("🎂 Carl's birthday"));
      expect(find.text(skippedLine), findsNothing);
    }, timeout: const Timeout(Duration(seconds: 30)));

    testWidgets('the calendar screen shows no skipped line when nobody is left out',
        (tester) async {
      await tester.runAsync(() => setUpSyncedFriends([anna, vera]));
      await tester.pumpWidget(const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: [
          AppLocalizationsDelegate(),
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: CalendarSettingsScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Pending'), findsOneWidget);
      expect(find.textContaining('left out – from your contacts'), findsNothing);
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
