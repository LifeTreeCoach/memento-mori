import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the Android permissions: the release app must ask for exactly
/// these, and never for INTERNET (only the debug/profile manifests add it,
/// for the Flutter tooling).
const _appSrc = 'android/app/src';
const _mainManifest = '$_appSrc/main/AndroidManifest.xml';

/// Flavor manifests merged into release builds.
const _flavorManifests = [
  '$_appSrc/foss/AndroidManifest.xml',
  '$_appSrc/play/AndroidManifest.xml',
];

const _allowedPermissions = {
  'android.permission.POST_NOTIFICATIONS',
  'android.permission.READ_CALENDAR',
  'android.permission.WRITE_CALENDAR',
  'android.permission.RECEIVE_BOOT_COMPLETED',
  'android.permission.READ_CONTACTS',
};

/// Declared by libraries and stripped again with `tools:node="remove"`.
const _removedPermissions = {'android.permission.FOREGROUND_SERVICE'};

const _internet = 'android.permission.INTERNET';

final _usesPermission = RegExp(
  r'<uses-permission\b([^>]*)/?>',
  multiLine: true,
);
final _name = RegExp(r'android:name="([^"]+)"');
final _removeNode = RegExp(r'tools:node="remove"');

/// A `<uses-permission>` entry: its name and whether it removes the entry.
typedef _Permission = ({String name, bool removed});

List<_Permission> _permissionsIn(String xml) {
  final withoutComments = xml.replaceAll(
    RegExp(r'<!--.*?-->', dotAll: true),
    '',
  );
  return [
    for (final match in _usesPermission.allMatches(withoutComments))
      (
        name: _name.firstMatch(match.group(1)!)!.group(1)!,
        removed: _removeNode.hasMatch(match.group(1)!),
      ),
  ];
}

int? _targetSdkIn(String gradle) {
  final match = RegExp(
    r'targetSdk(?:Version)?\s*=?\s*(?:Math\.max\([^,]+,\s*)?(\d+)',
  ).firstMatch(gradle);
  return match == null ? null : int.parse(match.group(1)!);
}

void main() {
  group('main AndroidManifest.xml', () {
    final permissions = _permissionsIn(File(_mainManifest).readAsStringSync());

    test('requests exactly the allowed permissions', () {
      final requested = {
        for (final p in permissions)
          if (!p.removed) p.name,
      };
      expect(requested, _allowedPermissions);
    });

    test('only strips the expected library permissions', () {
      final removed = {
        for (final p in permissions)
          if (p.removed) p.name,
      };
      expect(removed, _removedPermissions);
    });

    test('never asks for INTERNET', () {
      expect(permissions.map((p) => p.name), isNot(contains(_internet)));
      // Not even as <uses-permission-sdk-23> or in another element.
      expect(
        File(_mainManifest).readAsStringSync(),
        isNot(contains(_internet)),
      );
    });
  });

  test('flavor manifests add no permissions', () {
    for (final path in _flavorManifests) {
      final file = File(path);
      if (!file.existsSync()) continue;
      final added = _permissionsIn(file.readAsStringSync())
          .where((p) => !p.removed);
      expect(added, isEmpty, reason: path);
    }
  });

  group('targetSdk', () {
    for (final path in [
      'android/app/build.gradle',
      'android/wear/build.gradle',
    ]) {
      test('$path targets API 37 or newer', () {
        final targetSdk = _targetSdkIn(File(path).readAsStringSync());
        expect(targetSdk, isNotNull, reason: 'no targetSdk found');
        expect(targetSdk, greaterThanOrEqualTo(37));
      });
    }
  });
}
