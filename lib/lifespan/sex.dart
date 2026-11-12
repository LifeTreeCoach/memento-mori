/// Sex used to pick the life table.
///
/// [unspecified] never uses the WPP "Both" table in the estimator (see
/// `lifespan_estimator.dart`): it averages the female and male survival curves.
enum Sex {
  female,
  male,
  unspecified;

  static Sex? fromName(String? name) {
    for (final sex in values) {
      if (sex.name == name) return sex;
    }
    return null;
  }
}
