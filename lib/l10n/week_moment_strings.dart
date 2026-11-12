/// Strings of the weekly moment (a calm look at the week that passed, after
/// the Sunday Compass reminder), its setting and diagnostics; spread into
/// AppLocalizations.
///
/// Tone: warm and personal, never a countdown, pressure or guilt; it lets
/// the user feel that a week passed and invites them to enjoy life and make
/// room for what matters. Informal address (du / tu / tú); Spanish says
/// "etapa" for a phase. The name appears once per moment: only
/// `week_moment_close_title` has a `_named` twin (see `PersonalAddress`)
/// with `{name}`. The final act has two steps (`week_moment_close_*`: close
/// the week that passed, `week_moment_plan_*`: plan the next one); `{week}`
/// in their eyebrows is the ISO calendar week, `{step}` / `{total}` the
/// step counter. French puts U+00A0 before `: ; ? ! %` and uses `’`;
/// Spanish opens questions with `¿`; numbers stay joined to their units
/// with U+00A0, and a dash " – " or dot " · " keeps U+00A0 before it so it
/// never starts a line. `{ordinal}` is `yearOrdinal`
/// (`lib/week_moment/ordinal.dart`), `{week}`, `{n}` and `{total}` grouped
/// numbers.
const Map<String, String> weekMomentStringsEn = {
  'week_moment_eyebrow_week': 'This week',
  'week_moment_eyebrow_phase': 'Your phase',
  'week_moment_eyebrow_life': 'Your life',
  'week_moment_passed_one': 'Another week has passed.',
  'week_moment_passed_other': 'Another {n}\u00A0weeks have passed.',
  'week_moment_year_left_one':
      'In your {ordinal}\u00A0year of life, {n}\u00A0week remains.',
  'week_moment_year_left_other':
      'In your {ordinal}\u00A0year of life, {n}\u00A0weeks remain.',
  'week_moment_year_days_one':
      'Your {ordinal}\u00A0year of life begins in {n}\u00A0day.',
  'week_moment_year_days_other':
      'Your {ordinal}\u00A0year of life begins in {n}\u00A0days.',
  'week_moment_year_begun':
      'A new year of life has just begun\u00A0– your {ordinal}.',
  'week_moment_phase_week': 'Week\u00A0{week} of your phase “{phase}”.',
  'week_moment_phase_left_one': '{n}\u00A0more planned week lies ahead.',
  'week_moment_phase_left_other': '{n}\u00A0more planned weeks lie ahead.',
  'week_moment_phase_open': 'It has room for as long as it needs.',
  'week_moment_life_one': 'Of about {total}\u00A0weeks, about {n}\u00A0still lies ahead of you\u00A0– room for what matters.',
  'week_moment_life_other': 'Of about {total}\u00A0weeks, about {n}\u00A0still lie ahead of you\u00A0– room for what matters.',
  'week_moment_life_beyond': 'Every week from here on is a gift.',
  'week_moment_close_eyebrow': 'Week\u00A0{week}\u00A0· complete',
  'week_moment_close_title': 'The week is over.',
  'week_moment_close_title_named': '{name}, the week is over.',
  'week_moment_close_body': 'What was beautiful about it? Hold on to it for a moment\u00A0– in your thoughts or in a sentence.',
  'week_moment_close_label': 'Write it down\u00A0– only if you like',
  'week_moment_close_hint': 'e.g. A long walk on Sunday, finally a clear head again.',
  'week_moment_close_primary': 'Close the week',
  'week_moment_close_secondary': 'Kept in my thoughts',
  'week_moment_plan_eyebrow': 'Week\u00A0{week}',
  'week_moment_plan_eyebrow_phase_one': 'Week\u00A0{week}\u00A0· {n} more in this phase',
  'week_moment_plan_eyebrow_phase_other': 'Week\u00A0{week}\u00A0· {n} more in this phase',
  'week_moment_plan_eyebrow_year_one': 'Week\u00A0{week}\u00A0· {n} more in this year of life',
  'week_moment_plan_eyebrow_year_other': 'Week\u00A0{week}\u00A0· {n} more in this year of life',
  'week_moment_plan_title': 'The new week is yours.',
  'week_moment_plan_body': 'What should it make room for?',
  'week_moment_plan_label': 'One thing that counts this week',
  'week_moment_plan_hint': 'e.g. Call a friend again.',
  'week_moment_plan_primary': 'Plan the week',
  'week_moment_plan_secondary': 'Enjoy life',
  'week_moment_step_counter': '{step} of {total}',
  'week_moment_skip': 'Skip',
  'week_moment_tap_hint': 'continue',
  'week_moment_stage_label': 'Your life in weeks',
  'week_moment_replay': 'See your week',
  'compass_setting_week_moment': 'Weekly moment',
  'compass_setting_week_moment_sub':
      'A calm look at the week that passed, after the Sunday reminder',
  'diagnostics_week_moment': 'Show weekly moment now',
  'diagnostics_week_moment_sub': 'Plays it as after the Sunday reminder',
  'diagnostics_week_moment_reset': 'Reset weekly moment',
  'diagnostics_week_moment_reset_sub': 'Shows it again after the next reminder',
  'diagnostics_week_moment_reset_done': 'Weekly moment reset',
};

const Map<String, String> weekMomentStringsDe = {
  'week_moment_eyebrow_week': 'Diese Woche',
  'week_moment_eyebrow_phase': 'Deine Phase',
  'week_moment_eyebrow_life': 'Dein Leben',
  'week_moment_passed_one': 'Wieder ist eine Woche vergangen.',
  'week_moment_passed_other': 'Wieder sind {n}\u00A0Wochen vergangen.',
  'week_moment_year_left_one':
      'In deinem {ordinal}\u00A0Lebensjahr bleibt noch {n}\u00A0Woche.',
  'week_moment_year_left_other':
      'In deinem {ordinal}\u00A0Lebensjahr bleiben noch {n}\u00A0Wochen.',
  'week_moment_year_days_one':
      'Dein {ordinal}\u00A0Lebensjahr beginnt in {n}\u00A0Tag.',
  'week_moment_year_days_other':
      'Dein {ordinal}\u00A0Lebensjahr beginnt in {n}\u00A0Tagen.',
  // No final period: the ordinal ("37.") already ends the sentence.
  'week_moment_year_begun':
      'Ein neues Lebensjahr hat gerade begonnen\u00A0– dein {ordinal}',
  'week_moment_phase_week': 'Woche\u00A0{week} deiner Phase „{phase}“.',
  'week_moment_phase_left_one': 'Geplant ist noch {n}\u00A0Woche.',
  'week_moment_phase_left_other': 'Geplant sind noch {n}\u00A0Wochen.',
  'week_moment_phase_open': 'Sie hat Raum, solange sie braucht.',
  'week_moment_life_one': 'Von etwa {total}\u00A0Wochen liegt etwa {n}\u00A0noch vor dir\u00A0– Raum für das, was zählt.',
  'week_moment_life_other': 'Von etwa {total}\u00A0Wochen liegen etwa {n}\u00A0noch vor dir\u00A0– Raum für das, was zählt.',
  'week_moment_life_beyond': 'Jede Woche von hier an ist ein Geschenk.',
  'week_moment_close_eyebrow': 'Woche\u00A0{week}\u00A0· abgeschlossen',
  'week_moment_close_title': 'Die Woche ist vorbei.',
  'week_moment_close_title_named': '{name}, die Woche ist vorbei.',
  'week_moment_close_body': 'Was war schön daran? Halte es kurz fest\u00A0– in Gedanken oder in einem Satz.',
  'week_moment_close_label': 'Aufschreiben\u00A0– nur wenn du magst',
  'week_moment_close_hint': 'z.\u00A0B. Ein langer Spaziergang am Sonntag, endlich wieder ein klarer Kopf.',
  'week_moment_close_primary': 'Woche abschließen',
  'week_moment_close_secondary': 'Nur in Gedanken festgehalten',
  'week_moment_plan_eyebrow': 'Woche\u00A0{week}',
  'week_moment_plan_eyebrow_phase_one': 'Woche\u00A0{week}\u00A0· noch {n} in dieser Phase',
  'week_moment_plan_eyebrow_phase_other': 'Woche\u00A0{week}\u00A0· noch {n} in dieser Phase',
  'week_moment_plan_eyebrow_year_one': 'Woche\u00A0{week}\u00A0· noch {n} in diesem Lebensjahr',
  'week_moment_plan_eyebrow_year_other': 'Woche\u00A0{week}\u00A0· noch {n} in diesem Lebensjahr',
  'week_moment_plan_title': 'Die neue Woche gehört dir.',
  'week_moment_plan_body': 'Wofür soll sie Platz haben?',
  'week_moment_plan_label': 'Eine Sache, die diese Woche zählt',
  'week_moment_plan_hint': 'z.\u00A0B. Endlich wieder eine Freundin anrufen.',
  'week_moment_plan_primary': 'Woche planen',
  'week_moment_plan_secondary': 'Leben genießen',
  'week_moment_step_counter': '{step} von {total}',
  'week_moment_skip': 'Überspringen',
  'week_moment_tap_hint': 'weiter',
  'week_moment_stage_label': 'Dein Leben in Wochen',
  'week_moment_replay': 'Deine Woche ansehen',
  'compass_setting_week_moment': 'Wochen-Moment',
  'compass_setting_week_moment_sub':
      'Ein ruhiger Blick auf die vergangene Woche, nach der Sonntagserinnerung',
  'diagnostics_week_moment': 'Wochen-Moment jetzt zeigen',
  'diagnostics_week_moment_sub':
      'Spielt ihn wie nach der Sonntagserinnerung ab',
  'diagnostics_week_moment_reset': 'Wochen-Moment zurücksetzen',
  'diagnostics_week_moment_reset_sub':
      'Zeigt ihn nach der nächsten Erinnerung wieder',
  'diagnostics_week_moment_reset_done': 'Wochen-Moment zurückgesetzt',
};

const Map<String, String> weekMomentStringsFr = {
  'week_moment_eyebrow_week': 'Cette semaine',
  'week_moment_eyebrow_phase': 'Ta phase',
  'week_moment_eyebrow_life': 'Ta vie',
  'week_moment_passed_one': 'Une semaine de plus vient de passer.',
  'week_moment_passed_other': '{n}\u00A0semaines de plus viennent de passer.',
  'week_moment_year_left_one':
      'Dans ta {ordinal}\u00A0année de vie, il reste {n}\u00A0semaine.',
  'week_moment_year_left_other':
      'Dans ta {ordinal}\u00A0année de vie, il reste {n}\u00A0semaines.',
  'week_moment_year_days_one':
      'Ta {ordinal}\u00A0année de vie commence dans {n}\u00A0jour.',
  'week_moment_year_days_other':
      'Ta {ordinal}\u00A0année de vie commence dans {n}\u00A0jours.',
  'week_moment_year_begun':
      'Une nouvelle année de vie vient de commencer\u00A0– ta {ordinal}.',
  'week_moment_phase_week':
      'Semaine\u00A0{week} de ta phase «\u00A0{phase}\u00A0».',
  'week_moment_phase_left_one': 'Encore {n}\u00A0semaine prévue devant toi.',
  'week_moment_phase_left_other':
      'Encore {n}\u00A0semaines prévues devant toi.',
  'week_moment_phase_open': 'Elle a tout le temps dont elle a besoin.',
  'week_moment_life_one': 'Sur environ {total}\u00A0semaines, environ {n}\u00A0est encore devant toi\u00A0– de la place pour ce qui compte.',
  'week_moment_life_other': 'Sur environ {total}\u00A0semaines, environ {n}\u00A0sont encore devant toi\u00A0– de la place pour ce qui compte.',
  'week_moment_life_beyond': 'Désormais, chaque semaine est un cadeau.',
  'week_moment_close_eyebrow': 'Semaine\u00A0{week}\u00A0· terminée',
  'week_moment_close_title': 'La semaine est finie.',
  'week_moment_close_title_named': '{name}, la semaine est finie.',
  'week_moment_close_body': 'Qu’est-ce qui a été beau\u00A0? Garde-le un instant\u00A0– en pensée ou en une phrase.',
  'week_moment_close_label': 'L’écrire\u00A0– seulement si tu veux',
  'week_moment_close_hint': 'p.\u00A0ex. Une longue balade dimanche, enfin l’esprit clair.',
  'week_moment_close_primary': 'Clore la semaine',
  'week_moment_close_secondary': 'Gardé en pensée',
  'week_moment_plan_eyebrow': 'Semaine\u00A0{week}',
  'week_moment_plan_eyebrow_phase_one': 'Semaine\u00A0{week}\u00A0· encore {n} dans cette phase',
  'week_moment_plan_eyebrow_phase_other': 'Semaine\u00A0{week}\u00A0· encore {n} dans cette phase',
  'week_moment_plan_eyebrow_year_one': 'Semaine\u00A0{week}\u00A0· encore {n} dans cette année de vie',
  'week_moment_plan_eyebrow_year_other': 'Semaine\u00A0{week}\u00A0· encore {n} dans cette année de vie',
  'week_moment_plan_title': 'La nouvelle semaine est à toi.',
  'week_moment_plan_body': 'À quoi veux-tu faire de la place\u00A0?',
  'week_moment_plan_label': 'Une chose qui compte cette semaine',
  'week_moment_plan_hint': 'p.\u00A0ex. Rappeler enfin une amie.',
  'week_moment_plan_primary': 'Planifier la semaine',
  'week_moment_plan_secondary': 'Profiter de la vie',
  'week_moment_step_counter': '{step} sur {total}',
  'week_moment_skip': 'Passer',
  'week_moment_tap_hint': 'continuer',
  'week_moment_stage_label': 'Ta vie en semaines',
  'week_moment_replay': 'Revoir ta semaine',
  'compass_setting_week_moment': 'Moment de la semaine',
  'compass_setting_week_moment_sub':
      'Un regard apaisé sur la semaine écoulée, après le rappel du dimanche',
  'diagnostics_week_moment': 'Afficher le moment de la semaine',
  'diagnostics_week_moment_sub': 'Le joue comme après le rappel du dimanche',
  'diagnostics_week_moment_reset': 'Réinitialiser le moment de la semaine',
  'diagnostics_week_moment_reset_sub':
      'Le montre à nouveau après le prochain rappel',
  'diagnostics_week_moment_reset_done': 'Moment de la semaine réinitialisé',
};

const Map<String, String> weekMomentStringsEs = {
  'week_moment_eyebrow_week': 'Esta semana',
  'week_moment_eyebrow_phase': 'Tu etapa',
  'week_moment_eyebrow_life': 'Tu vida',
  'week_moment_passed_one': 'Ha pasado otra semana.',
  'week_moment_passed_other': 'Han pasado otras {n}\u00A0semanas.',
  'week_moment_year_left_one':
      'En tu {ordinal}\u00A0año de vida te queda {n}\u00A0semana.',
  'week_moment_year_left_other':
      'En tu {ordinal}\u00A0año de vida te quedan {n}\u00A0semanas.',
  'week_moment_year_days_one':
      'Tu {ordinal}\u00A0año de vida empieza en {n}\u00A0día.',
  'week_moment_year_days_other':
      'Tu {ordinal}\u00A0año de vida empieza en {n}\u00A0días.',
  'week_moment_year_begun':
      'Acaba de empezar un nuevo año de vida\u00A0– tu {ordinal}.',
  'week_moment_phase_week': 'Semana\u00A0{week} de tu etapa «{phase}».',
  'week_moment_phase_left_one': 'Aún queda {n}\u00A0semana planeada.',
  'week_moment_phase_left_other': 'Aún quedan {n}\u00A0semanas planeadas.',
  'week_moment_phase_open': 'Tiene todo el tiempo que necesite.',
  'week_moment_life_one': 'De unas {total}\u00A0semanas, aún tienes por delante alrededor de {n}\u00A0– espacio para lo que importa.',
  'week_moment_life_other': 'De unas {total}\u00A0semanas, aún tienes por delante unas {n}\u00A0– espacio para lo que importa.',
  'week_moment_life_beyond': 'A partir de aquí, cada semana es un regalo.',
  'week_moment_close_eyebrow': 'Semana\u00A0{week}\u00A0· cerrada',
  'week_moment_close_title': 'La semana ha terminado.',
  'week_moment_close_title_named': '{name}, la semana ha terminado.',
  'week_moment_close_body': '¿Qué tuvo de bonito? Guárdalo un momento\u00A0– en tus pensamientos o en una frase.',
  'week_moment_close_label': 'Escríbelo\u00A0– solo si quieres',
  'week_moment_close_hint': 'p.\u00A0ej. Un paseo largo el domingo, por fin la cabeza despejada.',
  'week_moment_close_primary': 'Cerrar la semana',
  'week_moment_close_secondary': 'Guardado en mis pensamientos',
  'week_moment_plan_eyebrow': 'Semana\u00A0{week}',
  'week_moment_plan_eyebrow_phase_one': 'Semana\u00A0{week}\u00A0· queda {n} en esta etapa',
  'week_moment_plan_eyebrow_phase_other': 'Semana\u00A0{week}\u00A0· quedan {n} en esta etapa',
  'week_moment_plan_eyebrow_year_one': 'Semana\u00A0{week}\u00A0· queda {n} en este año de vida',
  'week_moment_plan_eyebrow_year_other': 'Semana\u00A0{week}\u00A0· quedan {n} en este año de vida',
  'week_moment_plan_title': 'La nueva semana es tuya.',
  'week_moment_plan_body': '¿Para qué quieres que tenga espacio?',
  'week_moment_plan_label': 'Algo que cuente esta semana',
  'week_moment_plan_hint': 'p.\u00A0ej. Volver a llamar a una amiga.',
  'week_moment_plan_primary': 'Planear la semana',
  'week_moment_plan_secondary': 'Disfrutar de la vida',
  'week_moment_step_counter': '{step} de {total}',
  'week_moment_skip': 'Saltar',
  'week_moment_tap_hint': 'continuar',
  'week_moment_stage_label': 'Tu vida en semanas',
  'week_moment_replay': 'Ver tu semana',
  'compass_setting_week_moment': 'Momento semanal',
  'compass_setting_week_moment_sub': 'Una mirada tranquila a la semana que pasó, después del recordatorio del domingo',
  'diagnostics_week_moment': 'Mostrar el momento semanal ahora',
  'diagnostics_week_moment_sub':
      'Lo reproduce como tras el recordatorio del domingo',
  'diagnostics_week_moment_reset': 'Restablecer el momento semanal',
  'diagnostics_week_moment_reset_sub':
      'Vuelve a mostrarlo tras el próximo recordatorio',
  'diagnostics_week_moment_reset_done': 'Momento semanal restablecido',
};
