import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/life/quote_service.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:share_plus/share_plus.dart';

/// "Seneca · De Brevitate Vitae 1.3", or just the author without a source;
/// null for anonymous quotes.
String? quoteAttribution(Quote quote) {
  final author = quote.author;
  if (author == null || author.isEmpty) return null;
  final source = quote.source;
  return source == null || source.isEmpty ? author : '$author · $source';
}

/// The shared text: the quote in the language's quotation marks, its
/// attribution and the app name.
String quoteShareText(AppLocalizations l10n, Quote quote) {
  final attribution = quoteAttribution(quote);
  if (attribution == null) {
    return l10n.translate('quote_share_text_anonymous',
        replacements: {'text': quote.text});
  }
  return l10n.translate('quote_share_text',
      replacements: {'text': quote.text, 'attribution': attribution});
}

/// Opens the system share sheet with [quote].
Future<void> shareQuote(BuildContext context, Quote quote) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  try {
    await SharePlus.instance.share(
      ShareParams(text: quoteShareText(l10n, quote)),
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
