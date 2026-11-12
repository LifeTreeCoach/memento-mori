import 'package:memento_mori_life_in_weeks/friend.dart';
import 'package:memento_mori_life_in_weeks/life/upcoming_birthday_card.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/people/friend_tile.dart';

/// Localized phrases shared by the friend detail, form and lifespan views.
class FriendText {
  FriendText(this.l10n);

  final AppLocalizations l10n;

  /// "12 Mar 1998" / "12.03.1998".
  String date(DateTime d) => l10n.shortDateFormat.format(d);

  /// [friend]'s birth date: "12 Mar 1998", or "12 Mar" without a year.
  String birthDate(Friend friend) => friend.hasBirthYear
      ? date(friend.birthDate)
      : l10n.dayMonthFormat.format(friend.birthDate);

  /// "31 years old".
  String age(int years) => l10n.plural('friend_age', years);

  /// "31 years".
  String years(int count) => l10n.plural('friend_years', count);

  /// "12 days".
  String days(int count) => l10n.plural('friend_days', count);

  /// "44 years" left of [friend]'s expected lifespan, or a gentle
  /// "Beyond the expected time" once it is reached (never a negative).
  /// Null without a birth year.
  String? remaining(Friend friend, {DateTime? today}) {
    final left = friend.getRemainingYears(today: today);
    if (left == null) return null;
    return friend.isBeyondExpectedLifespan(today: today)
        ? l10n.translate('friend_beyond_expectancy')
        : years(left);
  }

  /// Whole percent of [friend]'s expected lifespan already lived; null
  /// without a birth year.
  static int? percentLived(Friend friend) {
    final age = friend.getCurrentAge();
    if (age == null) return null;
    if (friend.customLifespan <= 0) return 100;
    final ratio = age / friend.customLifespan;
    return (ratio.clamp(0.0, 1.0) * 100).round();
  }

  /// "turns 31 · in 12 days" / "turns 31 today 🎂" (see
  /// [describeNextBirthday]).
  String turns(UpcomingBirthday next) => describeNextBirthday(l10n, next);

  /// Short plain-text summary of [friend] for the share sheet.
  String shareText(Friend friend) {
    final currentAge = friend.getCurrentAge();
    if (currentAge == null) {
      return l10n.translate('friend_share_text_noage', replacements: {
        'name': friend.name,
        'date': date(friend.getNextBirthday()),
      });
    }
    return l10n.translate(
      'friend_share_text',
      replacements: {
        'name': friend.name,
        'age': age(currentAge),
        'date': date(friend.getNextBirthday()),
        'p': '${percentLived(friend)}',
        'lifespan': years(friend.customLifespan),
      },
    );
  }
}
