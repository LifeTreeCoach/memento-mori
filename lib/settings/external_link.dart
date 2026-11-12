import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a link; screens take one so tests can replace it.
typedef ExternalLinkOpener = Future<void> Function(
  BuildContext context,
  String url,
);

/// Opens [url] in the browser; shows a snack bar if that fails.
///
/// Calls [launchUrl] directly: `canLaunchUrl` needs a manifest `<queries>`
/// entry on Android 11+ and would report false without it.
Future<void> openExternalLink(BuildContext context, String url) async {
  final messenger = ScaffoldMessenger.of(context);
  final error = AppLocalizations.of(context).translate('settings_link_error');
  var opened = false;
  try {
    opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
  } catch (e) {
    debugPrint('Link $url failed: $e');
  }
  if (!opened) messenger.showSnackBar(SnackBar(content: Text(error)));
}
