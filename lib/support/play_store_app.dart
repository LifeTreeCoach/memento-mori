import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Opens `market://` links in the Google Play Store app only.
///
/// A plain `market://` intent also matches other stores (F-Droid, ...),
/// so Android would show a chooser. The intent is restricted to
/// `com.android.vending` in android/.../MainActivity.kt; that is just an
/// intent, not a Play Services dependency.
class PlayStoreApp {
  const PlayStoreApp._();

  /// Implemented in android/.../MainActivity.kt.
  static const MethodChannel channel = MethodChannel('memento/app_settings');

  static const String openListingMethod = 'openPlayStoreListing';

  /// Whether [uri] is a Play Store app link (`market://`).
  static bool handles(Uri uri) => uri.scheme == 'market';

  /// Opens [uri] in the Play Store app. False when the Play Store is not
  /// installed, the platform has no handler (iOS, tests) or the call fails.
  static Future<bool> open(Uri uri) async {
    try {
      final opened = await channel.invokeMethod<bool>(openListingMethod, {
        'uri': uri.toString(),
      });
      return opened ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (e) {
      debugPrint('Play Store link $uri failed: $e');
      return false;
    }
  }
}
