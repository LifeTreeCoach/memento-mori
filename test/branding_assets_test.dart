import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The brand assets used in the app and the README come from `branding/`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the in-app brand icon is a bundled asset', () async {
    final data = await rootBundle.load('branding/exports/web/icon-192.png');
    expect(data.lengthInBytes, greaterThan(0));
  });

  test('the README header shows the round logo', () {
    final readme = File('README.md').readAsStringSync();
    expect(readme, contains('src="branding/logo.svg"'));
    expect(File('branding/logo.svg').existsSync(), isTrue);
  });

  test('launcher icons are generated from the branding exports', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final path in [
      'branding/exports/app/app-icon-1024.png',
      'branding/exports/android/adaptive-foreground-1024.png',
      'branding/exports/android/adaptive-background-1024.png',
      'branding/exports/android/adaptive-monochrome-1024.png',
    ]) {
      expect(pubspec, contains(path));
      expect(File(path).existsSync(), isTrue, reason: path);
    }
  });
}
