/// Strings of the Compass intention flow (kind, when, time window), the
/// intention rows and their quiet meta lines; spread into AppLocalizations.
///
/// Tone: warm, no pressure. Informal address (du / tu / tú). French puts
/// U+00A0 before `: ; ? ! %` and uses `’`; Spanish opens questions with `¿`;
/// numbers stay joined to their units with U+00A0.
const Map<String, String> intentionStringsEn = {
  'intention_title': 'What do you want to spend a few weeks on?',
  'intention_intro': 'One small thing is enough.',
  'intention_hint': 'e.g. a trip to Norway with Dad',
  'intention_kind_label': 'What is it for you?',
  'intention_kind_do': 'Get something done',
  'intention_kind_do_sub': 'Has an end. May push.',
  'intention_kind_enjoy': 'Enjoy something',
  'intention_kind_enjoy_sub': 'Has no end. Mustn’t push.',
  'intention_when_label': 'When?',
  'intention_when_phase': 'In this phase',
  'intention_when_now': 'Now',
  'intention_when_someday': 'Someday',
  'intention_due_label': 'Date',
  'intention_due_hint': 'no rush, but not without a date',
  'intention_due_clear': 'Remove date',
  'intention_more': 'More',
  'intention_less': 'Less',
  'intention_window_label': 'Your time window',
  'intention_window_weeks_one': 'About {n} more week in this phase.',
  'intention_window_weeks_other': 'About {n} more weeks in this phase.',
  'intention_window_ending':
      'The planned time of this phase is up – just begin.',
  'intention_window_share': 'That’s {p}% of your lifespan.',
  'intention_window_nudge': 'Not much – but enough if you start soon.',
  'intention_window_open': 'This phase has no planned end. Just begin.',
  'intention_window_enjoy':
      'No pressure. Give it a date, then it’s more likely to happen.',
  'intention_window_enjoy_dated': 'No pressure – you’ve set {date} for it.',
  'intention_rhythm_weekly':
      'On Sundays the Compass reminds you of your intentions.',
  'intention_rhythm_every4Weeks':
      'Every four weeks you’ll briefly be asked how it’s going.',
  'intention_dots_scale_one': '1\u00A0dot = {n}\u00A0week',
  'intention_dots_scale_other': '1\u00A0dot = {n}\u00A0weeks',
  'intention_save_phase': 'Plan it for this phase',
  'intention_save_now': 'Plan it now',
  'intention_save_someday': 'Keep it for someday',
  'intention_meta_do': 'Intention',
  'intention_meta_do_months_one': 'Intention · ~{n} more month in this phase',
  'intention_meta_do_months_other':
      'Intention · ~{n} more months in this phase',
  'intention_meta_do_weeks_one': 'Intention · ~{n} more week in this phase',
  'intention_meta_do_weeks_other':
      'Intention · ~{n} more weeks in this phase',
  'intention_meta_enjoy': 'Enjoy · no rush, but not without a date',
  'intention_meta_enjoy_on': 'Enjoy · on {date}',
  'intention_done_phase_year_one': 'Done · {phase}, year\u00A0{n}',
  'intention_done_phase_year_other': 'Done · {phase}, year\u00A0{n}',
  'compass_now_count': '{n} of {max} · the rest can wait',
  'compass_someday_waiting_one': '{n} idea waiting.',
  'compass_someday_waiting_other': '{n} ideas waiting.',
  'compass_someday_fine': 'Most may stay here – that’s fine.',
  'compass_let_go': 'Let go',
  'compass_let_go_done': 'Let go. That’s all right.',
};

const Map<String, String> intentionStringsDe = {
  'intention_title': 'Wofür willst du ein paar Wochen verwenden?',
  'intention_intro': 'Eine kleine Sache genügt.',
  'intention_hint': 'z. B. mit Papa nach Norwegen',
  'intention_kind_label': 'Was ist das für dich?',
  'intention_kind_do': 'Etwas erledigen',
  'intention_kind_do_sub': 'Hat ein Ende. Darf drängen.',
  'intention_kind_enjoy': 'Etwas genießen',
  'intention_kind_enjoy_sub': 'Hat kein Ende. Darf nicht drängen.',
  'intention_when_label': 'Wann?',
  'intention_when_phase': 'In dieser Phase',
  'intention_when_now': 'Jetzt',
  'intention_when_someday': 'Irgendwann',
  'intention_due_label': 'Termin',
  'intention_due_hint': 'ohne Eile, aber nicht ohne Termin',
  'intention_due_clear': 'Termin entfernen',
  'intention_more': 'Mehr',
  'intention_less': 'Weniger',
  'intention_window_label': 'Dein Zeitfenster',
  'intention_window_weeks_one': 'Noch etwa {n} Woche in dieser Phase.',
  'intention_window_weeks_other': 'Noch etwa {n} Wochen in dieser Phase.',
  'intention_window_ending':
      'Die geplante Zeit dieser Phase ist um – fang einfach an.',
  'intention_window_share': 'Das sind {p} % deiner Lebensspanne.',
  'intention_window_nudge': 'Nicht viel – aber genug, wenn du bald anfängst.',
  'intention_window_open':
      'Diese Phase hat kein geplantes Ende. Fang einfach an.',
  'intention_window_enjoy':
      'Kein Druck. Gib ihm einen Termin, dann passiert es eher.',
  'intention_window_enjoy_dated':
      'Kein Druck – du hast dir den {date} vorgenommen.',
  'intention_rhythm_weekly':
      'Sonntags erinnert dich der Kompass an deine Vorhaben.',
  'intention_rhythm_every4Weeks':
      'Du wirst alle vier Wochen kurz gefragt, ob es vorangeht.',
  'intention_dots_scale_one': '1\u00A0Punkt = {n}\u00A0Woche',
  'intention_dots_scale_other': '1\u00A0Punkt = {n}\u00A0Wochen',
  'intention_save_phase': 'Für diese Phase vornehmen',
  'intention_save_now': 'Jetzt vornehmen',
  'intention_save_someday': 'Für irgendwann merken',
  'intention_meta_do': 'Vorhaben',
  'intention_meta_do_months_one': 'Vorhaben · noch ~{n} Monat in dieser Phase',
  'intention_meta_do_months_other':
      'Vorhaben · noch ~{n} Monate in dieser Phase',
  'intention_meta_do_weeks_one': 'Vorhaben · noch ~{n} Woche in dieser Phase',
  'intention_meta_do_weeks_other':
      'Vorhaben · noch ~{n} Wochen in dieser Phase',
  'intention_meta_enjoy': 'Genießen · ohne Eile, aber nicht ohne Termin',
  'intention_meta_enjoy_on': 'Genießen · am {date}',
  'intention_done_phase_year_one': 'Erledigt · {phase}, {n}.\u00A0Jahr',
  'intention_done_phase_year_other': 'Erledigt · {phase}, {n}.\u00A0Jahr',
  'compass_now_count': '{n} von {max} · Rest darf warten',
  'compass_someday_waiting_one': '{n} Idee wartet.',
  'compass_someday_waiting_other': '{n} Ideen warten.',
  'compass_someday_fine': 'Die meisten dürfen hier bleiben – das ist in Ordnung.',
  'compass_let_go': 'Loslassen',
  'compass_let_go_done': 'Losgelassen. Das ist in Ordnung.',
};

const Map<String, String> intentionStringsFr = {
  'intention_title': 'À quoi veux-tu consacrer quelques semaines ?',
  'intention_intro': 'Une petite chose suffit.',
  'intention_hint': 'p. ex. un voyage en Norvège avec papa',
  'intention_kind_label': 'Qu’est-ce que c’est pour toi ?',
  'intention_kind_do': 'Accomplir quelque chose',
  'intention_kind_do_sub': 'A une fin. Peut presser.',
  'intention_kind_enjoy': 'Profiter de quelque chose',
  'intention_kind_enjoy_sub': 'N’a pas de fin. Ne doit pas presser.',
  'intention_when_label': 'Quand ?',
  'intention_when_phase': 'Dans cette phase',
  'intention_when_now': 'Maintenant',
  'intention_when_someday': 'Un jour',
  'intention_due_label': 'Date',
  'intention_due_hint': 'sans hâte, mais pas sans date',
  'intention_due_clear': 'Retirer la date',
  'intention_more': 'Plus',
  'intention_less': 'Moins',
  'intention_window_label': 'Ta fenêtre de temps',
  'intention_window_weeks_one':
      'Encore environ {n} semaine dans cette phase.',
  'intention_window_weeks_other':
      'Encore environ {n} semaines dans cette phase.',
  'intention_window_ending':
      'Le temps prévu pour cette phase est écoulé – commence simplement.',
  'intention_window_share': 'C’est {p} % de ta durée de vie.',
  'intention_window_nudge':
      'Ce n’est pas beaucoup – mais assez si tu commences bientôt.',
  'intention_window_open':
      'Cette phase n’a pas de fin prévue. Commence simplement.',
  'intention_window_enjoy':
      'Aucune pression. Donne-lui une date, ça arrivera plus facilement.',
  'intention_window_enjoy_dated':
      'Aucune pression – tu l’as prévu pour le {date}.',
  'intention_rhythm_weekly':
      'Le dimanche, la Boussole te rappelle tes intentions.',
  'intention_rhythm_every4Weeks':
      'Toutes les quatre semaines, on te demandera brièvement où tu en es.',
  'intention_dots_scale_one': '1\u00A0point = {n}\u00A0semaine',
  'intention_dots_scale_other': '1\u00A0point = {n}\u00A0semaines',
  'intention_save_phase': 'Le prévoir pour cette phase',
  'intention_save_now': 'Le prévoir maintenant',
  'intention_save_someday': 'Le garder pour un jour',
  'intention_meta_do': 'Intention',
  'intention_meta_do_months_one':
      'Intention · encore ~{n} mois dans cette phase',
  'intention_meta_do_months_other':
      'Intention · encore ~{n} mois dans cette phase',
  'intention_meta_do_weeks_one':
      'Intention · encore ~{n} semaine dans cette phase',
  'intention_meta_do_weeks_other':
      'Intention · encore ~{n} semaines dans cette phase',
  'intention_meta_enjoy': 'Profiter · sans hâte, mais pas sans date',
  'intention_meta_enjoy_on': 'Profiter · le {date}',
  'intention_done_phase_year_one': 'Accompli · {phase}, {n}re\u00A0année',
  'intention_done_phase_year_other': 'Accompli · {phase}, {n}e\u00A0année',
  'compass_now_count': '{n} sur {max} · le reste peut attendre',
  'compass_someday_waiting_one': '{n} idée attend.',
  'compass_someday_waiting_other': '{n} idées attendent.',
  'compass_someday_fine':
      'La plupart peuvent rester ici – c’est très bien ainsi.',
  'compass_let_go': 'Lâcher prise',
  'compass_let_go_done': 'Lâché. C’est bien ainsi.',
};

const Map<String, String> intentionStringsEs = {
  'intention_title': '¿En qué quieres invertir unas semanas?',
  'intention_intro': 'Basta con una cosa pequeña.',
  'intention_hint': 'p. ej. un viaje a Noruega con papá',
  'intention_kind_label': '¿Qué es para ti?',
  'intention_kind_do': 'Hacer algo',
  'intention_kind_do_sub': 'Tiene un final. Puede apremiar.',
  'intention_kind_enjoy': 'Disfrutar algo',
  'intention_kind_enjoy_sub': 'No tiene final. No debe apremiar.',
  'intention_when_label': '¿Cuándo?',
  'intention_when_phase': 'En esta etapa',
  'intention_when_now': 'Ahora',
  'intention_when_someday': 'Algún día',
  'intention_due_label': 'Fecha',
  'intention_due_hint': 'sin prisa, pero no sin fecha',
  'intention_due_clear': 'Quitar fecha',
  'intention_more': 'Más',
  'intention_less': 'Menos',
  'intention_window_label': 'Tu margen de tiempo',
  'intention_window_weeks_one': 'Queda más o menos {n} semana en esta etapa.',
  'intention_window_weeks_other':
      'Quedan más o menos {n} semanas en esta etapa.',
  'intention_window_ending':
      'El tiempo previsto de esta etapa ya pasó: empieza sin más.',
  'intention_window_share': 'Es el {p} % de tu vida.',
  'intention_window_nudge': 'No es mucho, pero basta si empiezas pronto.',
  'intention_window_open':
      'Esta etapa no tiene un final previsto. Empieza sin más.',
  'intention_window_enjoy':
      'Sin presión. Ponle una fecha y será más fácil que ocurra.',
  'intention_window_enjoy_dated':
      'Sin presión: lo tienes previsto para el {date}.',
  'intention_rhythm_weekly':
      'Los domingos, la Brújula te recuerda tus intenciones.',
  'intention_rhythm_every4Weeks':
      'Cada cuatro semanas te preguntaremos brevemente cómo va.',
  'intention_dots_scale_one': '1\u00A0punto = {n}\u00A0semana',
  'intention_dots_scale_other': '1\u00A0punto = {n}\u00A0semanas',
  'intention_save_phase': 'Proponérmelo para esta etapa',
  'intention_save_now': 'Proponérmelo ahora',
  'intention_save_someday': 'Guardarlo para algún día',
  'intention_meta_do': 'Intención',
  'intention_meta_do_months_one': 'Intención · queda ~{n} mes en esta etapa',
  'intention_meta_do_months_other':
      'Intención · quedan ~{n} meses en esta etapa',
  'intention_meta_do_weeks_one':
      'Intención · queda ~{n} semana en esta etapa',
  'intention_meta_do_weeks_other':
      'Intención · quedan ~{n} semanas en esta etapa',
  'intention_meta_enjoy': 'Disfrutar · sin prisa, pero no sin fecha',
  'intention_meta_enjoy_on': 'Disfrutar · el {date}',
  'intention_done_phase_year_one': 'Hecho · {phase}, año\u00A0{n}',
  'intention_done_phase_year_other': 'Hecho · {phase}, año\u00A0{n}',
  'compass_now_count': '{n} de {max} · el resto puede esperar',
  'compass_someday_waiting_one': '{n} idea espera.',
  'compass_someday_waiting_other': '{n} ideas esperan.',
  'compass_someday_fine': 'La mayoría puede quedarse aquí, y está bien así.',
  'compass_let_go': 'Soltar',
  'compass_let_go_done': 'Soltado. Está bien así.',
};
