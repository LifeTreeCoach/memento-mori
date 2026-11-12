import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/widgets/scroll_thread.dart';

/// Shared frame of the text-led onboarding steps: scrollable content in
/// the upper part, the primary action (and an optional secondary one)
/// pinned at the bottom. The scroll area ends above the actions (never
/// behind them), keeps a gap to them and fades out at its lower edge, so
/// content that continues below reads as "scroll on", not as covered.
class StepLayout extends StatelessWidget {
  const StepLayout({
    super.key,
    required this.children,
    required this.action,
    this.secondaryAction,
    this.topPadding = 48,
    this.centerContent = false,
  });

  final List<Widget> children;
  final Widget action;
  final Widget? secondaryAction;

  /// Space above the content; denser steps use less.
  final double topPadding;

  /// Centres content shorter than the scroll area vertically in it (longer
  /// content scrolls as usual).
  final bool centerContent;

  static const EdgeInsets padding = EdgeInsets.symmetric(horizontal: 28);

  /// Space between the end of the scroll area and the actions.
  static const double actionGap = 8;

  /// Height of the fade at the lower edge of the scroll area; smaller than
  /// the content's bottom padding, so fully scrolled content never fades.
  static const double fadeHeight = 16;
  static const double _contentBottomPadding = 24;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          // The thread sits over the scroll area only (not the actions) and
          // outside the fade, so it stays crisp down to the area's end.
          child: ScrollThread(
            child: SizedBox.expand(
              child: _BottomFade(
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    key: const ValueKey('step_layout_scroll'),
                    padding: padding.copyWith(
                      top: topPadding,
                      bottom: _contentBottomPadding,
                    ),
                    child: _content(constraints.maxHeight),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: actionGap),
        StepActions(action: action, secondaryAction: secondaryAction),
      ],
    );
  }

  /// The children, at least as tall as the scroll area of [viewportHeight]
  /// (minus its padding) and centred in it when [centerContent] is set.
  Widget _content(double viewportHeight) {
    final column = Column(
      mainAxisAlignment: centerContent
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
    if (!centerContent || !viewportHeight.isFinite) return column;
    final minHeight = viewportHeight - topPadding - _contentBottomPadding;
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: minHeight.clamp(0, double.infinity),
      ),
      child: column,
    );
  }
}

/// Full-width primary button with an optional text button beneath.
class StepActions extends StatelessWidget {
  const StepActions({super.key, required this.action, this.secondaryAction});

  final Widget action;
  final Widget? secondaryAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: StepLayout.padding.copyWith(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 52, child: action),
          if (secondaryAction != null) ...[
            const SizedBox(height: 8),
            SizedBox(height: 48, child: secondaryAction),
          ],
        ],
      ),
    );
  }
}

/// Fades [child] out over the last [StepLayout.fadeHeight] pixels.
class _BottomFade extends StatelessWidget {
  const _BottomFade({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) {
        final height = bounds.height <= 0 ? 1.0 : bounds.height;
        final solidUntil =
            (1 - StepLayout.fadeHeight / height).clamp(0.0, 1.0);
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Colors.white, Colors.white, Colors.transparent],
          stops: [0, solidUntil, 1],
        ).createShader(bounds);
      },
      child: child,
    );
  }
}
