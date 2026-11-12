import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:memento_mori_life_in_weeks/reminders/notification_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// Whether the system lets the app show notifications, and how to get
/// that permission back; swappable in tests.
abstract class NotificationPermission {
  /// True if notifications can currently be shown.
  Future<bool> isGranted();

  /// Shows the system prompt if the system still allows one; true if granted.
  Future<bool> request();

  /// Opens the system notification settings of this app.
  Future<void> openSystemSettings();
}

/// Asks again and, if that does not grant the permission (the system no
/// longer shows a prompt after repeated denials), opens the system settings.
Future<bool> requestOrOpenSettings(NotificationPermission permission) async {
  if (await permission.request()) return true;
  await permission.openSystemSettings();
  return false;
}

/// Uses the notification plugin and the platform settings screens.
class SystemNotificationPermission implements NotificationPermission {
  const SystemNotificationPermission();

  /// Implemented in android/.../MainActivity.kt.
  static const MethodChannel _androidSettings =
      MethodChannel('memento/app_settings');

  @override
  Future<bool> isGranted() => NotificationService.areNotificationsEnabled();

  @override
  Future<bool> request() => NotificationService.requestPermission();

  @override
  Future<void> openSystemSettings() async {
    try {
      if (Platform.isAndroid) {
        await _androidSettings.invokeMethod<void>('openNotificationSettings');
      } else if (Platform.isIOS) {
        await launchUrl(Uri.parse('app-settings:'));
      }
    } catch (e) {
      debugPrint('Could not open notification settings: $e');
    }
  }
}
