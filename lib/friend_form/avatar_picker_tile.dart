import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/people/friend_avatar.dart';

/// Tappable photo circle with an "Add photo" / "Change photo" label.
class AvatarPickerTile extends StatelessWidget {
  const AvatarPickerTile({
    super.key,
    required this.avatarPath,
    required this.onTap,
  });

  final String? avatarPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final photo = FriendAvatar.photoAt(avatarPath);
    final labelKey = avatarPath != null
        ? 'form_photo_change'
        : 'form_photo_add';
    return Center(
      child: Column(
        children: [
          InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: CircleAvatar(
              radius: 40,
              backgroundColor: scheme.surfaceContainerHigh,
              foregroundImage: photo,
              onForegroundImageError:
                  photo != null ? FriendAvatar.ignorePhotoError : null,
              child: Icon(
                Icons.person_outline,
                size: 36,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.photo_camera_outlined, size: 18),
            label: Text(AppLocalizations.of(context).translate(labelKey)),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet offering gallery, camera and (when set) removal.
class AvatarOptionsSheet extends StatelessWidget {
  const AvatarOptionsSheet({
    super.key,
    required this.hasPhoto,
    required this.onGallery,
    required this.onCamera,
    required this.onRemove,
  });

  final bool hasPhoto;
  final VoidCallback onGallery;
  final VoidCallback onCamera;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final error = theme.colorScheme.error;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Text(
              l10n.translate('form_photo_sheet_title'),
              style: theme.textTheme.titleLarge,
            ),
          ),
          _option(
            context,
            Icons.photo_library_outlined,
            'form_photo_gallery',
            onGallery,
          ),
          _option(
            context,
            Icons.photo_camera_outlined,
            'form_photo_camera',
            onCamera,
          ),
          if (hasPhoto)
            _option(
              context,
              Icons.delete_outline,
              'form_photo_remove',
              onRemove,
              color: error,
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _option(
    BuildContext context,
    IconData icon,
    String labelKey,
    VoidCallback action, {
    Color? color,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: Icon(icon, color: color),
      title: Text(
        AppLocalizations.of(context).translate(labelKey),
        style: TextStyle(color: color),
      ),
      onTap: () {
        Navigator.pop(context);
        action();
      },
    );
  }
}
