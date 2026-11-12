import 'package:flutter/material.dart';

import '../../localization.dart';
import '../../widgets/scroll_thread.dart';
import '../import_applier.dart';
import 'candidate_avatar.dart';
import 'import_review_header.dart';
import 'import_review_list.dart';
import 'import_review_model.dart';
import 'import_review_options.dart';

/// The review list with its header, options and the "Add 38 people"
/// button; rebuilt whenever [model] changes.
class ImportReviewBody extends StatefulWidget {
  const ImportReviewBody({
    super.key,
    required this.model,
    required this.found,
    required this.existingGroups,
    required this.applying,
    required this.onApply,
    required this.onOpenSettings,
    this.today,
  });

  final ImportReviewModel model;
  final ImportFound found;
  final List<String> existingGroups;
  final bool applying;
  final VoidCallback onApply;
  final VoidCallback onOpenSettings;
  final DateTime? today;

  @override
  State<ImportReviewBody> createState() => _ImportReviewBodyState();
}

class _ImportReviewBodyState extends State<ImportReviewBody> {
  final _search = TextEditingController();
  final _group = TextEditingController();
  final _photos = CandidatePhotoCache();

  @override
  void initState() {
    super.initState();
    _search.addListener(() => widget.model.search = _search.text);
    _group.addListener(() => widget.model.setGroupName(_group.text));
  }

  @override
  void dispose() {
    _search.dispose();
    _group.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.model,
      builder: (context, _) => Column(
        children: [
          Expanded(child: _scrollView()),
          _bottomBar(context),
        ],
      ),
    );
  }

  Widget _scrollView() {
    final model = widget.model;
    return ScrollThread(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: ImportReviewHeader(
              model: model,
              found: widget.found,
              searchController: _search,
              onOpenSettings: widget.onOpenSettings,
            ),
          ),
          if (model.hasSelectable)
            SliverToBoxAdapter(
              child: ImportReviewOptions(
                model: model,
                groupController: _group,
                existingGroups: widget.existingGroups,
              ),
            ),
          ImportReviewList(model: model, photos: _photos, today: widget.today),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }

  Widget _bottomBar(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final model = widget.model;
    final count = model.selectedCount;
    final String label;
    final VoidCallback? onPressed;
    if (!model.hasSelectable) {
      label = l10n.translate('import_done');
      onPressed = () => Navigator.of(context).pop(_nothing);
    } else {
      label = l10n.plural('import_apply', count);
      onPressed = count == 0 || widget.applying ? null : widget.onApply;
    }
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: const ValueKey('import-apply'),
            onPressed: onPressed,
            child: widget.applying
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(label, textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }

  static const _nothing = ImportOutcome(addedIds: [], previous: []);
}
