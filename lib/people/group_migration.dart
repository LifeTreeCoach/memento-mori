import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/people/group_names.dart';

/// One-time move of typed "Family"/"Friends" groups (in any supported
/// language) to the predefined group ids; every other group stays as is.
class GroupMigration {
  GroupMigration._();

  /// SharedPreferences flag set once the migration ran.
  static const String doneKey = 'groups_migrated_v1';

  /// [friends] with predefined labels replaced by their ids; null when
  /// nothing changed.
  static List<Friend>? migrate(List<Friend> friends) {
    var changed = false;
    final migrated = friends.map((friend) {
      final id = _migratedGroupOf(friend);
      if (id == null) return friend;
      changed = true;
      return friend.copyWith(groupName: id);
    }).toList();
    return changed ? migrated : null;
  }

  /// The predefined id for [friend]'s typed group; null when it has none
  /// or it already is an id.
  static String? _migratedGroupOf(Friend friend) {
    final name = friend.groupName;
    if (name == null || GroupNames.isPredefined(name)) return null;
    return GroupNames.predefinedIdFor(name);
  }
}
