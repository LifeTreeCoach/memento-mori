/// Strings of the locked-data screen (`lib/security/ui/`), shown when the
/// encrypted personal data on this device cannot be opened, and of the
/// unsaved-changes notice (`vault_unsaved_*`); spread into AppLocalizations.
///
/// French puts U+00A0 before `: ; ? ! %`; Spanish opens questions with `¿`.
const Map<String, String> vaultStringsEn = {
  'vault_locked_title': 'Your data can’t be opened right now',
  'vault_locked_body': 'Your personal data on this device is stored '
      'encrypted, and its key can’t be read at the moment. This can happen '
      'when the data was moved to this device without its key – for example '
      'by restoring a backup of the app.',
  'vault_locked_nothing_deleted':
      'Nothing has been deleted. Your data is still here, just locked.',
  'vault_locked_unlock_hint':
      'If your phone has just restarted, unlock it once and try again.',
  'vault_unavailable_hint': 'Unlock your phone and try again. If it still '
      'doesn’t open, restart your phone and try once more.',
  'vault_try_again': 'Try again',
  'vault_still_locked': 'Still locked. Nothing was changed.',
  'vault_start_fresh': 'Start fresh',
  'vault_start_fresh_title': 'Start fresh?',
  'vault_start_fresh_body': 'The locked data on this device – your birth '
      'date, people, photos and Compass – will be deleted permanently. This '
      'can’t be undone.\n\nIf you have a backup file, you can import it '
      'afterwards under Settings > Data > Import & Export.',
  'vault_start_fresh_confirm': 'Delete and start fresh',
  'vault_start_fresh_cancel': 'Cancel',
  'vault_start_fresh_failed': 'That didn’t work. Please try again.',
  'vault_unsaved_message': 'Your latest changes couldn’t be saved. Free up '
      'some storage space and try again.',
  'vault_unsaved_retry': 'Try again',
  'vault_unsaved_saved': 'Saved.',
};

const Map<String, String> vaultStringsDe = {
  'vault_locked_title': 'Deine Daten lassen sich gerade nicht öffnen',
  'vault_locked_body': 'Deine persönlichen Daten sind auf diesem Gerät '
      'verschlüsselt gespeichert, und ihr Schlüssel lässt sich gerade nicht '
      'lesen. Das kann passieren, wenn die Daten ohne ihren Schlüssel auf '
      'dieses Gerät gekommen sind – zum Beispiel durch das Wiederherstellen '
      'einer Sicherung der App.',
  'vault_locked_nothing_deleted':
      'Es wurde nichts gelöscht. Deine Daten sind noch da, nur verschlossen.',
  'vault_locked_unlock_hint': 'Wenn dein Handy gerade neu gestartet ist, '
      'entsperre es einmal und versuche es dann noch einmal.',
  'vault_unavailable_hint': 'Entsperre dein Handy und versuche es noch '
      'einmal. Klappt es dann noch nicht, starte dein Handy neu und versuche '
      'es danach erneut.',
  'vault_try_again': 'Noch einmal versuchen',
  'vault_still_locked': 'Noch immer verschlossen. Es wurde nichts verändert.',
  'vault_start_fresh': 'Neu beginnen',
  'vault_start_fresh_title': 'Neu beginnen?',
  'vault_start_fresh_body': 'Die verschlossenen Daten auf diesem Gerät – '
      'dein Geburtsdatum, deine Menschen, Fotos und Kompass – werden endgültig '
      'gelöscht. Das lässt sich nicht rückgängig machen.\n\nWenn du eine '
      'Sicherungsdatei hast, kannst du sie danach unter Einstellungen > Daten '
      '> Import & Export importieren.',
  'vault_start_fresh_confirm': 'Löschen und neu beginnen',
  'vault_start_fresh_cancel': 'Abbrechen',
  'vault_start_fresh_failed':
      'Das hat nicht geklappt. Bitte versuche es noch einmal.',
  'vault_unsaved_message': 'Deine letzten Änderungen konnten nicht '
      'gespeichert werden. Schaffe etwas Speicherplatz frei und versuche es '
      'noch einmal.',
  'vault_unsaved_retry': 'Noch einmal versuchen',
  'vault_unsaved_saved': 'Gespeichert.',
};

const Map<String, String> vaultStringsFr = {
  'vault_locked_title': 'Tes données ne peuvent pas être ouvertes pour le '
      'moment',
  'vault_locked_body': 'Tes données personnelles sont chiffrées sur cet '
      'appareil, et leur clé ne peut pas être lue pour le moment. Cela peut '
      'arriver quand les données ont été transférées sur cet appareil sans '
      'leur clé – par exemple en restaurant une sauvegarde de l’app.',
  'vault_locked_nothing_deleted': 'Rien n’a été supprimé. Tes données sont '
      'toujours là, simplement verrouillées.',
  'vault_locked_unlock_hint': 'Si ton téléphone vient de redémarrer, '
      'déverrouille-le une fois et réessaie.',
  'vault_unavailable_hint': 'Déverrouille ton téléphone et réessaie. Si '
      'ça ne s’ouvre toujours pas, redémarre ton téléphone et réessaie.',
  'vault_try_again': 'Réessayer',
  'vault_still_locked': 'Toujours verrouillé. Rien n’a été modifié.',
  'vault_start_fresh': 'Repartir de zéro',
  'vault_start_fresh_title': 'Repartir de zéro ?',
  'vault_start_fresh_body': 'Les données verrouillées sur cet appareil – ta '
      'date de naissance, tes proches, les photos et la Boussole – seront '
      'supprimées définitivement. C’est irréversible.\n\nSi tu as un fichier '
      'de sauvegarde, tu pourras l’importer ensuite dans Réglages > Données > '
      'Import et export.',
  'vault_start_fresh_confirm': 'Supprimer et repartir de zéro',
  'vault_start_fresh_cancel': 'Annuler',
  'vault_start_fresh_failed': 'Ça n’a pas fonctionné. Réessaie, s’il te plaît.',
  'vault_unsaved_message': 'Tes dernières modifications n’ont pas pu être '
      'enregistrées. Libère un peu d’espace de stockage et réessaie.',
  'vault_unsaved_retry': 'Réessayer',
  'vault_unsaved_saved': 'Enregistré.',
};

const Map<String, String> vaultStringsEs = {
  'vault_locked_title': 'Ahora mismo no se pueden abrir tus datos',
  'vault_locked_body': 'Tus datos personales están guardados cifrados en '
      'este dispositivo, y su clave no se puede leer en este momento. Puede '
      'pasar cuando los datos llegaron a este dispositivo sin su clave, por '
      'ejemplo al restaurar una copia de seguridad de la app.',
  'vault_locked_nothing_deleted': 'No se ha borrado nada. Tus datos siguen '
      'aquí, solo están bloqueados.',
  'vault_locked_unlock_hint': 'Si tu teléfono acaba de reiniciarse, '
      'desbloquéalo una vez y vuelve a intentarlo.',
  'vault_unavailable_hint': 'Desbloquea tu teléfono y vuelve a intentarlo. '
      'Si sigue sin abrirse, reinicia tu teléfono y prueba otra vez.',
  'vault_try_again': 'Intentar de nuevo',
  'vault_still_locked': 'Sigue bloqueado. No se ha cambiado nada.',
  'vault_start_fresh': 'Empezar de cero',
  'vault_start_fresh_title': '¿Empezar de cero?',
  'vault_start_fresh_body': 'Los datos bloqueados de este dispositivo (tu '
      'fecha de nacimiento, tus personas, las fotos y la Brújula) se borrarán '
      'para siempre. No se puede deshacer.\n\nSi tienes un archivo de copia '
      'de seguridad, podrás importarlo después en Ajustes > Datos > Importar '
      'y exportar.',
  'vault_start_fresh_confirm': 'Borrar y empezar de cero',
  'vault_start_fresh_cancel': 'Cancelar',
  'vault_start_fresh_failed': 'No ha funcionado. Inténtalo de nuevo.',
  'vault_unsaved_message': 'No se han podido guardar tus últimos cambios. '
      'Libera algo de espacio de almacenamiento e inténtalo de nuevo.',
  'vault_unsaved_retry': 'Reintentar',
  'vault_unsaved_saved': 'Guardado.',
};
