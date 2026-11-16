import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/app_settings_controller.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

import 'locked_data_screen.dart';

/// Minimal app shown while the personal data is locked: only the
/// [LockedDataScreen], in the user's theme and language (plain settings,
/// readable without the personal data). Nothing else starts, so nothing can
/// overwrite or delete the locked data.
class LockedDataApp extends StatefulWidget {
  const LockedDataApp({
    super.key,
    required this.reason,
    required this.onTryAgain,
    required this.onStartFresh,
  });

  final LockedDataReason reason;
  final Future<LockedDataReason?> Function() onTryAgain;
  final Future<void> Function() onStartFresh;

  @override
  State<LockedDataApp> createState() => _LockedDataAppState();
}

class _LockedDataAppState extends State<LockedDataApp> {
  final AppSettingsController _settings = AppSettingsController();

  @override
  void dispose() {
    _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _settings.lightTheme,
      darkTheme: _settings.darkTheme,
      themeMode: _settings.themeMode,
      locale: _settings.locale,
      localizationsDelegates: AppLocalizations.delegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: LockedDataScreen(
        reason: widget.reason,
        onTryAgain: widget.onTryAgain,
        onStartFresh: widget.onStartFresh,
      ),
    );
  }
}
