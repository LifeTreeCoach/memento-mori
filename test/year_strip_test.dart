import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/onboarding/staggered_intro.dart';
import 'package:memento_mori_life_in_weeks/onboarding/year_strip.dart';
import 'package:memento_mori_life_in_weeks/onboarding/year_strip_painter.dart';
import 'package:memento_mori_life_in_weeks/theme/motion.dart';

final DateTime _today = DateTime(2026, 11, 5);

/// Born 15 Jun 1990: 20 whole weeks since the last birthday, week 21.
final DateTime _birth = DateTime(1990, 6, 15);

Widget _host(Widget child, {bool reduceMotion = false}) {
  return MaterialApp(
    localizationsDelegates: const [AppLocalizationsDelegate()],
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: Scaffold(body: SizedBox(width: 337, child: child)),
      ),
    ),
  );
}

/// Pumps the strip once; later calls change its birth date in place.
final ValueNotifier<DateTime?> _date = ValueNotifier(null);

Future<void> _pumpStrip(
  WidgetTester tester,
  DateTime? birth, {
  bool reduceMotion = false,
}) async {
  if (find.byType(YearStrip).evaluate().isNotEmpty) {
    _date.value = birth;
    return tester.pump();
  }
  _date.value = birth;
  await tester.pumpWidget(
    _host(
      ValueListenableBuilder<DateTime?>(
        valueListenable: _date,
        builder: (context, date, _) =>
            YearStrip(birthDate: date, today: _today),
      ),
      reduceMotion: reduceMotion,
    ),
  );
  await tester.pump(); // the app strings load asynchronously
}

YearStripPainter _painter(WidgetTester tester) {
  final paint = tester.widget<CustomPaint>(
    find.byKey(const ValueKey('onboarding_year_strip')),
  );
  return paint.painter! as YearStripPainter;
}

String _caption(WidgetTester tester) => tester
    .widget<Text>(find.byKey(const ValueKey('onboarding_year_caption')))
    .data!;

/// Records haptic feedback calls on the platform channel.
List<String> _recordHaptics() {
  final calls = <String>[];
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          calls.add('${call.arguments}');
        }
        return null;
      });
  return calls;
}

void main() {
  group('YearStrip', () {
    testWidgets('is empty and without a caption before a birth date', (
      tester,
    ) async {
      await _pumpStrip(tester, null);
      await tester.pumpAndSettle();
      expect(_painter(tester).filled, 0);
      expect(_painter(tester).nowIndex, isNull);
      expect(_caption(tester), '');
    });

    testWidgets('fills the weeks since the birthday, then rests', (
      tester,
    ) async {
      final haptics = _recordHaptics();
      await _pumpStrip(tester, null);
      await _pumpStrip(tester, _birth);
      expect(_painter(tester).filled, 0);
      await tester.pump(Motion.long ~/ 2);
      expect(_painter(tester).filled, inExclusiveRange(0, 20));
      expect(_painter(tester).nowIndex, isNull);
      await tester.pumpAndSettle(); // breathes 3x, then no more frames
      expect(_painter(tester).filled, 20);
      expect(_painter(tester).nowIndex, 20);
      expect(_painter(tester).nowGlow, 1);
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(_caption(tester), 'Week 21 of your current year of life');
      expect(haptics, ['HapticFeedbackType.lightImpact']);
    });

    testWidgets('the current week breathes before it settles', (tester) async {
      await _pumpStrip(tester, null);
      await _pumpStrip(tester, _birth);
      while (_painter(tester).nowIndex == null) {
        await tester.pump(const Duration(milliseconds: 16)); // still filling
      }
      await tester.pump(Motion.pulse ~/ 2); // deepest point of a breath
      expect(_painter(tester).nowGlow, lessThan(0.1));
      await tester.pumpAndSettle();
      expect(_painter(tester).nowGlow, 1);
    });

    testWidgets('reduced motion shows the final state at the first frame', (
      tester,
    ) async {
      await _pumpStrip(tester, null, reduceMotion: true);
      await _pumpStrip(tester, _birth, reduceMotion: true);
      expect(_painter(tester).filled, 20);
      expect(_painter(tester).nowIndex, 20);
      expect(_painter(tester).nowGlow, 1);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('week 53 keeps the current week on the last square', (
      tester,
    ) async {
      await _pumpStrip(tester, DateTime(1990, 11, 7), reduceMotion: true);
      await _pumpStrip(tester, DateTime(1990, 11, 6), reduceMotion: true);
      expect(_painter(tester).filled, 51);
      expect(_painter(tester).nowIndex, 51);
      expect(_caption(tester), 'Week 53 of your current year of life');
    });
  });

  group('YearStripGeometry', () {
    test('cells shrink to fit narrow widths and cap at 9 dp', () {
      expect(YearStripGeometry(400).cell, 9);
      final narrow = YearStripGeometry(250);
      expect(narrow.cellRect(25).right, closeTo(250, 0.001));
      expect(narrow.height, 2 * narrow.cell + YearStripGeometry.gap);
    });
  });

  group('StaggeredIntro', () {
    Widget intro() =>
        const StaggeredIntro(children: [Text('Title'), Text('Subtitle')]);

    double opacityOf(WidgetTester tester, String text) => tester
        .widget<Opacity>(
          find
              .ancestor(of: find.text(text), matching: find.byType(Opacity))
              .first,
        )
        .opacity;

    testWidgets('fades in once, the subtitle a little later', (tester) async {
      await tester.pumpWidget(_host(intro()));
      await tester.pump(); // strings loaded: the intro's first frame
      expect(opacityOf(tester, 'Title'), 0);
      await tester.pump(StaggeredIntro.duration ~/ 4);
      expect(opacityOf(tester, 'Title'), greaterThan(0));
      expect(opacityOf(tester, 'Subtitle'), 0);
      await tester.pumpAndSettle();
      expect(opacityOf(tester, 'Title'), 1);
      expect(opacityOf(tester, 'Subtitle'), 1);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('reduced motion shows both at the first frame', (tester) async {
      await tester.pumpWidget(_host(intro(), reduceMotion: true));
      await tester.pump(); // strings loaded: the intro's first frame
      expect(opacityOf(tester, 'Title'), 1);
      expect(opacityOf(tester, 'Subtitle'), 1);
    });
  });
}
