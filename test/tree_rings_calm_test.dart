import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/app_settings_controller.dart';
import 'package:memento_mori_life_in_weeks/life/alternative_layout_view.dart';
import 'package:memento_mori_life_in_weeks/life/layouts/tree_rings_layout_painter.dart';
import 'package:memento_mori_life_in_weeks/life/visualization_settings.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:memento_mori_life_in_weeks/theme/breath.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _size = Size(400, 400);

TreeRingsLayoutPainter _painter({
  double animationValue = 0,
  double boundaryEmphasis = 0,
}) =>
    TreeRingsLayoutPainter(
      totalItems: 80,
      itemsCompleted: 36,
      colorTheme: 'default',
      visualSettings: const VisualizationSettings(enableAnimations: true),
      animationValue: animationValue,
      lifeExpectancyYears: 80,
      ageYears: 36.5,
      boundaryEmphasis: boundaryEmphasis,
    );

Future<Uint8List> _render(TreeRingsLayoutPainter painter) async {
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), _size);
  final image = await recorder
      .endRecording()
      .toImage(_size.width.toInt(), _size.height.toInt());
  final bytes = await image.toByteData();
  image.dispose();
  return bytes!.buffer.asUint8List();
}

Future<AppSettingsController> _settings() async {
  SharedPreferences.setMockInitialValues({
    'language': 'en',
    'visualization_settings': jsonEncode(
        const VisualizationSettings(enableAnimations: true).toMap()),
  });
  await SettingsService.initialize();
  return AppSettingsController();
}

/// Pumps [view] plus one frame: the app's localizations load
/// asynchronously, so the layout view is built a frame later.
Future<void> _pumpView(WidgetTester tester, Widget view) async {
  await tester.pumpWidget(view);
  await tester.pump();
}

Widget _view(
  AppSettingsController settings,
  LayoutType layout, {
  bool reduceMotion = false,
  bool visible = true,
}) {
  return AppSettingsScope(
    controller: settings,
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        ...GlobalMaterialLocalizations.delegates,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: TickerMode(enabled: visible, child: child!),
      ),
      home: SizedBox.square(
        dimension: 200,
        child: AlternativeLayoutView(
          settings: VisualizationSettings(
            layoutType: layout,
            enableAnimations: true,
          ),
          totalItems: 80,
          itemsCompleted: 36,
          colorThemeId: 'default',
          lifeExpectancyYears: 80,
          semanticsLabel: 'life',
          ageYears: 36.5,
        ),
      ),
    ),
  );
}

double _emphasis(WidgetTester tester) {
  final paint = tester.widget<CustomPaint>(find.descendant(
    of: find.byType(AlternativeLayoutView),
    matching: find.byType(CustomPaint),
  ));
  return (paint.painter! as TreeRingsLayoutPainter).boundaryEmphasis;
}

void main() {
  group('TreeRingsLayoutPainter', () {
    test('paints the same for every animation value (no growth ring)',
        () async {
      final still = await _render(_painter(animationValue: 0));
      expect(await _render(_painter(animationValue: 0.37)), still);
      expect(await _render(_painter(animationValue: 0.81)), still);
    });

    test('an emphasized boundary paints differently', () async {
      final still = await _render(_painter());
      expect(await _render(_painter(boundaryEmphasis: 1)), isNot(still));
    });

    test('repaints when the emphasis changes', () {
      expect(_painter().shouldRepaint(_painter(boundaryEmphasis: 0.5)), isTrue);
      expect(_painter().shouldRepaint(_painter()), isFalse);
    });
  });

  group('BreathTween', () {
    test('starts and ends at rest', () {
      const tween = BreathTween(3);
      expect(tween.transform(0), closeTo(1, 1e-9));
      expect(tween.transform(1), closeTo(1, 1e-9));
      expect(tween.transform(1 / 6), closeTo(0, 1e-9));
    });
  });

  group('AlternativeLayoutView tree rings', () {
    testWidgets('emphasis breathes, then settles with no ticker',
        (tester) async {
      final settings = await _settings();
      await _pumpView(tester, _view(settings, LayoutType.treeRings));
      await tester.pump(const Duration(seconds: 2));
      expect(_emphasis(tester), greaterThan(0));

      await tester.pump(const Duration(seconds: 12));
      await tester.pumpAndSettle();
      expect(_emphasis(tester), 0);
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('breathes again when its tab becomes visible', (tester) async {
      final settings = await _settings();
      await _pumpView(tester, _view(settings, LayoutType.treeRings));
      await tester.pumpAndSettle();
      await tester.pumpWidget(
          _view(settings, LayoutType.treeRings, visible: false));
      await _pumpView(tester, _view(settings, LayoutType.treeRings));
      await tester.pump(const Duration(seconds: 2));
      expect(_emphasis(tester), greaterThan(0));
      await tester.pumpAndSettle();
      expect(_emphasis(tester), 0);
    });

    testWidgets('reduced motion starts no animation', (tester) async {
      final settings = await _settings();
      await _pumpView(
          tester, _view(settings, LayoutType.treeRings, reduceMotion: true));
      expect(tester.binding.transientCallbackCount, 0); // no ticking
      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(_emphasis(tester), 0);
    });
  });

  testWidgets('spiral keeps looping', (tester) async {
    final settings = await _settings();
    await _pumpView(tester, _view(settings, LayoutType.spiral));
    await tester.pump(const Duration(seconds: 30));
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pumpWidget(const SizedBox());
  });
}
