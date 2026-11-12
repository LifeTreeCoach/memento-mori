import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/country_picker_sheet.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/sources_sheet.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/settings/choice_tile.dart';
import 'package:memento_mori_life_in_weeks/widgets/scroll_thread.dart';

import 'support/lifespan_test_data.dart';
import 'support/scroll_thread_probe.dart';

/// Opens the sheet that [open] shows on a phone-sized screen.
Future<void> _openSheet(
  WidgetTester tester,
  void Function(BuildContext context) open,
) async {
  tester.view.physicalSize = phoneViewport * 3;
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
          onPressed: () => open(context),
          child: const Text('open'),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle(); // localizations load asynchronously
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

/// Scrolls the sheet's vertical scroll view to its very end.
Future<void> _scrollToEnd(WidgetTester tester) async {
  final vertical = find.byWidgetPredicate(
    (widget) => widget is Scrollable && widget.axis == Axis.vertical,
  );
  final position = tester.state<ScrollableState>(vertical).position;
  // A lazy list learns its full length while scrolling: repeat until the end.
  while (position.extentAfter > 0) {
    position.jumpTo(position.maxScrollExtent);
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('country picker shows the thread beside the list until its end',
      (tester) async {
    await _openSheet(
      tester,
      (context) => showCountryPickerSheet(
        context,
        countries: lifespanTestData.countries,
        selected: 'DE',
      ),
    );

    expect(find.byKey(ScrollThread.threadKey), findsOneWidget);
    expect(scrollThreadOpacity(tester), 1);
    // The track sits next to the list, below the title and search field.
    final track = tester.getRect(find.byKey(ScrollThread.threadKey));
    final list = tester.getRect(find.byType(ListView));
    final search =
        tester.getRect(find.byKey(const ValueKey('lifespan_country_search')));
    expect(track.top, greaterThanOrEqualTo(search.bottom));
    expect(track.top, list.top);
    expect(track.right, list.right - ScrollThread.rightInset);

    await _scrollToEnd(tester);
    expect(scrollThreadOpacity(tester), 0);
  });

  testWidgets('sources sheet shows the thread below its title', (tester) async {
    await _openSheet(tester, showLifespanSourcesSheet);

    expect(scrollThreadOpacity(tester), 1);
    final track = tester.getRect(find.byKey(ScrollThread.threadKey));
    final title = tester.getRect(find.text('Sources'));
    expect(track.top, greaterThan(title.bottom));

    await _scrollToEnd(tester);
    expect(scrollThreadOpacity(tester), 0);
  });

  testWidgets('a short choice sheet shows no thread', (tester) async {
    await _openSheet(
      tester,
      (context) => showChoiceSheet<int>(
        context,
        title: 'Pick',
        options: const [
          SettingsOption(1, 'One'),
          SettingsOption(2, 'Two'),
          SettingsOption(3, 'Three'),
        ],
        selected: 1,
      ),
    );

    expect(find.byKey(ScrollThread.threadKey), findsOneWidget);
    expect(scrollThreadOpacity(tester), 0);
  });
}
