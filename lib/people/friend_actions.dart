import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/friends_service.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/widgets/action_snack_bar.dart';

/// Delete flows of the People tab. [onChanged] reloads the list.
class FriendActions {
  const FriendActions({required this.onChanged});

  final Future<void> Function() onChanged;

  /// Asks whether to delete [friend]; true when confirmed.
  static Future<bool> confirmDelete(BuildContext context, Friend friend) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _DeleteDialog(friend: friend, l10n: l10n),
    );
    return confirmed == true;
  }

  /// Asks for confirmation, then deletes [friend].
  Future<void> confirmAndDelete(BuildContext context, Friend friend) async {
    if (!await confirmDelete(context, friend) || !context.mounted) return;
    await deleteWithUndo(context, friend);
  }

  /// How long the undo action stays on screen; long enough to reach it.
  static const Duration undoDuration = actionSnackBarDuration;

  /// Deletes [friend] right away and offers to undo it.
  Future<void> deleteWithUndo(BuildContext context, Friend friend) =>
      deleteWithUndoIn(
          ScaffoldMessenger.of(context), AppLocalizations.of(context), friend);

  /// As [deleteWithUndo], showing the snackbars in [messenger]; for callers
  /// that captured it before their own context could go away.
  Future<void> deleteWithUndoIn(
    ScaffoldMessengerState messenger,
    AppLocalizations l10n,
    Friend friend,
  ) async {
    try {
      await FriendsService.deleteFriend(friend.id);
    } catch (e) {
      if (!messenger.mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text(l10n.translate('people_delete_error',
            replacements: {'error': '$e'})),
      ));
      return;
    }
    await onChanged();
    if (!messenger.mounted) return;
    showActionSnackBar(
      messenger,
      text: l10n.translate('people_removed', replacements: {'name': friend.name}),
      action: SnackBarAction(
        label: l10n.translate('people_undo'),
        onPressed: () => _restore(friend),
      ),
    );
  }

  Future<void> _restore(Friend friend) async {
    await FriendsService.addFriend(friend.copyWith(isActive: true));
    await onChanged();
  }
}

class _DeleteDialog extends StatelessWidget {
  const _DeleteDialog({required this.friend, required this.l10n});

  final Friend friend;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final name = {'name': friend.name};
    return AlertDialog(
      title: Text(l10n.translate('people_delete_title', replacements: name)),
      content: Text(l10n.translate('people_delete_body', replacements: name)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.translate('people_cancel')),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error),
          child: Text(l10n.translate('people_delete')),
        ),
      ],
    );
  }
}
