# tool/ - life-table asset pipeline

`build_lifetables.py` turns the UN World Population Prospects 2024 single-age life tables
into the compact on-device asset used by the cohort life-expectancy engine (the app has no
internet at runtime).

```bash
python3 -I tool/build_lifetables.py     # from the repo root, Python 3 stdlib only, ~1 min
```

- Downloads once into the gitignored `tool/.cache/` (3 x ~200 MB WPP CSV.gz + CLDR JSON) and
  verifies every file against the sha256 pinned in the script.
- Writes `assets/lifespan/wpp2024_lt.bin`, `assets/lifespan/countries.json`,
  `assets/lifespan/licenses/{wpp,unicode}.txt`, `test/fixtures/lifespan_cases.json` and the
  validation report `tool/lifespan_validation.txt` (deterministic; commit it with the asset).
- Exits non-zero if a validation check fails.

## Sources

| Input | Version | Licence |
|---|---|---|
| `WPP2024_Life_Table_Complete_Medium_{Both,Female,Male}_2024-2100.csv.gz` from population.un.org | WPP 2024, Medium variant | CC BY 3.0 IGO |
| `cldr-json/cldr-localenames-full/main/{en,de,fr,es}/territories.json` | unicode-org/cldr-json tag `48.0.0` | Unicode License v3 |

Locations: every `LocTypeID == 4` (Country/Area) row with an ISO2 code (237; none was
dropped in WPP 2024) plus the World (`LocID 900`) under the key `WLD` - 238 in total.
Country names: CLDR territory name per language (`001` for `WLD`, first letter upper-cased,
because CLDR 48 English says "world"); falls back to the WPP name when CLDR lacks a code
(currently never).

## Model

Per location x sex (Both, Female, Male) x single age `x = 0..100` (100 = open interval 100+):

```
lnm[x]      = ln(max(mx(x, 2026), 1e-6))              WPP central death rate, 2026
ln mu(x, y) = lnm[x] + sum_p b_p(x) * (clamp(y, Y_p, Y_p+1) - Y_p)
segments    Y = 2026, 2040, 2065, 2100   (P = 3; frozen after 2100)
```

A continuous piecewise-linear trend in `ln mx`, anchored at the 2026 table. The P slopes per
age are fitted jointly by least squares over every annual table 2026..2100, then stored only
at the 22 knot ages `0, 1, 5, 10, ..., 100` (least-squares piecewise-linear fit in age) and
linearly interpolated between knots.

Why three segments (the originally planned design was two independent OLS slopes,
2026-2050 and 2050-2100): checked against the true year-by-year cohort e(a) (check b below),

| trend model | worst Female/Male diff |
|---|---|
| 2 independent OLS slopes (2026-50, 2050-2100) | 0.52 y (IS female e30) |
| 2 continuous segments, hinge 2050 | 0.31 y (World male e0) |
| **3 continuous segments, hinges 2040, 2065** | **0.24 y** (World male e0) |
| 4 continuous segments, hinges 2035, 2050, 2070 | 0.20 y |

Three segments cost 32 KB more than two (240 KB vs 209 KB) and pass the 0.3 y bound.

## Binary format: `assets/lifespan/wpp2024_lt.bin`

All integers little-endian. Offsets from 10 on are for P = 3 and K = 22; a parser should
derive them from P and K.

| offset | size | type | field |
|---|---|---|---|
| 0 | 4 | ASCII | magic `WPP1` |
| 4 | 2 | uint16 | format version = 1 |
| 6 | 1 | uint8 | number of ages A = 101 (0..100, last = open interval 100+) |
| 7 | 1 | uint8 | number of knots K = 22 |
| 8 | 1 | uint8 | number of sexes S = 3, order Both, Female, Male |
| 9 | 1 | uint8 | number of trend segments P = 3 |
| 10 | 2(P+1) | uint16[P+1] | segment years Y_0..Y_P = 2026, 2040, 2065, 2100 |
| 18 | K | uint8[K] | knot ages 0, 1, 5, 10, ..., 100 |
| 40 | 4 | uint32 | lnm scale = 2000 (`ln mx = int16 / 2000`) |
| 44 | 4 | uint32 | slope scale = 100000 (`b = int16 / 100000`) |
| 48 | 2 | uint16 | number of locations N (238) |
| 50 | 7N | index | N entries, sorted byte-wise by key: 3 bytes ASCII key NUL-padded (`DE\0`, `WLD`), uint32 absolute byte offset of the location block |
| ... | | | 0x00 padding to a 4-byte boundary |
| block | | int16[] | per location, S sexes (Both, Female, Male); per sex: A x int16 `lnm[0..100]`, then P x K int16 slopes, segment-major (`b_0` at the K knots, then `b_1`, then `b_2`) |

Block size: `S * (A + P*K) * 2` = 1002 bytes; file size 240,192 bytes.

## Reference engine (port this exactly; fixtures match to 1e-6)

Inputs: dequantised table (`lnm = q/2000`, `b = q/100000`), exact age `a >= 0`, calendar time
`T` (fractional year, e.g. 2026.8), lifestyle hazard multiplier `H > 0`. Unknown location key
-> `WLD`. Sex `both | female | male`.

1. Per integer age `i = 0..100`, `b_p(i)` = linear interpolation between the knots
   `k_j <= i <= k_j+1`: `t = (i - k_j) / (k_j+1 - k_j)`, `b = v_j + (v_j+1 - v_j) * t`.
2. Hazard of a step starting at age `x` with length `d`:
   `i = min(floor(x), 100)`, `y = T + (x + d/2 - a)` (calendar year at the step midpoint),
   `B = sum_p b_p(i) * (min(max(y, Y_p), Y_p+1) - Y_p)` (sum from p = 0 upwards),
   `mu = exp(lnm[i] + B) * H`.
3. Steps end at integer ages: first boundary `floor(a) + 1` (a whole year if `a` is an
   integer), then every integer up to and including 125. Per step `k`:
   `S_k+1 = S_k * exp(-mu*d)`, `L_k = S_k * (1 - exp(-mu*d)) / mu`, starting at `S_0 = 1`.
4. Tail after 125: `S_end / mu_tail`, `mu_tail` = mu of the last step (age 124, i.e. the
   age-100 hazard). If `a >= 125` there are no steps: `mu_tail = mu(i = 100, y = T)`.
5. `mean = a + sum L_k + tail`.
6. `p25 / median / p75` = age where `S` falls to `0.75 / 0.5 / 0.25`: in the step with
   `S_k > target >= S_k+1`: `x_k + ln(S_k / target) / mu_k`; otherwise in the tail:
   `x_end + ln(S_end / target) / mu_tail` (`x_end` = 125, or `a` when there were no steps).
7. `reach80 / reach90` = `S` at the step boundary 80 / 90; `null` if `a >= 80 / 90`.

`test/fixtures/lifespan_cases.json`: `{description, asset_sha256, cases: [{input: {code, sex,
age, year, hazardMultiplier}, expected: {resolvedCode, mean, p25, median, p75, reach80,
reach90}}]}`; the expected values come from this engine run on the quantised asset.

## Validation (`tool/lifespan_validation.txt`)

- **a) Period check**: 2026 rates only (slopes = 0), e0 and e65 vs WPP's own `ex` 2026 within
  0.1 y for DE, JP, US, NG, WLD x 3 sexes. Worst over all locations: 0.064 y (GN male e0;
  WPP's age-0 `ax` differs from the constant-hazard assumption in high infant-mortality
  countries).
- **b) Cohort compression check**: the model vs the true cohort e(a) computed year by year
  from all annual WPP tables 2026..2100 (frozen after) for a = 0, 30, 50, 70, 90 at
  2026.0, H = 1: max 0.241 y, mean 0.044 y. The gate covers every Female and Male table and
  every regular Both table. 23 "Both" tables of micro-states and migrant-heavy countries (MF,
  MH, CK, TK, TO, SH, NU, AE, MS, QA, ...) are reported but not gated: WPP derives Both from
  the sexes, and shifting sex ratios make their single-year Both series jagged (year-to-year
  jumps up to 0.5 in ln mx) or put the Both cohort e(a) outside the Female..Male range, which
  no smooth trend can follow (worst: MF Both e30, 1.96 y). Their Female/Male tables pass.
- **c) Sanity print**: DE/JP/US/NG x female/male/both at age 36 in 2026.

# tool/ - life quotes

`quotes/quotes.json` is the verified quote collection (182 entries: id, author and text per
language, source, original language, themes, life stages, plus the verification note/URL).
`generate_quotes.py` validates it and writes `lib/life/quotes/quote_data.dart` (const Dart,
no verification URLs):

```bash
python3 -I tool/generate_quotes.py     # from the repo root, Python 3 stdlib only
```

# tool/ - Compass prompts

`compass/prompts.json` holds the Compass texts (157 entries: id, kind courage/connection/rest/
pride/note/limit, life stages, suggestion intention/moment, optional `phase` flag, optional
`topic` per language (weekly questions only: shown in the question's eyebrow instead of the
kind's name), text per language; phase questions name the current life phase through `{phase}`).
`generate_compass_prompts.py` validates it (kinds, stages = `LifeStage`, all four languages,
same placeholders per language) and writes `lib/compass/compass_prompts.dart`:

```bash
python3 -I tool/generate_compass_prompts.py     # from the repo root, Python 3 stdlib only
```
