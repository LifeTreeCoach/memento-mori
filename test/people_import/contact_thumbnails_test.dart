import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/people_import/contact_thumbnails.dart';

Contact _contact(String id, List<int>? thumbnail) => Contact(
  id: id,
  photo: thumbnail == null
      ? null
      : Photo(thumbnail: Uint8List.fromList(thumbnail)),
);

void main() {
  test('keeps only contacts with thumbnail bytes, in batches', () async {
    final batches = <List<String>>[];
    final thumbnails = ContactThumbnails(
      batchSize: 2,
      readContacts: (ids) async {
        batches.add(ids);
        return [
          for (final id in ids)
            _contact(id, switch (id) {
              'a' => [1],
              'c' => const [],
              'e' => [5],
              _ => null,
            }),
        ];
      },
    );

    final result = await thumbnails.read(['a', 'b', 'c', 'd', 'e']);

    expect(batches, [
      ['a', 'b'],
      ['c', 'd'],
      ['e'],
    ]);
    expect(result.keys, ['a', 'e']);
    expect(result['e'], [5]);
  });

  test('no ids, no query', () async {
    var calls = 0;
    final thumbnails = ContactThumbnails(
      readContacts: (ids) async {
        calls++;
        return const [];
      },
    );
    expect(await thumbnails.read(const []), isEmpty);
    expect(calls, 0);
  });

  test('a failing batch only loses its own photos', () async {
    final thumbnails = ContactThumbnails(
      batchSize: 1,
      readContacts: (ids) async {
        if (ids.single == 'bad') throw PlatformException(code: 'gone');
        return [
          _contact(ids.single, [1]),
        ];
      },
    );
    final result = await thumbnails.read(['ok', 'bad', 'fine']);
    expect(result.keys, ['ok', 'fine']);
  });
}
