import 'dart:io';

import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/data/avatar_store.dart';
import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/theme/life_palette.dart';

/// A friend's photo, or their initials on a softly tinted circle.
/// [highlight] tints the circle with the amber accent (birthday today).
class FriendAvatar extends StatelessWidget {
  const FriendAvatar({
    super.key,
    required this.friend,
    this.radius = 22,
    this.highlight = false,
  });

  final Friend friend;
  final double radius;
  final bool highlight;

  /// Up to two initials ("Anna Maria Lopez" -> "AL").
  static String initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    final first = parts.first.characters.first;
    if (parts.length == 1) return first.toUpperCase();
    return (first + parts.last.characters.first).toUpperCase();
  }

  /// Photo at [path] (resolved by [AvatarStore.resolve], so photos survive
  /// a moved app container), or null when none is set. A missing or unreadable
  /// file is handled by the avatar's image error callback, so build never
  /// touches the file system synchronously.
  static ImageProvider? photoAt(String? path) {
    final resolved = AvatarStore.resolve(path);
    if (resolved == null) return null;
    return FileImage(File(resolved));
  }

  /// Like [photoAt], but decoded at [diameter] logical pixels times
  /// [devicePixelRatio] instead of the photo's full resolution, which
  /// keeps long lists of avatars light on memory.
  static ImageProvider? photoSizedAt(
    String? path, {
    required double diameter,
    required double devicePixelRatio,
  }) {
    final photo = photoAt(path);
    if (photo == null) return null;
    // Width only: the height follows the aspect ratio; `fit` never
    // upscales photos that are already small.
    return ResizeImage(
      photo,
      width: (diameter * devicePixelRatio).round(),
      policy: ResizeImagePolicy.fit,
    );
  }

  /// Keeps the fallback (initials/icon) visible when the photo can't load.
  static void ignorePhotoError(Object error, StackTrace? stackTrace) {}

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = LifePalette.of(context).accent;
    final tint = highlight ? accent : scheme.onSurfaceVariant;
    final photo = photoSizedAt(
      friend.avatarPath,
      diameter: radius * 2,
      devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
    );
    return CircleAvatar(
      radius: radius,
      backgroundColor: tint.withValues(alpha: highlight ? 0.22 : 0.14),
      foregroundImage: photo,
      onForegroundImageError: photo != null ? ignorePhotoError : null,
      child: Text(
        initialsOf(friend.name),
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: highlight ? accent : scheme.onSurface,
              fontSize: radius * 0.72,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
