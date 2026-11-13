# Memento Mori – Brand

Logo, app icon and exports for **Memento Mori – Life in Weeks**.
Everything here is generated from `src/` — edit the generator, not the SVG output.

## Files

| Path | What it is | Use it for |
|---|---|---|
| `logo.svg` | **Master logo** (variant *Horizont*), round badge, transparent outside the ring | README, website header, print, stickers |
| `variants/*.svg` | Same badge with other scenes: `rosen`, `gipfel`, `meer`, `traumnacht`, `horizont` | Alternates, merch, splash screens |
| `icon/app-icon.svg` | **App icon**: hourglass with both skulls (41/39) over the Horizont sun and sea, no title, opaque (`launcher_icon()`) | Launcher, iOS, store listings, PWA |
| `icon/app-icon-maskable.svg` | Same, hourglass smaller so it survives circular masks | PWA `maskable` icon |
| `icon/adaptive-foreground.svg` / `-background.svg` | Android adaptive icon layers: hourglass inside the 66/108 safe circle / the sun-and-sea scene | Android launcher |
| `splash/splash-android12.svg` | Badge inside the Android 12+ splash circle, transparent around it | Launch screen (Android 12+) |
| `icon/adaptive-monochrome.svg` | Single-colour hourglass silhouette | Android 13+ themed icons |
| `icon/app-icon-simple.svg` | Reduced icon: hourglass over the Horizont sun, no title/skulls | Tiny sizes only (favicon) |
| `icon/favicon.svg` | Rounded-square mini icon based on `app-icon-simple` | Browser tab |
| `github/social-preview.svg` / `social-preview-light.svg` | 1280×640 card, dark or white background | GitHub repo social preview |
| `github/avatar-light.svg` / `avatar-dark.svg` | Badge on a white or ink square | GitHub org/user avatar |
| `exports/` | Ready-made PNG / ICO renders of all of the above | Anything that can't take SVG |

### Exports

- `exports/logo/logo-{2048,1024,512,256,128}.png` – master logo, transparent
- `exports/logo/variants/*-1024.png`
- `exports/app/app-icon-1024.png` – iOS / App Store (opaque, no alpha channel)
- `exports/android/adaptive-{foreground,background,monochrome}-1024.png`, `play-store-512.png`
- `exports/web/` – `favicon.svg`, `favicon.ico` (16/32/48), `favicon-32.png`, `apple-touch-icon.png` (180), `icon-192.png`, `icon-512.png`, `icon-maskable-512.png`
- `exports/splash/splash-logo-768.png` (badge, transparent; Android < 12 + iOS launch screen), `splash-android12-1152.png`
- `exports/github/social-preview-1280x640.png` (dark), `social-preview-light-1280x640.png` (white), `avatar-light-500.png`, `avatar-dark-500.png`

## Rules

- The badge (`logo.svg`) is the logo: README, website, launch screen. The app icon drops the title (the launcher shows the name below it) but keeps the skulls. Below ~64 px (favicons, tiny UI glyphs) use `app-icon-simple` / `favicon`; the badge's title and skulls can't be read that small.
- On white surfaces (GitHub light mode, docs, print) the badge works unchanged; for full cards use the `-light` versions.
- Don't redraw, recolour or re-letter the logo by hand; change `src/` and rebuild.
- All text is outlined to paths, so no font is needed to display any SVG.
- Keep clear space around the badge of at least 10 % of its diameter.
- Backgrounds: the badge works on any background (it carries its own black disk). The app icon is meant to be shown as-is.

## Meaning

The hourglass is a lifetime of **80 years**. The sand in the **top** bulb is the time still ahead (**41** years), the sand in the **bottom** bulb is the time already lived (**39** years). The sand *areas* are computed so they really are in the ratio 41 : 39. The two skulls carry those numbers: the small one sits fully in the deep-red sand of the top bulb, the larger one in the bottom pile.

## Colours

| Token | Hex | Role |
|---|---|---|
| Ink | `#121212` | Badge ground, outlines |
| Cream | `#F7EBD3` | Title, glass frame |
| Gold | `#F5A623` | Ring, top sand layer, accents |
| Red | `#E8452C` | Caps, sand |
| Deep red | `#C42B1E` | Deep sand |
| Coral | `#F4673F` | Sun gradient, highlights |
| Teal | `#17A898` | Glass |
| Light teal | `#2CC3B1` | Glass top, mountain light faces |
| Dark teal | `#0E857A` | Glass bottom, shadows |
| Sea | `#0B5F58` | Sea, deep backgrounds |

For app UI: Ink background, Cream text, Gold as the primary accent, Teal as the secondary accent, Red for warnings or emphasis.

## Typography

- **Poppins ExtraBold**: title ("MEMENTO MORI"), digits in the skulls
- **Poppins SemiBold**: subtitles ("Life in Weeks")

Both fonts are in `src/fonts/` (SIL Open Font License, see `src/fonts/OFL.txt`).

## Regenerating

```bash
pip install -r branding/src/requirements.txt
python branding/src/build.py                         # all SVGs + exports
python branding/src/build.py --svg-only              # SVGs only
python branding/src/build.py --remain 40 --lived 40  # different years (sand is recomputed)
```

`src/mementomori.py` holds the geometry, palette and all document builders (`badge`, `app_icon`, `app_icon_simple`, `adaptive_*`, `favicon`, `social_preview`, `avatar`). `src/scenes.py` holds the five background scenes. All drawing happens in a 1000×1000 badge space: hourglass centred on x = 500, glass from y = 203 to 809, neck at y = 506.

## Platform snippets

**Flutter** (`pubspec.yaml`, package `flutter_launcher_icons`):

```yaml
flutter_launcher_icons:
  image_path: "branding/exports/app/app-icon-1024.png"
  android: true
  ios: true
  remove_alpha_ios: true
  adaptive_icon_foreground: "branding/exports/android/adaptive-foreground-1024.png"
  adaptive_icon_background: "branding/exports/android/adaptive-background-1024.png"
  adaptive_icon_monochrome: "branding/exports/android/adaptive-monochrome-1024.png"
  web:
    generate: true
    image_path: "branding/exports/web/icon-512.png"
    background_color: "#121212"
    theme_color: "#121212"
```

In-app logo: `flutter_svg` → `SvgPicture.asset('branding/logo.svg')` (add the file to `assets:` in `pubspec.yaml`).

**Website** (`<head>`):

```html
<link rel="icon" href="/favicon.svg" type="image/svg+xml">
<link rel="icon" href="/favicon.ico" sizes="any">
<link rel="apple-touch-icon" href="/apple-touch-icon.png">
<meta name="theme-color" content="#121212">
```

**README header**:

```html
<p align="center"><img src="branding/logo.svg" width="220" alt="Memento Mori"></p>
```

**GitHub social preview**: Settings → General → Social preview → upload `exports/github/social-preview-light-1280x640.png` or the dark one (can't be set from git). GitHub shows the same image in light and dark mode, so pick one.

**README banner that follows the viewer's theme**:

```html
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="branding/exports/github/social-preview-1280x640.png">
  <img src="branding/exports/github/social-preview-light-1280x640.png" alt="Memento Mori – Life in Weeks" width="640">
</picture>
```
