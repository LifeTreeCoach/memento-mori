import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the Android Auto Backup / device transfer rules: both files must
/// back up the same data and never the plugin's list of pending
/// notifications (the alarms themselves are not restored, so a restored
/// list would make the diff scheduler skip reminders that don't exist).
const _xmlDir = 'android/app/src/main/res/xml';
const _pluginPendingList = 'scheduled_notifications.xml';

/// The file flutter_local_notifications keeps its pending list in.
const _pluginSource =
    'static final String SCHEDULED_NOTIFICATIONS = "scheduled_notifications"';

/// One `<include>`/`<exclude>` rule: element, domain and path.
typedef _Rule = ({String kind, String domain, String path});

final _rule = RegExp(r'<(include|exclude)\s+domain="([^"]+)"\s+path="([^"]+)"\s*/>');

String _withoutComments(String xml) =>
    xml.replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '');

Set<_Rule> _rulesIn(String xml) => {
      for (final m in _rule.allMatches(xml))
        (kind: m.group(1)!, domain: m.group(2)!, path: m.group(3)!),
    };

/// The body of every `<tag>...</tag>` section in [xml].
List<String> _sections(String xml, String tag) => [
      for (final m in RegExp('<$tag>(.*?)</$tag>', dotAll: true).allMatches(xml))
        m.group(1)!,
    ];

const _excludePluginList =
    (kind: 'exclude', domain: 'sharedpref', path: _pluginPendingList);

void main() {
  final fullBackup =
      _withoutComments(File('$_xmlDir/backup_rules.xml').readAsStringSync());
  final extraction = _withoutComments(
      File('$_xmlDir/data_extraction_rules.xml').readAsStringSync());

  final legacyRules = _rulesIn(fullBackup);
  final cloudRules = _rulesIn(_sections(extraction, 'cloud-backup').single);
  final transferRules = _rulesIn(_sections(extraction, 'device-transfer').single);

  test('backup_rules.xml excludes the plugin\'s pending list', () {
    expect(legacyRules, contains(_excludePluginList));
  });

  test('cloud backup and device transfer exclude the plugin\'s pending list', () {
    expect(cloudRules, contains(_excludePluginList));
    expect(transferRules, contains(_excludePluginList));
  });

  test('both files back up the same data', () {
    expect(cloudRules, legacyRules);
    expect(transferRules, legacyRules);
  });

  test('the excluded file is the one the plugin writes', () {
    final config = File('.dart_tool/package_config.json');
    final match = RegExp(r'"rootUri":\s*"([^"]*flutter_local_notifications-[\d.]+)"')
        .firstMatch(config.readAsStringSync());
    if (match == null) return markTestSkipped('plugin not resolved');
    final root = match.group(1)!.replaceFirst('file://', '');
    final source = File('$root/android/src/main/java/com/dexterous/'
        'flutterlocalnotifications/FlutterLocalNotificationsPlugin.java');
    if (!source.existsSync()) return markTestSkipped('no plugin source at $root');
    expect(source.readAsStringSync(), contains(_pluginSource));
  });
}
