import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/settings/choice_tile.dart';
import 'package:memento_mori_life_in_weeks/settings/settings_section.dart';
import 'package:memento_mori_life_in_weeks/widget_service.dart';

/// Pin the home-screen widget and choose the unit it counts in.
class WidgetSection extends StatefulWidget {
  const WidgetSection({super.key});

  @override
  State<WidgetSection> createState() => _WidgetSectionState();
}

class _WidgetSectionState extends State<WidgetSection> {
  Future<void> _addWidget() async {
    if (!WidgetService.canRequestPin) return _showManualHint();
    final requested = await WidgetService.requestPinWidget();
    if (!requested && mounted) await _showManualHint();
  }

  Future<void> _showManualHint() {
    final l10n = AppLocalizations.of(context);
    final bodyKey = WidgetService.canRequestPin
        ? 'settings_add_widget_manual_body'
        : 'settings_add_widget_ios_body';
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.translate('settings_add_widget_manual_title')),
        content: Text(l10n.translate(bodyKey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(MaterialLocalizations.of(dialogContext).okButtonLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _setDisplayMode(String mode) async {
    await WidgetService.setWidgetDisplayMode(mode);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsSection(
      title: l10n.translate('settings_section_widget'),
      children: [
        ListTile(
          leading: const Icon(Icons.widgets_outlined),
          title: Text(l10n.translate('settings_add_widget')),
          subtitle: Text(l10n.translate('settings_add_widget_sub')),
          onTap: _addWidget,
        ),
        ChoiceTile<String>(
          icon: Icons.timelapse_outlined,
          title: l10n.translate('settings_widget_shows'),
          options: [
            for (final mode in WidgetService.widgetDisplayModes)
              SettingsOption(mode, l10n.translate(mode)),
          ],
          selected: WidgetService.getWidgetDisplayMode(),
          onChanged: _setDisplayMode,
        ),
      ],
    );
  }
}
