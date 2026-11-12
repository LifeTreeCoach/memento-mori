import 'package:flutter/material.dart';

import '../../localization.dart';
import '../birthday_candidate.dart';
import '../import_matcher.dart';
import 'candidate_avatar.dart';
import 'import_review_model.dart';
import 'import_year_field.dart';
import 'no_year_badge.dart';

/// One candidate in the review list: tick box, photo, name and birthday
/// ("old → new" for a differing date), plus "no year" with an optional
/// year field; once a valid year is typed, the date shows it instead of
/// the "no year" badge. "Already there" rows cannot be ticked.
class ImportCandidateRow extends StatefulWidget {
  const ImportCandidateRow({
    super.key,
    required this.match,
    required this.model,
    required this.photos,
    this.today,
  });

  final CandidateMatch match;
  final ImportReviewModel model;
  final CandidatePhotoCache photos;
  final DateTime? today;

  @override
  State<ImportCandidateRow> createState() => _ImportCandidateRowState();
}

class _ImportCandidateRowState extends State<ImportCandidateRow> {
  late bool _editingYear =
      widget.model.yearFor(widget.match.candidate.id) != null;

  BirthdayCandidate get _candidate => widget.match.candidate;

  bool get _selectable => widget.match.status != MatchStatus.alreadyThere;

  @override
  Widget build(BuildContext context) {
    final selected = widget.model.isSelected(_candidate.id);
    return InkWell(
      onTap: _selectable ? () => widget.model.toggle(widget.match) : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 20, 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: _selectable && selected,
              onChanged: _selectable
                  ? (_) => widget.model.toggle(widget.match)
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 12),
              child: CandidateAvatar(
                candidate: _candidate,
                cache: widget.photos,
              ),
            ),
            Expanded(child: _texts(context)),
          ],
        ),
      ),
    );
  }

  Widget _texts(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_candidate.displayName, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 2),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                _dateText(AppLocalizations.of(context)),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (_offersYear && _enteredYear == null)
                NoYearBadge(onTap: _openYear),
            ],
          ),
          if (_editingYear && _offersYear) _yearField(),
        ],
      ),
    );
  }

  bool get _offersYear => _selectable && !_candidate.hasYear;

  /// The valid year typed into the year field, if any.
  int? get _enteredYear => widget.model.yearFor(_candidate.id);

  void _openYear() => setState(() => _editingYear = true);

  Widget _yearField() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: ImportYearField(
        month: _candidate.month,
        day: _candidate.day,
        initialYear: widget.model.yearFor(_candidate.id),
        today: widget.today,
        onChanged: (year) => widget.model.setYear(_candidate.id, year),
      ),
    );
  }

  String _dateText(AppLocalizations l10n) {
    final date = _format(
      l10n,
      _candidate.month,
      _candidate.day,
      _candidate.year ?? _enteredYear,
    );
    final existing = widget.match.existing;
    if (widget.match.status != MatchStatus.dateDiffers || existing == null) {
      return date;
    }
    final old = _format(l10n, existing.month, existing.day, existing.year);
    return '$old → $date';
  }

  static String _format(AppLocalizations l10n, int month, int day, int? year) {
    return year == null
        ? l10n.dayMonthFormat.format(DateTime(2000, month, day))
        : l10n.shortDateFormat.format(DateTime(year, month, day));
  }
}
