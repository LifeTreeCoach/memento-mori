import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/life_phase.dart';

void main() {
  final intention = Intention(
    id: 'i1',
    title: 'Call grandma more often',
    note: 'Sundays',
    area: LifeArea.relationships,
    horizon: const Horizon.byAge(50),
    status: IntentionStatus.done,
    createdAt: DateTime(2026, 3, 1, 14, 30),
    doneAt: DateTime(2026, 4, 2),
  );
  final moment = Moment(
    id: 'm1',
    title: 'Hiked the Zugspitze',
    date: DateTime(2019, 8, 14),
    area: LifeArea.adventure,
    fromIntentionId: 'i1',
  );

  group('Horizon', () {
    test('JSON round trip for every kind', () {
      for (final horizon in [
        Horizon.thisSeason,
        Horizon.thisYear,
        Horizon.someday,
        const Horizon.byAge(42),
      ]) {
        expect(Horizon.tryParse(horizon.toJson()), horizon);
      }
      expect(const Horizon.byAge(42).toJson(), 'byAge:42');
    });

    test('unknown values parse as null', () {
      for (final value in [null, 3, '', 'tomorrow', 'byAge:', 'byAge:x', 'byAge:-1']) {
        expect(Horizon.tryParse(value), isNull, reason: '$value');
      }
    });
  });

  group('Intention and Moment', () {
    test('round trip through JSON keeps every field, dates as yyyy-MM-dd', () {
      final json = jsonDecode(jsonEncode(intention.toJson())) as Map<String, dynamic>;
      expect(json['createdAt'], '2026-03-01');
      expect(json['doneAt'], '2026-04-02');
      final back = Intention.fromJson(json);
      expect(back.id, 'i1');
      expect(back.title, intention.title);
      expect(back.note, 'Sundays');
      expect(back.area, LifeArea.relationships);
      expect(back.horizon, const Horizon.byAge(50));
      expect(back.status, IntentionStatus.done);
      expect(back.createdAt, DateTime(2026, 3, 1));
      expect(back.doneAt, DateTime(2026, 4, 2));

      final m = Moment.fromJson(jsonDecode(jsonEncode(moment.toJson())));
      expect(m.date, DateTime(2019, 8, 14));
      expect(m.area, LifeArea.adventure);
      expect(m.fromIntentionId, 'i1');
      expect(moment.toJson()['date'], '2019-08-14');
    });

    test('optional fields are left out of the JSON', () {
      final minimal = Intention(id: 'x', title: 'Rest', createdAt: DateTime(2026));
      expect(minimal.toJson().keys, ['id', 'title', 'status', 'createdAt']);
    });

    test('the friend link survives JSON, copyWith and older data', () {
      final linked = Intention(
          id: 'x', title: 'Time with Anna', createdAt: DateTime(2026), friendId: 'anna');
      final parsed = Intention.fromJson(jsonDecode(jsonEncode(linked.toJson())));
      expect(parsed.friendId, 'anna');
      expect(parsed.copyWith(status: IntentionStatus.done).friendId, 'anna');
      final legacy = Intention.fromJson({'id': 'y', 'title': 'Time with Anna'});
      expect(legacy.friendId, isNull);
      expect(legacy.isOpen, isTrue);
    });

    test('missing or unknown fields fall back to defaults', () {
      final parsed = Intention.fromJson({
        'id': 'x',
        'title': 'Learn the cello',
        'area': 'bogus',
        'horizon': 'yesterday',
        'status': 'overdue',
        'doneAt': '2026-01-01',
      });
      expect(parsed.area, isNull);
      expect(parsed.horizon, isNull);
      expect(parsed.status, IntentionStatus.someday);
      expect(parsed.doneAt, isNull, reason: 'only done intentions keep doneAt');
    });

    test('entries without id or title are rejected', () {
      expect(() => Intention.fromJson({'title': 'x'}), throwsFormatException);
      expect(() => Intention.fromJson({'id': 'x', 'title': ' '}), throwsFormatException);
      expect(() => Moment.fromJson({'id': 'x', 'title': 'y'}), throwsFormatException);
      expect(() => Moment.fromJson({'id': 'x', 'title': 'y', 'date': 'nope'}),
          throwsFormatException);
    });
  });

  group('CompassData', () {
    test('round trip', () {
      final data = CompassData(intentions: [intention], moments: [moment]);
      final back = CompassData.fromJson(jsonDecode(jsonEncode(data.toJson())));
      expect(back.intentions.single.id, 'i1');
      expect(back.moments.single.id, 'm1');
    });

    test('tolerates missing lists, wrong types and broken entries', () {
      expect(CompassData.fromJson(null).isEmpty, isTrue);
      expect(CompassData.fromJson('nope').isEmpty, isTrue);
      expect(CompassData.fromJson(<String, dynamic>{}).isEmpty, isTrue);
      final data = CompassData.fromJson({
        'intentions': [intention.toJson(), 'x', 42, {'id': 'no title'}],
        'moments': 'not a list',
      });
      expect(data.intentions, hasLength(1));
      expect(data.moments, isEmpty);
    });

    test('nowCount, isNowFull and momentsBetween', () {
      Intention now(String id) => Intention(
          id: id, title: id, status: IntentionStatus.now, createdAt: DateTime(2026));
      final data = CompassData(
        intentions: [now('a'), now('b'), now('c')],
        moments: [
          Moment(id: '2', title: 'b', date: DateTime(2020, 1, 8)),
          Moment(id: '1', title: 'a', date: DateTime(2020, 1, 1)),
          Moment(id: '3', title: 'c', date: DateTime(2020, 1, 15)),
        ],
      );
      expect(data.nowCount, 3);
      expect(data.isNowFull, isTrue);
      final inRange = data.momentsBetween(
          DateTime.utc(2020, 1, 1), DateTime.utc(2020, 1, 15));
      expect(inRange.map((m) => m.id), ['1', '2']);
    });

    test('phases round trip and are only written when there are some', () {
      final phase = LifePhase(id: 'p', name: 'Sabbatical', start: DateTime(2026));
      final data = CompassData(phases: [phase]);
      expect(data.isEmpty, isFalse);
      final back = CompassData.fromJson(jsonDecode(jsonEncode(data.toJson())));
      expect(back.phases.single.name, 'Sabbatical');
      expect(CompassData(moments: [moment]).toJson().containsKey('phases'), isFalse);
    });

    test('old JSON without phases loads; broken phases are skipped', () {
      final old = CompassData.fromJson({'intentions': [intention.toJson()]});
      expect(old.phases, isEmpty);
      final broken = CompassData.fromJson({
        'phases': [
          {'id': 'p', 'start': '2020-01-01'},
          {'id': 'no start'},
          'x',
        ],
      });
      expect(broken.phases.single.id, 'p');
    });
  });

  group('kind, phase, due date and letting go', () {
    final base = Intention(id: 'k', title: 'Sail', createdAt: DateTime(2026));

    test('round trip through JSON keeps the new fields', () {
      final full = base
          .copyWith(kind: IntentionKind.enjoy, dueDate: DateTime(2027, 6, 1, 9))
          .withPhase('p1')
          .letGo(DateTime(2026, 11, 6, 20));
      final json = jsonDecode(jsonEncode(full.toJson())) as Map<String, dynamic>;
      expect(json['kind'], 'enjoy');
      expect(json['phaseId'], 'p1');
      expect(json['dueDate'], '2027-06-01');
      expect(json['letGoAt'], '2026-11-06');
      expect(json['status'], 'letGo');
      final back = Intention.fromJson(json);
      expect(back.kind, IntentionKind.enjoy);
      expect(back.phaseId, 'p1');
      expect(back.dueDate, DateTime(2027, 6, 1));
      expect(back.letGoAt, DateTime(2026, 11, 6));
      expect(back.status, IntentionStatus.letGo);
    });

    test('let-go intentions are not open, done ones neither', () {
      expect(base.letGo(DateTime(2026)).isOpen, isFalse);
      expect(base.copyWith(status: IntentionStatus.done).isOpen, isFalse);
      expect(base.copyWith(status: IntentionStatus.now).isOpen, isTrue);
      expect(base.isOpen, isTrue);
    });

    test('unknown kind is null; letGoAt only for let-go intentions', () {
      final parsed = Intention.fromJson({
        'id': 'x',
        'title': 'y',
        'kind': 'maybe',
        'status': 'someday',
        'letGoAt': '2026-01-01',
        'dueDate': 'soon',
      });
      expect(parsed.kind, isNull);
      expect(parsed.letGoAt, isNull);
      expect(parsed.dueDate, isNull);
    });

    test('copyWith clears kind and due date; reopening drops letGoAt', () {
      final set = base.copyWith(kind: IntentionKind.doTask, dueDate: DateTime(2027));
      final cleared = set.copyWith(clearKind: true, clearDueDate: true);
      expect(cleared.kind, isNull);
      expect(cleared.dueDate, isNull);
      final reopened = set.letGo(DateTime(2026)).copyWith(status: IntentionStatus.someday);
      expect(reopened.letGoAt, isNull);
      expect(reopened.kind, IntentionKind.doTask);
    });

    test('moment note: JSON round trip, tolerant parsing, copyWith', () {
      final moment = Moment(
          id: 'm', title: 'Swim', date: DateTime(2026, 7, 1), note: 'cold!');
      final json = moment.toJson();
      expect(json['note'], 'cold!');
      expect(Moment.fromJson(json).note, 'cold!');
      expect(Moment(id: 'm', title: 'Swim', date: DateTime(2026)).toJson(),
          isNot(contains('note')));
      for (final broken in [42, '', '   ', null, ['x']]) {
        expect(Moment.fromJson({...json, 'note': broken}).note, isNull,
            reason: '$broken');
      }
      expect(moment.copyWith(title: 'Sea swim').note, 'cold!');
      expect(moment.copyWith(note: 'warm').note, 'warm');
      expect(moment.copyWith(clearNote: true).note, isNull);
    });

    test('withPhase sets and clears the phase, keeping the rest', () {
      final linked = base.copyWith(kind: IntentionKind.doTask).withPhase('p');
      expect(linked.phaseId, 'p');
      expect(linked.copyWith(title: 'Sail more').phaseId, 'p');
      final free = linked.withPhase(null);
      expect(free.phaseId, isNull);
      expect(free.kind, IntentionKind.doTask);
    });
  });
}
