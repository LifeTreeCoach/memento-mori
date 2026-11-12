import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:memento_mori_life_in_weeks/add_friend_screen.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/friend_form/birthday_field.dart';
import 'package:memento_mori_life_in_weeks/friend_form/friend_estimate_launcher.dart';
import 'package:memento_mori_life_in_weeks/friend_form/lifespan_estimate_tile.dart';
import 'package:memento_mori_life_in_weeks/friends_service.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/lifespan_profile.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _l10n = AppLocalizations(const Locale('en'));
String _t(String key) => _l10n.translate(key);

final _anna = Friend(
  id: 'a',
  name: 'Anna',
  birthDate: DateTime(1995, 9, 1),
  createdDate: DateTime(2025),
  lastUpdated: DateTime(2025),
);

/// Pushes a stand-in estimate screen and returns null when it is left.
Future<LifespanProfile?> _estimateRoute(
  BuildContext context,
  FriendEstimateRequest request,
) => Navigator.of(context).push<LifespanProfile>(
  MaterialPageRoute(
    builder: (context) => Scaffold(
      body: TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('leave estimate'),
      ),
    ),
  ),
);

Future<void> _pumpForm(WidgetTester tester, {Friend? friend}) async {
  tester.view.physicalSize = const Size(1080, 3600);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      supportedLocales: const [Locale('en')],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        ...GlobalMaterialLocalizations.delegates,
      ],
      home: AddFriendScreen(friend: friend, estimateLauncher: _estimateRoute),
    ),
  );
  await tester.pumpAndSettle();
}

final Finder _nameField =
    find.byType(TextFormField, skipOffstage: false).first;

bool _nameHasFocus(WidgetTester tester) => tester
    .widget<EditableText>(
      find.descendant(of: _nameField, matching: find.byType(EditableText)),
    )
    .focusNode
    .hasFocus;

Future<void> _scrollToName(WidgetTester tester) async {
  await tester.ensureVisible(_nameField);
  await tester.pumpAndSettle();
}

Future<void> _focusName(WidgetTester tester) async {
  await tester.tap(_nameField);
  await tester.pump();
  expect(_nameHasFocus(tester), isTrue);
}

Future<void> _tapEstimateTile(WidgetTester tester) async {
  final tile = find.byType(LifespanEstimateTile);
  await tester.ensureVisible(tile);
  await tester.pumpAndSettle();
  await tester.tap(find.descendant(of: tile, matching: find.byType(ListTile)));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting());

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.initialize();
    await FriendsService.clearCacheForTesting();
  });

  group('name error', () {
    testWidgets('disappears once a name is typed after the estimate asked '
        'for one', (tester) async {
      await _pumpForm(tester);
      await _tapEstimateTile(tester);
      expect(find.text(_t('form_name_required'), skipOffstage: false), findsOneWidget);

      await _scrollToName(tester);
      await tester.enterText(_nameField, 'Anna');
      await tester.pump();
      expect(find.text(_t('form_name_required'), skipOffstage: false), findsNothing);
    });

    testWidgets('does not show while typing before it was asked for',
        (tester) async {
      await _pumpForm(tester);
      await tester.enterText(_nameField, 'A');
      await tester.enterText(_nameField, '');
      await tester.pump();
      expect(find.text(_t('form_name_required'), skipOffstage: false), findsNothing);
    });
  });

  group('keyboard stays closed', () {
    testWidgets('after the birthday date picker', (tester) async {
      await _pumpForm(tester, friend: _anna);
      await _focusName(tester);
      await tester.tap(find.descendant(
        of: find.byType(BirthdayField),
        matching: find.byType(InkWell),
      ).first);
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await tester.tap(find.text(_t('form_ok')));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsNothing);
      expect(_nameHasFocus(tester), isFalse);
    });

    testWidgets('after returning from the estimate', (tester) async {
      await _pumpForm(tester, friend: _anna);
      await _focusName(tester);
      await _tapEstimateTile(tester);
      expect(find.text('leave estimate'), findsOneWidget);
      await tester.tap(find.text('leave estimate'));
      await tester.pumpAndSettle();
      expect(find.byType(AddFriendScreen), findsOneWidget);
      await _scrollToName(tester);
      expect(_nameHasFocus(tester), isFalse);
    });
  });
}
