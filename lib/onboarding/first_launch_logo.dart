import 'dart:async';

import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:memento_mori_life_in_weeks/theme/app_color_schemes.dart';
import 'package:memento_mori_life_in_weeks/theme/motion.dart';

/// The Memento Mori badge, shown once on the very first launch before the
/// onboarding: fade in, hold, fade out, then [next] replaces it.
///
/// The native launch screen is the plain surface colour (paper light, ink
/// dark, following the system like the native splash), so this screen uses
/// the same colour and the badge appears on it without a seam. A tap
/// anywhere skips it. With reduced motion the badge is shown without fades
/// for the same time.
class FirstLaunchLogo extends StatefulWidget {
  const FirstLaunchLogo({
    super.key,
    required this.next,
    this.duration = Motion.firstLaunchLogo,
  });

  /// Badge asset (the master logo, transparent outside the circle).
  static const String asset = 'branding/exports/logo/logo-512.png';

  /// Diameter of the badge.
  static const double size = 176;

  /// Share of [duration] for each fade (in and out); the rest is the hold.
  static const double fadeShare = 0.3;

  /// Whether to show the logo: only before the first onboarding and only
  /// once. People who onboarded before the logo existed never see it.
  static bool shouldShow({required bool onboarded, required bool shown}) =>
      !onboarded && !shown;

  /// Decides at app start whether the logo shows and marks it as shown
  /// right away: it is shown now, or never (already onboarded).
  static bool claimFirstLaunch() {
    final shown = SettingsService.hasShownIntroLogo();
    if (!shown) unawaited(SettingsService.setIntroLogoShown());
    return shouldShow(
      onboarded: SettingsService.hasCompletedOnboarding(),
      shown: shown,
    );
  }

  /// The screen shown after the logo (the onboarding).
  final WidgetBuilder next;

  /// Total time on screen (fade in + hold + fade out).
  final Duration duration;

  /// The launch screen colour for [platformBrightness].
  static Color backgroundFor(Brightness platformBrightness) =>
      platformBrightness == Brightness.dark
          ? AppColorSchemes.ink
          : AppColorSchemes.paper;

  @override
  State<FirstLaunchLogo> createState() => _FirstLaunchLogoState();
}

class _FirstLaunchLogoState extends State<FirstLaunchLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration)
        ..addStatusListener(_onStatus);
  late final Animation<double> _opacity = _controller.drive(_fadeInHoldOut());
  Timer? _holdTimer;
  bool _animated = true;
  bool _started = false;
  bool _done = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _animated = Motion.enabled(context);
    if (_animated) {
      _controller.forward();
    } else {
      _holdTimer = Timer(widget.duration, _finish);
    }
  }

  TweenSequence<double> _fadeInHoldOut() {
    const fade = FirstLaunchLogo.fadeShare * 100;
    const hold = 100 - 2 * fade;
    return TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Motion.standard)),
        weight: fade,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: hold),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: fade,
      ),
    ]);
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _finish();
  }

  void _finish() {
    if (_done || !mounted) return;
    _done = true;
    _holdTimer?.cancel();
    final fade = Motion.of(context, Motion.short);
    Navigator.of(context).pushReplacement(PageRouteBuilder<void>(
      transitionDuration: fade,
      pageBuilder: (context, _, _) => widget.next(context),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ));
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final background =
        FirstLaunchLogo.backgroundFor(MediaQuery.platformBrightnessOf(context));
    final badge = Image.asset(
      FirstLaunchLogo.asset,
      width: FirstLaunchLogo.size,
      height: FirstLaunchLogo.size,
      filterQuality: FilterQuality.medium,
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _finish,
      child: ColoredBox(
        color: background,
        child: Center(
          child: Semantics(
            label: 'Memento Mori',
            image: true,
            child: ExcludeSemantics(
              child: _animated
                  ? FadeTransition(opacity: _opacity, child: badge)
                  : badge,
            ),
          ),
        ),
      ),
    );
  }
}
