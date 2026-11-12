import 'package:flutter/material.dart';

/// "Label ........ value" row inside a detail card.
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.caption,
  });

  final String label;
  final String value;

  /// Emphasizes the value (e.g. the amber accent on a birthday).
  final Color? valueColor;

  /// Small muted note under the value (e.g. where the number comes from).
  final String? caption;

  /// The label's usual share of the row; it grows up to its longest word
  /// so long compounds ("Lebensfortschritt") never break mid-word.
  static const double labelShare = 2 / 5;
  static const double gap = 12;

  /// Width of the label column in a row [available] wide: [labelShare] of
  /// it, widened to [longestLabelWord] as long as [longestValueWord] still
  /// fits next to it.
  static double labelWidthFor({
    required double available,
    required double longestLabelWord,
    required double longestValueWord,
  }) {
    final usual = available * labelShare;
    final most = available - gap - longestValueWord;
    if (longestLabelWord <= usual || most <= usual) return usual;
    return longestLabelWord < most ? longestLabelWord : most;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme.bodyMedium;
    final labelStyle =
        text?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final valueStyle = text?.copyWith(
      color: valueColor,
      fontWeight: valueColor != null ? FontWeight.w600 : null,
    );
    final scaler = MediaQuery.textScalerOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: LayoutBuilder(builder: (context, constraints) {
        final labelWidth = labelWidthFor(
          available: constraints.maxWidth,
          longestLabelWord: _longestWord(label, labelStyle, scaler),
          longestValueWord: _longestWord(value, valueStyle, scaler),
        );
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: labelWidth,
              child: Text(label, style: labelStyle),
            ),
            const SizedBox(width: gap),
            Expanded(child: _value(theme, valueStyle)),
          ],
        );
      }),
    );
  }

  Widget _value(ThemeData theme, TextStyle? valueStyle) {
    final value = Text(this.value, textAlign: TextAlign.end, style: valueStyle);
    final caption = this.caption;
    if (caption == null) return value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        value,
        Text(
          caption,
          textAlign: TextAlign.end,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// Width of the widest unbreakable part of [value] (its longest word).
  static double _longestWord(
      String value, TextStyle? style, TextScaler scaler) {
    final painter = TextPainter(
      text: TextSpan(text: value, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    final width = painter.minIntrinsicWidth;
    painter.dispose();
    return width.ceilToDouble();
  }
}

/// A quiet card holding [InfoRow]s and other content.
class InfoCard extends StatelessWidget {
  const InfoCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}
