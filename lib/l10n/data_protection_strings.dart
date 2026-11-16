/// Strings of "How your data is protected" (Settings > Data,
/// `lib/settings/data_protection_screen.dart`); spread into
/// AppLocalizations.
///
/// Neutral wording only: the screen shows in store builds too, so no
/// support or money words. French puts U+00A0 before `: ; ? ! %`.
const Map<String, String> dataProtectionStringsEn = {
  'data_protection_title': 'How your data is protected',
  'data_protection_screen_title': 'Your data, protected',
  'data_protection_tile_sub': 'Encryption, backups and export',
  'data_protection_intro': 'Your life calendar is personal. This is how the '
      'app keeps it that way.',
  'data_protection_encrypted_title': 'Encrypted on this device',
  'data_protection_encrypted_body': 'Your birth date, name and life '
      'expectancy, your estimate result, the people you add and their '
      'photos, your Compass entries and the state of your reminders and '
      'calendar sync are stored encrypted (AES-256). The key is kept by your '
      'phone’s secure key store and isn’t synced to your other devices; only '
      'a backup can carry it, together with your data (see Backups). '
      'Settings like theme and language aren’t personal and are stored as '
      'they are.',
  'data_protection_health_title': 'Health answers are never saved',
  'data_protection_health_body': 'The lifespan estimate asks about habits '
      'and health: smoking, activity, alcohol, social life and '
      'conditions, plus country, sex, height and weight. These answers are '
      'only used for the calculation. Only the result is kept – the answers '
      'are never saved, not on this device, not in backups and not in '
      'exports.',
  'data_protection_backup_title': 'Backups',
  'data_protection_backup_android': 'Android backs up the app only when the '
      'backup is end-to-end encrypted. The key travels only in such a '
      'backup or in a direct transfer to a new phone.',
  'data_protection_backup_ios': 'The key travels with iCloud backups and '
      'encrypted computer backups. Without Advanced Data Protection, Apple '
      'can technically access iCloud backups. An unencrypted computer backup '
      'brings your data back without its key: it stays locked, and nothing '
      'is deleted.',
  'data_protection_export_title': 'Export',
  'data_protection_export_body': 'An export is a plain, readable file unless '
      'you protect it with a password. A protected export is encrypted '
      '(AES-256 with a key made from your password). Without the password '
      'nobody can restore it, so keep it somewhere safe.',
  'data_protection_readable_title': 'What stays readable, and why',
  'data_protection_readable_body': 'A few things have to stay readable so '
      'your phone can use them: the home-screen widget and your watch get '
      'your birth date, life expectancy and display settings; scheduled '
      'reminders keep their texts, including names, so they still arrive '
      'after a restart; birthday events you choose to add to your calendar '
      'belong to the calendar. Backups made with earlier versions of the app '
      'may still contain unencrypted data until they are replaced.',
  'data_protection_offline_title': 'No internet, no account',
  'data_protection_offline_body': 'The app doesn’t send your data to any '
      'server. There is no account, no tracking and no ads. On Android it '
      'doesn’t even have permission to use the internet.',
  'data_protection_policy_link': 'Read the full privacy policy',
};

const Map<String, String> dataProtectionStringsDe = {
  'data_protection_title': 'So sind deine Daten geschützt',
  'data_protection_screen_title': 'Schutz deiner Daten',
  'data_protection_tile_sub': 'Verschlüsselung, Sicherungen und Export',
  'data_protection_intro': 'Dein Lebenskalender ist persönlich. So sorgt die '
      'App dafür, dass er es bleibt.',
  'data_protection_encrypted_title': 'Verschlüsselt auf diesem Gerät',
  'data_protection_encrypted_body': 'Dein Geburtsdatum, dein Name und deine '
      'Lebenserwartung, das Ergebnis deiner Schätzung, die Menschen, die du '
      'hinzufügst, und ihre Fotos, deine Kompass-Einträge sowie der Stand '
      'deiner Erinnerungen und der Kalender-Synchronisierung werden '
      'verschlüsselt gespeichert (AES-256). Den Schlüssel verwahrt der '
      'sichere Schlüsselspeicher deines Handys. Er wird nicht mit deinen '
      'anderen Geräten synchronisiert; nur eine Sicherung kann ihn zusammen '
      'mit deinen Daten mitnehmen (siehe Sicherungen). Einstellungen wie Design und Sprache sind nicht persönlich und werden '
      'unverändert gespeichert.',
  'data_protection_health_title': 'Gesundheitsangaben werden nie gespeichert',
  'data_protection_health_body': 'Die Schätzung der Lebenserwartung fragt '
      'nach Gewohnheiten und Gesundheit: Rauchen, Bewegung, Alkohol, '
      'soziales Leben und Erkrankungen, dazu Land, Geschlecht, Größe '
      'und Gewicht. Diese Antworten dienen nur der Berechnung. Behalten wird '
      'nur das Ergebnis – die Antworten werden nie gespeichert, weder auf '
      'diesem Gerät noch in Sicherungen oder Exporten.',
  'data_protection_backup_title': 'Sicherungen',
  'data_protection_backup_android': 'Android sichert die App nur, wenn die '
      'Sicherung Ende-zu-Ende-verschlüsselt ist. Der Schlüssel reist nur in '
      'einer solchen Sicherung oder bei einer direkten Übertragung auf ein '
      'neues Handy mit.',
  'data_protection_backup_ios': 'Der Schlüssel reist mit iCloud-Backups und '
      'verschlüsselten Computer-Backups mit. Ohne den erweiterten '
      'Datenschutz kann Apple technisch auf iCloud-Backups zugreifen. Ein '
      'unverschlüsseltes Computer-Backup bringt deine Daten ohne ihren '
      'Schlüssel zurück: Sie bleiben verschlossen, und es wird nichts '
      'gelöscht.',
  'data_protection_export_title': 'Export',
  'data_protection_export_body': 'Ein Export ist eine einfache, lesbare '
      'Datei, außer du schützt ihn mit einem Passwort. Ein geschützter Export '
      'ist verschlüsselt (AES-256 mit einem Schlüssel aus deinem Passwort). '
      'Ohne das Passwort kann ihn niemand wiederherstellen, bewahre es also '
      'gut auf.',
  'data_protection_readable_title': 'Was lesbar bleibt, und warum',
  'data_protection_readable_body': 'Einiges muss lesbar bleiben, damit dein '
      'Handy es nutzen kann: Das Widget auf dem Startbildschirm und deine Uhr '
      'bekommen dein Geburtsdatum, deine Lebenserwartung und die '
      'Anzeige-Einstellungen; geplante Erinnerungen behalten ihre Texte samt '
      'Namen, damit sie auch nach einem Neustart ankommen; '
      'Geburtstagstermine, die du in deinen Kalender eintragen lässt, gehören '
      'dem Kalender. Sicherungen von früheren Versionen der App können noch '
      'unverschlüsselte Daten enthalten, bis sie ersetzt werden.',
  'data_protection_offline_title': 'Kein Internet, kein Konto',
  'data_protection_offline_body': 'Die App schickt deine Daten an keinen '
      'Server. Es gibt kein Konto, kein Tracking und keine Werbung. Unter '
      'Android hat sie nicht einmal die Berechtigung, das Internet zu nutzen.',
  'data_protection_policy_link': 'Ganze Datenschutzerklärung lesen',
};

const Map<String, String> dataProtectionStringsFr = {
  'data_protection_title': 'Comment tes données sont protégées',
  'data_protection_screen_title': 'Protection de tes données',
  'data_protection_tile_sub': 'Chiffrement, sauvegardes et export',
  'data_protection_intro': 'Ton calendrier de vie est personnel. Voici '
      'comment l’app veille à ce qu’il le reste.',
  'data_protection_encrypted_title': 'Chiffré sur cet appareil',
  'data_protection_encrypted_body': 'Ta date de naissance, ton prénom et ton '
      'espérance de vie, le résultat de ton estimation, les personnes que tu '
      'ajoutes et leurs photos, tes entrées de Boussole ainsi que l’état de '
      'tes rappels et de la synchronisation du calendrier sont enregistrés '
      'chiffrés (AES-256). La clé est gardée par le stockage sécurisé de ton '
      'téléphone et n’est pas synchronisée avec tes autres appareils ; seule '
      'une sauvegarde peut l’emporter, avec tes données (voir Sauvegardes). '
      'Les réglages comme le thème et la '
      'langue ne sont pas personnels et sont enregistrés tels quels.',
  'data_protection_health_title':
      'Les réponses de santé ne sont jamais enregistrées',
  'data_protection_health_body': 'L’estimation de l’espérance de vie pose '
      'des questions sur tes habitudes et ta santé : tabac, activité, '
      'alcool, vie sociale et maladies, ainsi que pays, sexe, taille '
      'et poids. Ces réponses servent uniquement au calcul. Seul le résultat '
      'est conservé – les réponses ne sont jamais enregistrées, ni sur cet '
      'appareil, ni dans les sauvegardes, ni dans les exports.',
  'data_protection_backup_title': 'Sauvegardes',
  'data_protection_backup_android': 'Android ne sauvegarde l’app que si la '
      'sauvegarde est chiffrée de bout en bout. La clé ne voyage que dans une '
      'telle sauvegarde ou lors d’un transfert direct vers un nouveau '
      'téléphone.',
  'data_protection_backup_ios': 'La clé voyage avec les sauvegardes iCloud '
      'et les sauvegardes chiffrées sur ordinateur. Sans la protection '
      'avancée des données, Apple peut techniquement accéder aux sauvegardes '
      'iCloud. Une sauvegarde non chiffrée sur ordinateur restaure tes '
      'données sans leur clé : elles restent verrouillées, et rien '
      'n’est supprimé.',
  'data_protection_export_title': 'Export',
  'data_protection_export_body': 'Un export est un simple fichier lisible, '
      'sauf si tu le protèges par un mot de passe. Un export protégé est '
      'chiffré (AES-256 avec une clé issue de ton mot de passe). Sans le mot '
      'de passe, personne ne peut le restaurer, alors garde-le en lieu sûr.',
  'data_protection_readable_title': 'Ce qui reste lisible, et pourquoi',
  'data_protection_readable_body': 'Certaines choses doivent rester lisibles '
      'pour que ton téléphone puisse les utiliser : le widget de '
      'l’écran d’accueil et ta montre reçoivent ta date de naissance, ton '
      'espérance de vie et les réglages d’affichage ; les rappels '
      'programmés gardent leurs textes, noms compris, pour arriver même après '
      'un redémarrage ; les anniversaires que tu choisis d’ajouter à ton '
      'calendrier appartiennent au calendrier. Les sauvegardes faites avec '
      'des versions antérieures de l’app peuvent encore contenir des données '
      'non chiffrées jusqu’à ce qu’elles soient remplacées.',
  'data_protection_offline_title': 'Pas d’internet, pas de compte',
  'data_protection_offline_body': 'L’app n’envoie tes données à aucun '
      'serveur. Pas de compte, pas de pistage, pas de publicité. Sur Android, '
      'elle n’a même pas l’autorisation d’utiliser internet.',
  'data_protection_policy_link': 'Lire la politique de confidentialité',
};

const Map<String, String> dataProtectionStringsEs = {
  'data_protection_title': 'Cómo se protegen tus datos',
  'data_protection_screen_title': 'Protección de tus datos',
  'data_protection_tile_sub': 'Cifrado, copias de seguridad y exportación',
  'data_protection_intro': 'Tu calendario de vida es personal. Así se '
      'encarga la app de que lo siga siendo.',
  'data_protection_encrypted_title': 'Cifrado en este dispositivo',
  'data_protection_encrypted_body': 'Tu fecha de nacimiento, tu nombre y tu '
      'esperanza de vida, el resultado de tu estimación, las personas que '
      'añades y sus fotos, tus entradas de la Brújula y el estado de tus '
      'recordatorios y de la sincronización del calendario se guardan '
      'cifrados (AES-256). La clave la guarda el almacén seguro de claves de '
      'tu móvil y no se sincroniza con tus otros dispositivos; solo una '
      'copia de seguridad puede llevarla, junto con tus datos (ver Copias de '
      'seguridad). Los ajustes como el tema y el idioma no '
      'son personales y se guardan tal cual.',
  'data_protection_health_title': 'Las respuestas de salud nunca se guardan',
  'data_protection_health_body': 'La estimación de la esperanza de vida '
      'pregunta por tus hábitos y tu salud: tabaco, actividad, alcohol, '
      'vida social y enfermedades, además de país, sexo, altura y peso. Esas '
      'respuestas solo se usan para el cálculo. Solo se conserva el resultado '
      '– las respuestas nunca se guardan, ni en este dispositivo, ni en las '
      'copias de seguridad, ni en las exportaciones.',
  'data_protection_backup_title': 'Copias de seguridad',
  'data_protection_backup_android': 'Android solo hace una copia de '
      'seguridad de la app cuando está cifrada de extremo a extremo. La clave '
      'solo viaja en una copia así o en una transferencia directa a un móvil '
      'nuevo.',
  'data_protection_backup_ios': 'La clave viaja con las copias de iCloud y '
      'las copias cifradas en el ordenador. Sin la Protección de datos '
      'avanzada, Apple puede acceder técnicamente a las copias de iCloud. Una '
      'copia sin cifrar en el ordenador devuelve tus datos sin su clave: '
      'siguen bloqueados y no se borra nada.',
  'data_protection_export_title': 'Exportación',
  'data_protection_export_body': 'Una exportación es un archivo sencillo y '
      'legible, salvo que la protejas con una contraseña. Una exportación '
      'protegida está cifrada (AES-256 con una clave derivada de tu '
      'contraseña). Sin la contraseña nadie puede restaurarla, así que '
      'guárdala en un lugar seguro.',
  'data_protection_readable_title': 'Qué sigue siendo legible y por qué',
  'data_protection_readable_body': 'Algunas cosas tienen que seguir siendo '
      'legibles para que tu móvil pueda usarlas: el widget de la pantalla de '
      'inicio y tu reloj reciben tu fecha de nacimiento, tu esperanza de vida '
      'y los ajustes de visualización; los recordatorios programados '
      'conservan sus textos, nombres incluidos, para llegar también después '
      'de un reinicio; los cumpleaños que decides añadir a tu calendario '
      'pertenecen al calendario. Las copias de seguridad hechas con versiones '
      'anteriores de la app pueden seguir conteniendo datos sin cifrar hasta '
      'que se sustituyan.',
  'data_protection_offline_title': 'Sin internet, sin cuenta',
  'data_protection_offline_body': 'La app no envía tus datos a ningún '
      'servidor. No hay cuenta, ni seguimiento, ni anuncios. En Android ni '
      'siquiera tiene permiso para usar internet.',
  'data_protection_policy_link': 'Leer la política de privacidad completa',
};
