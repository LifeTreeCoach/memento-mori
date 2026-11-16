import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/app_settings_controller.dart';
import 'package:memento_mori_life_in_weeks/core/life_calculator.dart';
import 'package:memento_mori_life_in_weeks/lifespan/lifespan_estimator.dart';
import 'package:memento_mori_life_in_weeks/lifespan/lifespan_result_store.dart';
import 'package:memento_mori_life_in_weeks/lifespan/lifestyle_model.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/estimate_subject.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/lifespan_data.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/lifespan_estimate_flow.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/lifespan_profile.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

/// Full-screen [LifespanEstimateFlow], prefilled with [initial] (or no
/// answers). Applying saves only the result to [store] (when there is
/// one), updates the life expectancy in [settings] (the user's own
/// estimate only) and pops with the applied [LifespanProfile]; leaving
/// without applying pops with null.
class LifespanEstimateScreen extends StatefulWidget {
  const LifespanEstimateScreen({
    super.key,
    required this.birthDate,
    this.settings,
    this.subject = const SelfSubject(),
    this.initial,
    this.store,
    this.currentYears,
    this.loadData = LifespanData.load,
    this.now,
  });

  final DateTime birthDate;

  /// The app settings; their life expectancy follows a self estimate.
  final AppSettingsController? settings;
  final LifespanEstimateSubject subject;

  /// Answers to prefill; defaults to none (answers are never stored).
  final LifespanProfile? initial;

  /// Where the applied result is kept. Defaults to the user's own
  /// settings for [SelfSubject] and to none for another person (the
  /// caller keeps what it needs of the returned profile).
  final LifespanResultStore? store;

  /// The years in use ("keep"); defaults to the settings' value.
  final int? currentYears;
  final LifespanDataLoader loadData;
  final DateTime? now;

  /// Loader used by [open]; tests replace it with one reading the files.
  @visibleForTesting
  static LifespanDataLoader defaultLoader = LifespanData.load;

  /// Pushes the user's own estimate; needs a birth date. Completes with
  /// the applied profile, or null when nothing was applied.
  static Future<LifespanProfile?> open(
    BuildContext context,
    AppSettingsController settings, {
    LifespanResultStore store = const SettingsLifespanResultStore(),
  }) async {
    final birthDate = settings.birthDate;
    if (birthDate == null) return null;
    return Navigator.of(context).push(
      MaterialPageRoute<LifespanProfile>(
        builder: (_) => LifespanEstimateScreen(
          settings: settings,
          birthDate: birthDate,
          store: store,
          loadData: defaultLoader,
        ),
      ),
    );
  }

  /// Pushes the estimate about another person ([OtherSubject] [name]),
  /// starting from [initial]; nothing is stored here, the caller keeps the
  /// applied profile it completes with (null when nothing was applied).
  static Future<LifespanProfile?> openForPerson(
    BuildContext context, {
    required String name,
    required DateTime birthDate,
    required LifespanProfile initial,
    required int currentYears,
  }) => Navigator.of(context).push(
    MaterialPageRoute<LifespanProfile>(
      builder: (_) => LifespanEstimateScreen(
        birthDate: birthDate,
        subject: OtherSubject(name),
        initial: initial,
        currentYears: currentYears,
        loadData: defaultLoader,
      ),
    ),
  );

  @override
  State<LifespanEstimateScreen> createState() => _LifespanEstimateScreenState();
}

class _LifespanEstimateScreenState extends State<LifespanEstimateScreen> {
  final GlobalKey<LifespanEstimateFlowState> _flow = GlobalKey();
  late final LifespanResultStore? _store =
      widget.store ??
      (widget.subject.isSelf ? const SettingsLifespanResultStore() : null);
  late final LifespanProfile _initial =
      widget.initial ?? const LifespanProfile();
  bool _saving = false;

  int get _currentYears =>
      widget.currentYears ??
      widget.settings?.lifeExpectancyYears ??
      LifeCalculator.defaultLifeExpectancyYears;

  Future<void> _apply(
    int years,
    LifespanEstimate estimate,
    LifestyleAnswers answers,
  ) async {
    if (_saving) return;
    _saving = true;
    final profile = LifespanProfile.applied(
      estimate: estimate,
      answers: answers,
      years: years,
    );
    await _store?.save(profile);
    if (widget.subject.isSelf) await _updateSettings(years);
    if (mounted) Navigator.of(context).pop(profile);
  }

  Future<void> _updateSettings(int years) async {
    final settings = widget.settings;
    if (settings == null) return;
    if (years == settings.lifeExpectancyYears) {
      settings.reload(); // the stored estimate changed; refresh the subtitle
    } else {
      await settings.setLifeExpectancyYears(years);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (!(_flow.currentState?.back() ?? false)) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.translate('estimate_screen_title'))),
        body: SafeArea(
          top: false,
          child: LifespanEstimateFlow(
            key: _flow,
            birthDate: widget.birthDate,
            currentYears: _currentYears,
            initial: _initial,
            loadData: widget.loadData,
            now: widget.now,
            subject: widget.subject,
            onApply: _apply,
            onSkip: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }
}
