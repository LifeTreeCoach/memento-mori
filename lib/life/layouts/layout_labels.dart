import 'package:flutter/foundation.dart';

/// Localized text templates drawn by the layout painters; `{value}` is
/// replaced with the formatted number.
@immutable
class LayoutLabels {
  const LayoutLabels({
    this.yearsLived = '{value} years lived',
    this.yearsStacked = '{value}\nyears',
    this.grown = '{value}% grown',
    this.percent = '{value}%',
    this.decimalSeparator = '.',
  });

  final String yearsLived;
  final String yearsStacked;
  final String grown;
  final String percent;
  final String decimalSeparator;

  /// [value] with one decimal, using [decimalSeparator].
  String decimal(double value) =>
      value.toStringAsFixed(1).replaceAll('.', decimalSeparator);

  String fill(String template, double value) =>
      template.replaceAll('{value}', decimal(value));

  @override
  bool operator ==(Object other) =>
      other is LayoutLabels &&
      other.yearsLived == yearsLived &&
      other.yearsStacked == yearsStacked &&
      other.grown == grown &&
      other.percent == percent &&
      other.decimalSeparator == decimalSeparator;

  @override
  int get hashCode =>
      Object.hash(yearsLived, yearsStacked, grown, percent, decimalSeparator);
}
