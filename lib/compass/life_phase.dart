import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';

/// Ready-made life phases; their names are translated, so they follow the
/// app language.
enum PhasePreset {
  childhood,
  school,
  study,
  careerStart,
  buildUp,
  family,
  transition,
  calmer;

  /// Offered when choosing the current phase (childhood and school only
  /// make sense when adding earlier phases).
  static const List<PhasePreset> onboarding = [
    study,
    careerStart,
    buildUp,
    family,
    transition,
    calmer,
  ];

  /// The preset named [value], or null if unknown.
  static PhasePreset? tryParse(Object? value) {
    for (final preset in values) {
      if (preset.name == value) return preset;
    }
    return null;
  }
}

/// A chapter of the user's life. Only starts are stored: a phase ends where
/// the next one starts, the latest one is the current phase.
class LifePhase {
  LifePhase({
    required this.id,
    this.name = '',
    this.preset,
    required DateTime start,
    DateTime? plannedEnd,
    this.note,
  })  : start = compassDate(start),
        plannedEnd = plannedEnd == null ? null : compassDate(plannedEnd);

  final String id;

  /// The user's own name; empty for [preset] phases.
  final String name;
  final PhasePreset? preset;

  /// First day of the phase (date only).
  final DateTime start;

  /// Day the user plans to end it; null when open-ended.
  final DateTime? plannedEnd;

  /// "What was good about this phase?", written when closing it.
  final String? note;

  /// Copy with the given fields replaced; `clearX: true` sets X to null.
  LifePhase copyWith({
    String? name,
    PhasePreset? preset,
    DateTime? start,
    DateTime? plannedEnd,
    bool clearPlannedEnd = false,
    String? note,
    bool clearNote = false,
  }) {
    return LifePhase(
      id: id,
      name: name ?? this.name,
      preset: preset ?? this.preset,
      start: start ?? this.start,
      plannedEnd: clearPlannedEnd ? null : plannedEnd ?? this.plannedEnd,
      note: clearNote ? null : note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (preset != null) 'presetId': preset!.name,
        'start': encodeCompassDate(start),
        if (plannedEnd != null) 'plannedEnd': encodeCompassDate(plannedEnd!),
        if (note != null) 'note': note,
      };

  /// Phase of [json]; unreadable optional fields are dropped. Throws
  /// [FormatException] without an id or start.
  factory LifePhase.fromJson(Map<String, dynamic> json) {
    final id = nonEmptyCompassString(json['id']);
    final start = tryDecodeCompassDate(json['start']);
    if (id == null || start == null) {
      throw const FormatException('Life phase without id or start');
    }
    final name = json['name'];
    return LifePhase(
      id: id,
      name: name is String ? name : '',
      preset: PhasePreset.tryParse(json['presetId']),
      start: start,
      plannedEnd: tryDecodeCompassDate(json['plannedEnd']),
      note: nonEmptyCompassString(json['note']),
    );
  }
}
