import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/theme/app_theme.dart';
import 'package:memento_mori_life_in_weeks/theme/theme_options.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_anchor.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_anchors.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_result.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_runner.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_step.dart';

/// A dummy scrolling screen with anchors 'a' (top), 'b' (far below) and
/// 'c' (further below), plus a "start" button that runs a tour.
class TourHarness {
  final TourAnchors anchors = TourAnchors();
  TourResult? result;
}

TourStep tourStep(String id, String? anchorId) =>
    TourStep(id: id, anchorId: anchorId, titleKey: 'Title $id', bodyKey: 'Body $id');

Finder boxOf(String anchorId) => find.byKey(ValueKey('box_$anchorId'));

Future<TourHarness> pumpTourScreen(
  WidgetTester tester,
  List<TourStep> steps, {
  Brightness brightness = Brightness.light,
  bool disableAnimations = false,
  Size size = const Size(400, 800),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final harness = TourHarness();
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.build(style: ThemeStyle.stoic, brightness: brightness),
    locale: const Locale('en'),
    supportedLocales: const [Locale('en')],
    localizationsDelegates: const [
      AppLocalizationsDelegate(),
      ...GlobalMaterialLocalizations.delegates,
    ],
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
          disableAnimations: disableAnimations,
          textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: TourAnchorScope(
      anchors: harness.anchors,
      child: Builder(builder: (context) => _screen(context, harness, steps)),
    ),
  ));
  await tester.pumpAndSettle();
  return harness;
}

Widget _anchoredBox(String id) => TourAnchor(
    id: id, child: Container(key: ValueKey('box_$id'), height: 80));

Widget _screen(BuildContext context, TourHarness harness, List<TourStep> steps) {
  return Scaffold(
    // Not a lazy ListView: anchors must be built to be found.
    body: SingleChildScrollView(child: Column(children: [
      _anchoredBox('a'),
      const SizedBox(height: 1200),
      _anchoredBox('b'),
      const SizedBox(height: 400),
      _anchoredBox('c'),
      const SizedBox(height: 200),
    ])),
    floatingActionButton: FloatingActionButton(
      key: const ValueKey('start'),
      onPressed: () async =>
          harness.result = await runTour(context, steps, harness.anchors),
      child: const Icon(Icons.play_arrow),
    ),
  );
}

Future<void> startTour(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('start')));
  await tester.pumpAndSettle();
}
