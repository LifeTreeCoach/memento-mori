import 'package:flutter/material.dart';

import '../../localization.dart';

/// "no year +" pill; tapping it opens the year field.
class NoYearBadge extends StatelessWidget {
  const NoYearBadge({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.secondaryContainer,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context).translate('import_no_year'),
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: scheme.onSecondaryContainer),
              ),
              const SizedBox(width: 2),
              Icon(Icons.add, size: 14, color: scheme.onSecondaryContainer),
            ],
          ),
        ),
      ),
    );
  }
}
