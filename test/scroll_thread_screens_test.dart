import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:memento_mori_life_in_weeks/add_friend_screen.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/friend_detail_screen.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/onboarding/step_layout.dart';
import 'package:memento_mori_life_in_weeks/people_import/ui/import_review_states.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:memento_mori_life_in_weeks/theme/app_theme.dart';
import 'package:memento_mori_life_in_weeks/theme/theme_options.dart';
import 'package:memento_mori_life_in_weeks/widgets/scroll_thread.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/scroll_thread_probe.dart';

Future<void> _pump(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = phoneViewport;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.build(style: ThemeStyle.stoic, brightness: Brightness.light),
    locale: const Locale('en'),
    supportedLocales: const [Locale('en')],
    localizationsDelegates: const [
      AppLocalizationsDelegate(),
      ...GlobalMaterialLocalizations.delegates,
    ],
    home: home,
  ));
  await tester.pumpAndSettle();
}

Rect _threadTrack(WidgetTester tester) =>
    tester.getRect(find.byKey(ScrollThread.threadKey));

Future<void> _scrollToEnd(WidgetTester tester, Finder scrollable) async {
  await tester.fling(scrollable, const Offset(0, -6000), 3000);
  await tester.pumpAndSettle();
}

Widget _stepPage(int paragraphs) => Scaffold(
      body: SafeArea(
        child: StepLayout(
          action: FilledButton(onPressed: () {}, child: const Text('Next')),
          children: [
            for (var i = 0; i < paragraphs; i++)
              SizedBox(height: 120, child: Text('Paragraph $i')),
          ],
        ),
      ),
    );

void main() {
  setUpAll(() => initializeDateFormatting());

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'birth_date': DateTime(1990, 11, 17).toIso8601String(),
      // Its lifespan card animates forever (pumpAndSettle would time out).
      'lifespan_visualization_enabled': false,
    });
    await SettingsService.initialize();
  });

  testWidgets('add form shows the thread below the app bar, hides at the end',
      (tester) async {
    await _pump(tester, const AddFriendScreen());

    expect(find.byKey(ScrollThread.threadKey), findsOneWidget);
    expect(scrollThreadOpacity(tester), 1);
    final appBar = tester.getRect(find.byType(AppBar));
    expect(_threadTrack(tester).top, appBar.bottom);

    await _scrollToEnd(tester, find.byType(ListView));
    expect(scrollThreadOpacity(tester), 0);
  });

  testWidgets('friend detail shows the thread while content lies below',
      (tester) async {
    final friend = Friend(
      id: '1',
      name: 'Anna Lopez',
      birthDate: DateTime(1995, 11, 14),
      createdDate: DateTime(2025, 1, 1),
      lastUpdated: DateTime(2025, 1, 1),
    );
    await _pump(tester, FriendDetailScreen(friend: friend));

    expect(scrollThreadOpacity(tester), 1);
    expect(
      _threadTrack(tester).top,
      tester.getRect(find.byType(AppBar)).bottom,
    );

    await _scrollToEnd(tester, find.byType(ListView));
    expect(scrollThreadOpacity(tester), 0);
  });

  testWidgets('step page: the thread ends above the pinned action',
      (tester) async {
    await _pump(tester, _stepPage(12));

    expect(scrollThreadOpacity(tester), 1);
    final track = _threadTrack(tester);
    final scrollArea =
        tester.getRect(find.byKey(const ValueKey('step_layout_scroll')));
    expect(track.top, scrollArea.top);
    expect(track.bottom, scrollArea.bottom);
    expect(
      track.bottom,
      lessThanOrEqualTo(tester.getRect(find.byType(FilledButton)).top),
    );

    await _scrollToEnd(
        tester, find.byKey(const ValueKey('step_layout_scroll')));
    expect(scrollThreadOpacity(tester), 0);
  });

  testWidgets('step page with short content shows no thread', (tester) async {
    await _pump(tester, _stepPage(2));
    expect(scrollThreadOpacity(tester), 0);
  });

  testWidgets('short import message shows no thread', (tester) async {
    await _pump(
      tester,
      const Scaffold(
        body: ImportMessageState(
          icon: Icons.contacts_outlined,
          title: 'Title',
          body: 'Body',
        ),
      ),
    );
    expect(scrollThreadOpacity(tester), 0);
  });
}
