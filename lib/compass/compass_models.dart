/// Compass: a gentle "life to-do" that helps choose what matters in the
/// remaining weeks, without adding stress.
///
/// Principles:
/// - Oliver Burkeman, *Four Thousand Weeks*: finitude means choosing. At most
///   three intentions are "Now" ([nowLimit]); everything else waits calmly in
///   "Someday", and leaving most things undone is normal, not failure.
/// - Bronnie Ware, *The Top Five Regrets of the Dying*: the weekly questions
///   lean on the common regrets - courage to live one's own life, time with
///   friends, letting oneself be happier, not only working - and on noticing
///   what already went well (pride, moments).
/// - Kristin Neff, self-compassion: kindness instead of self-judgement;
///   compassionate notes, "gentle only" mode without courage questions.
///
/// Deliberately absent: streaks, overdue states, badges, scores.
/// A horizon ("this season", "by 50") is orientation, never a deadline; the
/// optional due date of an [IntentionKind.enjoy] intention is an
/// appointment with oneself, never a reproach.
library;

import 'package:memento_mori_life_in_weeks/compass/life_phase.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';

/// Most intentions that can be "Now" at the same time.
const int nowLimit = 3;

/// Areas of a life an intention or moment can belong to.
enum LifeArea {
  relationships,
  health,
  growth,
  creativity,
  adventure,
  contribution,
  rest;

  /// The area named [value], or null if unknown.
  static LifeArea? tryParse(Object? value) => _byName(values, value);
}

/// Where an intention stands. There is no "overdue". [letGo] intentions
/// were consciously released when a phase closed; they stay visible.
enum IntentionStatus {
  now,
  someday,
  done,
  letGo;

  static IntentionStatus? tryParse(Object? value) => _byName(values, value);
}

/// What an intention asks for: getting something done (urgency) or
/// enjoying something (without pressure).
enum IntentionKind {
  doTask,
  enjoy;

  static IntentionKind? tryParse(Object? value) => _byName(values, value);
}

T? _byName<T extends Enum>(List<T> values, Object? name) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  return null;
}

/// Kind of [Horizon].
enum HorizonKind { thisSeason, thisYear, someday, byAge }

/// A loose time frame for an intention (orientation, not a due date).
///
/// JSON: `thisSeason`, `thisYear`, `someday` or `byAge:<age>`.
class Horizon {
  const Horizon._(this.kind, [this.age]);

  static const Horizon thisSeason = Horizon._(HorizonKind.thisSeason);
  static const Horizon thisYear = Horizon._(HorizonKind.thisYear);
  static const Horizon someday = Horizon._(HorizonKind.someday);

  /// Before turning [age].
  const Horizon.byAge(int age) : this._(HorizonKind.byAge, age);

  final HorizonKind kind;

  /// The age for [HorizonKind.byAge], else null.
  final int? age;

  static const String _agePrefix = 'byAge:';

  String toJson() =>
      kind == HorizonKind.byAge ? '$_agePrefix$age' : kind.name;

  /// The horizon of [value], or null if missing or unreadable.
  static Horizon? tryParse(Object? value) {
    if (value is! String) return null;
    if (value.startsWith(_agePrefix)) {
      final age = int.tryParse(value.substring(_agePrefix.length));
      return age == null || age < 0 ? null : Horizon.byAge(age);
    }
    return switch (_byName(HorizonKind.values, value)) {
      HorizonKind.thisSeason => thisSeason,
      HorizonKind.thisYear => thisYear,
      HorizonKind.someday => someday,
      _ => null,
    };
  }

  @override
  bool operator ==(Object other) =>
      other is Horizon && other.kind == kind && other.age == age;

  @override
  int get hashCode => Object.hash(kind, age);

  @override
  String toString() => 'Horizon(${toJson()})';
}

/// Local-midnight date of [date].
DateTime compassDate(DateTime date) => DateTime(date.year, date.month, date.day);

/// [date] as `yyyy-MM-dd` (the format of every Compass date).
String encodeCompassDate(DateTime date) => Friend.encodeBirthDate(date);

/// Local-midnight date of a stored [value], or null if missing or unreadable.
DateTime? tryDecodeCompassDate(Object? value) {
  try {
    return value == null ? null : Friend.decodeBirthDate(value);
  } on FormatException {
    return null;
  }
}

/// [value] if it is a string with visible text, else null.
String? nonEmptyCompassString(Object? value) =>
    value is String && value.trim().isNotEmpty ? value : null;

/// Something the user wants to do with their remaining time.
class Intention {
  Intention({
    required this.id,
    required this.title,
    this.note,
    this.area,
    this.horizon,
    this.status = IntentionStatus.someday,
    required DateTime createdAt,
    DateTime? doneAt,
    this.friendId,
    this.kind,
    this.phaseId,
    DateTime? dueDate,
    DateTime? letGoAt,
  })  : createdAt = compassDate(createdAt),
        doneAt = doneAt == null ? null : compassDate(doneAt),
        dueDate = dueDate == null ? null : compassDate(dueDate),
        letGoAt = letGoAt == null ? null : compassDate(letGoAt);

  final String id;
  final String title;
  final String? note;
  final LifeArea? area;
  final Horizon? horizon;
  final IntentionStatus status;

  /// Day it was written down (date only).
  final DateTime createdAt;

  /// Day it was completed; null unless [status] is done.
  final DateTime? doneAt;

  /// The person this intention is about ("Plan time together"); null for
  /// the user's own intentions and in data saved before it existed.
  final String? friendId;

  /// Do or enjoy; null in data saved before it existed.
  final IntentionKind? kind;

  /// The [LifePhase] it belongs to (set while in "Now"); null otherwise.
  final String? phaseId;

  /// Optional appointment (date only), e.g. for an enjoy intention.
  final DateTime? dueDate;

  /// Day it was let go; null unless [status] is letGo.
  final DateTime? letGoAt;

  /// Not done and not let go ("Now" or "Someday").
  bool get isOpen =>
      status == IntentionStatus.now || status == IntentionStatus.someday;

  /// Copy with the given fields replaced; `clearX: true` sets X to null.
  Intention copyWith({
    String? title,
    String? note,
    bool clearNote = false,
    LifeArea? area,
    bool clearArea = false,
    Horizon? horizon,
    bool clearHorizon = false,
    IntentionStatus? status,
    DateTime? doneAt,
    bool clearDoneAt = false,
    IntentionKind? kind,
    bool clearKind = false,
    DateTime? dueDate,
    bool clearDueDate = false,
    String? phaseId,
    bool clearPhaseId = false,
    DateTime? letGoAt,
  }) {
    final newStatus = status ?? this.status;
    return Intention(
      id: id,
      title: title ?? this.title,
      note: clearNote ? null : note ?? this.note,
      area: clearArea ? null : area ?? this.area,
      horizon: clearHorizon ? null : horizon ?? this.horizon,
      status: newStatus,
      createdAt: createdAt,
      doneAt: clearDoneAt ? null : doneAt ?? this.doneAt,
      friendId: friendId,
      kind: clearKind ? null : kind ?? this.kind,
      phaseId: clearPhaseId ? null : phaseId ?? this.phaseId,
      dueDate: clearDueDate ? null : dueDate ?? this.dueDate,
      letGoAt: newStatus == IntentionStatus.letGo ? letGoAt ?? this.letGoAt : null,
    );
  }

  /// Copy belonging to phase [phaseId] (null: to no phase).
  Intention withPhase(String? phaseId) =>
      copyWith(phaseId: phaseId, clearPhaseId: phaseId == null);

  /// Copy about friend [friendId] (null: about nobody).
  Intention withFriend(String? friendId) => Intention(
        id: id,
        title: title,
        note: note,
        area: area,
        horizon: horizon,
        status: status,
        createdAt: createdAt,
        doneAt: doneAt,
        friendId: friendId,
        kind: kind,
        phaseId: phaseId,
        dueDate: dueDate,
        letGoAt: letGoAt,
      );

  /// Copy released on [today]; it keeps its phase.
  Intention letGo(DateTime today) => copyWith(
      status: IntentionStatus.letGo, letGoAt: today, clearDoneAt: true);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        if (note != null) 'note': note,
        if (area != null) 'area': area!.name,
        if (horizon != null) 'horizon': horizon!.toJson(),
        'status': status.name,
        'createdAt': encodeCompassDate(createdAt),
        if (doneAt != null) 'doneAt': encodeCompassDate(doneAt!),
        if (friendId != null) 'friendId': friendId,
        if (kind != null) 'kind': kind!.name,
        if (phaseId != null) 'phaseId': phaseId,
        if (dueDate != null) 'dueDate': encodeCompassDate(dueDate!),
        if (letGoAt != null) 'letGoAt': encodeCompassDate(letGoAt!),
      };

  /// Intention of [json]; unknown or missing optional fields fall back to
  /// defaults. Throws [FormatException] without an id or title.
  factory Intention.fromJson(Map<String, dynamic> json) {
    final id = nonEmptyCompassString(json['id']);
    final title = nonEmptyCompassString(json['title']);
    if (id == null || title == null) {
      throw const FormatException('Intention without id or title');
    }
    final status = IntentionStatus.tryParse(json['status']) ?? IntentionStatus.someday;
    final doneAt = tryDecodeCompassDate(json['doneAt']);
    return Intention(
      id: id,
      title: title,
      note: nonEmptyCompassString(json['note']),
      area: LifeArea.tryParse(json['area']),
      horizon: Horizon.tryParse(json['horizon']),
      status: status,
      createdAt: tryDecodeCompassDate(json['createdAt']) ?? doneAt ?? DateTime(1970),
      doneAt: status == IntentionStatus.done ? doneAt : null,
      friendId: nonEmptyCompassString(json['friendId']),
      kind: IntentionKind.tryParse(json['kind']),
      phaseId: nonEmptyCompassString(json['phaseId']),
      dueDate: tryDecodeCompassDate(json['dueDate']),
      letGoAt: status == IntentionStatus.letGo
          ? tryDecodeCompassDate(json['letGoAt'])
          : null,
    );
  }
}

/// Something lived worth remembering; marked on the life grid.
class Moment {
  Moment({
    required this.id,
    required this.title,
    required DateTime date,
    this.area,
    this.fromIntentionId,
    this.note,
  }) : date = compassDate(date);

  final String id;
  final String title;

  /// Day it happened (date only, may be in the past).
  final DateTime date;
  final LifeArea? area;

  /// The completed intention this moment came from, if any.
  final String? fromIntentionId;

  /// A short personal line, e.g. what the user is grateful for (written in
  /// the look back after completing an intention); null when empty.
  final String? note;

  /// Copy with the given fields replaced; `clearX: true` sets X to null.
  Moment copyWith({
    String? title,
    DateTime? date,
    LifeArea? area,
    bool clearArea = false,
    String? note,
    bool clearNote = false,
  }) {
    return Moment(
      id: id,
      title: title ?? this.title,
      date: date ?? this.date,
      area: clearArea ? null : area ?? this.area,
      fromIntentionId: fromIntentionId,
      note: clearNote ? null : note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date': encodeCompassDate(date),
        if (area != null) 'area': area!.name,
        if (fromIntentionId != null) 'fromIntentionId': fromIntentionId,
        if (note != null) 'note': note,
      };

  /// Moment of [json]. Throws [FormatException] without id, title or date.
  factory Moment.fromJson(Map<String, dynamic> json) {
    final id = nonEmptyCompassString(json['id']);
    final title = nonEmptyCompassString(json['title']);
    final date = tryDecodeCompassDate(json['date']);
    if (id == null || title == null || date == null) {
      throw const FormatException('Moment without id, title or date');
    }
    return Moment(
      id: id,
      title: title,
      date: date,
      area: LifeArea.tryParse(json['area']),
      fromIntentionId: nonEmptyCompassString(json['fromIntentionId']),
      note: nonEmptyCompassString(json['note']),
    );
  }
}

/// Everything the user wrote in Compass (stored and backed up as one JSON
/// object). Settings are kept separately.
class CompassData {
  CompassData({
    List<Intention> intentions = const [],
    List<Moment> moments = const [],
    List<LifePhase> phases = const [],
  })  : intentions = List.unmodifiable(intentions),
        moments = List.unmodifiable(moments),
        phases = List.unmodifiable(phases);

  static final CompassData empty = CompassData();

  /// In the order they were added.
  final List<Intention> intentions;

  /// In the order they were added (see [momentsBetween] for date order).
  final List<Moment> moments;

  /// Life phases in the order they were added (see `resolvePhases` in
  /// `phase_timeline.dart` for date order).
  final List<LifePhase> phases;

  bool get isEmpty => intentions.isEmpty && moments.isEmpty && phases.isEmpty;

  List<Intention> withStatus(IntentionStatus status) =>
      intentions.where((i) => i.status == status).toList();

  int get nowCount =>
      intentions.where((i) => i.status == IntentionStatus.now).length;

  bool get isNowFull => nowCount >= nowLimit;

  /// Moments on days from [start] (inclusive) to [end] (exclusive), oldest
  /// first. Only the calendar day of the bounds counts (any time zone).
  List<Moment> momentsBetween(DateTime start, DateTime end) {
    final from = DateTime(start.year, start.month, start.day);
    final until = DateTime(end.year, end.month, end.day);
    return moments
        .where((m) => !m.date.isBefore(from) && m.date.isBefore(until))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  CompassData copyWith({
    List<Intention>? intentions,
    List<Moment>? moments,
    List<LifePhase>? phases,
  }) =>
      CompassData(
        intentions: intentions ?? this.intentions,
        moments: moments ?? this.moments,
        phases: phases ?? this.phases,
      );

  Map<String, dynamic> toJson() => {
        'intentions': [for (final i in intentions) i.toJson()],
        'moments': [for (final m in moments) m.toJson()],
        if (phases.isNotEmpty) 'phases': [for (final p in phases) p.toJson()],
      };

  /// Data of [json]; a missing list is empty, unreadable entries are skipped
  /// and anything that is not a map gives [empty].
  factory CompassData.fromJson(Object? json) {
    if (json is! Map) return CompassData();
    return CompassData(
      intentions: _parseAll(json['intentions'], Intention.fromJson),
      moments: _parseAll(json['moments'], Moment.fromJson),
      phases: _parseAll(json['phases'], LifePhase.fromJson),
    );
  }

  static List<T> _parseAll<T>(
      Object? list, T Function(Map<String, dynamic>) parse) {
    if (list is! List) return [];
    final result = <T>[];
    for (final entry in list) {
      if (entry is! Map) continue;
      try {
        result.add(parse(Map<String, dynamic>.from(entry)));
      } on FormatException {
        continue;
      } on TypeError {
        continue;
      }
    }
    return result;
  }
}
