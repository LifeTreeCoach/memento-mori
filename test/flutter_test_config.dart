import 'dart:async';

import 'package:memento_mori_life_in_weeks/security/personal_store.dart';
import 'package:memento_mori_life_in_weeks/security/shared_prefs_personal_store.dart';

/// Runs before every test file: personal data goes to plain (mock)
/// SharedPreferences in tests; the app uses the encrypted vault.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  PersonalStore.configure(SharedPrefsPersonalStore());
  await testMain();
}
