import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:memento_mori_life_in_weeks/data/avatar_store.dart';
import 'package:memento_mori_life_in_weeks/security/vault_cipher.dart';

/// A friend photo file sealed by [AvatarStore], decrypted while it loads
/// (never during build).
///
/// Plain image files (written before photos were encrypted) load as they
/// are. A photo that cannot be opened (wrong key, damaged file) fails like
/// any unreadable image, so avatars fall back to their initials through
/// their image error callback.
///
/// Cached by path and scale: every saved photo gets a new, unique file name,
/// so a path never changes its picture.
@immutable
class EncryptedFileImage extends ImageProvider<EncryptedFileImage> {
  const EncryptedFileImage(this.file, {this.scale = 1.0, this.cipher});

  final File file;
  final double scale;

  /// Opens sealed photos; [AvatarStore.configuredCipher] when null.
  final RecordCipher? cipher;

  @override
  Future<EncryptedFileImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<EncryptedFileImage>(this);

  @override
  ImageStreamCompleter loadImage(
    EncryptedFileImage key,
    ImageDecoderCallback decode,
  ) => MultiFrameImageStreamCompleter(
    codec: _loadCodec(key, decode),
    scale: key.scale,
    debugLabel: key.file.path,
    informationCollector: () => [ErrorDescription('Path: ${file.path}')],
  );

  Future<ui.Codec> _loadCodec(
    EncryptedFileImage key,
    ImageDecoderCallback decode,
  ) async {
    final bytes = await AvatarStore.openPhoto(
      key.file.path,
      await key.file.readAsBytes(),
      key.cipher ?? AvatarStore.configuredCipher,
    );
    if (bytes.isEmpty) {
      throw StateError('${key.file.path} is empty and cannot be loaded.');
    }
    return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
  }

  @override
  bool operator ==(Object other) =>
      other is EncryptedFileImage &&
      other.file.path == file.path &&
      other.scale == scale &&
      identical(other.cipher, cipher);

  @override
  int get hashCode => Object.hash(file.path, scale, cipher);

  @override
  String toString() =>
      '${objectRuntimeType(this, 'EncryptedFileImage')}'
      '("${file.path}", scale: ${scale.toStringAsFixed(1)})';
}
