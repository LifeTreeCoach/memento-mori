import 'package:flutter/services.dart';

/// Loads the bundled text fonts (Inter, Fraunces, Nunito) so layout tests
/// measure real text widths instead of the square test font.
Future<void> loadAppFonts() async {
  const families = {
    'Inter': ['Regular', 'Medium', 'SemiBold'],
    'Fraunces': ['Regular', 'SemiBold'],
    'Nunito': ['SemiBold', 'Bold'],
  };
  for (final MapEntry(key: family, value: weights) in families.entries) {
    final loader = FontLoader(family);
    for (final weight in weights) {
      loader.addFont(rootBundle.load('assets/fonts/$family-$weight.ttf'));
    }
    await loader.load();
  }
}
