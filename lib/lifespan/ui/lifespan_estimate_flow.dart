import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/lifespan/condition_model.dart';
import 'package:memento_mori_life_in_weeks/lifespan/country_names.dart';
import 'package:memento_mori_life_in_weeks/lifespan/lifespan_estimator.dart';
import 'package:memento_mori_life_in_weeks/lifespan/lifestyle_model.dart';
import 'package:memento_mori_life_in_weeks/lifespan/sex.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/baseline_years.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/basics_page.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/conditions_page.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/country_picker_sheet.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/estimate_intro.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/estimate_subject.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/lifespan_data.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/lifespan_profile.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/question_page.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/question_steps.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/result_page.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/weight_page.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/theme/motion.dart';

/// Called with the chosen years, the estimate behind them and the lifestyle
/// answers that produced it (the caller persists them).
typedef LifespanApply = void Function(
  int years,
  LifespanEstimate estimate,
  LifestyleAnswers answers,
);

/// The personal lifespan estimate, used by the onboarding and by
/// `LifespanEstimateScreen`: country and sex, optional questions, result.
///
/// Its pages have their own back history: callers route back gestures to
/// [LifespanEstimateFlowState.back] (via a [GlobalKey]) first.
class LifespanEstimateFlow extends StatefulWidget {
  const LifespanEstimateFlow({
    super.key,
    required this.birthDate,
    required this.currentYears,
    required this.onApply,
    required this.onSkip,
    this.initial = const LifespanProfile(),
    this.loadData = LifespanData.load,
    this.now,
    this.deviceCountryCode,
    this.subject = const SelfSubject(),
    this.intro,
  });

  /// Whose lifespan is estimated: the user (default) or a named person.
  final LifespanEstimateSubject subject;

  /// The first page's title and intro as the caller words them; null uses
  /// the [subject]'s texts.
  final EstimateIntro? intro;

  final DateTime birthDate;

  /// The life expectancy in use; "keep" leaves it unchanged.
  final int currentYears;
  final LifespanApply onApply;
  final VoidCallback onSkip;

  /// Stored answers to prefill (country, sex, lifestyle, last estimate).
  final LifespanProfile initial;
  final LifespanDataLoader loadData;

  /// Fixed "today" for tests; defaults to the clock.
  final DateTime? now;

  /// Overrides the device region for tests.
  final String? deviceCountryCode;

  @override
  State<LifespanEstimateFlow> createState() => LifespanEstimateFlowState();
}

class LifespanEstimateFlowState extends State<LifespanEstimateFlow> {
  static final int _resultIndex = QuestionSteps.result;

  LifespanData? _data;
  bool _failed = false;

  late String _country = widget.initial.country ?? CountryNames.worldCode;
  late Sex _sex = widget.initial.sex ?? Sex.unspecified;
  late LifestyleAnswers _answers = widget.initial.answers;

  /// Index of the shown page, see [QuestionSteps].
  int _page = QuestionSteps.basics;
  final List<int> _history = [];

  LifespanEstimate? _estimate;
  int? _years;

  DateTime get _now => widget.now ?? DateTime.now();

  late final BaselineYears _baseline = BaselineYears(
    birthDate: widget.birthDate,
    now: _now,
  );

  bool get _isAdult =>
      LifespanEstimator.exactAge(widget.birthDate, _now) >=
      LifestyleAnswers.adultAge;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await widget.loadData();
      if (!mounted) return;
      setState(() {
        _data = data;
        _country = _initialCountry(data.countries);
      });
    } catch (error) {
      // Keep the current value; the page offers only "keep".
      debugPrint('Lifespan data could not be loaded: $error');
      if (mounted) setState(() => _failed = true);
    }
  }

  /// Stored choice first (the user picked it), then the device region,
  /// then World.
  String _initialCountry(CountryNames countries) {
    final stored = widget.initial.country;
    if (countries.contains(stored)) return stored!;
    return countries.deviceCountry(countryCode: widget.deviceCountryCode) ??
        CountryNames.worldCode;
  }

  /// Goes one page back; false when already on the first page.
  bool back() {
    if (_history.isEmpty) return false;
    FocusScope.of(context).unfocus();
    setState(() => _page = _history.removeLast());
    return true;
  }

  void _goTo(int page) {
    FocusScope.of(context).unfocus();
    if (page == _resultIndex) _computeEstimate();
    setState(() {
      _history.add(_page);
      _page = page;
    });
  }

  void _computeEstimate() {
    final data = _data;
    if (data == null) return;
    final estimate = LifespanEstimator(data.tables).estimate(
      country: _country,
      sex: _sex,
      birthDate: widget.birthDate,
      now: _now,
      answers: _isAdult ? _answers : null,
    );
    final previous = _estimate;
    _estimate = estimate;
    if (previous == null) {
      _years = _initialYears(estimate);
    } else if (previous.recommendedYears != estimate.recommendedYears) {
      _years = estimate.recommendedYears;
    }
  }

  /// The recommended value, or the stored fine-tuned one when the inputs
  /// still lead to the same recommendation.
  int _initialYears(LifespanEstimate estimate) {
    final applied = widget.initial.applied;
    if (applied != null &&
        applied.estimate.recommendedYears == estimate.recommendedYears) {
      return applied.appliedYears
          .clamp(estimateMinYears, estimateMaxYears)
          .toInt();
    }
    return estimate.recommendedYears;
  }

  Future<void> _pickCountry() async {
    final data = _data;
    if (data == null) return;
    final picked = await showCountryPickerSheet(
      context,
      countries: data.countries,
      selected: _country,
    );
    if (picked != null && mounted) setState(() => _country = picked);
  }

  void _setAnswer(LifestyleFactor factor, LifestyleOption? option) {
    setState(() => _answers = _answers.withAnswer(factor, option));
  }

  void _setConditions(Set<ChronicCondition>? conditions) {
    setState(() => _answers = _answers.withConditions(conditions));
  }

  void _skipConditions() {
    _setConditions(null);
    _goTo(_resultIndex);
  }

  bool get _hasConditions =>
      _isAdult && (_answers.conditions?.isNotEmpty ?? false);

  void _apply() {
    final estimate = _estimate;
    if (estimate == null) return;
    Haptics.light();
    widget.onApply(
      _years ?? estimate.recommendedYears,
      estimate,
      _isAdult ? _answers : const LifestyleAnswers(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Motion.of(context, Motion.medium),
      switchInCurve: Motion.standard,
      switchOutCurve: Motion.standard,
      child: KeyedSubtree(key: ValueKey(_page), child: _pageAt()),
    );
  }

  Widget _pageAt() {
    final l10n = AppLocalizations.of(context);
    final keepLabel = l10n.translate(
      'estimate_keep',
      replacements: {'n': '${widget.currentYears}'},
    );
    if (_page == QuestionSteps.basics) return _basics(l10n, keepLabel);
    if (_page == _resultIndex) return _result(keepLabel);
    final factor = QuestionSteps.factorAt(_page);
    return factor == null ? _conditions() : _question(factor);
  }

  Widget _basics(AppLocalizations l10n, String keepLabel) {
    final data = _data;
    return BasicsPage(
      countryName: data?.countries.name(_country, l10n.locale.languageCode),
      sex: _sex,
      baselineYears: data == null
          ? null
          : _baseline.of(data.tables, _country, _sex),
      answeredCount: QuestionSteps.answeredCount(_answers),
      showQuestions: _isAdult,
      loading: data == null,
      failed: _failed,
      keepLabel: keepLabel,
      onPickCountry: _pickCountry,
      onSexChanged: (sex) => setState(() => _sex = sex),
      onQuestions: () => _goTo(QuestionSteps.firstQuestion),
      onShowEstimate: () => _goTo(_resultIndex),
      onKeep: widget.onSkip,
      subject: widget.subject,
      intro: widget.intro,
    );
  }

  Widget _result(String keepLabel) => ResultPage(
    estimate: _estimate!,
    years: _years!,
    currentYears: widget.currentYears,
    keepLabel: keepLabel,
    showConditionsNote: _hasConditions,
    onYearsChanged: (years) => setState(() => _years = years),
    onApply: _apply,
    onKeep: widget.onSkip,
    subject: widget.subject,
  );

  Widget _conditions() => ConditionsPage(
    answer: _answers.conditions,
    onAnswer: _setConditions,
    onNext: () => _goTo(_resultIndex),
    onSkip: _skipConditions,
    subject: widget.subject,
  );

  Widget _question(LifestyleFactor factor) {
    final isLast = QuestionSteps.isLastQuestion(_page);
    void next() => _goTo(_page + 1);
    void skipRest() => _goTo(_resultIndex);
    if (factor == LifestyleFactor.bmi) {
      return WeightPage(
        answer: _answers.bmi,
        isLast: isLast,
        onAnswer: (band) => _setAnswer(factor, band),
        onNext: next,
        onSkipRest: skipRest,
        subject: widget.subject,
      );
    }
    return QuestionPage(
      factor: factor,
      answer: _answers.answerFor(factor),
      isLast: isLast,
      onAnswer: (option) => _setAnswer(factor, option),
      onNext: next,
      onSkipRest: skipRest,
      subject: widget.subject,
    );
  }
}
