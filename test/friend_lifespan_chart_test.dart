import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/theme/color_themes.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/friend_detail/friend_lifespan_painter.dart';
import 'package:memento_mori_life_in_weeks/theme/app_theme.dart';
import 'package:memento_mori_life_in_weeks/theme/contrast.dart';
import 'package:memento_mori_life_in_weeks/theme/layout_text.dart';
import 'package:memento_mori_life_in_weeks/theme/life_palette.dart';
import 'package:memento_mori_life_in_weeks/theme/theme_options.dart';

FriendLifespanPainter _painter(ThemeData theme) {
  final scheme = theme.colorScheme;
  return FriendLifespanPainter(
    friend: Friend(
      id: '1',
      name: 'Anna',
      birthDate: DateTime(1990, 1, 1),
      createdDate: DateTime(2020),
      lastUpdated: DateTime(2020),
    ),
    palette: theme.extension<LifePalette>()!,
    outline: scheme.outlineVariant,
    labelColor: scheme.onSurfaceVariant,
    scaleText: LayoutText.fromTheme(theme),
    indicatorFill: scheme.surface,
  );
}

void main() {
  test('scale labels below the liquid surface sit on the lived fill', () {
    final theme = AppTheme.build(style: ThemeStyle.stoic, brightness: Brightness.dark);
    final painter = _painter(theme);
    expect(painter.scaleLabelBackground(150, 100), painter.palette.lived);
    expect(painter.scaleLabelBackground(50, 100), painter.palette.remaining);
  });

  for (final brightness in Brightness.values) {
    for (final style in ThemeStyle.values) {
      for (final id in ColorThemes.getSelectableThemeIds()) {
        test('$id ${style.name} ${brightness.name}: scale labels >= 4.5:1', () {
          final theme = AppTheme.build(
            style: style,
            brightness: brightness,
            gridOverride: LifePaletteColors.forColorThemeId(id),
          );
          final painter = _painter(theme);
          for (final (labelY, background) in [
            (150.0, painter.palette.lived),
            (50.0, painter.palette.remaining),
          ]) {
            final color = painter.scaleLabelStyle(labelY, 100).color!;
            expect(contrastRatio(color, background),
                greaterThanOrEqualTo(LayoutText.minContrast),
                reason: 'on $background');
          }
        });
      }
    }
  }
}
