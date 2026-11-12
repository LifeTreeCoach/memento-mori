import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/life/layouts/layout_labels.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

void main() {
  test('default labels format one decimal in English', () {
    const labels = LayoutLabels();
    expect(labels.fill(labels.yearsLived, 35.24), '35.2 years lived');
  });

  test('German templates use a decimal comma', () {
    final de = AppLocalizations.valuesFor('de');
    final labels = LayoutLabels(
      grown: de['layout_grown']!,
      decimalSeparator: de['layout_decimal_separator']!,
    );
    expect(labels.fill(labels.grown, 45.25), '45,3\u00A0% gewachsen');
  });

  test('labels compare by value so painters do not repaint needlessly', () {
    expect(const LayoutLabels(), LayoutLabels(percent: '{value}%'));
  });
}
