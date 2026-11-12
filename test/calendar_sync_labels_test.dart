import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento_mori_life_in_weeks/calendar/calendar_service.dart';
import 'package:memento_mori_life_in_weeks/calendar/calendar_sync_labels.dart';
import 'package:memento_mori_life_in_weeks/localization.dart';

void main() {
  group('statusKey', () {
    test('a selected calendar without a sync is ready', () {
      expect(
        CalendarSyncLabels.statusKey(CalendarSyncStatus.notConfigured, calendarSelected: true),
        'calendar_status_ready',
      );
    });

    test('without a calendar it is not configured', () {
      expect(
        CalendarSyncLabels.statusKey(CalendarSyncStatus.notConfigured, calendarSelected: false),
        'calendar_status_not_configured',
      );
    });

    test('sync states keep their own labels', () {
      expect(CalendarSyncLabels.statusKey(CalendarSyncStatus.syncing, calendarSelected: true),
          'calendar_status_syncing');
      expect(CalendarSyncLabels.statusKey(CalendarSyncStatus.synced, calendarSelected: true),
          'calendar_status_synced');
      expect(CalendarSyncLabels.statusKey(CalendarSyncStatus.error, calendarSelected: true),
          'calendar_status_error');
    });
  });

  group('calendarLineKey', () {
    test('asks for a calendar when none is selected', () {
      expect(
        CalendarSyncLabels.calendarLineKey(CalendarSyncStatus.notConfigured,
            calendarSelected: false),
        'calendar_select_first',
      );
    });

    test('names the calendar until a sync happened', () {
      expect(
        CalendarSyncLabels.calendarLineKey(CalendarSyncStatus.notConfigured,
            calendarSelected: true),
        'calendar_selected_name',
      );
    });

    test('says "syncing to" once a sync started', () {
      for (final status in [
        CalendarSyncStatus.syncing,
        CalendarSyncStatus.synced,
        CalendarSyncStatus.error,
      ]) {
        expect(CalendarSyncLabels.calendarLineKey(status, calendarSelected: true),
            'calendar_syncing_to');
      }
    });
  });

  test('new labels are translated', () {
    final en = AppLocalizations(const Locale('en'));
    final de = AppLocalizations(const Locale('de'));
    expect(en.translate('calendar_status_ready'), 'Ready to sync');
    expect(de.translate('calendar_status_ready'), 'Bereit zum Synchronisieren');
    expect(en.translate('calendar_selected_name', replacements: {'name': 'X'}), 'Calendar: X');
    expect(de.translate('calendar_selected_name', replacements: {'name': 'X'}), 'Kalender: X');
  });
}
