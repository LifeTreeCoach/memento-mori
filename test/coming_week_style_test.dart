import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/life/coming_week_style.dart';
import 'package:memento_mori_life_in_weeks/theme/app_theme.dart';
import 'package:memento_mori_life_in_weeks/theme/contrast.dart';
import 'package:memento_mori_life_in_weeks/theme/phase_palette.dart';
import 'package:memento_mori_life_in_weeks/theme/theme_options.dart';

const _style = ComingWeekStyle(
  fill: Color(0xFFFAF8F4),
  frame: Color(0xFF111111),
  ring: Color(0xFFD4973A),
);

Future<Color> _pixel(ui.Image image, Offset at) async {
  final data = await image.toByteData();
  final i = (at.dy.floor() * image.width + at.dx.floor()) * 4;
  final b = data!.buffer.asUint8List();
  return Color.fromARGB(b[i + 3], b[i], b[i + 1], b[i + 2]);
}

void main() {
  test('widths grow with the cell and never get thinner than the minimum',
      () {
    expect(ComingWeekStyle.frameWidthOf(4), ComingWeekStyle.minFrame);
    expect(ComingWeekStyle.ringWidthOf(4), ComingWeekStyle.minRing);
    expect(ComingWeekStyle.frameWidthOf(40), 40 * ComingWeekStyle.frameShare);
    expect(ComingWeekStyle.ringWidthOf(40), 40 * ComingWeekStyle.ringShare);
  });

  test('paints the light fill, the ink frame inside and the ring outside',
      () async {
    const cell = Rect.fromLTWH(20, 20, 40, 40);
    final recorder = ui.PictureRecorder();
    _style.paint(Canvas(recorder), cell, 4);
    final image = await recorder.endRecording().toImage(80, 80);
    final frame = ComingWeekStyle.frameWidthOf(cell.width);
    final ring = ComingWeekStyle.ringWidthOf(cell.width);
    expect(await _pixel(image, cell.center), isSameColorAs(_style.fill));
    expect(
      await _pixel(image, Offset(cell.left + frame / 2, cell.center.dy)),
      isSameColorAs(_style.frame),
    );
    expect(
      await _pixel(image, Offset(cell.left - ring / 2, cell.center.dy)),
      isSameColorAs(_style.ring),
    );
    image.dispose();
  });

  test('opacity 0 paints nothing', () async {
    final recorder = ui.PictureRecorder();
    _style.paint(Canvas(recorder), const Rect.fromLTWH(10, 10, 20, 20), 2,
        opacity: 0);
    final image = await recorder.endRecording().toImage(40, 40);
    expect((await _pixel(image, const Offset(20, 20))).a, 0);
    image.dispose();
  });

  for (final style in ThemeStyle.values) {
    for (final brightness in Brightness.values) {
      testWidgets('of: surface fill, ink frame, readable gold ring in '
          '${style.name} ${brightness.name}', (tester) async {
        late ComingWeekStyle coming;
        late ThemeData theme;
        await tester.pumpWidget(MaterialApp(
          theme: AppTheme.build(style: style, brightness: brightness),
          home: Builder(builder: (context) {
            coming = ComingWeekStyle.of(context);
            theme = Theme.of(context);
            return const SizedBox();
          }),
        ));
        final scheme = theme.colorScheme;
        expect(coming.fill, scheme.surface);
        expect(coming.frame, scheme.onSurface);
        expect(contrastRatio(coming.ring, scheme.surface),
            greaterThanOrEqualTo(PhaseColors.minRingContrast));
        expect(contrastRatio(coming.frame, coming.fill), greaterThan(7));
      });
    }
  }
}
