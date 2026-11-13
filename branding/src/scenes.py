"""Background scenes for the Memento Mori badge variants.

All scenes draw in a 1000x1000 space, behind the hourglass and title, and are
clipped to the inner disk (r=480) by the caller.
"""
import math, random

INK = "#121212"
CREAM = "#F7EBD3"
GOLD = "#F5A623"
RED = "#E8452C"
RED_D = "#C42B1E"
RED_L = "#F4673F"
TEAL = "#17A898"
TEAL_L = "#2CC3B1"
TEAL_D = "#0E857A"
DEEP = "#0B5F58"
ROCK = "#3A4746"


def f(x):
    return f"{x:.1f}".rstrip("0").rstrip(".")


def pts(p):
    return " ".join(f"{f(x)},{f(y)}" for x, y in p)


def sparkle(x, y, r=11, fill=GOLD):
    a = r * 0.22
    return (f'<path transform="translate({f(x)} {f(y)})" fill="{fill}" '
            f'd="M0,{-r} C{a},{-a} {a},{-a} {r},0 C{a},{a} {a},{a} 0,{r} '
            f'C{-a},{a} {-a},{a} {-r},0 C{-a},{-a} {-a},{-a} 0,{-r} Z"/>')


def title_arcs():
    a = f'<path d="M210,306 Q246,232 356,222" fill="none" stroke="{GOLD}" stroke-width="5" stroke-linecap="round"/>'
    return a + f'<g transform="translate(1000 0) scale(-1 1)">{a}</g>'


def stars(seed, n, avoid=()):
    """scattered dots + a few sparkles, kept off the title, hourglass, numbers and given boxes."""
    rnd = random.Random(seed)
    boxes = [(330, 130, 670, 880)] + list(avoid)
    out, tries = [], 0
    while len(out) < n and tries < 5000:
        tries += 1
        x, y = rnd.uniform(40, 960), rnd.uniform(80, 700)
        dx, dy = x - 500, y - 500
        r = math.hypot(dx, dy)
        ang = math.degrees(math.atan2(dx, -dy))
        if r > 462:
            continue
        if 375 < r < 470 and abs(ang) < 60:
            continue
        if any(x0 <= x <= x1 and y0 <= y <= y1 for x0, y0, x1, y1 in boxes):
            continue
        if any(math.hypot(x - a, y - b) < 22 for a, b, _ in out):
            continue
        out.append((x, y, rnd.random()))
    s = []
    for x, y, q in out:
        if q > 0.86:
            s.append(sparkle(x, y, 7 + q * 4))
        else:
            s.append(f'<circle cx="{f(x)}" cy="{f(y)}" r="{f(1.6 + q * 1.8)}" fill="{CREAM}" opacity="{f(0.45 + q * 0.55)}"/>')
    return "".join(s)


def crescent(cx, cy, r, inner=0.55, fill=CREAM, stroke=5):
    ri = r * inner
    return (f'<path d="M{f(cx)},{f(cy - r)} A{f(r)} {f(r)} 0 1 0 {f(cx)},{f(cy + r)} '
            f'A{f(ri)} {f(r)} 0 0 1 {f(cx)},{f(cy - r)} Z" fill="{fill}" stroke="{INK}" '
            f'stroke-width="{stroke}" stroke-linejoin="round"/>')


def sun(cx, cy, r, rays=12):
    s = []
    for i in range(rays):
        a = math.radians(i * 360 / rays)
        p = [(cx + math.sin(a - 0.11) * (r + 9), cy - math.cos(a - 0.11) * (r + 9)),
             (cx + math.sin(a) * (r + 26), cy - math.cos(a) * (r + 26)),
             (cx + math.sin(a + 0.11) * (r + 9), cy - math.cos(a + 0.11) * (r + 9))]
        s.append(f'<polygon points="{pts(p)}" fill="{GOLD}" stroke="{INK}" stroke-width="3" stroke-linejoin="round"/>')
    s.append(f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{GOLD}" stroke="{INK}" stroke-width="5"/>')
    s.append(f'<circle cx="{cx}" cy="{cy}" r="{r * 0.62}" fill="#FFC24D"/>')
    s.append(f'<path d="M{f(cx - r * 0.55)},{f(cy - r * 0.25)} A{f(r * 0.6)} {f(r * 0.6)} 0 0 1 {f(cx - r * 0.1)},{f(cy - r * 0.6)}" '
             f'fill="none" stroke="#FFE3A3" stroke-width="5" stroke-linecap="round"/>')
    return "".join(s)


def mountain(px, py, lx, rx, by, light, dark, snow=0.26):
    h = by - py
    ridge = [(px, py), (px + 10, py + 0.3 * h), (px - 8, py + 0.62 * h), (px + 6, by)]
    lightp = [(lx, by)] + ridge
    darkp = ridge + [(rx, by)]
    sh = snow * h
    sl = (px - (px - lx) * snow, py + sh)
    sr = (px + (rx - px) * snow, py + sh)
    cap = [(px, py), sr,
           (px + (rx - px) * snow * 0.45, py + sh * 0.72),
           (px + 6, py + sh * 1.05),
           (px - (px - lx) * snow * 0.4, py + sh * 0.7), sl]
    return (f'<polygon points="{pts(lightp)}" fill="{light}"/>'
            f'<polygon points="{pts(darkp)}" fill="{dark}"/>'
            f'<polygon points="{pts(cap)}" fill="{CREAM}" stroke="{INK}" stroke-width="3.5" stroke-linejoin="round"/>'
            f'<polygon points="{pts([(lx, by), (px, py), (rx, by)])}" fill="none" stroke="{INK}" stroke-width="5" stroke-linejoin="round"/>')


def gull(x, y, s=1.0, color=CREAM):
    return (f'<path transform="translate({x} {y}) scale({s})" d="M-14,0 C-10,-9 -4,-9 0,0 C4,-9 10,-9 14,0" '
            f'fill="none" stroke="{color}" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>')


# ------------------------------------------------------------------ Gipfel
def gipfel():
    s = [stars(11, 34, avoid=[(195, 265, 335, 405), (665, 265, 805, 405)])]
    s.append(title_arcs())
    s.append(sun(265, 338, 42))
    s.append(crescent(737, 338, 46, 0.5))
    s.append(sparkle(782, 300, 8) + sparkle(700, 392, 7))
    # back range
    s.append(mountain(500, 730, 300, 700, 1000, TEAL_D, DEEP, 0.15))
    s.append(mountain(95, 540, -120, 300, 1000, TEAL_D, DEEP, 0.2))
    s.append(mountain(905, 540, 700, 1120, 1000, TEAL_D, DEEP, 0.2))
    s.append(mountain(330, 650, 150, 520, 1000, TEAL_D, DEEP, 0.2))
    s.append(mountain(670, 650, 480, 850, 1000, TEAL_D, DEEP, 0.2))
    # front range
    s.append(mountain(190, 445, -90, 440, 1000, TEAL_L, TEAL, 0.24))
    s.append(mountain(812, 480, 570, 1090, 1000, TEAL_L, TEAL, 0.24))
    # trail to the summit
    s.append(f'<path d="M318,960 C250,915 300,860 240,815 C180,770 262,715 222,655 C192,605 232,540 194,452" '
             f'fill="none" stroke="{CREAM}" stroke-width="4" stroke-dasharray="2 12" stroke-linecap="round"/>')
    # summit flag
    s.append(f'<path d="M190,446 V378" stroke="{INK}" stroke-width="10" stroke-linecap="round"/>'
             f'<path d="M190,446 V378" stroke="{CREAM}" stroke-width="4" stroke-linecap="round"/>'
             f'<path d="M192,380 C206,374 220,388 236,382 L230,398 L236,414 C220,420 206,406 192,412 Z" '
             f'fill="{RED}" stroke="{INK}" stroke-width="4" stroke-linejoin="round"/>')
    # small cairn on the right summit
    s.append(f'<g stroke="{INK}" stroke-width="3.5" fill="{GOLD}">'
             f'<ellipse cx="812" cy="468" rx="14" ry="7"/><ellipse cx="812" cy="456" rx="10" ry="6"/>'
             f'<ellipse cx="812" cy="446" rx="6" ry="5"/></g>')
    return "".join(s)


# ------------------------------------------------------------------ Meer
def wave_band(y0, amp, period, color, phase=0, foam=True):
    x = -60 - phase
    d = [f"M{f(x)},{y0}"]
    crests = []
    while x < 1060:
        d.append(f"C{f(x + period * 0.25)},{f(y0 - amp)} {f(x + period * 0.75)},{f(y0 - amp)} {f(x + period)},{y0}")
        crests.append(x + period * 0.5)
        x += period
    top = " ".join(d)
    body = top + f" L1060,1010 L-60,1010 Z"
    out = [f'<path d="{body}" fill="{color}"/>',
           f'<path d="{top}" fill="none" stroke="{INK}" stroke-width="5" stroke-linejoin="round"/>']
    if foam:
        for cx in crests:
            yc = y0 - amp * 0.75
            out.append(f'<path d="M{f(cx - period * 0.3)},{f(y0 - amp * 0.35)} Q{f(cx - period * 0.12)},{f(yc - 2)} {f(cx + period * 0.08)},{f(yc + 1)} '
                       f'q-6,10 4,14" fill="none" stroke="{CREAM}" stroke-width="4" stroke-linecap="round"/>')
    return "".join(out)


def lighthouse(cx, base, top):
    s = []
    hw_b, hw_t = 32, 19
    # beams
    s.append(f'<polygon points="{pts([(cx, top - 22), (990, top - 75), (990, top + 25)])}" fill="{GOLD}" opacity="0.3"/>')
    s.append(f'<polygon points="{pts([(cx, top - 22), (650, top - 60), (650, top + 10)])}" fill="{GOLD}" opacity="0.22"/>')
    s.append(f'<circle cx="{cx}" cy="{top - 22}" r="34" fill="{GOLD}" opacity="0.25"/>')
    # rock
    s.append(f'<path d="M{cx - 78},{base + 40} C{cx - 70},{base - 4} {cx - 40},{base - 14} {cx},{base - 12} '
             f'C{cx + 44},{base - 14} {cx + 74},{base} {cx + 82},{base + 40} Z" fill="{ROCK}" stroke="{INK}" stroke-width="5" stroke-linejoin="round"/>')
    # tower stripes
    n = 4
    for i in range(n):
        y0 = base - (base - top) * i / n
        y1 = base - (base - top) * (i + 1) / n
        w0 = hw_b + (hw_t - hw_b) * i / n
        w1 = hw_b + (hw_t - hw_b) * (i + 1) / n
        col = RED if i % 2 == 0 else CREAM
        s.append(f'<polygon points="{pts([(cx - w0, y0), (cx + w0, y0), (cx + w1, y1), (cx - w1, y1)])}" fill="{col}"/>')
    s.append(f'<polygon points="{pts([(cx - hw_b, base), (cx + hw_b, base), (cx + hw_t, top), (cx - hw_t, top)])}" '
             f'fill="none" stroke="{INK}" stroke-width="5" stroke-linejoin="round"/>')
    s.append(f'<rect x="{cx - 9}" y="{base - 40}" width="18" height="30" rx="9" fill="{INK}"/>')
    # gallery, lantern, roof
    s.append(f'<rect x="{cx - 27}" y="{top - 10}" width="54" height="12" rx="3" fill="{CREAM}" stroke="{INK}" stroke-width="4"/>')
    s.append(f'<rect x="{cx - 15}" y="{top - 42}" width="30" height="32" fill="{GOLD}" stroke="{INK}" stroke-width="4"/>')
    s.append(f'<path d="M{cx - 5},{top - 42} V{top - 10} M{cx + 5},{top - 42} V{top - 10}" stroke="{INK}" stroke-width="3"/>')
    s.append(f'<polygon points="{pts([(cx - 24, top - 42), (cx, top - 68), (cx + 24, top - 42)])}" fill="{RED}" stroke="{INK}" stroke-width="4" stroke-linejoin="round"/>')
    s.append(f'<circle cx="{cx}" cy="{top - 72}" r="5" fill="{CREAM}" stroke="{INK}" stroke-width="3"/>')
    return "".join(s)


def sailboat(cx, y):
    return (f'<g stroke="{INK}" stroke-width="5" stroke-linejoin="round" stroke-linecap="round">'
            f'<path d="M{cx},{y} V{y - 168}" stroke-width="11"/>'
            f'<path d="M{cx},{y} V{y - 168}" stroke="{CREAM}" stroke-width="4"/>'
            f'<path d="M{cx + 2},{y - 160} L{cx + 34},{y - 150} L{cx + 2},{y - 140} Z" fill="{RED}" stroke-width="3.5"/>'
            f'<path d="M{cx + 7},{y - 132} C{cx + 46},{y - 88} {cx + 74},{y - 44} {cx + 80},{y - 12} L{cx + 7},{y - 12} Z" fill="{CREAM}"/>'
            f'<path d="M{cx - 7},{y - 120} L{cx - 7},{y - 12} L{cx - 66},{y - 12} C{cx - 48},{y - 52} {cx - 28},{y - 92} {cx - 7},{y - 120} Z" fill="{GOLD}"/>'
            f'<path d="M{cx + 36},{y - 92} C{cx + 52},{y - 68} {cx + 60},{y - 46} {cx + 63},{y - 30}" fill="none" stroke="#E6D3AE" stroke-width="4"/>'
            f'<path d="M{cx - 88},{y} L{cx + 92},{y} L{cx + 66},{y + 40} L{cx - 64},{y + 40} Z" fill="{RED}"/>'
            f'<path d="M{cx - 80},{y + 12} L{cx + 84},{y + 12}" stroke="{CREAM}" stroke-width="4"/>'
            f'</g>')


def meer():
    s = [stars(23, 30, avoid=[(205, 280, 325, 395), (120, 420, 320, 660), (700, 340, 990, 660)])]
    s.append(title_arcs())
    s.append(crescent(265, 335, 42, 0.5))
    s.append(sparkle(300, 300, 8))
    s.append(gull(712, 318) + gull(748, 296, 0.8) + gull(870, 520, 0.9))
    s.append(lighthouse(805, 640, 470))
    s.append(sailboat(212, 642))
    s.append(wave_band(668, 20, 104, TEAL_L, 10))
    s.append(wave_band(748, 24, 128, TEAL, 52))
    s.append(wave_band(830, 26, 150, TEAL_D, 20))
    s.append(wave_band(912, 26, 172, DEEP, 80, foam=True))
    return "".join(s)


# ------------------------------------------------------------------ Traumnacht
def convex_hull(p):
    p = sorted(set(p))
    def cross(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])
    lo, up = [], []
    for q in p:
        while len(lo) >= 2 and cross(lo[-2], lo[-1], q) <= 0: lo.pop()
        lo.append(q)
    for q in reversed(p):
        while len(up) >= 2 and cross(up[-2], up[-1], q) <= 0: up.pop()
        up.append(q)
    return lo[:-1] + up[:-1]


def cloud_bank(circles):
    out = [f'<circle cx="{x}" cy="{y}" r="{r}" fill="{INK}" stroke="{INK}" stroke-width="12"/>' for x, y, r in circles]
    out += [f'<circle cx="{x}" cy="{y}" r="{r}" fill="{CREAM}"/>' for x, y, r in circles]
    hull = convex_hull([(x, y) for x, y, _ in circles])
    out.append(f'<polygon points="{pts(hull)}" fill="{CREAM}"/>')
    out += [f'<path d="M{x - r * 0.55},{y - r * 0.35} A{r * 0.7} {r * 0.7} 0 0 1 {x + r * 0.1},{y - r * 0.7}" fill="none" stroke="#FFFFFF" stroke-width="5" stroke-linecap="round" opacity="0.7"/>'
            for x, y, r in circles[:3]]
    return "".join(out)


def ladder(x0, y0, x1, y1, w=34, rungs=8):
    dx, dy = x1 - x0, y1 - y0
    L = math.hypot(dx, dy)
    nx, ny = -dy / L * w / 2, dx / L * w / 2
    a0, a1 = (x0 + nx, y0 + ny), (x1 + nx, y1 + ny)
    b0, b1 = (x0 - nx, y0 - ny), (x1 - nx, y1 - ny)
    lines = [f"M{f(a0[0])},{f(a0[1])} L{f(a1[0])},{f(a1[1])}", f"M{f(b0[0])},{f(b0[1])} L{f(b1[0])},{f(b1[1])}"]
    for i in range(1, rungs + 1):
        t = i / (rungs + 1)
        lines.append(f"M{f(a0[0] + (a1[0] - a0[0]) * t)},{f(a0[1] + (a1[1] - a0[1]) * t)} "
                     f"L{f(b0[0] + (b1[0] - b0[0]) * t)},{f(b0[1] + (b1[1] - b0[1]) * t)}")
    d = " ".join(lines)
    return (f'<path d="{d}" stroke="{INK}" stroke-width="12" stroke-linecap="round"/>'
            f'<path d="{d}" stroke="{GOLD}" stroke-width="5" stroke-linecap="round"/>')


def traumnacht():
    s = [f'<defs><linearGradient id="trail" x1="0" y1="0" x2="1" y2="0">'
         f'<stop offset="0" stop-color="{GOLD}" stop-opacity="0.95"/><stop offset="1" stop-color="{GOLD}" stop-opacity="0"/>'
         f'</linearGradient></defs>']
    s.append(stars(37, 46, avoid=[(130, 320, 335, 530), (680, 240, 880, 470), (700, 480, 930, 640)]))
    s.append(title_arcs())
    # moon with craters
    s.append(crescent(236, 425, 92, 0.52))
    s.append(f'<circle cx="170" cy="400" r="9" fill="#E3D0A8"/><circle cx="178" cy="462" r="6" fill="#E3D0A8"/>'
             f'<circle cx="196" cy="358" r="5" fill="#E3D0A8"/>')
    # ladder to the moon
    s.append(ladder(282, 780, 214, 470, 34, 8))
    # constellation
    cst = [(690, 306), (728, 268), (770, 300), (748, 342)]
    s.append(f'<polyline points="{pts(cst + [cst[0]])}" fill="none" stroke="{CREAM}" stroke-width="2" opacity="0.7"/>')
    s.append("".join(f'<circle cx="{x}" cy="{y}" r="4.5" fill="{GOLD}" stroke="{INK}" stroke-width="2"/>' for x, y in cst))
    # ringed planet
    s.append(f'<g transform="translate(778 418) rotate(-18)">'
             f'<ellipse rx="90" ry="22" fill="none" stroke="{INK}" stroke-width="13"/>'
             f'<ellipse rx="90" ry="22" fill="none" stroke="{GOLD}" stroke-width="6"/>'
             f'<circle r="46" fill="{TEAL}" stroke="{INK}" stroke-width="5"/>'
             f'<path d="M-44,-12 C-20,-4 20,-4 44,-12 M-40,20 C-14,26 14,26 40,20" fill="none" stroke="{TEAL_L}" stroke-width="7" stroke-linecap="round"/>'
             f'<path d="M-90,0 A90 22 0 0 0 90,0" fill="none" stroke="{INK}" stroke-width="13"/>'
             f'<path d="M-90,0 A90 22 0 0 0 90,0" fill="none" stroke="{GOLD}" stroke-width="6"/>'
             f'<circle r="46" fill="none" stroke="{INK}" stroke-width="0"/>'
             f'</g>')
    # shooting star
    s.append(f'<polygon points="{pts([(738, 594), (912, 498), (742, 608)])}" fill="url(#trail)"/>'
             f'<path d="M760,606 L880,540" stroke="{CREAM}" stroke-width="2.5" stroke-linecap="round" opacity="0.7"/>')
    s.append(sparkle(738, 601, 17) + f'<circle cx="738" cy="601" r="4" fill="#FFF3D6"/>')
    # cloud banks
    left = [(110, 790, 62), (186, 760, 54), (262, 788, 50), (330, 826, 40), (150, 852, 70), (250, 858, 58), (60, 870, 60), (330, 878, 40)]
    s.append(cloud_bank(left))
    s.append(cloud_bank([(1000 - x, y + 14, r) for x, y, r in left]))
    return "".join(s)


# ------------------------------------------------------------------ Horizont
def horizont():
    hy = 640
    s = [f'<defs><linearGradient id="sunG" x1="0" y1="0" x2="0" y2="1">'
         f'<stop offset="0" stop-color="{GOLD}"/><stop offset="0.55" stop-color="{RED_L}"/><stop offset="1" stop-color="{RED}"/>'
         f'</linearGradient>'
         f'<clipPath id="sky"><rect x="0" y="0" width="1000" height="{hy}"/></clipPath></defs>']
    s.append(stars(51, 40, avoid=[(690, 290, 790, 380), (150, 400, 860, 650)]))
    s.append(title_arcs())
    s.append(crescent(740, 335, 32, 0.5))
    # retro sun
    stripes = "".join(f'<rect x="200" y="{y}" width="600" height="{h}" fill="{INK}"/>'
                      for y, h in [(548, 5), (574, 8), (600, 11), (624, 14)])
    s.append(f'<g clip-path="url(#sky)"><circle cx="500" cy="{hy}" r="235" fill="url(#sunG)" stroke="{INK}" stroke-width="5"/>{stripes}</g>')
    # mountains on the horizon
    s.append(mountain(140, 470, -70, 345, hy, TEAL_L, TEAL, 0.25))
    s.append(mountain(860, 482, 650, 1070, hy, TEAL_L, TEAL, 0.25))
    s.append(mountain(290, 548, 180, 410, hy, TEAL_D, DEEP, 0.22))
    s.append(mountain(770, 556, 668, 880, hy, TEAL_D, DEEP, 0.22))
    # sea
    s.append(f'<rect x="0" y="{hy}" width="1000" height="{1000 - hy}" fill="{DEEP}"/>')
    for i, (w, h) in enumerate([(430, 9), (380, 9), (320, 8), (260, 8), (200, 7), (150, 6)]):
        y = hy + 20 + i * 30
        col = GOLD if i % 2 == 0 else RED_L
        s.append(f'<rect x="{500 - w / 2}" y="{y}" width="{w}" height="{h}" rx="{h / 2}" fill="{col}"/>')
    for x, y, w in [(90, 690, 70), (180, 760, 90), (70, 820, 60), (250, 880, 70), (820, 700, 80), (900, 780, 60), (760, 850, 90), (860, 900, 50)]:
        s.append(f'<path d="M{x - w / 2},{y} q{w / 8},-8 {w / 4},0 t{w / 4},0 t{w / 4},0 t{w / 4},0" fill="none" stroke="{TEAL_L}" stroke-width="4" stroke-linecap="round"/>')
    s.append(f'<path d="M0,{hy} H1000" stroke="{INK}" stroke-width="5"/>')
    # little boat on the horizon
    s.append(f'<g stroke="{INK}" stroke-width="3.5" stroke-linejoin="round">'
             f'<path d="M772,{hy + 6} V{hy - 46}" stroke-width="4"/>'
             f'<path d="M776,{hy - 44} L776,{hy - 2} L804,{hy - 2} Z" fill="{CREAM}"/>'
             f'<path d="M768,{hy - 36} L768,{hy - 2} L748,{hy - 2} Z" fill="{GOLD}"/>'
             f'<path d="M742,{hy} L810,{hy} L800,{hy + 14} L752,{hy + 14} Z" fill="{RED}"/></g>')
    # birds across the sun
    s.append(gull(350, 512, 1.0, INK) + gull(386, 538, 0.8, INK))
    return "".join(s)


def f2(x):
    return f"{x:.2f}".rstrip("0").rstrip(".")


def leaf(x, y, length, angle, width=0.52):
    """two-tone leaf, base at (x,y), pointing along angle (deg, 0 = up)."""
    L = 100
    W = 50 * width / 0.5
    sc = length / L
    return (
        f'<g transform="translate({f2(x)} {f2(y)}) rotate({f2(angle)}) scale({f2(sc)})">'
        f'<path d="M0,0 C{-W*0.55},{-L*0.25} {-W*0.55},{-L*0.75} 0,{-L} Z" fill="{TEAL_L}"/>'
        f'<path d="M0,0 C{W*0.55},{-L*0.25} {W*0.55},{-L*0.75} 0,{-L} Z" fill="{TEAL_D}"/>'
        f'<path d="M0,0 C{-W*0.55},{-L*0.25} {-W*0.55},{-L*0.75} 0,{-L} '
        f'C{W*0.55},{-L*0.75} {W*0.55},{-L*0.25} 0,0 Z M0,-4 C1,{-L*0.4} 0,{-L*0.7} 0,{-L*0.88}" '
        f'fill="none" stroke="{INK}" stroke-width="{f2(4.5/sc)}" stroke-linejoin="round" stroke-linecap="round"/>'
        f'</g>'
    )

def _sparkle_unused(x, y, r=11):
    a = r * 0.22
    return (f'<path transform="translate({x} {y})" fill="{GOLD}" '
            f'd="M0,{-r} C{a},{-a} {a},{-a} {r},0 C{a},{a} {a},{a} 0,{r} '
            f'C{-a},{a} {-a},{a} {-r},0 C{-a},{-a} {-a},{-a} 0,{-r} Z"/>')

skull = f'''<g transform="translate(234 360)">
      <path fill="{CREAM}" stroke="{INK}" stroke-width="4" stroke-linejoin="round"
        d="M-45,-6 C-45,-34 -24,-44 0,-44 C24,-44 45,-34 45,-6 C45,11 38,18 29,21 L27,33 C27,39 22,42 17,42 L-17,42 C-22,42 -27,39 -27,33 L-29,21 C-38,18 -45,11 -45,-6 Z"/>
      <ellipse cx="-17" cy="1" rx="11.5" ry="12.5" fill="{INK}"/>
      <ellipse cx="17" cy="1" rx="11.5" ry="12.5" fill="{INK}"/>
      <path d="M-5,23 L0,13 L5,23 Z" fill="{INK}" stroke="{INK}" stroke-width="2" stroke-linejoin="round"/>
      <path d="M-9,31 V42 M0,31 V42 M9,31 V42" stroke="{INK}" stroke-width="3.5" stroke-linecap="round"/>
    </g>'''

def daisy(cx, cy):
    petals = "".join(
        f'<ellipse cx="0" cy="-36" rx="13" ry="23" transform="rotate({i*30})"/>' for i in range(12))
    return (f'<g transform="translate({cx} {cy})">'
            f'<g fill="{GOLD}" stroke="{INK}" stroke-width="4">{petals}</g>'
            f'<circle r="19" fill="{INK}"/><circle r="13" fill="{TEAL_L}"/>'
            f'<circle cx="-4" cy="-4" r="3.5" fill="#BFF3EC"/></g>')

rose = f'''<g transform="translate(200 524)" stroke="{INK}" stroke-width="5" stroke-linejoin="round" stroke-linecap="round">
      <!-- back silhouette -->
      <path fill="{RED_D}" d="M-142,8 C-150,-42 -110,-82 -60,-76 C-40,-106 40,-106 60,-76 C110,-82 150,-42 142,8 C136,60 90,102 0,104 C-90,102 -136,60 -142,8 Z"/>
      <!-- side petals -->
      <path fill="{RED}" d="M-142,8 C-140,-34 -106,-66 -62,-62 C-82,-30 -84,12 -58,44 C-88,48 -124,36 -142,8 Z"/>
      <path fill="{RED}" d="M142,8 C140,-34 106,-66 62,-62 C82,-30 84,12 58,44 C88,48 124,36 142,8 Z"/>
      <!-- front petal -->
      <path fill="{RED_L}" d="M-112,40 C-74,74 74,74 112,40 C96,84 54,104 0,104 C-54,104 -96,84 -112,40 Z"/>
      <!-- cup -->
      <path fill="{RED}" d="M-72,-42 C-72,-84 72,-84 72,-42 C74,10 42,50 0,52 C-42,50 -74,10 -72,-42 Z"/>
      <!-- opening -->
      <path fill="{RED_D}" d="M-58,-50 C-56,-76 56,-76 58,-50 C56,-30 30,-22 0,-22 C-30,-22 -56,-30 -58,-50 Z"/>
      <!-- spiral and folds -->
      <path fill="none" d="M-34,-48 C-30,-66 30,-68 36,-50 C40,-38 18,-32 0,-34 C-14,-36 -16,-48 -4,-51 C8,-53 12,-45 6,-42"/>
      <path fill="{RED_L}" d="M-66,-14 C-44,14 44,14 66,-14 C60,22 30,46 0,48 C-30,46 -60,22 -66,-14 Z"/>
      <path fill="none" d="M-40,22 C-20,34 20,34 40,22"/>
      <!-- highlights -->
      <path fill="none" stroke="#FF9A70" stroke-width="5" d="M-120,-6 C-116,-28 -100,-44 -82,-50"/>
      <path fill="none" stroke="#FF9A70" stroke-width="5" d="M30,82 C50,80 70,72 84,62"/>
    </g>'''

stem = (f'<path d="M214,610 C222,660 240,700 256,740" fill="none" stroke="{INK}" stroke-width="15" stroke-linecap="round"/>'
        f'<path d="M214,610 C222,660 240,700 256,740" fill="none" stroke="{TEAL}" stroke-width="7" stroke-linecap="round"/>')

side = "\n    ".join([
    leaf(182, 462, 140, -10, 0.6),          # tall leaf behind rose
    stem,
    leaf(236, 640, 132, 62, 0.55),           # leaf to the right, rising
    leaf(222, 650, 120, 128, 0.52),          # leaf to the right, falling
    leaf(196, 638, 112, -132, 0.5),          # leaf to the left, falling
    rose,
    daisy(259, 772),
    skull,
    sparkle(326, 262), sparkle(356, 398, 10),
    f'<path d="M210,306 Q246,232 356,222" fill="none" stroke="{GOLD}" stroke-width="5" stroke-linecap="round"/>',
])



def rosen():
    """original badge: roses, leaves, daisies and skulls, mirrored left/right."""
    return (f'<defs><g id="side">{side}</g></defs>'
            '<use href="#side"/><use href="#side" transform="translate(1000 0) scale(-1 1)"/>')

SCENES = {"rosen": rosen, "gipfel": gipfel, "meer": meer, "traumnacht": traumnacht, "horizont": horizont}
