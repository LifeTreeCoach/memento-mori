import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:memento_mori_life_in_weeks/l10n/compass_strings.dart';
import 'package:memento_mori_life_in_weeks/l10n/core_strings.dart';
import 'package:memento_mori_life_in_weeks/l10n/data_protection_strings.dart';
import 'package:memento_mori_life_in_weeks/l10n/friend_data_strings.dart';
import 'package:memento_mori_life_in_weeks/l10n/friend_estimate_strings.dart';
import 'package:memento_mori_life_in_weeks/l10n/friend_form_strings.dart';
import 'package:memento_mori_life_in_weeks/l10n/import_strings.dart';
import 'package:memento_mori_life_in_weeks/l10n/intention_strings.dart';
import 'package:memento_mori_life_in_weeks/l10n/lifespan_other_strings.dart';
import 'package:memento_mori_life_in_weeks/l10n/lifespan_strings.dart';
import 'package:memento_mori_life_in_weeks/l10n/onboarding_strings.dart';
import 'package:memento_mori_life_in_weeks/l10n/people_strings.dart';
import 'package:memento_mori_life_in_weeks/l10n/compass_setup_strings.dart';
import 'package:memento_mori_life_in_weeks/l10n/phase_strings.dart';
import 'package:memento_mori_life_in_weeks/l10n/quote_strings.dart';
import 'package:memento_mori_life_in_weeks/l10n/reflection_strings.dart';
import 'package:memento_mori_life_in_weeks/l10n/settings_strings.dart';
import 'package:memento_mori_life_in_weeks/l10n/support_strings.dart';
import 'package:memento_mori_life_in_weeks/l10n/together_strings.dart';
import 'package:memento_mori_life_in_weeks/l10n/tour_strings.dart';
import 'package:memento_mori_life_in_weeks/l10n/vault_strings.dart';
import 'package:memento_mori_life_in_weeks/l10n/week_moment_strings.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  /// Languages the user can pick and the app follows from the device locale,
  /// in display order. Single source of truth for the delegate, the
  /// MaterialApp locales, the device-language fallback and the pickers.
  ///
  /// 'fr' and 'es' get added here once their string tables exist (see
  /// [_localizedValues]); [languageNames] already knows their names.
  static const List<String> supportedLanguages = ['en', 'de', 'fr', 'es'];

  /// Delegates of every app root (the app's strings plus Flutter's own).
  static const List<LocalizationsDelegate<dynamic>> delegates = [
    AppLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  /// [supportedLanguages] as locales, for `MaterialApp.supportedLocales`.
  static List<Locale> get supportedLocales => [
        for (final code in supportedLanguages) Locale(code),
      ];

  /// Endonyms shown in the language pickers (never translated).
  static const Map<String, String> languageNames = {
    'en': 'English',
    'de': 'Deutsch',
    'fr': 'Français',
    'es': 'Español',
  };

  /// Grouped integers ("4,160" / "4.160"), created once per locale.
  late final NumberFormat numberFormat =
      NumberFormat.decimalPattern(locale.languageCode);

  /// The app-wide date format ("12 Mar 1998" / "12. März 1998"), created
  /// once per locale. Use it for every user-facing date.
  late final DateFormat shortDateFormat =
      shortDateFormatFor(locale.languageCode);

  /// English keeps its day-first "12 Mar 1998"; every other language uses
  /// its CLDR medium date (de "12. März 1998", fr "12 mars 1998",
  /// es "12 mar 1998").
  static DateFormat shortDateFormatFor(String languageCode) =>
      languageCode == 'en'
          ? DateFormat('d MMM y', 'en')
          : DateFormat.yMMMd(languageCode);

  /// Day and month only ("12 Mar" / "12. März"), for birthdays without a
  /// year.
  late final DateFormat dayMonthFormat = locale.languageCode == 'en'
      ? DateFormat('d MMM', 'en')
      : DateFormat.MMMd(locale.languageCode);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  /// All strings per language. Adding a language = one entry spreading the
  /// core table and every per-feature table (`lib/l10n/*_strings.dart`)
  /// for that language, plus its code in [supportedLanguages].
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      ...coreStringsEn,
      ...peopleStringsEn,
      ...friendFormStringsEn,
      ...friendEstimateStringsEn,
      ...friendDataStringsEn,
      ...settingsStringsEn,
      ...onboardingStringsEn,
      ...lifespanStringsEn,
      ...lifespanOtherStringsEn,
      ...quoteStringsEn,
      ...compassStringsEn,
      ...togetherStringsEn,
      ...phaseStringsEn,
      ...compassSetupStringsEn,
      ...intentionStringsEn,
      ...supportStringsEn,
      ...reflectionStringsEn,
      ...importStringsEn,
      ...tourStringsEn,
      ...weekMomentStringsEn,
      ...vaultStringsEn,
      ...dataProtectionStringsEn,
    },
    'de': {
      ...coreStringsDe,
      ...peopleStringsDe,
      ...friendFormStringsDe,
      ...friendEstimateStringsDe,
      ...friendDataStringsDe,
      ...settingsStringsDe,
      ...onboardingStringsDe,
      ...lifespanStringsDe,
      ...lifespanOtherStringsDe,
      ...quoteStringsDe,
      ...compassStringsDe,
      ...togetherStringsDe,
      ...phaseStringsDe,
      ...compassSetupStringsDe,
      ...intentionStringsDe,
      ...supportStringsDe,
      ...reflectionStringsDe,
      ...importStringsDe,
      ...tourStringsDe,
      ...weekMomentStringsDe,
      ...vaultStringsDe,
      ...dataProtectionStringsDe,
    },
    'fr': {
      ...coreStringsFr,
      ...peopleStringsFr,
      ...friendFormStringsFr,
      ...friendEstimateStringsFr,
      ...friendDataStringsFr,
      ...settingsStringsFr,
      ...onboardingStringsFr,
      ...lifespanStringsFr,
      ...lifespanOtherStringsFr,
      ...quoteStringsFr,
      ...compassStringsFr,
      ...togetherStringsFr,
      ...phaseStringsFr,
      ...compassSetupStringsFr,
      ...intentionStringsFr,
      ...supportStringsFr,
      ...reflectionStringsFr,
      ...importStringsFr,
      ...tourStringsFr,
      ...weekMomentStringsFr,
      ...vaultStringsFr,
      ...dataProtectionStringsFr,
    },
    'es': {
      ...coreStringsEs,
      ...peopleStringsEs,
      ...friendFormStringsEs,
      ...friendEstimateStringsEs,
      ...friendDataStringsEs,
      ...settingsStringsEs,
      ...onboardingStringsEs,
      ...lifespanStringsEs,
      ...lifespanOtherStringsEs,
      ...quoteStringsEs,
      ...compassStringsEs,
      ...togetherStringsEs,
      ...phaseStringsEs,
      ...compassSetupStringsEs,
      ...intentionStringsEs,
      ...supportStringsEs,
      ...reflectionStringsEs,
      ...importStringsEs,
      ...tourStringsEs,
      ...weekMomentStringsEs,
      ...vaultStringsEs,
      ...dataProtectionStringsEs,
    },
  };


  /// All strings of [languageCode], for completeness checks.
  static Map<String, String> valuesFor(String languageCode) =>
      _localizedValues[languageCode] ?? const {};

  /// Keys per language, for completeness checks.
  static Map<String, Set<String>> get keysByLanguage => {
        for (final entry in _localizedValues.entries)
          entry.key: entry.value.keys.toSet(),
      };

  String translate(String key, {Map<String, String>? replacements}) {
    String translation = _localizedValues[locale.languageCode]?[key] ?? key;
    if (replacements != null) {
      replacements.forEach((placeholder, value) {
        translation = translation.replaceAll('{$placeholder}', value);
      });
    }
    return translation;
  }

  /// Plural form of [baseKey] for [count]: uses `<baseKey>_zero` (when
  /// defined) for 0, otherwise `<baseKey>_one` or `<baseKey>_other` as
  /// the language's CLDR plural rule says (French: 0 and 1 are "one");
  /// `{n}` is replaced by [count].
  String plural(String baseKey, int count,
      {Map<String, String>? replacements}) {
    final values = {'n': '$count', ...?replacements};
    final languageCode = locale.languageCode;
    final hasZero =
        _localizedValues[languageCode]?['${baseKey}_zero'] != null;
    final suffix =
        pluralSuffix(count, languageCode: languageCode, hasZero: hasZero);
    return translate('${baseKey}_$suffix', replacements: values);
  }

  /// The plural key suffix ('zero', 'one' or 'other') for [count] in
  /// [languageCode]. 'zero' only when the table defines it ([hasZero]);
  /// CLDR categories the tables don't use (two, few, many) fall back to
  /// 'other'.
  static String pluralSuffix(int count,
      {required String languageCode, bool hasZero = false}) {
    return Intl.pluralLogic(
      count,
      locale: languageCode,
      zero: hasZero ? 'zero' : null,
      one: 'one',
      other: 'other',
    );
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLanguages.contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(LocalizationsDelegate<AppLocalizations> old) => false;
}
