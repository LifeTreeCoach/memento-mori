import 'package:memento_mori_life_in_weeks/lifespan/country_names.dart';
import 'package:memento_mori_life_in_weeks/lifespan/life_table_repository.dart';
import 'package:memento_mori_life_in_weeks/lifespan/life_table_set.dart';

/// The two bundled assets the estimate flow needs.
class LifespanData {
  const LifespanData({required this.tables, required this.countries});

  final LifeTableSet tables;
  final CountryNames countries;

  /// Loads both assets (memoised by their loaders).
  static Future<LifespanData> load() async {
    final results = await Future.wait<Object>([
      LifeTableRepository.instance.load(),
      CountryNames.load(),
    ]);
    return LifespanData(
      tables: results[0] as LifeTableSet,
      countries: results[1] as CountryNames,
    );
  }
}

/// Loads [LifespanData]; injectable for tests.
typedef LifespanDataLoader = Future<LifespanData> Function();
