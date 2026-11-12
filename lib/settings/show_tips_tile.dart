import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/tour/tour_progress.dart';

/// "Show tips again": forgets every product tour, so each one shows once
/// more on its next visit.
class ShowTipsTile extends StatelessWidget {
  const ShowTipsTile({super.key});

  Future<void> _reset(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final message =
        AppLocalizations.of(context).translate('tour_show_again_done');
    await TourProgressStore.reset();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      key: const ValueKey('settings_show_tips_tile'),
      leading: const Icon(Icons.lightbulb_outline),
      title: Text(l10n.translate('tour_show_again')),
      subtitle: Text(l10n.translate('tour_show_again_sub')),
      onTap: () => _reset(context),
    );
  }
}
