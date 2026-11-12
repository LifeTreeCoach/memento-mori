import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_launch_requests.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_service.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_actions.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/friend_detail/birth_year_hint.dart';
import 'package:memento_mori_life_in_weeks/friend_detail/friend_lifespan_visualization.dart';
import 'package:memento_mori_life_in_weeks/friend_detail/together_view.dart';
import 'package:memento_mori_life_in_weeks/friends_service.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/people/meeting_frequency.dart';
import 'package:memento_mori_life_in_weeks/people/shared_time.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:memento_mori_life_in_weeks/widgets/action_snack_bar.dart';
import 'package:memento_mori_life_in_weeks/widgets/section_label.dart';

/// The lifespan section of the friend detail screen: a "Their life |
/// Together" switch (remembered via [SettingsService.getFriendLifespanView])
/// above either [FriendLifespanVisualization] or [TogetherView]. Without the
/// user's birth date there is no shared time, so only their life is shown.
/// Without the friend's birth year neither can be computed: a
/// [BirthYearHint] invites to add it instead.
class FriendLifespanSection extends StatefulWidget {
  const FriendLifespanSection({
    super.key,
    required this.friend,
    required this.today,
    required this.userBirthDate,
    required this.userLifeExpectancyYears,
    required this.onFriendChanged,
    this.onAddBirthYear,
  });

  final Friend friend;
  final DateTime today;
  final DateTime? userBirthDate;
  final int userLifeExpectancyYears;

  /// The friend was saved with a new meeting frequency.
  final ValueChanged<Friend> onFriendChanged;

  /// Opens the edit form from the [BirthYearHint] (friends without a year).
  final VoidCallback? onAddBirthYear;

  @override
  State<FriendLifespanSection> createState() => _FriendLifespanSectionState();
}

class _FriendLifespanSectionState extends State<FriendLifespanSection> {
  late String _view = SettingsService.getFriendLifespanView();

  AppLocalizations get _l10n => AppLocalizations.of(context);

  @override
  Widget build(BuildContext context) {
    if (!widget.friend.hasBirthYear) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel.compact(
              _l10n.translate('friend_detail_section_lifespan')),
          BirthYearHint(onAddBirthYear: widget.onAddBirthYear),
        ],
      );
    }
    final time = SharedTime.compute(
      friend: widget.friend,
      userBirthDate: widget.userBirthDate,
      userLifeExpectancyYears: widget.userLifeExpectancyYears,
      today: widget.today,
    );
    final showTogether =
        time != null && _view == SettingsService.friendLifespanViewTogether;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel.compact(_l10n.translate('friend_detail_section_lifespan')),
        if (time != null) ...[
          _switch(),
          const SizedBox(height: 12),
        ],
        if (showTogether)
          TogetherView(
            friend: widget.friend,
            time: time,
            onFrequencyChanged: _setFrequency,
            onPlan: _planTimeTogether,
          )
        else
          FriendLifespanVisualization(
            friend: widget.friend,
            height: 300,
            showDetails: true,
            enableAnimation: true,
          ),
      ],
    );
  }

  Widget _switch() {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<String>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(
            value: SettingsService.friendLifespanViewLife,
            icon: const Icon(Icons.person_outline),
            label: Text(_l10n.translate('together_view_life')),
          ),
          ButtonSegment(
            value: SettingsService.friendLifespanViewTogether,
            icon: const Icon(Icons.people_outline),
            label: Text(_l10n.translate('together_view_together')),
          ),
        ],
        selected: {_view},
        onSelectionChanged: (selection) => _setView(selection.first),
      ),
    );
  }

  void _setView(String view) {
    setState(() => _view = view);
    SettingsService.setFriendLifespanView(view);
  }

  Future<void> _setFrequency(MeetingFrequency? frequency) async {
    final updated = frequency == null
        ? widget.friend.copyWith(clearMeetingFrequency: true)
        : widget.friend.copyWith(meetingFrequency: frequency);
    widget.onFriendChanged(updated);
    await FriendsService.updateFriend(updated);
  }

  /// Adds "Time with {name}" to the Compass, once: while an open intention
  /// for this person exists, it only offers to open the Compass.
  Future<void> _planTimeTogether() async {
    final title = _l10n.translate('together_intention_title',
        replacements: {'name': widget.friend.name});
    final existing = await CompassService.openIntentionForFriend(
        widget.friend.id,
        title: title);
    if (!mounted) return;
    if (existing != null) {
      showActionSnackBar(
        ScaffoldMessenger.of(context),
        text: _l10n.translate('together_already_planned',
            replacements: {'title': existing.title}),
        action: _openCompassAction(),
      );
      return;
    }
    await CompassActions(
      contextOf: () => context,
      today: () => widget.today,
      birthDate: () => widget.userBirthDate,
      onSavedToSomeday: () {},
    ).addIntentionDirectly(
      title: title,
      area: LifeArea.relationships,
      savedText: _l10n.translate('together_planned',
          replacements: {'title': title}),
      action: _openCompassAction(),
      friendId: widget.friend.id,
    );
  }

  SnackBarAction _openCompassAction() => SnackBarAction(
        label: _l10n.translate('together_open_compass'),
        onPressed: CompassLaunchRequests.request,
      );
}
