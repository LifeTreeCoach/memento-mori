import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/support/play_store_app.dart';
import 'package:memento_mori_life_in_weeks/support/store_actions.dart';
import 'package:memento_mori_life_in_weeks/support/store_listing.dart';

final List<Uri> _playReviewUris = StoreListing.resolve(
  flavor: 'play',
  platform: TargetPlatform.android,
).reviewUris;

final Uri _market = Uri.parse(
  'market://details?id=${StoreListing.androidPackage}',
);

/// Answers `openPlayStoreListing` on the `memento/app_settings` channel.
List<MethodCall> _mockPlayStore(Object? Function(MethodCall call) answer) {
  final calls = <MethodCall>[];
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(PlayStoreApp.channel, (call) async {
        calls.add(call);
        return answer(call);
      });
  addTearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(PlayStoreApp.channel, null),
  );
  return calls;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlayStoreApp.open', () {
    test('asks the Play Store app to open the market link', () async {
      final calls = _mockPlayStore((_) => true);
      expect(await PlayStoreApp.open(_market), isTrue);
      expect(calls.single.method, 'openPlayStoreListing');
      expect(calls.single.arguments, {'uri': _market.toString()});
    });

    test('false when the Play Store is not installed', () async {
      _mockPlayStore((_) => false);
      expect(await PlayStoreApp.open(_market), isFalse);
    });

    test('false when the platform fails or has no handler', () async {
      _mockPlayStore((_) => throw PlatformException(code: 'boom'));
      expect(await PlayStoreApp.open(_market), isFalse);
      _mockPlayStore((_) => throw MissingPluginException());
      expect(await PlayStoreApp.open(_market), isFalse);
    });

    test('handles only market:// links', () {
      expect(PlayStoreApp.handles(_market), isTrue);
      expect(PlayStoreApp.handles(StoreListing.playStoreUri), isFalse);
    });
  });

  group('openReviewPage (play flavor)', () {
    test('the Play Store app opens: no browser, no chooser', () async {
      final calls = _mockPlayStore((_) => true);
      final external = <Uri>[];
      final opened = await openReviewPage(
        _playReviewUris,
        openExternal: (uri) async {
          external.add(uri);
          return true;
        },
      );
      expect(opened, isTrue);
      expect(calls, hasLength(1));
      expect(external, isEmpty);
    });

    test('no Play Store app: falls back to the Play website', () async {
      _mockPlayStore((_) => false);
      final external = <Uri>[];
      final opened = await openReviewPage(
        _playReviewUris,
        openExternal: (uri) async {
          external.add(uri);
          return true;
        },
      );
      expect(opened, isTrue);
      // market:// is never handed to url_launcher (it would show a chooser).
      expect(external, [StoreListing.playStoreUri]);
    });

    test('no channel at all (e.g. iOS): falls back to the website', () async {
      final external = <Uri>[];
      final opened = await openReviewPage(
        _playReviewUris,
        openExternal: (uri) async {
          external.add(uri);
          return true;
        },
      );
      expect(opened, isTrue);
      expect(external, [StoreListing.playStoreUri]);
    });

    test('false when nothing opens', () async {
      _mockPlayStore((_) => false);
      final opened = await openReviewPage(
        _playReviewUris,
        openExternal: (_) async => false,
      );
      expect(opened, isFalse);
    });

    test('other links go straight to the external opener', () async {
      final calls = _mockPlayStore((_) => true);
      final appStore = Uri.parse('https://apps.apple.com/app/id1');
      final external = <Uri>[];
      await openReviewPage(
        [appStore],
        openExternal: (uri) async {
          external.add(uri);
          return true;
        },
      );
      expect(calls, isEmpty);
      expect(external, [appStore]);
    });
  });

  test('German Life cards both call Memento Mori "es"', () {
    final de = AppLocalizations.valuesFor('de');
    for (final key in ['support_card_body', 'recommend_card_body']) {
      expect(de[key], startsWith('Wenn es dir gefällt,'), reason: key);
    }
  });
}
