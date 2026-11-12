import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_rhythm.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_moment_inputs.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_moment_launcher.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_moment_result.dart';

/// Sunday 15 Nov 2026 at 20:00, an hour after the weekly reminder.
final DateTime _sundayEvening = DateTime(2026, 11, 15, 20);
final DateTime _reminderDay = DateTime(2026, 11, 15);

WeekMomentInputs _inputs({
  DateTime? birthDate,
  bool noBirthDate = false,
  bool enabled = true,
  bool onboarded = true,
  DateTime? lastShown,
  ReminderRhythm rhythm = ReminderRhythm.weekly,
}) =>
    WeekMomentInputs(
      birthDate: noBirthDate ? null : (birthDate ?? DateTime(1990, 7, 10)),
      lifeExpectancyYears: 80,
      rhythm: rhythm,
      onboarded: onboarded,
      enabled: enabled,
      lastShown: lastShown,
      since: DateTime(2026, 11, 1),
    );

/// Records marks and pushes instead of touching storage or the navigator.
class _RecordingLauncher extends WeekMomentLauncher {
  _RecordingLauncher(this.inputs);

  final WeekMomentInputs inputs;
  final List<String> log = [];
  final List<DateTime?> shownDays = [];

  @override
  Future<WeekMomentInputs> loadInputs() async => inputs;

  @override
  Future<void> markShown(DateTime day) async =>
      log.add('mark ${day.year}-${day.month}-${day.day}');

  @override
  Future<WeekMomentResult> show(
    BuildContext context,
    WeekMomentInputs inputs, {
    required DateTime now,
    DateTime? reminderDay,
  }) async {
    log.add('show ${inputs.storyOn(now).nowCell}');
    shownDays.add(reminderDay);
    return WeekMomentResult.continued;
  }
}

Future<BuildContext> _context(WidgetTester tester) async {
  late BuildContext context;
  await tester.pumpWidget(Builder(builder: (c) {
    context = c;
    return const SizedBox();
  }));
  return context;
}

void main() {
  group('forReminder', () {
    testWidgets('marks the reminder day before it shows', (tester) async {
      final context = await _context(tester);
      final launcher = _RecordingLauncher(_inputs());
      final result = await launcher.forReminder(context,
          reminderDay: _reminderDay, now: _sundayEvening);
      expect(result, WeekMomentResult.continued);
      expect(launcher.log, hasLength(2));
      expect(launcher.log.first, 'mark 2026-11-15');
      expect(launcher.log.last, startsWith('show '));
      // The card names the reminder's week.
      expect(launcher.shownDays, [_reminderDay]);
    });

    testWidgets('an undated tap counts for the latest reminder',
        (tester) async {
      final context = await _context(tester);
      final launcher = _RecordingLauncher(_inputs());
      // Monday morning: the latest reminder was Sunday evening.
      await launcher.forReminder(context, now: DateTime(2026, 11, 16, 8));
      expect(launcher.log.first, 'mark 2026-11-15');
    });

    testWidgets('an undated tap without a rhythm counts for today',
        (tester) async {
      final context = await _context(tester);
      final launcher = _RecordingLauncher(_inputs(rhythm: ReminderRhythm.off));
      await launcher.forReminder(context, now: DateTime(2026, 11, 18, 8));
      expect(launcher.log.first, 'mark 2026-11-18');
    });

    for (final (name, inputs) in [
      ('without a birth date', _inputs(noBirthDate: true)),
      ('when switched off', _inputs(enabled: false)),
      ('when already shown for that day', _inputs(lastShown: _reminderDay)),
    ]) {
      testWidgets('is not shown $name', (tester) async {
        final context = await _context(tester);
        final launcher = _RecordingLauncher(inputs);
        final result = await launcher.forReminder(context,
            reminderDay: _reminderDay, now: _sundayEvening);
        expect(result, WeekMomentResult.notShown);
        expect(launcher.log, isEmpty);
      });
    }

    testWidgets('shows again for the next reminder', (tester) async {
      final context = await _context(tester);
      final launcher =
          _RecordingLauncher(_inputs(lastShown: DateTime(2026, 11, 8)));
      final result = await launcher.forReminder(context,
          reminderDay: _reminderDay, now: _sundayEvening);
      expect(result, WeekMomentResult.continued);
    });
  });

  group('catchUpIfDue', () {
    testWidgets('marks the latest reminder day before it shows',
        (tester) async {
      final context = await _context(tester);
      final launcher = _RecordingLauncher(_inputs());
      final result = await launcher.catchUpIfDue(context,
          now: DateTime(2026, 11, 17, 9));
      expect(result, WeekMomentResult.continued);
      expect(launcher.log.first, 'mark 2026-11-15');
      expect(launcher.log.last, startsWith('show '));
    });

    for (final (name, inputs, now) in [
      ('without a birth date', _inputs(noBirthDate: true), _sundayEvening),
      ('when switched off', _inputs(enabled: false), _sundayEvening),
      ('before onboarding finished', _inputs(onboarded: false), _sundayEvening),
      ('without reminders', _inputs(rhythm: ReminderRhythm.off), _sundayEvening),
      ('when already shown', _inputs(lastShown: _reminderDay), _sundayEvening),
      ('after the window', _inputs(), DateTime(2026, 11, 18, 20)),
    ]) {
      testWidgets('is not shown $name', (tester) async {
        final context = await _context(tester);
        final launcher = _RecordingLauncher(inputs);
        final result = await launcher.catchUpIfDue(context, now: now);
        expect(result, WeekMomentResult.notShown);
        expect(launcher.log, isEmpty);
      });
    }
  });

  group('replay', () {
    testWidgets('ignores the last shown day and records nothing',
        (tester) async {
      final context = await _context(tester);
      final launcher = _RecordingLauncher(
          _inputs(lastShown: _reminderDay, enabled: false, onboarded: false));
      final result = await launcher.replay(context, now: _sundayEvening);
      expect(result, WeekMomentResult.continued);
      expect(launcher.log, hasLength(1));
      expect(launcher.log.single, startsWith('show '));
      // No reminder: the card's weeks are seen from now.
      expect(launcher.shownDays, [null]);
    });

    testWidgets('needs a birth date', (tester) async {
      final context = await _context(tester);
      final launcher = _RecordingLauncher(_inputs(noBirthDate: true));
      expect(await launcher.replay(context, now: _sundayEvening),
          WeekMomentResult.notShown);
      expect(launcher.log, isEmpty);
    });
  });

  test('settles for 800 ms before a catch-up', () {
    expect(WeekMomentLauncher.settle, const Duration(milliseconds: 800));
  });
}
