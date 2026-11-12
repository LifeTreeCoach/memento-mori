import 'package:flutter/material.dart';

import '../../localization.dart';
import '../../people/people_section_header.dart';
import '../import_matcher.dart';
import 'candidate_avatar.dart';
import 'import_candidate_row.dart';
import 'import_review_model.dart';

/// The review sections as one lazy sliver: New, Different date, Add year
/// and Already there (collapsed). Only rows on screen are built.
class ImportReviewList extends StatelessWidget {
  const ImportReviewList({
    super.key,
    required this.model,
    required this.photos,
    this.today,
  });

  final ImportReviewModel model;
  final CandidatePhotoCache photos;
  final DateTime? today;

  static const _order = [
    MatchStatus.newPerson,
    MatchStatus.dateDiffers,
    MatchStatus.yearAddable,
    MatchStatus.alreadyThere,
  ];

  @override
  Widget build(BuildContext context) {
    final entries = _entries();
    if (entries.isEmpty) return _noMatch(context);
    return SliverList.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) => _build(context, entries[index]),
    );
  }

  List<Object> _entries() {
    final entries = <Object>[];
    for (final status in _order) {
      final matches = model.visible(status);
      if (matches.isEmpty) continue;
      entries.add((status, matches.length));
      if (status == MatchStatus.alreadyThere && !model.showAlreadyThere) {
        continue;
      }
      if (status == MatchStatus.dateDiffers) entries.add(_hintKey);
      entries.addAll(matches);
    }
    return entries;
  }

  static const _hintKey = 'import_section_date_differs_hint';

  Widget _build(BuildContext context, Object entry) {
    if (entry case (MatchStatus status, int count)) {
      return _header(context, status, count);
    }
    if (entry is CandidateMatch) {
      return ImportCandidateRow(
        key: ValueKey('import-row-${entry.candidate.id}'),
        match: entry,
        model: model,
        photos: photos,
        today: today,
      );
    }
    return _hint(context);
  }

  Widget _header(BuildContext context, MatchStatus status, int count) {
    final l10n = AppLocalizations.of(context);
    final label = l10n.translate(_labelKey(status));
    if (status != MatchStatus.alreadyThere) {
      return PeopleSectionHeader(label: '$label · $count');
    }
    return InkWell(
      key: const ValueKey('import-already-toggle'),
      onTap: model.toggleAlreadyThere,
      child: PeopleSectionHeader(
        label: '$label · $count',
        trailing: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Icon(
            model.showAlreadyThere ? Icons.expand_less : Icons.expand_more,
          ),
        ),
      ),
    );
  }

  static String _labelKey(MatchStatus status) => switch (status) {
    MatchStatus.newPerson => 'import_section_new',
    MatchStatus.dateDiffers => 'import_section_date_differs',
    MatchStatus.yearAddable => 'import_section_year',
    MatchStatus.alreadyThere => 'import_section_already',
  };

  Widget _hint(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      child: Text(
        AppLocalizations.of(context).translate(_hintKey),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _noMatch(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          AppLocalizations.of(context).translate('import_no_match'),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
