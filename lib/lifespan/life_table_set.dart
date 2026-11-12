import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'sex.dart';

/// One dequantised WPP 2024 life table (location x sex) with its trend slopes
/// interpolated to every single age 0..100 (100 = open interval 100+).
///
/// Format and model: `tool/README.md`.
class LifeTable {
  LifeTable({
    required this.lnm,
    required this.slopes,
    required this.segmentYears,
  });

  /// `ln mx` in 2026 per single age 0..100.
  final List<double> lnm;

  /// Per trend segment p, the slope `b_p(i)` per single age 0..100.
  final List<List<double>> slopes;

  /// Segment boundaries Y_0..Y_P (2026, 2040, 2065, 2100).
  final List<int> segmentYears;

  static const int maxAgeIndex = 100;

  /// Central death rate at single age [ageIndex] in calendar year [year],
  /// before any lifestyle multiplier.
  double hazard(int ageIndex, double year) {
    var trend = 0.0;
    for (var p = 0; p < slopes.length; p++) {
      final lo = segmentYears[p].toDouble();
      final hi = segmentYears[p + 1].toDouble();
      trend += slopes[p][ageIndex] * (math.min(math.max(year, lo), hi) - lo);
    }
    return math.exp(lnm[ageIndex] + trend);
  }
}

/// All life tables of the bundled asset `assets/lifespan/wpp2024_lt.bin`.
///
/// Tables are decoded lazily per location and cached.
class LifeTableSet {
  LifeTableSet._(this._data, this._header, this._offsets);

  /// Parses the asset bytes. Throws [FormatException] for a bad magic,
  /// version or truncated file.
  factory LifeTableSet.parse(ByteData data) {
    final header = _Header.read(data);
    final offsets = <String, int>{};
    var pos = header.indexStart;
    for (var n = 0; n < header.count; n++) {
      _require(data, pos + 7);
      final key = _readKey(data, pos);
      final offset = data.getUint32(pos + 3, Endian.little);
      _require(data, offset + header.blockSize);
      offsets[key] = offset;
      pos += 7;
    }
    if (!offsets.containsKey(worldCode)) {
      throw const FormatException('Life table asset has no WLD entry');
    }
    return LifeTableSet._(data, header, offsets);
  }

  static const String worldCode = 'WLD';
  static const String _magic = 'WPP1';
  static const int _version = 1;

  final ByteData _data;
  final _Header _header;
  final Map<String, int> _offsets;
  final Map<String, LifeTable> _cache = {};

  /// Every location key in the asset (ISO 3166-1 alpha-2 plus `WLD`), sorted.
  List<String> get codes => _offsets.keys.toList()..sort();

  bool contains(String? code) => code != null && _offsets.containsKey(code);

  /// [code] if the asset has it, otherwise `WLD`.
  String resolve(String? code) => contains(code) ? code! : worldCode;

  /// Table for [code] (unknown/null -> `WLD`). [Sex.unspecified] returns the
  /// WPP "Both" table (raw access; the estimator mixes female and male instead).
  LifeTable table(String? code, Sex sex) {
    final key = resolve(code);
    final sexIndex = switch (sex) {
      Sex.unspecified => 0,
      Sex.female => 1,
      Sex.male => 2,
    };
    return _cache.putIfAbsent('$key/$sexIndex', () => _decode(key, sexIndex));
  }

  LifeTable _decode(String key, int sexIndex) {
    final h = _header;
    final perSex = h.ages + h.segments * h.knots.length;
    var pos = _offsets[key]! + sexIndex * perSex * 2;
    double next(int scale) {
      final value = _data.getInt16(pos, Endian.little) / scale;
      pos += 2;
      return value;
    }

    final lnm = [for (var i = 0; i < h.ages; i++) next(h.lnmScale)];
    final slopes = <List<double>>[];
    for (var p = 0; p < h.segments; p++) {
      final atKnots = [
        for (var k = 0; k < h.knots.length; k++) next(h.slopeScale),
      ];
      slopes.add(_interpolate(h.knots, atKnots, h.ages));
    }
    return LifeTable(lnm: lnm, slopes: slopes, segmentYears: h.segmentYears);
  }

  /// Linear interpolation of knot values to every age (first matching knot
  /// interval, as in the reference engine).
  static List<double> _interpolate(
    List<int> knots,
    List<double> values,
    int ages,
  ) {
    final out = <double>[];
    for (var age = 0; age < ages; age++) {
      for (var k = 0; k < knots.length - 1; k++) {
        final lo = knots[k], hi = knots[k + 1];
        if (lo <= age && age <= hi) {
          final t = (age - lo) / (hi - lo);
          out.add(values[k] + (values[k + 1] - values[k]) * t);
          break;
        }
      }
    }
    return out;
  }

  static String _readKey(ByteData data, int pos) {
    final bytes = [for (var i = 0; i < 3; i++) data.getUint8(pos + i)]
        .where((b) => b != 0)
        .toList();
    return ascii.decode(bytes);
  }

  static void _require(ByteData data, int end) {
    if (end > data.lengthInBytes) {
      throw const FormatException('Life table asset is truncated');
    }
  }
}

class _Header {
  _Header({
    required this.ages,
    required this.segments,
    required this.segmentYears,
    required this.knots,
    required this.lnmScale,
    required this.slopeScale,
    required this.count,
    required this.indexStart,
  });

  factory _Header.read(ByteData data) {
    LifeTableSet._require(data, 10);
    final magic = ascii.decode([
      for (var i = 0; i < 4; i++) data.getUint8(i),
    ], allowInvalid: true);
    if (magic != LifeTableSet._magic) {
      throw FormatException('Bad life table magic: $magic');
    }
    final version = data.getUint16(4, Endian.little);
    if (version != LifeTableSet._version) {
      throw FormatException('Unsupported life table version: $version');
    }
    final ages = data.getUint8(6);
    final knotCount = data.getUint8(7);
    final sexes = data.getUint8(8);
    final segments = data.getUint8(9);
    if (ages != LifeTable.maxAgeIndex + 1 ||
        sexes != 3 ||
        segments < 1 ||
        knotCount < 2) {
      throw const FormatException('Unexpected life table dimensions');
    }
    var pos = 10;
    LifeTableSet._require(data, pos + 2 * (segments + 1) + knotCount + 10);
    final years = <int>[];
    for (var p = 0; p <= segments; p++) {
      years.add(data.getUint16(pos, Endian.little));
      pos += 2;
    }
    final knots = [for (var k = 0; k < knotCount; k++) data.getUint8(pos + k)];
    pos += knotCount;
    final lnmScale = data.getUint32(pos, Endian.little);
    final slopeScale = data.getUint32(pos + 4, Endian.little);
    final count = data.getUint16(pos + 8, Endian.little);
    pos += 10;
    return _Header(
      ages: ages,
      segments: segments,
      segmentYears: years,
      knots: knots,
      lnmScale: lnmScale,
      slopeScale: slopeScale,
      count: count,
      indexStart: pos,
    );
  }

  final int ages;
  final int segments;
  final List<int> segmentYears;
  final List<int> knots;
  final int lnmScale;
  final int slopeScale;
  final int count;
  final int indexStart;

  int get blockSize => 3 * (ages + segments * knots.length) * 2;
}
