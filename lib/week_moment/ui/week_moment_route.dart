import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/onboarding/personal_address.dart';
import 'package:memento_mori_life_in_weeks/theme/motion.dart';
import 'package:memento_mori_life_in_weeks/week_moment/ui/week_moment_screen.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_moment_result.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_moment_story.dart';
import 'package:memento_mori_life_in_weeks/week_moment/week_turn.dart';

/// Fades the weekly moment in as an opaque full screen over [context]'s
/// navigator and completes with how it ended (back = closed); [turn] names
/// the weeks on the closing card (null: seen from today).
Future<WeekMomentResult> showWeekMoment(
  BuildContext context, {
  required WeekMomentStory story,
  PersonalAddress address = PersonalAddress.none,
  WeekTurn? turn,
}) async {
  final duration = Motion.of(context, Motion.medium);
  final result = await Navigator.of(context).push<WeekMomentResult>(
    PageRouteBuilder<WeekMomentResult>(
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      pageBuilder: (_, _, _) =>
          WeekMomentScreen(story: story, address: address, turn: turn),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
  return result ?? WeekMomentResult.closed;
}
