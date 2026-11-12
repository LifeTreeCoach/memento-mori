import 'dart:convert';

import 'package:memento_mori_life_in_weeks/lifespan/ui/lifespan_profile.dart';

/// A person's answers to the lifespan estimate (country, sex, the optional
/// answers incl. health conditions) and the applied result, kept with the
/// [Friend] under `lifespanEstimate`.
///
/// The per-factor `gains` of the estimate are not stored: they only explain
/// the result screen and are computed again whenever the flow is reopened.
class FriendLifespanEstimate {
  const FriendLifespanEstimate(this.profile);

  static const String gainsKey = 'gains';

  final LifespanProfile profile;

  /// The years the estimate applied; null before it was applied.
  int? get appliedYears => profile.applied?.appliedYears;

  /// Reads [json] tolerantly: null when it is not a map, broken fields are
  /// left empty (see [LifespanProfile.fromJson]).
  static FriendLifespanEstimate? fromJson(Object? json) {
    if (json is! Map) return null;
    return FriendLifespanEstimate(
      LifespanProfile.fromJson(Map<String, Object?>.from(json)),
    );
  }

  Map<String, Object?> toJson() {
    final json = profile.toJson();
    final applied = json[LifespanProfile.appliedKey];
    if (applied is Map<String, Object?>) {
      json[LifespanProfile.appliedKey] = Map.of(applied)..remove(gainsKey);
    }
    return json;
  }

  @override
  bool operator ==(Object other) =>
      other is FriendLifespanEstimate &&
      jsonEncode(other.toJson()) == jsonEncode(toJson());

  @override
  int get hashCode => jsonEncode(toJson()).hashCode;

  @override
  String toString() => 'FriendLifespanEstimate(${jsonEncode(toJson())})';
}
