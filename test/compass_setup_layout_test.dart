import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_setup_progress.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/phase_draft.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/phase/phase_edit_screen.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/setup/compass_setup_screen.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/setup/setup_rhythm_step.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/onboarding/step_layout.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_rhythm.dart';
import 'package:memento_mori_life_in_weeks/settings/reminder_rhythm_control.dart';

import 'support/compass_test_app.dart';

/// A Pixel 5 in logical pixels.
const Size _pixel5 = Size(393, 851);

/// The app's bundled fonts, so text sizes match the device.
Future<void> _loadAppFonts() async {
  const families = {
    'Inter': ['Inter-Regular', 'Inter-Medium', 'Inter-SemiBold'],
    'Fraunces': ['Fraunces-Regular', 'Fraunces-SemiBold'],
  };
  for (final entry in families.entries) {
    final loader = FontLoader(entry.key);
    for (final file in entry.value) {
      loader.addFont(rootBundle.load('assets/fonts/$file.ttf'));
    }
    await loader.load();
  }
}

Finder _key(String key) => find.byKey(ValueKey(key));

Rect _scrollArea(WidgetTester tester) =>
    tester.getRect(_key('step_layout_scroll'));

/// The scroll area ends above the action area, so nothing in it can ever
/// sit behind the buttons.
void _expectScrollAreaAboveActions(WidgetTester tester, String action) {
  final scroll = _scrollArea(tester);
  final actions = tester.getRect(find.byType(StepActions));
  expect(scroll.bottom, lessThanOrEqualTo(actions.top),
      reason: 'scroll area overlaps the actions');
  expect(tester.getRect(_key(action)).top,
      greaterThanOrEqualTo(scroll.bottom + StepLayout.actionGap - 0.01));
}

Future<void> _scrollToEnd(WidgetTester tester) async {
  await tester.drag(_key('step_layout_scroll'), const Offset(0, -2000));
  await tester.pumpAndSettle();
}

/// Fully scrolled, the preview card lies inside the scroll area and above
/// the fade at its lower edge.
void _expectCardFullyVisible(WidgetTester tester) {
  final card = tester.getRect(_key('phase_preview_card'));
  final scroll = _scrollArea(tester);
  expect(card.top, greaterThanOrEqualTo(scroll.top));
  expect(card.bottom,
      lessThanOrEqualTo(scroll.bottom - StepLayout.fadeHeight),
      reason: 'card reaches into the fade / behind the buttons');
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
    await _loadAppFonts();
  });

  group('setup step 1 on a 393x851 phone', () {
    for (final lang in AppLocalizations.supportedLanguages) {
      testWidgets('the preview card is never behind the buttons ($lang)',
          (tester) async {
        await initCompassTest(lang: lang);
        await pumpCompassApp(
          tester,
          CompassSetupScreen(
            start: SetupStep.phase,
            today: compassToday,
            birthDate: compassBirthDate,
            lifeExpectancyYears: 80,
          ),
          size: _pixel5,
        );
        await tester.tap(_key('phase_preset_buildUp'));
        await tester.pumpAndSettle();
        _expectScrollAreaAboveActions(tester, 'phase_apply');
        expect(_key('phase_start_today'), findsOneWidget);
        await _scrollToEnd(tester);
        _expectCardFullyVisible(tester);
        expect(tester.takeException(), isNull);
      });
    }
  });

  testWidgets('the phase editor keeps the card clear of the buttons',
      (tester) async {
    await initCompassTest(lang: 'de');
    await pumpCompassApp(
      tester,
      PhaseEditScreen(
        draft: PhaseDraft(
          today: compassToday,
          birthDate: compassBirthDate,
          lifeExpectancyYears: 80,
        ),
      ),
      size: _pixel5,
    );
    await tester.tap(_key('phase_preset_buildUp'));
    await tester.pumpAndSettle();
    _expectScrollAreaAboveActions(tester, 'phase_apply');
    await _scrollToEnd(tester);
    _expectCardFullyVisible(tester);
  });

  group('setup step 4 rhythm on a 393x851 phone', () {
    for (final lang in AppLocalizations.supportedLanguages) {
      testWidgets('every segment label stays on one line ($lang)',
          (tester) async {
        await initCompassTest(lang: lang);
        await pumpCompassApp(
          tester,
          Scaffold(
            body: SafeArea(
              child: SetupRhythmStep(
                initial: ReminderRhythm.every4Weeks,
                onConfirm: (_) async {},
              ),
            ),
          ),
          size: _pixel5,
        );
        expect(tester.takeException(), isNull);
        for (final rhythm in ReminderRhythm.values) {
          final key = ReminderRhythmControl.labelKey(rhythm);
          final label = tester.renderObject<RenderParagraph>(_key(key));
          // One line = the height of the text laid out without width limit.
          final lineHeight = label.getMinIntrinsicHeight(double.infinity);
          expect(label.size.height, lessThan(lineHeight * 1.5),
              reason: '$lang $key wraps');
          expect(label.didExceedMaxLines, isFalse, reason: '$lang $key');
        }
      });
    }
  });
}
