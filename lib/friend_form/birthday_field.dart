import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/friend_detail/friend_text.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

/// The form's birthday: the chosen date (with the age, or day and month
/// only) and a "Year unknown" switch below it.
class BirthdayField extends StatelessWidget {
  const BirthdayField({
    super.key,
    required this.birthDate,
    required this.yearUnknown,
    required this.onTap,
    required this.onYearUnknownChanged,
  });

  /// Null until chosen; only day and month count while [yearUnknown].
  final DateTime? birthDate;
  final bool yearUnknown;
  final VoidCallback onTap;
  final ValueChanged<bool> onYearUnknownChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: l10n.translate('form_birthday_label'),
              prefixIcon: const Icon(Icons.cake_outlined),
              suffixIcon: const Icon(Icons.calendar_today_outlined),
            ),
            child: Text(_value(l10n)),
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: yearUnknown,
          onChanged: onYearUnknownChanged,
          title: Text(l10n.translate('form_birthday_year_unknown')),
        ),
      ],
    );
  }

  String _value(AppLocalizations l10n) {
    final date = birthDate;
    if (date == null) return l10n.translate('form_birthday_pick');
    if (yearUnknown) return l10n.dayMonthFormat.format(date);
    final text = FriendText(l10n);
    return '${text.date(date)} · '
        '${text.age(Friend.ageOn(date, DateTime.now()))}';
  }
}
