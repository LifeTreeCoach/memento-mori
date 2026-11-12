import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

/// Asks for a birthday without a year (day and month). Returns the date in
/// [Friend.noYearStorageYear] (a leap year, so Feb 29 can be chosen), or
/// null when cancelled.
Future<DateTime?> showDayMonthPicker(
  BuildContext context, {
  DateTime? initialDate,
}) {
  return showDialog<DateTime>(
    context: context,
    builder: (context) => _DayMonthDialog(initialDate: initialDate),
  );
}

/// Days of [month] in the storage leap year.
int daysInStorageMonth(int month) =>
    DateTime(Friend.noYearStorageYear, month + 1, 0).day;

class _DayMonthDialog extends StatefulWidget {
  const _DayMonthDialog({this.initialDate});

  final DateTime? initialDate;

  @override
  State<_DayMonthDialog> createState() => _DayMonthDialogState();
}

class _DayMonthDialogState extends State<_DayMonthDialog> {
  late int _day = widget.initialDate?.day ?? 1;
  late int _month = widget.initialDate?.month ?? 1;

  void _setMonth(int month) => setState(() {
        _month = month;
        final last = daysInStorageMonth(month);
        if (_day > last) _day = last;
      });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final monthNames = DateFormat.MMMM(l10n.locale.languageCode);
    return AlertDialog(
      title: Text(l10n.translate('form_birthday_picker_title')),
      content: Row(
        children: [
          SizedBox(
            width: 88,
            child: DropdownButtonFormField<int>(
              // Rebuilt per month, so a clamped day shows up.
              key: ValueKey(_month),
              initialValue: _day,
              decoration: InputDecoration(
                  labelText: l10n.translate('form_birthday_day')),
              items: [
                for (var d = 1; d <= daysInStorageMonth(_month); d++)
                  DropdownMenuItem(value: d, child: Text('$d')),
              ],
              onChanged: (d) => setState(() => _day = d ?? _day),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<int>(
              initialValue: _month,
              isExpanded: true,
              decoration: InputDecoration(
                  labelText: l10n.translate('form_birthday_month')),
              items: [
                for (var m = 1; m <= 12; m++)
                  DropdownMenuItem(
                    value: m,
                    child: Text(
                      monthNames.format(DateTime(Friend.noYearStorageYear, m)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (m) => _setMonth(m ?? _month),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.translate('people_cancel')),
        ),
        TextButton(
          onPressed: () => Navigator.of(context)
              .pop(DateTime(Friend.noYearStorageYear, _month, _day)),
          child: Text(l10n.translate('form_ok')),
        ),
      ],
    );
  }
}
