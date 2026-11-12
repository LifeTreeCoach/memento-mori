import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/people/friend_lifespan_estimate.dart';

/// Where the person's lifespan number stands relative to an estimate.
enum FriendEstimateStatus {
  /// No (applied) estimate yet.
  none,

  /// The number is the one the estimate applied.
  fromEstimate,

  /// An estimate exists, but the slider was moved since.
  adjusted;

  static FriendEstimateStatus of(
    FriendLifespanEstimate? estimate,
    int lifespan,
  ) {
    final applied = estimate?.appliedYears;
    if (applied == null) return none;
    return applied == lifespan ? fromEstimate : adjusted;
  }
}

/// Tile under the lifespan slider of the friend form: starts (or reopens)
/// the estimate for this person and offers to forget its answers while
/// keeping the number. A privacy line sits below it.
class LifespanEstimateTile extends StatelessWidget {
  const LifespanEstimateTile({
    super.key,
    required this.estimate,
    required this.lifespan,
    required this.onOpen,
    required this.onForget,
  });

  final FriendLifespanEstimate? estimate;
  final int lifespan;
  final VoidCallback onOpen;
  final VoidCallback onForget;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final status = FriendEstimateStatus.of(estimate, lifespan);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.insights_outlined),
          title: Text(_title(l10n, status)),
          subtitle: Text(_subtitle(l10n, status)),
          trailing: estimate == null ? null : _menu(l10n),
          onTap: onOpen,
        ),
        Text(l10n.translate('form_estimate_privacy'), style: muted),
      ],
    );
  }

  String _years() => '${estimate?.appliedYears ?? lifespan}';

  String _title(AppLocalizations l10n, FriendEstimateStatus status) =>
      switch (status) {
        FriendEstimateStatus.none => l10n.translate('form_estimate_start'),
        FriendEstimateStatus.fromEstimate => l10n.translate(
          'form_estimate_from',
          replacements: {'n': _years()},
        ),
        FriendEstimateStatus.adjusted => l10n.translate(
          'form_estimate_adjusted',
        ),
      };

  String _subtitle(AppLocalizations l10n, FriendEstimateStatus status) =>
      switch (status) {
        FriendEstimateStatus.none => l10n.translate('form_estimate_start_hint'),
        FriendEstimateStatus.fromEstimate => l10n.translate(
          'form_estimate_review_hint',
        ),
        FriendEstimateStatus.adjusted => l10n.translate(
          'form_estimate_adjusted_hint',
          replacements: {'n': _years()},
        ),
      };

  Widget _menu(AppLocalizations l10n) => PopupMenuButton<void>(
    tooltip: l10n.translate('form_estimate_options'),
    itemBuilder: (_) => [
      PopupMenuItem<void>(
        onTap: onForget,
        child: Text(l10n.translate('form_estimate_forget')),
      ),
    ],
  );
}
