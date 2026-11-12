/// The raw birthday texts of the device contacts (Android only): the
/// fallback for birthdays `flutter_contacts` cannot parse, such as
/// `15.08.1992`, which it drops.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Reads the texts over the MethodChannel `memento/contact_birthdays`
/// (native side `contacts/ContactBirthdayTexts.kt`): method `birthdayTexts`
/// -> map contact id (`Contact.id`) -> raw `Event.START_DATE` of its first
/// birthday. Without the native side (iOS, whose birthdays are always
/// structured) or on failure the map is empty.
class ContactBirthdayTexts {
  const ContactBirthdayTexts({
    this.channel = const MethodChannel('memento/contact_birthdays'),
  });

  final MethodChannel channel;

  Future<Map<String, String>> read() async {
    try {
      final texts = await channel.invokeMapMethod<String, String>(
        'birthdayTexts',
      );
      return texts ?? const {};
    } on MissingPluginException {
      return const {};
    } on PlatformException catch (e) {
      debugPrint('Contact birthday texts not read: $e');
      return const {};
    }
  }
}
