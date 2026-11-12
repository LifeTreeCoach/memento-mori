import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_prompt.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

/// Localized names and icons of the Compass model values.
extension CompassLabels on AppLocalizations {
  String areaLabel(LifeArea area) => translate('compass_area_${area.name}');

  String horizonLabel(Horizon horizon) => switch (horizon.kind) {
        HorizonKind.thisSeason => translate('compass_horizon_this_season'),
        HorizonKind.thisYear => translate('compass_horizon_this_year'),
        HorizonKind.someday => translate('compass_horizon_someday'),
        HorizonKind.byAge => plural('compass_horizon_by_age', horizon.age ?? 0),
      };

  /// Area and horizon of [intention], for a quiet meta line.
  List<String> intentionMeta(Intention intention) => [
        if (intention.area case final area?) areaLabel(area),
        if (intention.horizon case final horizon?) horizonLabel(horizon),
      ];

  /// What the eyebrow names after "Question of the week": the prompt's own
  /// topic, else the name of its kind (null for non-question kinds).
  String? questionTopicLabel(CompassPrompt prompt) =>
      prompt.topicFor(locale.languageCode) ?? questionKindLabel(prompt.kind);

  /// Name of a weekly question kind; null for non-question kinds.
  String? questionKindLabel(CompassPromptKind kind) => switch (kind) {
        CompassPromptKind.courage ||
        CompassPromptKind.connection ||
        CompassPromptKind.rest ||
        CompassPromptKind.pride =>
          translate('compass_kind_${kind.name}'),
        _ => null,
      };
}

/// Icon of [moment]: its area, else a sparkle (or a check if it came from
/// a completed intention).
IconData momentIcon(Moment moment) {
  if (moment.area case final area?) return lifeAreaIcon(area);
  return moment.fromIntentionId == null
      ? Icons.auto_awesome_outlined
      : Icons.check_circle_outline_rounded;
}

/// A calm outline icon per life area.
IconData lifeAreaIcon(LifeArea area) => switch (area) {
      LifeArea.relationships => Icons.favorite_outline_rounded,
      LifeArea.health => Icons.spa_outlined,
      LifeArea.growth => Icons.eco_outlined,
      LifeArea.creativity => Icons.palette_outlined,
      LifeArea.adventure => Icons.landscape_outlined,
      LifeArea.contribution => Icons.volunteer_activism_outlined,
      LifeArea.rest => Icons.self_improvement_rounded,
    };
