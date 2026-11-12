import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/people/sheet_title.dart';
import 'package:memento_mori_life_in_weeks/widgets/scroll_thread.dart';

/// Shows a scroll-controlled Compass sheet that moves above the keyboard.
Future<T?> showCompassSheet<T>(BuildContext context, WidgetBuilder builder) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: builder,
  );
}

/// Title, scrollable form fields and Cancel / Save of a Compass sheet.
class CompassSheetFrame extends StatelessWidget {
  const CompassSheetFrame({
    super.key,
    required this.title,
    required this.formKey,
    required this.children,
    required this.onSave,
  });

  final String title;
  final GlobalKey<FormState> formKey;
  final List<Widget> children;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: insets),
      child: ScrollThread(
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SheetTitle(title),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                  ),
                ),
                _buttons(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buttons(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: OverflowBar(
        alignment: MainAxisAlignment.end,
        spacing: 8,
        overflowSpacing: 8,
        overflowAlignment: OverflowBarAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.translate('compass_cancel')),
          ),
          FilledButton(
            key: const ValueKey('compass_sheet_save'),
            onPressed: onSave,
            child: Text(l10n.translate('compass_save')),
          ),
        ],
      ),
    );
  }
}
