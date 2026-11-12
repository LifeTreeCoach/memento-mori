/// Shrinking imported photos to avatar size before they are saved.
library;

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import '../data/backup_avatar.dart';

/// Longest side of a saved imported photo (the size picked photos get).
const int importPhotoMaxSide = 300;

/// Turns source photo bytes into the bytes to save; null = no photo.
typedef ImportPhotoResizer = Future<Uint8List?> Function(Uint8List bytes);

/// [bytes] scaled down so the longer side is at most [maxSide] (PNG, the
/// only format the engine encodes); smaller photos are kept as they are.
/// Null for empty, oversized (> [BackupAvatar.maxBytes]), unknown or
/// undecodable images.
Future<Uint8List?> resizeImportPhoto(
  Uint8List bytes, {
  int maxSide = importPhotoMaxSide,
}) async {
  if (bytes.isEmpty || bytes.length > BackupAvatar.maxBytes) return null;
  if (BackupAvatar.sniffMime(bytes) == null) return null;
  try {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    buffer.dispose();
    try {
      return await _scaled(descriptor, bytes, maxSide);
    } finally {
      descriptor.dispose();
    }
  } catch (e) {
    debugPrint('Imported photo not decoded: $e');
    return null;
  }
}

Future<Uint8List?> _scaled(
  ui.ImageDescriptor descriptor,
  Uint8List original,
  int maxSide,
) async {
  final width = descriptor.width, height = descriptor.height;
  if (width <= maxSide && height <= maxSide) return original;
  final landscape = width >= height;
  final codec = await descriptor.instantiateCodec(
    targetWidth: landscape ? maxSide : null,
    targetHeight: landscape ? null : maxSide,
  );
  try {
    final image = (await codec.getNextFrame()).image;
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data?.buffer.asUint8List();
  } finally {
    codec.dispose();
  }
}
