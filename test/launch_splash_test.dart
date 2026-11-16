import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The native launch screen is only the app surface colour, without a logo:
/// paper (#F4F1EA) in light mode, ink (#0F0F10) in dark mode. The badge is
/// shown once, in the app, on the very first launch (FirstLaunchLogo).
void main() {
  const res = 'android/app/src/main/res';
  const assets = 'ios/Runner/Assets.xcassets';

  String read(String path) => File(path).readAsStringSync();

  group('Android', () {
    test('the former splash images are gone', () {
      for (final path in [
        '$res/drawable-nodpi/splash_logo.png',
        '$res/drawable-nodpi/splash_icon.png',
      ]) {
        expect(File(path).existsSync(), isFalse, reason: path);
      }
    });

    test('the launch backgrounds are only the splash colour', () {
      for (final folder in ['drawable', 'drawable-v21']) {
        final xml = read('$res/$folder/launch_background.xml');
        expect(xml, contains('@color/splash_background'), reason: folder);
        expect(xml, isNot(contains('@drawable/')), reason: folder);
        expect('<item'.allMatches(xml), hasLength(1), reason: folder);
      }
    });

    test('the splash colour is paper in light and ink in dark mode', () {
      expect(
        read('$res/values/colors.xml'),
        contains('<color name="splash_background">#F4F1EA</color>'),
      );
      expect(
        read('$res/values-night/colors.xml'),
        contains('<color name="splash_background">#0F0F10</color>'),
      );
    });

    test('the Android 12+ splash icon is transparent', () {
      final xml = read('$res/drawable/splash_icon_none.xml');
      expect(xml, contains('@android:color/transparent'));
      expect(xml, isNot(contains('@drawable/')));
    });

    test('Android 12+ styles: splash colour and the transparent icon', () {
      for (final folder in ['values-v31', 'values-night-v31']) {
        final xml = read('$res/$folder/styles.xml');
        expect(
          xml,
          contains(
            '<item name="android:windowSplashScreenBackground">'
            '@color/splash_background</item>',
          ),
          reason: folder,
        );
        // Without an icon Android 12+ would show the launcher icon.
        expect(
          xml,
          contains(
            '<item name="android:windowSplashScreenAnimatedIcon">'
            '@drawable/splash_icon_none</item>',
          ),
          reason: folder,
        );
        expect(xml, contains('name="NormalTheme"'), reason: folder);
      }
    });
  });

  group('iOS', () {
    test('the launch image is gone', () {
      expect(
        Directory('$assets/LaunchImage.imageset').existsSync(),
        isFalse,
      );
    });

    test('the launch background colour has paper and ink variants', () {
      final json = read('$assets/LaunchBackground.colorset/Contents.json');
      expect(json, contains('"red" : "0xF4"'));
      expect(json, contains('"green" : "0xF1"'));
      expect(json, contains('"blue" : "0xEA"'));
      expect(json, contains('"value" : "dark"'));
      expect(json, contains('"red" : "0x0F"'));
      expect(json, contains('"blue" : "0x10"'));
    });

    test('the launch storyboard is only the named background colour', () {
      final storyboard = read('ios/Runner/Base.lproj/LaunchScreen.storyboard');
      expect(
        storyboard,
        contains('<color key="backgroundColor" name="LaunchBackground"/>'),
      );
      expect(storyboard, contains('<namedColor name="LaunchBackground">'));
      expect(storyboard, isNot(contains('<imageView')));
      expect(storyboard, isNot(contains('<image ')));
      expect(storyboard, isNot(contains('LaunchImage')));
    });
  });

  test('the first-launch badge is a bundled asset', () {
    expect(File('branding/exports/logo/logo-512.png').existsSync(), isTrue);
    expect(
      read('pubspec.yaml'),
      contains('- branding/exports/logo/logo-512.png'),
    );
  });
}
