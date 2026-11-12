import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/theme/app_color_schemes.dart';
import 'package:memento_mori_life_in_weeks/theme/life_palette.dart';
import 'package:memento_mori_life_in_weeks/theme/phase_palette.dart';
import 'package:memento_mori_life_in_weeks/theme/theme_options.dart';

/// Builds the app's Material 3 [ThemeData] for a style and brightness.
class AppTheme {
  AppTheme._();

  static const String serifFamily = 'Fraunces';
  static const String sansFamily = 'Inter';
  static const String roundedFamily = 'Nunito';

  static ThemeData build({
    required ThemeStyle style,
    required Brightness brightness,
    LifePaletteColors? gridOverride,
  }) {
    final scheme = AppColorSchemes.of(style, brightness);
    final spec = _ThemeSpec(style, scheme, buildTextTheme(style, scheme));
    final palette = LifePalette.resolve(
      style,
      brightness,
      gridOverride: gridOverride,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: sansFamily,
      textTheme: spec.text,
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.standard,
      extensions: [
        palette,
        PhaseColors.forTheme(
          style,
          brightness,
          palette,
          userColorTheme: gridOverride != null,
        ),
      ],
      pageTransitionsTheme: _pageTransitions,
      appBarTheme: _appBar(spec),
      navigationBarTheme: _navigationBar(spec),
      cardTheme: _card(spec),
      segmentedButtonTheme: _segmentedButton(spec),
      listTileTheme: _listTile(spec),
      switchTheme: _switch(scheme),
      bottomSheetTheme: _bottomSheet(scheme),
      dialogTheme: _dialog(spec),
      inputDecorationTheme: _input(spec),
      filledButtonTheme: _filledButton(spec),
      textButtonTheme: _textButton(spec),
      chipTheme: _chip(spec),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: _snackBar(spec),
    );
  }

  // ---------------------------------------------------------------------------
  // Typography

  /// Inter for body/labels; Fraunces (stoic) or Nunito (warm) for headings.
  static TextTheme buildTextTheme(ThemeStyle style, ColorScheme scheme) {
    final body = _baseTextTheme(scheme).apply(
      fontFamily: sansFamily,
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    return style == ThemeStyle.stoic
        ? _stoicHeadings(body)
        : _warmHeadings(body);
  }

  static TextTheme _baseTextTheme(ColorScheme scheme) {
    final typography = Typography.material2021(colorScheme: scheme);
    final colored = scheme.brightness == Brightness.dark
        ? typography.white
        : typography.black;
    return typography.englishLike.merge(colored);
  }

  static TextTheme _stoicHeadings(TextTheme t) {
    TextStyle? serif(TextStyle? s, FontWeight w, double spacing) => s?.copyWith(
      fontFamily: serifFamily,
      fontWeight: w,
      letterSpacing: spacing,
      height: 1.15,
    );
    return t.copyWith(
      displayLarge: serif(t.displayLarge, FontWeight.w400, -1.0),
      displayMedium: serif(t.displayMedium, FontWeight.w400, -0.6),
      displaySmall: serif(t.displaySmall, FontWeight.w400, -0.4),
      headlineLarge: serif(t.headlineLarge, FontWeight.w400, -0.3),
      headlineMedium: serif(t.headlineMedium, FontWeight.w400, -0.2),
      headlineSmall: serif(t.headlineSmall, FontWeight.w600, -0.1),
      titleLarge: serif(t.titleLarge, FontWeight.w600, 0),
    );
  }

  static TextTheme _warmHeadings(TextTheme t) {
    TextStyle? rounded(TextStyle? s, FontWeight w) => s?.copyWith(
      fontFamily: roundedFamily,
      fontWeight: w,
      letterSpacing: 0,
      height: 1.2,
    );
    return t.copyWith(
      displayLarge: rounded(t.displayLarge, FontWeight.w700),
      displayMedium: rounded(t.displayMedium, FontWeight.w700),
      displaySmall: rounded(t.displaySmall, FontWeight.w700),
      headlineLarge: rounded(t.headlineLarge, FontWeight.w700),
      headlineMedium: rounded(t.headlineMedium, FontWeight.w700),
      headlineSmall: rounded(t.headlineSmall, FontWeight.w700),
      titleLarge: rounded(t.titleLarge, FontWeight.w700),
    );
  }

  // ---------------------------------------------------------------------------
  // Component themes

  static const PageTransitionsTheme _pageTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: ZoomPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
    },
  );

  static AppBarThemeData _appBar(_ThemeSpec spec) {
    return AppBarThemeData(
      backgroundColor: spec.scheme.surface,
      foregroundColor: spec.scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: spec.text.titleLarge,
    );
  }

  static NavigationBarThemeData _navigationBar(_ThemeSpec spec) {
    return NavigationBarThemeData(
      backgroundColor: spec.scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 68,
      indicatorColor: spec.scheme.secondaryContainer,
      labelTextStyle: WidgetStatePropertyAll(spec.text.labelMedium),
    );
  }

  static CardThemeData _card(_ThemeSpec spec) {
    final scheme = spec.scheme;
    return CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: spec.isStoic
          ? scheme.surfaceContainerLow
          : scheme.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spec.cardRadius),
        side: spec.isStoic
            ? BorderSide(color: scheme.outlineVariant)
            : BorderSide.none,
      ),
    );
  }

  static SegmentedButtonThemeData _segmentedButton(_ThemeSpec spec) {
    final scheme = spec.scheme;
    return SegmentedButtonThemeData(
      style: ButtonStyle(
        textStyle: WidgetStatePropertyAll(spec.text.labelLarge),
        side: WidgetStatePropertyAll(BorderSide(color: scheme.outlineVariant)),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.secondaryContainer
              : Colors.transparent,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.onSecondaryContainer
              : scheme.onSurfaceVariant,
        ),
      ),
    );
  }

  static ListTileThemeData _listTile(_ThemeSpec spec) {
    return ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      iconColor: spec.scheme.onSurfaceVariant,
      titleTextStyle: spec.text.bodyLarge?.copyWith(
        fontWeight: FontWeight.w500,
      ),
      subtitleTextStyle: spec.text.bodyMedium?.copyWith(
        color: spec.scheme.onSurfaceVariant,
      ),
    );
  }

  static SwitchThemeData _switch(ColorScheme scheme) {
    return SwitchThemeData(
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? Colors.transparent
            : scheme.outline,
      ),
    );
  }

  static BottomSheetThemeData _bottomSheet(ColorScheme scheme) {
    return BottomSheetThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      showDragHandle: true,
      dragHandleColor: scheme.outline,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    );
  }

  static DialogThemeData _dialog(_ThemeSpec spec) {
    return DialogThemeData(
      backgroundColor: spec.scheme.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: spec.text.headlineSmall,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spec.isStoic ? 20 : 28),
      ),
    );
  }

  static InputDecorationThemeData _input(_ThemeSpec spec) {
    final scheme = spec.scheme;
    // Underline borders keep the floating label inside the filled
    // container (an outline border would notch it into the top edge).
    UnderlineInputBorder border(Color color, double width) =>
        UnderlineInputBorder(
          borderRadius: BorderRadius.circular(spec.controlRadius),
          borderSide: width == 0
              ? BorderSide.none
              : BorderSide(color: color, width: width),
        );
    return InputDecorationThemeData(
      filled: true,
      fillColor: scheme.surfaceContainerHigh,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: border(Colors.transparent, 0),
      enabledBorder: border(Colors.transparent, 0),
      focusedBorder: border(scheme.primary, 1.5),
      errorBorder: border(scheme.error, 1),
      focusedErrorBorder: border(scheme.error, 1.5),
    );
  }

  static FilledButtonThemeData _filledButton(_ThemeSpec spec) {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 48),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: spec.text.labelLarge,
        shape: spec.buttonShape,
      ),
    );
  }

  static TextButtonThemeData _textButton(_ThemeSpec spec) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: spec.scheme.primary,
        textStyle: spec.text.labelLarge,
        shape: spec.buttonShape,
      ),
    );
  }

  static ChipThemeData _chip(_ThemeSpec spec) {
    return ChipThemeData(
      backgroundColor: spec.scheme.surfaceContainerLow,
      selectedColor: spec.scheme.secondaryContainer,
      side: BorderSide(color: spec.scheme.outlineVariant),
      labelStyle: spec.text.labelLarge,
      shape: spec.isStoic
          ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
          : const StadiumBorder(),
    );
  }

  static SnackBarThemeData _snackBar(_ThemeSpec spec) {
    return SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: spec.scheme.inverseSurface,
      contentTextStyle: spec.text.bodyMedium?.copyWith(
        color: spec.scheme.onInverseSurface,
      ),
      actionTextColor: spec.scheme.inversePrimary,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(spec.controlRadius),
      ),
    );
  }
}

/// Values shared by the component theme builders.
class _ThemeSpec {
  _ThemeSpec(this.style, this.scheme, this.text);

  final ThemeStyle style;
  final ColorScheme scheme;
  final TextTheme text;

  bool get isStoic => style == ThemeStyle.stoic;

  double get cardRadius => isStoic ? 12 : 20;

  double get controlRadius => isStoic ? 12 : 16;

  OutlinedBorder get buttonShape => isStoic
      ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
      : const StadiumBorder();
}
