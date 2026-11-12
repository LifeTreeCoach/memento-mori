import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/people_import/import_photo.dart';

Future<Uint8List> _png(int width, int height) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint()..color = const ui.Color(0xFF336699),
  );
  final image = await recorder.endRecording().toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

Future<(int, int)> _size(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final image = (await codec.getNextFrame()).image;
  return (image.width, image.height);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('scales the longer side down to 300 px', () async {
    final landscape = await resizeImportPhoto(await _png(900, 600));
    expect(await _size(landscape!), (300, 200));
    final portrait = await resizeImportPhoto(await _png(400, 800));
    expect(await _size(portrait!), (150, 300));
  });

  test('keeps small photos unchanged', () async {
    final small = await _png(120, 80);
    expect(await resizeImportPhoto(small), same(small));
  });

  test('rejects empty, unknown and oversized data', () async {
    expect(await resizeImportPhoto(Uint8List(0)), isNull);
    expect(await resizeImportPhoto(Uint8List.fromList([1, 2, 3, 4])), isNull);
    final huge = Uint8List(3 << 20)..setAll(0, [0x89, 0x50, 0x4E, 0x47]);
    expect(await resizeImportPhoto(huge), isNull);
  });

  test('a corrupt image with a valid signature gives null', () async {
    final corrupt = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0, 0, 0, 0]);
    expect(await resizeImportPhoto(corrupt), isNull);
  });
}
