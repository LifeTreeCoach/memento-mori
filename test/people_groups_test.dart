import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/friend_form/group_field.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/people/friend_query.dart';
import 'package:memento_mori_life_in_weeks/people/group_filter_bar.dart';
import 'package:memento_mori_life_in_weeks/people/group_names.dart';
import 'package:memento_mori_life_in_weeks/people/people_view.dart';

final _today = DateTime(2026, 11, 8);

Friend _friend(String name, String? group) => Friend(
      id: name,
      name: name,
      birthDate: DateTime(1990, 5, 1),
      groupName: group,
      createdDate: _today,
      lastUpdated: _today,
    );

AppLocalizations _l10n(String lang) => AppLocalizations(Locale(lang));

Future<void> _pump(WidgetTester tester, Widget child,
    {String lang = 'en'}) async {
  await tester.pumpWidget(MaterialApp(
      locale: Locale(lang),
      supportedLocales: [
        for (final code in AppLocalizations.supportedLanguages) Locale(code),
      ],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        ...GlobalMaterialLocalizations.delegates,
      ],
      home: Scaffold(body: child),
    ));
  await tester.pump();
}

void main() {
  group('GroupNames.label', () {
    test('localizes predefined ids', () {
      expect(GroupNames.label('@family', _l10n('en')), 'Family');
      expect(GroupNames.label('@friends', _l10n('de')), 'Freunde');
      expect(GroupNames.label('@family', _l10n('fr')), 'Famille');
      expect(GroupNames.label('@friends', _l10n('es')), 'Amigos');
    });

    test('shows custom groups as stored', () {
      expect(GroupNames.label('Colleagues', _l10n('de')), 'Colleagues');
    });
  });

  group('GroupNames.normalize', () {
    test('maps the labels of every language to the ids, ignoring case', () {
      for (final text in ['Family', ' familie ', 'FAMILLE', 'familia']) {
        expect(GroupNames.normalize(text), '@family', reason: text);
      }
      for (final text in ['Friends', 'freunde', 'Amis', 'amigos ']) {
        expect(GroupNames.normalize(text), '@friends', reason: text);
      }
    });

    test('keeps other text trimmed, empty becomes null', () {
      expect(GroupNames.normalize('  Colleagues '), 'Colleagues');
      expect(GroupNames.normalize('Family friends'), 'Family friends');
      expect(GroupNames.normalize('   '), isNull);
      expect(GroupNames.normalize(null), isNull);
    });

    test('a typed id stays that id', () {
      expect(GroupNames.normalize('@family'), '@family');
    });
  });

  group('FriendQuery with group labels', () {
    final friends = [
      _friend('Anna', '@family'),
      _friend('Ben', 'Chor'),
      _friend('Cleo', '@friends'),
    ];

    List<String> names(FriendQuery query) =>
        query.apply(friends, _today).map((f) => f.name).toList();

    test('search finds predefined groups by their label', () {
      final en = FriendQuery(
          search: 'family', groupLabel: GroupNames.labelerFor(_l10n('en')));
      expect(names(en), ['Anna']);
      final de = FriendQuery(
          search: 'Familie', groupLabel: GroupNames.labelerFor(_l10n('de')));
      expect(names(de), ['Anna']);
    });

    test('sort by group uses the label', () {
      final de = FriendQuery(
          sort: SortOption.group,
          groupLabel: GroupNames.labelerFor(_l10n('de')));
      // Chor < Familie < Freunde
      expect(names(de), ['Ben', 'Anna', 'Cleo']);
    });

    test('copyWith keeps the labeler', () {
      final query = FriendQuery(groupLabel: GroupNames.labelerFor(_l10n('de')))
          .copyWith(search: 'freunde');
      expect(names(query), ['Cleo']);
    });

    test('groups of the view are sorted by label', () {
      expect(
        PeopleView.groupsOf(friends, GroupNames.labelerFor(_l10n('en'))),
        ['Chor', '@family', '@friends'],
      );
    });
  });

  group('GroupField', () {
    testWidgets('shows the predefined chips without any friends and '
        'selecting one stores its id', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await _pump(
        tester,
        StatefulBuilder(
          builder: (context, setState) => GroupField(
            controller: controller,
            existingGroups: const [],
            onGroupSelected: (label) =>
                setState(() => controller.text = label),
          ),
        ),
        lang: 'de',
      );
      expect(find.widgetWithText(ChoiceChip, 'Familie'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Freunde'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Familie'));
      await tester.pump();
      expect(controller.text, 'Familie');
      expect(GroupNames.normalize(controller.text), '@family');
      final chip = tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Familie'));
      expect(chip.selected, isTrue);
    });

    test('chip groups: predefined first, then custom by label, no repeats',
        () {
      expect(
        GroupField.chipGroups(['Zoo', '@family', 'chor', 'Zoo'], (s) => s),
        ['@family', '@friends', 'chor', 'Zoo'],
      );
    });
  });

  testWidgets('filter bar shows predefined groups by label (de)',
      (tester) async {
    await _pump(
      tester,
      GroupFilterBar(
        groups: const ['@family', 'Chor'],
        selected: null,
        onSelected: (_) {},
      ),
      lang: 'de',
    );
    expect(find.text('Familie'), findsOneWidget);
    expect(find.text('Chor'), findsOneWidget);
    expect(find.text('@family'), findsNothing);
  });
}
