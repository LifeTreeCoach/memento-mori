import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:memento_mori_life_in_weeks/compass/life_phase.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/onboarding/personal_address.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_rhythm.dart';
import 'package:memento_mori_life_in_weeks/week_moment/ui/week_moment_texts.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_moment_sequence.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_moment_story.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_turn.dart';

const _nbsp = '\u00A0';

WeekMomentTexts _texts(String lang, {String name = ''}) => WeekMomentTexts(
  AppLocalizations(Locale(lang)),
  address: PersonalAddress(name),
);

YearMoment _year({
  int yearNumber = 37,
  int weeksUntilBirthday = 34,
  int daysUntilBirthday = 240,
  bool justBegan = false,
}) => YearMoment(
  yearNumber: yearNumber,
  yearStart: 1904,
  length: 52,
  filled: 18,
  passedFrom: 1921,
  passedTo: 1922,
  weeksUntilBirthday: weeksUntilBirthday,
  daysUntilBirthday: daysUntilBirthday,
  justBegan: justBegan,
);

PhaseMoment _phase({int? plannedLeft, bool overdue = false}) => PhaseMoment(
  phase: LifePhase(
    id: 'p',
    preset: PhasePreset.buildUp,
    start: DateTime(2025, 6, 1),
  ),
  weekInPhase: 1234,
  plannedLeft: plannedLeft,
  overdue: overdue,
  from: 1800,
  to: 1923,
  runs: const [],
);

LifeMoment _life({int total = 4160, int lived = 1922, bool beyond = false}) =>
    LifeMoment(
      totalWeeks: total,
      weeksLived: lived,
      weeksRemaining: beyond ? 0 : total - lived,
      beyond: beyond,
      runs: const [],
    );

void main() {
  setUpAll(() => initializeDateFormatting());

  group('week act', () {
    test('one week passed, never with the name', () {
      expect(_texts('en').passedLine(1), 'Another week has passed.');
      expect(
        _texts('de', name: ' Daniel ').passedLine(1),
        'Wieder ist eine Woche vergangen.',
      );
    });

    test('four weeks passed for the 4-week rhythm', () {
      expect(_texts('en').passedLine(4), 'Another 4${_nbsp}weeks have passed.');
      expect(
        _texts('es', name: 'Ana').passedLine(4),
        'Han pasado otras 4${_nbsp}semanas.',
      );
    });

    test('weeks left in the year of life, with the ordinal', () {
      expect(
        _texts('en').yearLine(_year()),
        'In your 37th${_nbsp}year of life, 34${_nbsp}weeks remain.',
      );
      expect(
        _texts('de').yearLine(_year(weeksUntilBirthday: 1)),
        'In deinem 37.${_nbsp}Lebensjahr bleibt noch 1${_nbsp}Woche.',
      );
      expect(
        _texts('fr').yearLine(_year(yearNumber: 1)),
        'Dans ta 1re${_nbsp}année de vie, il reste 34${_nbsp}semaines.',
      );
    });

    test('week 53: the coming year begins in a few days', () {
      final year = _year(weeksUntilBirthday: 0, daysUntilBirthday: 3);
      expect(
        _texts('en').yearLine(year),
        'Your 38th${_nbsp}year of life begins in 3${_nbsp}days.',
      );
      expect(
        _texts('es')
            .yearLine(_year(weeksUntilBirthday: 0, daysUntilBirthday: 1)),
        'Tu 38.º${_nbsp}año de vida empieza en 1${_nbsp}día.',
      );
    });

    test('birthday week: a new year has begun', () {
      final year = _year(justBegan: true, weeksUntilBirthday: 51);
      expect(
        _texts('de').yearLine(year),
        'Ein neues Lebensjahr hat gerade begonnen$_nbsp– dein 37.',
      );
      expect(
        _texts('en').yearLine(year),
        'A new year of life has just begun$_nbsp– your 37th.',
      );
    });
  });

  group('phase act', () {
    test('week of the phase with grouped number and preset name', () {
      expect(
        _texts('en').phaseWeekLine(_phase()),
        'Week${_nbsp}1,234 of your phase “Building up”.',
      );
    });

    test('planned weeks left', () {
      expect(
        _texts('en').phaseRestLine(_phase(plannedLeft: 1)),
        '1${_nbsp}more planned week lies ahead.',
      );
      expect(
        _texts('de').phaseRestLine(_phase(plannedLeft: 30)),
        'Geplant sind noch 30${_nbsp}Wochen.',
      );
    });

    test('open-ended or overdue phase has room as long as it needs', () {
      expect(
        _texts('en').phaseRestLine(_phase()),
        'It has room for as long as it needs.',
      );
      expect(
        _texts('de').phaseRestLine(_phase(overdue: true)),
        'Sie hat Raum, solange sie braucht.',
      );
    });
  });

  group('life act', () {
    test('weeks ahead, grouped in the app language', () {
      expect(
        _texts('de').lifeLine(_life()),
        'Von etwa 4.160${_nbsp}Wochen liegen etwa 2.238${_nbsp}noch vor dir'
        '$_nbsp– Raum für das, was zählt.',
      );
      expect(
        _texts('en').lifeLine(_life(lived: 4159)),
        contains('about 1${_nbsp}still lies ahead of you'),
      );
    });

    test('beyond the life expectancy every week is a gift', () {
      expect(
        _texts('en').lifeLine(_life(beyond: true)),
        'Every week from here on is a gift.',
      );
    });
  });

  group('closing steps', () {
    const turn = WeekTurn(endedWeek: 45, nextWeek: 46);

    test('only the closing title greets by name', () {
      final named = _texts('de', name: 'Daniel');
      final close = named.closingLines(ClosingStep.close);
      expect(close.main, 'Daniel, die Woche ist vorbei.');
      expect(
        close.detail,
        'Was war schön daran? Halte es kurz fest$_nbsp– in Gedanken oder in '
        'einem Satz.',
      );
      final plan = named.closingLines(ClosingStep.plan);
      expect(plan.main, 'Die neue Woche gehört dir.');
      expect(plan.detail, 'Wofür soll sie Platz haben?');
      expect(
        _texts('de').closingLines(ClosingStep.close).main,
        'Die Woche ist vorbei.',
      );
      expect(
        _texts('en', name: 'Daniel').closingLines(ClosingStep.close).main,
        'Daniel, the week is over.',
      );
    });

    test('the final act shows the first step and no top eyebrow', () {
      final texts = _texts('en', name: 'Daniel');
      expect(texts.eyebrow(WeekMomentAct.next), isNull);
      expect(
        texts.linesFor(WeekMomentAct.next, _story()).main,
        'Daniel, the week is over.',
      );
    });

    test('eyebrows name the ended and the next ISO week', () {
      final de = _texts('de');
      final story = _story(plannedEnd: DateTime(2026, 12, 24));
      expect(
        de.stepEyebrow(ClosingStep.close, turn, story),
        'Woche${_nbsp}45$_nbsp· abgeschlossen',
      );
      expect(
        de.stepEyebrow(ClosingStep.plan, turn, story),
        'Woche${_nbsp}46$_nbsp· noch 6 in dieser Phase',
      );
      expect(de.stepCounter(ClosingStep.close), '1 von 2');
      expect(de.stepCounter(ClosingStep.plan), '2 von 2');
    });

    test('without planned phase weeks the plan eyebrow counts the year', () {
      final en = _texts('en');
      expect(
        en.stepEyebrow(ClosingStep.plan, turn, _story()),
        'Week${_nbsp}46$_nbsp· 34 more in this year of life',
      );
    });

    test('a birthday within days leaves just the week', () {
      final story = WeekMomentStory.of(
        birthDate: DateTime(1990, 11, 14),
        lifeExpectancyYears: 80,
        today: DateTime(2026, 11, 12),
        phases: const [],
        rhythm: ReminderRhythm.weekly,
        showPhases: true,
      );
      expect(story.year.weeksUntilBirthday, 0);
      expect(
        _texts('en').stepEyebrow(ClosingStep.plan, turn, story),
        'Week${_nbsp}46',
      );
    });

    test('every step has all its texts in every language', () {
      for (final lang in AppLocalizations.supportedLanguages) {
        final texts = _texts(lang);
        for (final step in ClosingStep.values) {
          for (final text in [
            texts.closingLines(step).main,
            texts.closingLines(step).detail!,
            texts.fieldLabel(step),
            texts.fieldHint(step),
            texts.primaryAction(step),
            texts.secondaryAction(step),
            texts.stepCounter(step),
            texts.stepEyebrow(step, turn, _story()),
          ]) {
            expect(text, isNot(startsWith('week_moment_')), reason: lang);
            expect(text, isNot(contains('{')), reason: '$lang: $text');
          }
        }
      }
    });
  });

  test('every act before the final one has an eyebrow in every language', () {
    for (final lang in AppLocalizations.supportedLanguages) {
      for (final act in WeekMomentAct.values.where((a) => a != WeekMomentAct.next)) {
        final eyebrow = _texts(lang).eyebrow(act);
        expect(eyebrow, isNotNull, reason: lang);
        expect(eyebrow, isNot(startsWith('week_moment_')), reason: lang);
      }
    }
  });

  test('every act of a real story has lines', () {
    final story = _story();
    for (final act in story.acts) {
      final lines = _texts('fr').linesFor(act, story);
      expect(lines.main, isNotEmpty, reason: '$act');
      expect(lines.main, isNot(contains('{')), reason: '$act');
      expect(lines.detail ?? '', isNot(contains('{')), reason: '$act');
    }
  });
}

WeekMomentStory _story({DateTime? plannedEnd}) => WeekMomentStory.of(
  birthDate: DateTime(1990, 7, 10),
  lifeExpectancyYears: 80,
  today: DateTime(2026, 11, 12),
  phases: [
    LifePhase(
      id: 'p',
      preset: PhasePreset.buildUp,
      start: DateTime(2025, 6, 1),
      plannedEnd: plannedEnd,
    ),
  ],
  rhythm: ReminderRhythm.weekly,
  showPhases: true,
);
