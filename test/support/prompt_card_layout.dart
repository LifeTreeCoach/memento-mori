import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Checks the Life-tab prompt card's two-row button layout: the [primary]
/// label in a full-width [FilledButton], then [notNow] and [done] as text
/// buttons side by side on one row below it, every label on one line.
void expectPromptCardLayout(
  WidgetTester tester, {
  required String primary,
  required String notNow,
  required String done,
}) {
  final card = find.byKey(const ValueKey('life_support_card'));
  final cardRect = tester.getRect(card);

  final primaryButton = _button<FilledButton>(primary);
  final notNowButton = _button<TextButton>(notNow);
  final doneButton = _button<TextButton>(done);
  final primaryRect = tester.getRect(primaryButton);
  final notNowRect = tester.getRect(notNowButton);
  final doneRect = tester.getRect(doneButton);

  // Full width: only the card's own padding left and right.
  expect(primaryRect.width, greaterThan(cardRect.width - 48), reason: primary);
  // The secondary actions share the row below the primary one.
  expect(notNowRect.top, greaterThanOrEqualTo(primaryRect.bottom));
  expect(doneRect.center.dy, moreOrLessEquals(notNowRect.center.dy));
  expect(notNowRect.right, lessThanOrEqualTo(doneRect.left));
  for (final rect in [primaryRect, notNowRect, doneRect]) {
    expect(cardRect.contains(rect.topLeft), isTrue);
    expect(rect.right, lessThanOrEqualTo(cardRect.right));
  }
  for (final label in [primary, notNow, done]) {
    final lineHeight = tester.getSize(find.text(label)).height;
    expect(lineHeight, lessThan(30), reason: '"$label" wraps');
  }
}

Finder _button<T extends Widget>(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(T));
