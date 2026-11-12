import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../localization.dart';
import '../birthday_text_parser.dart';

/// Optional birth year typed in for a candidate without one. Reports a
/// valid year (real date, not in the future, from [earliestBirthYear] on)
/// or null when empty; shows an error for anything else.
class ImportYearField extends StatefulWidget {
  const ImportYearField({
    super.key,
    required this.month,
    required this.day,
    required this.initialYear,
    required this.onChanged,
    this.today,
  });

  final int month;
  final int day;
  final int? initialYear;
  final ValueChanged<int?> onChanged;
  final DateTime? today;

  @override
  State<ImportYearField> createState() => _ImportYearFieldState();
}

class _ImportYearFieldState extends State<ImportYearField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialYear?.toString() ?? '',
  );
  bool _invalid = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    final year = _validYear(text);
    final invalid = text.length == 4 && year == null;
    if (invalid != _invalid) setState(() => _invalid = invalid);
    widget.onChanged(year);
  }

  int? _validYear(String text) {
    if (text.length != 4) return null;
    final year = int.tryParse(text);
    if (year == null) return null;
    final date = birthdayFromParts(
      year: year,
      month: widget.month,
      day: widget.day,
      today: widget.today,
    );
    return date?.year;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: 160,
      child: TextField(
        controller: _controller,
        autofocus: widget.initialYear == null,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(4),
        ],
        onChanged: _onChanged,
        decoration: InputDecoration(
          isDense: true,
          labelText: l10n.translate('import_year_label'),
          hintText: l10n.translate('import_year_hint'),
          errorText: _invalid ? l10n.translate('import_year_invalid') : null,
        ),
      ),
    );
  }
}
