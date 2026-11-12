/// Reading the thumbnails of a set of device contacts in batches.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

/// Reads the contacts with these ids (only the thumbnail property).
typedef ContactsByIds = Future<List<Contact>> Function(List<String> ids);

/// The thumbnails of the contacts that have one. `flutter_contacts` only
/// knows whether a contact has a photo when the thumbnail is read, so this
/// is how photo presence is found out: one query per [batchSize] ids (the
/// plugin puts every id into one SQL `IN (...)`, and older Android SQLite
/// builds allow at most 999 parameters). Thumbnails are small (Android
/// 96 px, iOS a few dozen KB at most), so the bytes are kept instead of
/// being read a second time.
class ContactThumbnails {
  const ContactThumbnails({
    this.readContacts = _readThumbnails,
    this.batchSize = 200,
  });

  final ContactsByIds readContacts;
  final int batchSize;

  /// Thumbnail bytes by contact id; contacts without a photo are missing.
  /// A failing batch only loses its photos.
  Future<Map<String, Uint8List>> read(List<String> contactIds) async {
    final thumbnails = <String, Uint8List>{};
    for (var start = 0; start < contactIds.length; start += batchSize) {
      final end = (start + batchSize).clamp(0, contactIds.length);
      thumbnails.addAll(await _readBatch(contactIds.sublist(start, end)));
    }
    return thumbnails;
  }

  Future<Map<String, Uint8List>> _readBatch(List<String> ids) async {
    try {
      return {
        for (final contact in await readContacts(ids))
          if (contact.id != null && _hasBytes(contact.photo?.thumbnail))
            contact.id!: contact.photo!.thumbnail!,
      };
    } catch (e) {
      debugPrint('Contact photos not read (${ids.length} contacts): $e');
      return const {};
    }
  }

  static bool _hasBytes(Uint8List? bytes) => bytes != null && bytes.isNotEmpty;

  static Future<List<Contact>> _readThumbnails(List<String> ids) =>
      FlutterContacts.getAll(
        properties: const {ContactProperty.photoThumbnail},
        filter: ContactFilter.ids(ids),
      );
}
