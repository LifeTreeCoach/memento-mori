import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/friend_detail_screen.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/people/friend_actions.dart';

/// Opens [friend]'s detail screen. A delete confirmed there is carried out
/// here with [FriendActions.deleteWithUndoIn], so the undo snackbar shows in
/// the opening screen's messenger (looked up from [context] before the push,
/// so it does not depend on [context] surviving); otherwise the list is
/// reloaded, as the friend may have been edited.
Future<void> openFriendDetail(
  BuildContext context,
  Friend friend,
  FriendActions actions,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  final result = await Navigator.of(context).push<Object?>(
    MaterialPageRoute(builder: (_) => FriendDetailScreen(friend: friend)),
  );
  if (result is FriendDeleteRequest) {
    await actions.deleteWithUndoIn(messenger, l10n, result.friend);
  } else {
    await actions.onChanged();
  }
}
