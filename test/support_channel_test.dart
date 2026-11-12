import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/support/project_links.dart';
import 'package:memento_mori_life_in_weeks/support/store_actions.dart';
import 'package:memento_mori_life_in_weeks/support/store_listing.dart';
import 'package:memento_mori_life_in_weeks/support/support_channel.dart';

import 'support/money_words.dart';

const _android = TargetPlatform.android;
const _iOS = TargetPlatform.iOS;

void main() {
  group('SupportChannel.resolve', () {
    test('Android: play rates, foss and no flavor keep the link', () {
      expect(
        SupportChannel.resolve(flavor: 'play', platform: _android),
        SupportChannel.rate,
      );
      expect(
        SupportChannel.resolve(flavor: 'foss', platform: _android),
        SupportChannel.link,
      );
      expect(SupportChannel.resolve(platform: _android), SupportChannel.link);
      expect(
        SupportChannel.resolve(flavor: 'other', platform: _android),
        SupportChannel.link,
      );
    });

    test('iOS always rates (App Store), whatever the flavor', () {
      expect(SupportChannel.resolve(platform: _iOS), SupportChannel.rate);
      expect(
        SupportChannel.resolve(flavor: 'foss', platform: _iOS),
        SupportChannel.rate,
      );
    });

    test('other platforms keep the link', () {
      expect(
        SupportChannel.resolve(platform: TargetPlatform.macOS),
        SupportChannel.link,
      );
    });

    test('a valid --dart-define override wins, an invalid one is ignored', () {
      expect(
        SupportChannel.resolve(
          override: 'link',
          flavor: 'play',
          platform: _android,
        ),
        SupportChannel.link,
      );
      expect(
        SupportChannel.resolve(override: ' Link ', platform: _iOS),
        SupportChannel.link,
      );
      expect(
        SupportChannel.resolve(
          override: 'rate',
          flavor: 'foss',
          platform: _android,
        ),
        SupportChannel.rate,
      );
      expect(
        SupportChannel.resolve(
          override: 'coffee',
          flavor: 'play',
          platform: _android,
        ),
        SupportChannel.rate,
      );
    });

    test('the test environment (no flavor, no define) keeps the link', () {
      expect(SupportChannel.fromEnvironment(), SupportChannel.link);
    });
  });

  group('StoreListing.resolve', () {
    test('play: the Play Store app first, then the Play website', () {
      final listing = StoreListing.resolve(flavor: 'play', platform: _android);
      const web =
          'https://play.google.com/store/apps/details'
          '?id=lifetree.coach.memento_mori_life_in_weeks';
      expect(listing.canRate, isTrue);
      expect(listing.reviewUris.map((u) => '$u'), [
        'market://details?id=lifetree.coach.memento_mori_life_in_weeks',
        web,
      ]);
      expect('${listing.shareUri}', web);
    });

    test('foss: nothing to rate, the homepage (if any) to share', () {
      final foss = StoreListing.resolve(flavor: 'foss', platform: _android);
      expect(foss.canRate, isFalse);
      expect('${foss.shareUri}', ProjectLinks.repository);
      expect(
        StoreListing.resolve(
          flavor: 'foss',
          platform: _android,
          homepage: null,
        ),
        StoreListing.none,
      );
      final withHomepage = StoreListing.resolve(
        flavor: 'foss',
        platform: _android,
        homepage: 'https://example.org/memento',
      );
      expect(withHomepage.canRate, isFalse);
      expect('${withHomepage.shareUri}', 'https://example.org/memento');
    });

    test('iOS: hidden until the App Store id is set', () {
      expect(StoreListing.appStoreId, isNull);
      expect(StoreListing.resolve(platform: _iOS), StoreListing.none);
      final listing = StoreListing.resolve(platform: _iOS, storeId: '123');
      expect(listing.reviewUris.map((u) => '$u'), [
        'https://apps.apple.com/app/id123?action=write-review',
      ]);
      expect('${listing.shareUri}', 'https://apps.apple.com/app/id123');
    });
  });

  group('recommendShareText', () {
    test('adds the store link on its own line when there is one', () {
      final l10n = AppLocalizations(const Locale('en'));
      final play = StoreListing.resolve(flavor: 'play', platform: _android);
      expect(
        recommendShareText(l10n, play),
        'I use Memento Mori to see my life in weeks. No ads, no tracking. '
        'Maybe it’s something for you too.\n${StoreListing.playStoreUri}',
      );
      expect(
        recommendShareText(l10n, StoreListing.none),
        l10n.translate('recommend_share_text'),
      );
    });

    for (final lang in AppLocalizations.supportedLanguages) {
      test('is translated and money-free in $lang', () {
        final text = recommendShareText(
          AppLocalizations(Locale(lang)),
          StoreListing.none,
        );
        expect(text, isNot(contains('recommend_')));
        expect(text, isNot(matches(moneyWords)));
      });
    }
  });
}
