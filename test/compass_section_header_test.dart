import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_service.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_screen.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

import 'support/compass_test_app.dart';

Finder _inSomeday(Finder finder) => find.descendant(
    of: find.byKey(const ValueKey('compass_someday_section')),
    matching: finder);

void main() {
  setUpAll(() => initializeDateFormatting());

  for (final lang in AppLocalizations.supportedLanguages) {
    testWidgets('in $lang the Someday count keeps clear of the subtitle',
        (tester) async {
      await initCompassTest(lang: lang);
      await CompassService.addIntention(
          title: 'Learn to sail', status: IntentionStatus.someday);
      await pumpCompassApp(tester, CompassScreen(now: compassToday),
          size: const Size(393, 4000));

      final l10n = AppLocalizations(Locale(lang));
      final subtitle = [
        l10n.plural('compass_someday_waiting', 1),
        l10n.translate('compass_someday_fine'),
      ].join(' ');
      final subtitleRect = tester.getRect(_inSomeday(find.text(subtitle)));
      final countRect = tester.getRect(_inSomeday(find.text('1')));
      expect(subtitleRect.overlaps(countRect), isFalse);
      expect(countRect.left - subtitleRect.right,
          greaterThanOrEqualTo(12 - 0.01));
      expect(tester.takeException(), isNull);
    });
  }
}
