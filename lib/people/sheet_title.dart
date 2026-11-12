import 'package:flutter/material.dart';

/// Title line of the People bottom sheets.
class SheetTitle extends StatelessWidget {
  const SheetTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(text, style: Theme.of(context).textTheme.titleLarge),
      ),
    );
  }
}
