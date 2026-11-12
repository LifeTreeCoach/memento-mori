import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/friend_detail/friend_text.dart';
import 'package:memento_mori_life_in_weeks/friend_detail/info_row.dart';
import 'package:memento_mori_life_in_weeks/widgets/section_label.dart';
import 'package:memento_mori_life_in_weeks/life/upcoming_birthday_card.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/people/group_names.dart';
import 'package:memento_mori_life_in_weeks/theme/life_palette.dart';

/// Birth date, next birthday and the age it brings.
class FriendBirthdaySection extends StatelessWidget {
  const FriendBirthdaySection({
    super.key,
    required this.friend,
    required this.today,
  });

  final Friend friend;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = FriendText(l10n);
    final next = UpcomingBirthday.forFriend(friend, today);
    final isToday = next.daysUntil == 0;
    final accent = LifePalette.of(context).accent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel.compact(l10n.translate('friend_detail_section_birthday')),
        InfoCard(
          children: [
            InfoRow(
              label: l10n.translate('friend_detail_born'),
              value: text.birthDate(friend),
            ),
            InfoRow(
              label: l10n.translate('friend_detail_next_birthday'),
              value: isToday
                  ? l10n.translate('friend_detail_today')
                  : text.date(friend.getNextBirthday()),
              valueColor: isToday ? accent : null,
            ),
            if (!isToday)
              InfoRow(
                label: l10n.translate('friend_detail_days_until'),
                value: text.days(next.daysUntil),
                valueColor: next.daysUntil <= 7 ? accent : null,
              ),
            if (next.age case final age?)
              InfoRow(
                label: l10n.translate('friend_detail_turning'),
                value: text.age(age),
              ),
          ],
        ),
      ],
    );
  }
}

/// Group, expected lifespan and progress (with a known birth year), date
/// added and notes.
class FriendPersonalSection extends StatelessWidget {
  const FriendPersonalSection({super.key, required this.friend});

  final Friend friend;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = FriendText(l10n);
    final notes = friend.notes;
    final group = friend.groupName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel.compact(l10n.translate('friend_detail_section_personal')),
        InfoCard(
          children: [
            if (group != null && group.isNotEmpty)
              InfoRow(
                label: l10n.translate('friend_detail_group'),
                value: GroupNames.label(group, l10n),
              ),
            if (friend.hasBirthYear) ...[
              InfoRow(
                label: l10n.translate('friend_detail_expected_lifespan'),
                value: text.years(friend.customLifespan),
                caption: friend.lifespanFromEstimate
                    ? l10n.translate('friend_detail_lifespan_estimated')
                    : null,
              ),
              InfoRow(
                label: l10n.translate('friend_detail_remaining'),
                value: text.remaining(friend)!,
              ),
              InfoRow(
                label: l10n.translate('friend_detail_life_progress'),
                value: l10n.translate(
                  'friend_detail_percent_lived',
                  replacements: {'p': '${FriendText.percentLived(friend)}'},
                ),
              ),
            ],
            InfoRow(
              label: l10n.translate('friend_detail_added'),
              value: text.date(friend.createdDate),
            ),
            if (notes != null && notes.isNotEmpty) _Notes(notes: notes),
          ],
        ),
      ],
    );
  }
}

class _Notes extends StatelessWidget {
  const _Notes({required this.notes});

  final String notes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context).translate('friend_detail_notes'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(notes, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}

/// The birthday message and a button to send a test notification.
class FriendReminderSection extends StatelessWidget {
  const FriendReminderSection({
    super.key,
    required this.friend,
    required this.onSendTest,
  });

  final Friend friend;
  final VoidCallback onSendTest;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final message = friend.customNotificationMessage;
    final hasMessage = message != null && message.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel.compact(l10n.translate('friend_detail_section_reminder')),
        InfoCard(
          children: [
            InfoRow(
              label: l10n.translate(
                hasMessage
                    ? 'friend_detail_custom_message'
                    : 'friend_detail_message',
              ),
              value: hasMessage
                  ? message
                  : l10n.translate('friend_detail_default_message'),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onSendTest,
                icon: const Icon(Icons.notifications_outlined),
                label: Text(l10n.translate('friend_detail_send_test')),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ],
    );
  }
}
