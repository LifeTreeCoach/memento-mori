import 'package:memento_mori_life_in_weeks/lifespan/life_table_set.dart';
import 'package:memento_mori_life_in_weeks/lifespan/lifespan_estimator.dart';
import 'package:memento_mori_life_in_weeks/lifespan/sex.dart';

/// The population estimate (no lifestyle answers) for a country and sex,
/// remembered per pair so switching back and forth stays cheap.
class BaselineYears {
  BaselineYears({required this.birthDate, required this.now});

  final DateTime birthDate;
  final DateTime now;
  final Map<String, int> _cache = {};

  int of(LifeTableSet tables, String country, Sex sex) {
    return _cache.putIfAbsent(
      '$country|${sex.name}',
      () => LifespanEstimator(tables)
          .estimate(country: country, sex: sex, birthDate: birthDate, now: now)
          .recommendedYears,
    );
  }
}
