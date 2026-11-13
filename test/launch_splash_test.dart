import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The native launch screen shows the round badge on the app surface colour:
/// paper (#F4F1EA) in light mode, ink (#0F0F10) in dark mode.
void main() {
  const res = 'android/app/src/main/res';
  const assets = 'ios/Runner/Assets.xcassets';

  String read(String path) => File(path).readAsStringSync();

  group('Android', () {
    test('the splash images exist', () {
      for (final path in [
        '$res/drawable-nodpi/splash_logo.png',
        '$res/drawable-nodpi/splash_icon.png',
      ]) {
        expect(File(path).existsSync(), isTrue, reason: path);
      }
    });

    test('the launch backgrounds draw the badge on the splash colour', () {
      for (final folder in ['drawable', 'drawable-v21']) {
        final xml = read('$res/$folder/launch_background.xml');
        expect(xml, contains('@color/splash_background'), reason: folder);
        expect(xml, contains('@drawable/splash_logo'), reason: folder);
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

    test('Android 12+ styles set the splash screen in light and dark', () {
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
        expect(
          xml,
          contains(
            '<item name="android:windowSplashScreenAnimatedIcon">'
            '@drawable/splash_icon</item>',
          ),
          reason: folder,
        );
        expect(xml, contains('name="NormalTheme"'), reason: folder);
      }
    });
  });

  group('iOS', () {
    test('the launch image exists at every scale', () {
      for (final name in [
        'LaunchImage.png',
        'LaunchImage@2x.png',
        'LaunchImage@3x.png',
      ]) {
        final path = '$assets/LaunchImage.imageset/$name';
        expect(File(path).existsSync(), isTrue, reason: path);
      }
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

    test('the launch storyboard uses the named background colour', () {
      final storyboard = read('ios/Runner/Base.lproj/LaunchScreen.storyboard');
      expect(
        storyboard,
        contains('<color key="backgroundColor" name="LaunchBackground"/>'),
      );
      expect(storyboard, contains('<namedColor name="LaunchBackground">'));
      expect(
        storyboard,
        contains('<image name="LaunchImage" width="192" height="192"/>'),
      );
    });
  });
}
