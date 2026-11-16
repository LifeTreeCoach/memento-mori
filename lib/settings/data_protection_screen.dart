import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/settings/external_link.dart';
import 'package:memento_mori_life_in_weeks/support/project_links.dart';
import 'package:memento_mori_life_in_weeks/widgets/scroll_thread.dart';

/// "How your data is protected" (Settings > Data): a calm, plain-language
/// summary of encryption at rest, the never-saved health answers, backups,
/// export, the plain-text exceptions and the missing internet access, with a
/// link to the full privacy policy ([ProjectLinks.privacy]).
class DataProtectionScreen extends StatelessWidget {
  const DataProtectionScreen({super.key, this.openLink = openExternalLink});

  /// Opens the privacy policy; injectable for tests.
  final ExternalLinkOpener openLink;

  /// Key of the privacy policy link, for tests.
  static const Key policyLinkKey = ValueKey('data-protection-policy-link');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isIos = theme.platform == TargetPlatform.iOS;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.translate('data_protection_screen_title'))),
      body: ScrollThread(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              l10n.translate('data_protection_intro'),
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            _ProtectionPoint(
              icon: Icons.lock_outline,
              titleKey: 'data_protection_encrypted_title',
              bodyKey: 'data_protection_encrypted_body',
            ),
            _ProtectionPoint(
              icon: Icons.health_and_safety_outlined,
              titleKey: 'data_protection_health_title',
              bodyKey: 'data_protection_health_body',
            ),
            _ProtectionPoint(
              icon: Icons.backup_outlined,
              titleKey: 'data_protection_backup_title',
              bodyKey: isIos
                  ? 'data_protection_backup_ios'
                  : 'data_protection_backup_android',
            ),
            _ProtectionPoint(
              icon: Icons.key_outlined,
              titleKey: 'data_protection_export_title',
              bodyKey: 'data_protection_export_body',
            ),
            _ProtectionPoint(
              icon: Icons.visibility_outlined,
              titleKey: 'data_protection_readable_title',
              bodyKey: 'data_protection_readable_body',
            ),
            _ProtectionPoint(
              icon: Icons.cloud_off_outlined,
              titleKey: 'data_protection_offline_title',
              bodyKey: 'data_protection_offline_body',
            ),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                key: policyLinkKey,
                icon: const Icon(Icons.open_in_new, size: 18),
                label: Text(l10n.translate('data_protection_policy_link')),
                onPressed: () => openLink(context, ProjectLinks.privacy),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One section: an icon beside a title and a short paragraph.
class _ProtectionPoint extends StatelessWidget {
  const _ProtectionPoint({
    required this.icon,
    required this.titleKey,
    required this.bodyKey,
  });

  final IconData icon;
  final String titleKey;
  final String bodyKey;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    l10n.translate(titleKey),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.translate(bodyKey),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
