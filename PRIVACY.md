# Privacy

Effective date: 2026-11-13

Deutsche Fassung: [weiter unten](#datenschutz).
Version française : [plus bas](#confidentialité).
Versión en español: [más abajo](#privacidad).

## English

Memento Mori - Life in Weeks keeps everything on your device. There is no
account, no analytics or tracking, no ads and no server of ours.

### What the app stores

On your device only:

- your name (optional), birth date, life expectancy and settings (language,
  theme, reminders, widget)
- the people you add: name, birthday (with or without year), groups, an
  optional photo, message, meeting frequency and life expectancy. People you
  import also keep where they came from (contacts or vCard) and the contact's
  id there, so a later import only shows new or changed birthdays.
- your Compass entries and weekly questions
- of the lifespan estimate, only the result: the years (for you also the
  average and the range). The answers - country, sex, height and weight,
  smoking, activity, alcohol, social life and the optional health answers
  such as chronic conditions - are only used for the calculation and are
  never saved: not on the device, not in backups and not in exports. This
  applies to estimates for other people too.

### How your data is protected

- **Encrypted on the device**: your name, birth date, life expectancy,
  estimate result, people, Compass entries, calendar sync state and
  reminder state, and the photos of your people, are stored encrypted with
  AES-256-GCM. The 256-bit key is held by the system key store (Android
  Keystore, iPhone Keychain), available after the first unlock and not synced
  to your other devices. Only a backup can carry it, together with the data:
  on iPhone it travels with iCloud and encrypted computer backups (see
  "Backups and export"). Settings that are not personal (theme, language and
  similar switches) are stored without encryption.
- **What stays readable**, because the system or the native parts of the app
  need it:
  - the home-screen widget and the watch inputs: birth date, life expectancy
    and display settings
  - the list of scheduled notifications, kept by the notification library so
    reminders still arrive after a restart; it contains their texts,
    including names
  - calendar events, if you turn on birthday sync
- If the encrypted data reaches a device without its key (for example after
  restoring an unencrypted computer backup on an iPhone), the app shows that
  the data is locked and offers "Try again" or "Start fresh". Nothing is
  deleted automatically.

### Internet

Release builds for Android do not have the internet permission, so the app
cannot send anything anywhere. The app contains no networking code on any
platform.

### Permissions

- **Notifications**: birthday reminders and the optional weekly question.
  They are scheduled on the device.
- **Calendar** (optional): only if you turn on birthday sync. The app then
  writes the birthdays of your people into the calendar you choose. If that
  calendar syncs with an online account, the account provider will see those
  events.
- **Run at startup** (`RECEIVE_BOOT_COMPLETED`): to reschedule reminders and the
  home-screen widget's midnight refresh after a restart.
- **Contacts** (optional, read only): only when you import birthdays from your
  contacts. The app reads names, birthdays and, if you want, contact photos,
  on the device only. Only the people you select are saved; nothing else from
  your address book is kept, and nothing is written back to it. The import is
  one-time: the app does not read your contacts in the background. You can
  revoke the permission at any time in your system settings; people you
  already imported stay in the app.
  - On Android 17 and newer, "Choose contacts" uses the system contact picker
    and needs no permission: the app only receives the contacts you pick.
    Only "Search all contacts with a birthday" asks for the contacts
    permission.
  - On iPhone you can share all contacts or only selected ones.
- **vCard file** (optional): importing a .vcf file needs no permission. The app
  reads only the file you choose, on the device.
- **Photos / camera**: only when you pick a photo for a person. The app
  receives just the picture you choose and keeps a copy of it on the device.
- **Vibration, wake lock, network state**: added by the notification and
  widget libraries (Android); the app sends no data.

### Backups and export

- **Android backup and device transfer**: the app's data is only backed up to
  the cloud when the backup is end-to-end encrypted (Android skips it
  otherwise); a direct transfer to a new phone works too. The data key goes
  only into such an end-to-end encrypted backup or the device-to-device
  transfer.
- **iPhone**: the key travels with iCloud backups and encrypted computer
  backups. Without Advanced Data Protection, Apple can technically access
  iCloud backups, which contain the data and the key. An unencrypted computer
  backup restores the data without its key, so it stays locked (see above).
- Backups made before this version may still contain unencrypted data until
  they are replaced by newer ones.
- **Export / import** (Settings > Data): creates a file with your people
  (including their life expectancy), their photos and your Compass entries.
  It never contains estimate answers. By default it is a readable JSON file;
  you can protect it with a password instead (PBKDF2-HMAC-SHA256 with 600,000
  iterations and AES-256-GCM). Without the password nobody can restore a
  protected export. You decide where the file goes; the app never uploads it.

### Watches

- **Wear OS** (Google Play build only): your birth date, life expectancy,
  display and colour settings are sent from your phone to your watch over the
  Wear OS Data Layer, device to device. People are never sent. The F-Droid /
  APK build contains no Google Play services and no watch sync.
- **Apple Watch**: the same values go from the iPhone to the watch through
  Apple's WatchConnectivity.

### Links

Some buttons open a page in your browser or store app; after that, that site's
own privacy policy applies:

- GitHub: source code, ideas & feedback, this page
- Buy Me a Coffee: only in the F-Droid / APK build
- Google Play / App Store: "Rate the app" in store builds

Sharing (a quote, a person, a recommendation, a backup) uses your system's share
sheet and only goes where you send it.

### Contact

Questions or concerns:
https://github.com/LifeTreeCoach/memento-mori/discussions

---

## Datenschutz

Gültig ab: 2026-11-13

Memento Mori speichert alles auf deinem Gerät. Es gibt kein
Konto, keine Analyse oder Tracking, keine Werbung und keinen eigenen Server.

### Was die App speichert

Nur auf deinem Gerät:

- deinen Namen (optional), dein Geburtsdatum, deine Lebenserwartung und
  Einstellungen (Sprache, Design, Erinnerungen, Widget)
- die Personen, die du hinzufügst: Name, Geburtstag (mit oder ohne Jahr),
  Gruppen, optional ein Foto, eine Nachricht, wie oft ihr euch seht und ihre
  Lebenserwartung. Bei importierten Personen merkt sich die App außerdem die
  Herkunft (Kontakte oder vCard) und die Kontakt-ID dort, damit ein späterer
  Import nur neue oder geänderte Geburtstage zeigt.
- deine Kompass-Einträge und Wochenfragen
- von der Lebenserwartungs-Schätzung nur das Ergebnis: die Jahre (für dich
  außerdem Mittelwert und Spanne). Die Antworten - Land, Geschlecht, Größe und
  Gewicht, Rauchen, Bewegung, Alkohol, soziales Leben und die optionalen
  Gesundheitsangaben wie chronische Erkrankungen - dienen nur der Berechnung
  und werden nie gespeichert: weder auf dem Gerät noch in Sicherungen oder
  Exporten. Das gilt auch für Schätzungen für andere Menschen.

### Wie deine Daten geschützt sind

- **Verschlüsselt auf dem Gerät**: dein Name, Geburtsdatum, deine
  Lebenserwartung, das Ergebnis der Schätzung, deine Personen,
  Kompass-Einträge, der Stand der Kalender-Synchronisierung und der
  Erinnerungen sowie die Fotos deiner Personen werden mit AES-256-GCM
  verschlüsselt gespeichert. Den 256-Bit-Schlüssel verwahrt der
  Schlüsselspeicher des Systems (Android Keystore, iPhone-Schlüsselbund),
  verfügbar nach dem ersten Entsperren und nicht mit deinen anderen Geräten
  synchronisiert. Nur eine Sicherung kann ihn zusammen mit den Daten
  mitnehmen: Auf dem iPhone reist er mit iCloud-Backups und verschlüsselten
  Computer-Backups (siehe „Sicherungen und Export“). Nicht persönliche Einstellungen (Design, Sprache und
  ähnliche Schalter) werden unverschlüsselt gespeichert.
- **Was lesbar bleibt**, weil das System oder die nativen Teile der App es
  brauchen:
  - die Eingaben für Widget und Uhr: Geburtsdatum, Lebenserwartung und
    Anzeige-Einstellungen
  - die Liste der geplanten Benachrichtigungen, die die
    Benachrichtigungs-Bibliothek aufbewahrt, damit Erinnerungen auch nach
    einem Neustart ankommen; sie enthält deren Texte samt Namen
  - Kalendertermine, wenn du die Geburtstags-Synchronisierung einschaltest
- Kommen die verschlüsselten Daten ohne ihren Schlüssel auf ein Gerät (zum
  Beispiel nach dem Wiederherstellen einer unverschlüsselten
  Computer-Sicherung auf einem iPhone), zeigt die App, dass die Daten
  verschlossen sind, und bietet "Noch einmal versuchen" oder "Neu beginnen"
  an. Es wird nichts automatisch gelöscht.

### Internet

Release-Versionen für Android haben keine Internet-Berechtigung, die App kann
also nichts versenden. Die App enthält auf keiner Plattform Netzwerk-Code.

### Berechtigungen

- **Benachrichtigungen**: Geburtstagserinnerungen und die optionale
  Wochenfrage. Sie werden auf dem Gerät geplant.
- **Kalender** (optional): nur wenn du den Geburtstags-Abgleich einschaltest.
  Dann trägt die App die Geburtstage deiner Personen in den Kalender ein, den
  du auswählst. Wird dieser Kalender mit einem Online-Konto synchronisiert,
  sieht der Anbieter des Kontos diese Termine.
- **Beim Start ausführen** (`RECEIVE_BOOT_COMPLETED`): um Erinnerungen und die
  nächtliche Aktualisierung des Widgets nach einem Neustart neu zu planen.
- **Kontakte** (optional, nur lesen): nur wenn du Geburtstage aus deinen
  Kontakten importierst. Die App liest Namen, Geburtstage und, wenn du
  möchtest, Kontaktfotos, nur auf dem Gerät. Gespeichert werden nur die
  Personen, die du auswählst; sonst wird nichts aus deinem Adressbuch
  behalten und nichts dorthin zurückgeschrieben. Der Import ist einmalig: Die
  App liest deine Kontakte nicht im Hintergrund. Du kannst die Berechtigung
  jederzeit in den Systemeinstellungen entziehen; bereits importierte
  Personen bleiben in der App.
  - Ab Android 17 nutzt „Kontakte auswählen“ die Kontaktauswahl des Systems
    und braucht keine Berechtigung: Die App bekommt nur die Kontakte, die du
    auswählst. Nur „Alle Kontakte mit Geburtstag durchsuchen“ fragt nach der
    Kontakte-Berechtigung.
  - Auf dem iPhone kannst du alle Kontakte oder nur ausgewählte freigeben.
- **vCard-Datei** (optional): Der Import einer .vcf-Datei braucht keine
  Berechtigung. Die App liest nur die Datei, die du auswählst, auf dem Gerät.
- **Fotos / Kamera**: nur wenn du ein Foto für eine Person auswählst. Die App
  bekommt nur das Bild, das du wählst, und speichert eine Kopie auf dem Gerät.
- **Vibration, Wake Lock, Netzwerkstatus**: kommen von den Bibliotheken für
  Benachrichtigungen und Widget (Android); die App sendet keine Daten.

### Sicherungen und Export

- **Android-Sicherung und Geräteübertragung**: Die Daten der App werden nur
  dann in der Cloud gesichert, wenn die Sicherung Ende-zu-Ende-verschlüsselt
  ist (sonst lässt Android sie aus); eine direkte Übertragung auf ein neues
  Handy geht ebenfalls. Der Datenschlüssel kommt nur in eine solche
  Ende-zu-Ende-verschlüsselte Sicherung oder in die Übertragung von Gerät zu
  Gerät.
- **iPhone**: Der Schlüssel reist mit iCloud-Backups und verschlüsselten
  Computer-Backups mit. Ohne den erweiterten Datenschutz kann Apple technisch
  auf iCloud-Backups zugreifen, die Daten und Schlüssel enthalten. Ein
  unverschlüsseltes Computer-Backup stellt die Daten ohne ihren Schlüssel
  wieder her, sie bleiben dann verschlossen (siehe oben).
- Sicherungen, die vor dieser Version entstanden sind, können noch
  unverschlüsselte Daten enthalten, bis neuere sie ersetzen.
- **Export / Import** (Einstellungen > Daten): erstellt eine Datei mit deinen
  Personen (samt ihrer Lebenserwartung), ihren Fotos und deinen
  Kompass-Einträgen. Antworten zur Schätzung enthält sie nie. Standardmäßig
  ist sie eine lesbare JSON-Datei; du kannst sie stattdessen mit einem
  Passwort schützen (PBKDF2-HMAC-SHA256 mit 600.000 Durchläufen und
  AES-256-GCM). Ohne das Passwort kann niemand einen geschützten Export
  wiederherstellen. Du entscheidest, wo die Datei landet; die App lädt sie
  nirgends hoch.

### Uhren

- **Wear OS** (nur die Google-Play-Version): dein Geburtsdatum, deine
  Lebenserwartung sowie Anzeige- und Farbeinstellungen gehen über den Wear OS
  Data Layer direkt vom Handy auf die Uhr. Personen werden nie übertragen. Die
  F-Droid-/APK-Version enthält keine Google-Play-Dienste und keinen
  Uhren-Abgleich.
- **Apple Watch**: dieselben Werte gehen über Apples WatchConnectivity vom
  iPhone auf die Uhr.

### Links

Einige Schaltflächen öffnen eine Seite im Browser oder im Store; dort gilt die
Datenschutzerklärung der jeweiligen Seite:

- GitHub: Quellcode, Ideen & Feedback, diese Seite
- Buy Me a Coffee: nur in der F-Droid-/APK-Version
- Google Play / App Store: „App bewerten“ in den Store-Versionen

Teilen (ein Zitat, eine Person, eine Empfehlung, eine Sicherung) läuft über das Teilen-Menü
deines Systems und geht nur dorthin, wohin du es schickst.

### Kontakt

Fragen oder Anliegen:
https://github.com/LifeTreeCoach/memento-mori/discussions

---

## Confidentialité

En vigueur depuis le : 2026-11-13

Memento Mori - Life in Weeks garde tout sur ton appareil. Il n’y a ni
compte, ni analyse ou suivi, ni publicité, ni serveur à nous.

### Ce que l’app enregistre

Uniquement sur ton appareil :

- ton prénom (facultatif), ta date de naissance, ton espérance de vie et tes
  réglages (langue, thème, rappels, widget)
- les personnes que tu ajoutes : nom, anniversaire (avec ou sans année),
  groupes, et en option une photo, un message, la fréquence de vos rencontres
  et leur espérance de vie. Pour les personnes importées, l’app retient aussi
  leur provenance (contacts ou vCard) et l’identifiant du contact là-bas, pour
  qu’une importation ultérieure n’affiche que les anniversaires nouveaux ou
  modifiés.
- tes entrées de la Boussole et les questions de la semaine
- de l’estimation de l’espérance de vie, uniquement le résultat : les années
  (pour toi aussi la moyenne et la fourchette). Les réponses - pays, sexe,
  taille et poids, tabac, activité, alcool, vie sociale et les réponses de
  santé facultatives comme les maladies chroniques - servent uniquement au
  calcul et ne sont jamais enregistrées : ni sur l’appareil, ni dans les
  sauvegardes, ni dans les exports. Cela vaut aussi pour les estimations
  faites pour d’autres personnes.

### Comment tes données sont protégées

- **Chiffrées sur l’appareil** : ton prénom, ta date de naissance, ton
  espérance de vie, le résultat de l’estimation, tes personnes, tes entrées
  de la Boussole, l’état de la synchronisation du calendrier et des rappels,
  ainsi que les photos de tes personnes, sont enregistrés chiffrés avec
  AES-256-GCM. La clé de 256 bits est gardée par le stockage de clés du
  système (Android Keystore, trousseau de l’iPhone), disponible après le
  premier déverrouillage et non synchronisée avec tes autres appareils. Seule
  une sauvegarde peut l’emporter, avec les données : sur iPhone, elle
  voyage avec les sauvegardes iCloud et les sauvegardes chiffrées sur
  ordinateur (voir « Sauvegardes et export »). Les
  réglages non personnels (thème, langue et interrupteurs similaires) sont
  enregistrés sans chiffrement.
- **Ce qui reste lisible**, parce que le système ou les parties natives de
  l’app en ont besoin :
  - les données du widget et de la montre : date de naissance, espérance de
    vie et réglages d’affichage
  - la liste des notifications programmées, conservée par la bibliothèque de
    notifications pour que les rappels arrivent même après un redémarrage ;
    elle contient leurs textes, noms compris
  - les événements du calendrier, si tu actives la synchronisation des
    anniversaires
- Si les données chiffrées arrivent sur un appareil sans leur clé (par
  exemple après la restauration d’une sauvegarde non chiffrée sur ordinateur
  sur un iPhone), l’app indique que les données sont verrouillées et propose
  « Réessayer » ou « Repartir de zéro ». Rien n’est supprimé
  automatiquement.

### Internet

Les versions de production pour Android n’ont pas l’autorisation d’accès à
Internet : l’app ne peut donc rien envoyer nulle part. L’app ne contient aucun
code réseau, sur aucune plateforme.

### Autorisations

- **Notifications** : rappels d’anniversaire et question hebdomadaire
  facultative. Ils sont planifiés sur l’appareil.
- **Calendrier** (facultatif) : uniquement si tu actives la synchronisation
  des anniversaires. L’app inscrit alors les anniversaires de tes personnes
  dans le calendrier que tu choisis. Si ce calendrier est synchronisé avec un
  compte en ligne, le fournisseur du compte verra ces événements.
- **Exécution au démarrage** (`RECEIVE_BOOT_COMPLETED`) : pour replanifier les
  rappels et l’actualisation de minuit du widget de l’écran d’accueil après un
  redémarrage.
- **Contacts** (facultatif, lecture seule) : uniquement quand tu importes des
  anniversaires depuis tes contacts. L’app lit les noms, les anniversaires et,
  si tu le souhaites, les photos des contacts, uniquement sur l’appareil.
  Seules les personnes que tu sélectionnes sont enregistrées ; rien d’autre de
  ton carnet d’adresses n’est conservé, et rien n’y est réécrit. L’importation
  est ponctuelle : l’app ne lit pas tes contacts en arrière-plan. Tu peux
  retirer l’autorisation à tout moment dans les réglages du système ; les
  personnes déjà importées restent dans l’app.
  - À partir d’Android 17, « Choisir des contacts » utilise le sélecteur de
    contacts du système et ne demande aucune autorisation : l’app ne reçoit
    que les contacts que tu choisis. Seul « Parcourir tous les contacts avec
    un anniversaire » demande l’autorisation d’accès aux contacts.
  - Sur iPhone, tu peux partager tous tes contacts ou seulement certains.
- **Fichier vCard** (facultatif) : importer un fichier .vcf ne demande aucune
  autorisation. L’app lit uniquement le fichier que tu choisis, sur l’appareil.
- **Photos / appareil photo** : uniquement quand tu choisis une photo pour une
  personne. L’app reçoit seulement l’image que tu choisis et en garde une
  copie sur l’appareil.
- **Vibration, maintien de l’activité (wake lock), état du réseau** : ajoutés
  par les bibliothèques de notifications et de widget (Android) ; l’app
  n’envoie aucune donnée.

### Sauvegardes et export

- **Sauvegarde Android et transfert d’appareil** : les données de l’app ne
  sont sauvegardées dans le cloud que si la sauvegarde est chiffrée de bout
  en bout (sinon Android les ignore) ; un transfert direct vers un nouveau
  téléphone fonctionne aussi. La clé des données ne va que dans une telle
  sauvegarde chiffrée de bout en bout ou dans le transfert d’appareil à
  appareil.
- **iPhone** : la clé voyage avec les sauvegardes iCloud et les sauvegardes
  chiffrées sur ordinateur. Sans la protection avancée des données, Apple
  peut techniquement accéder aux sauvegardes iCloud, qui contiennent les
  données et la clé. Une sauvegarde non chiffrée sur ordinateur restaure les
  données sans leur clé ; elles restent alors verrouillées (voir plus haut).
- Les sauvegardes faites avant cette version peuvent encore contenir des
  données non chiffrées jusqu’à ce que de plus récentes les remplacent.
- **Export / import** (Réglages > Données) : crée un fichier avec tes
  personnes (y compris leur espérance de vie), leurs photos et tes entrées de
  la Boussole. Il ne contient jamais les réponses de l’estimation. Par
  défaut, c’est un fichier JSON lisible ; tu peux le protéger par un mot de
  passe (PBKDF2-HMAC-SHA256 avec 600 000 itérations et AES-256-GCM). Sans le
  mot de passe, personne ne peut restaurer un export protégé. C’est toi qui
  décides où va le fichier ; l’app ne le téléverse jamais.

### Montres

- **Wear OS** (version Google Play uniquement) : ta date de naissance, ton
  espérance de vie et tes réglages d’affichage et de couleurs sont envoyés de
  ton téléphone à ta montre via le Wear OS Data Layer, d’appareil à appareil.
  Les personnes ne sont jamais envoyées. La version F-Droid / APK ne contient
  pas les services Google Play ni de synchronisation avec la montre.
- **Apple Watch** : les mêmes valeurs passent de l’iPhone à la montre via
  WatchConnectivity d’Apple.

### Liens

Certains boutons ouvrent une page dans ton navigateur ou ta boutique
d’applications ; ensuite, c’est la politique de confidentialité de ce site qui
s’applique :

- GitHub : code source, idées et retours, cette page
- Buy Me a Coffee : uniquement dans la version F-Droid / APK
- Google Play / App Store : « Noter l’app » dans les versions des boutiques

Le partage (une citation, une personne, une recommandation, une sauvegarde)
passe par le menu de partage de ton système et ne va que là où tu l’envoies.

### Contact

Questions ou préoccupations :
https://github.com/LifeTreeCoach/memento-mori/discussions

---

## Privacidad

En vigor desde: 2026-11-13

Memento Mori - Life in Weeks guarda todo en tu dispositivo. No hay cuenta,
ni analíticas o seguimiento, ni anuncios, ni servidor propio.

### Qué guarda la app

Solo en tu dispositivo:

- tu nombre (opcional), tu fecha de nacimiento, tu esperanza de vida y tus
  ajustes (idioma, tema, recordatorios, widget)
- las personas que añades: nombre, cumpleaños (con o sin año), grupos y, de
  forma opcional, una foto, un mensaje, la frecuencia con la que os veis y su
  esperanza de vida. De las personas importadas, la app guarda además su
  origen (contactos o vCard) y el identificador del contacto allí, para que
  una importación posterior solo muestre cumpleaños nuevos o cambiados.
- tus entradas de la Brújula y las preguntas semanales
- de la estimación de la esperanza de vida, solo el resultado: los años (para
  ti también la media y el rango). Las respuestas - país, sexo, altura y
  peso, tabaco, actividad, alcohol, vida social y las respuestas de salud
  opcionales como las enfermedades crónicas - solo se usan para el cálculo y
  nunca se guardan: ni en el dispositivo, ni en las copias de seguridad, ni
  en las exportaciones. Esto vale también para las estimaciones de otras
  personas.

### Cómo se protegen tus datos

- **Cifrados en el dispositivo**: tu nombre, tu fecha de nacimiento, tu
  esperanza de vida, el resultado de la estimación, tus personas, tus
  entradas de la Brújula, el estado de la sincronización del calendario y de
  los recordatorios, y las fotos de tus personas se guardan cifrados con
  AES-256-GCM. La clave de 256 bits la guarda el almacén de claves del
  sistema (Android Keystore, llavero del iPhone), disponible tras el primer
  desbloqueo y sin sincronizar con tus otros dispositivos. Solo una copia de
  seguridad puede llevarla, junto con los datos: en el iPhone viaja con las
  copias de iCloud y las copias cifradas en el ordenador (ver «Copias de
  seguridad y exportación»). Los ajustes no
  personales (tema, idioma e interruptores similares) se guardan sin cifrar.
- **Lo que sigue siendo legible**, porque el sistema o las partes nativas de
  la app lo necesitan:
  - los datos del widget y del reloj: fecha de nacimiento, esperanza de vida
    y ajustes de visualización
  - la lista de notificaciones programadas, que guarda la biblioteca de
    notificaciones para que los recordatorios lleguen también después de un
    reinicio; contiene sus textos, nombres incluidos
  - los eventos del calendario, si activas la sincronización de cumpleaños
- Si los datos cifrados llegan a un dispositivo sin su clave (por ejemplo,
  tras restaurar una copia sin cifrar del ordenador en un iPhone), la app
  indica que los datos están bloqueados y ofrece "Intentar de nuevo" o
  "Empezar de cero". No se borra nada automáticamente.

### Internet

Las versiones de lanzamiento para Android no tienen el permiso de internet,
así que la app no puede enviar nada a ningún sitio. La app no contiene código
de red en ninguna plataforma.

### Permisos

- **Notificaciones**: recordatorios de cumpleaños y la pregunta semanal
  opcional. Se programan en el dispositivo.
- **Calendario** (opcional): solo si activas la sincronización de
  cumpleaños. La app escribe entonces los cumpleaños de tus personas en el
  calendario que elijas. Si ese calendario se sincroniza con una cuenta en
  línea, el proveedor de la cuenta verá esos eventos.
- **Ejecutar al iniciar** (`RECEIVE_BOOT_COMPLETED`): para volver a programar
  los recordatorios y la actualización de medianoche del widget de la pantalla
  de inicio después de un reinicio.
- **Contactos** (opcional, solo lectura): solo cuando importas cumpleaños de
  tus contactos. La app lee nombres, cumpleaños y, si quieres, fotos de los
  contactos, solo en el dispositivo. Solo se guardan las personas que
  seleccionas; no se conserva nada más de tu agenda y no se escribe nada en
  ella. La importación es única: la app no lee tus contactos en segundo plano.
  Puedes retirar el permiso en cualquier momento en los ajustes del sistema;
  las personas que ya importaste se quedan en la app.
  - En Android 17 y versiones posteriores, «Elegir contactos» usa el selector
    de contactos del sistema y no necesita ningún permiso: la app solo recibe
    los contactos que eliges. Solo «Buscar en todos los contactos con
    cumpleaños» pide el permiso de contactos.
  - En el iPhone puedes compartir todos los contactos o solo algunos.
- **Archivo vCard** (opcional): importar un archivo .vcf no necesita ningún
  permiso. La app lee solo el archivo que eliges, en el dispositivo.
- **Fotos / cámara**: solo cuando eliges una foto para una persona. La app
  recibe solo la imagen que eliges y guarda una copia en el dispositivo.
- **Vibración, mantener activo (wake lock), estado de la red**: los añaden las
  bibliotecas de notificaciones y del widget (Android); la app no envía datos.

### Copias de seguridad y exportación

- **Copia de seguridad de Android y transferencia entre dispositivos**: los
  datos de la app solo se copian en la nube cuando la copia está cifrada de
  extremo a extremo (si no, Android los omite); también funciona una
  transferencia directa a un móvil nuevo. La clave de los datos solo va en
  una copia así, cifrada de extremo a extremo, o en la transferencia de
  dispositivo a dispositivo.
- **iPhone**: la clave viaja con las copias de iCloud y las copias cifradas
  en el ordenador. Sin la Protección de datos avanzada, Apple puede acceder
  técnicamente a las copias de iCloud, que contienen los datos y la clave.
  Una copia sin cifrar en el ordenador restaura los datos sin su clave, así
  que siguen bloqueados (ver arriba).
- Las copias hechas antes de esta versión pueden seguir conteniendo datos
  sin cifrar hasta que otras más recientes las sustituyan.
- **Exportar / importar** (Ajustes > Datos): crea un archivo con tus personas
  (incluida su esperanza de vida), sus fotos y tus entradas de la Brújula.
  Nunca contiene respuestas de la estimación. Por defecto es un archivo JSON
  legible; también puedes protegerlo con una contraseña (PBKDF2-HMAC-SHA256
  con 600.000 iteraciones y AES-256-GCM). Sin la contraseña, nadie puede
  restaurar una exportación protegida. Tú decides adónde va el archivo; la
  app nunca lo sube.

### Relojes

- **Wear OS** (solo la versión de Google Play): tu fecha de nacimiento, tu
  esperanza de vida y los ajustes de visualización y de color se envían de tu
  móvil a tu reloj a través del Wear OS Data Layer, de dispositivo a
  dispositivo. Las personas nunca se envían. La versión de F-Droid / APK no
  contiene los servicios de Google Play ni sincronización con el reloj.
- **Apple Watch**: los mismos valores pasan del iPhone al reloj a través de
  WatchConnectivity de Apple.

### Enlaces

Algunos botones abren una página en tu navegador o en tu tienda de
aplicaciones; a partir de ahí se aplica la política de privacidad de ese sitio:

- GitHub: código fuente, ideas y comentarios, esta página
- Buy Me a Coffee: solo en la versión de F-Droid / APK
- Google Play / App Store: «Valorar la app» en las versiones de las tiendas

Compartir (una cita, una persona, una recomendación, una copia de seguridad)
usa el menú para compartir de tu sistema y solo llega adonde lo envías.

### Contacto

Preguntas o inquietudes:
https://github.com/LifeTreeCoach/memento-mori/discussions
