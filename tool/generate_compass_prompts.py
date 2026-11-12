#!/usr/bin/env python3
"""Generate lib/compass/compass_prompts.dart from tool/compass/prompts.json.

Run from the repository root (Python 3 standard library only):

    python3 -I tool/generate_compass_prompts.py

Each entry has an id, a kind (courage, connection, rest, pride = weekly
questions; note = compassionate notes; limit = hints shown when "Now" is
full), life stages (empty = any), an optional suggestion (intention or
moment), an optional `phase` flag, an optional `topic` per app language
(weekly questions only; shown in the eyebrow instead of the kind's name)
and the text per app language.
Placeholders such as {weeks} must appear in every language of an entry.
Phase questions (`"phase": true`, weekly question kinds only) name the
current life phase through {phase}; no other entry may contain {phase}.
"""
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SOURCE = ROOT / 'tool' / 'compass' / 'prompts.json'
TARGET = ROOT / 'lib' / 'compass' / 'compass_prompts.dart'
LANGUAGES = ('en', 'de', 'fr', 'es')
# Must match lib/life/life_stage.dart.
STAGES = ('young', 'exploring', 'building', 'midlife', 'harvest', 'wisdom')
QUESTION_KINDS = ('courage', 'connection', 'rest', 'pride')
KINDS = QUESTION_KINDS + ('note', 'limit')
SUGGESTIONS = ('intention', 'moment')
PLACEHOLDER = re.compile(r'\{(\w+)\}')


def dart_string(value):
    """A single-quoted Dart literal; non-ASCII spaces become \\u escapes."""
    out = []
    for char in value:
        if char in '\\\'$':
            out.append('\\' + char)
        elif char == '\n':
            out.append('\\n')
        elif char in '   ':
            out.append('\\u%04X' % ord(char))
        else:
            out.append(char)
    return "'" + ''.join(out) + "'"


def language_map(values, indent):
    pad = ' ' * indent
    lines = ['{']
    for language in LANGUAGES:
        lines.append(f'{pad}  \'{language}\': {dart_string(values[language])},')
    lines.append(pad + '}')
    return '\n'.join(lines)


def validate_entry(prompt):
    pid = prompt['id']
    if prompt['kind'] not in KINDS:
        sys.exit(f'{pid}: unknown kind {prompt["kind"]}')
    if prompt['suggestion'] is not None and prompt['suggestion'] not in SUGGESTIONS:
        sys.exit(f'{pid}: unknown suggestion {prompt["suggestion"]}')
    for stage in prompt['stages']:
        if stage not in STAGES:
            sys.exit(f'{pid}: unknown stage {stage}')
    validate_phase(prompt)
    validate_topic(prompt)
    placeholders = None
    for language in LANGUAGES:
        text = prompt['text'].get(language, '')
        if not text.strip():
            sys.exit(f'{pid}: empty {language} text')
        found = sorted(set(PLACEHOLDER.findall(text)))
        if placeholders is not None and found != placeholders:
            sys.exit(f'{pid}: placeholders differ in {language}')
        placeholders = found


def validate_phase(prompt):
    """`phase` is an optional bool; {phase} appears exactly in phase prompts."""
    pid = prompt['id']
    phase = prompt.get('phase', False)
    if not isinstance(phase, bool):
        sys.exit(f'{pid}: phase must be true or false')
    if phase and prompt['kind'] not in QUESTION_KINDS:
        sys.exit(f'{pid}: only weekly questions can be phase questions')
    for language in LANGUAGES:
        has_placeholder = '{phase}' in prompt['text'].get(language, '')
        if phase and not has_placeholder:
            sys.exit(f'{pid}: phase question without {{phase}} in {language}')
        if not phase and has_placeholder:
            sys.exit(f'{pid}: {{phase}} in {language} of a non-phase entry')


def validate_topic(prompt):
    """`topic` is optional: a short label in every language, questions only."""
    pid = prompt['id']
    topic = prompt.get('topic')
    if topic is None:
        return
    if prompt['kind'] not in QUESTION_KINDS:
        sys.exit(f'{pid}: only weekly questions can have a topic')
    for language in LANGUAGES:
        if not str(topic.get(language, '')).strip():
            sys.exit(f'{pid}: empty {language} topic')
        if PLACEHOLDER.search(topic[language]):
            sys.exit(f'{pid}: placeholder in {language} topic')


def validate(prompts):
    ids = set()
    for prompt in prompts:
        if prompt['id'] in ids:
            sys.exit(f'duplicate id {prompt["id"]}')
        ids.add(prompt['id'])
        validate_entry(prompt)
    for kind in KINDS:
        if not any(p['kind'] == kind for p in prompts):
            sys.exit(f'no {kind} entries')


def entry(prompt):
    lines = ['  CompassPrompt(', f'    id: {dart_string(prompt["id"])},']
    lines.append(f'    kind: CompassPromptKind.{prompt["kind"]},')
    if prompt['stages']:
        stages = ', '.join(f'LifeStage.{s}' for s in prompt['stages'])
        lines.append(f'    stages: [{stages}],')
    if prompt['suggestion']:
        lines.append(f'    suggestion: CompassSuggestion.{prompt["suggestion"]},')
    if prompt.get('phase', False):
        lines.append('    phase: true,')
    if prompt.get('topic'):
        lines.append(f'    topic: {language_map(prompt["topic"], 4)},')
    lines.append(f'    text: {language_map(prompt["text"], 4)},')
    lines.append('  ),')
    return '\n'.join(lines)


def dart_list(name, doc, prompts):
    body = '\n'.join(entry(p) for p in prompts)
    return f'/// {doc}\nconst List<CompassPrompt> {name} = [\n{body}\n];\n'


def main():
    prompts = json.loads(SOURCE.read_text(encoding='utf-8'))
    validate(prompts)
    questions = [p for p in prompts if p['kind'] in QUESTION_KINDS]
    notes = [p for p in prompts if p['kind'] == 'note']
    limits = [p for p in prompts if p['kind'] == 'limit']
    header = (
        '// GENERATED by tool/generate_compass_prompts.py from tool/compass/prompts.json.\n'
        '// Do not edit by hand: change the JSON and run\n'
        '//   python3 -I tool/generate_compass_prompts.py\n\n'
        "import 'package:memento_mori_life_in_weeks/compass/compass_prompt.dart';\n"
        "import 'package:memento_mori_life_in_weeks/life/life_stage.dart';\n\n"
    )
    sections = [
        dart_list('compassQuestions',
                  'Weekly questions (courage, connection, rest, pride), in collection order;\n'
                  '/// `phase` questions contain `{phase}` (the current life phase).',
                  questions),
        dart_list('compassNotes',
                  'Compassionate notes; `{weeks}` is the number of weeks lived.',
                  notes),
        dart_list('compassLimitHints',
                  'Hints shown when "Now" already holds three intentions.',
                  limits),
    ]
    TARGET.write_text(header + '\n'.join(sections), encoding='utf-8')
    print(f'{len(questions)} questions, {len(notes)} notes, {len(limits)} limit hints'
          f' -> {TARGET.relative_to(ROOT)}')


if __name__ == '__main__':
    main()
