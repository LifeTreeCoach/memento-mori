import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_timeline.dart';

/// What a life phase held: intentions lived, still open and let go, plus
/// the moments recorded during it.
class PhaseBilanz {
  const PhaseBilanz({
    required this.lived,
    required this.open,
    required this.letGo,
    required this.moments,
  });

  /// Intentions of [span] in [data]; moments from its start up to its end
  /// (exclusive) or, while current, up to and including [today].
  factory PhaseBilanz.of(CompassData data, PhaseSpan span, DateTime today) {
    final ofPhase =
        data.intentions.where((i) => i.phaseId == span.phase.id).toList();
    List<Intention> withStatus(IntentionStatus status) =>
        ofPhase.where((i) => i.status == status).toList();
    return PhaseBilanz(
      lived: withStatus(IntentionStatus.done),
      open: ofPhase.where((i) => i.isOpen).toList(),
      letGo: withStatus(IntentionStatus.letGo),
      moments: data.momentsBetween(span.start, span.end ?? _dayAfter(today)),
    );
  }

  final List<Intention> lived;
  final List<Intention> open;
  final List<Intention> letGo;

  /// Oldest first.
  final List<Moment> moments;

  static DateTime _dayAfter(DateTime day) =>
      DateTime(day.year, day.month, day.day + 1);
}
