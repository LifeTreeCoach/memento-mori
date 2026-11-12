import 'package:flutter/material.dart';

import '../../friend_form/group_field.dart';
import '../../localization.dart';
import 'import_review_model.dart';

/// "Import photos" (when any candidate has one) and an optional group for
/// every new person, reusing the friend form's group field.
class ImportReviewOptions extends StatelessWidget {
  const ImportReviewOptions({
    super.key,
    required this.model,
    required this.groupController,
    required this.existingGroups,
  });

  final ImportReviewModel model;
  final TextEditingController groupController;
  final List<String> existingGroups;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        if (model.hasPhotos)
          SwitchListTile(
            key: const ValueKey('import-photos-switch'),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            secondary: const Icon(Icons.photo_outlined),
            title: Text(l10n.translate('import_photos')),
            value: model.importPhotos,
            onChanged: model.setImportPhotos,
          ),
        ExpansionTile(
          key: const ValueKey('import-group-tile'),
          tilePadding: const EdgeInsets.symmetric(horizontal: 20),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          leading: const Icon(Icons.group_outlined),
          title: Text(l10n.translate('import_group')),
          subtitle: model.groupName.trim().isEmpty
              ? null
              : Text(model.groupName.trim()),
          children: [
            GroupField(
              controller: groupController,
              existingGroups: existingGroups,
              // The review body listens to the controller.
              onGroupSelected: (group) => groupController.text = group,
            ),
          ],
        ),
      ],
    );
  }
}
