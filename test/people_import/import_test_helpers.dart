import 'dart:typed_data';

import 'package:memento_mori_life_in_weeks/people_import/birthday_candidate.dart';
import 'package:memento_mori_life_in_weeks/people_import/existing_person.dart';

BirthdayCandidate candidate(
  String id,
  String name,
  int month,
  int day, {
  int? year,
  String? sourceId,
  bool photo = false,
  ImportSource source = ImportSource.contacts,
}) {
  return BirthdayCandidate(
    id: id,
    displayName: name,
    month: month,
    day: day,
    year: year,
    source: source,
    sourceId: sourceId,
    photo: photo ? CandidatePhoto.memory(Uint8List.fromList([1, 2, 3])) : null,
  );
}

ExistingPerson person(
  String id,
  String name,
  int month,
  int day, {
  int? year,
  String? sourceId,
}) {
  return ExistingPerson(
    id: id,
    name: name,
    month: month,
    day: day,
    year: year,
    sourceId: sourceId,
  );
}
