import 'dart:convert';

import 'package:flutter/foundation.dart';

/// A friend's photo embedded in a backup as
/// `"avatar": {"mime": "image/jpeg", "data": "<base64>"}`.
///
/// The type is taken from the image bytes, not from the declared `mime`,
/// so only real JPEG/PNG/WebP/GIF images are ever written to disk.
@immutable
class BackupAvatar {
  const BackupAvatar._(this.mime, this.bytes);

  /// Backup entry key of the embedded photo.
  static const String key = 'avatar';

  /// Photos larger than this are neither exported nor imported (picked
  /// photos are downscaled to 300x300, i.e. a few dozen KB).
  static const int maxBytes = 2 * 1024 * 1024;

  static const Map<String, String> _extensions = {
    'image/jpeg': 'jpg',
    'image/png': 'png',
    'image/webp': 'webp',
    'image/gif': 'gif',
  };

  final String mime;
  final Uint8List bytes;

  /// File extension for [mime].
  String get extension => _extensions[mime]!;

  /// The photo in [bytes]; null when empty, too large or not an image.
  static BackupAvatar? fromBytes(Uint8List bytes) {
    if (bytes.isEmpty || bytes.length > maxBytes) return null;
    final mime = sniffMime(bytes);
    return mime == null ? null : BackupAvatar._(mime, bytes);
  }

  /// The photo of a backup entry's `avatar` value; null when it is missing
  /// or corrupt (bad base64, not an image, too large).
  static BackupAvatar? fromJson(Object? json) {
    if (json is! Map || json['data'] is! String) return null;
    final data = json['data'] as String;
    // Base64 is 4/3 the size; reject huge strings before decoding them.
    if (data.length > maxBytes * 4 ~/ 3 + 4) return null;
    try {
      return fromBytes(base64Decode(data));
    } on FormatException {
      return null;
    }
  }

  Map<String, String> toJson() => {'mime': mime, 'data': base64Encode(bytes)};

  /// Image type from the file signature, or null if it is none of the
  /// supported ones.
  static String? sniffMime(List<int> bytes) {
    bool startsWith(List<int> signature, [int offset = 0]) {
      if (bytes.length < offset + signature.length) return false;
      for (var i = 0; i < signature.length; i++) {
        if (bytes[offset + i] != signature[i]) return false;
      }
      return true;
    }

    if (startsWith(const [0xFF, 0xD8, 0xFF])) return 'image/jpeg';
    if (startsWith(const [0x89, 0x50, 0x4E, 0x47])) return 'image/png';
    if (startsWith(const [0x47, 0x49, 0x46, 0x38])) return 'image/gif';
    if (startsWith(ascii.encode('RIFF')) && startsWith(ascii.encode('WEBP'), 8)) {
      return 'image/webp';
    }
    return null;
  }
}
