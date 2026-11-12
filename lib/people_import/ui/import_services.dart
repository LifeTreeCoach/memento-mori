import 'package:flutter/widgets.dart';

import '../../reminders/notification_service.dart';
import '../contacts_source.dart';
import '../import_applier.dart';
import '../picked_contacts_source.dart';
import '../vcard_source.dart';

/// Everything the import screens talk to; tests inject fakes through an
/// [ImportServicesScope].
class ImportServices {
  const ImportServices({
    this.contacts = const DeviceContactsSource(),
    this.picker = const ChannelPickedContactsSource(),
    this.vcard = const VCardSource(),
    this.applier = const ImportApplier(),
    this.requestNotificationPermission = NotificationService.requestPermission,
    this.today,
  });

  final ContactsSource contacts;
  final PickedContactsSource picker;
  final VCardSource vcard;
  final ImportApplier applier;

  /// Asked once after the first import into an empty People list (as when
  /// the first person is added by hand).
  final Future<bool> Function() requestNotificationPermission;

  /// Fixed "today" for year validation (tests); null = the clock.
  final DateTime? today;
}

/// Provides [ImportServices] to the import flow below it.
class ImportServicesScope extends InheritedWidget {
  const ImportServicesScope({
    super.key,
    required this.services,
    required super.child,
  });

  final ImportServices services;

  /// The nearest services; the real device sources without a scope.
  static ImportServices of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<ImportServicesScope>()?.services ??
      const ImportServices();

  @override
  bool updateShouldNotify(ImportServicesScope oldWidget) =>
      services != oldWidget.services;
}
