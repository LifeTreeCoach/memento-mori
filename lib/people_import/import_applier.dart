/// Saves an [ImportPlan] as one batch of friend changes and takes it back.
library;

import 'package:flutter/foundation.dart';

import '../data/avatar_store.dart';
import '../data/backup_avatar.dart';
import '../friend.dart';
import '../friends_service.dart';
import 'birthday_candidate.dart';
import 'import_photo.dart';
import 'import_plan.dart';

/// What one import changed, enough to undo it.
@immutable
class ImportOutcome {
  const ImportOutcome({required this.addedIds, required this.previous});

  /// Ids of the people added by the import.
  final List<String> addedIds;

  /// The updated people as they were before the import.
  final List<Friend> previous;

  int get addedCount => addedIds.length;

  int get updatedCount => previous.length;

  bool get isEmpty => addedIds.isEmpty && previous.isEmpty;
}

/// Turns an [ImportPlan] into [FriendsService] changes.
class ImportApplier {
  const ImportApplier({
    this.avatarStore = const AvatarStore(),
    this.resizePhoto = resizeImportPhoto,
    this.now = DateTime.now,
  });

  final AvatarStore avatarStore;
  final ImportPhotoResizer resizePhoto;
  final DateTime Function() now;

  /// Adds the planned people (photos shrunk and saved first) and updates
  /// the planned birthdays in one [FriendsService.applyChanges] batch.
  /// Updates of people deleted meanwhile are skipped.
  Future<ImportOutcome> apply(ImportPlan plan) async {
    final time = now();
    final added = <Friend>[];
    for (final planned in plan.newFriends) {
      final avatarPath = await _savePhoto(planned.photo);
      added.add(_newFriend(planned, time, added.length, avatarPath));
    }
    final byId = {
      for (final friend in await FriendsService.getAllFriends())
        friend.id: friend,
    };
    final previous = <Friend>[];
    final updated = <Friend>[];
    for (final update in plan.updates) {
      final friend = byId[update.friendId];
      if (friend == null) continue;
      previous.add(friend);
      updated.add(_updatedFriend(friend, update, time));
    }
    await FriendsService.applyChanges(add: added, update: updated);
    return ImportOutcome(
      addedIds: [for (final friend in added) friend.id],
      previous: previous,
    );
  }

  /// Removes the people [outcome] added and restores the ones it updated,
  /// in one batch; people deleted since then are left alone.
  Future<void> undo(ImportOutcome outcome) async {
    final present = {
      for (final friend in await FriendsService.getAllFriends()) friend.id,
    };
    await FriendsService.applyChanges(
      remove: [
        for (final id in outcome.addedIds)
          if (present.contains(id)) id,
      ],
      update: [
        for (final friend in outcome.previous)
          if (present.contains(friend.id)) friend,
      ],
    );
  }

  /// Loads, shrinks and saves [photo]; null when there is none or any step
  /// fails (the person is imported without a photo).
  Future<String?> _savePhoto(CandidatePhoto? photo) async {
    if (photo == null) return null;
    try {
      final bytes = await photo.load();
      if (bytes == null || bytes.length > BackupAvatar.maxBytes) return null;
      final resized = await resizePhoto(bytes);
      if (resized == null) return null;
      return await avatarStore.restore(BackupAvatar.fromBytes(resized));
    } catch (e) {
      debugPrint('Imported photo not saved: $e');
      return null;
    }
  }
}

Friend _newFriend(
  PlannedFriend planned,
  DateTime now,
  int index,
  String? avatarPath,
) {
  return Friend(
    id: FriendsService.newFriendId(now, index),
    name: planned.name,
    birthDate: _birthDate(planned.year, planned.month, planned.day),
    hasBirthYear: planned.year != null,
    avatarPath: avatarPath,
    groupName: planned.groupName,
    importSource: _sourceName(planned.source),
    importSourceId: planned.sourceId,
    createdDate: now,
    lastUpdated: now,
  );
}

Friend _updatedFriend(Friend friend, PlannedUpdate update, DateTime now) {
  return friend.copyWith(
    birthDate: _birthDate(update.year, update.month, update.day),
    hasBirthYear: update.year != null,
    lastUpdated: now,
  );
}

/// Stored birth date; without a year it lies in [Friend.noYearStorageYear].
DateTime _birthDate(int? year, int month, int day) =>
    DateTime(year ?? Friend.noYearStorageYear, month, day);

String _sourceName(ImportSource source) => switch (source) {
  ImportSource.contacts => Friend.importSourceContacts,
  ImportSource.vcard => Friend.importSourceVcard,
};
