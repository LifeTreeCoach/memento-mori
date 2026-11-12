import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/friend_detail/friend_text.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:share_plus/share_plus.dart';

/// Opens the system share sheet with a short summary of [friend].
Future<void> shareFriend(BuildContext context, Friend friend) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  try {
    await SharePlus.instance.share(
      ShareParams(text: FriendText(l10n).shareText(friend)),
    );
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          l10n.translate(
            'friend_detail_share_error',
            replacements: {'error': '$e'},
          ),
        ),
      ),
    );
  }
}
