/// How the Life tab draws a life: the week grid or an alternative layout.
enum LayoutType { grid, spiral, liquid, treeRings }

/// Display options of the Life tab, persisted as a map.
class VisualizationSettings {
  final bool enableGradients;
  final bool enableMilestones;
  final bool enableSeasons;
  final bool enableAnimations;
  final LayoutType layoutType;

  /// Colours the life visualisation by the Compass life phases.
  final bool showPhases;

  const VisualizationSettings({
    this.enableGradients = false,
    this.enableMilestones = true,
    this.enableSeasons = false,
    this.enableAnimations = true,
    this.layoutType = LayoutType.grid,
    this.showPhases = true,
  });

  VisualizationSettings copyWith({
    bool? enableGradients,
    bool? enableMilestones,
    bool? enableSeasons,
    bool? enableAnimations,
    LayoutType? layoutType,
    bool? showPhases,
  }) {
    return VisualizationSettings(
      enableGradients: enableGradients ?? this.enableGradients,
      enableMilestones: enableMilestones ?? this.enableMilestones,
      enableSeasons: enableSeasons ?? this.enableSeasons,
      enableAnimations: enableAnimations ?? this.enableAnimations,
      layoutType: layoutType ?? this.layoutType,
      showPhases: showPhases ?? this.showPhases,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enableGradients': enableGradients,
      'enableMilestones': enableMilestones,
      'enableSeasons': enableSeasons,
      'enableAnimations': enableAnimations,
      'layoutType': layoutType.index,
      'showPhases': showPhases,
    };
  }

  factory VisualizationSettings.fromMap(Map<String, dynamic> map) {
    return VisualizationSettings(
      enableGradients: map['enableGradients'] ?? false,
      enableMilestones: map['enableMilestones'] ?? true,
      enableSeasons: map['enableSeasons'] ?? false,
      enableAnimations: map['enableAnimations'] ?? true,
      layoutType: LayoutType.values[map['layoutType'] ?? 0],
      showPhases: map['showPhases'] is bool ? map['showPhases'] as bool : true,
    );
  }
}
