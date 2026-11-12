/// Neutral links to the project itself, allowed in every build (store builds
/// included): source code and community, never support or money wording.
abstract final class ProjectLinks {
  /// The source code repository; also the homepage foss builds share.
  static const String repository =
      'https://github.com/LifeTreeCoach/memento-mori';

  /// Ideas, questions and feedback.
  static const String discussions = '$repository/discussions';

  /// The privacy policy (`PRIVACY.md` at the repository root).
  static const String privacy = '$repository/blob/main/PRIVACY.md';
}
