import 'package:flutter/material.dart';
import 'package:memento_mori_life_in_weeks/app_settings_controller.dart';
import 'package:memento_mori_life_in_weeks/app_shell.dart';
import 'package:memento_mori_life_in_weeks/lifespan/lifespan_estimator.dart';
import 'package:memento_mori_life_in_weeks/lifespan/lifestyle_model.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/estimate_intro.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/lifespan_data.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/lifespan_estimate_flow.dart';
import 'package:memento_mori_life_in_weeks/lifespan/ui/lifespan_profile.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/onboarding/birth_date_step.dart';
import 'package:memento_mori_life_in_weeks/onboarding/language_button.dart';
import 'package:memento_mori_life_in_weeks/onboarding/onboarding_answers.dart';
import 'package:memento_mori_life_in_weeks/onboarding/personal_address.dart';
import 'package:memento_mori_life_in_weeks/onboarding/reminder_opt_in.dart';
import 'package:memento_mori_life_in_weeks/onboarding/reminders_step.dart';
import 'package:memento_mori_life_in_weeks/onboarding/reveal_step.dart';
import 'package:memento_mori_life_in_weeks/onboarding/step_dots.dart';
import 'package:memento_mori_life_in_weeks/onboarding/support_step.dart';
import 'package:memento_mori_life_in_weeks/onboarding/theme_toggle.dart';
import 'package:memento_mori_life_in_weeks/settings/sponsor_link.dart';
import 'package:memento_mori_life_in_weeks/settings_service.dart';
import 'package:memento_mori_life_in_weeks/support/support_channel.dart';
import 'package:memento_mori_life_in_weeks/support/support_scope.dart';
import 'package:memento_mori_life_in_weeks/theme/motion.dart';
import 'package:memento_mori_life_in_weeks/theme/theme_options.dart';

/// The onboarding steps, in the order they are shown.
enum OnboardingStep { birthDate, estimate, reveal, reminders, support }

/// First-launch flow: birth date → lifespan estimate → the reveal →
/// reminders → support (skippable), then the app. Store builds
/// ([SupportChannel.rate], from [SupportScope]) have no support step:
/// the reminders choice finishes the flow. The estimate and the reveal
/// greet the user by the name from the first step ([PersonalAddress]).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.onLanguageChange,
    this.reminders = const SystemReminderOptIn(),
    this.now,
    this.loadLifespanData = LifespanData.load,
    this.openSupportLink = openSponsorLink,
  });

  /// Reloads app settings when no [AppSettingsScope] is available.
  final VoidCallback onLanguageChange;
  final ReminderOptIn reminders;

  /// Fixed "today" for tests; defaults to the clock.
  final DateTime? now;

  /// Loads the life tables for the estimate step; injectable for tests.
  final LifespanDataLoader loadLifespanData;

  /// Opens the sponsor page from the support step; injectable for tests.
  final SponsorLinkOpener openSupportLink;

  /// Steps in display order; adding a step = one enum value + its page.
  static const List<OnboardingStep> steps = OnboardingStep.values;

  /// The steps shown for [channel]: all of [steps] with the coffee link,
  /// without [OnboardingStep.support] in store builds.
  static List<OnboardingStep> stepsFor(SupportChannel channel) =>
      switch (channel) {
        SupportChannel.link => steps,
        SupportChannel.rate => [
          for (final step in steps)
            if (step != OnboardingStep.support) step,
        ],
      };

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  List<OnboardingStep> get _steps =>
      OnboardingScreen.stepsFor(SupportScope.of(context).channel);

  final OnboardingAnswers _answers = OnboardingAnswers.fromSettings();
  late final TextEditingController _nameController = TextEditingController(
    text: _answers.name,
  );

  final GlobalKey<LifespanEstimateFlowState> _estimateFlow = GlobalKey();

  /// Index into [_steps].
  int _step = 0;
  bool _revealed = false;
  bool _finishing = false;

  DateTime get _today => widget.now ?? DateTime.now();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  OnboardingStep get _current => _steps[_step];

  void _goTo(OnboardingStep step) {
    FocusScope.of(context).unfocus();
    setState(() => _step = _steps.indexOf(step));
  }

  void _next() => _goTo(_steps[_step + 1]);

  void _back() {
    if (_current == OnboardingStep.estimate &&
        (_estimateFlow.currentState?.back() ?? false)) {
      return;
    }
    _goTo(_steps[_step - 1]);
  }

  void _setBirthDate(DateTime date) {
    setState(() {
      _answers.birthDate = date;
      _revealed = false; // a new date earns a new reveal
    });
  }

  void _applyEstimate(
    int years,
    LifespanEstimate estimate,
    LifestyleAnswers answers,
  ) {
    setState(() {
      _answers.lifespan = LifespanProfile.applied(
        estimate: estimate,
        answers: answers,
        years: years,
      );
      _answers.lifeExpectancyYears = OnboardingAnswers.clampLifeExpectancy(
        years,
      );
      _revealed = false; // a new number earns a new reveal
    });
    _next();
  }

  void _setLifeExpectancy(int years) {
    setState(
      () => _answers.lifeExpectancyYears =
          OnboardingAnswers.clampLifeExpectancy(years),
    );
  }

  void _setLanguage(String language) {
    setState(() => _answers.language = language);
    final controller = AppSettingsScope.maybeOf(context);
    if (controller != null) {
      controller.setLanguage(language);
    } else {
      SettingsService.setLanguage(language);
      widget.onLanguageChange();
    }
  }

  /// Saved right away, like the language: the choice outlives onboarding.
  Future<void> _setBrightness(AppBrightness brightness) async {
    final controller = AppSettingsScope.maybeOf(context);
    if (controller != null) return controller.setBrightness(brightness);
    await SettingsService.setBrightness(brightness.id);
    widget.onLanguageChange(); // reloads app settings
  }

  /// Applies the reminder choice right away (the permission prompt belongs
  /// to this question), then moves on to the support step, or finishes
  /// when there is none (store builds).
  Future<void> _chooseReminders({required bool enable}) async {
    setState(() => _finishing = true);
    // Saved first: reminder texts use the name and language.
    await _saveAnswers();
    if (enable) {
      await widget.reminders.enable();
    } else {
      await widget.reminders.skip();
    }
    if (!mounted) return;
    if (_step == _steps.length - 1) return _finish();
    setState(() => _finishing = false);
    _next();
  }

  Future<void> _saveAnswers() {
    _answers.name = _nameController.text;
    return _answers.save(AppSettingsScope.maybeOf(context));
  }

  Future<void> _finish() async {
    setState(() => _finishing = true);
    final transition = Motion.of(context, Motion.long);
    await _saveAnswers();
    SettingsService.setOnboardingCompleted(true);
    if (!mounted) return;
    Navigator.of(context)
        .pushReplacement(_fadeTo(AppShell(now: widget.now), transition));
  }

  static Route<void> _fadeTo(Widget page, Duration duration) {
    return PageRouteBuilder<void>(
      transitionDuration: duration,
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Motion.standard),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_finishing) _back();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _TopBar(
                step: _step,
                count: _steps.length,
                onBack: _step > 0 && !_finishing ? _back : null,
                language: _answers.language,
                onLanguageChanged: _setLanguage,
                onBrightnessChanged: _setBrightness,
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: Motion.of(context, Motion.medium),
                  switchInCurve: Motion.standard,
                  switchOutCurve: Motion.standard,
                  child: KeyedSubtree(
                    key: ValueKey(_step),
                    child: _stepAt(_current),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepAt(OnboardingStep step) {
    // Read on every build: the name is live, a language change rebuilds.
    final address = PersonalAddress(_nameController.text);
    switch (step) {
      case OnboardingStep.birthDate:
        return BirthDateStep(
          birthDate: _answers.birthDate,
          today: _today,
          canContinue: _answers.hasValidBirthDate(_today),
          nameController: _nameController,
          onBirthDateChanged: _setBirthDate,
          onContinue: _next,
        );
      case OnboardingStep.estimate:
        return LifespanEstimateFlow(
          key: _estimateFlow,
          birthDate: _answers.birthDate!,
          currentYears: _answers.lifeExpectancyYears,
          initial: _answers.lifespan,
          loadData: widget.loadLifespanData,
          now: _today,
          onApply: _applyEstimate,
          onSkip: _next,
          intro: _estimateIntro(AppLocalizations.of(context), address),
        );
      case OnboardingStep.reveal:
        return RevealStep(
          calculator: _answers.calculator(_today),
          alreadyRevealed: _revealed,
          onRevealed: () => _revealed = true,
          language: _answers.language,
          onLanguageChanged: _setLanguage,
          onLifeExpectancyChanged: _setLifeExpectancy,
          onContinue: _next,
          address: address,
        );
      case OnboardingStep.reminders:
        return RemindersStep(
          busy: _finishing,
          onEnable: () => _chooseReminders(enable: true),
          onSkip: () => _chooseReminders(enable: false),
        );
      case OnboardingStep.support:
        return SupportStep(
          busy: _finishing,
          onStart: _finish,
          onSupport: () => widget.openSupportLink(context),
        );
    }
  }

  /// The estimate's first page in onboarding words: the life calendar,
  /// starting from the current number of years.
  EstimateIntro _estimateIntro(
    AppLocalizations l10n,
    PersonalAddress address,
  ) => EstimateIntro(
    title: address.translate(l10n, 'onboarding_estimate_title'),
    text: l10n.translate(
      'onboarding_estimate_intro',
      replacements: {'n': '${_answers.lifeExpectancyYears}'},
    ),
  );
}

/// Back arrow (from the second step on) and the step dots, centred; on
/// the right, quiet language and light/dark controls on every step.
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.step,
    required this.count,
    required this.language,
    required this.onLanguageChanged,
    required this.onBrightnessChanged,
    this.onBack,
  });

  final int step;
  final int count;
  final String language;
  final ValueChanged<String> onLanguageChanged;
  final ValueChanged<AppBrightness> onBrightnessChanged;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          StepDots(count: count, index: step),
          if (onBack != null)
            Positioned(
              left: 4,
              child: IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack,
              ),
            ),
          Positioned(right: 4, child: _quietControls()),
        ],
      ),
    );
  }

  Widget _quietControls() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LanguageButton(
          key: const ValueKey('onboarding_language_button'),
          language: language,
          onChanged: onLanguageChanged,
          compact: true,
        ),
        ThemeToggle(onChanged: onBrightnessChanged),
      ],
    );
  }
}
