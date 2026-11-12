import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/support/play_store_app.dart';
import 'package:memento_mori_life_in_weeks/support/store_listing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// "Rate the app" and "Recommend to a friend"; screens get them from
/// [SupportScope] so tests can replace them.
abstract interface class StoreActions {
  /// Opens the store's review page of [listing].
  Future<void> rate(BuildContext context, StoreListing listing);

  /// Opens the system share sheet with [recommendShareText].
  Future<void> recommend(BuildContext context, StoreListing listing);
}

/// The recommendation text, plus the listing's link when it has one.
String recommendShareText(AppLocalizations l10n, StoreListing listing) {
  final text = l10n.translate('recommend_share_text');
  final link = listing.shareUri;
  return link == null ? text : '$text\n$link';
}

/// Opens a link; true when something handled it.
typedef UriOpener = Future<bool> Function(Uri uri);

/// Tries each of [reviewUris] in order until one opens; false when none
/// did. `market://` links go only to the Play Store app ([openInPlayStore],
/// no "Play Store or F-Droid?" chooser); when it is missing, the next page
/// (the Play website) is tried. Everything else goes to [openExternal].
Future<bool> openReviewPage(
  List<Uri> reviewUris, {
  UriOpener openInPlayStore = PlayStoreApp.open,
  required UriOpener openExternal,
}) async {
  for (final uri in reviewUris) {
    final opener = PlayStoreApp.handles(uri) ? openInPlayStore : openExternal;
    if (await opener(uri)) return true;
  }
  return false;
}

/// Store pages via url_launcher (Play Store app links via [PlayStoreApp]),
/// the share sheet via share_plus.
class PlatformStoreActions implements StoreActions {
  const PlatformStoreActions();

  /// Opens the first review page that works ([openReviewPage]); shows a
  /// snack bar when none opens. Calls [launchUrl] directly: `canLaunchUrl`
  /// needs `<queries>` entries on Android 11+.
  @override
  Future<void> rate(BuildContext context, StoreListing listing) async {
    final messenger = ScaffoldMessenger.of(context);
    final error = AppLocalizations.of(context).translate('settings_link_error');
    if (await openReviewPage(listing.reviewUris, openExternal: _open)) return;
    messenger.showSnackBar(SnackBar(content: Text(error)));
  }

  static Future<bool> _open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Store link $uri failed: $e');
      return false;
    }
  }

  @override
  Future<void> recommend(BuildContext context, StoreListing listing) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await SharePlus.instance.share(
        ShareParams(text: recommendShareText(l10n, listing)),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n.translate('quote_share_error', replacements: {'error': '$e'}),
          ),
        ),
      );
    }
  }
}
