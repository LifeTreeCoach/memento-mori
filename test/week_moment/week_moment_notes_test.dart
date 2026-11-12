import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_service.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_moment_notes.dart';

import '../support/compass_test_app.dart';

void main() {
  const notes = WeekMomentNotes();
  final day = DateTime(2026, 11, 8, 19, 30);

  setUp(() => initCompassTest());

  group('savable', () {
    test('trims, and a blank text saves nothing', () {
      expect(WeekMomentNotes.savable('  A walk  '), 'A walk');
      for (final blank in ['', '   ', '\n\t']) {
        expect(WeekMomentNotes.savable(blank), isNull);
      }
    });
  });

  group('keepMoment', () {
    test('saves what was beautiful as a moment on that day', () async {
      final moment = await notes.keepMoment(' A walk on Sunday ', day: day);
      expect(moment, isNotNull);
      final data = await CompassService.load();
      expect(data.moments, hasLength(1));
      expect(data.moments.single.title, 'A walk on Sunday');
      expect(data.moments.single.date, DateTime(2026, 11, 8));
    });

    test('a blank text saves nothing', () async {
      expect(await notes.keepMoment('  ', day: day), isNull);
      expect((await CompassService.load()).moments, isEmpty);
    });
  });

  group('planIntention', () {
    test('adds the one thing to "Now"', () async {
      final result = await notes.planIntention(' Call Anna ', day: day);
      expect(result!.nowLimitReached, isFalse);
      final saved = (await CompassService.load()).intentions.single;
      expect(saved.title, 'Call Anna');
      expect(saved.status, IntentionStatus.now);
    });

    test('a full "Now" sends it to "Someday" and says so', () async {
      for (var i = 0; i < nowLimit; i++) {
        await CompassService.addIntention(title: 'Now $i', today: day);
      }
      final result = await notes.planIntention('One more', day: day);
      expect(result!.nowLimitReached, isTrue);
      expect(result.intention.status, IntentionStatus.someday);
    });

    test('a blank text adds nothing', () async {
      expect(await notes.planIntention('', day: day), isNull);
      expect((await CompassService.load()).intentions, isEmpty);
    });
  });
}
