import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards what other apps can reach in `:app`: the launcher activity and the
/// widget receiver are the only exported components of our own, the launcher
/// takes no deep links, and the release manifest stays free of debug and
/// cleartext switches. When a merged release manifest has been built
/// (`./gradlew :app:processFossReleaseManifest`, `flutter build apk`), the
/// exported components that libraries add are pinned too, each behind the
/// system permission that guards it.
const _mainManifest = 'android/app/src/main/AndroidManifest.xml';

const _package = 'lifetree.coach.memento_mori_life_in_weeks';

/// Our own exported components (short names as in the main manifest).
const _ownExported = {'.MainActivity', '.widget.LifeWidgetReceiver'};

/// Every exported component of a merged release manifest and the permission
/// a caller needs (null = none). Libraries: Glance (RemoteViews service,
/// bound only by the system), WorkManager (job service, diagnostics) and
/// profileinstaller (DUMP is signature|privileged: adb/system only).
const _mergedExported = <String, String?>{
  '$_package.MainActivity': null,
  '$_package.widget.LifeWidgetReceiver': null,
  'androidx.glance.appwidget.GlanceRemoteViewsService':
      'android.permission.BIND_REMOTEVIEWS',
  'androidx.work.impl.background.systemjob.SystemJobService':
      'android.permission.BIND_JOB_SERVICE',
  'androidx.work.impl.diagnostics.DiagnosticsReceiver':
      'android.permission.DUMP',
  'androidx.profileinstaller.ProfileInstallReceiver': 'android.permission.DUMP',
};

const _mergedReleaseManifests = [
  'build/app/intermediates/merged_manifests/fossRelease/'
      'processFossReleaseManifest/AndroidManifest.xml',
  'build/app/intermediates/merged_manifests/playRelease/'
      'processPlayReleaseManifest/AndroidManifest.xml',
];

/// One `<activity|activity-alias|receiver|service|provider>` element.
typedef _Component = ({String tag, Map<String, String> attributes, String body});

final _componentTag = RegExp(
  r'<(activity-alias|activity|receiver|service|provider)\b([^>]*?)(/>|>)',
  dotAll: true,
);
final _attribute = RegExp(r'([\w:]+)\s*=\s*"([^"]*)"');

String _withoutComments(String xml) =>
    xml.replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '');

Map<String, String> _attributes(String text) => {
      for (final m in _attribute.allMatches(text)) m.group(1)!: m.group(2)!,
    };

List<_Component> _componentsIn(String xml) {
  final source = _withoutComments(xml);
  return [
    for (final m in _componentTag.allMatches(source))
      (
        tag: m.group(1)!,
        attributes: _attributes(m.group(2)!),
        body: m.group(3) == '/>' ? '' : _bodyAfter(source, m.end, m.group(1)!),
      ),
  ];
}

String _bodyAfter(String xml, int start, String tag) {
  final end = xml.indexOf('</$tag>', start);
  return end < 0 ? '' : xml.substring(start, end);
}

/// Exported per Android's rule: explicit attribute, else true only with an
/// intent filter (providers default to false since API 17).
bool _isExported(_Component c) {
  final explicit = c.attributes['android:exported'];
  if (explicit != null) return explicit == 'true';
  return c.tag != 'provider' && c.body.contains('<intent-filter');
}

Set<String> _actionsIn(String body) => {
      for (final m in RegExp(r'<action\b[^>]*android:name="([^"]+)"')
          .allMatches(body))
        m.group(1)!,
    };

void main() {
  final manifest = File(_mainManifest).readAsStringSync();
  final components = _componentsIn(manifest);
  _Component named(String name) =>
      components.singleWhere((c) => c.attributes['android:name'] == name);

  group('main AndroidManifest.xml', () {
    test('every component states android:exported', () {
      for (final c in components) {
        expect(c.attributes, contains('android:exported'),
            reason: c.attributes['android:name']);
      }
    });

    test('only the launcher and the widget receiver are exported', () {
      final exported = {
        for (final c in components)
          if (_isExported(c)) c.attributes['android:name'],
      };
      expect(exported, _ownExported);
    });

    test('the launcher takes no deep links', () {
      final activity = named('.MainActivity');
      expect(_actionsIn(activity.body), {'android.intent.action.MAIN'});
      expect(activity.body, isNot(contains('<data')));
      expect(activity.body, isNot(contains('BROWSABLE')));
      expect(activity.body, contains('android:name="flutter_deeplinking_enabled"'));
      expect(
        RegExp(r'flutter_deeplinking_enabled"\s*android:value="false"')
            .hasMatch(activity.body),
        isTrue,
      );
    });

    test('the widget receiver only takes widget updates', () {
      expect(
        _actionsIn(named('.widget.LifeWidgetReceiver').body),
        {'android.appwidget.action.APPWIDGET_UPDATE'},
      );
    });

    test('no debuggable, cleartext or network security switches', () {
      final source = _withoutComments(manifest);
      expect(source, isNot(contains('android:debuggable')));
      expect(source, isNot(contains('android:usesCleartextTraffic')));
      expect(source, isNot(contains('android:networkSecurityConfig')));
    });
  });

  group('merged release manifest', () {
    for (final path in _mergedReleaseManifests) {
      final file = File(path);
      final flavor = path.contains('foss') ? 'foss' : 'play';

      test('$flavor exports only the pinned components', () {
        if (!file.existsSync()) {
          return markTestSkipped('not built: $path');
        }
        final merged = _componentsIn(file.readAsStringSync());
        final exported = {
          for (final c in merged)
            if (_isExported(c))
              c.attributes['android:name']!:
                  c.attributes['android:permission'],
        };
        expect(exported, _mergedExported);
      });

      test('$flavor exports no content provider', () {
        if (!file.existsSync()) {
          return markTestSkipped('not built: $path');
        }
        final providers = _componentsIn(file.readAsStringSync())
            .where((c) => c.tag == 'provider');
        for (final p in providers) {
          expect(p.attributes['android:exported'], 'false',
              reason: p.attributes['android:name']);
        }
      });
    }
  });
}
