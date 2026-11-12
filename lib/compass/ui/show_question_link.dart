import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

/// What remains of the question card after "Not now": a small link.
class ShowQuestionLink extends StatelessWidget {
  const ShowQuestionLink({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: TextButton.icon(
        key: const ValueKey('compass_show_question'),
        icon: const Icon(Icons.help_outline_rounded, size: 18),
        label: Text(
            AppLocalizations.of(context).translate('compass_show_question')),
        onPressed: onPressed,
      ),
    );
  }
}
