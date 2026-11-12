/// Strings of the friend screens; spread into AppLocalizations.
const Map<String, String> friendDataStringsEn = {
  // Unsaved changes in the add/edit form
  'form_discard_title': 'Discard changes?',
  'form_discard_body': 'Your changes to this person will be lost.',
  'form_discard_confirm': 'Discard',
  'form_keep_editing': 'Keep editing',

  // Import & export
  'import_export_title': 'Import & Export',
  'import_export_cancel': 'Cancel',
  'import_export_export_header': 'Export',
  'import_export_export_description':
      'Create a backup of all people and their birthdays and of your Compass: intentions, moments and life phases. Save it to your device or share it, so you can import it later.',
  'import_export_save_button': 'Save to device',
  'import_export_share_button': 'Share',
  'import_export_save_dialog_title': 'Save backup',
  'import_export_import_header': 'Import',
  'import_export_import_description':
      'Import people and Compass data from a previously exported backup file. Duplicates are skipped automatically.',
  'import_export_import_button': 'Import people',
  'import_export_clear_header': 'Danger zone',
  'import_export_clear_description':
      'Permanently delete all people and birthday reminders. This cannot be undone. Consider exporting first.',
  'import_export_clear_button': 'Delete all people',
  'import_export_status_preparing_export': 'Preparing export…',
  'import_export_status_nothing_to_export': 'No people to export',
  'import_export_share_subject': 'People & birthdays backup',
  'import_export_share_text_one': 'Memento Mori backup – {n} person',
  'import_export_share_text_other': 'Memento Mori backup – {n} people',
  'import_export_exported_one': 'Exported {n} person',
  'import_export_exported_other': 'Exported {n} people',
  'import_export_status_export_cancelled': 'Export cancelled',
  'import_export_shared': 'Backup shared',
  'import_export_export_failed': 'Export failed: {error}',
  'import_export_status_selecting_file': 'Selecting file…',
  'import_export_status_no_file': 'No file selected',
  'import_export_status_processing': 'Processing import data…',
  'import_export_error_invalid_format': 'Invalid backup file format',
  'import_export_error_no_valid_friends': 'No valid people found in backup file',
  'import_export_dialog_title': 'Import people',
  'import_export_dialog_found_one': 'Found {n} person to import.',
  'import_export_dialog_found_other': 'Found {n} people to import.',
  'import_export_dialog_options': 'Import options',
  'import_export_dialog_rule_duplicates': '• Duplicates will be skipped',
  'import_export_dialog_rule_new': '• New people will be added',
  'import_export_dialog_rule_existing':
      '• People with the same name and birthday will not be overwritten',
  'import_export_dialog_confirm': 'Import',
  'import_export_status_cancelled': 'Import cancelled',
  'import_export_status_importing': 'Importing people…',
  'import_export_import_result':
      'Import completed: {added} added, {skipped} duplicates skipped',
  'import_export_import_failed': 'Import failed: {error}',
  'import_export_clear_dialog_title': 'Delete all people',
  'import_export_clear_dialog_body':
      'This will permanently delete all people and their birthday reminders. This cannot be undone.\n\nWe recommend exporting a backup first.',
  'import_export_clear_dialog_confirm': 'Delete all',
  'import_export_status_clearing': 'Deleting all people…',
  'import_export_cleared': 'All people have been deleted',
  'import_export_clear_failed': 'Deleting failed: {error}',

  // Calendar integration
  'calendar_title': 'Calendar integration',
  'calendar_refresh_tooltip': 'Refresh calendars',
  'calendar_selected_success': 'Calendar selected',
  'calendar_selected_failed': 'Failed to select calendar',
  'calendar_select_first': 'Please select a calendar first',
  'calendar_sync_success': 'Birthday events synced',
  'calendar_sync_partial': 'Some events failed to sync. Check permissions.',
  'calendar_clear_dialog_title': 'Clear all birthday events',
  'calendar_clear_dialog_body':
      'This will remove all birthday events from your calendar. This cannot be undone.',
  'calendar_cancel': 'Cancel',
  'calendar_clear_dialog_confirm': 'Clear all',
  'calendar_cleared': 'All birthday events cleared',
  'calendar_status_not_configured': 'Not configured',
  'calendar_status_syncing': 'Syncing…',
  'calendar_status_synced': 'Synced',
  'calendar_status_error': 'Sync error',
  'calendar_status_ready': 'Ready to sync',
  'calendar_permissions_title': 'Calendar permission required',
  'calendar_permissions_body':
      'To sync birthday events with your calendar, please grant calendar access in your device settings.',
  'calendar_try_again': 'Try again',
  'calendar_none_title': 'No writable calendars found',
  'calendar_none_body':
      'Please create a calendar on your device or make an existing calendar writable to enable birthday sync.',
  'calendar_refresh': 'Refresh',
  'calendar_sync_status_header': 'Sync status',
  'calendar_syncing_to': 'Syncing to: {name}',
  'calendar_selected_name': 'Calendar: {name}',
  'calendar_stats_header': 'Statistics',
  'calendar_stat_total': 'People',
  'calendar_stat_synced': 'Synced',
  'calendar_stat_pending': 'Pending',
  'calendar_stat_skipped_one': '{n} person left out – from your contacts',
  'calendar_stat_skipped_other': '{n} people left out – from your contacts',
  'calendar_select_header': 'Calendar',
  'calendar_unnamed': 'Unnamed calendar',
  'calendar_local': 'Local calendar',
  'calendar_skip_contacts_title': 'Leave out people from contacts',
  'calendar_skip_contacts_sub':
      "They're usually in your calendar already – this way nothing shows up twice.",
  'calendar_actions_header': 'Actions',
  'calendar_sync_all': 'Sync all birthdays',
  'calendar_clear_all': 'Clear all events',
  'calendar_help_header': 'How it works',
  'calendar_help_body':
      '• Select a calendar to sync birthday events\n'
          '• Birthdays are created as yearly recurring events\n'
          '• Each event includes the birth year\n'
          '• Events include a 24-hour reminder\n'
          '• Only active people are synced\n'
          '• Changes to people are synced automatically',
  'calendar_event_title': "🎂 {name}'s birthday",
  'calendar_event_description_noyear': 'Synced by Memento Mori – Life in Weeks',
  'calendar_event_description': 'Born {year}\n\nSynced by Memento Mori – Life in Weeks',
};

const Map<String, String> friendDataStringsDe = {
  // Ungespeicherte Änderungen im Formular
  'form_discard_title': 'Änderungen verwerfen?',
  'form_discard_body': 'Deine Änderungen an dieser Person gehen verloren.',
  'form_discard_confirm': 'Verwerfen',
  'form_keep_editing': 'Weiter bearbeiten',

  // Import & Export
  'import_export_title': 'Import & Export',
  'import_export_cancel': 'Abbrechen',
  'import_export_export_header': 'Export',
  'import_export_export_description':
      'Erstelle eine Sicherung aller Personen und ihrer Geburtstage sowie deines Kompasses: Vorhaben, Momente und Lebensphasen. Speichere sie auf dem Gerät oder teile sie, um sie später wieder zu importieren.',
  'import_export_save_button': 'Auf Gerät speichern',
  'import_export_share_button': 'Teilen',
  'import_export_save_dialog_title': 'Sicherung speichern',
  'import_export_import_header': 'Import',
  'import_export_import_description':
      'Importiere Personen und Kompass-Daten aus einer zuvor exportierten Sicherungsdatei. Doppelte Einträge werden automatisch übersprungen.',
  'import_export_import_button': 'Personen importieren',
  'import_export_clear_header': 'Gefahrenzone',
  'import_export_clear_description':
      'Löscht alle Personen und Geburtstagserinnerungen endgültig. Das kann nicht rückgängig gemacht werden. Exportiere am besten vorher.',
  'import_export_clear_button': 'Alle Personen löschen',
  'import_export_status_preparing_export': 'Export wird vorbereitet …',
  'import_export_status_nothing_to_export': 'Keine Personen zum Exportieren',
  'import_export_share_subject': 'Sicherung: Personen & Geburtstage',
  'import_export_share_text_one': 'Memento-Mori-Sicherung – {n} Person',
  'import_export_share_text_other': 'Memento-Mori-Sicherung – {n} Personen',
  'import_export_exported_one': '{n} Person exportiert',
  'import_export_exported_other': '{n} Personen exportiert',
  'import_export_status_export_cancelled': 'Export abgebrochen',
  'import_export_shared': 'Sicherung geteilt',
  'import_export_export_failed': 'Export fehlgeschlagen: {error}',
  'import_export_status_selecting_file': 'Datei wird ausgewählt …',
  'import_export_status_no_file': 'Keine Datei ausgewählt',
  'import_export_status_processing': 'Importdaten werden verarbeitet …',
  'import_export_error_invalid_format': 'Ungültiges Format der Sicherungsdatei',
  'import_export_error_no_valid_friends':
      'Keine gültigen Personen in der Sicherungsdatei gefunden',
  'import_export_dialog_title': 'Personen importieren',
  'import_export_dialog_found_one': '{n} Person zum Importieren gefunden.',
  'import_export_dialog_found_other': '{n} Personen zum Importieren gefunden.',
  'import_export_dialog_options': 'Importoptionen',
  'import_export_dialog_rule_duplicates': '• Doppelte Einträge werden übersprungen',
  'import_export_dialog_rule_new': '• Neue Personen werden hinzugefügt',
  'import_export_dialog_rule_existing':
      '• Vorhandene Personen mit gleichem Namen und Geburtstag werden nicht überschrieben',
  'import_export_dialog_confirm': 'Importieren',
  'import_export_status_cancelled': 'Import abgebrochen',
  'import_export_status_importing': 'Personen werden importiert …',
  'import_export_import_result':
      'Import abgeschlossen: {added} hinzugefügt, {skipped} Duplikate übersprungen',
  'import_export_import_failed': 'Import fehlgeschlagen: {error}',
  'import_export_clear_dialog_title': 'Alle Personen löschen',
  'import_export_clear_dialog_body':
      'Damit werden alle Personen und ihre Geburtstagserinnerungen endgültig gelöscht. Das kann nicht rückgängig gemacht werden.\n\nWir empfehlen, vorher eine Sicherung zu exportieren.',
  'import_export_clear_dialog_confirm': 'Alle löschen',
  'import_export_status_clearing': 'Alle Personen werden gelöscht …',
  'import_export_cleared': 'Alle Personen wurden gelöscht',
  'import_export_clear_failed': 'Löschen fehlgeschlagen: {error}',

  // Kalender-Integration
  'calendar_title': 'Kalender-Integration',
  'calendar_refresh_tooltip': 'Kalender aktualisieren',
  'calendar_selected_success': 'Kalender ausgewählt',
  'calendar_selected_failed': 'Kalender konnte nicht ausgewählt werden',
  'calendar_select_first': 'Bitte wähle zuerst einen Kalender aus',
  'calendar_sync_success': 'Geburtstagstermine synchronisiert',
  'calendar_sync_partial':
      'Einige Termine konnten nicht synchronisiert werden. Prüfe die Berechtigungen.',
  'calendar_clear_dialog_title': 'Alle Geburtstagstermine entfernen',
  'calendar_clear_dialog_body':
      'Damit werden alle Geburtstagstermine aus deinem Kalender entfernt. Das kann nicht rückgängig gemacht werden.',
  'calendar_cancel': 'Abbrechen',
  'calendar_clear_dialog_confirm': 'Alle entfernen',
  'calendar_cleared': 'Alle Geburtstagstermine entfernt',
  'calendar_status_not_configured': 'Nicht eingerichtet',
  'calendar_status_syncing': 'Synchronisiere …',
  'calendar_status_synced': 'Synchronisiert',
  'calendar_status_error': 'Sync-Fehler',
  'calendar_status_ready': 'Bereit zum Synchronisieren',
  'calendar_permissions_title': 'Kalenderzugriff erforderlich',
  'calendar_permissions_body':
      'Um Geburtstage mit deinem Kalender zu synchronisieren, erlaube bitte den Kalenderzugriff in den Geräteeinstellungen.',
  'calendar_try_again': 'Erneut versuchen',
  'calendar_none_title': 'Keine beschreibbaren Kalender gefunden',
  'calendar_none_body':
      'Bitte lege auf deinem Gerät einen Kalender an oder mache einen vorhandenen Kalender beschreibbar, um Geburtstage zu synchronisieren.',
  'calendar_refresh': 'Aktualisieren',
  'calendar_sync_status_header': 'Sync-Status',
  'calendar_syncing_to': 'Synchronisiert mit: {name}',
  'calendar_selected_name': 'Kalender: {name}',
  'calendar_stats_header': 'Statistik',
  'calendar_stat_total': 'Personen',
  'calendar_stat_synced': 'Synchronisiert',
  'calendar_stat_pending': 'Ausstehend',
  'calendar_stat_skipped_one': '{n} Person ausgelassen – aus deinen Kontakten',
  'calendar_stat_skipped_other': '{n} Personen ausgelassen – aus deinen Kontakten',
  'calendar_select_header': 'Kalender',
  'calendar_unnamed': 'Unbenannter Kalender',
  'calendar_local': 'Lokaler Kalender',
  'calendar_skip_contacts_title': 'Personen aus Kontakten auslassen',
  'calendar_skip_contacts_sub':
      'Sie stehen meist schon in deinem Kalender – so entstehen keine Doppelungen.',
  'calendar_actions_header': 'Aktionen',
  'calendar_sync_all': 'Alle Geburtstage synchronisieren',
  'calendar_clear_all': 'Alle Termine entfernen',
  'calendar_help_header': 'So funktioniert es',
  'calendar_help_body':
      '• Wähle einen Kalender für die Geburtstagstermine\n'
          '• Geburtstage werden als jährlich wiederkehrende Termine angelegt\n'
          '• Jeder Termin enthält das Geburtsjahr\n'
          '• Termine enthalten eine Erinnerung 24\u00A0Stunden vorher\n'
          '• Nur aktive Personen werden synchronisiert\n'
          '• Änderungen an Personen werden automatisch übernommen',
  'calendar_event_title': '🎂 Geburtstag von {name}',
  'calendar_event_description_noyear': 'Synchronisiert von Memento Mori – Lebenswochen',
  'calendar_event_description': 'Geboren {year}\n\nSynchronisiert von Memento Mori – Lebenswochen',
};

const Map<String, String> friendDataStringsEs = {
  // Unsaved changes in the add/edit form
  'form_discard_title': '¿Descartar cambios?',
  'form_discard_body': 'Se perderán los cambios que hayas hecho.',
  'form_discard_confirm': 'Descartar',
  'form_keep_editing': 'Seguir editando',

  // Import & export
  'import_export_title': 'Importar y exportar',
  'import_export_cancel': 'Cancelar',
  'import_export_export_header': 'Exportar',
  'import_export_export_description':
      'Crea una copia de seguridad de todas las personas y sus cumpleaños y de tu Brújula: intenciones, momentos y etapas de la vida. Guárdala en tu dispositivo o compártela para importarla más tarde.',
  'import_export_save_button': 'Guardar en el dispositivo',
  'import_export_share_button': 'Compartir',
  'import_export_save_dialog_title': 'Guardar copia',
  'import_export_import_header': 'Importar',
  'import_export_import_description':
      'Importa personas y datos de la Brújula desde una copia exportada antes. Los duplicados se omiten automáticamente.',
  'import_export_import_button': 'Importar personas',
  'import_export_clear_header': 'Zona de peligro',
  'import_export_clear_description':
      'Elimina definitivamente a todas las personas y sus recordatorios de cumpleaños. No se puede deshacer. Te recomendamos exportar antes.',
  'import_export_clear_button': 'Eliminar a todas las personas',
  'import_export_status_preparing_export': 'Preparando la exportación…',
  'import_export_status_nothing_to_export': 'No hay personas para exportar',
  'import_export_share_subject': 'Copia de personas y cumpleaños',
  'import_export_share_text_one': 'Copia de Memento Mori – {n} persona',
  'import_export_share_text_other': 'Copia de Memento Mori – {n} personas',
  'import_export_exported_one': '{n} persona exportada',
  'import_export_exported_other': '{n} personas exportadas',
  'import_export_status_export_cancelled': 'Exportación cancelada',
  'import_export_shared': 'Copia compartida',
  'import_export_export_failed': 'Error al exportar: {error}',
  'import_export_status_selecting_file': 'Eligiendo archivo…',
  'import_export_status_no_file': 'No se eligió ningún archivo',
  'import_export_status_processing': 'Procesando los datos…',
  'import_export_error_invalid_format': 'Formato de copia no válido',
  'import_export_error_no_valid_friends': 'La copia no contiene personas válidas',
  'import_export_dialog_title': 'Importar personas',
  'import_export_dialog_found_one': 'Se encontró {n} persona para importar.',
  'import_export_dialog_found_other': 'Se encontraron {n} personas para importar.',
  'import_export_dialog_options': 'Opciones de importación',
  'import_export_dialog_rule_duplicates': '• Los duplicados se omitirán',
  'import_export_dialog_rule_new': '• Las personas nuevas se añadirán',
  'import_export_dialog_rule_existing':
      '• Las personas con el mismo nombre y cumpleaños no se sobrescribirán',
  'import_export_dialog_confirm': 'Importar',
  'import_export_status_cancelled': 'Importación cancelada',
  'import_export_status_importing': 'Importando personas…',
  'import_export_import_result':
      'Importación completada: {added} añadidas, {skipped} duplicados omitidos',
  'import_export_import_failed': 'Error al importar: {error}',
  'import_export_clear_dialog_title': 'Eliminar a todas las personas',
  'import_export_clear_dialog_body':
      'Se eliminarán definitivamente todas las personas y sus recordatorios de cumpleaños. No se puede deshacer.\n\nTe recomendamos exportar antes una copia de seguridad.',
  'import_export_clear_dialog_confirm': 'Eliminar todo',
  'import_export_status_clearing': 'Eliminando a todas las personas…',
  'import_export_cleared': 'Se eliminaron todas las personas',
  'import_export_clear_failed': 'Error al eliminar: {error}',

  // Calendar integration
  'calendar_title': 'Integración con el calendario',
  'calendar_refresh_tooltip': 'Actualizar calendarios',
  'calendar_selected_success': 'Calendario elegido',
  'calendar_selected_failed': 'No se pudo elegir el calendario',
  'calendar_select_first': 'Primero elige un calendario',
  'calendar_sync_success': 'Cumpleaños sincronizados',
  'calendar_sync_partial': 'Algunos eventos no se sincronizaron. Revisa los permisos.',
  'calendar_clear_dialog_title': 'Borrar todos los cumpleaños',
  'calendar_clear_dialog_body':
      'Se quitarán todos los eventos de cumpleaños de tu calendario. No se puede deshacer.',
  'calendar_cancel': 'Cancelar',
  'calendar_clear_dialog_confirm': 'Borrar todo',
  'calendar_cleared': 'Se borraron todos los cumpleaños',
  'calendar_status_not_configured': 'Sin configurar',
  'calendar_status_syncing': 'Sincronizando…',
  'calendar_status_synced': 'Sincronizado',
  'calendar_status_error': 'Error de sincronización',
  'calendar_status_ready': 'Listo para sincronizar',
  'calendar_permissions_title': 'Se necesita acceso al calendario',
  'calendar_permissions_body':
      'Para sincronizar los cumpleaños con tu calendario, permite el acceso al calendario en los ajustes del dispositivo.',
  'calendar_try_again': 'Reintentar',
  'calendar_none_title': 'No hay calendarios editables',
  'calendar_none_body':
      'Crea un calendario en tu dispositivo o haz editable uno existente para sincronizar los cumpleaños.',
  'calendar_refresh': 'Actualizar',
  'calendar_sync_status_header': 'Estado de sincronización',
  'calendar_syncing_to': 'Sincronizando con: {name}',
  'calendar_selected_name': 'Calendario: {name}',
  'calendar_stats_header': 'Estadísticas',
  'calendar_stat_total': 'Personas',
  'calendar_stat_synced': 'Sincronizadas',
  'calendar_stat_pending': 'Pendientes',
  'calendar_stat_skipped_one': '{n} persona omitida – de tus contactos',
  'calendar_stat_skipped_other': '{n} personas omitidas – de tus contactos',
  'calendar_select_header': 'Calendario',
  'calendar_unnamed': 'Calendario sin nombre',
  'calendar_local': 'Calendario local',
  'calendar_skip_contacts_title': 'Omitir personas de los contactos',
  'calendar_skip_contacts_sub':
      'Normalmente ya están en tu calendario: así no se duplica nada.',
  'calendar_actions_header': 'Acciones',
  'calendar_sync_all': 'Sincronizar cumpleaños',
  'calendar_clear_all': 'Borrar todos los eventos',
  'calendar_help_header': 'Cómo funciona',
  'calendar_help_body':
      '• Elige un calendario para sincronizar los cumpleaños\n'
          '• Los cumpleaños se crean como eventos anuales\n'
          '• Cada evento incluye el año de nacimiento\n'
          '• Los eventos tienen un aviso 24\u00A0horas antes\n'
          '• Solo se sincronizan las personas activas\n'
          '• Los cambios en las personas se sincronizan automáticamente',
  'calendar_event_title': '🎂 Cumpleaños de {name}',
  'calendar_event_description_noyear': 'Sincronizado por Memento Mori – La vida en semanas',
  'calendar_event_description': 'Año de nacimiento: {year}\n\nSincronizado por Memento Mori – La vida en semanas',
};

const Map<String, String> friendDataStringsFr = {
  // Unsaved changes in the add/edit form
  'form_discard_title': 'Abandonner les modifications ?',
  'form_discard_body': 'Tes modifications pour cette personne seront perdues.',
  'form_discard_confirm': 'Abandonner',
  'form_keep_editing': 'Continuer à modifier',

  // Import & export
  'import_export_title': 'Import et export',
  'import_export_cancel': 'Annuler',
  'import_export_export_header': 'Exporter',
  'import_export_export_description':
      'Crée une sauvegarde de tous tes proches et de leurs anniversaires, ainsi que de ta Boussole\u00A0: intentions, moments et phases de vie. Enregistre-la sur ton appareil ou partage-la pour pouvoir l’importer plus tard.',
  'import_export_save_button': 'Enregistrer sur l’appareil',
  'import_export_share_button': 'Partager',
  'import_export_save_dialog_title': 'Enregistrer la sauvegarde',
  'import_export_import_header': 'Importer',
  'import_export_import_description':
      'Importe des proches et les données de la Boussole depuis un fichier de sauvegarde exporté auparavant. Les doublons sont ignorés automatiquement.',
  'import_export_import_button': 'Importer des proches',
  'import_export_clear_header': 'Zone dangereuse',
  'import_export_clear_description':
      'Supprime définitivement tous tes proches et leurs rappels d’anniversaire. Action irréversible. Pense à exporter d’abord.',
  'import_export_clear_button': 'Supprimer tous les proches',
  'import_export_status_preparing_export': 'Préparation de l’export…',
  'import_export_status_nothing_to_export': 'Aucune personne à exporter',
  'import_export_share_subject': 'Sauvegarde des proches et anniversaires',
  'import_export_share_text_one': 'Sauvegarde Memento Mori – {n} personne',
  'import_export_share_text_other': 'Sauvegarde Memento Mori – {n} personnes',
  'import_export_exported_one': '{n} personne exportée',
  'import_export_exported_other': '{n} personnes exportées',
  'import_export_status_export_cancelled': 'Export annulé',
  'import_export_shared': 'Sauvegarde partagée',
  'import_export_export_failed': 'Échec de l’export : {error}',
  'import_export_status_selecting_file': 'Sélection du fichier…',
  'import_export_status_no_file': 'Aucun fichier sélectionné',
  'import_export_status_processing': 'Traitement des données…',
  'import_export_error_invalid_format': 'Format de sauvegarde non valide',
  'import_export_error_no_valid_friends':
      'Aucune personne valide dans la sauvegarde',
  'import_export_dialog_title': 'Importer des proches',
  'import_export_dialog_found_one': '{n} personne à importer.',
  'import_export_dialog_found_other': '{n} personnes à importer.',
  'import_export_dialog_options': 'Options d’import',
  'import_export_dialog_rule_duplicates': '• Les doublons seront ignorés',
  'import_export_dialog_rule_new': '• Les nouvelles personnes seront ajoutées',
  'import_export_dialog_rule_existing':
      '• Les personnes avec le même nom et la même date de naissance ne seront pas écrasées',
  'import_export_dialog_confirm': 'Importer',
  'import_export_status_cancelled': 'Import annulé',
  'import_export_status_importing': 'Import en cours…',
  'import_export_import_result':
      'Import terminé : personnes ajoutées : {added}, doublons ignorés : {skipped}',
  'import_export_import_failed': 'Échec de l’import : {error}',
  'import_export_clear_dialog_title': 'Supprimer tous les proches',
  'import_export_clear_dialog_body':
      'Tous tes proches et leurs rappels d’anniversaire seront supprimés définitivement. Action irréversible.\n\nNous te conseillons d’exporter une sauvegarde d’abord.',
  'import_export_clear_dialog_confirm': 'Tout supprimer',
  'import_export_status_clearing': 'Suppression en cours…',
  'import_export_cleared': 'Tous les proches ont été supprimés',
  'import_export_clear_failed': 'Échec de la suppression : {error}',

  // Calendar integration
  'calendar_title': 'Intégration agenda',
  'calendar_refresh_tooltip': 'Actualiser les agendas',
  'calendar_selected_success': 'Agenda sélectionné',
  'calendar_selected_failed': 'Impossible de sélectionner l’agenda',
  'calendar_select_first': 'Choisis d’abord un agenda',
  'calendar_sync_success': 'Anniversaires synchronisés',
  'calendar_sync_partial':
      'Certains événements n’ont pas pu être synchronisés. Vérifie les autorisations.',
  'calendar_clear_dialog_title': 'Effacer tous les anniversaires',
  'calendar_clear_dialog_body':
      'Tous les anniversaires seront retirés de ton agenda. Action irréversible.',
  'calendar_cancel': 'Annuler',
  'calendar_clear_dialog_confirm': 'Tout effacer',
  'calendar_cleared': 'Tous les anniversaires ont été effacés',
  'calendar_status_not_configured': 'Non configuré',
  'calendar_status_syncing': 'Synchronisation…',
  'calendar_status_synced': 'Synchronisé',
  'calendar_status_error': 'Erreur de synchro',
  'calendar_status_ready': 'Prêt à synchroniser',
  'calendar_permissions_title': 'Accès à l’agenda requis',
  'calendar_permissions_body':
      'Pour synchroniser les anniversaires avec ton agenda, autorise l’accès à l’agenda dans les réglages de ton appareil.',
  'calendar_try_again': 'Réessayer',
  'calendar_none_title': 'Aucun agenda modifiable trouvé',
  'calendar_none_body':
      'Crée un agenda sur ton appareil ou rends un agenda existant modifiable pour activer la synchro des anniversaires.',
  'calendar_refresh': 'Actualiser',
  'calendar_sync_status_header': 'État de la synchro',
  'calendar_syncing_to': 'Synchro vers : {name}',
  'calendar_selected_name': 'Agenda : {name}',
  'calendar_stats_header': 'Statistiques',
  'calendar_stat_total': 'Personnes',
  'calendar_stat_synced': 'Synchronisés',
  'calendar_stat_pending': 'En attente',
  'calendar_stat_skipped_one': '{n} personne laissée de côté – de tes contacts',
  'calendar_stat_skipped_other': '{n} personnes laissées de côté – de tes contacts',
  'calendar_select_header': 'Agenda',
  'calendar_unnamed': 'Agenda sans nom',
  'calendar_local': 'Agenda local',
  'calendar_skip_contacts_title': 'Ignorer les personnes des contacts',
  'calendar_skip_contacts_sub':
      'Elles figurent souvent déjà dans ton agenda – ainsi, rien n’apparaît en double.',
  'calendar_actions_header': 'Actions',
  'calendar_sync_all': 'Synchroniser tous les anniversaires',
  'calendar_clear_all': 'Effacer tous les événements',
  'calendar_help_header': 'Comment ça marche',
  'calendar_help_body':
      '• Choisis un agenda pour y synchroniser les anniversaires\n'
          '• Les anniversaires sont créés comme événements annuels récurrents\n'
          '• Chaque événement indique l’année de naissance\n'
          '• Chaque événement a un rappel 24 h avant\n'
          '• Seuls les proches actifs sont synchronisés\n'
          '• Les modifications sont synchronisées automatiquement',
  'calendar_event_title': '🎂 Anniversaire : {name}',
  'calendar_event_description_noyear': 'Synchronisé par Memento Mori – La vie en semaines',
  'calendar_event_description':
      'Année de naissance : {year}\n\nSynchronisé par Memento Mori – La vie en semaines',
};
