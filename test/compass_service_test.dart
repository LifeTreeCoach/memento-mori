import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_service.dart';
import 'package:memento_mori_life_in_weeks/compass/life_phase.dart';
import 'package:memento_mori_life_in_weeks/core/life_calculator.dart';
import 'package:memento_mori_life_in_weeks/life/life_mode.dart';
import 'package:memento_mori_life_in_weeks/life/life_period.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Map<String, dynamic>> _stored() async {
  final prefs = await SharedPreferences.getInstance();
  return jsonDecode(prefs.getString(CompassService.dataKey)!) as Map<String, dynamic>;
}

/// Reloads the service from storage.
Future<void> _reload() async {
  CompassService.clearCacheForTesting();
  await CompassService.initialize();
}

void main() {
  late int changes;
  void countChange() => changes++;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CompassService.clearCacheForTesting();
    changes = 0;
    CompassService.revision.addListener(countChange);
  });

  tearDown(() => CompassService.revision.removeListener(countChange));

  group('intentions', () {
    test('the first three go to Now, the fourth to Someday with the limit reported',
        () async {
      final results = [
        for (final title in ['a', 'b', 'c', 'd'])
          await CompassService.addIntention(title: title),
      ];
      expect(results.take(3).map((r) => r.intention.status),
          everyElement(IntentionStatus.now));
      expect(results.take(3).map((r) => r.nowLimitReached), everyElement(isFalse));
      expect(results.last.nowLimitReached, isTrue);
      expect(results.last.intention.status, IntentionStatus.someday);
      expect(CompassService.data.intentions, hasLength(4), reason: 'never dropped');
      expect(changes, 4);
    });

    test('someday on request does not count against the limit', () async {
      final result = await CompassService.addIntention(
          title: 'Learn Japanese', status: IntentionStatus.someday);
      expect(result.intention.status, IntentionStatus.someday);
      expect(result.nowLimitReached, isFalse);
    });

    test('moveToNow refuses when Now is full, moveToSomeday frees a slot', () async {
      for (final title in ['a', 'b', 'c']) {
        await CompassService.addIntention(title: title);
      }
      final extra = (await CompassService.addIntention(title: 'd')).intention;
      changes = 0;

      expect(await CompassService.moveToNow(extra.id), isFalse);
      expect(changes, 0);

      final first = CompassService.data.intentions.first;
      await CompassService.moveToSomeday(first.id);
      expect(await CompassService.moveToNow(extra.id), isTrue);
      expect(CompassService.data.nowCount, 3);
      expect(changes, 2);
    });

    test('edit changes text fields but keeps status and dates', () async {
      final added = (await CompassService.addIntention(
              title: 'Run', today: DateTime(2026, 1, 5)))
          .intention;
      await CompassService.editIntention(added.copyWith(
        title: 'Run a 10k',
        note: 'slowly',
        area: LifeArea.health,
        horizon: Horizon.thisYear,
        status: IntentionStatus.done,
      ));
      final edited = CompassService.data.intentions.single;
      expect(edited.title, 'Run a 10k');
      expect(edited.note, 'slowly');
      expect(edited.area, LifeArea.health);
      expect(edited.horizon, Horizon.thisYear);
      expect(edited.status, IntentionStatus.now);
      expect(edited.createdAt, DateTime(2026, 1, 5));
    });

    test('complete marks done and records a moment for today', () async {
      final added = (await CompassService.addIntention(
              title: 'Visit Lisbon', area: LifeArea.adventure))
          .intention;
      changes = 0;
      final moment = await CompassService.complete(added.id, today: DateTime(2026, 6, 1, 18));

      final done = CompassService.data.intentions.single;
      expect(done.status, IntentionStatus.done);
      expect(done.doneAt, DateTime(2026, 6, 1));
      expect(moment.fromIntentionId, added.id);
      expect(moment.date, DateTime(2026, 6, 1));
      expect(moment.title, 'Visit Lisbon');
      expect(moment.area, LifeArea.adventure);
      expect(CompassService.data.moments.single.id, moment.id);
      expect(CompassService.data.nowCount, 0, reason: 'frees a Now slot');
      expect(changes, 1);
    });

    test('undoComplete restores the status and removes the moment', () async {
      final added = (await CompassService.addIntention(
              title: 'Later', status: IntentionStatus.someday))
          .intention;
      await CompassService.addMoment(title: 'Other', date: DateTime(2026, 1, 1));
      final moment = await CompassService.complete(added.id);
      await CompassService.undoComplete(added, moment.id);

      final restored = CompassService.data.intentions.single;
      expect(restored.status, IntentionStatus.someday);
      expect(restored.doneAt, isNull);
      expect(CompassService.data.moments.map((m) => m.title), ['Other']);
    });

    test('undoComplete goes to Someday if Now filled up meanwhile', () async {
      final first = (await CompassService.addIntention(title: 'a')).intention;
      final moment = await CompassService.complete(first.id);
      for (var i = 0; i < nowLimit; i++) {
        await CompassService.addIntention(title: 'n$i');
      }
      await CompassService.undoComplete(first, moment.id);
      expect(CompassService.data.intentions.first.status, IntentionStatus.someday);
      expect(CompassService.data.moments, isEmpty);
    });

    test('delete keeps moments of the intention', () async {
      final added = (await CompassService.addIntention(title: 'x')).intention;
      await CompassService.complete(added.id);
      await CompassService.deleteIntention(added.id);
      expect(CompassService.data.intentions, isEmpty);
      expect(CompassService.data.moments, hasLength(1));
    });

    test('unknown ids throw', () async {
      expect(CompassService.moveToNow('nope'), throwsStateError);
      expect(CompassService.complete('nope'), throwsStateError);
      expect(CompassService.deleteIntention('nope'), throwsStateError);
      expect(CompassService.deleteMoment('nope'), throwsStateError);
    });

    test('ids are unique', () async {
      for (var i = 0; i < 5; i++) {
        await CompassService.addIntention(title: '$i', status: IntentionStatus.someday);
      }
      expect(CompassService.data.intentions.map((i) => i.id).toSet(), hasLength(5));
    });
  });

  group('moments', () {
    test('add (backdated), edit and delete persist', () async {
      final moment = await CompassService.addMoment(
          title: 'First child born', date: DateTime(2015, 4, 20), area: LifeArea.relationships);
      expect((await _stored())['moments'].single['date'], '2015-04-20');

      await CompassService.editMoment(moment.copyWith(title: 'Mia born', clearArea: true));
      await _reload();
      final edited = CompassService.data.moments.single;
      expect(edited.title, 'Mia born');
      expect(edited.area, isNull);
      expect(edited.date, DateTime(2015, 4, 20));

      await CompassService.deleteMoment(moment.id);
      expect(CompassService.data.moments, isEmpty);
      expect(changes, 3);
    });

    test('the note is kept on edit, set, trimmed and cleared', () async {
      final moment = await CompassService.addMoment(
          title: 'Hike', date: DateTime(2026, 5, 1), note: '  the view ');
      expect(CompassService.data.moments.single.note, 'the view');

      await CompassService.editMoment(moment.copyWith(title: 'Long hike'));
      expect(CompassService.data.moments.single.note, 'the view');

      await CompassService.setMomentNote(moment.id, 'my legs');
      await _reload();
      expect(CompassService.data.moments.single.note, 'my legs');
      expect((await _stored())['moments'].single['note'], 'my legs');

      await CompassService.setMomentNote(moment.id, '   ');
      expect(CompassService.data.moments.single.note, isNull);
      await CompassService.editMoment(
          CompassService.data.moments.single.copyWith(note: 'again'));
      expect(CompassService.data.moments.single.note, 'again');
      await CompassService.editMoment(
          CompassService.data.moments.single.copyWith(clearNote: true));
      expect(CompassService.data.moments.single.note, isNull);
      expect(() => CompassService.setMomentNote('nope', 'x'),
          throwsA(isA<StateError>()));
    });

    test('momentsIn a life period and by date range', () async {
      // Week cells of someone born on Saturday 1990-03-17 start on Saturdays;
      // the cell of 2020-03-15 runs from Sat 2020-03-14 to Fri 2020-03-20.
      await CompassService.addMoment(title: 'before', date: DateTime(2020, 3, 13));
      await CompassService.addMoment(title: 'in', date: DateTime(2020, 3, 14));
      await CompassService.addMoment(title: 'last day', date: DateTime(2020, 3, 20));
      await CompassService.addMoment(title: 'after', date: DateTime(2020, 3, 21));

      final calc = LifeCalculator(birthDate: DateTime(1990, 3, 17), now: DateTime(2026, 11, 5));
      final index = DateTime.utc(2020, 3, 15).difference(DateTime.utc(1990, 3, 17)).inDays ~/ 7;
      final period = LifePeriod.of(LifeMode.weeks, index, calc);
      expect(period.start, DateTime.utc(2020, 3, 14));
      expect(CompassService.momentsIn(period).map((m) => m.title), ['in', 'last day']);
      expect(
          CompassService.momentsBetween(DateTime(2020), DateTime(2021)).map((m) => m.title),
          ['before', 'in', 'last day', 'after']);
    });
  });

  group('storage', () {
    test('data survives a reload', () async {
      await CompassService.addIntention(title: 'a', horizon: const Horizon.byAge(60));
      await _reload();
      expect(CompassService.data.intentions.single.horizon, const Horizon.byAge(60));
    });

    test('corrupt stored JSON loads as empty', () async {
      SharedPreferences.setMockInitialValues({CompassService.dataKey: '{oops'});
      await _reload();
      expect(CompassService.data.isEmpty, isTrue);
    });
  });

  group('settings', () {
    test('defaults: gentleOnly off, grid marks on', () async {
      await CompassService.initialize();
      expect(CompassService.gentleOnly, isFalse);
      expect(CompassService.showGridMarks, isTrue);
    });

    test('are stored under their keys and bump the revision', () async {
      await CompassService.setGentleOnly(true);
      await CompassService.setShowGridMarks(false);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('compass_gentle_only'), isTrue);
      expect(prefs.getBool('compass_grid_marks'), isFalse);
      await _reload();
      expect(CompassService.gentleOnly, isTrue);
      expect(CompassService.showGridMarks, isFalse);
      expect(changes, 2);
    });
  });

  group('reflection setting', () {
    test('is on by default, stored under compass_reflection', () async {
      await CompassService.initialize();
      expect(CompassService.showReflection, isTrue);
      await CompassService.setShowReflection(false);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('compass_reflection'), isFalse);
      await _reload();
      expect(CompassService.showReflection, isFalse);
      expect(changes, 1);
    });
  });

  group('week state', () {
    test('one swap per ISO week; dismissed is per week too', () async {
      final thursday = DateTime(2026, 11, 5);
      expect(CompassService.weekState(thursday).week, '2026-W45');
      expect(await CompassService.swapQuestion(thursday), isTrue);
      expect(await CompassService.swapQuestion(DateTime(2026, 11, 8)), isFalse);
      await CompassService.dismissQuestion(thursday);

      await _reload();
      final state = CompassService.weekState(DateTime(2026, 11, 2));
      expect(state.swapped, isTrue);
      expect(state.dismissed, isTrue);

      final next = CompassService.weekState(DateTime(2026, 11, 9));
      expect(next.week, '2026-W46');
      expect(next.swapped, isFalse);
      expect(next.dismissed, isFalse);
      expect(await CompassService.swapQuestion(DateTime(2026, 11, 9)), isTrue);
    });

    test('restoreQuestion brings a dismissed question back, persisted',
        () async {
      final thursday = DateTime(2026, 11, 5);
      await CompassService.swapQuestion(thursday);
      await CompassService.dismissQuestion(thursday);
      await CompassService.restoreQuestion(DateTime(2026, 11, 7));

      await _reload();
      final state = CompassService.weekState(thursday);
      expect(state.dismissed, isFalse);
      expect(state.swapped, isTrue);
    });
  });

  group('importData', () {
    test('adds new entries only and keeps Now within the limit', () async {
      await CompassService.addIntention(title: 'mine');
      final existing = CompassService.data.intentions.single;
      Intention now(String id) => Intention(
          id: id, title: id, status: IntentionStatus.now, createdAt: DateTime(2026));
      final imported = CompassData(
        intentions: [existing, now('n1'), now('n2'), now('n3')],
        moments: [Moment(id: 'm', title: 'm', date: DateTime(2010))],
      );

      expect(await CompassService.importData(imported), 4);
      expect(CompassService.data.intentions, hasLength(4));
      expect(CompassService.data.nowCount, 3);
      expect(CompassService.data.intentions.last.status, IntentionStatus.someday);
      expect(await CompassService.importData(imported), 0, reason: 'idempotent');
    });
  });

  group('life phases', () {
    final today = DateTime(2026, 11, 6);

    Future<LifePhase> startCurrent() => CompassService.startPhase(
        preset: PhasePreset.buildUp,
        start: DateTime(2024, 1, 1),
        plannedEnd: DateTime(2028),
        today: today);

    test('startPhase persists, bumps the revision and becomes current', () async {
      expect(CompassService.currentPhase(today: today), isNull);
      final phase = await startCurrent();
      expect(changes, 1);
      expect(CompassService.currentPhase(today: today)!.id, phase.id);
      await _reload();
      final stored = CompassService.data.phases.single;
      expect(stored.preset, PhasePreset.buildUp);
      expect(stored.plannedEnd, DateTime(2028));
      expect((await _stored())['phases'], hasLength(1));
    });

    test('Now intentions without a phase join a new current phase', () async {
      final early = (await CompassService.addIntention(title: 'a')).intention;
      expect(early.phaseId, isNull);
      final phase = await startCurrent();
      expect(CompassService.data.intentions.single.phaseId, phase.id);
    });

    test('addIntention links Now to the current phase, never Someday', () async {
      final phase = await startCurrent();
      final now = await CompassService.addIntention(
          title: 'Run',
          today: today,
          kind: IntentionKind.doTask,
          dueDate: DateTime(2027));
      expect(now.intention.phaseId, phase.id);
      expect(now.intention.kind, IntentionKind.doTask);
      expect(now.intention.dueDate, DateTime(2027));
      final someday = await CompassService.addIntention(
          title: 'Sail', status: IntentionStatus.someday, today: today);
      expect(someday.intention.phaseId, isNull);
      for (final title in ['b', 'c']) {
        await CompassService.addIntention(title: title, today: today);
      }
      final overflow = await CompassService.addIntention(title: 'd', today: today);
      expect(overflow.nowLimitReached, isTrue);
      expect(overflow.intention.phaseId, isNull);
    });

    test('moveToNow links the current phase, moveToSomeday clears it', () async {
      final phase = await startCurrent();
      final added = (await CompassService.addIntention(
              title: 'x', status: IntentionStatus.someday, today: today))
          .intention;
      await CompassService.moveToNow(added.id, today: today);
      expect(CompassService.data.intentions.single.phaseId, phase.id);
      await CompassService.moveToSomeday(added.id);
      expect(CompassService.data.intentions.single.phaseId, isNull);
    });

    test('editIntention saves kind and due date, keeps the phase', () async {
      final phase = await startCurrent();
      final added =
          (await CompassService.addIntention(title: 'x', today: today)).intention;
      await CompassService.editIntention(added.copyWith(
          kind: IntentionKind.enjoy, dueDate: DateTime(2027, 2, 2)));
      final stored = CompassService.data.intentions.single;
      expect(stored.kind, IntentionKind.enjoy);
      expect(stored.dueDate, DateTime(2027, 2, 2));
      expect(stored.phaseId, phase.id);
    });

    test('letGoIntention keeps the intention, no longer open', () async {
      final added =
          (await CompassService.addIntention(title: 'x', today: today)).intention;
      await CompassService.letGoIntention(added.id, today: today);
      final stored = CompassService.data.intentions.single;
      expect(stored.status, IntentionStatus.letGo);
      expect(stored.letGoAt, today);
      expect(stored.isOpen, isFalse);
      expect(CompassService.data.nowCount, 0);
    });

    test('closePhase saves note, next phase, carry-over and let-go in one save',
        () async {
      final closing = await startCurrent();
      final carry = (await CompassService.addIntention(title: 'carry', today: today)).intention;
      final release = (await CompassService.addIntention(title: 'release', today: today)).intention;
      final stay = (await CompassService.addIntention(title: 'stay', today: today)).intention;
      final next = LifePhase(
          id: CompassService.newId(), preset: PhasePreset.calmer, start: today);
      changes = 0;

      await CompassService.closePhase(
        closingId: closing.id,
        note: 'We built a home',
        next: next,
        carryOver: {carry.id},
        letGo: {release.id},
        today: today,
      );
      expect(changes, 1, reason: 'atomic');
      await _reload();
      final data = CompassService.data;
      expect(data.phases.firstWhere((p) => p.id == closing.id).note, 'We built a home');
      expect(CompassService.currentPhase(today: today)!.id, next.id);
      Intention byId(String id) => data.intentions.firstWhere((i) => i.id == id);
      expect(byId(carry.id).phaseId, next.id);
      expect(byId(release.id).status, IntentionStatus.letGo);
      expect(byId(release.id).phaseId, closing.id);
      expect(byId(stay.id).phaseId, closing.id);
    });

    test('editPhase saves; deletePhase clears links and keeps intentions', () async {
      final phase = await startCurrent();
      await CompassService.addIntention(title: 'x', today: today);
      await CompassService.editPhase(phase.copyWith(name: 'Home', clearPlannedEnd: true));
      expect(CompassService.data.phases.single.name, 'Home');
      expect(CompassService.data.phases.single.plannedEnd, isNull);

      await CompassService.deletePhase(phase.id);
      expect(CompassService.data.phases, isEmpty);
      expect(CompassService.data.intentions.single.phaseId, isNull);
      expect(() => CompassService.deletePhase(phase.id), throwsStateError);
      expect(() => CompassService.editPhase(phase), throwsStateError);
    });

    test('importData merges phases by id', () async {
      final mine = await startCurrent();
      final imported = CompassData(phases: [
        mine,
        LifePhase(id: 'other', preset: PhasePreset.study, start: DateTime(2010)),
      ]);
      expect(await CompassService.importData(imported), 1);
      expect(CompassService.data.phases.map((p) => p.id), [mine.id, 'other']);
      expect(await CompassService.importData(imported), 0);
    });
  });
}
