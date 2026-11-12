import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/life/upcoming_birthday_card.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/people/people_section_header.dart';
import 'package:memento_mori_life_in_weeks/people/people_sections.dart';
import 'package:memento_mori_life_in_weeks/theme/life_palette.dart';

/// Builds the row for one friend; [section] keeps keys unique when the
/// same friend appears in two sections.
typedef PersonRowBuilder = Widget Function(
    UpcomingBirthday birthday, String section);

/// Horizontal padding of rows inside the inset "Today" group.
const double todayRowPadding = 20 - _TodayGroup.inset;

/// The People sections as a sliver: Today, Next 30 days, Everyone (or a
/// single Results list while searching).
class PeopleList extends StatelessWidget {
  const PeopleList({
    super.key,
    required this.sections,
    required this.rowBuilder,
    required this.searching,
    this.everyoneTrailing,
    this.everyoneLeading,
  });

  final PeopleSections sections;
  final PersonRowBuilder rowBuilder;
  final bool searching;

  /// Action shown in the "Everyone" header (the sort button).
  final Widget? everyoneTrailing;

  /// Row shown at the top of "Everyone" (the reminders switch).
  final Widget? everyoneLeading;

  @override
  Widget build(BuildContext context) {
    final entries = searching ? _searchEntries() : _sectionEntries();
    final indexByKey = {
      for (var i = 0; i < entries.length; i++) entries[i].key: i,
    };
    return SliverList.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) => entries[index].build(context),
      findChildIndexCallback: (key) => indexByKey[key],
    );
  }

  /// One entry per list item; rows are only built once scrolled into
  /// view, so hundreds of people stay cheap.
  List<_PeopleListEntry> _searchEntries() => [
        _header('people_section_results'),
        ..._rows(sections.everyone, 'results'),
      ];

  List<_PeopleListEntry> _sectionEntries() => [
        if (sections.today.isNotEmpty) ...[
          _header('people_section_today', accent: true),
          _todayGroup(),
        ],
        if (sections.upcoming.isNotEmpty) ...[
          _header('people_section_upcoming'),
          ..._rows(sections.upcoming, 'upcoming'),
        ],
        _header('people_section_everyone', trailing: everyoneTrailing),
        if (everyoneLeading case final leading?)
          _PeopleListEntry(const ValueKey('everyone-leading'), (_) => leading),
        ..._rows(sections.everyone, 'everyone'),
      ];

  _PeopleListEntry _header(String labelKey,
          {bool accent = false, Widget? trailing}) =>
      _PeopleListEntry(
        ValueKey('header-$labelKey'),
        (context) => PeopleSectionHeader(
          label: AppLocalizations.of(context).translate(labelKey),
          color: accent ? LifePalette.of(context).accent : null,
          trailing: trailing,
        ),
      );

  /// Today's (few) rows as one entry so they share one backdrop.
  _PeopleListEntry _todayGroup() => _PeopleListEntry(
        const ValueKey('today-group'),
        (_) => _TodayGroup(children: [
          for (final birthday in sections.today) rowBuilder(birthday, 'today'),
        ]),
      );

  Iterable<_PeopleListEntry> _rows(
          List<UpcomingBirthday> birthdays, String section) =>
      birthdays.map((birthday) => _PeopleListEntry(
            ValueKey('row-$section-${birthday.friend.id}'),
            (_) => rowBuilder(birthday, section),
          ));
}

/// One lazily built item of [PeopleList]; [key] is unique within the list
/// and lets the sliver keep a row's state when rows above it go away.
class _PeopleListEntry {
  const _PeopleListEntry(this.key, this._builder);

  final Key key;
  final WidgetBuilder _builder;

  Widget build(BuildContext context) =>
      KeyedSubtree(key: key, child: _builder(context));
}

/// Quietly celebratory backdrop for today's birthdays.
class _TodayGroup extends StatelessWidget {
  /// Inset of the group; rows inside pad by 20 minus this.
  static const double inset = 8;

  const _TodayGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final accent = LifePalette.of(context).accent;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: inset),
      child: Material(
        color: accent.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: accent.withValues(alpha: 0.25)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      ),
    );
  }
}
