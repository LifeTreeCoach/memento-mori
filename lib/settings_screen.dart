import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/app_settings_controller.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/settings/about_section.dart';
import 'package:memento_mori_life_in_weeks/settings/appearance_section.dart';
import 'package:memento_mori_life_in_weeks/settings/compass_section.dart';
import 'package:memento_mori_life_in_weeks/settings/data_section.dart';
import 'package:memento_mori_life_in_weeks/settings/external_link.dart';
import 'package:memento_mori_life_in_weeks/settings/life_section.dart';
import 'package:memento_mori_life_in_weeks/settings/recommend_section.dart';
import 'package:memento_mori_life_in_weeks/settings/reminders_section.dart';
import 'package:memento_mori_life_in_weeks/settings/support_section.dart';
import 'package:memento_mori_life_in_weeks/settings/widget_section.dart';
import 'package:memento_mori_life_in_weeks/support/support_scope.dart';
import 'package:memento_mori_life_in_weeks/widgets/scroll_thread.dart';

/// The Settings tab: grouped sections under a large serif title.
///
/// Values are read on every build (from [AppSettingsController] or the
/// services), so the tab stays current without being recreated and keeps
/// its scroll position.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    this.alwaysShowDiagnostics = kDebugMode,
    this.openProjectLink = openExternalLink,
  });

  /// Shows the diagnostics entry without the 7-tap unlock.
  final bool alwaysShowDiagnostics;

  /// Opens the project links (About, privacy policy from Data);
  /// injectable for tests.
  final ExternalLinkOpener openProjectLink;

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: ListTileTheme.merge(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: ScrollThread(
          child: CustomScrollView(
            slivers: [
              SliverAppBar.large(
                // The extra 4 aligns the title with the 20px content gutter.
                title: Padding(
                  padding: const EdgeInsetsDirectional.only(start: 4),
                  child: Text(l10n.translate('settings')),
                ),
              ),
              SliverList.list(children: [
                LifeSection(settings: settings),
                AppearanceSection(settings: settings),
                // Not const: these read services directly and must rebuild
                // when the tab is revisited (e.g. after the People toggle).
                RemindersSection(),
                const CompassSection(),
                WidgetSection(),
                DataSection(openLink: openProjectLink),
                // Coffee link outside the stores, rate + recommend in them.
                if (SupportScope.of(context).showsLink)
                  const SupportSection()
                else
                  const RecommendSection(),
                AboutSection(
                  alwaysShowDiagnostics: alwaysShowDiagnostics,
                  openLink: openProjectLink,
                ),
                const SizedBox(height: 32),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
