import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/onboarding/step_layout.dart';
import 'package:memento_mori_life_in_weeks/theme/life_palette.dart';

/// Why the data is locked, which decides the way out.
enum LockedDataReason {
  /// Probably passes (key store or storage not readable right now, e.g.
  /// before the first unlock): only "Try again" and the unlock/restart hint.
  unavailable,

  /// Can't be opened with this device's key (wrong, missing or unusable key,
  /// damaged data): "Try again" and, after a confirmation, "Start fresh".
  locked,
}

/// Shown instead of the app when the encrypted personal data cannot be
/// opened: explains calmly that nothing was deleted and offers "Try again"
/// or, for [LockedDataReason.locked] and after a confirmation, "Start fresh".
class LockedDataScreen extends StatefulWidget {
  const LockedDataScreen({
    super.key,
    required this.reason,
    required this.onTryAgain,
    required this.onStartFresh,
  });

  /// The reason when the screen opened; "Try again" may change it.
  final LockedDataReason reason;

  /// Opens the data again; null when it worked (the app then takes over),
  /// else why it is still locked.
  final Future<LockedDataReason?> Function() onTryAgain;

  /// Deletes the locked data and starts the app empty; throws on failure.
  final Future<void> Function() onStartFresh;

  @override
  State<LockedDataScreen> createState() => _LockedDataScreenState();
}

class _LockedDataScreenState extends State<LockedDataScreen> {
  bool _busy = false;
  late LockedDataReason _reason = widget.reason;

  /// Outcome of the last action, shown in the text (a snack bar would
  /// cover "Start fresh").
  String? _messageKey;

  Future<void> _run(Future<String?> Function() action) async {
    setState(() {
      _busy = true;
      _messageKey = null;
    });
    String? messageKey;
    try {
      messageKey = await action();
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _messageKey = messageKey;
        });
      }
    }
  }

  Future<void> _tryAgain() => _run(() async {
    final reason = await widget.onTryAgain();
    if (reason == null) return null;
    if (mounted) setState(() => _reason = reason);
    return 'vault_still_locked';
  });

  Future<void> _startFresh() async {
    if (!await _confirmStartFresh()) return;
    await _run(() async {
      try {
        await widget.onStartFresh();
        return null;
      } catch (error) {
        debugPrint('LockedDataScreen: start fresh failed (${error.runtimeType})');
        return 'vault_start_fresh_failed';
      }
    });
  }

  Future<bool> _confirmStartFresh() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const StartFreshDialog(),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final secondaryText = theme.textTheme.bodyLarge?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final mayStartFresh = _reason == LockedDataReason.locked;
    return Scaffold(
      body: SafeArea(
        child: StepLayout(
          action: FilledButton(
            onPressed: _busy ? null : _tryAgain,
            child: Text(l10n.translate('vault_try_again')),
          ),
          secondaryAction: mayStartFresh
              ? TextButton(
                  onPressed: _busy ? null : _startFresh,
                  child: Text(l10n.translate('vault_start_fresh')),
                )
              : null,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Icon(
                Icons.lock_outline,
                size: 32,
                color: LifePalette.of(context).accent,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.translate('vault_locked_title'),
              style: theme.textTheme.headlineLarge,
            ),
            const SizedBox(height: 12),
            Text(l10n.translate('vault_locked_body'), style: secondaryText),
            const SizedBox(height: 16),
            Text(
              l10n.translate('vault_locked_nothing_deleted'),
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.translate(
                mayStartFresh
                    ? 'vault_locked_unlock_hint'
                    : 'vault_unavailable_hint',
              ),
              style: secondaryText,
            ),
            if (_messageKey case final key?) ...[
              const SizedBox(height: 24),
              Semantics(
                liveRegion: true,
                child: Text(
                  l10n.translate(key),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Confirms "Start fresh": pops true only for the destructive choice.
class StartFreshDialog extends StatelessWidget {
  const StartFreshDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(l10n.translate('vault_start_fresh_title')),
      content: SingleChildScrollView(
        child: Text(l10n.translate('vault_start_fresh_body')),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.translate('vault_start_fresh_cancel')),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: colors.error),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.translate('vault_start_fresh_confirm')),
        ),
      ],
    );
  }
}
