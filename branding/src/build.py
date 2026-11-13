#!/usr/bin/env python3
"""Regenerate every Memento Mori brand asset.

    python branding/src/build.py              # SVGs + PNG/ICO exports
    python branding/src/build.py --svg-only   # just the SVG sources
    python branding/src/build.py --remain 40 --lived 40

Needs: fonttools, shapely, pillow, and either the `rsvg-convert` CLI (librsvg)
or the `cairosvg` Python package for the PNG exports.
"""
import argparse
import os
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import mementomori as mm  # noqa: E402

ROOT = os.path.dirname(HERE)          # branding/
VARIANTS = ["horizont", "rosen", "gipfel", "meer", "traumnacht"]
MAIN = "horizont"


def write(rel, text):
    path = os.path.join(ROOT, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(text)
    return path


def render(svg_rel, png_rel, width, height=None, opaque=False):
    src = os.path.join(ROOT, svg_rel)
    dst = os.path.join(ROOT, png_rel)
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    height = height or width
    if shutil.which("rsvg-convert"):
        subprocess.run(["rsvg-convert", "-w", str(width), "-h", str(height), src, "-o", dst], check=True)
    else:
        import cairosvg
        cairosvg.svg2png(url=src, write_to=dst, output_width=width, output_height=height)
    if opaque:  # App Store / Play Store icons must not carry an alpha channel
        from PIL import Image
        im = Image.open(dst).convert("RGBA")
        bg = Image.new("RGB", im.size, mm.INK)
        bg.paste(im, mask=im.split()[3])
        bg.save(dst)
    return dst


def build_svgs():
    write("logo.svg", mm.badge(MAIN))
    for v in VARIANTS:
        write(f"variants/memento-mori-{v}.svg", mm.badge(v))
    write("icon/app-icon.svg", mm.launcher_icon())
    write("icon/app-icon-maskable.svg", mm.launcher_icon(height_frac=0.68))
    write("icon/app-icon-simple.svg", mm.app_icon_simple())
    write("icon/adaptive-foreground.svg", mm.launcher_foreground())
    write("icon/adaptive-background.svg", mm.launcher_background())
    write("icon/adaptive-monochrome.svg", mm.adaptive_monochrome())
    write("icon/favicon.svg", mm.favicon())
    write("github/social-preview.svg", mm.social_preview(MAIN))
    write("github/social-preview-light.svg", mm.social_preview(MAIN, theme="light"))
    write("github/avatar-light.svg", mm.avatar(theme="light"))
    write("github/avatar-dark.svg", mm.avatar(theme="dark"))
    write("splash/splash-android12.svg", mm.splash_android12())


def build_exports():
    for w in (2048, 1024, 512, 256, 128):
        render("logo.svg", f"exports/logo/logo-{w}.png", w)
    for v in VARIANTS:
        render(f"variants/memento-mori-{v}.svg", f"exports/logo/variants/memento-mori-{v}-1024.png", 1024)

    # iOS / generic store icon (opaque, square, the OS rounds the corners)
    render("icon/app-icon.svg", "exports/app/app-icon-1024.png", 1024, opaque=True)
    # Android adaptive icon layers + Play Store listing icon
    render("icon/adaptive-foreground.svg", "exports/android/adaptive-foreground-1024.png", 1024)
    render("icon/adaptive-background.svg", "exports/android/adaptive-background-1024.png", 1024, opaque=True)
    render("icon/adaptive-monochrome.svg", "exports/android/adaptive-monochrome-1024.png", 1024)
    render("icon/app-icon.svg", "exports/android/play-store-512.png", 512, opaque=True)

    # Web
    os.makedirs(os.path.join(ROOT, "exports/web"), exist_ok=True)
    shutil.copy(os.path.join(ROOT, "icon/favicon.svg"), os.path.join(ROOT, "exports/web/favicon.svg"))
    render("icon/favicon.svg", "exports/web/favicon-32.png", 32)
    render("icon/app-icon.svg", "exports/web/apple-touch-icon.png", 180, opaque=True)
    render("icon/app-icon.svg", "exports/web/icon-192.png", 192, opaque=True)
    render("icon/app-icon.svg", "exports/web/icon-512.png", 512, opaque=True)
    render("icon/app-icon-maskable.svg", "exports/web/icon-maskable-512.png", 512, opaque=True)
    from PIL import Image
    sizes = (16, 32, 48)
    frames = [Image.open(render("icon/favicon.svg", f"exports/web/.fav-{s}.png", s)) for s in sizes]
    frames[-1].save(os.path.join(ROOT, "exports/web/favicon.ico"), sizes=[(s, s) for s in sizes], append_images=frames[:-1])
    for s in sizes:
        os.remove(os.path.join(ROOT, f"exports/web/.fav-{s}.png"))

    # Splash (first launch): the badge, transparent outside the circle
    render("logo.svg", "exports/splash/splash-logo-768.png", 768)
    render("splash/splash-android12.svg", "exports/splash/splash-android12-1152.png", 1152)

    # GitHub
    render("github/social-preview.svg", "exports/github/social-preview-1280x640.png", 1280, 640, opaque=True)
    render("github/social-preview-light.svg", "exports/github/social-preview-light-1280x640.png", 1280, 640, opaque=True)
    render("github/avatar-light.svg", "exports/github/avatar-light-500.png", 500, opaque=True)
    render("github/avatar-dark.svg", "exports/github/avatar-dark-500.png", 500, opaque=True)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--svg-only", action="store_true")
    ap.add_argument("--remain", type=int, default=mm.REMAIN, help="years in the top bulb (default %(default)s)")
    ap.add_argument("--lived", type=int, default=mm.LIVED, help="years in the bottom bulb (default %(default)s)")
    a = ap.parse_args()
    mm.REMAIN, mm.LIVED = a.remain, a.lived
    build_svgs()
    if not a.svg_only:
        build_exports()
    print("done ->", ROOT)


if __name__ == "__main__":
    main()
