import 'package:memento_mori_life_in_weeks/core/life_calculator.dart';

/// Time unit of the life visualisation. [id] is the value persisted in
/// SettingsService.displayMode.
enum LifeMode {
  weeks('weeks'),
  months('months'),
  years('years');

  const LifeMode(this.id);

  final String id;

  /// Unknown or legacy ids (e.g. 'days') fall back to [weeks].
  static LifeMode fromId(String id) {
    return LifeMode.values.firstWhere(
      (mode) => mode.id == id,
      orElse: () => LifeMode.weeks,
    );
  }

  /// Cells standing for one year of life.
  int get cellsPerYear {
    switch (this) {
      case LifeMode.weeks:
        return LifeCalculator.weeksPerYear;
      case LifeMode.months:
        return LifeCalculator.monthsPerYear;
      case LifeMode.years:
        return 1;
    }
  }

  /// Years of life covered by one grid row: one for weeks, two for months
  /// (keeps the grid from becoming a tall narrow column), a decade for
  /// years.
  int get yearsPerRow {
    switch (this) {
      case LifeMode.weeks:
        return 1;
      case LifeMode.months:
        return 2;
      case LifeMode.years:
        return 10;
    }
  }

  /// Cells per grid row.
  int get columns => cellsPerYear * yearsPerRow;

  int totalCells(LifeCalculator calc) {
    switch (this) {
      case LifeMode.weeks:
        return calc.totalWeeks;
      case LifeMode.months:
        return calc.totalMonths;
      case LifeMode.years:
        return calc.totalYears;
    }
  }

  /// Number of completed cells; also the 0-based index of the current one.
  int livedCells(LifeCalculator calc) {
    switch (this) {
      case LifeMode.weeks:
        return calc.weeksLived;
      case LifeMode.months:
        return calc.monthsLived;
      case LifeMode.years:
        return calc.yearsLived;
    }
  }
}
