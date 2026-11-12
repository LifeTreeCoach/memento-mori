import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/lifespan/lifespan_profile_store.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/lifespan_estimate_screen.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/lifespan_profile.dart';
import 'package:memento_mori_life_in_weeks/people/friend_lifespan_estimate.dart';

/// What the friend form hands to the estimate about a person.
class FriendEstimateRequest {
  const FriendEstimateRequest({
    required this.name,
    required this.birthDate,
    required this.initial,
    required this.currentYears,
  });

  final String name;
  final DateTime birthDate;
  final LifespanProfile initial;

  /// The slider value ("keep" in the flow).
  final int currentYears;

  /// The answers to start from: the stored ones, or an empty profile with
  /// the user's own country (from [own]); sex is left to choose.
  static LifespanProfile initialProfile(
    FriendLifespanEstimate? stored, {
    LifespanProfileStore own = const SettingsLifespanProfileStore(),
  }) =>
      stored?.profile ?? LifespanProfile(country: own.load().effectiveCountry);
}

/// Opens the estimate for a person; completes with the applied profile or
/// null. Tests inject a fake one into the form.
typedef FriendEstimateLauncher = Future<LifespanProfile?> Function(
  BuildContext context,
  FriendEstimateRequest request,
);

/// The real [FriendEstimateLauncher]: [LifespanEstimateScreen] about
/// [FriendEstimateRequest.name]; the form keeps the returned profile.
Future<LifespanProfile?> openFriendEstimate(
  BuildContext context,
  FriendEstimateRequest request,
) => LifespanEstimateScreen.openForPerson(
  context,
  name: request.name,
  birthDate: request.birthDate,
  initial: request.initial,
  currentYears: request.currentYears,
);
