#!/usr/bin/env python3
"""Build the on-device cohort life-expectancy asset from UN WPP 2024 life tables.

Run from the repository root (Python 3 standard library only):

    python3 -I tool/build_lifetables.py

Inputs (downloaded once into the gitignored ``tool/.cache/`` and verified by sha256):
  * UN World Population Prospects 2024, single-age life tables, Medium variant,
    2024-2100, for Both / Female / Male (``WPP2024_Life_Table_Complete_Medium_*``).
  * unicode-org cldr-json 48.0.0 territory names (en, de, fr, es) and its LICENSE.

Outputs:
  * assets/lifespan/wpp2024_lt.bin        binary life-table asset (format below)
  * assets/lifespan/countries.json        {"DE": {"en": .., "de": .., "fr": .., "es": ..}, ...}
  * assets/lifespan/licenses/wpp.txt      CC BY 3.0 IGO attribution for the WPP data
  * assets/lifespan/licenses/unicode.txt  Unicode License v3 (CLDR)
  * test/fixtures/lifespan_cases.json     engine fixtures (inputs + expected outputs)
  * tool/lifespan_validation.txt          validation report (deterministic, committed)

The script exits non-zero if a validation check fails.

Model
-----
For every location (key = ISO 3166-1 alpha-2 code, or "WLD" for the World) and sex
(Both, Female, Male) and single age x = 0..100 (100 = open interval 100+):

    lnm[x]   = ln(max(mx(x, 2026), 1e-6))          WPP central death rate of the year 2026
    b_p(x)   = log-linear improvement slope (per calendar year) of trend segment p,
               segments [2026, 2040], [2040, 2065], [2065, 2100] (P = 3)
    ln mu(x, y) = lnm[x] + sum_p b_p(x) * (clamp(y, Y_p, Y_{p+1}) - Y_p)

i.e. a continuous piecewise-linear trend in ln mx, anchored at 2026 and frozen after 2100.
The slopes are fitted jointly by least squares to ln mx(x, y) - lnm[x] over all annual
tables 2026..2100 (regression through the 2026 anchor with hinges at 2040 and 2065). They
are stored only at the 22 knot ages 0, 1, 5, 10, ..., 100 (least-squares fit of a
piecewise-linear function of age to the single-age slopes) and linearly interpolated
between knots by the engine.

Why three segments: the originally planned two independent OLS slopes (2026-2050,
2050-2100) gave cohort errors up to 0.5 y (Iceland, Pakistan); a continuous two-segment fit
(hinge 2050) up to 0.31 y (World, male, e0); three continuous segments stay below 0.25 y for
every Female/Male table. See tool/README.md and tool/lifespan_validation.txt.

Binary format of assets/lifespan/wpp2024_lt.bin (all integers little-endian)
----------------------------------------------------------------------------
offset size  type        field
     0    4  ASCII       magic "WPP1"
     4    2  uint16      format version (1)
     6    1  uint8       number of ages A = 101 (0..100, last = open interval 100+)
     7    1  uint8       number of knots K = 22
     8    1  uint8       number of sexes S = 3 (order: Both, Female, Male)
     9    1  uint8       number of trend segments P = 3
    10 2(P+1) uint16[P+1] segment years Y_0..Y_P = 2026, 2040, 2065, 2100
                         (Y_0 = year of the lnm table; mortality frozen after Y_P)
    18    K  uint8[K]    knot ages: 0, 1, 5, 10, 15, ..., 100
    40    4  uint32      lnm scale   (2000):   ln mx = int16 / 2000
    44    4  uint32      slope scale (100000): b     = int16 / 100000
    48    2  uint16      number of locations N
    50  7*N  index       N entries sorted by key (byte-wise ascending):
                           3 bytes  ASCII key, NUL-padded ("DE\\0", "WLD")
                           4 bytes  uint32 absolute byte offset of the location's block
  ...        padding     0x00 up to a 4-byte boundary
  block      int16[...]  per location, S sexes in order Both, Female, Male; per sex:
                           A      int16  lnm[0..100]                 (round(ln mx * 2000))
                           P * K  int16  slopes, segment-major:
                                         b_0 at knots, b_1 at knots, b_2 at knots
                                         (round(b * 100000))
                         = S * (A + P*K) int16 = 1002 bytes per location.
(Offsets 10.. assume P = 3 and K = 22; a parser should compute them from P and K.)

Reference engine (cohort, piecewise-constant hazard), see ``run_engine`` below
-----------------------------------------------------------------------------
Inputs: location table (dequantised: lnm = q/2000, b = q/1e5), exact age a >= 0 (float),
calendar time T (float, e.g. 2026.8), lifestyle hazard multiplier H > 0.
  * b_p(i) for integer age i = 0..100: linear interpolation between the surrounding knots
    (i between knots k_j <= i <= k_{j+1}: t = (i - k_j) / (k_{j+1} - k_j),
    b = v_j + (v_{j+1} - v_j) * t).
  * Hazard on a step that starts at age x: i = min(floor(x), 100), y = calendar year at the
    step midpoint = T + (x + d/2 - a);
      B  = sum_p b_p(i) * (min(max(y, Y_p), Y_{p+1}) - Y_p)
      mu = exp(lnm[i] + B) * H
    (y < Y_0 gives B = 0; y > Y_P gives the frozen 2100 level.)
  * Steps break at integer ages: from x = a to the next integer age > a (the first step is
    1 - frac(a), or a whole year if a is an integer), then whole years until age 125.
    S_0 = 1; S_{k+1} = S_k * exp(-mu_k d_k); L_k = S_k * (1 - exp(-mu_k d_k)) / mu_k.
  * Tail beyond 125: S_end / mu_tail, where mu_tail = mu of the last step (age 124, i.e. the
    age-100 hazard); if a >= 125 there are no steps and mu_tail = mu(100, y = T).
  * mean = a + sum(L_k) + tail.
  * p25 / median / p75 = ages at which S falls to 0.75 / 0.5 / 0.25: inside the step k with
    S_k > target >= S_{k+1}: age = x_k + ln(S_k / target) / mu_k; in the tail:
    125 + ln(S_end / target) / mu_tail.
  * reach80 / reach90 = S at exact age 80 / 90 (a step boundary); null if a >= 80 / 90.
Unknown location keys fall back to "WLD"; sex is one of "both", "female", "male".
"""

import csv
import gzip
import hashlib
import json
import math
import os
import struct
import sys
import unicodedata
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CACHE = os.path.join(ROOT, 'tool', '.cache')
ASSET_DIR = os.path.join(ROOT, 'assets', 'lifespan')
BIN_PATH = os.path.join(ASSET_DIR, 'wpp2024_lt.bin')
COUNTRIES_PATH = os.path.join(ASSET_DIR, 'countries.json')
LICENSE_DIR = os.path.join(ASSET_DIR, 'licenses')
FIXTURES_PATH = os.path.join(ROOT, 'test', 'fixtures', 'lifespan_cases.json')
VALIDATION_PATH = os.path.join(ROOT, 'tool', 'lifespan_validation.txt')

WPP_BASE = ('https://population.un.org/wpp/assets/Excel%20Files/'
            '1_Indicator%20(Standard)/CSV_FILES/')
WPP_FILES = {
    'Both': ('WPP2024_Life_Table_Complete_Medium_Both_2024-2100.csv.gz',
             'ca2977c727b77a27548673d82cf065fe10e87162a3e31af5eaa811ea507ce390'),
    'Female': ('WPP2024_Life_Table_Complete_Medium_Female_2024-2100.csv.gz',
               '8ebd82988839c514556290364794daf7e8d29a39987f7c15c2cb04b4bf8845d1'),
    'Male': ('WPP2024_Life_Table_Complete_Medium_Male_2024-2100.csv.gz',
             '0a7e3eceaef592a599ec2808dd43e5081b0b834e2a579a6fd886fcf6ede77a1b'),
}
SEXES = ('Both', 'Female', 'Male')
SEX_KEYS = {'both': 0, 'female': 1, 'male': 2}

CLDR_TAG = '48.0.0'
CLDR_BASE = f'https://raw.githubusercontent.com/unicode-org/cldr-json/{CLDR_TAG}/'
CLDR_LANGS = ('en', 'de', 'fr', 'es')
CLDR_SHA256 = {
    'territories_en.json': '158c1d575308f7e46912edbeda435c8fe2ef5dad280798231f3a432e406b1807',
    'territories_de.json': 'e5b7a831cd70afeaad10a56360c08e2d970e9fe79f254ee8d937a7dfa13686b7',
    'territories_fr.json': '42d67b78cb74ffe87380db1d702d06be995c3082d7f711ffd6e75a721133c5e0',
    'territories_es.json': '027b9c91d4e923d506b404415648691ef41ebde721aa454cee4d9f7f66b3ea62',
    'LICENSE': '220ba0e1c43b99530d2d5bdb892a99dca0989414f51ab695ecd90163eaa1ec3b',
}

SEGMENT_YEARS = (2026, 2040, 2065, 2100)  # trend segment boundaries Y_0..Y_P
Y0, Y2 = SEGMENT_YEARS[0], SEGMENT_YEARS[-1]
AGES = 101
KNOTS = [0, 1] + list(range(5, 101, 5))
LNM_SCALE = 2000
B_SCALE = 100000
MX_FLOOR = 1e-6
MAX_AGE = 125
WORLD_LOCID = '900'
WORLD_KEY = 'WLD'


# --------------------------------------------------------------------------- downloads

def sha256_of(path):
    digest = hashlib.sha256()
    with open(path, 'rb') as handle:
        for chunk in iter(lambda: handle.read(1 << 20), b''):
            digest.update(chunk)
    return digest.hexdigest()


def fetch(url, name, expected_sha):
    """Download url into the cache once and verify its sha256 (if pinned)."""
    os.makedirs(CACHE, exist_ok=True)
    path = os.path.join(CACHE, name)
    if not os.path.exists(path):
        print(f'downloading {url}')
        tmp = path + '.part'
        with urllib.request.urlopen(url, timeout=600) as response, open(tmp, 'wb') as out:
            while True:
                chunk = response.read(1 << 20)
                if not chunk:
                    break
                out.write(chunk)
        os.replace(tmp, path)
    actual = sha256_of(path)
    if expected_sha is None:
        print(f'  NOTE: {name} is not pinned, sha256 = {actual}')
    elif actual != expected_sha:
        sys.exit(f'sha256 mismatch for {name}: {actual} != {expected_sha}')
    return path


# --------------------------------------------------------------------------- WPP parsing

def read_wpp(sex, path):
    """Return {locid: {'key','name','mx':{year:[101]}, 'ex':{age:ex2026}}} and dropped list."""
    locations = {}
    dropped = {}
    with gzip.open(path, 'rt', encoding='utf-8-sig', newline='') as handle:
        reader = csv.reader(handle)
        header = next(reader)
        col = {name: i for i, name in enumerate(header)}
        c_loc, c_type, c_iso2 = col['LocID'], col['LocTypeID'], col['ISO2_code']
        c_name, c_time, c_age = col['Location'], col['Time'], col['AgeGrpStart']
        c_mx, c_ex = col['mx'], col['ex']
        for row in reader:
            loc_id, loc_type = row[c_loc], row[c_type]
            if loc_id != WORLD_LOCID and loc_type != '4':
                continue
            year = int(row[c_time])
            if year < Y0:
                continue
            entry = locations.get(loc_id)
            if entry is None:
                if loc_id == WORLD_LOCID:
                    key = WORLD_KEY
                else:
                    key = row[c_iso2].strip()
                    if not key:
                        dropped[loc_id] = row[c_name]
                        continue
                entry = {'key': key, 'name': row[c_name], 'mx': {}, 'ex': {}}
                locations[loc_id] = entry
            age = int(row[c_age])
            mx_by_age = entry['mx'].setdefault(year, [None] * AGES)
            mx_by_age[age] = float(row[c_mx])
            if year == Y0 and age in (0, 65):
                entry['ex'][age] = float(row[c_ex])
    print(f'  {sex}: {len(locations)} locations')
    return locations, dropped


def load_tables():
    """Return {key: {'name', 'sexes': [ {'mx':{year:[..]}, 'ex':{..}} x3 ]}}."""
    per_sex = []
    dropped_all = {}
    for sex in SEXES:
        name, sha = WPP_FILES[sex]
        path = fetch(WPP_BASE + name, name, sha)
        locations, dropped = read_wpp(sex, path)
        per_sex.append(locations)
        dropped_all.update(dropped)
    tables = {}
    for loc_id, entry in per_sex[0].items():
        if not all(loc_id in other for other in per_sex[1:]):
            dropped_all[loc_id] = entry['name'] + ' (missing a sex)'
            continue
        sexes = [{'mx': s[loc_id]['mx'], 'ex': s[loc_id]['ex']} for s in per_sex]
        for sex_table in sexes:
            for year in range(Y0, Y2 + 1):
                ages = sex_table['mx'].get(year)
                if ages is None or any(v is None for v in ages):
                    sys.exit(f'incomplete table for {entry["key"]} {year}')
        tables[entry['key']] = {'name': entry['name'], 'sexes': sexes}
    return tables, dropped_all


# --------------------------------------------------------------------------- fitting

def ln_mx(value):
    return math.log(max(value, MX_FLOOR))


def segment_exposures(year, segment_years):
    """Years spent in each trend segment between Y_0 and `year` (clamped)."""
    return [min(max(year, lo), hi) - lo for lo, hi in zip(segment_years, segment_years[1:])]


def fit_trend_slopes(series):
    """Least-squares segment slopes b for z(y) = sum_p b_p * exposure_p(y), z(Y_0) = 0."""
    n = len(SEGMENT_YEARS) - 1
    normal = [[0.0] * n for _ in range(n)]
    rhs = [0.0] * n
    for year, z in series:
        u = segment_exposures(year, SEGMENT_YEARS)
        for i in range(n):
            rhs[i] += u[i] * z
            for j in range(n):
                normal[i][j] += u[i] * u[j]
    return solve(normal, rhs)


def hat_weights(age):
    """(knot index, weight) pairs of the piecewise-linear interpolation at an age."""
    for k in range(len(KNOTS) - 1):
        lo, hi = KNOTS[k], KNOTS[k + 1]
        if lo <= age <= hi:
            t = (age - lo) / (hi - lo)
            return [(k, 1.0 - t), (k + 1, t)]
    raise ValueError(age)


def solve(matrix, rhs):
    """Gaussian elimination with partial pivoting (small dense systems)."""
    n = len(rhs)
    a = [row[:] + [rhs[i]] for i, row in enumerate(matrix)]
    for col in range(n):
        pivot = max(range(col, n), key=lambda r: abs(a[r][col]))
        a[col], a[pivot] = a[pivot], a[col]
        for r in range(col + 1, n):
            factor = a[r][col] / a[col][col]
            for c in range(col, n + 1):
                a[r][c] -= factor * a[col][c]
    x = [0.0] * n
    for r in range(n - 1, -1, -1):
        x[r] = (a[r][n] - sum(a[r][c] * x[c] for c in range(r + 1, n))) / a[r][r]
    return x


def fit_knots(per_age):
    """Least-squares knot values of a piecewise-linear function of age to per-age values."""
    n = len(KNOTS)
    normal = [[0.0] * n for _ in range(n)]
    rhs = [0.0] * n
    for age, value in enumerate(per_age):
        weights = hat_weights(age)
        for i, wi in weights:
            rhs[i] += wi * value
            for j, wj in weights:
                normal[i][j] += wi * wj
    return solve(normal, rhs)


def fit_sex(mx_by_year):
    lnm = [ln_mx(v) for v in mx_by_year[Y0]]
    slopes_by_age = []
    for age in range(AGES):
        series = [(y, ln_mx(mx_by_year[y][age]) - lnm[age]) for y in range(Y0, Y2 + 1)]
        slopes_by_age.append(fit_trend_slopes(series))
    per_segment = [fit_knots([slopes[p] for slopes in slopes_by_age])
                   for p in range(len(SEGMENT_YEARS) - 1)]
    return lnm, per_segment


def quantise(value, scale):
    q = round(value * scale)
    if not -32768 <= q <= 32767:
        sys.exit(f'int16 overflow: {value} * {scale}')
    return q


# --------------------------------------------------------------------------- binary asset

HEADER_FMT = '<4sHBBBB'


def encode_asset(fitted):
    keys = sorted(fitted, key=lambda k: k.encode('ascii'))
    segments = len(SEGMENT_YEARS) - 1
    header = struct.pack(HEADER_FMT, b'WPP1', 1, AGES, len(KNOTS), len(SEXES), segments)
    header += struct.pack(f'<{segments + 1}H', *SEGMENT_YEARS)
    header += bytes(KNOTS)
    header += struct.pack('<IIH', LNM_SCALE, B_SCALE, len(keys))
    index_size = 7 * len(keys)
    payload_start = len(header) + index_size
    payload_start += (-payload_start) % 4
    block_size = len(SEXES) * (AGES + segments * len(KNOTS)) * 2
    index = b''
    payload = b''
    for n, key in enumerate(keys):
        index += key.encode('ascii').ljust(3, b'\0') + struct.pack('<I', payload_start + n * block_size)
        values = []
        for lnm, per_segment in fitted[key]:
            values += [quantise(v, LNM_SCALE) for v in lnm]
            for slopes in per_segment:
                values += [quantise(v, B_SCALE) for v in slopes]
        payload += struct.pack(f'<{len(values)}h', *values)
    data = header + index
    data += b'\0' * (payload_start - len(data))
    return data + payload


def decode_asset(data):
    """Parse the binary asset (exactly as the app must) into dequantised tables."""
    magic, version, ages, nknots, nsexes, segments = struct.unpack_from(HEADER_FMT, data, 0)
    assert magic == b'WPP1' and version == 1
    pos = struct.calcsize(HEADER_FMT)
    years = struct.unpack_from(f'<{segments + 1}H', data, pos)
    pos += 2 * (segments + 1)
    knots = list(data[pos:pos + nknots])
    pos += nknots
    lnm_scale, b_scale, count = struct.unpack_from('<IIH', data, pos)
    pos += 10
    tables = {}
    for n in range(count):
        key = data[pos:pos + 3].rstrip(b'\0').decode('ascii')
        (offset,) = struct.unpack_from('<I', data, pos + 3)
        pos += 7
        sexes = []
        for s in range(nsexes):
            per_sex = ages + segments * nknots
            raw = struct.unpack_from(f'<{per_sex}h', data, offset + s * per_sex * 2)
            lnm = [q / lnm_scale for q in raw[:ages]]
            slopes = [[q / b_scale for q in raw[ages + p * nknots:ages + (p + 1) * nknots]]
                      for p in range(segments)]
            sexes.append(SexTable(lnm, knots, slopes, years))
        tables[key] = sexes
    return tables


# --------------------------------------------------------------------------- engine

class SexTable:
    """Dequantised table for one location and sex; b(i) interpolated to every age."""

    def __init__(self, lnm, knots, slopes_at_knots, segment_years):
        self.lnm = lnm
        self.segment_years = segment_years
        self.slopes = [self._interpolate(knots, values) for values in slopes_at_knots]

    @staticmethod
    def _interpolate(knots, values):
        out = []
        for age in range(knots[-1] + 1):
            for k in range(len(knots) - 1):
                lo, hi = knots[k], knots[k + 1]
                if lo <= age <= hi:
                    t = (age - lo) / (hi - lo)
                    out.append(values[k] + (values[k + 1] - values[k]) * t)
                    break
        return out

    def hazard(self, age_index, year, multiplier):
        exposures = segment_exposures(year, self.segment_years)
        b = sum(slopes[age_index] * u for slopes, u in zip(self.slopes, exposures))
        return math.exp(self.lnm[age_index] + b) * multiplier


def run_engine(hazard, age, time):
    """Cohort survival from exact age `age` at calendar time `time`.

    hazard(age_index, midpoint_year) -> mu. Returns the result dict of the engine.
    """
    targets = [0.75, 0.5, 0.25]
    quantiles = [None, None, None]
    reach = {80: None, 90: None}
    survival = 1.0
    total = 0.0
    x = age
    boundary = math.floor(age) + 1
    mu = None
    while boundary <= MAX_AGE:
        d = boundary - x
        mid_year = time + (x + d / 2.0 - age)
        mu = hazard(min(math.floor(x), 100), mid_year)
        next_survival = survival * math.exp(-mu * d)
        total += survival * (1.0 - math.exp(-mu * d)) / mu
        for n, target in enumerate(targets):
            if quantiles[n] is None and survival > target >= next_survival:
                quantiles[n] = x + math.log(survival / target) / mu
        survival = next_survival
        if boundary in reach:
            reach[boundary] = survival
        x = float(boundary)
        boundary += 1
    if mu is None:
        mu = hazard(100, time)
    total += survival / mu
    for n, target in enumerate(targets):
        if quantiles[n] is None:
            quantiles[n] = x + math.log(survival / target) / mu
    return {
        'mean': age + total,
        'p25': quantiles[0],
        'median': quantiles[1],
        'p75': quantiles[2],
        'reach80': reach[80] if age < 80 else None,
        'reach90': reach[90] if age < 90 else None,
    }


def model_result(tables, key, sex, age, time, multiplier=1.0):
    resolved = key if key in tables else WORLD_KEY
    table = tables[resolved][SEX_KEYS[sex]]
    result = run_engine(lambda i, y: table.hazard(i, y, multiplier), age, time)
    result['resolvedCode'] = resolved
    return result


def period_result(table, age):
    """2026 period life expectancy from the quantised lnm only (all slopes 0)."""
    return run_engine(lambda i, y: math.exp(table.lnm[i]), age, Y0)['mean'] - age


def true_cohort_mean(mx_by_year, age):
    """Cohort e(age) from the annual WPP tables 2026..2100 (frozen after), integer age."""
    def hazard(i, mid_year):
        year = min(int(math.floor(mid_year)), Y2)
        return math.exp(ln_mx(mx_by_year[year][i]))
    return run_engine(hazard, float(age), float(Y0))['mean'] - age


# --------------------------------------------------------------------------- CLDR names

def load_cldr_names():
    names = {}
    for lang in CLDR_LANGS:
        rel = f'cldr-json/cldr-localenames-full/main/{lang}/territories.json'
        file_name = f'territories_{lang}.json'
        path = fetch(CLDR_BASE + rel, file_name, CLDR_SHA256[file_name])
        with open(path, encoding='utf-8') as handle:
            doc = json.load(handle)
        names[lang] = doc['main'][lang]['localeDisplayNames']['territories']
    license_path = fetch(CLDR_BASE + 'LICENSE', 'LICENSE', CLDR_SHA256['LICENSE'])
    with open(license_path, encoding='utf-8') as handle:
        license_text = handle.read()
    return names, license_text


def build_countries(keys, wpp_names, cldr):
    countries = {}
    fallbacks = []
    for key in sorted(keys):
        code = '001' if key == WORLD_KEY else key
        entry = {}
        for lang in CLDR_LANGS:
            name = cldr[lang].get(code)
            if name is None:
                name = wpp_names[key]
                fallbacks.append(f'{key}/{lang}')
            if key == WORLD_KEY:
                # CLDR 48 English has "world" (lower case, for running text); used as a title here.
                name = name[:1].upper() + name[1:]
            entry[lang] = unicodedata.normalize('NFC', name)
        countries[key] = entry
    return countries, fallbacks


# --------------------------------------------------------------------------- validation

class Report:
    def __init__(self):
        self.lines = []
        self.failed = []

    def add(self, line=''):
        print(line)
        self.lines.append(line)

    def fail(self, message):
        self.failed.append(message)
        self.add('FAIL: ' + message)


def validate_period(report, raw, tables):
    report.add('a) Period check (2026 rates only, slopes = 0) vs WPP ex(2026), tolerance 0.1 y')
    report.add(f'   {"loc":<4} {"sex":<7} {"e0 model":>9} {"e0 WPP":>8} {"e65 model":>9} {"e65 WPP":>8}')
    worst = []
    for key in sorted(tables):
        for s, sex in enumerate(SEXES):
            ex = raw[key]['sexes'][s]['ex']
            table = tables[key][s]
            e0, e65 = period_result(table, 0.0), period_result(table, 65.0)
            diff = max(abs(e0 - ex[0]), abs(e65 - ex[65]))
            worst.append((diff, key, sex, e0, ex[0], e65, ex[65]))
            if key in ('DE', 'JP', 'US', 'NG', WORLD_KEY):
                report.add(f'   {key:<4} {sex:<7} {e0:9.3f} {ex[0]:8.3f} {e65:9.3f} {ex[65]:8.3f}')
                if diff > 0.1:
                    report.fail(f'period check {key} {sex}: diff {diff:.3f} y')
    worst.sort(reverse=True)
    report.add('   10 worst locations (max |diff| of e0, e65):')
    for diff, key, sex, e0, w0, e65, w65 in worst[:10]:
        report.add(f'   {key:<4} {sex:<7} diff {diff:.3f}  e0 {e0:.3f}/{w0:.3f}  e65 {e65:.3f}/{w65:.3f}')
    report.add()


COHORT_AGES = (0, 30, 50, 70, 90)
COHORT_TOLERANCE = 0.3
# A "Both" table is irregular when its single-year ln mx series is jagged (max deviation from
# the mean of the neighbouring years, ages 20..95) beyond this bound - every Female/Male table
# stays below 0.013 - or when its own cohort e(a) leaves the Female..Male range.
ROUGHNESS_LIMIT = 0.02


def roughness(mx_by_year):
    worst = 0.0
    for age in range(20, 96):
        series = [ln_mx(mx_by_year[y][age]) for y in range(Y0, Y2 + 1)]
        for n in range(1, len(series) - 1):
            worst = max(worst, abs(series[n] - 0.5 * (series[n - 1] + series[n + 1])))
    return worst


def cohort_rows(raw, tables, key):
    """[(sex, age, model, true)] for one location."""
    rows = []
    for s, sex in enumerate(SEXES):
        mx_by_year = raw[key]['sexes'][s]['mx']
        table = tables[key][s]
        for age in COHORT_AGES:
            true = true_cohort_mean(mx_by_year, age)
            model = run_engine(lambda i, y: table.hazard(i, y, 1.0), float(age), float(Y0))['mean'] - age
            rows.append((sex, age, model, true))
    return rows


def both_is_irregular(raw, key, rows):
    true = {(sex, age): t for sex, age, _, t in rows}
    outside = any(not min(true['Female', a], true['Male', a]) <= true['Both', a]
                  <= max(true['Female', a], true['Male', a]) for a in COHORT_AGES)
    rough = roughness(raw[key]['sexes'][0]['mx'])
    return (outside or rough > ROUGHNESS_LIMIT), rough, outside


def validate_cohort(report, raw, tables):
    report.add('b) Cohort compression check: model vs year-by-year WPP cohort e(a) from 2026.0, H = 1,')
    report.add(f'   all locations x sexes, a in {{{", ".join(map(str, COHORT_AGES))}}}, tolerance {COHORT_TOLERANCE} y')
    gated, informational, irregular = [], [], []
    for key in sorted(tables):
        rows = cohort_rows(raw, tables, key)
        skip_both, rough, outside = both_is_irregular(raw, key, rows)
        if skip_both:
            worst_both = max(abs(m - t) for sex, _, m, t in rows if sex == 'Both')
            irregular.append((worst_both, key, rough, outside))
        for sex, age, model, true in rows:
            target = informational if (sex == 'Both' and skip_both) else gated
            target.append((abs(model - true), key, sex, age, model, true))
    gated.sort(reverse=True)
    mean_abs = sum(w[0] for w in gated) / len(gated)
    report.add(f'   gated cases {len(gated)}: max |diff| {gated[0][0]:.3f} y, mean |diff| {mean_abs:.4f} y')
    for sex in SEXES:
        sex_rows = [w for w in gated if w[2] == sex]
        report.add(f'   {sex:<7} max |diff| {sex_rows[0][0]:.3f} y ({sex_rows[0][1]}, a={sex_rows[0][3]})')
    report.add('   10 worst gated:')
    for diff, key, sex, age, model, true in gated[:10]:
        report.add(f'   {key:<4} {sex:<7} a={age:<3} model {model:7.3f} true {true:7.3f} diff {diff:.3f}')
    if gated[0][0] >= COHORT_TOLERANCE:
        report.fail(f'cohort compression max diff {gated[0][0]:.3f} y')
    irregular.sort(reverse=True)
    report.add(f'   Not gated: {len(irregular)} irregular WPP "Both" tables (jagged year-to-year ln mx > '
               f'{ROUGHNESS_LIMIT}, or Both cohort e(a) outside the Female..Male range;')
    report.add('   WPP aggregates Both from the sexes, so shifting sex ratios in small or migrant-heavy')
    report.add('   populations make the Both series non-log-linear). Worst |diff| per location:')
    for worst_both, key, rough, outside in irregular:
        report.add(f'   {key:<4} Both    max diff {worst_both:.3f}  roughness {rough:.3f}'
                   f'{"  outside F..M" if outside else ""}')
    report.add()


def fmt(value, digits=1):
    return '-' if value is None else f'{value:.{digits}f}'


def sanity_print(report, tables):
    report.add('c) Sanity: age 36 at 2026.0, H = 1 (cohort, years are ages)')
    report.add(f'   {"loc":<4} {"sex":<7} {"mean":>6} {"p25":>6} {"median":>6} {"p75":>6} {"reach80":>8} {"reach90":>8}')
    for key in ('DE', 'JP', 'US', 'NG'):
        for sex in ('female', 'male', 'both'):
            r = model_result(tables, key, sex, 36.0, 2026.0)
            report.add(f'   {key:<4} {sex:<7} {r["mean"]:6.2f} {r["p25"]:6.2f} {r["median"]:6.2f} '
                       f'{r["p75"]:6.2f} {fmt(r["reach80"], 3):>8} {fmt(r["reach90"], 3):>8}')
    report.add()


# --------------------------------------------------------------------------- fixtures

FIXTURE_CASES = [
    ('DE', 'female', 36.6, 2026.0, 1.0),
    ('DE', 'male', 36.6, 2026.8, 1.0),
    ('DE', 'both', 0.0, 2026.0, 1.0),
    ('JP', 'female', 64.2, 2026.8, 0.8),
    ('US', 'male', 0.5, 2026.0, 1.5),
    ('NG', 'both', 36.6, 2026.0, 1.5),
    ('NG', 'female', 0.0, 2026.8, 0.8),
    ('IN', 'male', 64.2, 2026.0, 1.0),
    ('BR', 'female', 99.3, 2026.8, 1.0),
    ('FR', 'both', 105.0, 2026.0, 1.5),
    ('WLD', 'both', 36.6, 2026.8, 1.0),
    ('ZZ', 'male', 64.2, 2026.0, 0.8),
]


def build_fixtures(tables):
    cases = []
    for code, sex, age, year, mult in FIXTURE_CASES:
        r = model_result(tables, code, sex, age, year, mult)
        cases.append({
            'input': {'code': code, 'sex': sex, 'age': age, 'year': year, 'hazardMultiplier': mult},
            'expected': {k: r[k] for k in ('resolvedCode', 'mean', 'p25', 'median', 'p75',
                                           'reach80', 'reach90')},
        })
    return {
        'description': 'Cohort life-expectancy engine fixtures generated by tool/build_lifetables.py '
                       'from assets/lifespan/wpp2024_lt.bin (quantised values). Match to 1e-6.',
        'asset_sha256': None,
        'cases': cases,
    }


# --------------------------------------------------------------------------- main

WPP_LICENSE = """World Population Prospects 2024 - life tables

Source: United Nations, Department of Economic and Social Affairs, Population Division (2024).
World Population Prospects 2024. Modified: compressed log-linear fits by the app author.
No endorsement by the UN implied.

Licensed under the Creative Commons Attribution 3.0 IGO licence (CC BY 3.0 IGO):
https://creativecommons.org/licenses/by/3.0/igo/

Data: https://population.un.org/wpp/
"""


def write_text(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8', newline='\n') as handle:
        handle.write(text)


def main():
    raw, dropped = load_tables()
    report = Report()
    report.add('WPP 2024 cohort life-table asset - validation report (tool/build_lifetables.py)')
    report.add()
    report.add(f'Locations: {len(raw)} (Country/Area with ISO2 + World as WLD)')
    report.add('Dropped (no ISO2 code): ' + (', '.join(f'{v} [{k}]' for k, v in sorted(dropped.items()))
                                           or 'none'))
    report.add()

    fitted = {key: [fit_sex(sex['mx']) for sex in entry['sexes']] for key, entry in raw.items()}
    data = encode_asset(fitted)
    os.makedirs(ASSET_DIR, exist_ok=True)
    with open(BIN_PATH, 'wb') as handle:
        handle.write(data)
    tables = decode_asset(data)
    assert sorted(tables) == sorted(raw)

    cldr, license_text = load_cldr_names()
    countries, fallbacks = build_countries(tables.keys(), {k: v['name'] for k, v in raw.items()}, cldr)
    write_text(COUNTRIES_PATH, json.dumps(countries, ensure_ascii=False, indent=1, sort_keys=True) + '\n')
    write_text(os.path.join(LICENSE_DIR, 'wpp.txt'), WPP_LICENSE)
    write_text(os.path.join(LICENSE_DIR, 'unicode.txt'), license_text)

    report.add(f'Asset: {os.path.relpath(BIN_PATH, ROOT)} {len(data)} bytes, sha256 {hashlib.sha256(data).hexdigest()}')
    report.add(f'Country names: CLDR {CLDR_TAG}; WPP-name fallbacks: {", ".join(fallbacks) or "none"}')
    report.add()

    validate_period(report, raw, tables)
    validate_cohort(report, raw, tables)
    sanity_print(report, tables)

    fixtures = build_fixtures(tables)
    fixtures['asset_sha256'] = hashlib.sha256(data).hexdigest()
    write_text(FIXTURES_PATH, json.dumps(fixtures, indent=2) + '\n')

    report.add('RESULT: ' + ('FAILED - ' + '; '.join(report.failed) if report.failed else 'all checks passed'))
    write_text(VALIDATION_PATH, '\n'.join(report.lines) + '\n')
    return 1 if report.failed else 0


if __name__ == '__main__':
    sys.exit(main())
