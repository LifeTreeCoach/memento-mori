import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../people/friend_avatar.dart';
import '../birthday_candidate.dart';

/// Loads each candidate's photo at most once per review; rows only ask
/// when they are built, so off-screen thumbnails are never read.
class CandidatePhotoCache {
  final Map<String, Future<Uint8List?>> _photos = {};

  Future<Uint8List?>? photoOf(BirthdayCandidate candidate) {
    final photo = candidate.photo;
    if (photo == null) return null;
    return _photos.putIfAbsent(candidate.id, () => _safeLoad(photo));
  }

  static Future<Uint8List?> _safeLoad(CandidatePhoto photo) async {
    try {
      return await photo.load();
    } catch (_) {
      return null;
    }
  }
}

/// A candidate's thumbnail (decoded at display size) or their initials.
class CandidateAvatar extends StatelessWidget {
  const CandidateAvatar({
    super.key,
    required this.candidate,
    required this.cache,
    this.radius = 20,
  });

  final BirthdayCandidate candidate;
  final CandidatePhotoCache cache;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final future = cache.photoOf(candidate);
    if (future == null) return _circle(context, null);
    return FutureBuilder<Uint8List?>(
      future: future,
      builder: (context, snapshot) => _circle(context, snapshot.data),
    );
  }

  Widget _circle(BuildContext context, Uint8List? bytes) {
    final scheme = Theme.of(context).colorScheme;
    final size = (radius * 2 * MediaQuery.devicePixelRatioOf(context)).round();
    return CircleAvatar(
      radius: radius,
      backgroundColor: scheme.onSurfaceVariant.withValues(alpha: 0.14),
      foregroundImage: bytes == null
          ? null
          : ResizeImage(
              MemoryImage(bytes),
              width: size,
              policy: ResizeImagePolicy.fit,
            ),
      onForegroundImageError: bytes == null
          ? null
          : FriendAvatar.ignorePhotoError,
      child: Text(
        FriendAvatar.initialsOf(candidate.displayName),
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: scheme.onSurface,
          fontSize: radius * 0.72,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
