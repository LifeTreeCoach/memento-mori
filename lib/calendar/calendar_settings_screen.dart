import 'package:flutter/material.dart';
import 'package:device_calendar_plus/device_calendar_plus.dart';
import 'package:memento_mori_life_in_weeks/calendar/calendar_service.dart';
import 'package:memento_mori_life_in_weeks/calendar/calendar_sync_labels.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/widgets/section_label.dart';
import 'package:memento_mori_life_in_weeks/widgets/scroll_thread.dart';

class CalendarSettingsScreen extends StatefulWidget {
  const CalendarSettingsScreen({super.key});

  @override
  State<CalendarSettingsScreen> createState() => _CalendarSettingsScreenState();
}

class _CalendarSettingsScreenState extends State<CalendarSettingsScreen> {
  bool _isLoading = true;
  bool _hasPermissions = false;
  List<Calendar> _availableCalendars = [];
  String? _selectedCalendarId;
  CalendarSyncStatus _syncStatus = CalendarSyncStatus.notConfigured;
  Map<String, int> _syncStats = {};
  bool _skipImportedContacts = true;

  AppLocalizations get _l10n => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    CalendarService.revision.addListener(_onSyncChanged);
    _initializeCalendar();
  }

  @override
  void dispose() {
    CalendarService.revision.removeListener(_onSyncChanged);
    super.dispose();
  }

  /// Shows the outcome of an automatic sync (friend or language change)
  /// that ran while this screen is open.
  Future<void> _onSyncChanged() async {
    final syncStats = await CalendarService.getSyncStats();
    if (!mounted || _isLoading) return;
    setState(() {
      _hasPermissions = CalendarService.hasPermissions;
      _selectedCalendarId = CalendarService.selectedCalendarId;
      _syncStatus = CalendarService.syncStatus;
      _syncStats = syncStats;
      _skipImportedContacts = CalendarService.skipImportedContacts;
    });
  }

  void _showSnackBar(String key) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(_l10n.translate(key))));
  }

  Future<void> _initializeCalendar() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final hasPermissions = await CalendarService.initialize();

      final syncStats = await CalendarService.getSyncStats();
      final skipImportedContacts = await CalendarService.loadSkipImportedContacts();
      if (!mounted) return;
      setState(() {
        _hasPermissions = hasPermissions;
        _skipImportedContacts = skipImportedContacts;
        _availableCalendars = CalendarService.availableCalendars;
        _selectedCalendarId = CalendarService.selectedCalendarId;
        _syncStatus = CalendarService.syncStatus;
        _syncStats = syncStats;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error initializing calendar: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasPermissions = false;
      });
    }
  }

  Future<void> _selectCalendar(String calendarId) async {
    setState(() {
      _isLoading = true;
    });

    final success = await CalendarService.selectCalendar(calendarId);
    final syncStats = await CalendarService.getSyncStats();
    if (!mounted) return;

    setState(() {
      if (success) {
        _selectedCalendarId = calendarId;
        _syncStatus = CalendarService.syncStatus;
      }
      _syncStats = syncStats;
      _isLoading = false;
    });

    _showSnackBar(success ? 'calendar_selected_success' : 'calendar_selected_failed');
  }

  /// Saves the choice; the service removes or adds the events of people
  /// imported from contacts right away.
  Future<void> _setSkipImportedContacts(bool skip) async {
    setState(() => _skipImportedContacts = skip);
    await CalendarService.setSkipImportedContacts(skip);
    final syncStats = await CalendarService.getSyncStats();
    if (!mounted) return;
    setState(() {
      _syncStatus = CalendarService.syncStatus;
      _syncStats = syncStats;
    });
  }

  Future<void> _syncAllBirthdays() async {
    if (_selectedCalendarId == null) {
      _showSnackBar('calendar_select_first');
      return;
    }

    setState(() {
      _isLoading = true;
      _syncStatus = CalendarSyncStatus.syncing;
    });

    final success = await CalendarService.syncAllBirthdays();
    final syncStats = await CalendarService.getSyncStats();
    if (!mounted) return;

    setState(() {
      _syncStatus = CalendarService.syncStatus;
      _syncStats = syncStats;
      _isLoading = false;
    });

    _showSnackBar(success ? 'calendar_sync_success' : 'calendar_sync_partial');
  }

  Future<void> _clearAllEvents() async {
    final l10n = _l10n;
    final errorColor = Theme.of(context).colorScheme.error;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('calendar_clear_dialog_title')),
        content: Text(l10n.translate('calendar_clear_dialog_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.translate('calendar_cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: errorColor),
            child: Text(l10n.translate('calendar_clear_dialog_confirm')),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() {
      _isLoading = true;
    });

    final success = await CalendarService.clearAllBirthdayEvents();
    final syncStats = await CalendarService.getSyncStats();
    if (!mounted) return;

    setState(() {
      _selectedCalendarId = null;
      _syncStatus = CalendarSyncStatus.notConfigured;
      _syncStats = syncStats;
      _isLoading = false;
    });

    if (success) _showSnackBar('calendar_cleared');
  }

  Future<void> _refreshCalendars() async {
    setState(() {
      _isLoading = true;
    });

    await CalendarService.refresh();
    final syncStats = await CalendarService.getSyncStats();
    if (!mounted) return;

    setState(() {
      _availableCalendars = CalendarService.availableCalendars;
      _selectedCalendarId = CalendarService.selectedCalendarId;
      _syncStatus = CalendarService.syncStatus;
      _syncStats = syncStats;
      _isLoading = false;
    });
  }

  Color _getSyncStatusColor() {
    final colorScheme = Theme.of(context).colorScheme;
    switch (_syncStatus) {
      case CalendarSyncStatus.notConfigured:
        return colorScheme.onSurfaceVariant;
      case CalendarSyncStatus.syncing:
        return colorScheme.secondary;
      case CalendarSyncStatus.synced:
        return colorScheme.primary;
      case CalendarSyncStatus.error:
        return colorScheme.error;
    }
  }

  String _getSyncStatusText() => _l10n.translate(CalendarSyncLabels.statusKey(
        _syncStatus,
        calendarSelected: _selectedCalendarName != null,
      ));

  String? get _selectedCalendarName {
    for (final calendar in _availableCalendars) {
      if (calendar.id == _selectedCalendarId) {
        return _displayName(calendar);
      }
    }
    return null;
  }

  String _displayName(Calendar calendar) => calendar.name.trim().isEmpty
      ? _l10n.translate('calendar_unnamed')
      : calendar.name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_l10n.translate('calendar_title')),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshCalendars,
              tooltip: _l10n.translate('calendar_refresh_tooltip'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_hasPermissions) {
      return _CalendarEmptyState(
        icon: Icons.calendar_today_outlined,
        title: _l10n.translate('calendar_permissions_title'),
        body: _l10n.translate('calendar_permissions_body'),
        actionLabel: _l10n.translate('calendar_try_again'),
        onAction: _initializeCalendar,
      );
    }

    if (_availableCalendars.isEmpty) {
      return _CalendarEmptyState(
        icon: Icons.event_busy,
        title: _l10n.translate('calendar_none_title'),
        body: _l10n.translate('calendar_none_body'),
        actionLabel: _l10n.translate('calendar_refresh'),
        onAction: _refreshCalendars,
      );
    }

    return ScrollThread(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          _buildSyncStatusCard(),
          const SizedBox(height: 16),
          _buildStatsCard(),
          const SizedBox(height: 16),
          _buildCalendarSelectionCard(),
          const SizedBox(height: 16),
          _buildActionsCard(),
          const SizedBox(height: 16),
          _buildHelpCard(),
        ],
      ),
    );
  }

  Widget _buildSyncStatusCard() {
    final theme = Theme.of(context);
    final statusColor = _getSyncStatusColor();
    final calendarName = _selectedCalendarName;
    return _SectionCard(
      header: _l10n.translate('calendar_sync_status_header'),
      trailing: _StatusChip(label: _getSyncStatusText(), color: statusColor),
      children: [
        Row(
          children: [
            Icon(Icons.sync, color: statusColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _l10n.translate(
                  CalendarSyncLabels.calendarLineKey(
                    _syncStatus,
                    calendarSelected: calendarName != null,
                  ),
                  replacements: {'name': calendarName ?? ''},
                ),
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsCard() {
    String stat(String key) => _syncStats[key]?.toString() ?? '0';
    return _SectionCard(
      header: _l10n.translate('calendar_stats_header'),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(
              icon: Icons.people_outline,
              value: stat('totalFriends'),
              label: _l10n.translate('calendar_stat_total'),
            ),
            _StatItem(
              icon: Icons.event_available_outlined,
              value: stat('syncedFriends'),
              label: _l10n.translate('calendar_stat_synced'),
            ),
            _StatItem(
              icon: Icons.hourglass_empty,
              value: stat('unsyncedFriends'),
              label: _l10n.translate('calendar_stat_pending'),
            ),
          ],
        ),
        ..._buildSkippedLine(),
      ],
    );
  }

  /// "{n} left out – from your contacts", only when the
  /// [CalendarService.skipImportedContacts] setting leaves someone out
  /// (so People = synced + pending + left out adds up).
  List<Widget> _buildSkippedLine() {
    final skipped = _syncStats['skippedFriends'] ?? 0;
    if (skipped <= 0) return const [];
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return [
      const SizedBox(height: 12),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.contacts_outlined, size: 18, color: muted),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              _l10n.plural('calendar_stat_skipped', skipped),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: muted),
            ),
          ),
        ],
      ),
    ];
  }

  Widget _buildCalendarSelectionCard() {
    return _SectionCard(
      header: _l10n.translate('calendar_select_header'),
      children: [
        RadioGroup<String>(
          groupValue: _selectedCalendarId,
          onChanged: (value) {
            if (value != null) {
              _selectCalendar(value);
            }
          },
          child: Column(
            children: _availableCalendars
                .map((calendar) => RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      title: Text(_displayName(calendar)),
                      subtitle: Text(calendar.accountName ?? _l10n.translate('calendar_local')),
                      value: calendar.id,
                    ))
                .toList(),
          ),
        ),
        _buildSkipContactsSwitch(),
      ],
    );
  }

  Widget _buildSkipContactsSwitch() {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(_l10n.translate('calendar_skip_contacts_title')),
      subtitle: Text(_l10n.translate('calendar_skip_contacts_sub')),
      value: _skipImportedContacts,
      onChanged: _setSkipImportedContacts,
    );
  }

  Widget _buildActionsCard() {
    final colorScheme = Theme.of(context).colorScheme;
    final isSyncing = _syncStatus == CalendarSyncStatus.syncing;
    final hasSyncedEvents = (_syncStats['events'] ?? 0) > 0;
    return _SectionCard(
      header: _l10n.translate('calendar_actions_header'),
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _selectedCalendarId != null && !isSyncing ? _syncAllBirthdays : null,
            icon: isSyncing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            label: Text(_l10n.translate(
                isSyncing ? 'calendar_status_syncing' : 'calendar_sync_all')),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: hasSyncedEvents ? _clearAllEvents : null,
            icon: const Icon(Icons.clear_all),
            label: Text(_l10n.translate('calendar_clear_all')),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.error,
              side: BorderSide(color: colorScheme.error),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHelpCard() {
    final theme = Theme.of(context);
    return _SectionCard(
      header: _l10n.translate('calendar_help_header'),
      children: [
        Text(
          _l10n.translate('calendar_help_body'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

/// Card with an uppercase section label (and optional trailing widget).
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.header,
    required this.children,
    this.trailing,
  });

  final String header;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: SectionLabel(header)),
                ?trailing,
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Column(
      children: [
        Icon(icon, color: muted),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.headlineSmall),
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: muted)),
      ],
    );
  }
}

/// Centered icon, title, explanation and a retry/refresh button.
class _CalendarEmptyState extends StatelessWidget {
  const _CalendarEmptyState({
    required this.icon,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
