import 'dart:io';
import 'dart:typed_data';

import 'package:memento_mori_life_in_weeks/lifespan/country_names.dart';
import 'package:memento_mori_life_in_weeks/lifespan/life_table_set.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/lifespan_data.dart';

/// The real bundled assets, read from disk once (no asset bundle needed).
final LifespanData lifespanTestData = LifespanData(
  tables: LifeTableSet.parse(
    ByteData.sublistView(
      File('assets/lifespan/wpp2024_lt.bin').readAsBytesSync(),
    ),
  ),
  countries: CountryNames.parse(
    File('assets/lifespan/countries.json').readAsStringSync(),
  ),
);

/// A [LifespanDataLoader] returning [lifespanTestData].
Future<LifespanData> loadLifespanTestData() async => lifespanTestData;
