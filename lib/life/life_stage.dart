/// Broad life stages (after Erikson), derived from full years of age.
enum LifeStage {
  young,
  exploring,
  building,
  midlife,
  harvest,
  wisdom;

  /// The stage for [ageYears]: young <18, exploring 18-29, building 30-44,
  /// midlife 45-59, harvest 60-74, wisdom 75+.
  static LifeStage fromAge(int ageYears) {
    if (ageYears < 18) return young;
    if (ageYears < 30) return exploring;
    if (ageYears < 45) return building;
    if (ageYears < 60) return midlife;
    if (ageYears < 75) return harvest;
    return wisdom;
  }
}
