import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/people/sheet_title.dart';
import 'package:memento_mori_life_in_weeks/widgets/scroll_thread.dart';

/// One selectable value of a [ChoiceTile].
class SettingsOption<T> {
  const SettingsOption(this.value, this.label, {this.preview});

  final T value;
  final String label;

  /// Optional small visual shown next to the label (e.g. colour swatches).
  final Widget? preview;
}

/// Settings row showing the current choice as its subtitle; tapping opens a
/// bottom sheet listing all [options].
class ChoiceTile<T> extends StatelessWidget {
  const ChoiceTile({
    super.key,
    required this.icon,
    required this.title,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final List<SettingsOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;

  SettingsOption<T>? get _current {
    for (final option in options) {
      if (option.value == selected) return option;
    }
    return null;
  }

  Future<void> _pick(BuildContext context) async {
    final picked = await showChoiceSheet<T>(
      context,
      title: title,
      options: options,
      selected: selected,
    );
    if (picked != null && picked != selected) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final current = _current;
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: current == null ? null : Text(current.label),
      trailing: current?.preview,
      onTap: () => _pick(context),
    );
  }
}

/// Bottom sheet with one radio row per option; resolves to the picked value.
Future<T?> showChoiceSheet<T>(
  BuildContext context, {
  required String title,
  required List<SettingsOption<T>> options,
  required T selected,
}) {
  return showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => _ChoiceSheet<T>(
      title: title,
      options: options,
      selected: selected,
      onPicked: (value) => Navigator.pop(sheetContext, value),
    ),
  );
}

class _ChoiceSheet<T> extends StatelessWidget {
  const _ChoiceSheet({
    required this.title,
    required this.options,
    required this.selected,
    required this.onPicked,
  });

  final String title;
  final List<SettingsOption<T>> options;
  final T selected;
  final ValueChanged<T> onPicked;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetTitle(title),
          Flexible(
            child: ScrollThread(
              child: SingleChildScrollView(
                child: RadioGroup<T>(
                  groupValue: selected,
                  onChanged: (value) => onPicked(value as T),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [for (final option in options) _row(option)],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _row(SettingsOption<T> option) {
    return ListTile(
      contentPadding: const EdgeInsetsDirectional.only(start: 12, end: 24),
      leading: Radio<T>(value: option.value),
      title: Text(option.label),
      trailing: option.preview,
      onTap: () => onPicked(option.value),
    );
  }
}
