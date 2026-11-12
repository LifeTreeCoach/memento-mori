import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/settings/external_link.dart';

const String sponsorUrl = 'https://buymeacoffee.com/monkeywave';

/// Opens the sponsor page; screens take one so tests can replace it.
typedef SponsorLinkOpener = Future<void> Function(BuildContext context);

/// Opens the sponsor page in the browser; shows a snack bar if that fails
/// ([openExternalLink]).
Future<void> openSponsorLink(BuildContext context) =>
    openExternalLink(context, sponsorUrl);
