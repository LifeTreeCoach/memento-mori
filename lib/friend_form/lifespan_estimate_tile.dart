import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

/// Where the person's lifespan number stands relative to an estimate.
enum FriendEstimateStatus {
  /// No (applied) estimate yet.
  none,

  /// The number is the one the estimate applied.
  fromEstimate,

  /// An estimate exists, but the slider was moved since.
  adjusted;

  static FriendEstimateStatus of(int? estimatedYears, int lifespan) {
    if (estimatedYears == null) return none;
    return estimatedYears == lifespan ? fromEstimate : adjusted;
  }
}

/// Tile under the lifespan slider of the friend form: starts (or reopens)
/// the estimate for this person and offers to forget that the number came
/// from it while keeping the number. A privacy line sits below it.
class LifespanEstimateTile extends StatelessWidget {
  const LifespanEstimateTile({
    super.key,
    required this.estimatedYears,
    required this.lifespan,
    required this.onOpen,
    required this.onForget,
  });

  /// The years the estimate applied; null without one.
  final int? estimatedYears;
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
    final status = FriendEstimateStatus.of(estimatedYears, lifespan);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.insights_outlined),
          title: Text(_title(l10n, status)),
          subtitle: Text(_subtitle(l10n, status)),
          trailing: estimatedYears == null ? null : _menu(l10n),
          onTap: onOpen,
        ),
        Text(l10n.translate('form_estimate_privacy'), style: muted),
      ],
    );
  }

  String _years() => '${estimatedYears ?? lifespan}';

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
