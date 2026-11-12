import 'package:flutter/widgets.dart';
import 'package:memento_mori_life_in_weeks/support/store_actions.dart';
import 'package:memento_mori_life_in_weeks/support/store_listing.dart';
import 'package:memento_mori_life_in_weeks/support/support_channel.dart';

/// Everything the support spots (Settings, onboarding, Life-tab card) need
/// to know about this build: the [channel], the store [listing] and the
/// [actions] that rate or recommend.
@immutable
class SupportSetup {
  const SupportSetup({
    required this.channel,
    this.listing = StoreListing.none,
    this.actions = const PlatformStoreActions(),
  });

  /// This build's setup (flavor, platform, `--dart-define`s).
  factory SupportSetup.fromEnvironment() => SupportSetup(
    channel: SupportChannel.fromEnvironment(),
    listing: StoreListing.fromEnvironment(),
  );

  final SupportChannel channel;
  final StoreListing listing;
  final StoreActions actions;

  bool get showsLink => channel == SupportChannel.link;
}

/// Provides the [SupportSetup] to everything below the app root, so the
/// support spots don't read the build environment themselves.
class SupportScope extends InheritedWidget {
  const SupportScope({super.key, required this.setup, required super.child});

  final SupportSetup setup;

  /// The nearest setup; without a scope, this build's own
  /// ([SupportSetup.fromEnvironment]), so a Play build never falls back to
  /// the link.
  static SupportSetup of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SupportScope>()?.setup ??
      _environment;

  static final SupportSetup _environment = SupportSetup.fromEnvironment();

  @override
  bool updateShouldNotify(SupportScope oldWidget) => setup != oldWidget.setup;
}
