import 'package:memento_mori_life_in_weeks/lifespan/lifestyle_model.dart';

/// Page indices of the estimate flow: basics, one question per lifestyle
/// factor, the chronic conditions question (always last), result.
abstract final class QuestionSteps {
  /// The basics page (country and sex).
  static const int basics = 0;

  /// The first question page.
  static const int firstQuestion = 1;

  /// Number of optional questions: the lifestyle factors plus conditions.
  static final int questionCount = LifestyleFactor.values.length + 1;

  /// The chronic conditions page, the last question.
  static final int conditions = questionCount;

  /// The result page.
  static final int result = questionCount + 1;

  /// Whether [page] is the last question.
  static bool isLastQuestion(int page) => page == conditions;

  /// The lifestyle factor asked on [page], or null for the other pages.
  static LifestyleFactor? factorAt(int page) =>
      page >= firstQuestion && page < conditions
      ? LifestyleFactor.values[page - firstQuestion]
      : null;

  /// How many of the questions [answers] answers (conditions included).
  static int answeredCount(LifestyleAnswers answers) =>
      LifestyleFactor.values.where((f) => answers.answerFor(f) != null).length +
      (answers.conditions == null ? 0 : 1);
}
