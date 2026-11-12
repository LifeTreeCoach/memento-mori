import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';
import 'package:memento_mori_life_in_weeks/reminders/notification_launches.dart';

class NotificationService {
  /// Monochrome small icon of every notification
  /// (android/app/src/main/res/drawable/ic_stat_memento.xml).
  static const String smallIcon = 'ic_stat_memento';

  /// Channel ids never change: Android keeps user settings per id and only
  /// updates name and description when a channel is created again.
  static const String birthdayChannelId = 'birthday_reminders';
  static const String weeklyChannelId = 'weekly_reminders';

  /// Android channel of birthday reminders, named in the app language.
  static AndroidNotificationChannel birthdayChannel(AppLocalizations l10n) {
    return _channel(birthdayChannelId, 'notification_channel_birthday', l10n);
  }

  /// Android channel of the weekly reflection reminder, named in the app language.
  static AndroidNotificationChannel weeklyChannel(AppLocalizations l10n) {
    return _channel(weeklyChannelId, 'notification_channel_weekly', l10n);
  }

  static AndroidNotificationChannel _channel(
      String id, String keyPrefix, AppLocalizations l10n) {
    return AndroidNotificationChannel(
      id,
      l10n.translate('${keyPrefix}_name'),
      description: l10n.translate('${keyPrefix}_description'),
      importance: Importance.high,
    );
  }

  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  /// The shared plugin instance used for showing and scheduling notifications.
  static FlutterLocalNotificationsPlugin get plugin => _notificationsPlugin;

  /// High-priority Android details for a notification on [channel].
  static AndroidNotificationDetails androidDetails(
    AndroidNotificationChannel channel, {
    StyleInformation? styleInformation,
  }) {
    return AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: smallIcon,
      styleInformation: styleInformation,
    );
  }

  /// iOS thread ids: Notification Center groups each kind on its own.
  static const String birthdayThreadId = 'birthdays';
  static const String compassThreadId = 'compass';

  /// Details of a birthday notification (also the test notification).
  static NotificationDetails birthdayDetails(AppLocalizations l10n, String body) =>
      _details(birthdayChannel(l10n), birthdayThreadId, body);

  /// Details of a Compass reminder (weekly reflection, phase check-in).
  static NotificationDetails compassDetails(AppLocalizations l10n, String body) =>
      _details(weeklyChannel(l10n), compassThreadId, body);

  /// [body] as expandable big text on Android. iOS leaves the foreground
  /// presentation to the defaults of [initialize]'s Darwin settings.
  static NotificationDetails _details(
    AndroidNotificationChannel channel,
    String threadIdentifier,
    String body,
  ) {
    return NotificationDetails(
      android: androidDetails(
        channel,
        styleInformation: BigTextStyleInformation(body),
      ),
      iOS: DarwinNotificationDetails(threadIdentifier: threadIdentifier),
    );
  }

  /// Creates (or renames) the app's Android notification channels in the
  /// language of [l10n]; call again after the language changes (no-op elsewhere).
  static Future<void> createChannels(AppLocalizations l10n) async {
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return;
    await androidPlugin.createNotificationChannel(birthdayChannel(l10n));
    await androidPlugin.createNotificationChannel(weeklyChannel(l10n));
  }

  static Future<void> initialize() async {
    await _initializeTimeZone();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings(smallIcon);
    // iOS: ask for permission in context (reminder opt-in), not at launch.
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (response) =>
          NotificationTaps.report(response.payload),
    );
    await _reportLaunchingTap();
  }

  /// Reports the notification tap that started the app (if any), which
  /// [initialize]'s callback does not see.
  static Future<void> _reportLaunchingTap() async {
    try {
      final details = await _notificationsPlugin.getNotificationAppLaunchDetails();
      if (details?.didNotificationLaunchApp ?? false) {
        NotificationTaps.report(details!.notificationResponse?.payload);
      }
    } catch (e) {
      debugPrint('Could not read the notification launch details: $e');
    }
  }

  /// Sets tz.local to the device time zone so scheduled notifications fire at local time.
  static Future<void> _initializeTimeZone() async {
    tz.initializeTimeZones();
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (e) {
      debugPrint('Could not determine local time zone, falling back to UTC: $e');
      tz.setLocalLocation(tz.UTC);
    }
  }

  /// True if the system currently lets the app show notifications. Errors
  /// count as enabled, so a failed check never shows a false warning.
  static Future<bool> areNotificationsEnabled() async {
    try {
      if (Platform.isAndroid) {
        final android = _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        return await android?.areNotificationsEnabled() ?? true;
      }
      if (Platform.isIOS) {
        final ios = _notificationsPlugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        final options = await ios?.checkPermissions();
        return options?.isEnabled ?? true;
      }
    } catch (e) {
      debugPrint('Could not check the notification permission: $e');
    }
    return true;
  }

  /// Asks for the notification permission (Android 13+, iOS). Returns true if granted.
  static Future<bool> requestPermission() async {
    if (Platform.isIOS) return _requestIOSPermission();
    if (!Platform.isAndroid) return true;
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation == null) return false;

    final bool? granted = await androidImplementation.requestNotificationsPermission();
    debugPrint('Notification permission granted: $granted');
    return granted ?? false;
  }

  static Future<bool> _requestIOSPermission() async {
    final iosImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    final granted = await iosImplementation?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    return granted ?? false;
  }
}
