import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// How the app asks for support, by where it is distributed.
///
/// - [link]: the Buy Me a Coffee link (F-Droid, direct APK, other stores).
/// - [rate]: "rate + recommend" only, no payment wording at all. Google Play
///   and the App Store forbid links to outside payments
///   (CLAUDE.md, "Support Prompt").
enum SupportChannel {
  link,
  rate;

  /// The `--dart-define=SUPPORT_CHANNEL=link|rate` override ('' if unset).
  static const String overrideFromEnvironment = String.fromEnvironment(
    'SUPPORT_CHANNEL',
  );

  /// The Android build flavor that ships through Google Play.
  static const String playFlavor = 'play';

  /// The channel of this build: [overrideFromEnvironment], else the
  /// Android flavor ([appFlavor]) and platform ([resolve]).
  static SupportChannel fromEnvironment() => resolve(
    override: overrideFromEnvironment,
    flavor: appFlavor,
    platform: defaultTargetPlatform,
  );

  /// A valid [override] wins. Otherwise iOS is always [rate] (App Store),
  /// Android is [rate] only in the [playFlavor]; every other build
  /// (`foss`, no flavor, other platforms) keeps the [link].
  static SupportChannel resolve({
    String override = '',
    String? flavor,
    required TargetPlatform platform,
  }) {
    for (final channel in values) {
      if (channel.name == override.trim().toLowerCase()) return channel;
    }
    if (platform == TargetPlatform.iOS) return rate;
    if (platform == TargetPlatform.android && flavor == playFlavor) {
      return rate;
    }
    return link;
  }
}
