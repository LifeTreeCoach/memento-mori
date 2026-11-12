/// Strings of product tours (coach marks, `lib/tour/`): the generic
/// buttons, each tour's titles and bodies (`tour_<tour>_<step>_*`) and the
/// "Show tips again" entries; spread into AppLocalizations.
///
/// French puts U+00A0 before `: ; ? ! %`; Spanish opens questions with `¿`.
const Map<String, String> tourStringsEn = {
  'tour_skip': 'Skip',
  'tour_next': 'Next',
  'tour_done': 'Done',
  'tour_step_counter': 'Tip {i} of {n}',
  'tour_compass_help': 'How Compass works',
  'tour_compass_show_me': 'Show me',
  'tour_compass_not_now': 'Not now',
  'tour_compass_phase_title': 'What is a phase?',
  'tour_compass_phase_body': 'A phase is a stretch of life with its own '
      'focus – studying, a new job, a child, a fresh start. Compass always '
      'looks at the phase you’re in now.',
  'tour_compass_header_title': 'Your phase',
  'tour_compass_header_body': 'Tap here to see how long you’ve been in '
      'this phase, what you’ve done so far – and to close it when it ends.',
  'tour_compass_question_title': 'Question of the week',
  'tour_compass_question_body':
      'One question a week. Answer it – or simply let it sit with you.',
  'tour_compass_now_title': 'Now',
  'tour_compass_now_body': '“Now” holds up to three intentions for this '
      'phase. Few on purpose, so they stay real.',
  'tour_compass_someday_title': 'Someday & Lived',
  'tour_compass_someday_body': '“Someday” keeps what can wait. “Lived” '
      'collects what you did – moments worth remembering.',
  'tour_people_help': 'How People works',
  'tour_people_add_title': 'Your people',
  'tour_people_add_body': 'Add the people who matter to you.',
  'tour_people_import_title': 'Birthdays you already have',
  'tour_people_import_body': 'Or bring in birthdays from your contacts or a '
      'vCard file – it all stays on this device.',
  'tour_people_menu_title': 'More options',
  'tour_people_menu_body':
      'Sort, filter, import & export and calendar sync live here.',
  'tour_people_reminders_title': 'Birthday reminders',
  'tour_people_reminders_body':
      'Gentle birthday reminders – switch them on or off here.',
  'tour_people_groups_title': 'Groups',
  'tour_people_groups_body':
      'Show just one group – family, friends or your own.',
  'tour_people_person_title': 'A life in weeks',
  'tour_people_person_body': 'Tap someone to see their life in weeks – and '
      'under “Together”, the time you likely still share.',
  'tour_people_fab_title': 'Add someone',
  'tour_people_fab_body': 'Add someone anytime.',
  'tour_person_form_estimate_title': 'Know more, guess better',
  'tour_person_form_estimate_body': 'The more you know about this person, '
      'the more realistic their estimate gets – a few optional questions, '
      'an average, not a forecast.',
  'tour_person_form_estimate_now': 'Estimate now',
  'tour_person_form_later': 'Later',
  'tour_show_again': 'Show hints again',
  'tour_show_again_sub':
      'The short tours in Compass and People and the hint when adding someone',
  'tour_show_again_done': 'Hints will show again',
  'diagnostics_tours_reset': 'Reset tours',
  'diagnostics_tours_reset_sub':
      'Every product tour shows again on its next visit',
  'diagnostics_tours_reset_done': 'Tours reset',
};

const Map<String, String> tourStringsDe = {
  'tour_skip': 'Überspringen',
  'tour_next': 'Weiter',
  'tour_done': 'Fertig',
  'tour_step_counter': 'Tipp {i} von {n}',
  'tour_compass_help': 'So funktioniert der Kompass',
  'tour_compass_show_me': 'Zeig’s mir',
  'tour_compass_not_now': 'Jetzt nicht',
  'tour_compass_phase_title': 'Was ist eine Phase?',
  'tour_compass_phase_body': 'Eine Phase ist ein Lebensabschnitt mit '
      'eigenem Schwerpunkt – Studium, ein neuer Job, ein Kind, ein '
      'Neuanfang. Der Kompass schaut immer auf die Phase, in der du gerade '
      'bist.',
  'tour_compass_header_title': 'Deine Phase',
  'tour_compass_header_body': 'Tippe hier, um zu sehen, wie lange du '
      'schon in dieser Phase bist, was du bisher getan hast – und um sie '
      'abzuschließen, wenn sie endet.',
  'tour_compass_question_title': 'Frage der Woche',
  'tour_compass_question_body':
      'Eine Frage pro Woche. Beantworte sie – oder lass sie einfach wirken.',
  'tour_compass_now_title': 'Jetzt',
  'tour_compass_now_body': 'Unter „Jetzt“ stehen bis zu drei Vorhaben für '
      'diese Phase. Bewusst wenige, damit sie echt bleiben.',
  'tour_compass_someday_title': 'Irgendwann & Gelebt',
  'tour_compass_someday_body': '„Irgendwann“ hält fest, was warten kann. '
      '„Gelebt“ sammelt, was du getan hast – Momente, die bleiben.',
  'tour_people_help': 'So funktioniert „Menschen“',
  'tour_people_add_title': 'Deine Menschen',
  'tour_people_add_body': 'Füge die Menschen hinzu, die dir wichtig sind.',
  'tour_people_import_title': 'Geburtstage übernehmen',
  'tour_people_import_body': 'Oder übernimm Geburtstage aus deinen Kontakten '
      'oder einer vCard-Datei – alles bleibt auf diesem Gerät.',
  'tour_people_menu_title': 'Weitere Optionen',
  'tour_people_menu_body': 'Hier findest du Sortieren, Filtern, Import & '
      'Export und den Kalender-Abgleich.',
  'tour_people_reminders_title': 'Geburtstagserinnerungen',
  'tour_people_reminders_body':
      'Sanfte Geburtstagserinnerungen schaltest du hier ein oder aus.',
  'tour_people_groups_title': 'Gruppen',
  'tour_people_groups_body':
      'Zeig nur eine Gruppe – Familie, Freunde oder eigene.',
  'tour_people_person_title': 'Ein Leben in Wochen',
  'tour_people_person_body': 'Tippe auf jemanden, um das Leben dieser Person '
      'in Wochen zu sehen – und unter „Gemeinsam“ die Zeit, die ihr '
      'wahrscheinlich noch teilt.',
  'tour_people_fab_title': 'Jemanden hinzufügen',
  'tour_people_fab_body': 'Füge jederzeit jemanden hinzu.',
  'tour_person_form_estimate_title': 'Mehr wissen, besser schätzen',
  'tour_person_form_estimate_body': 'Je mehr du über diese Person weißt, '
      'desto realistischer wird ihre Schätzung – ein paar freiwillige '
      'Fragen, ein Durchschnitt, keine Vorhersage.',
  'tour_person_form_estimate_now': 'Jetzt schätzen',
  'tour_person_form_later': 'Später',
  'tour_show_again': 'Tipps erneut zeigen',
  'tour_show_again_sub':
      'Die kurzen Rundgänge in Kompass und Menschen und der Tipp beim '
      'Hinzufügen einer Person',
  'tour_show_again_done': 'Die Tipps erscheinen wieder',
  'diagnostics_tours_reset': 'Rundgänge zurücksetzen',
  'diagnostics_tours_reset_sub':
      'Jeder Rundgang erscheint beim nächsten Besuch erneut',
  'diagnostics_tours_reset_done': 'Rundgänge zurückgesetzt',
};

const Map<String, String> tourStringsFr = {
  'tour_skip': 'Passer',
  'tour_next': 'Suivant',
  'tour_done': 'Terminé',
  'tour_step_counter': 'Astuce {i} sur {n}',
  'tour_compass_help': 'Comment fonctionne la Boussole',
  'tour_compass_show_me': 'Montre-moi',
  'tour_compass_not_now': 'Pas maintenant',
  'tour_compass_phase_title': 'Qu’est-ce qu’une phase ?',
  'tour_compass_phase_body': 'Une phase est une période de la vie avec son '
      'propre centre – des études, un nouveau travail, un enfant, un nouveau '
      'départ. La Boussole regarde toujours la phase où tu es maintenant.',
  'tour_compass_header_title': 'Ta phase',
  'tour_compass_header_body': 'Touche ici pour voir depuis combien de '
      'temps tu es dans cette phase, ce que tu as fait jusqu’ici – et pour la clore '
      'quand elle se termine.',
  'tour_compass_question_title': 'Question de la semaine',
  'tour_compass_question_body': 'Une question par semaine. Réponds-y – ou '
      'laisse-la simplement faire son chemin.',
  'tour_compass_now_title': 'Maintenant',
  'tour_compass_now_body': '« Maintenant » accueille jusqu’à trois '
      'intentions pour cette phase. Peu, exprès, pour qu’elles restent '
      'vraies.',
  'tour_compass_someday_title': 'Un jour & Vécu',
  'tour_compass_someday_body': '« Un jour » garde ce qui peut attendre. '
      '« Vécu » rassemble ce que tu as fait – des moments qui restent.',
  'tour_people_help': 'Comment fonctionnent les Proches',
  'tour_people_add_title': 'Tes proches',
  'tour_people_add_body': 'Ajoute les personnes qui comptent pour toi.',
  'tour_people_import_title': 'Des anniversaires déjà notés',
  'tour_people_import_body': 'Ou reprends les anniversaires de tes contacts '
      'ou d’un fichier vCard – tout reste sur cet appareil.',
  'tour_people_menu_title': 'Plus d’options',
  'tour_people_menu_body': 'Le tri, les filtres, l’import et l’export et la '
      'synchro agenda se trouvent ici.',
  'tour_people_reminders_title': 'Rappels d’anniversaire',
  'tour_people_reminders_body': 'De doux rappels d’anniversaire – active-les '
      'ou désactive-les ici.',
  'tour_people_groups_title': 'Groupes',
  'tour_people_groups_body':
      'Affiche un seul groupe – famille, amis ou les tiens.',
  'tour_people_person_title': 'Une vie en semaines',
  'tour_people_person_body': 'Touche une personne pour voir sa vie en '
      'semaines – et, sous « Ensemble », le temps que vous '
      'partagerez sans doute encore.',
  'tour_people_fab_title': 'Ajouter quelqu’un',
  'tour_people_fab_body': 'Ajoute quelqu’un à tout moment.',
  'tour_person_form_estimate_title': 'En savoir plus, estimer mieux',
  'tour_person_form_estimate_body': 'Plus tu en sais sur cette personne, '
      'plus son estimation devient réaliste – quelques questions '
      'facultatives, une moyenne, pas une prédiction.',
  'tour_person_form_estimate_now': 'Estimer maintenant',
  'tour_person_form_later': 'Plus tard',
  'tour_show_again': 'Revoir les astuces',
  'tour_show_again_sub':
      'Les courtes visites de la Boussole et des Proches, et l’astuce '
      'à l’ajout d’une personne',
  'tour_show_again_done': 'Les astuces s’afficheront à nouveau',
  'diagnostics_tours_reset': 'Réinitialiser les visites',
  'diagnostics_tours_reset_sub':
      'Chaque visite guidée réapparaît à la prochaine ouverture',
  'diagnostics_tours_reset_done': 'Visites réinitialisées',
};

const Map<String, String> tourStringsEs = {
  'tour_skip': 'Omitir',
  'tour_next': 'Siguiente',
  'tour_done': 'Listo',
  'tour_step_counter': 'Consejo {i} de {n}',
  'tour_compass_help': 'Cómo funciona la Brújula',
  'tour_compass_show_me': 'Muéstramelo',
  'tour_compass_not_now': 'Ahora no',
  'tour_compass_phase_title': '¿Qué es una etapa?',
  'tour_compass_phase_body': 'Una etapa es un tramo de la vida con su '
      'propio foco: los estudios, un trabajo nuevo, un hijo, un nuevo '
      'comienzo. La Brújula siempre mira la etapa en la que estás ahora.',
  'tour_compass_header_title': 'Tu etapa',
  'tour_compass_header_body': 'Toca aquí para ver cuánto llevas en esta '
      'etapa, lo que has hecho hasta ahora – y para cerrarla cuando termine.',
  'tour_compass_question_title': 'Pregunta de la semana',
  'tour_compass_question_body': 'Una pregunta por semana. Respóndela – o '
      'simplemente deja que te acompañe.',
  'tour_compass_now_title': 'Ahora',
  'tour_compass_now_body': '«Ahora» guarda hasta tres intenciones para esta '
      'etapa. Pocas a propósito, para que sigan siendo reales.',
  'tour_compass_someday_title': 'Algún día y Vivido',
  'tour_compass_someday_body': '«Algún día» guarda lo que puede esperar. '
      '«Vivido» reúne lo que hiciste: momentos que merece la pena recordar.',
  'tour_people_help': 'Cómo funciona Personas',
  'tour_people_add_title': 'Tu gente',
  'tour_people_add_body': 'Añade a las personas que te importan.',
  'tour_people_import_title': 'Cumpleaños que ya tienes',
  'tour_people_import_body': 'O trae los cumpleaños de tus contactos o de un '
      'archivo vCard: todo se queda en este dispositivo.',
  'tour_people_menu_title': 'Más opciones',
  'tour_people_menu_body': 'Aquí encuentras ordenar, filtrar, importar y '
      'exportar, y sincronizar el calendario.',
  'tour_people_reminders_title': 'Recordatorios de cumpleaños',
  'tour_people_reminders_body': 'Recordatorios de cumpleaños suaves: '
      'actívalos o desactívalos aquí.',
  'tour_people_groups_title': 'Grupos',
  'tour_people_groups_body':
      'Muestra solo un grupo: familia, amigos o uno tuyo.',
  'tour_people_person_title': 'Una vida en semanas',
  'tour_people_person_body': 'Toca a alguien para ver su vida en semanas y, '
      'en «Juntos», el tiempo que probablemente aún compartís.',
  'tour_people_fab_title': 'Añadir a alguien',
  'tour_people_fab_body': 'Añade a alguien cuando quieras.',
  'tour_person_form_estimate_title': 'Saber más, estimar mejor',
  'tour_person_form_estimate_body': 'Cuanto más sepas de esta persona, más '
      'realista será su estimación: unas preguntas opcionales, un promedio, '
      'no un pronóstico.',
  'tour_person_form_estimate_now': 'Estimar ahora',
  'tour_person_form_later': 'Más tarde',
  'tour_show_again': 'Volver a mostrar los consejos',
  'tour_show_again_sub':
      'Los breves recorridos de la Brújula y Personas, y el consejo al '
      'añadir a alguien',
  'tour_show_again_done': 'Los consejos se mostrarán de nuevo',
  'diagnostics_tours_reset': 'Restablecer recorridos',
  'diagnostics_tours_reset_sub':
      'Cada recorrido vuelve a aparecer en la próxima visita',
  'diagnostics_tours_reset_done': 'Recorridos restablecidos',
};
