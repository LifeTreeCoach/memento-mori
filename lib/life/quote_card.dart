import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/life/quote_service.dart';
import 'package:memento_mori_life_in_weeks/life/quote_share.dart';
import 'package:memento_mori_life_in_weeks/theme/life_palette.dart';

/// "Quote of the day" in serif italics, with author, source and a share
/// action.
class QuoteCard extends StatelessWidget {
  const QuoteCard({super.key, required this.quote});

  final Quote quote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 8, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(context, l10n),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                l10n.translate('quote_text', replacements: {'text': quote.text}),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontFamily: 'Fraunces',
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w400,
                  height: 1.35,
                  color: LifePalette.of(context).quoteText,
                ),
              ),
            ),
            if (quote.author?.isNotEmpty ?? false) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _attribution(theme),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.translate('quote_of_the_day').toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 1.8,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.ios_share, size: 18),
          visualDensity: VisualDensity.compact,
          tooltip: l10n.translate('quote_share'),
          color: theme.colorScheme.onSurfaceVariant,
          onPressed: () => shareQuote(context, quote),
        ),
      ],
    );
  }

  /// "— Seneca · De Brevitate Vitae 1.3": the source smaller and fainter.
  Widget _attribution(ThemeData theme) {
    final muted = theme.colorScheme.onSurfaceVariant;
    final source = quote.source;
    return Text.rich(
      TextSpan(
        text: '— ${quote.author}',
        style: theme.textTheme.labelLarge?.copyWith(color: muted),
        children: [
          if (source != null && source.isNotEmpty)
            TextSpan(
              text: ' · $source',
              style: theme.textTheme.labelSmall?.copyWith(
                color: muted.withValues(alpha: 0.75),
                fontWeight: FontWeight.w400,
              ),
            ),
        ],
      ),
    );
  }
}
