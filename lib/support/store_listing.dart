import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:memento_mori_life_in_weeks/support/project_links.dart';
import 'package:memento_mori_life_in_weeks/support/support_channel.dart';

/// Where this build can be rated and which link a recommendation shares.
///
/// Plain store URLs opened with url_launcher: no in-app review or Play Core
/// libraries, so no Google dependency is added.
@immutable
class StoreListing {
  const StoreListing({this.reviewUris = const [], this.shareUri});

  /// No store to rate in and no link to share.
  static const StoreListing none = StoreListing();

  /// The Android application id (Google Play listing).
  static const String androidPackage =
      'lifetree.coach.memento_mori_life_in_weeks';

  /// The numeric App Store id; null until the app is published there, and
  /// "Rate" stays hidden on iOS until then.
  static const String? appStoreId = null;

  /// The project homepage shared by builds outside the stores.
  static const String projectHomepage = ProjectLinks.repository;

  /// Review pages, tried in order until one opens (e.g. the Play Store app,
  /// then the Play website). Empty = "Rate" is hidden.
  final List<Uri> reviewUris;

  /// The link added to a recommendation; null = text only.
  final Uri? shareUri;

  bool get canRate => reviewUris.isNotEmpty;

  /// The listing of this build ([resolve] with the environment).
  static StoreListing fromEnvironment() =>
      resolve(flavor: appFlavor, platform: defaultTargetPlatform);

  /// Android `play` flavor: Google Play. iOS: the App Store once
  /// [storeId] is set. Everything else: no store, [homepage] as the link.
  static StoreListing resolve({
    String? flavor,
    required TargetPlatform platform,
    String? storeId = appStoreId,
    String? homepage = projectHomepage,
  }) {
    if (platform == TargetPlatform.android &&
        flavor == SupportChannel.playFlavor) {
      return StoreListing(
        reviewUris: [
          Uri.parse('market://details?id=$androidPackage'),
          playStoreUri,
        ],
        shareUri: playStoreUri,
      );
    }
    if (platform == TargetPlatform.iOS) {
      if (storeId == null) return none;
      final app = Uri.parse('https://apps.apple.com/app/id$storeId');
      return StoreListing(
        reviewUris: [
          app.replace(queryParameters: {'action': 'write-review'}),
        ],
        shareUri: app,
      );
    }
    return StoreListing(
      shareUri: homepage == null ? null : Uri.parse(homepage),
    );
  }

  static final Uri playStoreUri = Uri.parse(
    'https://play.google.com/store/apps/details?id=$androidPackage',
  );

  @override
  bool operator ==(Object other) =>
      other is StoreListing &&
      listEquals(other.reviewUris, reviewUris) &&
      other.shareUri == shareUri;

  @override
  int get hashCode => Object.hash(Object.hashAll(reviewUris), shareUri);

  @override
  String toString() =>
      'StoreListing(reviewUris: $reviewUris, shareUri: $shareUri)';
}
