import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Coffee, donation, tip or payment wording in any of the four languages.
/// Store builds (rate channel) must never show any of it.
final RegExp moneyWords = RegExp(
  r'coffee|kaffee|café|donat|spende|spendier|trinkgeld|pourboire|propina|'
  r'money|geld|argent|dinero|paypal|\b(buy|pay|payer|payment|tips?)\b|☕',
  caseSensitive: false,
);

/// Every text on screen (plain and rich), for scanning with [moneyWords].
List<String> renderedTexts(WidgetTester tester) => [
  for (final text in tester.widgetList<Text>(find.byType(Text)))
    text.data ?? text.textSpan?.toPlainText() ?? '',
  for (final rich in tester.widgetList<RichText>(find.byType(RichText)))
    rich.text.toPlainText(),
];
