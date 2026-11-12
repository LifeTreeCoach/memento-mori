# Widget data contract (schema v1)

The home-screen widget is **native** (Android: Kotlin + Jetpack Glance; iOS: SwiftUI WidgetKit extension `ios/MementoWidget`).
Flutter publishes only **inputs**; the widget computes every displayed value itself so it stays
correct at midnight, after reboot, and while the Flutter app is not running.

Publisher: `lib/widget_service.dart` → `WidgetService.publishInputs()`, called on app start,
settings changes and pin requests. It writes with `HomeWidget.saveWidgetData` and then calls
`HomeWidget.updateWidget(qualifiedAndroidName: 'lifetree.coach.memento_mori_life_in_weeks.widget.LifeWidgetReceiver', iOSName: 'MementoWidget')`.

## Storage

| Platform | Store |
|----------|-------|
| Android  | `SharedPreferences` file `HomeWidgetPreferences` (read by `:app` `widget/WidgetInputsStore.kt` → `:lifecore` `WidgetInputs.fromValues`) |
| iOS      | App Group `group.lifetree.coach.memento_mori_life_in_weeks` `UserDefaults` (decoded by `ios/LifeCore` `WidgetInputs(defaults:)`; `WidgetInputs(values:)` for a WatchConnectivity context) |

home_widget stores Dart `int` as Java `Int` when it fits 32 bits, otherwise as `Long`
(e.g. ARGB colours ≥ `0x80000000`). Readers must accept any numeric type and truncate to 32 bits
(Swift: `Int`, `Int32`, `Int64`, `NSNumber` or a numeric string → `UInt32` ARGB).

## Keys

| Key | Type | Values / format | Default if missing |
|-----|------|-----------------|--------------------|
| `schema_version` | int | `1` | `1` |
| `birth_date` | String | `yyyy-MM-dd`; empty string = not set up | widget shows "open the app to set up" |
| `life_expectancy_years` | int | > 0 | `80` |
| `widget_display_mode` | String | `weeks` \| `months` \| `years` \| `days` (own key, independent of the app's `display_mode`) | `weeks` |
| `language` | String | `en` \| `de` \| `fr` \| `es` | device language if supported (`de`/`fr`/`es` devices get that language), else `en`; an unsupported published value falls back the same way |
| `theme_style` | String | `stoic` \| `warm` | `stoic` |
| `brightness` | String | `system` \| `light` \| `dark` (the app publishes `light` until the user picks one) | `system` |
| `color_lived` | int (ARGB) | current app colour theme, lived cells | `0xFF000000` |
| `color_remaining` | int (ARGB) | current app colour theme, remaining cells | `0xFFFFFFFF` |
| `color_accent` | int (ARGB) | accent / current week | `0xFFE0A84F` |
| `color_lived_dark` | int (ARGB) | optional: lived cells of a user colour theme in dark mode | `color_lived` |
| `color_remaining_dark` | int (ARGB) | optional: remaining cells of a user colour theme in dark mode | `color_remaining` |
| `color_accent_dark` | int (ARGB) | optional: current-week accent of the theme style in dark mode (`LifePalette.now`) | `color_accent` |

Android colours: the widget derives background, text, accent and grid colours from `theme_style` and
`brightness` itself (mirroring `lib/theme/`; `system` = day/night colours). `color_lived` /
`color_remaining` are used only when `color_lived` is not one of the style palettes' lived colours,
i.e. the user picked a colour theme. `color_accent` is currently not read on Android.

Dark colours (additive, still schema v1): colour themes are designed for light backgrounds, so
when a user colour theme is active Flutter also publishes `color_lived_dark`,
`color_remaining_dark` and `color_accent_dark`, computed with the app's own dark adaptation
(`LifePalette.resolve(style, Brightness.dark, gridOverride: ...)` in `lib/theme/life_palette.dart`:
remaining = the style's dark remaining colour with 20 % of the lived colour, lived lightened to
≥ 3:1 against it). With the style palette these keys are removed. Widgets use `color_lived` /
`color_remaining` in light mode and the `*_dark` keys in dark mode (Android: day/night
`ColorProvider`s for brightness `system`, chosen in `:lifecore` `LifePalette.gridTones`; iOS:
`LifePalette.resolve(for:systemIsDark:)`). Missing `*_dark` keys = the light colours are used in
dark mode too (behaviour before these keys existed). `color_accent_dark` is currently not read.

Readers must ignore unknown keys. Breaking changes bump `schema_version`.

## Calculation rules

Implemented identically, once per language, in `lib/core/life_calculator.dart`,
`android/lifecore/src/main/kotlin/.../widget/LifeCalculator.kt` (pure JVM module shared by all
Android targets) and `ios/LifeCore/Sources/LifeCore/LifeCalculator.swift` (Swift package shared by
the iOS widget and watch). All are tested against the shared vectors in
`test/fixtures/life_calculator_vectors.json`. All dates are date-only (local calendar day).

Swift detail: dates are `CivilDate` (year/month/day) with integer day arithmetic (no `Date`/DST
maths). "Today" is taken from `Date()` with a **Gregorian** calendar in `TimeZone.current`, never
`Calendar.current`, because `birth_date` is Gregorian and the user's calendar may be e.g. Buddhist
or Japanese.

| Value | Rule |
|-------|------|
| `daysLived` | days from birth date to today, ≥ 0 |
| `weeksLived` | `daysLived ~/ 7` |
| `totalWeeks` | `lifeExpectancyYears * 52` (the app's 52-weeks-per-year grid) |
| `weeksRemaining` | `max(0, totalWeeks - weeksLived)` |
| `currentWeekNumber` | `weeksLived + 1` (1-based) |
| `ageYears` = `yearsLived` | full years; a Feb 29 birthday is reached on Mar 1 in non-leap years |
| `totalYears` / `yearsRemaining` | `lifeExpectancyYears` / `max(0, totalYears - yearsLived)` |
| `monthsLived` | completed calendar months: `(Δyear*12 + Δmonth) - (today.day < birth.day ? 1 : 0)`, ≥ 0 |
| `totalMonths` / `monthsRemaining` | `lifeExpectancyYears * 12` / `max(0, totalMonths - monthsLived)` |
| `daysRemaining` | days until `birthDate + lifeExpectancyYears` years (Feb 29 → Mar 1 if not a leap year), ≥ 0 |
| `percentLived` | `weeksLived / totalWeeks * 100`, clamped to 0..100 (widget shows the floor) |

Any rule change must update the fixture first, then all three implementations.

Widget texts and colours are mirrored too: `ios/LifeCore` `WidgetText` matches
`android/app/src/main/res/values*/strings.xml` (EN `45%`; DE, FR and ES `45 %` with a no-break
space U+00A0; the floor of `percentLived`), and `LifePalette` matches `WidgetPalette.kt`.
Texts use informal address in every language (du / tu / tú). Plurals follow CLDR "one": only 1 in
EN/DE/ES, 0 and 1 in FR ("encore 0 an"). Numbers are grouped by the platform for the language
(EN `1,912`, DE `1.912`, FR `1 912` with U+202F). ES differs per platform: Android
(`java.text.NumberFormat`) groups 4-digit numbers (`1.912`), Apple Foundation follows CLDR
minimumGroupingDigits = 2 and prints `1912` (5+ digits group everywhere: `16.086`).
Tight complications use a one-letter week prefix without grouping: `W1912` (EN/DE), `S1912`
(FR "semaine", ES "semana"; Wear OS string `complication_week_prefix`, iOS
`WidgetText.shortWeekNumber`).

## Watches

Watches receive the **same keys** (no new schema; the optional `*_dark` colours are forwarded too) and compute everything themselves with the
shared cores (`:lifecore` on Wear OS, `ios/LifeCore` on watchOS).

### Wear OS (Wearable Data Layer)

- Phone: `:app` `widget/WearSync.kt` runs whenever the widget inputs are published
  (`LifeWidgetReceiver.onReceive` for `APPWIDGET_UPDATE`, which `HomeWidget.updateWidget` sends
  even when no widget is placed), so Flutter needs no changes. It reads the contract keys from
  `HomeWidgetPreferences` (`WidgetInputs.contractValues`) and puts a **DataItem at path
  `/memento/inputs`**: a `DataMap` with the contract keys (ints as `Int`/`Long`, strings as
  `String`) plus `updated_at` (`Long`, epoch ms) so every publish is a change, sent with
  `setUrgent()`. Runs on a background dispatcher; if Play services or the Wearable API is
  missing it logs and skips. Requires the same `applicationId` and signing key on phone and watch.
- Watch: `:wear` `sync/InputsListenerService` (`WearableListenerService`, `DATA_CHANGED` for
  `wear://*/memento/inputs`) stores the contract keys in its own `SharedPreferences` file
  `WatchInputs` and requests Tile and complication updates. The app also pulls the current
  DataItem on start (covers installing the watch app after the phone published).

### Apple Watch (WatchConnectivity)

- Phone: `ios/Runner/WatchSync.swift` (`WCSession` activated in `AppDelegate`) reads the contract
  keys from the App Group (`WidgetInputs.contractValues(in:)`, mirroring Kotlin `contractValues`) and
  calls `WCSession.default.updateApplicationContext(_:)` with them (ints as `Int`, strings as
  `String`) plus `updated_at` (`Int64`, epoch ms) so every publish is a change. Only the latest
  context is delivered, which matches "last inputs win". Triggers: after every
  `WidgetService.publishInputs()` (`HomeWidget.updateWidget` only reloads WidgetKit on iOS, so Dart
  then calls method channel `memento/watch_sync`, method `sync`, iOS only), on scene activation
  (`SceneDelegate.sceneDidBecomeActive`), when the session activates and on
  `sessionWatchStateDidChange` (watch paired / watch app installed later). Skipped silently while
  no watch is paired or the watch app is not installed.
- Watch: `ios/MementoWatch/WatchInputsStore.swift` handles `session(_:didReceiveApplicationContext:)`
  and, on activation, `receivedApplicationContext` (context sent while the app was not running).
  It replaces the contract keys in the watch's App Group `UserDefaults`
  (`group.lifetree.coach.memento_mori_life_in_weeks`, shared by the watch app and its WidgetKit
  extension `MementoWatchWidget`; `WidgetInputs.store(_:in:)`, which drops `updated_at` and removes
  keys missing from the context), calls `WidgetCenter.shared.reloadAllTimelines()` and publishes the
  decoded `WidgetInputs` to the SwiftUI app.
- Complications (`MementoWatchWidget`): accessoryCircular (gauge of the lived share, week number),
  accessoryRectangular (week, time left, bar), accessoryInline (`Week 1,912 · 45%`),
  accessoryCorner (percent, curved gauge label); timeline = now + the next 7 local midnights.

### Watch behaviour

- The watch caches the last inputs it received and **recomputes daily** from them (Apple Watch:
  complication timeline entries at each local midnight, the app recomputes "today" on activation;
  Wear OS:
  Tile `freshnessIntervalMillis` = time until the next local midnight; an inexact alarm after
  midnight, re-armed on boot/time/time-zone change, pushes Tile + complication updates).
  The phone does not need to be reachable for the week number to advance.
- No inputs yet (or empty `birth_date`): show "Open Memento Mori on your phone" /
  "Öffne Memento Mori auf deinem Smartphone" / "Ouvre Memento Mori sur ton téléphone" /
  "Abre Memento Mori en tu móvil" (Apple Watch: "... on your iPhone" / "... auf deinem iPhone" /
  "... sur ton iPhone" / "... en tu iPhone", `WidgetText.needsPhone`); before any inputs the
  language is the watch's own language if supported, else English; Wear OS complications return no data, Apple
  Watch complications show an hourglass / the app name.
- Texts follow the `language` key, not the watch language.
- Colours: watches are dark-first (OLED) and always use the **dark** variant of `theme_style`
  (Stoic dark / Warm dark); `brightness` is ignored. A user colour theme (non-default
  `color_lived`) only replaces lived / remaining / current-year colours with `color_lived_dark` /
  `color_remaining_dark` / `color_accent_dark`; without `color_lived_dark` the style's dark palette
  is used (the light `color_lived` / `color_remaining` are never shown on a watch). Chosen by
  `:lifecore` `LifePalette.watchTones` and `ios/LifeCore` `LifePalette.watch(for:)`. Applies to
  the watch apps and the Wear OS Tile; complications are tinted by the watch face, they only get
  the dark accent as a hint (Wear OS RANGED_VALUE `ColorRamp`, Apple Watch gauge `tint`).

## Widget tap

Tapping a widget opens the app at the **Life tab** (closing any screen pushed above the tab bar):
Android starts `MainActivity` with home_widget's launch action
(`es.antonborri.home_widget.actionStartActivity`) and data `mementomori://widget?homeWidget`;
iOS uses `widgetURL(mementomori://widget?homeWidget)` (URL scheme `mementomori` in
`Runner/Info.plist`; home_widget only reports URLs with a `homeWidget` query item). Flutter's
`lib/widget_launches.dart` (`HomeWidget.initiallyLaunchedFromHomeWidget` + `widgetClicked`)
tells `AppShell` to show the Life tab. Deep linking stays disabled, so the URL is never a route.

## Android refresh

- `LifeWidgetReceiver` (Glance) redraws on `APPWIDGET_UPDATE` (sent by `HomeWidget.updateWidget`
  and every 6 h via `updatePeriodMillis`).
- `MidnightRefreshReceiver` is woken by an inexact `AlarmManager.setAndAllowWhileIdle` alarm at
  00:01 local time (no exact-alarm permission) and on `BOOT_COMPLETED`, `MY_PACKAGE_REPLACED`,
  `TIME_SET` and `TIMEZONE_CHANGED`; it redraws all instances and re-arms the alarm.

## iOS refresh

The WidgetKit extension `MementoWidget` reads the keys from the App Group `UserDefaults` via
`ios/LifeCore` (`WidgetInputs.load()`), renders with `MementoWidgetUI` and uses a `TimelineProvider`
with entries for now and each of the next 7 local midnights (policy `.atEnd`), so it needs no app
wake-ups. `HomeWidget.updateWidget(iOSName: 'MementoWidget')` reloads the timeline after inputs change.
