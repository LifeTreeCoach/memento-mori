import 'dart:async';
import 'dart:convert';

import 'package:device_calendar_plus/device_calendar_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:memento_mori_life_in_weeks/calendar/serial_debouncer.dart';
import 'package:memento_mori_life_in_weeks/reminders/birthday_reminder_scheduler.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/friends_service.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/security/personal_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CalendarSyncStatus {
  notConfigured,
  syncing,
  synced,
  error,
}

class CalendarEvent {
  final String eventId;
  final String friendId;
  final String calendarId;
  final String title;
  final DateTime date;
  final bool isRecurring;
  final DateTime createdDate;
  final DateTime lastSynced;

  /// [CalendarService.eventSignature] of the synced content; null for
  /// events stored before signatures existed.
  final String? signature;

  const CalendarEvent({
    required this.eventId,
    required this.friendId,
    required this.calendarId,
    required this.title,
    required this.date,
    this.isRecurring = true,
    required this.createdDate,
    required this.lastSynced,
    this.signature,
  });

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'friendId': friendId,
      'calendarId': calendarId,
      'title': title,
      'date': date.millisecondsSinceEpoch,
      'isRecurring': isRecurring,
      'createdDate': createdDate.millisecondsSinceEpoch,
      'lastSynced': lastSynced.millisecondsSinceEpoch,
      if (signature != null) 'signature': signature,
    };
  }

  factory CalendarEvent.fromMap(Map<String, dynamic> map) {
    return CalendarEvent(
      eventId: map['eventId'] ?? '',
      friendId: map['friendId'] ?? '',
      calendarId: map['calendarId'] ?? '',
      title: map['title'] ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      isRecurring: map['isRecurring'] ?? true,
      createdDate: DateTime.fromMillisecondsSinceEpoch(map['createdDate']),
      lastSynced: DateTime.fromMillisecondsSinceEpoch(map['lastSynced']),
      signature: map['signature'] as String?,
    );
  }
}

class CalendarService {
  static final DeviceCalendar _deviceCalendar = DeviceCalendar.instance;

  static bool _hasPermissions = false;
  static List<Calendar> _availableCalendars = [];
  static String? _selectedCalendarId;
  static CalendarSyncStatus _syncStatus = CalendarSyncStatus.notConfigured;
  static List<CalendarEvent> _syncedEvents = [];

  /// [_syncedEvents] grouped by friend id (in list order); rebuilt lazily
  /// after every change of [_syncedEvents] (see [_eventsChanged]).
  static Map<String, List<CalendarEvent>>? _eventsByFriendCache;
  static bool _skipImportedContacts = true;
  static bool _settingsLoaded = false;
  static bool _listeningToFriends = false;

  /// Serializes every calendar write and debounces automatic syncs.
  static final SerialDebouncer _serial = SerialDebouncer(_syncChangesLocked);

  static const String _calendarIdKey = 'calendar_sync_calendar_id';
  /// In the [PersonalStore]; the other calendar keys stay in
  /// SharedPreferences.
  static const String _syncedEventsKey = PersonalKeys.calendarSyncedEvents;

  /// True when the stored synced events could not be read this session:
  /// they are never overwritten then (see [_saveSyncSettings]) and nothing
  /// is synced (see [_syncFriends]), which would duplicate every event.
  static bool _syncedEventsUnreadable = false;

  /// Whether people imported from the device contacts are left out of the
  /// sync (default on: they usually already appear in the calendar through
  /// the system's contacts birthday calendar).
  static const String skipImportedContactsKey = 'calendar_skip_imported_contacts';

  /// Bumped when the sync status or the synced events change (e.g. after an
  /// automatic sync), so an open calendar screen can refresh.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  /// Keeps the calendar in step with the friend list: deleted friends lose
  /// their events right away, every other change (add, edit, undo, import)
  /// schedules an automatic sync. Call once at startup; [initialize] also
  /// attaches it.
  static void attachToFriendsService() {
    FriendsService.onFriendsRemoved = removeFriendBirthdays;
    if (_listeningToFriends) return;
    _listeningToFriends = true;
    FriendsService.revision.addListener(_onFriendsChanged);
  }

  static void _onFriendsChanged() => unawaited(requestSync());

  /// Schedules an automatic, incremental sync (debounced, serialized with
  /// every other calendar write); see [syncChanges]. Also call it after the
  /// app language changes, which retitles the events.
  static Future<void> requestSync() => _serial.request();

  /// Quiet time before an automatic sync starts.
  @visibleForTesting
  static set autoSyncDelay(Duration delay) => _serial.delay = delay;

  /// Completes once no automatic sync is waiting or running.
  @visibleForTesting
  static Future<void> get autoSyncIdle => _serial.idle;

  /// Forgets all in-memory state (tests start from fresh preferences).
  @visibleForTesting
  static Future<void> resetForTesting() async {
    await _serial.idle;
    _hasPermissions = false;
    _availableCalendars = [];
    _selectedCalendarId = null;
    _syncStatus = CalendarSyncStatus.notConfigured;
    _syncedEvents = [];
    _eventsChanged();
    _skipImportedContacts = true;
    _syncedEventsUnreadable = false;
    _settingsLoaded = false;
  }

  // Initialize calendar service and request permissions
  static Future<bool> initialize() async {
    attachToFriendsService();
    try {
      debugPrint('CalendarService: Initializing...');

      // Check, then request full access (sync reads, updates and deletes events)
      var status = await _deviceCalendar.hasPermissions();
      if (status != CalendarPermissionStatus.granted) {
        status = await _deviceCalendar.requestPermissions();
      }
      if (status == CalendarPermissionStatus.granted) _hasPermissions = true;

      if (_hasPermissions) {
        await _ensureSyncSettings();
        if (await _loadAvailableCalendars()) await _forgetMissingCalendar();
        debugPrint('CalendarService: Initialized successfully with ${_availableCalendars.length} calendars');
        return true;
      } else {
        debugPrint('CalendarService: No calendar permissions granted');
        return false;
      }
    } catch (e) {
      debugPrint('CalendarService: Initialization error: $e');
      return false;
    }
  }

  // Load available calendars from device; false when the list is unknown.
  static Future<bool> _loadAvailableCalendars() async {
    try {
      final calendars = await _deviceCalendar.listCalendars();
      _availableCalendars = calendars
          .where((calendar) => !calendar.readOnly) // Only writable calendars
          .toList();
      debugPrint('CalendarService: Found ${_availableCalendars.length} writable calendars');
      return true;
    } catch (e) {
      debugPrint('CalendarService: Error loading calendars: $e');
      return false;
    }
  }

  /// True when [selectedId] is set but no longer among [available] (e.g. the
  /// calendar was deleted in the system), so the selection must be dropped.
  static bool isSelectionStale(String? selectedId, Iterable<String?> available) =>
      selectedId != null && !available.contains(selectedId);

  /// Drops a selected calendar (and its event ids) that no longer exists.
  static Future<void> _forgetMissingCalendar() async {
    final selected = _selectedCalendarId;
    if (!isSelectionStale(selected, _availableCalendars.map((c) => c.id))) return;
    debugPrint('CalendarService: Selected calendar $selected no longer exists');
    _selectedCalendarId = null;
    _syncedEvents.removeWhere((e) => e.calendarId == selected);
    _eventsChanged();
    _setStatus(CalendarSyncStatus.notConfigured);
    await _saveSyncSettings();
  }

  /// Loads the persisted sync settings once; afterwards memory is the
  /// source of truth (every change is saved right away).
  static Future<void> _ensureSyncSettings() async {
    if (!_settingsLoaded) await _loadSyncSettings();
  }

  static void _setStatus(CalendarSyncStatus status) {
    _syncStatus = status;
    revision.value++;
  }

  // Load sync settings (selected calendar, synced event ids) from storage
  static Future<void> _loadSyncSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _selectedCalendarId = prefs.getString(_calendarIdKey);
      _syncedEvents = await _loadSyncedEvents();
      _eventsChanged();
      _skipImportedContacts = prefs.getBool(skipImportedContactsKey) ?? true;
      _syncStatus = _selectedCalendarId != null && _syncedEvents.isNotEmpty
          ? CalendarSyncStatus.synced
          : CalendarSyncStatus.notConfigured;
      _settingsLoaded = true;
    } catch (e) {
      debugPrint('CalendarService: Error loading sync settings (${e.runtimeType})');
    }
  }

  /// The synced events from the [PersonalStore] (re-read first); none, and
  /// [_syncedEventsUnreadable] set, when they cannot be read.
  static Future<List<CalendarEvent>> _loadSyncedEvents() async {
    _syncedEventsUnreadable = false;
    try {
      final store = PersonalStore.instance;
      await store.reload();
      final source = store.getString(_syncedEventsKey);
      if (source == null) return [];
      final events = _tryDecodeSyncedEvents(source);
      if (events != null) return events;
    } catch (e) {
      debugPrint('CalendarService: synced events unreadable (${e.runtimeType})');
    }
    debugPrint('CalendarService: synced events will not be saved this session');
    _syncedEventsUnreadable = true;
    return [];
  }

  // Save sync settings to storage
  static Future<void> _saveSyncSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final calendarId = _selectedCalendarId;
      if (calendarId == null) {
        await prefs.remove(_calendarIdKey);
      } else {
        await prefs.setString(_calendarIdKey, calendarId);
      }
      if (_settingsLoaded && !_syncedEventsUnreadable) {
        await PersonalStore.instance
            .setString(_syncedEventsKey, encodeSyncedEvents(_syncedEvents));
      }
    } catch (e) {
      debugPrint('CalendarService: Error saving sync settings (${e.runtimeType})');
    }
  }

  /// JSON of [events] as persisted.
  @visibleForTesting
  static String encodeSyncedEvents(List<CalendarEvent> events) =>
      jsonEncode(events.map((e) => e.toMap()).toList());

  /// Events persisted by [encodeSyncedEvents]; unreadable data yields none.
  @visibleForTesting
  static List<CalendarEvent> decodeSyncedEvents(String? source) {
    if (source == null) return [];
    return _tryDecodeSyncedEvents(source) ?? [];
  }

  /// Events persisted by [encodeSyncedEvents]; null when unreadable.
  static List<CalendarEvent>? _tryDecodeSyncedEvents(String source) {
    try {
      return (jsonDecode(source) as List)
          .map((e) => CalendarEvent.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('CalendarService: Ignoring unreadable synced events (${e.runtimeType})');
      return null;
    }
  }

  /// Drops the per-friend index after [_syncedEvents] changed.
  static void _eventsChanged() => _eventsByFriendCache = null;

  /// The synced events of [friendId], in [_syncedEvents] order.
  static List<CalendarEvent> _eventsOf(String friendId) =>
      (_eventsByFriendCache ??= _indexByFriend(_syncedEvents))[friendId] ?? const [];

  static Map<String, List<CalendarEvent>> _indexByFriend(List<CalendarEvent> events) {
    final index = <String, List<CalendarEvent>>{};
    for (final event in events) {
      (index[event.friendId] ??= []).add(event);
    }
    return index;
  }

  // Public getters
  static bool get hasPermissions => _hasPermissions;
  static List<Calendar> get availableCalendars => List.unmodifiable(_availableCalendars);
  static String? get selectedCalendarId => _selectedCalendarId;
  static CalendarSyncStatus get syncStatus => _syncStatus;

  /// Whether people imported from contacts are left out (see
  /// [skipImportedContactsKey]). Valid once the settings are loaded
  /// ([initialize], a sync or [getSyncStats]); see [loadSkipImportedContacts].
  static bool get skipImportedContacts => _skipImportedContacts;

  /// Loads the persisted settings and returns [skipImportedContacts].
  static Future<bool> loadSkipImportedContacts() async {
    await _ensureSyncSettings();
    return _skipImportedContacts;
  }

  /// Saves the choice and syncs right away (when a calendar is selected and
  /// access is granted): turning it on deletes the events of people imported
  /// from contacts, turning it off creates them.
  static Future<void> setSkipImportedContacts(bool skip) => _serial.run(() async {
        await _ensureSyncSettings();
        _skipImportedContacts = skip;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(skipImportedContactsKey, skip);
        revision.value++;
        await _syncChangesLocked();
      });

  /// Whether [friend] is left out of the sync because it was imported from
  /// the device contacts and [skipImportedContacts] is on.
  static bool isSkippedFriend(Friend friend) =>
      isSkippedBySetting(friend, skipImportedContacts: _skipImportedContacts);

  /// Pure rule behind [isSkippedFriend].
  @visibleForTesting
  static bool isSkippedBySetting(Friend friend, {required bool skipImportedContacts}) =>
      skipImportedContacts && friend.importSource == Friend.importSourceContacts;

  /// Selects the calendar for the birthday sync and syncs right away (when
  /// access is granted): creates the missing events and moves those in a
  /// previously selected calendar into this one.
  static Future<bool> selectCalendar(String calendarId) =>
      _serial.run(() => _selectCalendarLocked(calendarId));

  static Future<bool> _selectCalendarLocked(String calendarId) async {
    try {
      if (!_availableCalendars.any((cal) => cal.id == calendarId)) {
        throw Exception('Calendar not found');
      }

      _selectedCalendarId = calendarId;
      await _saveSyncSettings();
      revision.value++;
      debugPrint('CalendarService: Calendar selected');

      await _syncChangesLocked();
      return true;
    } catch (e) {
      debugPrint('CalendarService: Error selecting calendar: $e');
      return false;
    }
  }

  /// Manual full resync: removes events of deleted friends and creates or
  /// updates every friend's event in the selected calendar.
  static Future<bool> syncAllBirthdays() => _serial.run(() async {
        await _ensureSyncSettings();
        if (_selectedCalendarId == null) {
          debugPrint('CalendarService: No calendar selected for sync');
          return false;
        }
        return _syncFriends(await FriendsService.getAllFriends(), onlyPending: false);
      });

  /// Incremental sync (what [requestSync] runs, but right away): creates
  /// missing events, updates changed ones (name, birth date, language) and
  /// deletes those of removed friends. Does nothing unless a calendar is
  /// selected and access is granted; never asks for permission.
  static Future<void> syncChanges() => _serial.run(_syncChangesLocked);

  static Future<void> _syncChangesLocked() async {
    if (!await _readyForAutoSync()) return;
    await _syncFriends(await FriendsService.getAllFriends(), onlyPending: true);
  }

  /// True when a calendar is selected (and still exists) and calendar
  /// access is granted. Only checks the permission, never requests it: a
  /// revoked permission shows on the calendar screen instead.
  static Future<bool> _readyForAutoSync() async {
    await _ensureSyncSettings();
    if (_selectedCalendarId == null) return false;
    final status = await _deviceCalendar.hasPermissions();
    _hasPermissions = status == CalendarPermissionStatus.granted;
    if (!_hasPermissions) {
      debugPrint('CalendarService: No calendar access, automatic sync skipped');
      revision.value++;
      return false;
    }
    if (await _loadAvailableCalendars()) await _forgetMissingCalendar();
    return _selectedCalendarId != null;
  }

  /// Removes events of friends no longer in [friends] or skipped
  /// ([isSkippedFriend]), then creates or updates the events of all active,
  /// not skipped [friends] (or only of those whose event is missing or out
  /// of date, with [onlyPending]).
  static Future<bool> _syncFriends(List<Friend> friends, {required bool onlyPending}) async {
    if (_syncedEventsUnreadable) {
      // Without the stored events every friend would look unsynced and get
      // a second event, every session.
      debugPrint('CalendarService: synced events unreadable, sync skipped');
      _setStatus(CalendarSyncStatus.error);
      return false;
    }
    try {
      _setStatus(CalendarSyncStatus.syncing);
      final kept = friends.where((f) => !isSkippedFriend(f));
      await _removeOrphanedEvents(kept.map((f) => f.id).toSet());
      final toSync = kept.where((f) => f.isActive && !(onlyPending && isFriendSynced(f)));
      var errorCount = 0;
      for (final friend in toSync.toList()) {
        if (!await _syncFriendBirthday(friend)) errorCount++;
      }
      _setStatus(errorCount == 0 ? CalendarSyncStatus.synced : CalendarSyncStatus.error);
      await _saveSyncSettings();
      debugPrint('CalendarService: Sync completed - Errors: $errorCount');
      return errorCount == 0;
    } catch (e) {
      debugPrint('CalendarService: Sync error: $e');
      _setStatus(CalendarSyncStatus.error);
      return false;
    }
  }

  /// Whether [friend]'s event exists in the selected calendar with the
  /// content [friend] (in the current app language) calls for.
  static bool isFriendSynced(Friend friend) {
    final l10n = BirthdayReminderScheduler.currentLocalizations();
    return _eventsOf(friend.id).any((event) =>
        event.calendarId == _selectedCalendarId &&
        isEventCurrent(event, friend, l10n));
  }

  /// Whether the stored [event] still matches [friend]'s current event
  /// content; events stored without a signature compare title and day.
  @visibleForTesting
  static bool isEventCurrent(CalendarEvent event, Friend friend, AppLocalizations l10n) {
    final details = birthdayEventDetails(friend, l10n);
    final signature = event.signature;
    if (signature != null) return signature == eventSignature(friend, details);
    return event.title == details.title &&
        event.date.month == details.start.month &&
        event.date.day == details.start.day;
  }

  /// What a synced event depends on: title, description and the birthday's
  /// month and day (not the next occurrence, which moves every year).
  static String eventSignature(Friend friend, BirthdayEventDetails details) =>
      '${details.title}\n${details.description}\n'
      '${friend.birthDate.month}-${friend.birthDate.day}';

  // Sync individual friend's birthday
  static Future<bool> _syncFriendBirthday(Friend friend) async {
    if (_selectedCalendarId == null) return false;

    try {
      // Check if event already exists
      final existingEvents = _eventsOf(friend.id);

      if (existingEvents.isNotEmpty) {
        final existingEvent = existingEvents.first;
        // Update existing event
        return await _updateBirthdayEvent(friend, existingEvent);
      } else {
        // Create new event
        return await _createBirthdayEvent(friend);
      }
    } catch (e) {
      // Event doesn't exist, create new one
      return await _createBirthdayEvent(friend);
    }
  }

  // Create birthday event in calendar
  static Future<bool> _createBirthdayEvent(Friend friend) async {
    if (_selectedCalendarId == null) return false;

    try {
      final details =
          birthdayEventDetails(friend, BirthdayReminderScheduler.currentLocalizations());
      final eventId = await _deviceCalendar.createEvent(
        calendarId: _selectedCalendarId,
        title: details.title,
        description: details.description,
        startDate: details.start,
        endDate: details.end,
        isAllDay: true,
        recurrenceRule: details.recurrence,
        reminders: const [birthdayReminderLeadTime],
      );

      _syncedEvents.add(CalendarEvent(
        eventId: eventId,
        friendId: friend.id,
        calendarId: _selectedCalendarId!,
        title: details.title,
        date: details.start,
        isRecurring: true,
        createdDate: DateTime.now(),
        lastSynced: DateTime.now(),
        signature: eventSignature(friend, details),
      ));
      _eventsChanged();
      await _saveSyncSettings();
      debugPrint('CalendarService: Created birthday event');
      return true;
    } catch (e) {
      debugPrint('CalendarService: Error creating birthday event (${e.runtimeType})');
      return false;
    }
  }

  // Update existing birthday event; recreates it when it no longer exists
  // or lives in a calendar other than the selected one.
  static Future<bool> _updateBirthdayEvent(Friend friend, CalendarEvent existingEvent) async {
    try {
      if (existingEvent.calendarId != _selectedCalendarId) {
        await _deleteCalendarEvent(existingEvent.eventId);
        return await _recreateBirthdayEvent(friend, existingEvent);
      }

      // A bare series id reads the event row itself (no occurrence expansion).
      final event = await _deviceCalendar.getEvent(existingEvent.eventId);
      if (event == null) {
        // Deleted outside the app: create it anew.
        return await _recreateBirthdayEvent(friend, existingEvent);
      }

      // Update details, dates and recurrence of the whole series from the
      // current birth date; the series' reminders stay as they are.
      final details =
          birthdayEventDetails(friend, BirthdayReminderScheduler.currentLocalizations());
      await _deviceCalendar.updateRecurring(
        existingEvent.eventId,
        EventSpan.allEvents,
        title: details.title,
        description: Patch.set(details.description),
        start: details.start,
        duration: details.end.difference(details.start),
        isAllDay: true,
        recurrenceRule: Patch.set(details.recurrence),
      );

      final index = _syncedEvents.indexWhere((e) => e.eventId == existingEvent.eventId);
      if (index != -1) {
        _syncedEvents[index] = existingEvent.copyWith(
          title: details.title,
          date: details.start,
          lastSynced: DateTime.now(),
          signature: eventSignature(friend, details),
        );
        _eventsChanged();
        await _saveSyncSettings();
      }
      debugPrint('CalendarService: Updated birthday event');
      return true;
    } catch (e) {
      debugPrint('CalendarService: Error updating birthday event (${e.runtimeType})');
      return false;
    }
  }

  /// Forgets the stale [existingEvent] and creates a new event for [friend].
  static Future<bool> _recreateBirthdayEvent(Friend friend, CalendarEvent existingEvent) async {
    _syncedEvents.removeWhere((e) => e.eventId == existingEvent.eventId);
    _eventsChanged();
    await _saveSyncSettings();
    return _createBirthdayEvent(friend);
  }

  /// Deletes the synced events of [friendIds] (e.g. deleted friends).
  static Future<void> removeFriendBirthdays(List<String> friendIds) =>
      _serial.run(() => _removeFriendBirthdaysLocked(friendIds));

  static Future<void> _removeFriendBirthdaysLocked(List<String> friendIds) async {
    await _ensureSyncSettings();
    final ids = friendIds.toSet();
    final toRemove = _syncedEvents.where((e) => ids.contains(e.friendId)).toList();
    if (toRemove.isEmpty) return;

    for (final event in toRemove) {
      if (!await _deleteCalendarEvent(event.eventId)) {
        debugPrint('CalendarService: Could not delete event ${event.eventId}');
      }
    }
    _syncedEvents.removeWhere((e) => ids.contains(e.friendId));
    _eventsChanged();
    await _saveSyncSettings();
    revision.value++;
  }

  /// Deletes the whole birthday series [eventId]; an event that is already
  /// gone counts as deleted. Returns false (and logs) on any other failure.
  static Future<bool> _deleteCalendarEvent(String eventId) async {
    try {
      await _deviceCalendar.deleteRecurring(eventId, EventSpan.allEvents);
      return true;
    } on DeviceCalendarException catch (e) {
      if (e.errorCode == DeviceCalendarError.notFound) return true;
      debugPrint('CalendarService: Error deleting event $eventId: $e');
      return false;
    } catch (e) {
      debugPrint('CalendarService: Error deleting event $eventId: $e');
      return false;
    }
  }

  /// Removes the synced event of a single deleted friend.
  static Future<void> removeFriendBirthday(String friendId) =>
      removeFriendBirthdays([friendId]);

  /// Deletes events whose friend no longer exists (deleted while unhooked)
  /// or is no longer synced (skipped); [existingFriendIds] keep theirs.
  static Future<void> _removeOrphanedEvents(Set<String> existingFriendIds) {
    final orphanIds = _syncedEvents
        .map((e) => e.friendId)
        .where((id) => !existingFriendIds.contains(id))
        .toSet()
        .toList();
    return _removeFriendBirthdaysLocked(orphanIds);
  }

  // Clear all synced birthday events
  static Future<bool> clearAllBirthdayEvents() => _serial.run(_clearAllLocked);

  static Future<bool> _clearAllLocked() async {
    try {
      int successCount = 0;
      int errorCount = 0;

      for (final event in List<CalendarEvent>.from(_syncedEvents)) {
        if (await _deleteCalendarEvent(event.eventId)) {
          successCount++;
        } else {
          errorCount++;
        }
      }

      _syncedEvents.clear();
      _eventsChanged();
      _selectedCalendarId = null;
      _setStatus(CalendarSyncStatus.notConfigured);
      await _saveSyncSettings();

      debugPrint('CalendarService: Cleared all events - Success: $successCount, Errors: $errorCount');
      return errorCount == 0;
    } catch (e) {
      debugPrint('CalendarService: Error clearing all events: $e');
      return false;
    }
  }

  /// Active friends (`totalFriends`), those whose event is current
  /// ([isFriendSynced], `syncedFriends`), the pending rest
  /// (`unsyncedFriends`), those left out by [isSkippedFriend]
  /// (`skippedFriends`, neither synced nor pending, so
  /// total = synced + unsynced + skipped) and the number of events the app
  /// keeps (`events`).
  static Future<Map<String, int>> getSyncStats() async {
    await _ensureSyncSettings();
    final friends = (await FriendsService.getAllFriends()).where((f) => f.isActive);
    final skippedFriends = friends.where(isSkippedFriend).length;
    final syncedFriends = friends.where((f) => !isSkippedFriend(f) && isFriendSynced(f)).length;
    return {
      'totalFriends': friends.length,
      'syncedFriends': syncedFriends,
      'unsyncedFriends': friends.length - skippedFriends - syncedFriends,
      'skippedFriends': skippedFriends,
      'events': _syncedEvents.length,
    };
  }

  // Refresh calendar data
  static Future<void> refresh() async {
    if (_hasPermissions) {
      await _ensureSyncSettings();
      if (await _loadAvailableCalendars()) await _forgetMissingCalendar();
    }
  }

  /// Title of [friend]'s yearly birthday event (age-free, as it recurs).
  static String formatEventTitle(Friend friend, AppLocalizations l10n) =>
      l10n.translate('calendar_event_title', replacements: {'name': friend.name});

  /// Description of [friend]'s yearly birthday event ("Born 1990"; without
  /// a birth year only the "synced by" line).
  static String formatEventDescription(Friend friend, AppLocalizations l10n) =>
      friend.hasBirthYear
          ? l10n.translate('calendar_event_description',
              replacements: {'year': '${friend.birthDate.year}'})
          : l10n.translate('calendar_event_description_noyear');

  /// Lead time of the reminder on a newly created birthday event (the day
  /// before, at the start of the all-day event).
  static const Duration birthdayReminderLeadTime = Duration(days: 1);

  /// Start and (exclusive) end of an all-day event on the calendar day of
  /// [date]: local midnight of that day and of the next one.
  /// device_calendar_plus treats all-day events as floating dates on both
  /// platforms (Android stores them at UTC midnight, EventKit through the
  /// last second of the day) and converts them itself, so the same bounds
  /// work everywhere; on Android a recurring row gets a one-day DURATION.
  static (DateTime, DateTime) allDayBounds(DateTime date) => (
        DateTime(date.year, date.month, date.day),
        DateTime(date.year, date.month, date.day + 1),
      );

  /// Title, description, all-day dates (next birthday) and yearly recurrence
  /// of [friend]'s birthday event from the friend's current data.
  static BirthdayEventDetails birthdayEventDetails(
    Friend friend,
    AppLocalizations l10n, {
    DateTime? today,
  }) {
    final (start, end) = allDayBounds(friend.getNextBirthday(today: today));
    return BirthdayEventDetails(
      title: formatEventTitle(friend, l10n),
      description: formatEventDescription(friend, l10n),
      start: start,
      end: end,
      recurrence: YearlyRecurrence(),
    );
  }
}

/// What a synced birthday event contains (see
/// [CalendarService.birthdayEventDetails]).
@immutable
class BirthdayEventDetails {
  const BirthdayEventDetails({
    required this.title,
    required this.description,
    required this.start,
    required this.end,
    required this.recurrence,
  });

  final String title;
  final String description;

  /// Local midnight of the next birthday.
  final DateTime start;

  /// Exclusive end: local midnight of the day after [start].
  final DateTime end;

  /// Yearly on the day of [start].
  final RecurrenceRule recurrence;
}

// Extension for CalendarEvent copyWith method
extension CalendarEventCopyWith on CalendarEvent {
  CalendarEvent copyWith({
    String? eventId,
    String? friendId,
    String? calendarId,
    String? title,
    DateTime? date,
    bool? isRecurring,
    DateTime? createdDate,
    DateTime? lastSynced,
    String? signature,
  }) {
    return CalendarEvent(
      eventId: eventId ?? this.eventId,
      friendId: friendId ?? this.friendId,
      calendarId: calendarId ?? this.calendarId,
      title: title ?? this.title,
      date: date ?? this.date,
      isRecurring: isRecurring ?? this.isRecurring,
      createdDate: createdDate ?? this.createdDate,
      lastSynced: lastSynced ?? this.lastSynced,
      signature: signature ?? this.signature,
    );
  }
}