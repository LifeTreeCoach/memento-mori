import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/data/avatar_store.dart';
import 'package:memento_mori_life_in_weeks/data/backup_avatar.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/people/group_migration.dart';
import 'package:memento_mori_life_in_weeks/people/group_names.dart';

/// A friend read from a backup, with the photo embedded there (if any).
@immutable
class BackupEntry {
  const BackupEntry(this.friend, {this.avatar});

  final Friend friend;
  final BackupAvatar? avatar;
}

/// Everything read from a backup file: friends and (1.2+) Compass data.
@immutable
class BackupContents {
  const BackupContents(this.entries, {this.compass});

  final List<BackupEntry> entries;

  /// The `compass` section; null when the file has none (or it is empty).
  final CompassData? compass;
}

/// Invalid friends backup; [messageKey] is a localization key.
class FriendsBackupException implements Exception {
  const FriendsBackupException(this.messageKey);
  final String messageKey;

  @override
  String toString() => 'FriendsBackupException($messageKey)';
}

class FriendsService {
  static const String _friendsKey = 'friends_data';
  /// Legacy store of per-friend notification state; removed on load.
  static const String _legacyBirthdayNotificationsKey = 'birthday_notifications';
  static const String _birthdayNotificationsEnabledKey = 'birthday_notifications_enabled';
  /// 1.1 adds the optional embedded `avatar` per friend and drops the
  /// device-internal `avatarPath`; 1.2 adds the optional `compass` section
  /// ([CompassData] JSON); 1.3 adds life phases and the kind, phase, due
  /// date and let-go date of intentions to that section (older apps read a
  /// let-go intention as "Someday"); 1.4 adds birthdays without a year
  /// (`birthDate` `--MM-dd`, skipped by older apps as unreadable entries)
  /// and the optional `importSource` / `importSourceId` per friend; 1.5
  /// adds the optional per-person `lifespanEstimate` (answers incl. health
  /// conditions and the applied result), ignored by older apps.
  /// Readers accept every 1.x backup.
  static const String backupVersion = '1.5';

  /// Key of the Compass section in a backup.
  static const String backupCompassKey = 'compass';

  static List<Friend> _cachedFriends = [];
  static bool _isInitialized = false;
  static bool _birthdayNotificationsEnabled = true;

  /// Photos of people deleted in this session: kept on disk until the next
  /// start, so "Undo" brings the photo back too.
  static final Set<String> _avatarsDeletedThisSession = {};

  /// Called after any change that affects birthday reminders
  /// (friend added/updated/deleted/imported, global toggle changed).
  static Future<void> Function()? onFriendsChanged;

  /// Bumped after every change to the friend list, so screens kept alive in
  /// other tabs can reload (listen instead of polling on rebuild).
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  /// Called with the ids of deleted friends (single delete or clear-all),
  /// e.g. to remove their synced calendar events.
  static Future<void> Function(List<String> friendIds)? onFriendsRemoved;

  /// Initialize the service (call once at app startup)
  static Future<void> initialize() async {
    if (_isInitialized) return;

    await _loadFriends();
    await _removeLegacyBirthdayNotifications();
    await _loadBirthdayNotificationsEnabled();
    await _backfillNotificationIds();
    await _migrateGroupNames();
    _isInitialized = true;
  }

  /// Drops the in-memory cache so the next [initialize] re-reads storage.
  @visibleForTesting
  static Future<void> clearCacheForTesting() async {
    _cachedFriends = [];
    _avatarsDeletedThisSession.clear();
    _birthdayNotificationsEnabled = true;
    _isInitialized = false;
  }

  static Future<void> _removeLegacyBirthdayNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(_legacyBirthdayNotificationsKey)) {
      await prefs.remove(_legacyBirthdayNotificationsKey);
    }
  }

  static Future<void> _loadBirthdayNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    _birthdayNotificationsEnabled = prefs.getBool(_birthdayNotificationsEnabledKey) ?? true;
  }

  /// Once: typed "Family"/"Friends" groups become the predefined ids.
  static Future<void> _migrateGroupNames() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(GroupMigration.doneKey) ?? false) return;
    final migrated = GroupMigration.migrate(_cachedFriends);
    if (migrated != null) {
      _cachedFriends = migrated;
      await _saveFriends();
      revision.value++;
    }
    await prefs.setBool(GroupMigration.doneKey, true);
  }

  /// Assign a notification id to friends stored before ids existed (or with duplicates).
  static Future<void> _backfillNotificationIds() async {
    if (!_assignMissingNotificationIds()) return;
    await _saveFriends();
  }

  /// Returns true if any friend received a new notification id.
  static bool _assignMissingNotificationIds() {
    final usedIds = <int>{};
    bool changed = false;
    for (int i = 0; i < _cachedFriends.length; i++) {
      final id = _cachedFriends[i].notificationId;
      if (id > 0 && usedIds.add(id)) continue;
      final newId = nextNotificationId(usedIds);
      usedIds.add(newId);
      _cachedFriends[i] = _cachedFriends[i].copyWith(notificationId: newId);
      changed = true;
    }
    return changed;
  }

  /// Smallest positive id greater than all [usedIds].
  static int nextNotificationId(Iterable<int> usedIds) {
    return usedIds.fold<int>(0, (max, id) => id > max ? id : max) + 1;
  }

  static Future<void> _notifyRemoved(List<String> friendIds) async {
    final callback = onFriendsRemoved;
    if (callback == null || friendIds.isEmpty) return;
    try {
      await callback(friendIds);
    } catch (e) {
      debugPrint('Error in friends removal callback: $e');
    }
  }

  static Future<void> _notifyChanged() async {
    revision.value++;
    final callback = onFriendsChanged;
    if (callback == null) return;
    try {
      await callback();
    } catch (e) {
      debugPrint('Error in friends change callback: $e');
    }
  }

  /// Load friends from SharedPreferences
  static Future<void> _loadFriends() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final friendsJson = prefs.getString(_friendsKey);

      if (friendsJson != null) {
        final List<dynamic> friendsList = json.decode(friendsJson);
        _cachedFriends = friendsList
            .map((friendMap) => Friend.fromMap(friendMap))
            .where((friend) => friend.isActive)
            .toList();
      } else {
        _cachedFriends = [];
      }
    } catch (e) {
      debugPrint('Error loading friends: $e');
      _cachedFriends = [];
    }
  }

  /// Save friends to SharedPreferences
  static Future<void> _saveFriends() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final friendsJson = json.encode(_cachedFriends.map((f) => f.toMap()).toList());
      await prefs.setString(_friendsKey, friendsJson);
    } catch (e) {
      debugPrint('Error saving friends: $e');
    }
  }

  // CRUD Operations for Friends

  /// Get all active friends
  static Future<List<Friend>> getAllFriends() async {
    await initialize();
    return List.from(_cachedFriends);
  }

  /// Add a new friend
  static Future<void> addFriend(Friend friend) => addFriends([friend]);

  /// Adds [friends] with one save and one change notification.
  static Future<void> addFriends(List<Friend> friends) =>
      applyChanges(add: friends);

  /// Removes the friends with ids in [remove], replaces those in [update]
  /// (as given: `lastUpdated` is the caller's) and appends [add], with one
  /// save, one removal callback and one change notification (one reminder
  /// reschedule and calendar sync for a whole import or its undo).
  /// Returns once the batch is saved; the callbacks keep running after.
  ///
  /// Checks everything first and throws without changing anything when an
  /// added id already exists (or repeats) or an updated / removed id is
  /// unknown.
  static Future<void> applyChanges({
    List<Friend> add = const [],
    List<Friend> update = const [],
    List<String> remove = const [],
  }) async {
    await initialize();
    if (add.isEmpty && update.isEmpty && remove.isEmpty) return;
    final indexById = {
      for (var i = 0; i < _cachedFriends.length; i++) _cachedFriends[i].id: i,
    };
    _checkBatch(indexById, add: add, update: update, remove: remove);

    for (final friend in update) {
      _cachedFriends[indexById[friend.id]!] = friend;
    }
    final removed = remove.toSet();
    _cachedFriends.removeWhere((friend) {
      if (!removed.contains(friend.id)) return false;
      _rememberDeletedAvatar(friend);
      return true;
    });
    _cachedFriends.addAll(add);
    _assignMissingNotificationIds();
    await _saveFriends();
    _notifyInBackground(remove);
  }

  /// Tells listeners about a batch at once ([revision]) but runs the slow
  /// follow-ups (calendar removal, reminder reschedule) without waiting:
  /// for a large import they take seconds, and the caller (e.g. the
  /// import's result snackbar) should not wait for them. Both callbacks
  /// serialize their own work, so a quick undo queues up behind them.
  static void _notifyInBackground(List<String> removedIds) {
    unawaited(_notifyRemoved(removedIds));
    unawaited(_notifyChanged());
  }

  static void _checkBatch(
    Map<String, int> indexById, {
    required List<Friend> add,
    required List<Friend> update,
    required List<String> remove,
  }) {
    for (final id in [...update.map((f) => f.id), ...remove]) {
      if (!indexById.containsKey(id)) {
        throw Exception('Friend with ID $id not found');
      }
    }
    final ids = indexById.keys.toSet();
    for (final friend in add) {
      if (!ids.add(friend.id)) {
        throw Exception('Friend with ID ${friend.id} already exists');
      }
    }
  }

  /// A fresh friend id: the time in ms plus the position in a batch.
  static String newFriendId(DateTime now, [int index = 0]) =>
      '${now.millisecondsSinceEpoch}$index';

  /// Update an existing friend
  static Future<void> updateFriend(Friend updatedFriend) async {
    await initialize();

    final index = _cachedFriends.indexWhere((f) => f.id == updatedFriend.id);
    if (index == -1) {
      throw Exception('Friend with ID ${updatedFriend.id} not found');
    }

    _cachedFriends[index] = updatedFriend.copyWith(
      lastUpdated: DateTime.now(),
    );
    await _saveFriends();
    await _notifyChanged();
  }

  /// Delete a friend
  static Future<void> deleteFriend(String id) async {
    await initialize();

    final index = _cachedFriends.indexWhere((f) => f.id == id);
    if (index == -1) {
      throw Exception('Friend with ID $id not found');
    }
    _rememberDeletedAvatar(_cachedFriends.removeAt(index));
    await _saveFriends();
    await _notifyRemoved([id]);
    await _notifyChanged();
  }

  // Birthday-specific operations

  /// Get friends who have birthdays today
  static List<Friend> getTodaysBirthdays() {
    return _cachedFriends.where((friend) => friend.isBirthdayToday()).toList();
  }

  // Birthday notification settings

  /// Check if birthday notifications are enabled globally
  static bool isBirthdayNotificationsEnabled() {
    return _birthdayNotificationsEnabled;
  }

  /// Enable/disable birthday notifications globally
  static Future<void> setBirthdayNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_birthdayNotificationsEnabledKey, enabled);
    _birthdayNotificationsEnabled = enabled;
    await _notifyChanged();
  }

  // Data management

  /// Backup JSON of [friends] (as shared by the export screen), with the
  /// photos in [avatars] (by friend id) embedded and [compass] (if not
  /// empty) as the `compass` section.
  static String encodeBackup(
    List<Friend> friends, {
    DateTime? now,
    Map<String, BackupAvatar> avatars = const {},
    CompassData? compass,
  }) {
    final exportData = {
      'version': backupVersion,
      'exportDate': (now ?? DateTime.now()).toIso8601String(),
      'friendsCount': friends.length,
      'friends': [
        for (final friend in friends) _backupEntry(friend, avatars[friend.id]),
      ],
      if (compass != null && !compass.isEmpty)
        backupCompassKey: compass.toJson(),
    };
    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  /// [friend]'s map without its local photo path (meaningless on another
  /// device), plus the embedded [avatar].
  static Map<String, dynamic> _backupEntry(Friend friend, BackupAvatar? avatar) {
    final map = friend.toMap()..remove('avatarPath');
    if (avatar != null) map[BackupAvatar.key] = avatar.toJson();
    return map;
  }

  /// [encodeBackup] with each friend's photo read from [avatarStore];
  /// photos that are missing or unreadable are left out.
  static Future<String> exportBackup(
    List<Friend> friends, {
    AvatarStore avatarStore = const AvatarStore(),
    DateTime? now,
    CompassData? compass,
  }) async {
    final avatars = <String, BackupAvatar>{};
    for (final friend in friends) {
      final avatar = await avatarStore.readForBackup(friend.avatarPath);
      if (avatar != null) avatars[friend.id] = avatar;
    }
    return encodeBackup(friends, now: now, avatars: avatars, compass: compass);
  }

  /// Friends of a backup; see [decodeBackupEntries].
  static List<Friend> decodeBackup(String jsonString) =>
      decodeBackupEntries(jsonString).map((entry) => entry.friend).toList();

  /// Friends of a backup with their embedded photos; see
  /// [decodeBackupContents]. Empty only for a backup with Compass data alone.
  static List<BackupEntry> decodeBackupEntries(String jsonString) =>
      decodeBackupContents(jsonString).entries;

  /// Friends (with embedded photos) and Compass data of a 1.x backup;
  /// friend entries may be maps or (legacy) JSON strings, unreadable entries
  /// are skipped, corrupt photos ignored. Throws [FriendsBackupException]
  /// for invalid files and for files with neither friends nor Compass data.
  static BackupContents decodeBackupContents(String jsonString) {
    final Object? importData;
    try {
      importData = jsonDecode(jsonString);
    } on FormatException {
      throw const FriendsBackupException('import_export_error_invalid_format');
    }
    if (importData is! Map<String, dynamic> ||
        importData['friends'] is! List ||
        !importData.containsKey('version')) {
      throw const FriendsBackupException('import_export_error_invalid_format');
    }
    final friends = _parseBackupEntries(importData['friends'] as List);
    final compass = CompassData.fromJson(importData[backupCompassKey]);
    if (friends.isEmpty && compass.isEmpty) {
      throw const FriendsBackupException('import_export_error_no_valid_friends');
    }
    return BackupContents(friends, compass: compass.isEmpty ? null : compass);
  }

  static List<BackupEntry> _parseBackupEntries(List<dynamic> entries) {
    final friends = <BackupEntry>[];
    for (final entry in entries) {
      try {
        final map = entry is String
            ? jsonDecode(entry) as Map<String, dynamic>
            : entry as Map<String, dynamic>;
        friends.add(BackupEntry(
          Friend.fromMap(map),
          avatar: BackupAvatar.fromJson(map[BackupAvatar.key]),
        ));
      } catch (e) {
        debugPrint('Error parsing friend data: $e');
      }
    }
    return friends;
  }

  /// Adds the [imported] friends not yet present (same name, case-insensitive,
  /// and birth date) as new friends; returns (added, skipped).
  static Future<(int, int)> importFriends(List<Friend> imported) =>
      importBackupEntries([for (final friend in imported) BackupEntry(friend)]);

  /// As [importFriends]; embedded photos of added friends are saved as new
  /// files in [avatarStore].
  static Future<(int, int)> importBackupEntries(
    List<BackupEntry> imported, {
    AvatarStore avatarStore = const AvatarStore(),
  }) async {
    final knownPeople = {
      for (final friend in await getAllFriends()) friend.identityKey,
    };
    final now = DateTime.now();
    final newFriends = <Friend>[];
    for (final entry in imported) {
      // Set lookup (linear for large backups); also skips repeats within
      // the backup itself.
      if (!knownPeople.add(entry.friend.identityKey)) continue;
      final avatarPath = await avatarStore.restore(entry.avatar);
      newFriends.add(
          _asNewFriend(entry.friend, now, newFriends.length, avatarPath));
    }
    await addFriends(newFriends);
    // In the background: the import result doesn't wait for file cleanup.
    unawaited(lastAvatarCleanup = removeOrphanedAvatars(avatarStore: avatarStore));
    return (newFriends.length, imported.length - newFriends.length);
  }

  /// The cleanup started by the last import; awaited by tests.
  @visibleForTesting
  static Future<int>? lastAvatarCleanup;

  static void _rememberDeletedAvatar(Friend friend) {
    final path = friend.avatarPath;
    if (path != null && path.isNotEmpty) _avatarsDeletedThisSession.add(path);
  }

  /// Deletes photos no stored friend uses any more (people deleted in an
  /// earlier session, replaced photos, photos picked but never saved) and
  /// returns how many were deleted. Photos of people deleted in this
  /// session stay until the next start, so "Undo" keeps working. Does
  /// nothing when the stored friends cannot be read.
  static Future<int> removeOrphanedAvatars({
    AvatarStore avatarStore = const AvatarStore(),
  }) async {
    final stored = await _storedAvatarPaths();
    if (stored == null) return 0;
    return avatarStore
        .removeUnreferenced([...stored, ..._avatarsDeletedThisSession]);
  }

  /// The avatar paths of every stored friend entry (active or not); null
  /// when the stored list cannot be read, so nothing is deleted by mistake.
  static Future<List<String?>?> _storedAvatarPaths() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final friendsJson = prefs.getString(_friendsKey);
      if (friendsJson == null) return const [];
      final entries = json.decode(friendsJson) as List<dynamic>;
      return [
        for (final entry in entries)
          if ((entry as Map)['avatarPath'] case final String path) path,
      ];
    } catch (e) {
      debugPrint('Avatar cleanup skipped, friends unreadable: $e');
      return null;
    }
  }

  /// Copy of an imported friend with a fresh id and timestamps. Its own
  /// avatar path is never used (it points into another device's storage);
  /// [avatarPath] is the restored photo on this device, if any.
  static Friend _asNewFriend(
    Friend friend,
    DateTime now,
    int index, [
    String? avatarPath,
  ]) {
    return Friend(
      id: newFriendId(now, index),
      name: friend.name,
      birthDate: friend.birthDate,
      avatarPath: avatarPath,
      notes: friend.notes,
      customNotificationMessage: friend.customNotificationMessage,
      // Older backups hold typed "Familie" etc.: map to predefined ids.
      groupName: GroupNames.normalize(friend.groupName),
      customLifespan: friend.customLifespan,
      meetingFrequency: friend.meetingFrequency,
      hasBirthYear: friend.hasBirthYear,
      importSource: friend.importSource,
      importSourceId: friend.importSourceId,
      createdDate: now,
      lastUpdated: now,
    );
  }

  /// Removes all friends (reminder settings are kept).
  static Future<void> clearAllData() async {
    await initialize();
    final removedIds = _cachedFriends.map((f) => f.id).toList();
    _cachedFriends.forEach(_rememberDeletedAvatar);
    _cachedFriends.clear();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_friendsKey);
    await _notifyRemoved(removedIds);
    await _notifyChanged();
  }

  // Friend group management

  /// Get all unique group names
  static List<String> getAllGroups() {
    final groups = <String>{};
    for (final friend in _cachedFriends) {
      if (friend.groupName != null && friend.groupName!.isNotEmpty) {
        groups.add(friend.groupName!);
      }
    }
    return groups.toList()..sort();
  }

  /// [getAllGroups] once the saved friends are loaded (the background
  /// start may not have loaded them yet).
  static Future<List<String>> loadAllGroups() async {
    await initialize();
    return getAllGroups();
  }
}
