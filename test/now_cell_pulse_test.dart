import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/app_settings_controller.dart';
import 'package:memento_mori_life_in_weeks/life/now_cell_pulse.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:memento_mori_life_in_weeks/life/visualization_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppSettingsController> _settings({required bool animations}) async {
  SharedPreferences.setMockInitialValues({
    'language': 'en',
    'visualization_settings':
        jsonEncode(VisualizationSettings(enableAnimations: animations).toMap()),
  });
  await SettingsService.initialize();
  return AppSettingsController();
}

Widget _pulse(AppSettingsController settings, {bool visible = true}) {
  return AppSettingsScope(
    controller: settings,
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: TickerMode(
        enabled: visible,
        child: const Stack(children: [
          NowCellPulse(
            cell: Rect.fromLTWH(10, 10, 8, 8),
            radius: 2,
            color: Colors.amber,
          ),
        ]),
      ),
    ),
  );
}

void main() {
  testWidgets('breathes briefly, then stops scheduling frames', (tester) async {
    final settings = await _settings(animations: true);
    await tester.pumpWidget(_pulse(settings));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.binding.hasScheduledFrame, isTrue);

    await tester.pump(const Duration(seconds: 15));
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('breathes again when its tab becomes visible', (tester) async {
    final settings = await _settings(animations: true);
    await tester.pumpWidget(_pulse(settings));
    await tester.pump(const Duration(seconds: 15));
    await tester.pumpWidget(_pulse(settings, visible: false));
    await tester.pumpWidget(_pulse(settings));
    expect(tester.binding.hasScheduledFrame, isTrue);

    await tester.pump(const Duration(seconds: 15));
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('stays static when animations are off', (tester) async {
    final settings = await _settings(animations: false);
    await tester.pumpWidget(_pulse(settings));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('stops live when animations are turned off', (tester) async {
    final settings = await _settings(animations: true);
    await tester.pumpWidget(_pulse(settings));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.binding.hasScheduledFrame, isTrue);

    settings.setVisualization(
        settings.visualization.copyWith(enableAnimations: false));
    await tester.pump(); // rebuild and paint the settled glow
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('respects the OS reduce-motion setting', (tester) async {
    final settings = await _settings(animations: true);
    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: _pulse(settings),
    ));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
