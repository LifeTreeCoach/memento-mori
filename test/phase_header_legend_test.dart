import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:memento_mori_life_in_weeks/compass/life_phase.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_fractions.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_labels.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_timeline.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/lifespan_preview_card.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase_header.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

import 'support/compass_test_app.dart';

/// Four earlier phases and a current one with a plan, so the legend wraps.
List<PhaseSpan> _spans() {
  final phases = [
    (PhasePreset.childhood, DateTime(1990, 11, 17), DateTime(1997, 9, 1)),
    (PhasePreset.school, DateTime(1997, 9, 1), DateTime(2009, 10, 1)),
    (PhasePreset.study, DateTime(2009, 10, 1), DateTime(2015, 3, 1)),
    (PhasePreset.careerStart, DateTime(2015, 3, 1), DateTime(2020, 1, 1)),
  ];
  return [
    for (final (preset, start, end) in phases)
      PhaseSpan(
        phase: LifePhase(id: preset.name, preset: preset, start: start),
        start: start,
        end: end,
        isCurrent: false,
      ),
    PhaseSpan(
      phase: LifePhase(
        id: 'now',
        preset: PhasePreset.buildUp,
        start: DateTime(2020, 1, 1),
        plannedEnd: DateTime(2028, 11, 1),
      ),
      start: DateTime(2020, 1, 1),
      isCurrent: true,
    ),
  ];
}

/// The text of every line of [paragraph], laid out at its width.
List<String> _lines(RenderParagraph paragraph, String text) {
  final painter = TextPainter(
    text: paragraph.text,
    textDirection: paragraph.textDirection,
    textScaler: paragraph.textScaler,
  )..layout(maxWidth: paragraph.constraints.maxWidth);
  addTearDown(painter.dispose);
  final lines = <String>[];
  var offset = 0;
  while (offset < text.length) {
    final range = painter.getLineBoundary(TextPosition(offset: offset));
    lines.add(text.substring(range.start, range.end));
    offset = range.end > offset ? range.end : offset + 1;
  }
  return lines;
}

void main() {
  setUpAll(() async {
    for (final lang in AppLocalizations.supportedLanguages) {
      await initializeDateFormatting(lang);
    }
  });

  test('joinPhaseNames keeps the separator on the previous line', () {
    expect(joinPhaseNames(['A', 'B c', 'D']), 'A · B c · D');
    expect(joinPhaseNames(['A']), 'A');
  });

  group('earlier phases legend at 393 wide', () {
    for (final lang in AppLocalizations.supportedLanguages) {
      testWidgets('never starts a line with "·" in $lang', (tester) async {
        await initCompassTest(lang: lang);
        await pumpCompassApp(
          tester,
          Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: PhaseHeader(
                spans: _spans(),
                today: compassToday,
                birthDate: compassBirthDate,
                lifeExpectancyYears: 80,
                onEdit: () {},
                onExtend: () {},
                onClose: () {},
              ),
            ),
          ),
          size: const Size(393, 851),
        );
        final legend = find.textContaining(' · ');
        expect(legend, findsOneWidget);
        final text = tester.widget<Text>(legend).data!;
        final paragraph = tester.renderObject<RenderParagraph>(
            find.descendant(of: legend, matching: find.byType(RichText)));
        final lines = _lines(paragraph, text);
        expect(lines.length, greaterThan(1), reason: 'legend should wrap');
        for (final line in lines) {
          expect(line.trimLeft().startsWith('·'), isFalse,
              reason: '"$line" in $lines');
        }
      });
    }
  });

  testWidgets('the preview card announces its lifespan share once',
      (tester) async {
    await initCompassTest(lang: 'de');
    final semantics = tester.ensureSemantics();
    await pumpCompassApp(
      tester,
      const Scaffold(
        body: LifespanPreviewCard(
          name: 'Familie',
          months: 26,
          fractions: LifespanBarFractions(
              phaseStart: 0.4, today: 0.45, plannedEnd: 0.5),
          share: 0.05,
          lifeExpectancyYears: 80,
        ),
      ),
      size: const Size(393, 851),
    );
    expect(find.text('5\u00A0% deiner Lebensspanne'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('deiner Lebensspanne')),
        findsOneWidget);
    semantics.dispose();
  });
}
