/// Title and intro of the estimate's first page when the caller words them
/// itself (the onboarding greets the user by name). Without one the page
/// uses the subject's own `estimate_title` and `estimate_intro`.
class EstimateIntro {
  const EstimateIntro({required this.title, required this.text});

  final String title;
  final String text;
}
