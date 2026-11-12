/// Strings of the calm look back after completing an intention (the
/// "reflection"), its setting and the moment note; spread into
/// AppLocalizations.
///
/// Tone: warm, self-compassion and gratitude, never pressure or a
/// countdown. Informal address (du / tu / tú); Spanish says "etapa" for a
/// phase and "intención" for an intention. French puts U+00A0 before
/// `: ; ? ! %` and uses `’`; Spanish opens questions with `¿`; numbers stay
/// joined to their units with U+00A0, and a dash " – " keeps U+00A0 before
/// it so it never starts a line. `{taken}` is one of the `reflection_taken_*`
/// texts (`reflection_taken_enjoy_*` for something enjoyed), `{week}` a
/// grouped number.
const Map<String, String> reflectionStringsEn = {
  'reflection_eyebrow': 'Lived',
  'reflection_phase_eyebrow': 'In this phase',
  'reflection_life_eyebrow': 'In your whole life',
  'reflection_ahead_eyebrow': 'What remains',
  'reflection_taken_same_day': 'Done the very same day',
  'reflection_taken_days_one': 'Done after {n}\u00A0day',
  'reflection_taken_days_other': 'Done after {n}\u00A0days',
  'reflection_taken_weeks_one': 'Done after {n}\u00A0week',
  'reflection_taken_weeks_other': 'Done after {n}\u00A0weeks',
  'reflection_taken_months_one': 'Done after {n}\u00A0month',
  'reflection_taken_months_other': 'Done after {n}\u00A0months',
  'reflection_taken_enjoy_same_day': 'Enjoyed the very same day',
  'reflection_taken_enjoy_days_one': 'Enjoyed after {n}\u00A0day',
  'reflection_taken_enjoy_days_other': 'Enjoyed after {n}\u00A0days',
  'reflection_taken_enjoy_weeks_one': 'Enjoyed after {n}\u00A0week',
  'reflection_taken_enjoy_weeks_other': 'Enjoyed after {n}\u00A0weeks',
  'reflection_taken_enjoy_months_one': 'Enjoyed after {n}\u00A0month',
  'reflection_taken_enjoy_months_other': 'Enjoyed after {n}\u00A0months',
  'reflection_taken_line': '{taken}.',
  'reflection_phase_line':
      '{taken}\u00A0– in week\u00A0{week} of your phase “{phase}”.',
  'reflection_life_line':
      'A moment in week\u00A0{week} of your life\u00A0– it is part of your story now, for good.',
  'reflection_ahead_zero':
      'Every week from here is a gift\u00A0– and room for more moments like this.',
  'reflection_ahead_one':
      'About {n}\u00A0week lies ahead of you. Room for more moments like this.',
  'reflection_ahead_other':
      'About {n}\u00A0weeks lie ahead of you. Room for many more moments like this.',
  'reflection_thanks_doTask_0': 'You took time for this. That counts.',
  'reflection_thanks_doTask_1':
      'Something that mattered to you\u00A0– and you did it.',
  'reflection_thanks_doTask_2': 'You may be a little proud of yourself.',
  'reflection_thanks_enjoy_0': 'How lovely that you treated yourself to this.',
  'reflection_thanks_enjoy_1': 'Joy is not something you have to earn.',
  'reflection_thanks_enjoy_2': 'May it stay with you for a while.',
  'reflection_thanks_long_0':
      'It was allowed to take its time\u00A0– now it is lived.',
  'reflection_thanks_long_1': 'Good things take as long as they take.',
  'reflection_note_label': 'What are you grateful for?',
  'reflection_note_hint_doTask': 'e.g. that I kept at it',
  'reflection_note_hint_enjoy': 'e.g. the people who were there',
  'reflection_close': 'Close',
  'reflection_not_done': 'Not done yet after all',
  'compass_setting_reflection': 'Look back after finishing',
  'compass_setting_reflection_sub':
      'A calm moment for what you lived when you tick off an intention',
  'compass_field_moment_note': 'Note',
};

const Map<String, String> reflectionStringsDe = {
  'reflection_eyebrow': 'Gelebt',
  'reflection_phase_eyebrow': 'In der Phase',
  'reflection_life_eyebrow': 'Im ganzen Leben',
  'reflection_ahead_eyebrow': 'Was bleibt',
  'reflection_taken_same_day': 'Noch am selben Tag geschafft',
  'reflection_taken_days_one': 'Nach {n}\u00A0Tag geschafft',
  'reflection_taken_days_other': 'Nach {n}\u00A0Tagen geschafft',
  'reflection_taken_weeks_one': 'Nach {n}\u00A0Woche geschafft',
  'reflection_taken_weeks_other': 'Nach {n}\u00A0Wochen geschafft',
  'reflection_taken_months_one': 'Nach {n}\u00A0Monat geschafft',
  'reflection_taken_months_other': 'Nach {n}\u00A0Monaten geschafft',
  'reflection_taken_enjoy_same_day': 'Noch am selben Tag erlebt',
  'reflection_taken_enjoy_days_one': 'Nach {n}\u00A0Tag erlebt',
  'reflection_taken_enjoy_days_other': 'Nach {n}\u00A0Tagen erlebt',
  'reflection_taken_enjoy_weeks_one': 'Nach {n}\u00A0Woche erlebt',
  'reflection_taken_enjoy_weeks_other': 'Nach {n}\u00A0Wochen erlebt',
  'reflection_taken_enjoy_months_one': 'Nach {n}\u00A0Monat erlebt',
  'reflection_taken_enjoy_months_other': 'Nach {n}\u00A0Monaten erlebt',
  'reflection_taken_line': '{taken}.',
  'reflection_phase_line':
      '{taken}\u00A0– in Woche\u00A0{week} deiner Phase „{phase}“.',
  'reflection_life_line':
      'Ein Moment in Woche\u00A0{week} deines Lebens\u00A0– er gehört jetzt für immer zu deiner Geschichte.',
  'reflection_ahead_zero':
      'Jede Woche ab jetzt ist ein Geschenk\u00A0– und Raum für weitere solcher Momente.',
  'reflection_ahead_one':
      'Vor dir liegt noch etwa {n}\u00A0Woche. Raum für weitere solcher Momente.',
  'reflection_ahead_other':
      'Vor dir liegen noch etwa {n}\u00A0Wochen. Raum für viele weitere solcher Momente.',
  'reflection_thanks_doTask_0': 'Du hast dir Zeit dafür genommen. Das zählt.',
  'reflection_thanks_doTask_1':
      'Etwas, das dir wichtig war\u00A0– und du hast es getan.',
  'reflection_thanks_doTask_2':
      'Du darfst ruhig ein bisschen stolz auf dich sein.',
  'reflection_thanks_enjoy_0': 'Schön, dass du dir das gegönnt hast.',
  'reflection_thanks_enjoy_1': 'Freude muss man sich nicht verdienen.',
  'reflection_thanks_enjoy_2': 'Möge es dich noch eine Weile begleiten.',
  'reflection_thanks_long_0': 'Es durfte dauern\u00A0– jetzt ist es gelebt.',
  'reflection_thanks_long_1': 'Gute Dinge brauchen, so lange sie brauchen.',
  'reflection_note_label': 'Wofür bist du dankbar?',
  'reflection_note_hint_doTask': 'z. B. dass ich drangeblieben bin',
  'reflection_note_hint_enjoy': 'z. B. die Menschen, die dabei waren',
  'reflection_close': 'Schließen',
  'reflection_not_done': 'Doch noch nicht erledigt',
  'compass_setting_reflection': 'Rückblick nach dem Erledigen',
  'compass_setting_reflection_sub':
      'Ein ruhiger Blick auf das Gelebte, wenn du ein Vorhaben abhakst',
  'compass_field_moment_note': 'Notiz',
};

const Map<String, String> reflectionStringsFr = {
  'reflection_eyebrow': 'Vécu',
  'reflection_phase_eyebrow': 'Dans cette phase',
  'reflection_life_eyebrow': 'Dans toute ta vie',
  'reflection_ahead_eyebrow': 'Ce qui reste',
  'reflection_taken_same_day': 'Fait le jour même',
  'reflection_taken_days_one': 'Fait en {n}\u00A0jour',
  'reflection_taken_days_other': 'Fait en {n}\u00A0jours',
  'reflection_taken_weeks_one': 'Fait en {n}\u00A0semaine',
  'reflection_taken_weeks_other': 'Fait en {n}\u00A0semaines',
  'reflection_taken_months_one': 'Fait en {n}\u00A0mois',
  'reflection_taken_months_other': 'Fait en {n}\u00A0mois',
  'reflection_taken_enjoy_same_day': 'Vécu le jour même',
  'reflection_taken_enjoy_days_one': 'Vécu après {n}\u00A0jour',
  'reflection_taken_enjoy_days_other': 'Vécu après {n}\u00A0jours',
  'reflection_taken_enjoy_weeks_one': 'Vécu après {n}\u00A0semaine',
  'reflection_taken_enjoy_weeks_other': 'Vécu après {n}\u00A0semaines',
  'reflection_taken_enjoy_months_one': 'Vécu après {n}\u00A0mois',
  'reflection_taken_enjoy_months_other': 'Vécu après {n}\u00A0mois',
  'reflection_taken_line': '{taken}.',
  'reflection_phase_line':
      '{taken}\u00A0– pendant la semaine\u00A0{week} de ta phase «\u00A0{phase}\u00A0».',
  'reflection_life_line':
      'Un moment de la semaine\u00A0{week} de ta vie\u00A0– il fait désormais partie de ton histoire, pour toujours.',
  'reflection_ahead_zero':
      'Chaque semaine à partir d’ici est un cadeau\u00A0– et de la place pour d’autres moments comme celui-ci.',
  'reflection_ahead_one':
      'Devant toi, environ {n}\u00A0semaine. De la place pour d’autres moments comme celui-ci.',
  'reflection_ahead_other':
      'Devant toi, environ {n}\u00A0semaines. De la place pour bien d’autres moments comme celui-ci.',
  'reflection_thanks_doTask_0': 'Tu as pris le temps pour ça. Ça compte.',
  'reflection_thanks_doTask_1':
      'Quelque chose qui comptait pour toi\u00A0– et tu l’as fait.',
  'reflection_thanks_doTask_2': 'Savoure-le, rien qu’un peu.',
  'reflection_thanks_enjoy_0': 'C’est beau que tu te sois offert ça.',
  'reflection_thanks_enjoy_1': 'La joie n’a pas besoin d’être méritée.',
  'reflection_thanks_enjoy_2': 'Que ça t’accompagne encore un moment.',
  'reflection_thanks_long_0':
      'Ça avait le droit de prendre du temps\u00A0– maintenant, c’est vécu.',
  'reflection_thanks_long_1': 'Les belles choses prennent le temps qu’il faut.',
  'reflection_note_label': 'Pour quoi aimerais-tu dire merci\u00A0?',
  'reflection_note_hint_doTask': 'p. ex. d’avoir persévéré',
  'reflection_note_hint_enjoy': 'p. ex. les personnes qui étaient là',
  'reflection_close': 'Fermer',
  'reflection_not_done': 'Finalement, pas encore fait',
  'compass_setting_reflection': 'Regard en arrière après coup',
  'compass_setting_reflection_sub':
      'Un moment calme sur ce que tu as vécu quand tu coches une intention',
  'compass_field_moment_note': 'Note',
};

const Map<String, String> reflectionStringsEs = {
  'reflection_eyebrow': 'Vivido',
  'reflection_phase_eyebrow': 'En esta etapa',
  'reflection_life_eyebrow': 'En toda tu vida',
  'reflection_ahead_eyebrow': 'Lo que queda',
  'reflection_taken_same_day': 'Hecho el mismo día',
  'reflection_taken_days_one': 'Hecho en {n}\u00A0día',
  'reflection_taken_days_other': 'Hecho en {n}\u00A0días',
  'reflection_taken_weeks_one': 'Hecho en {n}\u00A0semana',
  'reflection_taken_weeks_other': 'Hecho en {n}\u00A0semanas',
  'reflection_taken_months_one': 'Hecho en {n}\u00A0mes',
  'reflection_taken_months_other': 'Hecho en {n}\u00A0meses',
  'reflection_taken_enjoy_same_day': 'Disfrutado el mismo día',
  'reflection_taken_enjoy_days_one': 'Disfrutado tras {n}\u00A0día',
  'reflection_taken_enjoy_days_other': 'Disfrutado tras {n}\u00A0días',
  'reflection_taken_enjoy_weeks_one': 'Disfrutado tras {n}\u00A0semana',
  'reflection_taken_enjoy_weeks_other': 'Disfrutado tras {n}\u00A0semanas',
  'reflection_taken_enjoy_months_one': 'Disfrutado tras {n}\u00A0mes',
  'reflection_taken_enjoy_months_other': 'Disfrutado tras {n}\u00A0meses',
  'reflection_taken_line': '{taken}.',
  'reflection_phase_line':
      '{taken}, en la semana\u00A0{week} de tu etapa «{phase}».',
  'reflection_life_line':
      'Un momento de la semana\u00A0{week} de tu vida: ahora forma parte de tu historia para siempre.',
  'reflection_ahead_zero':
      'Cada semana a partir de ahora es un regalo, y espacio para más momentos como este.',
  'reflection_ahead_one':
      'Ante ti queda más o menos {n}\u00A0semana. Espacio para más momentos como este.',
  'reflection_ahead_other':
      'Ante ti quedan unas {n}\u00A0semanas. Espacio para muchos más momentos como este.',
  'reflection_thanks_doTask_0': 'Te tomaste tiempo para esto. Eso cuenta.',
  'reflection_thanks_doTask_1': 'Algo que te importaba, y lo hiciste.',
  'reflection_thanks_doTask_2': 'Date un momento para celebrarlo.',
  'reflection_thanks_enjoy_0': 'Qué bien que te hayas regalado esto.',
  'reflection_thanks_enjoy_1': 'La alegría no hay que ganársela.',
  'reflection_thanks_enjoy_2': 'Que te acompañe un buen rato.',
  'reflection_thanks_long_0': 'Podía llevar su tiempo, y ahora está vivido.',
  'reflection_thanks_long_1': 'Las cosas buenas llevan el tiempo que llevan.',
  'reflection_note_label': '¿Qué agradeces?',
  'reflection_note_hint_doTask': 'p. ej. haber seguido adelante',
  'reflection_note_hint_enjoy': 'p. ej. la gente que estuvo ahí',
  'reflection_close': 'Cerrar',
  'reflection_not_done': 'Todavía no está hecho',
  'compass_setting_reflection': 'Mirada atrás al completar',
  'compass_setting_reflection_sub':
      'Un momento tranquilo para lo vivido al marcar una intención',
  'compass_field_moment_note': 'Nota',
};
