import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the Android Auto Backup / device transfer rules: both files must
/// back up the same data and never the plugin's list of pending
/// notifications (the alarms themselves are not restored, so a restored
/// list would make the diff scheduler skip reminders that don't exist),
/// flutter_secure_storage's files (bound to this device's Keystore; the data
/// key travels only through VaultBackupAgent), the plaintext widget inputs or
/// the watch sync state. On API 28-30 (no cloud-only switch) every include
/// requires an end-to-end encrypted transport or a device-to-device transfer.
const _xmlDir = 'android/app/src/main/res/xml';
const _pluginPendingList = 'scheduled_notifications.xml';

/// shared_prefs files that must never be backed up.
const _excludedPrefs = [
  _pluginPendingList,
  'FlutterSecureStorage.xml',
  'FlutterSecureKeyStorage.xml',
  'FlutterSecureStorageConfiguration.xml',
  'FlutterSecureStorageConfiguration:FlutterSecureStorage.xml',
  'HomeWidgetPreferences.xml',
  'WearSyncState.xml',
];

/// The file flutter_local_notifications keeps its pending list in.
const _pluginSource =
    'static final String SCHEDULED_NOTIFICATIONS = "scheduled_notifications"';

/// One `<include>`/`<exclude>` rule: element, domain and path.
typedef _Rule = ({String kind, String domain, String path});

/// An `<include>`/`<exclude>` element with any attributes in any order.
final _rule = RegExp(r'<(include|exclude)\b([^>]*?)/?>');
final _attribute = RegExp(r'([\w:]+)\s*=\s*"([^"]*)"');

String _withoutComments(String xml) =>
    xml.replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '');

Map<String, String> _attributes(String text) => {
      for (final m in _attribute.allMatches(text)) m.group(1)!: m.group(2)!,
    };

Set<_Rule> _rulesIn(String xml) => {
      for (final m in _rule.allMatches(xml))
        if (_attributes(m.group(2)!) case {'domain': final d, 'path': final p})
          (kind: m.group(1)!, domain: d, path: p),
    };

/// Every `<tag ...>...</tag>` section in [xml]: its attributes and body.
List<({Map<String, String> attributes, String body})> _sections(
  String xml,
  String tag,
) => [
      for (final m in RegExp('<$tag\\b([^>]*)>(.*?)</$tag>', dotAll: true)
          .allMatches(xml))
        (attributes: _attributes(m.group(1)!), body: m.group(2)!),
    ];

/// The attributes of every `<include>` in [xml].
List<Map<String, String>> _includeAttributes(String xml) => [
      for (final m in _rule.allMatches(xml))
        if (m.group(1) == 'include') _attributes(m.group(2)!),
    ];

/// The two flags under which the legacy rules (API 28-30) back anything up:
/// the same cases in which VaultBackupAgent adds the data key.
const _legacyFlags = {'clientSideEncryption', 'deviceToDeviceTransfer'};

_Rule _exclude(String file) =>
    (kind: 'exclude', domain: 'sharedpref', path: file);

/// The root folder of a resolved package, or null.
String? _packageRoot(String name) {
  final config = File('.dart_tool/package_config.json');
  final match = RegExp('"rootUri":\\s*"([^"]*$name-[\\d.]+)"')
      .firstMatch(config.readAsStringSync());
  return match?.group(1)!.replaceFirst('file://', '');
}

const _excludePluginList =
    (kind: 'exclude', domain: 'sharedpref', path: _pluginPendingList);

void main() {
  final fullBackup =
      _withoutComments(File('$_xmlDir/backup_rules.xml').readAsStringSync());
  final extraction = _withoutComments(
      File('$_xmlDir/data_extraction_rules.xml').readAsStringSync());

  final legacyRules = _rulesIn(fullBackup);
  final cloud = _sections(extraction, 'cloud-backup').single;
  final cloudRules = _rulesIn(cloud.body);
  final transferRules =
      _rulesIn(_sections(extraction, 'device-transfer').single.body);

  test('backup_rules.xml excludes the plugin\'s pending list', () {
    expect(legacyRules, contains(_excludePluginList));
  });

  test('cloud backup and device transfer exclude the plugin\'s pending list', () {
    expect(cloudRules, contains(_excludePluginList));
    expect(transferRules, contains(_excludePluginList));
  });

  test('every file holds the vault data and avatars', () {
    const vault = (kind: 'include', domain: 'root', path: 'app_flutter/');
    expect(legacyRules, contains(vault));
    expect(cloudRules, contains(vault));
    expect(transferRules, contains(vault));
  });

  test('every file includes the data key staging folder, and only it', () {
    // VaultBackupAgent stages the key at files/vault_transfer/dek during an
    // encrypted backup; AOSP skips restoring files outside the includes.
    const staging = (kind: 'include', domain: 'file', path: 'vault_transfer/');
    for (final rules in [legacyRules, cloudRules, transferRules]) {
      expect(rules, contains(staging));
      expect(
        rules.where((r) => r.kind == 'include' && r.domain == 'file'),
        [staging],
      );
    }
  });

  test('the staging folder is the one VaultBackupAgent uses', () {
    final source = File('android/app/src/main/kotlin/lifetree/coach/'
            'memento_mori_life_in_weeks/backup/VaultTransferStaging.kt')
        .readAsStringSync();
    expect(source, contains('DIRECTORY = "vault_transfer"'));
  });

  test('device-bound, plaintext and sync-state files are excluded', () {
    for (final file in _excludedPrefs) {
      expect(legacyRules, contains(_exclude(file)), reason: file);
      expect(cloudRules, contains(_exclude(file)), reason: file);
      expect(transferRules, contains(_exclude(file)), reason: file);
    }
  });

  test('cloud backup needs an end-to-end encrypted transport', () {
    expect(cloud.attributes['disableIfNoEncryptionCapabilities'], 'true');
  });

  test('API 28-30 back up only end-to-end encrypted or device-to-device', () {
    final includes = _includeAttributes(fullBackup);
    expect(includes, isNotEmpty);
    // Flags of one include are ANDed by the platform, so each include names
    // exactly one flag and every path is included once per flag.
    for (final include in includes) {
      expect(_legacyFlags, contains(include['requireFlags']),
          reason: '${include['path']} needs exactly one known flag');
    }
    final paths = {for (final i in includes) (i['domain'], i['path'])};
    for (final (domain, path) in paths) {
      final flags = {
        for (final i in includes)
          if (i['domain'] == domain && i['path'] == path) i['requireFlags'],
      };
      expect(flags, _legacyFlags, reason: '$domain $path');
    }
  });

  test('requireFlags appears only on includes', () {
    final excludes = RegExp(r'<exclude\b[^>]*>').allMatches(fullBackup);
    for (final m in excludes) {
      expect(m.group(0), isNot(contains('requireFlags')));
    }
  });

  test('both files back up the same data', () {
    expect(cloudRules, legacyRules);
    expect(transferRules, legacyRules);
  });

  test('the excluded file is the one the plugin writes', () {
    final root = _packageRoot('flutter_local_notifications');
    if (root == null) return markTestSkipped('plugin not resolved');
    final source = File('$root/android/src/main/java/com/dexterous/'
        'flutterlocalnotifications/FlutterLocalNotificationsPlugin.java');
    if (!source.existsSync()) return markTestSkipped('no plugin source at $root');
    expect(source.readAsStringSync(), contains(_pluginSource));
  });

  test('the excluded secure storage files are the ones the plugin writes', () {
    final root = _packageRoot('flutter_secure_storage');
    if (root == null) return markTestSkipped('plugin not resolved');
    final dir = '$root/android/src/main/java/com/it_nomads/fluttersecurestorage';
    if (!Directory(dir).existsSync()) {
      return markTestSkipped('no plugin source at $root');
    }
    final config = File('$dir/FlutterSecureStorageConfig.java').readAsStringSync();
    final source = File('$dir/NamespacedConfigSource.java').readAsStringSync();
    expect(config, contains('DEFAULT_PREF_NAME = "FlutterSecureStorage"'));
    expect(config, contains(': "FlutterSecureKeyStorage"'));
    expect(source, contains('CONFIG_NAME = "FlutterSecureStorageConfiguration"'));
    expect(source, contains('"FlutterSecureStorageConfiguration:" + sharedPreferencesName'));
  });

  test('the excluded widget prefs are the ones home_widget writes', () {
    final root = _packageRoot('home_widget');
    if (root == null) return markTestSkipped('plugin not resolved');
    final source = File('$root/android/src/main/kotlin/es/antonborri/'
        'home_widget/HomeWidgetPlugin.kt');
    if (!source.existsSync()) return markTestSkipped('no plugin source at $root');
    expect(source.readAsStringSync(), contains('PREFERENCES = "HomeWidgetPreferences"'));
  });
}
