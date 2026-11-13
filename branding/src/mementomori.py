"""Memento Mori brand artwork generator.

Everything is drawn as plain SVG (text converted to paths, no external fonts or
images), so the output renders identically everywhere.

Coordinate system: the badge lives in a 1000x1000 box. The hourglass is centred
on x=500, glass from y=203 to y=809, neck at y=506.
"""
import math
import os

from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
from shapely.geometry import Polygon

import scenes

HERE = os.path.dirname(os.path.abspath(__file__))

# ------------------------------------------------------------------ palette
INK = "#121212"      # badge ground, outlines
CREAM = "#F7EBD3"    # title, glass frame
GOLD = "#F5A623"     # ring, top sand layer, accents
RED = "#E8452C"      # caps, sand
RED_D = "#C42B1E"    # deep sand
RED_L = "#F4673F"
TEAL = "#17A898"     # glass
TEAL_L = "#2CC3B1"
TEAL_D = "#0E857A"
DEEP = "#0B5F58"     # sea / deep teal
SKULL_LINE = "#7E1D14"
SKULL_FILL = "#F3DFC4"
GLINT = "#E8FFFA"

# ------------------------------------------------------------------ the years
REMAIN = 41   # years still in the top bulb
LIVED = 39    # years already in the bottom bulb
FILL = 0.92   # share of one bulb the total sand would fill


def f(x):
    return f"{x:.2f}".rstrip("0").rstrip(".")


# ------------------------------------------------------------------ type
_fonts = {}


def font(name):
    if name not in _fonts:
        _fonts[name] = TTFont(os.path.join(HERE, "fonts", name))
    return _fonts[name]


def glyph(fnt, ch):
    gs = fnt.getGlyphSet()
    name = fnt.getBestCmap()[ord(ch)]
    pen = SVGPathPen(gs)
    gs[name].draw(pen)
    return pen.getCommands(), gs[name].width


def text_paths(txt, x, baseline, size, fnt="Poppins-ExtraBold.ttf", track=0.0, anchor="start"):
    """Text as outlined paths. track in em; anchor start|middle|end."""
    fo = font(fnt)
    k = size / 1000
    gl = [glyph(fo, c) for c in txt]
    width = sum(w for _, w in gl) * k + track * size * (len(txt) - 1)
    if anchor == "middle":
        x -= width / 2
    elif anchor == "end":
        x -= width
    out = []
    for d, w in gl:
        if d:
            out.append(f'<path transform="translate({f(x)} {f(baseline)}) scale({f(k)} {f(-k)})" d="{d}"/>')
        x += w * k + track * size
    return "".join(out)


def arc_title(text="MEMENTO MORI", radius=396, span_deg=106, track=0.045, space=0.55):
    """Title set on an arc over the top of the badge (baseline radius, total span)."""
    fo = font("Poppins-ExtraBold.ttf")
    span = math.radians(span_deg)
    gl = [glyph(fo, c) for c in text]
    adv = [(space * 1000 if c == " " else w) / 1000 for (d, w), c in zip(gl, text)]
    size = radius * span / (sum(adv) + track * (len(text) - 1))
    k = size / 1000
    total = sum(adv) * size + track * size * (len(text) - 1)
    s = -total / 2
    out = []
    for (d, w), c, a in zip(gl, text, adv):
        aw, gw = a * size, w * k
        phi = (s + aw / 2) / radius
        x, y = 500 + radius * math.sin(phi), 500 - radius * math.cos(phi)
        if d and c != " ":
            out.append(f'<path transform="translate({f(x)} {f(y)}) rotate({f(math.degrees(phi))}) '
                       f'translate({f(-gw / 2)} 0) scale({f(k)} {f(-k)})" d="{d}"/>')
        s += aw + track * size
    return f'<g fill="{CREAM}">{"".join(out)}</g>'


# ------------------------------------------------------------------ hourglass geometry
GLASS = ("M400,203 C360,240 365,330 410,400 C445,450 490,470 492,506 "
         "C490,542 445,562 410,612 C365,682 360,772 400,809 L600,809 "
         "C640,772 635,682 590,612 C555,562 510,542 508,506 "
         "C510,470 555,450 590,400 C635,330 640,240 600,203 Z")
TOP = ("M400,203 C360,240 365,330 410,400 C445,450 490,470 492,506 L508,506 "
       "C510,470 555,450 590,400 C635,330 640,240 600,203 Z")
BOT = ("M400,809 C360,772 365,682 410,612 C445,562 490,542 492,506 L508,506 "
       "C510,542 555,562 590,612 C635,682 640,772 600,809 Z")


def _cub(p0, p1, p2, p3, n=40):
    return [(((1 - t) ** 3) * p0[0] + 3 * ((1 - t) ** 2) * t * p1[0] + 3 * (1 - t) * t * t * p2[0] + t ** 3 * p3[0],
             ((1 - t) ** 3) * p0[1] + 3 * ((1 - t) ** 2) * t * p1[1] + 3 * (1 - t) * t * t * p2[1] + t ** 3 * p3[1])
            for t in [i / n for i in range(n + 1)]]


_top_pts = (_cub((400, 203), (360, 240), (365, 330), (410, 400)) + _cub((410, 400), (445, 450), (490, 470), (492, 506))
            + _cub((508, 506), (510, 470), (555, 450), (590, 400)) + _cub((590, 400), (635, 330), (640, 240), (600, 203)))
TOP_POLY = Polygon(_top_pts)
BOT_POLY = Polygon([(x, 1012 - y) for x, y in _top_pts])
XS = [330 + i * 4 for i in range(86)]


def _dip(x):   # funnel in the upper bulb: sand runs out in the middle
    return 30 * math.exp(-((x - 500) / 52) ** 2) - 5


def _heap(x):  # cone in the lower bulb
    return -40 * math.exp(-((x - 500) / 72) ** 2) + 8


def _region(level, fn, off=0):
    return Polygon([(x, level + fn(x) + off) for x in XS] + [(670, 900), (330, 900)])


def _solve(poly, fn, target):
    lo, hi = 150, 860
    for _ in range(60):
        mid = (lo + hi) / 2
        if poly.intersection(_region(mid, fn)).area > target:
            lo = mid
        else:
            hi = mid
    return mid


def sand_levels(remain=None, lived=None, fill=FILL):
    """Sand surface levels so the sand AREAS are in the ratio remain : lived."""
    remain = REMAIN if remain is None else remain
    lived = LIVED if lived is None else lived
    cap = TOP_POLY.area * fill
    l_top = _solve(TOP_POLY, _dip, cap * remain / (remain + lived))
    l_bot = _solve(BOT_POLY, _heap, cap * lived / (remain + lived))
    return l_top, l_bot


def _spath(level, fn, off, fill):
    pts = " ".join(f"{f(x)},{f(level + fn(x) + off)}" for x in XS)
    return f'<path fill="{fill}" d="M{pts} L670,900 L330,900 Z"/>'


def skull_badge(cx, cy, number, sc=1.02):
    """Muted skull with the number engraved on its forehead (lives in the sand)."""
    kk = 32.4 * sc / 1000
    gl = [glyph(font("Poppins-ExtraBold.ttf"), c) for c in number]
    x = cx - sum(w for _, w in gl) * kk / 2
    digits = ""
    for d, w in gl:
        digits += f'<path transform="translate({f(x)} {f(cy - 13.4 * sc)}) scale({f(kk)} {f(-kk)})" d="{d}"/>'
        x += w * kk
    return (f'<g transform="translate({cx} {cy}) scale({sc})"><g opacity="0.92">'
            f'<path fill="{SKULL_FILL}" stroke="{SKULL_LINE}" stroke-width="{f(2.6 / sc)}" stroke-linejoin="round" '
            f'd="M-45,-6 C-45,-36 -24,-46 0,-46 C24,-46 45,-36 45,-6 C45,11 38,18 29,21 L27,33 C27,39 22,42 17,42 '
            f'L-17,42 C-22,42 -27,39 -27,33 L-29,21 C-38,18 -45,11 -45,-6 Z"/>'
            f'<path d="M-36,-30 C-30,-38 -20,-42 -10,-42" fill="none" stroke="#FFFFFF" stroke-width="{f(3 / sc)}" stroke-linecap="round" opacity="0.6"/>'
            f'<ellipse cx="-17" cy="4" rx="10" ry="10.5" fill="{SKULL_LINE}"/>'
            f'<ellipse cx="17" cy="4" rx="10" ry="10.5" fill="{SKULL_LINE}"/>'
            f'<path d="M-4.5,24 L0,15 L4.5,24 Z" fill="{SKULL_LINE}" stroke="{SKULL_LINE}" stroke-width="2" stroke-linejoin="round"/>'
            f'<path d="M-9,32 V42 M0,32 V42 M9,32 V42" stroke="{SKULL_LINE}" stroke-width="{f(3 / sc)}" stroke-linecap="round"/>'
            f'</g></g><g fill="{SKULL_LINE}">{digits}</g>')


def hourglass(skulls=True, remain=None, lived=None, frame=True):
    """The hourglass in badge coordinates (incl. its own defs)."""
    remain = REMAIN if remain is None else remain
    lived = LIVED if lived is None else lived
    l_top, l_bot = sand_levels(remain, lived)
    sand_top = _spath(l_top, _dip, 0, GOLD) + _spath(l_top, _dip, 22, RED) + _spath(l_top, _dip, 70, RED_D)
    sand_bot = _spath(l_bot, _heap, 0, GOLD) + _spath(l_bot, _heap, 26, RED)
    peak = l_bot + _heap(500)
    parts = [
        f'<defs>'
        f'<linearGradient id="tealTop" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{TEAL_L}"/><stop offset="1" stop-color="{TEAL}"/></linearGradient>'
        f'<linearGradient id="tealBot" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{TEAL}"/><stop offset="1" stop-color="{TEAL_D}"/></linearGradient>'
        f'<clipPath id="clipTop"><path d="{TOP}"/></clipPath><clipPath id="clipBot"><path d="{BOT}"/></clipPath>'
        f'</defs>'
    ]
    if frame:
        parts.append(f'<rect x="375" y="148" width="250" height="9" rx="4.5" fill="{GOLD}"/>')
    parts += [
        f'<path d="{GLASS}" fill="none" stroke="{INK}" stroke-width="46" stroke-linejoin="round"/>',
        f'<path d="{GLASS}" fill="none" stroke="{CREAM}" stroke-width="30" stroke-linejoin="round"/>',
        f'<g clip-path="url(#clipTop)"><rect x="340" y="190" width="320" height="330" fill="url(#tealTop)"/>{sand_top}</g>',
        f'<g clip-path="url(#clipBot)"><rect x="340" y="500" width="320" height="320" fill="url(#tealBot)"/>{sand_bot}</g>',
        f'<path d="{TOP}" fill="none" stroke="{INK}" stroke-width="4" stroke-linejoin="round"/>',
        f'<path d="{BOT}" fill="none" stroke="{INK}" stroke-width="4" stroke-linejoin="round"/>',
        f'<path d="M500,500 V{f(peak + 4)}" stroke="{GOLD}" stroke-width="6" stroke-linecap="round"/>',
    ]
    if skulls:
        parts.append(skull_badge(500, 448, str(remain), 0.6))
        parts.append(skull_badge(500, 762, str(lived)))
    parts += [
        f'<path d="M560,236 C580,248 592,268 596,292" fill="none" stroke="{GLINT}" stroke-width="9" stroke-linecap="round"/>',
        f'<circle cx="548" cy="230" r="4.5" fill="{GLINT}"/>',
        f'<path d="M548,600 C568,612 582,630 588,652" fill="none" stroke="{GLINT}" stroke-width="9" stroke-linecap="round"/>',
        f'<rect x="360" y="166" width="280" height="30" rx="15" fill="{RED}" stroke="{INK}" stroke-width="5"/>',
        f'<rect x="360" y="816" width="280" height="30" rx="15" fill="{RED}" stroke="{INK}" stroke-width="5"/>',
    ]
    if frame:
        parts.append(f'<rect x="375" y="857" width="250" height="9" rx="4.5" fill="{GOLD}"/>')
    return "".join(parts)


def hourglass_silhouette():
    """Single-colour hourglass (alpha only) for Android themed icons."""
    l_top, l_bot = sand_levels()
    return (f'<defs><clipPath id="mTop"><path d="{TOP}"/></clipPath><clipPath id="mBot"><path d="{BOT}"/></clipPath></defs>'
            f'<g fill="#FFFFFF" stroke="#FFFFFF">'
            f'<path d="{GLASS}" fill="none" stroke-width="30" stroke-linejoin="round"/>'
            f'<g clip-path="url(#mTop)" stroke="none">{_spath(l_top, _dip, 18, "#FFFFFF")}</g>'
            f'<g clip-path="url(#mBot)" stroke="none">{_spath(l_bot, _heap, 18, "#FFFFFF")}</g>'
            f'<path d="M500,520 V{f(l_bot + _heap(500) + 18)}" stroke-width="7" stroke-linecap="round"/>'
            f'<rect x="360" y="160" width="280" height="40" rx="20" stroke="none"/>'
            f'<rect x="360" y="812" width="280" height="40" rx="20" stroke="none"/>'
            f'</g>')


# ------------------------------------------------------------------ documents
def _svg(w, h, body, label="Memento Mori"):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}" '
            f'role="img" aria-label="{label}"><title>{label}</title>{body}</svg>\n')


def badge_body(variant="horizont"):
    return (f'<defs><clipPath id="disk"><circle cx="500" cy="500" r="480"/></clipPath></defs>'
            f'<circle cx="500" cy="500" r="497" fill="{INK}"/>'
            f'<circle cx="500" cy="500" r="490" fill="{GOLD}"/>'
            f'<circle cx="500" cy="500" r="480" fill="{INK}"/>'
            f'<g clip-path="url(#disk)">{scenes.SCENES[variant]()}</g>'
            f'{arc_title()}'
            f'{hourglass()}')


def badge(variant="horizont"):
    """Full round logo, transparent outside the ring."""
    return _svg(1000, 1000, badge_body(variant))


def icon_scene(size=1024, horizon=0.60):
    """Horizont backdrop for the app icon: night sky, retro sun, sea (full bleed)."""
    hy = size * horizon
    r = size * 0.33
    cx = size / 2
    stars = "".join(
        f'<circle cx="{f(x * size)}" cy="{f(y * size)}" r="{f(rr * size / 1000)}" fill="{CREAM}" opacity="{o}"/>'
        for x, y, rr, o in [(0.12, 0.14, 5, 0.9), (0.25, 0.08, 3.5, 0.7), (0.84, 0.12, 5, 0.9), (0.73, 0.06, 3.5, 0.6),
                            (0.08, 0.34, 3.5, 0.6), (0.92, 0.30, 4, 0.75), (0.18, 0.24, 2.5, 0.5), (0.80, 0.22, 2.5, 0.5)])
    stripes = "".join(f'<rect x="0" y="{f(hy - size * o)}" width="{size}" height="{f(size * h)}" fill="{INK}"/>'
                      for o, h in [(0.095, 0.006), (0.066, 0.009), (0.038, 0.012), (0.012, 0.014)])
    bars = "".join(
        f'<rect x="{f(cx - size * w / 2)}" y="{f(hy + size * (0.025 + i * 0.045))}" width="{f(size * w)}" '
        f'height="{f(size * 0.012)}" rx="{f(size * 0.006)}" fill="{GOLD if i % 2 == 0 else RED_L}"/>'
        for i, w in enumerate([0.78, 0.66, 0.54, 0.42, 0.30, 0.20, 0.12]))
    return (f'<defs><linearGradient id="sunG" x1="0" y1="0" x2="0" y2="1">'
            f'<stop offset="0" stop-color="{GOLD}"/><stop offset="0.55" stop-color="{RED_L}"/><stop offset="1" stop-color="{RED}"/>'
            f'</linearGradient><clipPath id="skyClip"><rect width="{size}" height="{f(hy)}"/></clipPath></defs>'
            f'<rect width="{size}" height="{size}" fill="{INK}"/>{stars}'
            f'<g clip-path="url(#skyClip)"><circle cx="{f(cx)}" cy="{f(hy)}" r="{f(r)}" fill="url(#sunG)"/>{stripes}</g>'
            f'<rect y="{f(hy)}" width="{size}" height="{f(size - hy)}" fill="{DEEP}"/>{bars}'
            f'<rect y="{f(hy - size * 0.003)}" width="{size}" height="{f(size * 0.006)}" fill="{INK}"/>')


def _placed_hourglass(size, height_frac, cy_frac=0.5, **kw):
    """Hourglass scaled so its full height (caps incl.) is height_frac of the canvas."""
    s = size * height_frac / 718
    return (f'<g transform="translate({f(size / 2)} {f(size * cy_frac)}) scale({f(s)}) translate(-500 -507)">'
            f'{hourglass(**kw)}</g>')


def _placed_badge(size, diameter_frac, variant="horizont"):
    d = size * diameter_frac
    o = (size - d) / 2
    return f'<svg x="{f(o)}" y="{f(o)}" width="{f(d)}" height="{f(d)}" viewBox="0 0 1000 1000">{badge_body(variant)}</svg>'


def app_icon(size=1024, variant="horizont", diameter=0.92):
    """Square, opaque: the round badge on ink. iOS / store icon, PWA (maskable: diameter 0.78)."""
    return _svg(size, size, f'<rect width="{size}" height="{size}" fill="{INK}"/>' + _placed_badge(size, diameter, variant),
                "Memento Mori App-Icon")


def app_icon_simple(size=1024):
    """Reduced icon (hourglass over the Horizont sun, no title/skulls) for tiny sizes such as favicons."""
    return _svg(size, size, icon_scene(size) + _placed_hourglass(size, 0.80, skulls=False), "Memento Mori")


def launcher_icon(size=1024, height_frac=0.80):
    """App icon: hourglass with both skulls over the Horizont sun and sea, full bleed, opaque.
    Launcher, iOS, store and PWA icon (maskable: height_frac 0.68). The badge stays the logo."""
    return _svg(size, size, icon_scene(size) + _placed_hourglass(size, height_frac), "Memento Mori App-Icon")


def launcher_background(size=1024, scale=0.75):
    """Adaptive background: the icon scene scaled into the visible centre, edges bled out."""
    inner = size * scale
    o = (size - inner) / 2
    horizon = o + inner * 0.60
    return _svg(size, size,
                f'<rect width="{size}" height="{size}" fill="{INK}"/>'
                f'<rect y="{f(horizon)}" width="{size}" height="{f(size - horizon)}" fill="{DEEP}"/>'
                f'<svg x="{f(o)}" y="{f(o)}" width="{f(inner)}" height="{f(inner)}" viewBox="0 0 {size} {size}">'
                f'{icon_scene(size)}</svg>', "Adaptive icon background")


def launcher_foreground(size=1024):
    """Adaptive foreground: the hourglass with skulls inside the 66/108 safe circle."""
    return _svg(size, size, _placed_hourglass(size, 0.58), "Adaptive icon foreground")


def splash_android12(size=1152, diameter=0.65):
    """Android 12+ splash icon: the badge, transparent around it, inside the 2/3 circle mask."""
    return _svg(size, size, _placed_badge(size, diameter), "Memento Mori")


def adaptive_background(size=1024):
    return _svg(size, size, f'<rect width="{size}" height="{size}" fill="{INK}"/>', "Adaptive icon background")


def adaptive_foreground(size=1024, variant="horizont"):
    # Android always shows the central 66/108 circle; the badge sits just inside it.
    return _svg(size, size, _placed_badge(size, 0.61, variant), "Adaptive icon foreground")


def adaptive_monochrome(size=1024):
    s = size * 0.56 / 718
    return _svg(size, size, f'<g transform="translate({f(size / 2)} {f(size / 2)}) scale({f(s)}) translate(-500 -507)">'
                            f'{hourglass_silhouette()}</g>', "Themed icon")


def favicon(size=64):
    body = (f'<defs><clipPath id="round"><rect width="{size}" height="{size}" rx="{f(size * 0.22)}"/></clipPath></defs>'
            f'<g clip-path="url(#round)">{icon_scene(size)}{_placed_hourglass(size, 0.84, skulls=False, frame=False)}</g>')
    return _svg(size, size, body, "Memento Mori")


THEMES = {
    # background, title, subtitle, rule
    "dark": (INK, CREAM, GOLD, RED),
    "light": ("#FFFFFF", INK, RED_D, GOLD),
}


def social_preview(variant="horizont", title="Memento Mori", subtitle="Life in Weeks", theme="dark"):
    """GitHub social preview, 1280x640. theme: dark | light (white background)."""
    bg, fg, sub, rule = THEMES[theme]
    logo = f'<svg x="70" y="60" width="520" height="520" viewBox="0 0 1000 1000">{badge_body(variant)}</svg>'
    lines = title.upper().split(" ", 1)
    text = "".join(f'<g fill="{fg}">{text_paths(line, 660, 262 + i * 104, 100, track=0.04)}</g>'
                   for i, line in enumerate(lines))
    text += (f'<g fill="{sub}">{text_paths(subtitle, 664, 262 + len(lines) * 104 - 14, 52, fnt="Poppins-SemiBold.ttf", track=0.01)}</g>'
             f'<rect x="664" y="{262 + len(lines) * 104 + 22}" width="120" height="8" rx="4" fill="{rule}"/>')
    return _svg(1280, 640, f'<rect width="1280" height="640" fill="{bg}"/>{logo}{text}', f"{title} – {subtitle}")


def avatar(size=1024, theme="light", variant="horizont"):
    """Square avatar (GitHub org/user picture): the badge on a plain background."""
    bg = THEMES[theme][0]
    return _svg(size, size, f'<rect width="{size}" height="{size}" fill="{bg}"/>' + _placed_badge(size, 0.86, variant),
                "Memento Mori")
