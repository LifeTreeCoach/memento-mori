import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/diagnostics_screen.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/settings/external_link.dart';
import 'package:memento_mori_life_in_weeks/settings/settings_section.dart';
import 'package:memento_mori_life_in_weeks/settings/show_tips_tile.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:memento_mori_life_in_weeks/support/project_links.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Version (tap it 7× to unlock diagnostics), "Show tips again", the
/// neutral project links (source code, ideas & feedback, privacy; every
/// build), licenses and, once unlocked, diagnostics. The sponsor link lives in the Support section.
class AboutSection extends StatefulWidget {
  const AboutSection({
    super.key,
    required this.alwaysShowDiagnostics,
    this.openLink = openExternalLink,
  });

  /// Shows diagnostics without the unlock (debug builds).
  final bool alwaysShowDiagnostics;

  /// Opens the [ProjectLinks]; injectable for tests.
  final ExternalLinkOpener openLink;

  static const int tapsToUnlock = 7;

  /// After this many taps a countdown hint appears.
  static const int tapsBeforeHint = 4;

  @override
  State<AboutSection> createState() => _AboutSectionState();
}

class _AboutSectionState extends State<AboutSection> {
  static const String _appName = 'Memento Mori';

  String _version = '';
  int _versionTaps = 0;

  bool get _diagnosticsVisible =>
      widget.alwaysShowDiagnostics || SettingsService.isDiagnosticsUnlocked();

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() => _version = '${info.version} (${info.buildNumber})');
    } catch (e) {
      debugPrint('Version lookup failed: $e');
    }
  }

  Future<void> _onVersionTap() async {
    if (_diagnosticsVisible) return;
    _versionTaps++;
    final remaining = AboutSection.tapsToUnlock - _versionTaps;
    if (remaining <= 0) {
      await SettingsService.setDiagnosticsUnlocked(true);
      if (!mounted) return;
      setState(() {});
      _showMessage(AppLocalizations.of(context)
          .translate('settings_diagnostics_unlocked'));
    } else if (_versionTaps >= AboutSection.tapsBeforeHint) {
      _showMessage(AppLocalizations.of(context)
          .plural('settings_diagnostics_taps', remaining));
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  void _openLicenses() {
    showLicensePage(
      context: context,
      applicationName: _appName,
      applicationVersion: _version,
      applicationIcon: Padding(
        padding: const EdgeInsets.all(12),
        // Brand app icon (branding/BRAND.md: small sizes use the icon, not the badge).
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset('branding/exports/web/icon-192.png', width: 48),
        ),
      ),
    );
  }

  void _openDiagnostics() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const DiagnosticsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsSection(
      title: l10n.translate('settings_section_about'),
      children: [
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: Text(l10n.translate('settings_version')),
          subtitle: Text(_version.isEmpty ? '—' : _version),
          onTap: _onVersionTap,
        ),
        const ShowTipsTile(),
        ListTile(
          key: const ValueKey('about_source_code_tile'),
          leading: const Icon(Icons.code),
          title: Text(l10n.translate('settings_source_code')),
          subtitle: Text(l10n.translate('settings_source_code_sub')),
          trailing: const Icon(Icons.open_in_new, size: 20),
          onTap: () => widget.openLink(context, ProjectLinks.repository),
        ),
        ListTile(
          key: const ValueKey('about_feedback_tile'),
          leading: const Icon(Icons.forum_outlined),
          title: Text(l10n.translate('settings_feedback')),
          subtitle: Text(l10n.translate('settings_feedback_sub')),
          trailing: const Icon(Icons.open_in_new, size: 20),
          onTap: () => widget.openLink(context, ProjectLinks.discussions),
        ),
        ListTile(
          key: const ValueKey('about_privacy_tile'),
          leading: const Icon(Icons.privacy_tip_outlined),
          title: Text(l10n.translate('settings_privacy')),
          subtitle: Text(l10n.translate('settings_privacy_sub')),
          trailing: const Icon(Icons.open_in_new, size: 20),
          onTap: () => widget.openLink(context, ProjectLinks.privacy),
        ),
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: Text(l10n.translate('settings_licenses')),
          trailing: const Icon(Icons.chevron_right),
          onTap: _openLicenses,
        ),
        if (_diagnosticsVisible)
          ListTile(
            leading: const Icon(Icons.build_outlined),
            title: Text(l10n.translate('diagnostics_title')),
            subtitle: Text(l10n.translate('settings_diagnostics_sub')),
            trailing: const Icon(Icons.chevron_right),
            onTap: _openDiagnostics,
          ),
      ],
    );
  }
}
