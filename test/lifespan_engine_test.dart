import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/lifespan/cohort_engine.dart';
import 'package:memento_mori_life_in_weeks/lifespan/life_table_set.dart';
import 'package:memento_mori_life_in_weeks/lifespan/sex.dart';

Uint8List _assetBytes() =>
    File('assets/lifespan/wpp2024_lt.bin').readAsBytesSync();

LifeTableSet _loadTables() =>
    LifeTableSet.parse(ByteData.sublistView(_assetBytes()));

Sex _fixtureSex(String name) => switch (name) {
  'female' => Sex.female,
  'male' => Sex.male,
  'both' => Sex.unspecified, // raw WPP "Both" table
  _ => throw ArgumentError(name),
};

void main() {
  final tables = _loadTables();

  group('LifeTableSet', () {
    test('exposes all 238 locations incl. WLD', () {
      expect(tables.codes, hasLength(238));
      expect(tables.codes, containsAll(['DE', 'JP', 'US', 'NG', 'WLD']));
    });

    test('unknown or null code falls back to WLD', () {
      expect(tables.resolve('ZZ'), 'WLD');
      expect(tables.resolve(null), 'WLD');
      expect(tables.resolve('DE'), 'DE');
      expect(
        identical(tables.table('ZZ', Sex.male), tables.table('WLD', Sex.male)),
        isTrue,
      );
      expect(
        identical(
          tables.table(null, Sex.female),
          tables.table('WLD', Sex.female),
        ),
        isTrue,
      );
    });

    test('bad magic throws FormatException', () {
      final bytes = Uint8List.fromList(_assetBytes());
      bytes[0] = 0x58; // 'X'
      expect(
        () => LifeTableSet.parse(ByteData.sublistView(bytes)),
        throwsFormatException,
      );
    });

    test('bad version throws FormatException', () {
      final bytes = Uint8List.fromList(_assetBytes());
      bytes[4] = 2;
      expect(
        () => LifeTableSet.parse(ByteData.sublistView(bytes)),
        throwsFormatException,
      );
    });

    test('truncated file throws FormatException', () {
      final bytes = Uint8List.sublistView(_assetBytes(), 0, 1000);
      expect(
        () => LifeTableSet.parse(ByteData.sublistView(bytes)),
        throwsFormatException,
      );
    });
  });

  group('CohortEngine fixtures', () {
    final fixtures = jsonDecode(
      File('test/fixtures/lifespan_cases.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    for (final raw in fixtures['cases'] as List) {
      final input = raw['input'] as Map<String, dynamic>;
      final expected = raw['expected'] as Map<String, dynamic>;
      test('${input['code']} ${input['sex']} age ${input['age']} '
          'year ${input['year']} H ${input['hazardMultiplier']}', () {
        final h = (input['hazardMultiplier'] as num).toDouble();
        expect(
          tables.resolve(input['code'] as String),
          expected['resolvedCode'],
        );
        final result = CohortEngine.run(
          tables.table(
            input['code'] as String,
            _fixtureSex(input['sex'] as String),
          ),
          age: (input['age'] as num).toDouble(),
          year: (input['year'] as num).toDouble(),
          hazardMultiplier: (_) => h,
        );
        void near(String key, double? actual) {
          final value = expected[key] as num?;
          if (value == null) {
            expect(actual, isNull, reason: key);
          } else {
            expect(actual, closeTo(value.toDouble(), 1e-6), reason: key);
          }
        }

        near('mean', result.mean);
        near('p25', result.p25);
        near('median', result.median);
        near('p75', result.p75);
        near('reach80', result.reach80);
        near('reach90', result.reach90);
      });
    }
  });

  group('CohortEngine edge cases', () {
    final table = tables.table('DE', Sex.female);

    for (final age in [0.0, 99.0, 105.0, 125.0, 130.0]) {
      test('age $age gives finite, ordered results and monotone S', () {
        final curve = CohortEngine.survival(table, age: age, year: 2026.5);
        final r = curve.summarize();
        for (final v in [r.mean, r.p25, r.median, r.p75]) {
          expect(v.isFinite, isTrue);
          expect(v, greaterThanOrEqualTo(age));
        }
        expect(r.p25 <= r.median && r.median <= r.p75, isTrue);
        var previous = 1.0;
        for (var x = age; x <= age + 40; x += 0.25) {
          final s = curve.survivalAt(x);
          expect(s, lessThanOrEqualTo(previous));
          expect(s, inInclusiveRange(0.0, 1.0));
          previous = s;
        }
        if (age >= 80) expect(r.reach80, isNull);
        if (age >= 90) expect(r.reach90, isNull);
      });
    }

    test(
      'later calendar year never lowers the expectancy (improving trend)',
      () {
        for (final code in ['DE', 'JP', 'NG', 'WLD']) {
          for (final sex in Sex.values) {
            final early = CohortEngine.run(
              tables.table(code, sex),
              age: 40,
              year: 2026,
            );
            final late = CohortEngine.run(
              tables.table(code, sex),
              age: 40,
              year: 2050,
            );
            expect(
              late.mean,
              greaterThanOrEqualTo(early.mean),
              reason: '$code $sex',
            );
          }
        }
      },
    );

    test('survivalAt matches the step survival at integer ages', () {
      final curve = CohortEngine.survival(table, age: 36.6, year: 2026);
      expect(curve.survivalAt(80), closeTo(curve.summarize().reach80!, 1e-12));
    });

    test('mixture lies between its components', () {
      final f = CohortEngine.survival(
        tables.table('DE', Sex.female),
        age: 36,
        year: 2026,
      );
      final m = CohortEngine.survival(
        tables.table('DE', Sex.male),
        age: 36,
        year: 2026,
      );
      final mix = CohortEngine.mixture(f, m);
      final rf = f.summarize(), rm = m.summarize();
      expect(mix.mean, closeTo((rf.mean + rm.mean) / 2, 1e-12));
      for (final (a, b, c) in [
        (rm.p25, mix.p25, rf.p25),
        (rm.median, mix.median, rf.median),
        (rm.p75, mix.p75, rf.p75),
      ]) {
        expect(b, greaterThan(a));
        expect(b, lessThan(c));
      }
      // The percentile really is where the mixture survival hits the target.
      final s = (f.survivalAt(mix.median) + m.survivalAt(mix.median)) / 2;
      expect(s, closeTo(0.5, 1e-9));
    });
  });
}
