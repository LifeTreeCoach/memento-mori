import 'package:intl/intl.dart';
import 'package:memento_mori_life_in_weeks/compass/compass_models.dart';
import 'package:memento_mori_life_in_weeks/compass/intention_meta.dart';
import 'package:memento_mori_life_in_weeks/compass/phase_labels.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/reminders/reminder_rhythm.dart';

/// Localized texts of the intention flow and the intention meta lines.
extension IntentionLabels on AppLocalizations {
  /// "Vorhaben · noch ~14 Monate in dieser Phase" / "Genießen · am 12. Juni";
  /// null for an intention without a kind.
  String? kindMetaText(IntentionMeta meta, {required DateTime today}) {
    switch (meta.kind) {
      case null:
        return null;
      case IntentionKind.enjoy:
        final due = meta.dueDate;
        return due == null
            ? translate('intention_meta_enjoy')
            : translate('intention_meta_enjoy_on',
                replacements: {'date': dayText(due, today: today)});
      case IntentionKind.doTask:
        return _doTaskMeta(meta);
    }
  }

  String _doTaskMeta(IntentionMeta meta) {
    final months = meta.monthsLeft;
    if (months != null && months > 0) {
      return plural('intention_meta_do_months', months);
    }
    final weeks = meta.weeksLeft;
    if (weeks != null && weeks > 0) {
      return plural('intention_meta_do_weeks', weeks);
    }
    return translate('intention_meta_do');
  }

  /// "12. Juni", with the year when it is not [today]'s. English stays
  /// day-first like the app's short dates ("12 June").
  String dayText(DateTime day, {required DateTime today}) {
    final code = locale.languageCode;
    final sameYear = day.year == today.year;
    final format = code == 'en'
        ? DateFormat(sameYear ? 'd MMMM' : 'd MMMM y', code)
        : (sameYear ? DateFormat.MMMMd(code) : DateFormat.yMMMMd(code));
    return format.format(day);
  }

  /// "Erledigt · Aufbauphase, 3. Jahr".
  String phaseYearText(PhaseYear phaseYear) => plural(
        'intention_done_phase_year',
        phaseYear.year,
        replacements: {'phase': phaseDisplayName(phaseYear.phase, this)},
      );

  /// "1,4" (one decimal below 10 %, "<0,1" for tiny shares) for [share]
  /// 0..1, without the percent sign.
  String percentText(double share) {
    final percent = share * 100;
    final code = locale.languageCode;
    if (percent < 0.1) return '<${NumberFormat('0.0', code).format(0.1)}';
    final pattern = percent < 10 ? '0.0' : '0';
    return NumberFormat(pattern, code).format(percent);
  }

  /// What the reminder [rhythm] will do with the intention; null when off.
  String? rhythmSentence(ReminderRhythm rhythm) => switch (rhythm) {
        ReminderRhythm.weekly => translate('intention_rhythm_weekly'),
        ReminderRhythm.every4Weeks => translate('intention_rhythm_every4Weeks'),
        ReminderRhythm.off => null,
      };

  /// "2 von 3 · Rest darf warten".
  String nowCountText(int count) => translate('compass_now_count',
      replacements: {'n': numberFormat.format(count), 'max': '$nowLimit'});
}
