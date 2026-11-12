import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/add_friend_screen.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/friend_detail/friend_hero.dart';
import 'package:memento_mori_life_in_weeks/friend_detail/friend_sections.dart';
import 'package:memento_mori_life_in_weeks/friend_detail/friend_share.dart';
import 'package:memento_mori_life_in_weeks/friend_detail/friend_lifespan_section.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/people/friend_actions.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_service.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:memento_mori_life_in_weeks/widgets/scroll_thread.dart';

enum _MenuAction { edit, testNotification, delete }

/// Popped by [FriendDetailScreen] once the user confirmed deleting [friend].
class FriendDeleteRequest {
  const FriendDeleteRequest(this.friend);

  final Friend friend;
}

class FriendDetailScreen extends StatefulWidget {
  final Friend friend;

  const FriendDetailScreen({super.key, required this.friend});

  @override
  State<FriendDetailScreen> createState() => _FriendDetailScreenState();
}

class _FriendDetailScreenState extends State<FriendDetailScreen> {
  static const _gap = SizedBox(height: 28);

  late Friend currentFriend;

  @override
  void initState() {
    super.initState();
    currentFriend = widget.friend;
  }

  AppLocalizations get _l10n => AppLocalizations.of(context);

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: _l10n.translate('friend_detail_share'),
            icon: const Icon(Icons.ios_share),
            onPressed: _shareFriend,
          ),
          _buildMenu(),
        ],
      ),
      body: ScrollThread(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            FriendHero(
              friend: currentFriend,
              today: today,
              userBirthDate: SettingsService.getBirthDate(),
              userLifeExpectancyYears: SettingsService.getLifeExpectancyYears(),
            ),
            _gap,
            if (SettingsService.isLifespanVisualizationEnabled()) ...[
              _buildLifespanSection(today),
              _gap,
            ],
            FriendBirthdaySection(friend: currentFriend, today: today),
            _gap,
            FriendPersonalSection(friend: currentFriend),
            _gap,
            FriendReminderSection(
              friend: currentFriend,
              onSendTest: _sendTestNotification,
            ),
            const SizedBox(height: 32),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildMenu() {
    final error = Theme.of(context).colorScheme.error;
    return PopupMenuButton<_MenuAction>(
      tooltip: _l10n.translate('friend_detail_more'),
      onSelected: _onMenuSelected,
      itemBuilder: (context) => [
        _menuItem(_MenuAction.edit, Icons.edit_outlined, 'people_edit'),
        _menuItem(
          _MenuAction.testNotification,
          Icons.notifications_outlined,
          'friend_detail_test_notification',
        ),
        _menuItem(
          _MenuAction.delete,
          Icons.delete_outline,
          'people_delete',
          color: error,
        ),
      ],
    );
  }

  PopupMenuItem<_MenuAction> _menuItem(
    _MenuAction action,
    IconData icon,
    String labelKey, {
    Color? color,
  }) {
    return PopupMenuItem(
      value: action,
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Text(_l10n.translate(labelKey), style: TextStyle(color: color)),
        ],
      ),
    );
  }

  Future<void> _onMenuSelected(_MenuAction action) async {
    switch (action) {
      case _MenuAction.edit:
        await _editFriend();
      case _MenuAction.testNotification:
        await _sendTestNotification();
      case _MenuAction.delete:
        await _deleteFriend();
    }
  }

  /// Their life or the time together (see [FriendLifespanSection]).
  Widget _buildLifespanSection(DateTime today) {
    return FriendLifespanSection(
      friend: currentFriend,
      today: today,
      userBirthDate: SettingsService.getBirthDate(),
      userLifeExpectancyYears: SettingsService.getLifeExpectancyYears(),
      onFriendChanged: (friend) => setState(() => currentFriend = friend),
      onAddBirthYear: _editFriend,
    );
  }

  Widget _buildActionButtons() {
    final error = Theme.of(context).colorScheme.error;
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _editFriend,
            icon: const Icon(Icons.edit_outlined),
            label: Text(_l10n.translate('people_edit')),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _shareFriend,
                icon: const Icon(Icons.ios_share),
                label: Text(_l10n.translate('friend_detail_share')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _deleteFriend,
                icon: const Icon(Icons.delete_outline),
                label: Text(_l10n.translate('people_delete')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: error,
                  side: BorderSide(color: error),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _editFriend() async {
    final result = await Navigator.of(context).push<Friend>(
      MaterialPageRoute(
        builder: (context) => AddFriendScreen(friend: currentFriend),
      ),
    );

    if (result != null) {
      setState(() {
        currentFriend = result;
      });
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: isError ? TextStyle(color: scheme.onError) : null,
        ),
        backgroundColor: isError ? scheme.error : null,
      ),
    );
  }

  Future<void> _sendTestNotification() async {
    try {
      await ReminderService.sendBirthdayNotification(currentFriend);
      if (!mounted) return;
      _showMessage(
        _l10n.translate(
          'friend_detail_test_sent',
          replacements: {'name': currentFriend.name},
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showMessage(
        _l10n.translate(
          'friend_detail_test_failed',
          replacements: {'error': '$e'},
        ),
        isError: true,
      );
    }
  }

  Future<void> _shareFriend() => shareFriend(context, currentFriend);

  /// After confirmation, returns to the opener, which deletes with undo
  /// (`openFriendDetail`) so the undo snackbar shows on the list.
  Future<void> _deleteFriend() async {
    if (!await FriendActions.confirmDelete(context, currentFriend)) return;
    if (!mounted) return;
    Navigator.of(context).pop(FriendDeleteRequest(currentFriend));
  }
}
