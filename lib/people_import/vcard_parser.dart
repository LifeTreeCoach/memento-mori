/// Reads birthdays from vCard files (2.1, 3.0 and 4.0) as exported by Google
/// Contacts, iCloud, Outlook and phone address books. Tolerant: broken lines
/// and cards are skipped, never thrown.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'birthday_candidate.dart';
import 'birthday_text_parser.dart';

/// Outcome of [parseVCards]: the cards with a usable birthday plus counts of
/// the cards that were left out.
class VCardParseResult {
  const VCardParseResult({
    required this.candidates,
    required this.cardCount,
    required this.withoutBirthday,
    required this.invalidBirthday,
    required this.withoutName,
  });

  final List<BirthdayCandidate> candidates;

  /// Every `BEGIN:VCARD` ... `END:VCARD` block found.
  final int cardCount;

  /// Cards without a `BDAY` line.
  final int withoutBirthday;

  /// Cards whose `BDAY` is not a real, plausible date.
  final int invalidBirthday;

  /// Cards with a valid birthday but neither `FN` nor `N`.
  final int withoutName;

  int get skippedCount => withoutBirthday + invalidBirthday + withoutName;
}

/// Decodes the bytes of a .vcf file: UTF-8 (with or without BOM), falling
/// back to Latin-1 for old 2.1 exports.
String decodeVCardBytes(List<int> bytes) {
  try {
    return utf8.decode(bytes).replaceFirst('﻿', '');
  } on FormatException {
    return latin1.decode(bytes);
  }
}

/// Parses every card in [text]. Candidate ids are `vcard:<card index>`;
/// inline photos are kept unless [includePhotos] is false.
VCardParseResult parseVCards(
  String text, {
  bool includePhotos = true,
  DateTime? today,
}) {
  final cards = _splitCards(_unfoldLines(text));
  final candidates = <BirthdayCandidate>[];
  var withoutBirthday = 0, invalidBirthday = 0, withoutName = 0;
  for (var index = 0; index < cards.length; index++) {
    final card = _VCard(cards[index]);
    final outcome = card.toCandidate(
      id: 'vcard:$index',
      includePhotos: includePhotos,
      today: today,
    );
    switch (outcome) {
      case _Accepted(:final candidate):
        candidates.add(candidate);
      case _Skipped(reason: _SkipReason.noBirthday):
        withoutBirthday++;
      case _Skipped(reason: _SkipReason.invalidBirthday):
        invalidBirthday++;
      case _Skipped(reason: _SkipReason.noName):
        withoutName++;
    }
  }
  return VCardParseResult(
    candidates: candidates,
    cardCount: cards.length,
    withoutBirthday: withoutBirthday,
    invalidBirthday: invalidBirthday,
    withoutName: withoutName,
  );
}

// ---------------------------------------------------------------- lines ---

/// Joins folded lines: a line starting with a space or tab continues the
/// previous one, and a quoted-printable value ending in `=` (2.1 soft line
/// break) continues on the next line.
List<String> _unfoldLines(String text) {
  final raw = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');
  final lines = <String>[];
  var softBreak = false;
  for (final line in raw) {
    if (softBreak) {
      lines[lines.length - 1] =
          lines.last.substring(0, lines.last.length - 1) + line;
    } else if (lines.isNotEmpty &&
        (line.startsWith(' ') || line.startsWith('\t'))) {
      lines[lines.length - 1] = lines.last + line.substring(1);
    } else {
      lines.add(line);
    }
    softBreak = _endsWithSoftBreak(lines.last);
  }
  return lines;
}

bool _endsWithSoftBreak(String line) =>
    line.endsWith('=') && _isQuotedPrintableLine(line);

bool _isQuotedPrintableLine(String line) {
  final colon = line.indexOf(':');
  if (colon < 0) return false;
  return line.substring(0, colon).toUpperCase().contains('QUOTED-PRINTABLE');
}

/// The content lines of each top-level card (nested `AGENT` cards and lines
/// outside any card are dropped).
List<List<_ContentLine>> _splitCards(List<String> lines) {
  final cards = <List<_ContentLine>>[];
  List<_ContentLine>? current;
  var depth = 0;
  for (final line in lines) {
    final upper = line.trim().toUpperCase();
    if (upper == 'BEGIN:VCARD') {
      depth++;
      if (depth == 1) current = [];
    } else if (upper == 'END:VCARD') {
      if (depth == 1 && current != null) cards.add(current);
      if (depth > 0) depth--;
      if (depth == 0) current = null;
    } else if (depth == 1) {
      final parsed = _ContentLine.tryParse(line);
      if (parsed != null) current?.add(parsed);
    }
  }
  return cards;
}

/// One `[group.]NAME;PARAM=VALUE:value` line, with upper-cased names.
class _ContentLine {
  _ContentLine(this.name, this.params, this.rawValue);

  final String name;
  final Map<String, String> params;
  final String rawValue;

  static _ContentLine? tryParse(String line) {
    final colon = _colonOutsideQuotes(line);
    if (colon <= 0) return null;
    final head = _splitOutsideQuotes(line.substring(0, colon), ';');
    final name = head.first.split('.').last.trim().toUpperCase();
    if (name.isEmpty) return null;
    return _ContentLine(
      name,
      _parseParams(head.skip(1)),
      line.substring(colon + 1),
    );
  }

  String? param(String key) => params[key];

  bool get isQuotedPrintable => param('ENCODING') == 'QUOTED-PRINTABLE';

  bool get isBase64 => const {'B', 'BASE64'}.contains(param('ENCODING'));

  /// The value as text: quoted-printable decoded in its `CHARSET`.
  String get decodedText => isQuotedPrintable
      ? _decodeQuotedPrintable(rawValue, param('CHARSET'))
      : rawValue;
}

/// Parameters by upper-cased name. vCard 2.1 bare parameters
/// (`;QUOTED-PRINTABLE`, `;BASE64`, `;JPEG`) become ENCODING or TYPE.
Map<String, String> _parseParams(Iterable<String> parts) {
  final params = <String, String>{};
  for (final part in parts) {
    final equals = part.indexOf('=');
    if (equals < 0) {
      final bare = part.trim().toUpperCase();
      final isEncoding = const {
        'QUOTED-PRINTABLE',
        'BASE64',
        'B',
        '8BIT',
      }.contains(bare);
      params.putIfAbsent(isEncoding ? 'ENCODING' : 'TYPE', () => bare);
      continue;
    }
    final key = part.substring(0, equals).trim().toUpperCase();
    final value = part.substring(equals + 1).trim().replaceAll('"', '');
    params[key] = key == 'CHARSET' || key == 'ENCODING' || key == 'VALUE'
        ? value.toUpperCase()
        : value;
  }
  return params;
}

int _colonOutsideQuotes(String line) {
  var quoted = false;
  for (var i = 0; i < line.length; i++) {
    final char = line[i];
    if (char == '"') quoted = !quoted;
    if (char == ':' && !quoted) return i;
  }
  return -1;
}

List<String> _splitOutsideQuotes(String text, String separator) {
  final parts = <String>[];
  final buffer = StringBuffer();
  var quoted = false;
  for (final char in text.split('')) {
    if (char == '"') quoted = !quoted;
    if (char == separator && !quoted) {
      parts.add(buffer.toString());
      buffer.clear();
    } else {
      buffer.write(char);
    }
  }
  parts.add(buffer.toString());
  return parts;
}

// --------------------------------------------------------------- values ---

String _decodeQuotedPrintable(String value, String? charset) {
  final bytes = <int>[];
  for (var i = 0; i < value.length; i++) {
    final code = value.codeUnitAt(i);
    final hex = value[i] == '=' && i + 2 < value.length
        ? int.tryParse(value.substring(i + 1, i + 3), radix: 16)
        : null;
    if (hex != null) {
      bytes.add(hex);
      i += 2;
    } else {
      bytes.addAll(code < 0x80 ? [code] : utf8.encode(value[i]));
    }
  }
  return _decodeCharset(bytes, charset);
}

String _decodeCharset(List<int> bytes, String? charset) {
  const latinCharsets = {'ISO-8859-1', 'ISO-8859-15', 'WINDOWS-1252', 'CP1252'};
  return latinCharsets.contains(charset)
      ? latin1.decode(bytes, allowInvalid: true)
      : utf8.decode(bytes, allowMalformed: true);
}

/// Unescapes vCard text (`\\`, `\,`, `\;`, `\n`/`\N`).
String _unescapeText(String value) {
  final buffer = StringBuffer();
  for (var i = 0; i < value.length; i++) {
    final char = value[i];
    if (char != r'\' || i + 1 == value.length) {
      buffer.write(char);
      continue;
    }
    final next = value[++i];
    buffer.write(next == 'n' || next == 'N' ? '\n' : next);
  }
  return buffer.toString();
}

/// Splits on [separator] where it is not escaped with a backslash.
List<String> _splitUnescaped(String value, String separator) {
  final parts = <String>[];
  var start = 0;
  for (var i = 0; i < value.length; i++) {
    if (value[i] == r'\') {
      i++;
    } else if (value[i] == separator) {
      parts.add(value.substring(start, i));
      start = i + 1;
    }
  }
  parts.add(value.substring(start));
  return parts;
}

String _collapseWhitespace(String text) =>
    text.replaceAll(RegExp(r'\s+'), ' ').trim();

Uint8List? _decodeBase64(String data) {
  final compact = data.replaceAll(RegExp(r'\s'), '');
  if (compact.isEmpty) return null;
  try {
    final bytes = base64.decode(base64.normalize(compact));
    return bytes.isEmpty ? null : bytes;
  } on FormatException {
    return null;
  }
}

// ---------------------------------------------------------------- cards ---

/// Why a card produced no candidate.
enum _SkipReason { noBirthday, invalidBirthday, noName }

sealed class _Outcome {
  const _Outcome();
}

class _Accepted extends _Outcome {
  const _Accepted(this.candidate);

  final BirthdayCandidate candidate;
}

class _Skipped extends _Outcome {
  const _Skipped(this.reason);

  final _SkipReason reason;
}

/// The properties of one card that the import needs.
class _VCard {
  _VCard(this.lines);

  final List<_ContentLine> lines;

  _Outcome toCandidate({
    required String id,
    required bool includePhotos,
    DateTime? today,
  }) {
    final birthdayLines = _all('BDAY');
    if (birthdayLines.isEmpty) return const _Skipped(_SkipReason.noBirthday);
    final birthday = _firstBirthday(birthdayLines, today);
    if (birthday == null) return const _Skipped(_SkipReason.invalidBirthday);
    final name = _displayName();
    if (name == null) return const _Skipped(_SkipReason.noName);
    final photo = includePhotos ? _photoBytes() : null;
    return _Accepted(
      BirthdayCandidate(
        id: id,
        displayName: name,
        month: birthday.month,
        day: birthday.day,
        year: birthday.year,
        source: ImportSource.vcard,
        sourceId: _uid(),
        photo: photo == null ? null : CandidatePhoto.memory(photo),
      ),
    );
  }

  Iterable<_ContentLine> _all(String name) =>
      lines.where((line) => line.name == name);

  _ContentLine? _first(String name) => _all(name).firstOrNull;

  BirthdayDate? _firstBirthday(
    Iterable<_ContentLine> birthdayLines,
    DateTime? today,
  ) {
    for (final line in birthdayLines) {
      final omitYear = int.tryParse(line.param('X-APPLE-OMIT-YEAR') ?? '');
      final date = parseBirthdayText(
        line.decodedText,
        omitYear: omitYear,
        today: today,
      );
      if (date != null) return date;
    }
    return null;
  }

  /// `FN`, else `N` as "Given Family"; null when both are empty.
  String? _displayName() {
    final formatted = _collapseWhitespace(
      _unescapeText(_first('FN')?.decodedText ?? ''),
    );
    if (formatted.isNotEmpty) return formatted;
    final structured = _first('N');
    if (structured == null) return null;
    final name = _nameFromStructured(structured.decodedText);
    return name.isEmpty ? null : name;
  }

  /// `Family;Given;Additional;Prefix;Suffix` -> "Given Family" (list values
  /// separated by commas become spaces).
  String _nameFromStructured(String value) {
    final parts = _splitUnescaped(value, ';')
        .map((part) => _unescapeText(_splitUnescaped(part, ',').join(' ')))
        .toList();
    final family = parts.isNotEmpty ? parts[0] : '';
    final given = parts.length > 1 ? parts[1] : '';
    return _collapseWhitespace('$given $family');
  }

  String? _uid() {
    final uid = _unescapeText(_first('UID')?.decodedText ?? '').trim();
    return uid.isEmpty ? null : uid;
  }

  /// Inline photo bytes (base64 parameter or `data:` URI); links are skipped.
  Uint8List? _photoBytes() {
    for (final line in _all('PHOTO')) {
      final bytes = _inlinePhoto(line);
      if (bytes != null) return bytes;
    }
    return null;
  }

  Uint8List? _inlinePhoto(_ContentLine line) {
    final value = line.rawValue.trim();
    if (line.isBase64) return _decodeBase64(value);
    final dataUri = RegExp(
      r'^data:[^,]*;base64,(.*)$',
      dotAll: true,
    ).firstMatch(value);
    return dataUri == null ? null : _decodeBase64(dataUri.group(1)!);
  }
}
