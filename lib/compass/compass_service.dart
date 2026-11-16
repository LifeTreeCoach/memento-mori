import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/life_phase.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_timeline.dart';
import 'package:memento_mori_life_in_weeks/compass/weekly_question.dart';
import 'package:memento_mori_life_in_weeks/life/life_period.dart';
import 'package:memento_mori_life_in_weeks/security/personal_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// New entries per kind from [CompassService.importDataCounts].
typedef CompassImportCounts = ({int intentions, int moments, int phases});

/// Outcome of [CompassService.addIntention]: the saved intention, and
/// whether "Now" was full so it went to "Someday" instead.
@immutable
class AddIntentionResult {
  const AddIntentionResult(this.intention, {required this.nowLimitReached});

  final Intention intention;

  /// True if "Now" was asked for but already held [nowLimit] intentions.
  final bool nowLimitReached;
}

/// What happened to this week's question (one ISO week at a time).
@immutable
class CompassWeekState {
  const CompassWeekState(this.week, {this.swapped = false, this.dismissed = false});

  /// ISO week key, e.g. `2026-W45` ([isoWeekKey]).
  final String week;

  /// The question was swapped (allowed once a week).
  final bool swapped;

  /// The question was put away for this week.
  final bool dismissed;

  Map<String, dynamic> toJson() =>
      {'week': week, 'swapped': swapped, 'dismissed': dismissed};

  /// State stored for [week]; a state of another week (or none) is fresh.
  static CompassWeekState forWeek(String week, Object? json) {
    if (json is! Map || json['week'] != week) return CompassWeekState(week);
    return CompassWeekState(
      week,
      swapped: json['swapped'] == true,
      dismissed: json['dismissed'] == true,
    );
  }
}

/// Stores Compass intentions, moments and life phases ([dataKey]) in the
/// [PersonalStore]; settings and the week state stay in SharedPreferences.
class CompassService {
  static const String dataKey = PersonalKeys.compassData;
  static const String gentleOnlyKey = 'compass_gentle_only';
  static const String showGridMarksKey = 'compass_grid_marks';
  static const String weekStateKey = 'compass_week_state';
  static const String showLifeCardKey = 'compass_life_card';
  static const String showReflectionKey = 'compass_reflection';

  static CompassData _data = CompassData.empty;
  static bool _gentleOnly = false;
  static bool _showGridMarks = true;
  static bool _showLifeCard = true;
  static bool _showReflection = true;
  static Object? _weekStateJson;
  static bool _isInitialized = false;
  static int _idCounter = 0;

  /// True when the stored [dataKey] could not be read this session: saves
  /// are refused so the unreadable data is never replaced by empty data.
  static bool _readOnly = false;

  /// Whether saving is disabled because the stored data was unreadable.
  static bool get isReadOnly => _readOnly;

  /// Bumped after every change (data or settings), so screens can reload.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  /// Loads the stored data once.
  static Future<void> initialize() async {
    if (_isInitialized) return;
    await _loadData();
    final prefs = await SharedPreferences.getInstance();
    _gentleOnly = prefs.getBool(gentleOnlyKey) ?? false;
    _showGridMarks = prefs.getBool(showGridMarksKey) ?? true;
    _showLifeCard = prefs.getBool(showLifeCardKey) ?? true;
    _showReflection = prefs.getBool(showReflectionKey) ?? true;
    _weekStateJson = _decode<Object?>(prefs.getString(weekStateKey), (json) => json);
    _isInitialized = true;
  }

  /// Drops the in-memory cache so the next [initialize] re-reads storage.
  @visibleForTesting
  static void clearCacheForTesting() {
    _data = CompassData.empty;
    _gentleOnly = false;
    _showGridMarks = true;
    _showLifeCard = true;
    _showReflection = true;
    _weekStateJson = null;
    _readOnly = false;
    _isInitialized = false;
  }

  /// Reads [dataKey] from the [PersonalStore] (re-read first). On any
  /// failure the data is empty and the session read-only (see [isReadOnly]).
  static Future<void> _loadData() async {
    _readOnly = false;
    try {
      final store = PersonalStore.instance;
      await store.reload();
      final source = store.getString(dataKey);
      _data = source == null
          ? CompassData.empty
          : CompassData.fromJson(jsonDecode(source));
    } catch (e) {
      debugPrint(
          'Error loading Compass data (${e.runtimeType}); saving disabled this session');
      _data = CompassData.empty;
      _readOnly = true;
    }
  }

  static T? _decode<T>(String? source, T Function(Object? json) parse) {
    if (source == null) return null;
    try {
      return parse(jsonDecode(source));
    } on FormatException catch (e) {
      debugPrint('Error loading Compass week state (${e.runtimeType})');
      return null;
    }
  }

  /// Everything stored (after [initialize]).
  static CompassData get data => _data;

  static Future<CompassData> load() async {
    await initialize();
    return _data;
  }

  /// Saves [data]; refused (nothing changes) while [isReadOnly].
  static Future<void> _save(CompassData data) async {
    if (_readOnly) {
      debugPrint('CompassService: stored data unreadable, change not saved');
      return;
    }
    _data = data;
    await PersonalStore.instance.setString(dataKey, jsonEncode(data.toJson()));
    revision.value++;
  }

  static String _newId(DateTime now) =>
      '${now.microsecondsSinceEpoch}${_idCounter++}';

  /// A fresh unique id, e.g. for the next phase passed to [closePhase].
  static String newId() => _newId(DateTime.now());

  static DateTime _today(DateTime? today) => compassDate(today ?? DateTime.now());

  // Intentions

  /// Saves a new intention. [status] now goes to "Someday" when "Now" is
  /// full (reported by [AddIntentionResult.nowLimitReached]); nothing is
  /// ever dropped. A done [status] is treated as someday. A "Now"
  /// intention belongs to the current phase.
  static Future<AddIntentionResult> addIntention({
    required String title,
    String? note,
    LifeArea? area,
    Horizon? horizon,
    IntentionStatus status = IntentionStatus.now,
    DateTime? today,
    String? friendId,
    IntentionKind? kind,
    DateTime? dueDate,
  }) async {
    await initialize();
    final wantsNow = status == IntentionStatus.now;
    final limitReached = wantsNow && _data.isNowFull;
    final day = _today(today);
    final isNow = wantsNow && !limitReached;
    final intention = Intention(
      id: _newId(DateTime.now()),
      title: title,
      note: note,
      area: area,
      horizon: horizon,
      status: isNow ? IntentionStatus.now : IntentionStatus.someday,
      createdAt: day,
      friendId: friendId,
      kind: kind,
      dueDate: dueDate,
      phaseId: isNow ? currentPhase(today: day)?.id : null,
    );
    await _save(_data.copyWith(intentions: [..._data.intentions, intention]));
    return AddIntentionResult(intention, nowLimitReached: limitReached);
  }

  /// The open ("Now" or "Someday") intention about friend [friendId], if
  /// any. Intentions saved before they were linked to a person match by
  /// their exact [title] instead.
  static Future<Intention?> openIntentionForFriend(
    String friendId, {
    required String title,
  }) async {
    await initialize();
    for (final intention in _data.intentions) {
      if (!intention.isOpen) continue;
      final linked = intention.friendId;
      if (linked == friendId || (linked == null && intention.title == title)) {
        return intention;
      }
    }
    return null;
  }

  /// Moves intention [id] to "Now" and into the current phase; false (and
  /// no change) if "Now" is full. A done or let-go intention is reopened.
  /// Throws [StateError] for unknown ids.
  static Future<bool> moveToNow(String id, {DateTime? today}) async {
    await initialize();
    final intention = _intention(id);
    if (intention.status == IntentionStatus.now) return true;
    if (_data.isNowFull) return false;
    await _replaceIntention(intention
        .copyWith(status: IntentionStatus.now, clearDoneAt: true)
        .withPhase(currentPhase(today: today)?.id));
    return true;
  }

  /// Moves intention [id] to "Someday" (reopens a done one); "Someday"
  /// belongs to no phase.
  static Future<void> moveToSomeday(String id) async {
    await initialize();
    final intention = _intention(id);
    await _replaceIntention(intention
        .copyWith(status: IntentionStatus.someday, clearDoneAt: true)
        .withPhase(null));
  }

  /// Lets intention [id] go on [today]: no longer open, but kept and shown.
  static Future<void> letGoIntention(String id, {DateTime? today}) async {
    await initialize();
    await _replaceIntention(_intention(id).letGo(_today(today)));
  }

  /// Puts [previous] back exactly as it was (undo of [letGoIntention]).
  /// Throws [StateError] for unknown ids.
  static Future<void> restoreIntention(Intention previous) async {
    await initialize();
    _intention(previous.id);
    await _replaceIntention(previous);
  }

  /// Saves the title, note, area, horizon, kind and due date of [edited];
  /// its status, phase and dates stay as stored (use [moveToNow],
  /// [moveToSomeday], [complete]).
  static Future<void> editIntention(Intention edited) async {
    await initialize();
    final stored = _intention(edited.id);
    await _replaceIntention(Intention(
      id: stored.id,
      title: edited.title,
      note: edited.note,
      area: edited.area,
      horizon: edited.horizon,
      status: stored.status,
      createdAt: stored.createdAt,
      doneAt: stored.doneAt,
      friendId: stored.friendId,
      kind: edited.kind,
      dueDate: edited.dueDate,
      phaseId: stored.phaseId,
      letGoAt: stored.letGoAt,
    ));
  }

  /// Marks intention [id] done and records a moment for it on [today].
  static Future<Moment> complete(String id, {DateTime? today}) async {
    await initialize();
    final intention = _intention(id);
    final day = _today(today);
    final moment = Moment(
      id: _newId(DateTime.now()),
      title: intention.title,
      date: day,
      area: intention.area,
      fromIntentionId: intention.id,
    );
    await _save(_data.copyWith(
      intentions: _replaced(
          intention.copyWith(status: IntentionStatus.done, doneAt: day)),
      moments: [..._data.moments, moment],
    ));
    return moment;
  }

  /// Undoes [complete]: [previous] gets its status back ("Someday" if it
  /// was in "Now" and "Now" has filled up since) and the moment [momentId]
  /// recorded for it is removed. Missing entries are skipped.
  static Future<void> undoComplete(Intention previous, String momentId) async {
    await initialize();
    final exists = _data.intentions.any((i) => i.id == previous.id);
    final backToNow =
        previous.status == IntentionStatus.now && !_data.isNowFull;
    final restored = previous.status == IntentionStatus.now && !backToNow
        ? previous.copyWith(status: IntentionStatus.someday).withPhase(null)
        : previous;
    await _save(_data.copyWith(
      intentions: exists ? _replaced(restored) : _data.intentions,
      moments: _data.moments.where((m) => m.id != momentId).toList(),
    ));
  }

  /// Deletes intention [id]; moments recorded from it stay.
  static Future<void> deleteIntention(String id) async {
    await initialize();
    _intention(id);
    await _save(_data.copyWith(
        intentions: _data.intentions.where((i) => i.id != id).toList()));
  }

  static Intention _intention(String id) => _data.intentions.firstWhere(
        (i) => i.id == id,
        orElse: () => throw StateError('Intention $id not found'),
      );

  static List<Intention> _replaced(Intention intention) => [
        for (final i in _data.intentions) i.id == intention.id ? intention : i,
      ];

  static Future<void> _replaceIntention(Intention intention) =>
      _save(_data.copyWith(intentions: _replaced(intention)));

  // Moments

  /// Records a moment on [date] (any day, also in the past), with an
  /// optional [note].
  static Future<Moment> addMoment({
    required String title,
    required DateTime date,
    LifeArea? area,
    String? note,
  }) async {
    await initialize();
    final moment = Moment(
      id: _newId(DateTime.now()),
      title: title,
      date: date,
      area: area,
      note: nonEmptyCompassString(note)?.trim(),
    );
    await _save(_data.copyWith(moments: [..._data.moments, moment]));
    return moment;
  }

  /// Saves the title, date, area and note of [edited] (a blank note is
  /// removed).
  static Future<void> editMoment(Moment edited) async {
    await initialize();
    final stored = _moment(edited.id);
    final note = nonEmptyCompassString(edited.note)?.trim();
    await _replaceMoment(stored.copyWith(
      title: edited.title,
      date: edited.date,
      area: edited.area,
      clearArea: edited.area == null,
      note: note,
      clearNote: note == null,
    ));
  }

  /// Sets the note of moment [id] (blank: removes it). Throws [StateError]
  /// for unknown ids.
  static Future<void> setMomentNote(String id, String? note) async {
    await initialize();
    final text = nonEmptyCompassString(note)?.trim();
    await _replaceMoment(
        _moment(id).copyWith(note: text, clearNote: text == null));
  }

  static Future<void> _replaceMoment(Moment updated) =>
      _save(_data.copyWith(moments: [
        for (final m in _data.moments) m.id == updated.id ? updated : m,
      ]));

  static Future<void> deleteMoment(String id) async {
    await initialize();
    _moment(id);
    await _save(_data.copyWith(
        moments: _data.moments.where((m) => m.id != id).toList()));
  }

  static Moment _moment(String id) => _data.moments.firstWhere(
        (m) => m.id == id,
        orElse: () => throw StateError('Moment $id not found'),
      );

  /// Moments inside [period] (one grid cell), oldest first.
  static List<Moment> momentsIn(LifePeriod period) =>
      momentsBetween(period.start, period.end);

  /// Moments from [start] (inclusive) to [end] (exclusive), oldest first.
  static List<Moment> momentsBetween(DateTime start, DateTime end) =>
      _data.momentsBetween(start, end);

  // Life phases

  /// The phase lived on [today] (default: now), or null before the first.
  static LifePhase? currentPhase({DateTime? today}) =>
      currentSpan(_data.phases, _today(today))?.phase;

  /// Saves a new phase starting on [start]. When it is the current phase
  /// on [today], "Now" intentions without a phase join it.
  static Future<LifePhase> startPhase({
    PhasePreset? preset,
    String name = '',
    required DateTime start,
    DateTime? plannedEnd,
    DateTime? today,
  }) async {
    await initialize();
    final phase = LifePhase(id: newId(), name: name, preset: preset,
        start: start, plannedEnd: plannedEnd);
    final phases = [..._data.phases, phase];
    final isCurrent = currentSpan(phases, _today(today))?.phase.id == phase.id;
    await _save(_data.copyWith(
      phases: phases,
      intentions: isCurrent ? _nowJoining(phase.id) : _data.intentions,
    ));
    return phase;
  }

  static List<Intention> _nowJoining(String phaseId) => [
        for (final i in _data.intentions)
          i.status == IntentionStatus.now && i.phaseId == null
              ? i.withPhase(phaseId)
              : i,
      ];

  /// Saves every field of [edited]. Throws [StateError] for unknown ids.
  static Future<void> editPhase(LifePhase edited) async {
    await initialize();
    _phase(edited.id);
    await _save(_data.copyWith(phases: _replacedPhase(edited)));
  }

  /// Deletes phase [id]; its intentions stay, without a phase.
  static Future<void> deletePhase(String id) async {
    await initialize();
    _phase(id);
    await _save(_data.copyWith(
      phases: _data.phases.where((p) => p.id != id).toList(),
      intentions: [
        for (final i in _data.intentions) i.phaseId == id ? i.withPhase(null) : i,
      ],
    ));
  }

  /// Closes phase [closingId] in one save: keeps [note] ("what was good")
  /// on it, adds [next], moves the intentions in [carryOver] into [next] and
  /// lets those in [letGo] go on [today]. Throws [StateError] for unknown
  /// [closingId].
  static Future<void> closePhase({
    required String closingId,
    String? note,
    required LifePhase next,
    required Set<String> carryOver,
    required Set<String> letGo,
    DateTime? today,
  }) async {
    await initialize();
    final closed = _phase(closingId).copyWith(note: nonEmptyCompassString(note));
    final day = _today(today);
    await _save(_data.copyWith(
      phases: [..._replacedPhase(closed), next],
      intentions: [
        for (final i in _data.intentions)
          carryOver.contains(i.id)
              ? i.withPhase(next.id)
              : letGo.contains(i.id) ? i.letGo(day) : i,
      ],
    ));
  }

  static LifePhase _phase(String id) => _data.phases.firstWhere(
        (p) => p.id == id,
        orElse: () => throw StateError('Life phase $id not found'),
      );

  static List<LifePhase> _replacedPhase(LifePhase phase) => [
        for (final p in _data.phases) p.id == phase.id ? phase : p,
      ];

  // Backup

  /// Adds the intentions, moments and phases of [imported] whose ids are not
  /// stored yet; imported "Now" intentions beyond [nowLimit] go to "Someday".
  /// Returns the number added.
  ///
  /// [friendIds] (from `FriendsService.importBackup`) maps the backup's
  /// friend ids to the people in this app; when given, each added
  /// intention's `friendId` is rewritten through it, and a link to nobody
  /// in it is dropped. Null keeps the links as they are (e.g. undo).
  static Future<int> importData(
    CompassData imported, {
    Map<String, String>? friendIds,
  }) async {
    final added = await importDataCounts(imported, friendIds: friendIds);
    return added.intentions + added.moments + added.phases;
  }

  /// Like [importData], but reports the new entries per kind.
  static Future<CompassImportCounts> importDataCounts(
    CompassData imported, {
    Map<String, String>? friendIds,
  }) async {
    await initialize();
    final intentionIds = _data.intentions.map((i) => i.id).toSet();
    final momentIds = _data.moments.map((m) => m.id).toSet();
    final intentions = [..._data.intentions];
    var nowCount = _data.nowCount;
    for (final original in imported.intentions) {
      if (!intentionIds.add(original.id)) continue;
      final intention = _relinked(original, friendIds);
      final isNow = intention.status == IntentionStatus.now;
      if (isNow && nowCount >= nowLimit) {
        intentions.add(
            intention.copyWith(status: IntentionStatus.someday).withPhase(null));
        continue;
      }
      if (isNow) nowCount++;
      intentions.add(intention);
    }
    final newMoments =
        imported.moments.where((m) => momentIds.add(m.id)).toList();
    final newPhases = _newPhases(imported.phases);
    final added = (
      intentions: intentions.length - _data.intentions.length,
      moments: newMoments.length,
      phases: newPhases.length,
    );
    if (added.intentions + added.moments + added.phases == 0) return added;
    await _save(CompassData(
      intentions: intentions,
      moments: [..._data.moments, ...newMoments],
      phases: [..._data.phases, ...newPhases],
    ));
    return added;
  }

  /// [intention] linked to its person's id in this app (see [importData]).
  /// Intention ids are kept on import, so moments' `fromIntentionId` stay
  /// valid without mapping.
  static Intention _relinked(
      Intention intention, Map<String, String>? friendIds) {
    final linked = intention.friendId;
    if (friendIds == null || linked == null) return intention;
    return intention.withFriend(friendIds[linked]);
  }

  static List<LifePhase> _newPhases(List<LifePhase> imported) {
    final ids = _data.phases.map((p) => p.id).toSet();
    return imported.where((p) => ids.add(p.id)).toList();
  }

  // Settings

  /// Weekly questions without courage prompts.
  static bool get gentleOnly => _gentleOnly;

  static Future<void> setGentleOnly(bool value) =>
      _setBool(gentleOnlyKey, value, () => _gentleOnly = value);

  /// Moments are marked on the life grid (default true).
  static bool get showGridMarks => _showGridMarks;

  static Future<void> setShowGridMarks(bool value) =>
      _setBool(showGridMarksKey, value, () => _showGridMarks = value);

  /// The question of the week is shown on the Life tab (default true).
  static bool get showLifeCard => _showLifeCard;

  static Future<void> setShowLifeCard(bool value) =>
      _setBool(showLifeCardKey, value, () => _showLifeCard = value);

  /// A calm look back opens after completing an intention (default true);
  /// off: a short "well done" snackbar with undo instead.
  static bool get showReflection => _showReflection;

  static Future<void> setShowReflection(bool value) =>
      _setBool(showReflectionKey, value, () => _showReflection = value);

  static Future<void> _setBool(String key, bool value, VoidCallback apply) async {
    await initialize();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    apply();
    revision.value++;
  }

  // Weekly question

  /// State of the question in the ISO week of [date].
  static CompassWeekState weekState(DateTime date) =>
      CompassWeekState.forWeek(isoWeekKey(date), _weekStateJson);

  /// Marks the question of [date]'s week swapped; false if it already was
  /// (one swap per week).
  static Future<bool> swapQuestion(DateTime date) async {
    await initialize();
    final state = weekState(date);
    if (state.swapped) return false;
    await _saveWeekState(CompassWeekState(state.week,
        swapped: true, dismissed: state.dismissed));
    return true;
  }

  /// Puts the question of [date]'s week away until next week.
  static Future<void> dismissQuestion(DateTime date) async {
    await initialize();
    final state = weekState(date);
    await _saveWeekState(
        CompassWeekState(state.week, swapped: state.swapped, dismissed: true));
  }

  /// Shows the question of [date]'s week again after [dismissQuestion]
  /// (Compass tab and Life-tab card).
  static Future<void> restoreQuestion(DateTime date) async {
    await initialize();
    final state = weekState(date);
    if (!state.dismissed) return;
    await _saveWeekState(CompassWeekState(state.week, swapped: state.swapped));
  }

  static Future<void> _saveWeekState(CompassWeekState state) async {
    _weekStateJson = state.toJson();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(weekStateKey, jsonEncode(_weekStateJson));
    revision.value++;
  }
}
