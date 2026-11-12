import 'package:memento_mori_life_in_weeks/calendar/calendar_service.dart';

/// Localization keys for the calendar screen's sync status card, so the
/// badge and the calendar line never contradict each other.
class CalendarSyncLabels {
  const CalendarSyncLabels._();

  /// Badge key: a selected calendar without any sync yet is "ready".
  static String statusKey(CalendarSyncStatus status, {required bool calendarSelected}) {
    switch (status) {
      case CalendarSyncStatus.notConfigured:
        return calendarSelected ? 'calendar_status_ready' : 'calendar_status_not_configured';
      case CalendarSyncStatus.syncing:
        return 'calendar_status_syncing';
      case CalendarSyncStatus.synced:
        return 'calendar_status_synced';
      case CalendarSyncStatus.error:
        return 'calendar_status_error';
    }
  }

  /// Calendar line key: "syncing to" only once a sync has started.
  static String calendarLineKey(CalendarSyncStatus status, {required bool calendarSelected}) {
    if (!calendarSelected) return 'calendar_select_first';
    return status == CalendarSyncStatus.notConfigured
        ? 'calendar_selected_name'
        : 'calendar_syncing_to';
  }
}
