import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/friend_detail/friend_lifespan_painter.dart';
import 'package:memento_mori_life_in_weeks/friend_detail/friend_share.dart';
import 'package:memento_mori_life_in_weeks/friend_detail/friend_text.dart';
import 'package:memento_mori_life_in_weeks/friend_detail/info_row.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/people/group_names.dart';
import 'package:memento_mori_life_in_weeks/theme/layout_text.dart';
import 'package:memento_mori_life_in_weeks/theme/life_palette.dart';

/// The lifespan card on the friend detail screen: stats, the animated
/// [FriendLifespanPainter] chart and details/share actions.
class FriendLifespanVisualization extends StatefulWidget {
  final Friend friend;
  final double height;
  final bool showDetails;
  final bool enableAnimation;

  /// Only for friends with a birth year ([Friend.hasBirthYear]); the
  /// lifespan section shows a hint instead for the others.
  const FriendLifespanVisualization({
    super.key,
    required this.friend,
    this.height = 200.0,
    this.showDetails = true,
    this.enableAnimation = true,
  });

  /// Shown instead of the years left once the expected lifespan is reached.
  static const String giftSymbol = '\u{1F381}';

  @override
  State<FriendLifespanVisualization> createState() =>
      _FriendLifespanVisualizationState();
}

class _FriendLifespanVisualizationState
    extends State<FriendLifespanVisualization>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.linear),
    );

    if (widget.enableAnimation) {
      _animationController.repeat();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.showDetails) ...[
              Text(
                _l10n.translate(
                  'lifespan_title',
                  replacements: {'name': widget.friend.name},
                ),
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              _buildLifespanStats(),
              const SizedBox(height: 16),
            ],
            _buildAnimatedPainter(),
            if (widget.showDetails) ...[
              const SizedBox(height: 16),
              _buildActionButtons(),
            ],
          ],
        ),
      ),
    );
  }

  AppLocalizations get _l10n => AppLocalizations.of(context);

  Widget _buildAnimatedPainter() {
    final palette = LifePalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _waveAnimation,
      builder: (context, child) {
        return SizedBox(
          height: widget.height,
          child: CustomPaint(
            painter: FriendLifespanPainter(
              friend: widget.friend,
              palette: palette,
              outline: scheme.outlineVariant,
              labelColor: scheme.onSurfaceVariant,
              scaleText: LayoutText.fromTheme(Theme.of(context)),
              indicatorFill: scheme.surface,
              animationValue: _waveAnimation.value,
              enableAnimation: widget.enableAnimation,
            ),
            child: const SizedBox.expand(),
          ),
        );
      },
    );
  }

  Widget _buildLifespanStats() {
    final currentAge = widget.friend.getCurrentAge() ?? 0;
    final progressPercent = FriendText.percentLived(widget.friend) ?? 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatItem('$currentAge', _l10n.translate('lifespan_age')),
        _remainingStat(),
        _buildStatItem(
          _l10n.translate('lifespan_percent',
              replacements: {'p': '$progressPercent'}),
          _l10n.translate('lifespan_lived'),
        ),
      ],
    );
  }

  /// Years left, or a gift once the expected lifespan is reached (never a
  /// negative number).
  Widget _remainingStat() {
    if (widget.friend.isBeyondExpectedLifespan()) {
      return _buildStatItem(
          FriendLifespanVisualization.giftSymbol,
          _l10n.translate('lifespan_beyond_label'));
    }
    return _buildStatItem('${widget.friend.getRemainingYears() ?? 0}',
        _l10n.translate('lifespan_years_left'));
  }

  Widget _buildStatItem(String value, String label) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(value, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 1.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    // Wraps instead of overflowing with long labels or large text.
    return Wrap(
      alignment: WrapAlignment.spaceEvenly,
      children: [
        TextButton.icon(
          onPressed: _showLifespanDetails,
          icon: const Icon(Icons.info_outline, size: 18),
          label: Text(_l10n.translate('lifespan_details')),
        ),
        TextButton.icon(
          onPressed: _shareLifespanInfo,
          icon: const Icon(Icons.ios_share, size: 18),
          label: Text(_l10n.translate('lifespan_share')),
        ),
      ],
    );
  }

  void _showLifespanDetails() {
    showDialog(
      context: context,
      builder: (context) => _LifespanDetailsDialog(friend: widget.friend),
    );
  }

  Future<void> _shareLifespanInfo() => shareFriend(context, widget.friend);
}

/// Age, expectancy, remaining years, next birthday and group of [friend].
class _LifespanDetailsDialog extends StatelessWidget {
  const _LifespanDetailsDialog({required this.friend});

  final Friend friend;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(
        l10n.translate('lifespan_title', replacements: {'name': friend.name}),
      ),
      // A fixed width: AlertDialog measures intrinsic widths, which the
      // InfoRows (sized by a LayoutBuilder) cannot report.
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _rows(l10n),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.translate('lifespan_close')),
        ),
      ],
    );
  }

  List<Widget> _rows(AppLocalizations l10n) {
    final text = FriendText(l10n);
    final group = friend.groupName;
    InfoRow row(String key, String value) =>
        InfoRow(label: l10n.translate(key), value: value);
    return [
      row('lifespan_current_age', text.years(friend.getCurrentAge() ?? 0)),
      InfoRow(
        label: l10n.translate('lifespan_expected'),
        value: text.years(friend.customLifespan),
        caption: friend.lifespanFromEstimate
            ? l10n.translate('friend_detail_lifespan_estimated')
            : null,
      ),
      row('lifespan_remaining', text.remaining(friend) ?? ''),
      row('lifespan_next_birthday', text.date(friend.getNextBirthday())),
      row('lifespan_days_until', text.days(friend.getDaysUntilNextBirthday())),
      if (group != null && group.isNotEmpty) row('lifespan_group', GroupNames.label(group, l10n)),
    ];
  }
}
