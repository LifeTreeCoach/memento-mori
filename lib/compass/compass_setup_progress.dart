import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The steps of the resumable Compass setup, in order.
enum SetupStep { phase, duration, intention, rhythm }

/// How far the user got through the Compass setup. Whether the phase and
/// first intention exist is derived from the data (`setup_flow.dart`); this
/// only remembers choices that leave no data behind.
@immutable
class CompassSetupProgress {
  const CompassSetupProgress({
    this.completed = const {},
    this.skipped = const {},
    this.lastStep,
    this.cardDismissed = false,
    this.autoOpened = false,
  });

  static const CompassSetupProgress empty = CompassSetupProgress();

  /// Tolerant reader: unknown steps and wrong types are ignored.
  factory CompassSetupProgress.fromJson(Object? json) {
    if (json is! Map) return empty;
    return CompassSetupProgress(
      completed: _steps(json['completed']),
      skipped: _steps(json['skipped']),
      lastStep: _step(json['lastStep']),
      cardDismissed: json['cardDismissed'] == true,
      autoOpened: json['autoOpened'] == true,
    );
  }

  /// Steps the user finished.
  final Set<SetupStep> completed;

  /// Steps the user skipped (offered again on resume).
  final Set<SetupStep> skipped;

  /// The step that was open when the setup was left, if any.
  final SetupStep? lastStep;

  /// The setup checklist card was hidden.
  final bool cardDismissed;

  /// The setup already opened by itself once.
  final bool autoOpened;

  Map<String, dynamic> toJson() => {
        'completed': [for (final s in SetupStep.values) if (completed.contains(s)) s.name],
        'skipped': [for (final s in SetupStep.values) if (skipped.contains(s)) s.name],
        if (lastStep != null) 'lastStep': lastStep!.name,
        'cardDismissed': cardDismissed,
        'autoOpened': autoOpened,
      };

  /// Copy with changed fields; [clearLastStep] sets [lastStep] to null.
  CompassSetupProgress copyWith({
    Set<SetupStep>? completed,
    Set<SetupStep>? skipped,
    SetupStep? lastStep,
    bool clearLastStep = false,
    bool? cardDismissed,
    bool? autoOpened,
  }) {
    return CompassSetupProgress(
      completed: completed ?? this.completed,
      skipped: skipped ?? this.skipped,
      lastStep: clearLastStep ? null : lastStep ?? this.lastStep,
      cardDismissed: cardDismissed ?? this.cardDismissed,
      autoOpened: autoOpened ?? this.autoOpened,
    );
  }

  /// [step] finished: no longer skipped.
  CompassSetupProgress markCompleted(SetupStep step) => copyWith(
        completed: {...completed, step},
        skipped: {...skipped}..remove(step),
      );

  /// [step] put off with "Later": the setup closes and resumes there.
  CompassSetupProgress markSkipped(SetupStep step) => copyWith(
        skipped: {...skipped, step},
        lastStep: step,
      );

  static SetupStep? _step(Object? name) {
    for (final step in SetupStep.values) {
      if (step.name == name) return step;
    }
    return null;
  }

  static Set<SetupStep> _steps(Object? json) {
    if (json is! List) return const {};
    return {for (final name in json) ?_step(name)};
  }

  @override
  bool operator ==(Object other) {
    return other is CompassSetupProgress &&
        setEquals(other.completed, completed) &&
        setEquals(other.skipped, skipped) &&
        other.lastStep == lastStep &&
        other.cardDismissed == cardDismissed &&
        other.autoOpened == autoOpened;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAllUnordered(completed),
        Object.hashAllUnordered(skipped),
        lastStep,
        cardDismissed,
        autoOpened,
      );

  @override
  String toString() => 'CompassSetupProgress(${toJson()})';
}

/// Stores the [CompassSetupProgress] in SharedPreferences.
class CompassSetupStore {
  static const String key = 'compass_setup';

  static CompassSetupProgress _progress = CompassSetupProgress.empty;
  static bool _isInitialized = false;

  /// Bumped after every change, so screens can reload.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  /// Loads the stored progress once.
  static Future<void> initialize() async {
    if (_isInitialized) return;
    final prefs = await SharedPreferences.getInstance();
    _progress = _decode(prefs.getString(key));
    _isInitialized = true;
  }

  /// Drops the in-memory cache so the next [initialize] re-reads storage.
  @visibleForTesting
  static void clearCacheForTesting() {
    _progress = CompassSetupProgress.empty;
    _isInitialized = false;
  }

  /// The stored progress (after [initialize]).
  static CompassSetupProgress get progress => _progress;

  static Future<CompassSetupProgress> load() async {
    await initialize();
    return _progress;
  }

  static Future<void> save(CompassSetupProgress progress) async {
    _progress = progress;
    _isInitialized = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(progress.toJson()));
    revision.value++;
  }

  /// Forgets all progress (diagnostics "reset setup").
  static Future<void> reset() async {
    _progress = CompassSetupProgress.empty;
    _isInitialized = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
    revision.value++;
  }

  static CompassSetupProgress _decode(String? source) {
    if (source == null) return CompassSetupProgress.empty;
    try {
      return CompassSetupProgress.fromJson(jsonDecode(source));
    } on FormatException catch (e) {
      debugPrint('Error loading Compass setup progress: $e');
      return CompassSetupProgress.empty;
    }
  }
}
