import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/reminders/notification_service.dart';

void main() {
  final l10n = AppLocalizations(const Locale('en'));

  test('birthday notifications: birthday channel, iOS thread "birthdays"', () {
    final details = NotificationService.birthdayDetails(l10n, 'Anna turns 30');
    expect(details.android!.channelId, NotificationService.birthdayChannelId);
    expect(details.iOS!.threadIdentifier, 'birthdays');
    expect(
      (details.android!.styleInformation! as BigTextStyleInformation).bigText,
      'Anna turns 30',
    );
  });

  test('Compass reminders: weekly channel, iOS thread "compass"', () {
    final details = NotificationService.compassDetails(l10n, 'A question');
    expect(details.android!.channelId, NotificationService.weeklyChannelId);
    expect(details.iOS!.threadIdentifier, 'compass');
  });

  test('iOS presentation follows the Darwin init defaults', () {
    final ios = NotificationService.compassDetails(l10n, 'x').iOS!;
    expect(ios.presentAlert, isNull);
    expect(ios.presentBanner, isNull);
    expect(ios.presentList, isNull);
    expect(ios.presentSound, isNull);
    expect(ios.presentBadge, isNull);
  });
}
