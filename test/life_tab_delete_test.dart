import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:memento_mori_life_in_weeks/app_settings_controller.dart';
import 'package:memento_mori_life_in_weeks/app_shell.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/friends_service.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:memento_mori_life_in_weeks/life/visualization_settings.dart';
import 'package:memento_mori_life_in_weeks/widget_launches.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

final DateTime _today = DateTime(2026, 11, 2);

class _NoWidgetLaunches implements WidgetLaunches {
  @override
  StreamSubscription<void> listen(VoidCallback onLaunch) =>
      const Stream<void>.empty().listen(null);
}

Future<void> _init() async {
  const visual = VisualizationSettings(enableAnimations: false);
  SharedPreferences.setMockInitialValues({
    'birth_date': DateTime(1990, 11, 17).toIso8601String(),
    'language': 'en',
    'visualization_settings': jsonEncode(visual.toMap()),
    'friends_data': '[]',
    'lifespan_visualization_enabled': false,
  });
  PackageInfo.setMockInitialValues(
    appName: 'Memento Mori',
    packageName: 'test',
    version: '1.2.3',
    buildNumber: '45',
    buildSignature: '',
  );
  await SettingsService.initialize();
  await FriendsService.clearCacheForTesting();
  await FriendsService.addFriend(Friend(
    id: 'a',
    name: 'Anna',
    birthDate: DateTime(1990, 11, 10),
    createdDate: DateTime(2025),
    lastUpdated: DateTime(2025),
  ));
}

Future<void> _pumpShell(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 6000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final controller = AppSettingsController();
  addTearDown(controller.dispose);
  await tester.pumpWidget(AppSettingsScope(
    controller: controller,
    child: MaterialApp(
      theme: controller.lightTheme,
      locale: controller.locale,
      supportedLocales: const [Locale('en'), Locale('de')],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        ...GlobalMaterialLocalizations.delegates,
      ],
      home: AppShell(now: _today, widgetLaunches: _NoWidgetLaunches()),
    ),
  ));
  await tester.pumpAndSettle();
}

Future<void> _deleteFromDetail(WidgetTester tester) async {
  final card = find.textContaining('Anna turns');
  await tester.tap(card);
  await tester.pumpAndSettle();
  final button = find.byIcon(Icons.delete_outline);
  await tester.scrollUntilVisible(button, 300,
      scrollable: find.byType(Scrollable).last);
  await tester.tap(button);
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(TextButton, 'Delete'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting());

  testWidgets('deleting from the upcoming-birthday card offers undo on the '
      'Life tab', (tester) async {
    await _init();
    await _pumpShell(tester);
    await _deleteFromDetail(tester);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Anna removed'), findsOneWidget);
    expect(await FriendsService.getAllFriends(), isEmpty);

    // Undo stays reachable well past the 4 s default.
    await tester.pump(const Duration(seconds: 6));
    expect(find.text('Undo'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect((await FriendsService.getAllFriends()).single.name, 'Anna');
  });

  testWidgets('the undo snackbar sits above the navigation bar',
      (tester) async {
    await _init();
    await _pumpShell(tester);
    await _deleteFromDetail(tester);

    final snackBarBottom = tester.getBottomLeft(find.byType(SnackBar)).dy;
    final navTop = tester.getTopLeft(find.byType(NavigationBar)).dy;
    expect(snackBarBottom, lessThanOrEqualTo(navTop));
  });

  testWidgets('undo goes away after its duration', (tester) async {
    await _init();
    await _pumpShell(tester);
    await _deleteFromDetail(tester);
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
    expect(find.text('Anna removed'), findsNothing);
  });
}
