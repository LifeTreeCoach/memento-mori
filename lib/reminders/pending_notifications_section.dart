import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/reminders/notification_service.dart';

/// Loads the notifications the system still has scheduled.
typedef PendingNotificationsLoader = Future<List<PendingNotificationRequest>>
    Function();

Future<List<PendingNotificationRequest>> _loadFromPlugin() =>
    NotificationService.plugin.pendingNotificationRequests();

/// Diagnostics: every pending notification (sorted by id), refreshable.
class PendingNotificationsSection extends StatefulWidget {
  const PendingNotificationsSection({super.key, this.load = _loadFromPlugin});

  final PendingNotificationsLoader load;

  @override
  State<PendingNotificationsSection> createState() =>
      _PendingNotificationsSectionState();
}

class _PendingNotificationsSectionState
    extends State<PendingNotificationsSection> {
  late Future<List<PendingNotificationRequest>> _pending = _loadSorted();

  Future<List<PendingNotificationRequest>> _loadSorted() async {
    final pending = [...await widget.load()];
    pending.sort((a, b) => a.id.compareTo(b.id));
    return pending;
  }

  void _refresh() {
    final next = _loadSorted();
    setState(() {
      _pending = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PendingNotificationRequest>>(
      future: _pending,
      builder: (context, snapshot) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(count: snapshot.data?.length, onRefresh: _refresh),
          ..._body(context, snapshot),
        ],
      ),
    );
  }

  List<Widget> _body(BuildContext context,
      AsyncSnapshot<List<PendingNotificationRequest>> snapshot) {
    final l10n = AppLocalizations.of(context);
    if (snapshot.hasError) {
      return [_Note(l10n.translate('diagnostics_pending_error'))];
    }
    final pending = snapshot.data;
    if (pending == null) return const [LinearProgressIndicator()];
    if (pending.isEmpty) {
      return [_Note(l10n.translate('diagnostics_pending_empty'))];
    }
    return [for (final request in pending) _PendingTile(request: request)];
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.count, required this.onRefresh});

  final int? count;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = l10n.translate('diagnostics_pending_title');
    return ListTile(
      title: Text(
        count == null ? title : '$title ($count)',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.refresh),
        tooltip: l10n.translate('diagnostics_pending_refresh'),
        onPressed: onRefresh,
      ),
    );
  }
}

class _PendingTile extends StatelessWidget {
  const _PendingTile({required this.request});

  final PendingNotificationRequest request;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = request.title ?? l10n.translate('diagnostics_pending_untitled');
    final payload = request.payload;
    final details = [
      if (request.body?.isNotEmpty ?? false) request.body!,
      if (payload != null && payload.isNotEmpty)
        l10n.translate('diagnostics_pending_payload',
            replacements: {'payload': payload}),
    ];
    return ListTile(
      dense: true,
      leading: Text('#${request.id}'),
      title: Text(title),
      subtitle: details.isEmpty ? null : Text(details.join('\n')),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}
