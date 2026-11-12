# Privacy

Effective date: 2026-11-08

Deutsche Fassung: [weiter unten](#datenschutz).
Version française : [plus bas](#confidentialité).
Versión en español: [más abajo](#privacidad).

## English

Memento Mori - Life in Weeks keeps everything on your device. There is no
account, no analytics or tracking, no ads and no server of ours.

### What the app stores

On your device only:

- your birth date, life expectancy and settings (language, theme, reminders,
  widget)
- the people you add: name, birthday (with or without year), groups, an
  optional photo, message and meeting frequency. People you import also keep
  where they came from (contacts or vCard) and the contact's id there, so a
  later import only shows new or changed birthdays.
- your Compass entries and weekly questions
- the answers to the lifespan estimate: country, sex and the lifestyle answers.
  For weight only the BMI band is saved; the height and weight you type in are
  never stored.
- optional health answers for the lifespan estimate: the chronic conditions
  you tick (for example diabetes or a past heart attack), or that you ticked
  none. They stay on the device and are never sent anywhere. They are part of
  the device's own backups (Android Auto Backup, iCloud or computer backup),
  but not of the JSON export. You can remove them at any time by opening the
  estimate again, skipping that question (or unticking everything) and
  applying the estimate, or by deleting the app's data or the app.
  If you enter such information about other people, please only do so with
  their consent.

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

- **Android Auto Backup** is on. If you have it enabled in your phone's
  settings, Android backs up the app's data (settings incl. the lifespan
  answers, people, Compass, photos) to your Google account and restores it on a new phone. On iPhone,
  the app's data is part of your normal iCloud or computer backup.
- **Export / import** (Settings > Data): creates a JSON file with your people,
  their photos and your Compass entries (not your lifespan answers). You decide where it goes; the app
  never uploads it.

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

Gültig ab: 2026-11-08

Memento Mori speichert alles auf deinem Gerät. Es gibt kein
Konto, keine Analyse oder Tracking, keine Werbung und keinen eigenen Server.

### Was die App speichert

Nur auf deinem Gerät:

- dein Geburtsdatum, deine Lebenserwartung und Einstellungen (Sprache, Design,
  Erinnerungen, Widget)
- die Personen, die du hinzufügst: Name, Geburtstag (mit oder ohne Jahr),
  Gruppen, optional ein Foto, eine Nachricht und wie oft ihr euch seht. Bei
  importierten Personen merkt sich die App außerdem die Herkunft (Kontakte
  oder vCard) und die Kontakt-ID dort, damit ein späterer Import nur neue
  oder geänderte Geburtstage zeigt.
- deine Kompass-Einträge und Wochenfragen
- die Antworten zur Lebenserwartungs-Schätzung: Land, Geschlecht und die
  Lebensstil-Antworten. Beim Gewicht wird nur der BMI-Bereich gespeichert;
  Größe und Gewicht, die du eintippst, werden nie gespeichert.
- optionale Gesundheitsangaben für die Lebenserwartungs-Schätzung: die
  chronischen Erkrankungen, die du ankreuzt (zum Beispiel Diabetes oder ein
  früherer Herzinfarkt), oder dass du keine angekreuzt hast. Sie bleiben auf
  dem Gerät und werden nirgendwohin gesendet. Sie sind Teil der Sicherungen
  deines Geräts (Android Auto Backup, iCloud- oder Computer-Sicherung), aber
  nicht des JSON-Exports. Du kannst sie jederzeit entfernen: Schätzung erneut
  öffnen, die Frage überspringen (oder alle Häkchen entfernen) und die
  Schätzung übernehmen, oder die App-Daten bzw. die App löschen.
  Wenn du solche Angaben über andere Menschen machst, tu das bitte nur mit
  ihrer Einwilligung.

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

- **Android Auto Backup** ist eingeschaltet. Wenn du es in den Einstellungen
  deines Handys aktiviert hast, sichert Android die Daten der App
  (Einstellungen samt Antworten zur Lebenserwartung, Personen, Kompass,
  Fotos) in deinem Google-Konto und stellt
  sie auf einem neuen Handy wieder her. Auf dem iPhone sind die Daten Teil
  deiner normalen iCloud- oder Computer-Sicherung.
- **Export / Import** (Einstellungen > Daten): erstellt eine JSON-Datei mit
  deinen Personen, ihren Fotos und deinen Kompass-Einträgen (nicht deinen
  Antworten zur Lebenserwartung). Du entscheidest,
  wo sie landet; die App lädt sie nirgends hoch.

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

En vigueur depuis le : 2026-11-08

Memento Mori - Life in Weeks garde tout sur ton appareil. Il n’y a ni
compte, ni analyse ou suivi, ni publicité, ni serveur à nous.

### Ce que l’app enregistre

Uniquement sur ton appareil :

- ta date de naissance, ton espérance de vie et tes réglages (langue, thème,
  rappels, widget)
- les personnes que tu ajoutes : nom, anniversaire (avec ou sans année),
  groupes, et en option une photo, un message et la fréquence de vos
  rencontres. Pour les personnes importées, l’app retient aussi leur provenance
  (contacts ou vCard) et l’identifiant du contact là-bas, pour qu’une
  importation ultérieure n’affiche que les anniversaires nouveaux ou modifiés.
- tes entrées de la Boussole et les questions de la semaine
- les réponses à l’estimation de l’espérance de vie : pays, sexe et réponses
  sur le mode de vie. Pour le poids, seule la tranche d’IMC est enregistrée ;
  la taille et le poids que tu saisis ne sont jamais enregistrés.
- des réponses de santé facultatives pour l’estimation de l’espérance de vie :
  les maladies chroniques que tu coches (par exemple le diabète ou un ancien
  infarctus), ou le fait que tu n’en as coché aucune. Elles restent sur
  l’appareil et ne sont jamais envoyées nulle part. Elles font partie des
  sauvegardes de l’appareil (Android Auto Backup, iCloud ou sauvegarde sur
  ordinateur), mais pas de l’export JSON. Tu peux les supprimer à tout moment
  en rouvrant l’estimation, en passant cette question (ou en décochant tout)
  et en appliquant l’estimation, ou en supprimant les données de l’app ou
  l’app elle-même.
  Si tu saisis de telles informations sur d’autres personnes, fais-le
  uniquement avec leur consentement.

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

- **Android Auto Backup** est activé. Si tu l’as activé dans les réglages de
  ton téléphone, Android sauvegarde les données de l’app (réglages, y compris
  les réponses sur l’espérance de vie, personnes, Boussole, photos) dans ton
  compte Google et les restaure sur un nouveau téléphone. Sur iPhone, les
  données de l’app font partie de ta sauvegarde iCloud ou sur ordinateur
  habituelle.
- **Export / import** (Réglages > Données) : crée un fichier JSON avec tes
  personnes, leurs photos et tes entrées de la Boussole (pas tes réponses sur
  l’espérance de vie). C’est toi qui décides où il va ; l’app ne le
  téléverse jamais.

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

En vigor desde: 2026-11-08

Memento Mori - Life in Weeks guarda todo en tu dispositivo. No hay cuenta,
ni analíticas o seguimiento, ni anuncios, ni servidor propio.

### Qué guarda la app

Solo en tu dispositivo:

- tu fecha de nacimiento, tu esperanza de vida y tus ajustes (idioma, tema,
  recordatorios, widget)
- las personas que añades: nombre, cumpleaños (con o sin año), grupos y, de
  forma opcional, una foto, un mensaje y la frecuencia con la que os veis. De
  las personas importadas, la app guarda además su origen (contactos o vCard)
  y el identificador del contacto allí, para que una importación posterior
  solo muestre cumpleaños nuevos o cambiados.
- tus entradas de la Brújula y las preguntas semanales
- las respuestas de la estimación de la esperanza de vida: país, sexo y las
  respuestas sobre el estilo de vida. Del peso solo se guarda la franja de
  IMC; la altura y el peso que escribes nunca se guardan.
- respuestas de salud opcionales para la estimación de la esperanza de vida:
  las enfermedades crónicas que marcas (por ejemplo, diabetes o un infarto
  anterior), o que no marcaste ninguna. Se quedan en el dispositivo y nunca se
  envían a ningún sitio. Forman parte de las copias de seguridad del propio
  dispositivo (Android Auto Backup, iCloud o copia en el ordenador), pero no
  de la exportación JSON. Puedes eliminarlas en cualquier momento abriendo de
  nuevo la estimación, saltando esa pregunta (o desmarcándolo todo) y
  aplicando la estimación, o borrando los datos de la app o la app.
  Si introduces este tipo de información sobre otras personas, hazlo solo con
  su consentimiento.

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

- **Android Auto Backup** está activado. Si lo tienes activado en los ajustes
  de tu móvil, Android hace una copia de seguridad de los datos de la app
  (ajustes, incluidas las respuestas sobre la esperanza de vida, personas,
  Brújula, fotos) en tu cuenta de Google y los restaura en un móvil nuevo. En
  el iPhone, los datos de la app forman parte de tu copia de seguridad
  habitual de iCloud o del ordenador.
- **Exportar / importar** (Ajustes > Datos): crea un archivo JSON con tus
  personas, sus fotos y tus entradas de la Brújula (no tus respuestas sobre la
  esperanza de vida). Tú decides adónde va; la app nunca lo sube.

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
