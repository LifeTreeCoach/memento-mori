import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/people/filter_sheet.dart';
import 'package:memento_mori_life_in_weeks/people/friend_query.dart';

/// Opens the filter sheet over [query]; every applied query lands in [applied].
Future<void> _openSheet(
  WidgetTester tester,
  FriendQuery query,
  List<FriendQuery> applied,
) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    locale: const Locale('en'),
    supportedLocales: const [Locale('en'), Locale('de')],
    localizationsDelegates: const [
      AppLocalizationsDelegate(),
      ...GlobalMaterialLocalizations.delegates,
    ],
    home: Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => showFilterSheet(
            context,
            query: query,
            countFor: (_) => 0,
            onChanged: applied.add,
          ),
          child: const Text('open'),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle(); // localizations load asynchronously
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  const weekFilter = FriendQuery(dateFilter: DateFilter.thisWeek);

  testWidgets('choosing a custom range keeps the applied filter', (tester) async {
    final applied = <FriendQuery>[];
    await _openSheet(tester, weekFilter, applied);

    await tester.tap(find.text('Custom date range'));
    await tester.pumpAndSettle();
    expect(applied, isEmpty);
    expect(find.text('From'), findsOneWidget); // range editor shown

    // Dismiss without picking dates: nothing was applied.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('From'), findsNothing);
    expect(applied, isEmpty);
  });

  testWidgets('Apply stays disabled until both dates are chosen', (tester) async {
    final applied = <FriendQuery>[];
    await _openSheet(tester, weekFilter, applied);
    await tester.tap(find.text('Custom date range'));
    await tester.pumpAndSettle();

    final apply = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Apply'));
    expect(apply.onPressed, isNull);
  });

  testWidgets('a full custom range applies on Apply', (tester) async {
    final applied = <FriendQuery>[];
    final today = DateUtils.dateOnly(DateTime.now());
    final ranged = FriendQuery(
      dateFilter: DateFilter.custom,
      customStart: today,
      customEnd: today.add(const Duration(days: 5)),
    );
    await _openSheet(tester, ranged, applied);

    await tester.tap(find.widgetWithText(FilledButton, 'Apply'));
    await tester.pumpAndSettle();
    expect(applied.single.dateFilter, DateFilter.custom);
    expect(applied.single.hasCustomRange, isTrue);
  });

  testWidgets('a fixed range applies at once and closes', (tester) async {
    final applied = <FriendQuery>[];
    await _openSheet(tester, weekFilter, applied);

    await tester.tap(find.text('Birthdays in the next 30\u00A0days'));
    await tester.pumpAndSettle();
    expect(applied.single.dateFilter, DateFilter.thisMonth);
    expect(find.text('Custom date range'), findsNothing);
  });
}
