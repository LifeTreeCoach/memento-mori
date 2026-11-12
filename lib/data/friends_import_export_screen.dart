import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_service.dart';
import 'package:memento_mori_life_in_weeks/friends_service.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/data/picked_files.dart';
import 'package:memento_mori_life_in_weeks/widgets/section_label.dart';
import 'package:memento_mori_life_in_weeks/widgets/scroll_thread.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

class FriendsImportExportScreen extends StatefulWidget {
  const FriendsImportExportScreen({super.key});

  @override
  State<FriendsImportExportScreen> createState() => _FriendsImportExportScreenState();
}

class _FriendsImportExportScreenState extends State<FriendsImportExportScreen> {
  bool isLoading = false;
  String statusMessage = '';

  AppLocalizations get _l10n => AppLocalizations.of(context);

  void _setStatus(String message, {bool? loading}) {
    setState(() {
      statusMessage = message;
      if (loading != null) isLoading = loading;
    });
  }

  String _errorText(Object error) =>
      error is FriendsBackupException ? _l10n.translate(error.messageKey) : '$error';

  /// Encodes all friends and Compass data and hands them to [deliver];
  /// reports an empty backup and failures in the status banner.
  Future<void> _export(Future<void> Function(_Backup backup) deliver) async {
    _setStatus(_l10n.translate('import_export_status_preparing_export'), loading: true);
    try {
      final friends = await FriendsService.getAllFriends();
      final compass = await CompassService.load();
      if (!mounted) return;
      if (friends.isEmpty && compass.isEmpty) {
        _setStatus(_l10n.translate('import_export_status_nothing_to_export'), loading: false);
        return;
      }
      await deliver(_Backup(
        json: await FriendsService.exportBackup(friends, compass: compass),
        count: friends.length,
        compass: compass,
        fileName: backupFileName(DateTime.now()),
      ));
    } catch (e) {
      if (!mounted) return;
      _setStatus(_l10n.translate('import_export_export_failed', replacements: {'error': '$e'}),
          loading: false);
    }
  }

  Future<void> _saveToDevice() => _export(_saveBackup);

  Future<void> _shareBackup() => _export(_shareBackupFile);

  /// Lets the user pick where to save the backup; cancelling saves nothing.
  Future<void> _saveBackup(_Backup backup) async {
    final savedTo = await FilePicker.saveFile(
      dialogTitle: _l10n.translate('import_export_save_dialog_title'),
      fileName: backup.fileName,
      bytes: Uint8List.fromList(utf8.encode(backup.json)),
      mimeType: 'application/json',
    );
    if (!mounted) return;
    _setStatus(
      savedTo == null
          ? _l10n.translate('import_export_status_export_cancelled')
          : _exportedText(backup),
      loading: false,
    );
  }

  Future<void> _shareBackupFile(_Backup backup) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/${backup.fileName}');
    await file.writeAsString(backup.json);
    if (!mounted) return;
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: backup.compass.isEmpty
            ? _l10n.plural('import_export_share_text', backup.count)
            : _l10n.translate('import_export_share_text_items',
                replacements: {'items': _backupItemsText(backup.count, backup.compass)}),
        subject: _l10n.translate('import_export_share_subject'),
      ),
    );
    if (!mounted) return;
    _reportShareResult(result.status, backup);
  }

  /// "Exported 2 people" or, with Compass data, "Exported 2 people,
  /// 3 intentions and 5 moments".
  String _exportedText(_Backup backup) => backup.compass.isEmpty
      ? _l10n.plural('import_export_exported', backup.count)
      : _l10n.translate('import_export_exported_items',
          replacements: {'items': _backupItemsText(backup.count, backup.compass)});

  /// [_itemsText] of [people] and everything in [compass].
  String _backupItemsText(int people, CompassData compass) => _itemsText(
        people: people,
        intentions: compass.intentions.length,
        moments: compass.moments.length,
        phases: compass.phases.length,
      );

  /// The non-empty parts of "2 people, 3 intentions, 5 moments and
  /// 4 life phases".
  String _itemsText({
    int people = 0,
    required int intentions,
    required int moments,
    required int phases,
  }) {
    String count(String key, int n) => _l10n.plural(key, n,
        replacements: {'n': _l10n.numberFormat.format(n)});
    final parts = [
      if (people > 0) count('import_export_count_people', people),
      if (intentions > 0) count('import_export_count_intentions', intentions),
      if (moments > 0) count('import_export_count_moments', moments),
      if (phases > 0) count('import_export_count_phases', phases),
    ];
    if (parts.length < 2) return parts.join();
    return _l10n.translate('import_export_list_and', replacements: {
      'first': parts.sublist(0, parts.length - 1).join(', '),
      'last': parts.last,
    });
  }

  /// Confirms an export only when the share sheet reports success.
  void _reportShareResult(ShareResultStatus status, _Backup backup) {
    final message = switch (status) {
      ShareResultStatus.success => _exportedText(backup),
      ShareResultStatus.dismissed =>
        _l10n.translate('import_export_status_export_cancelled'),
      // The platform can't tell whether a target was picked.
      ShareResultStatus.unavailable => _l10n.translate('import_export_shared'),
    };
    _setStatus(message, loading: false);
  }

  Future<void> _importFriends() async {
    _setStatus(_l10n.translate('import_export_status_selecting_file'), loading: true);

    try {
      final jsonString = await readPickedFile(
        () => FilePicker.pickFile(
          type: FileType.custom,
          allowedExtensions: ['json'],
        ),
        (file) async => utf8.decode(await file.readAsBytes()),
      );
      if (!mounted) return;

      if (jsonString == null) {
        _setStatus(_l10n.translate('import_export_status_no_file'), loading: false);
        return;
      }

      _setStatus(_l10n.translate('import_export_status_processing'));

      final contents = FriendsService.decodeBackupContents(jsonString);
      final importedFriends = contents.entries;

      final confirmed =
          await _confirmImport(importedFriends.length, contents.compass);
      if (!mounted) return;
      if (confirmed != true) {
        _setStatus(_l10n.translate('import_export_status_cancelled'), loading: false);
        return;
      }

      _setStatus(_l10n.translate('import_export_status_importing'));
      final (added, skipped) =
          await FriendsService.importBackupEntries(importedFriends);
      final compass = contents.compass;
      final compassAdded = compass == null
          ? null
          : await CompassService.importDataCounts(compass);
      if (!mounted) return;

      final result = [
        if (importedFriends.isNotEmpty)
          _l10n.translate('import_export_import_result', replacements: {
            'added': '$added',
            'skipped': '$skipped',
          }),
        if (compassAdded != null) _compassAddedText(compassAdded),
      ].join('\n');
      _setStatus(result, loading: false);
    } catch (e) {
      if (!mounted) return;
      _setStatus(
          _l10n.translate('import_export_import_failed', replacements: {'error': _errorText(e)}),
          loading: false);
    }
  }

  /// "Compass: added 1 intention and 5 life phases", or "… 0 new entries".
  String _compassAddedText(CompassImportCounts added) {
    final items = _itemsText(
      intentions: added.intentions,
      moments: added.moments,
      phases: added.phases,
    );
    return items.isEmpty
        ? _l10n.plural('import_export_compass_added', 0)
        : _l10n.translate('import_export_compass_added_items',
            replacements: {'items': items});
  }

  Future<bool?> _confirmImport(int count, CompassData? compass) {
    final l10n = _l10n;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('import_export_dialog_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(compass == null
                ? l10n.plural('import_export_dialog_found', count)
                : l10n.translate('import_export_dialog_found_items',
                    replacements: {'items': _backupItemsText(count, compass)})),
            const SizedBox(height: 16),
            SectionLabel(l10n.translate('import_export_dialog_options')),
            const SizedBox(height: 8),
            Text(l10n.translate('import_export_dialog_rule_duplicates')),
            Text(l10n.translate('import_export_dialog_rule_new')),
            Text(l10n.translate('import_export_dialog_rule_existing')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.translate('import_export_cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.translate('import_export_dialog_confirm')),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllFriends() async {
    final l10n = _l10n;
    final errorColor = Theme.of(context).colorScheme.error;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('import_export_clear_dialog_title')),
        content: Text(l10n.translate('import_export_clear_dialog_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.translate('import_export_cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: errorColor),
            child: Text(l10n.translate('import_export_clear_dialog_confirm')),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    _setStatus(l10n.translate('import_export_status_clearing'), loading: true);

    try {
      await FriendsService.clearAllData();
      if (!mounted) return;
      _setStatus(l10n.translate('import_export_cleared'), loading: false);
    } catch (e) {
      if (!mounted) return;
      _setStatus(l10n.translate('import_export_clear_failed', replacements: {'error': '$e'}),
          loading: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = _l10n;
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('import_export_title')),
      ),
      body: ScrollThread(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            // The single place results are shown, above the fold.
            if (isLoading) const LinearProgressIndicator(),
            if (statusMessage.isNotEmpty) ...[
              _StatusBanner(message: statusMessage),
              const SizedBox(height: 16),
            ],
            _ActionSection(
              header: l10n.translate('import_export_export_header'),
              description: l10n.translate('import_export_export_description'),
              button: _ExportButtons(
                onSave: isLoading ? null : _saveToDevice,
                onShare: isLoading ? null : _shareBackup,
              ),
            ),
            const SizedBox(height: 16),
            _ActionSection(
              header: l10n.translate('import_export_import_header'),
              description: l10n.translate('import_export_import_description'),
              button: FilledButton.tonalIcon(
                onPressed: isLoading ? null : _importFriends,
                icon: const Icon(Icons.download),
                label: Text(l10n.translate('import_export_import_button')),
              ),
            ),
            const SizedBox(height: 16),
            _ActionSection(
              header: l10n.translate('import_export_clear_header'),
              headerColor: colorScheme.error,
              description: l10n.translate('import_export_clear_description'),
              button: OutlinedButton.icon(
                onPressed: isLoading ? null : _clearAllFriends,
                icon: const Icon(Icons.delete_forever),
                label: Text(l10n.translate('import_export_clear_button')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.error,
                  side: BorderSide(color: colorScheme.error),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Default backup file name, e.g. `memento_backup_2026-11-04.json`.
String backupFileName(DateTime now) =>
    'memento_backup_${DateFormat('yyyy-MM-dd').format(now)}.json';

/// An encoded backup ready to be saved or shared.
class _Backup {
  const _Backup({
    required this.json,
    required this.count,
    required this.compass,
    required this.fileName,
  });

  final String json;

  /// Number of people.
  final int count;
  final CompassData compass;
  final String fileName;
}

/// "Save to device" (primary) and "Share" side by side.
class _ExportButtons extends StatelessWidget {
  const _ExportButtons({required this.onSave, required this.onShare});

  final VoidCallback? onSave;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        FilledButton.icon(
          onPressed: onSave,
          icon: const Icon(Icons.save_alt),
          label: Text(l10n.translate('import_export_save_button')),
        ),
        OutlinedButton.icon(
          onPressed: onShare,
          icon: const Icon(Icons.share_outlined),
          label: Text(l10n.translate('import_export_share_button')),
        ),
      ],
    );
  }
}

/// Card with a section label, description and one action button.
class _ActionSection extends StatelessWidget {
  const _ActionSection({
    required this.header,
    required this.description,
    required this.button,
    this.headerColor,
  });

  final String header;
  final String description;
  final Widget button;
  final Color? headerColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionLabel(header, color: headerColor),
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            button,
          ],
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodyMedium,
        textAlign: TextAlign.center,
      ),
    );
  }
}
