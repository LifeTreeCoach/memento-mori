import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/widgets/section_label.dart';

/// A labelled group of settings: small uppercase header, then its tiles.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
          child: Semantics(header: true, child: SectionLabel(title)),
        ),
        ...children,
      ],
    );
  }
}
