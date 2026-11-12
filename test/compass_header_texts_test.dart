import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_prompt.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_prompts.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_labels.dart';
import 'package:memento_mori_life_in_weeks/compass/ui/compass_labels.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

const _nbsp = ' ';

void main() {
  final en = AppLocalizations(const Locale('en'));
  final de = AppLocalizations(const Locale('de'));
  final fr = AppLocalizations(const Locale('fr'));
  final es = AppLocalizations(const Locale('es'));

  group('sinceLongText', () {
    test('years and months in full words with plurals', () {
      expect(de.sinceLongText(32), 'Seit 2${_nbsp}Jahren und 8${_nbsp}Monaten');
      expect(de.sinceLongText(13), 'Seit 1${_nbsp}Jahr und 1${_nbsp}Monat');
      expect(en.sinceLongText(32), 'For 2${_nbsp}years and 8${_nbsp}months');
      expect(fr.sinceLongText(14), 'Depuis 1${_nbsp}an et 2${_nbsp}mois');
      expect(es.sinceLongText(25), 'Desde hace 2${_nbsp}años y 1${_nbsp}mes');
    });

    test('only years or only months', () {
      expect(de.sinceLongText(36), 'Seit 3${_nbsp}Jahren');
      expect(de.sinceLongText(5), 'Seit 5${_nbsp}Monaten');
      expect(en.sinceLongText(1), 'For 1${_nbsp}month');
    });

    test('less than a month has just begun', () {
      expect(de.sinceLongText(0), 'Gerade begonnen');
      expect(en.sinceLongText(0), 'Just begun');
    });

    test('the compact form stays for other places', () {
      expect(de.sinceText(32), 'seit 2${_nbsp}J 8${_nbsp}M');
    });
  });

  group('plannedLeftText', () {
    test('months, else weeks', () {
      expect(de.plannedLeftText(months: 6, weeks: 26),
          'Geplant: noch etwa 6${_nbsp}Monate');
      expect(de.plannedLeftText(months: 0, weeks: 3),
          'Geplant: noch etwa 3${_nbsp}Wochen');
      expect(de.plannedLeftText(months: 0, weeks: 0), isNull);
    });
  });

  group('question topic', () {
    const plain = CompassPrompt(
      id: 'p',
      kind: CompassPromptKind.pride,
      text: {'en': 'Q'},
    );
    const topical = CompassPrompt(
      id: 't',
      kind: CompassPromptKind.pride,
      text: {'en': 'Q'},
      topic: {'en': 'Small gestures', 'de': 'Kleine Gesten'},
    );

    test('a prompt topic replaces the kind name', () {
      expect(de.questionTopicLabel(topical), 'Kleine Gesten');
      expect(fr.questionTopicLabel(topical), 'Small gestures');
      expect(de.questionTopicLabel(plain), 'Was gut lief');
    });

    test('the small gestures question carries its topic', () {
      final prompt =
          compassQuestions.singleWhere((p) => p.id == 'pride_everyday_care');
      expect(de.questionTopicLabel(prompt), 'Kleine Gesten');
      expect(es.questionTopicLabel(prompt), 'Pequeños gestos');
    });
  });
}
