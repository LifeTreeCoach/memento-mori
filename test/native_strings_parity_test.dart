import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/native_strings.dart';

/// Native string files stay in step with English: same names, plural forms
/// `one` + `other`, same format arguments, no empty values.
void main() {
  const languages = ['en', 'de', 'fr', 'es'];
  String androidDir(String code) => code == 'en' ? 'values' : 'values-$code';

  for (final module in ['app', 'wear']) {
    test('Android :$module strings match English in every language', () {
      AndroidStrings load(String code) => parseAndroidStrings(
        File('android/$module/src/main/res/${androidDir(code)}/strings.xml')
            .readAsStringSync(),
      );
      final en = load('en');
      expect(en.strings, isNotEmpty);
      expect(en.plurals, isNotEmpty);
      for (final code in languages) {
        expect(androidParityProblems('$module/$code', en, load(code)), isEmpty);
      }
    });
  }

  test('iOS InfoPlist.strings match English in every language', () {
    Map<String, String> load(String code) => parseIosStrings(
      File('ios/Runner/$code.lproj/InfoPlist.strings').readAsStringSync(),
    );
    final en = load('en');
    expect(en, contains('CFBundleDisplayName'));
    for (final code in languages) {
      expect(iosParityProblems('ios/$code', en, load(code)), isEmpty);
    }
  });

  group('the checks catch bad input', () {
    const englishXml = '''
<resources>
    <!-- <string name="commented_out">x</string> -->
    <string name="title">Week %1\$s</string>
    <string name="percent">%1\$d%% lived</string>
    <plurals name="left">
        <item quantity="one">%1\$s week left</item>
        <item quantity="other">%1\$s weeks left</item>
    </plurals>
</resources>''';
    final en = parseAndroidStrings(englishXml);

    test('the parser reads strings, plurals and skips comments', () {
      expect(en.strings.keys, ['title', 'percent']);
      expect(en.plurals['left']!.keys, ['one', 'other']);
      expect(formatArgs(en.strings['percent']!), [r'%1$d']);
      expect(androidParityProblems('en', en, en), isEmpty);
    });

    test(
      'Android: missing name, missing plural form, wrong argument, empty',
      () {
        final bad = parseAndroidStrings('''
<resources>
    <string name="percent">%1\$s%% vécu</string>
    <string name="extra">   </string>
    <plurals name="left">
        <item quantity="many">encore %1\$s semaines</item>
        <item quantity="other">encore semaines</item>
    </plurals>
</resources>''');
        final problems = androidParityProblems('fr', en, bad).join('\n');
        expect(problems, contains('title missing'));
        expect(problems, contains('extra not in en'));
        expect(problems, contains('no "one" item'));
        expect(problems, contains('percent: format arguments'));
        expect(problems, contains('left[other]: format arguments'));
        expect(problems, contains('extra: empty'));
      },
    );

    test('iOS: missing key, extra key, empty value', () {
      final iosEn = parseIosStrings('''
/* comment "Hidden" = "x"; */
"CFBundleDisplayName" = "Memento Mori";
"NSCameraUsageDescription" = "Take a \\"photo\\".";''');
      expect(iosEn.keys, ['CFBundleDisplayName', 'NSCameraUsageDescription']);
      final bad = parseIosStrings('''
"CFBundleDisplayName" = " ";
"Extra" = "x";''');
      final problems = iosParityProblems('ios/de', iosEn, bad).join('\n');
      expect(problems, contains('NSCameraUsageDescription missing'));
      expect(problems, contains('Extra not in en'));
      expect(problems, contains('CFBundleDisplayName: empty'));
    });
  });
}
