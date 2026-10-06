"""Turn the RatRoll art PNGs in ../art/ into the files the addon and the Forge site use.

    python tools/make_art.py

Needs Pillow 11.2 or newer (older versions write BLPs the game cannot read).
  art/icon.png       -> src/Media/icon.blp         (512, the addon icon)
  art/window-bg.png  -> src/Media/window-bg.blp    (512, behind the roll window)
  art/*.png          -> ../../apps/Okanor-s-Forge/images/ratroll/*.webp + icons/ratroll.webp
"""
import subprocess
import sys
from pathlib import Path

from PIL import Image

HERE = Path(__file__).resolve().parent.parent
ART = HERE / "art"
MEDIA = HERE / "src" / "Media"
PNG2BLP = HERE.parent / "Okanvil" / "scripts" / "png2blp_dxt5.py"
FORGE = HERE.parent.parent / "apps" / "Okanor-s-Forge" / "images"

# Forge page images: source -> (published path, width)
WEBP = {
    "icon.png": ("icons/ratroll.webp", 256),
    "banner.png": ("ratroll/banner.webp", 1600),
    "roll.png": ("ratroll/art-roll.webp", 1200),
    "softres.png": ("ratroll/art-softres.webp", 1200),
    "window-bg.png": ("ratroll/art-window.webp", 600),
    "og.png": ("ratroll/og.webp", 1200),
    "window-rat.png": ("ratroll/art-luck.webp", 1200),
}


def blp(src, dst):
    subprocess.run([sys.executable, str(PNG2BLP), str(src), str(dst), "512"], check=True)


def main():
    from PIL import __version__ as v
    if tuple(int(x) for x in v.split(".")[:2]) < (11, 2):
        sys.exit(f"Pillow {v} writes BLPs the game cannot read -- use 11.2 or newer")
    MEDIA.mkdir(parents=True, exist_ok=True)

    blp(ART / "icon.png", MEDIA / "icon.blp")

    # Behind the roll window: window-rat.png, 3 : 2, the rat on the right half and
    # the left half empty dark (painted that way, no text). Boot.lua's
    # ForgeArtStyle says aspect = 1.5 and the game crops from that, so the texture
    # can be squeezed into the 512 square a BLP needs: the texture coords stretch
    # it back. A new picture with another shape needs that aspect changed too.
    art = Image.open(ART / "window-rat.png").convert("RGB")
    low = art.resize((512, 512), Image.LANCZOS)
    tmp = ART / "_window-512.png"
    low.save(tmp)
    blp(tmp, MEDIA / "window-bg.blp")
    tmp.unlink()

    for name, (rel, width) in WEBP.items():
        im = Image.open(ART / name).convert("RGB")
        if im.width > width:
            im = im.resize((width, round(im.height * width / im.width)), Image.LANCZOS)
        out = FORGE / rel
        out.parent.mkdir(parents=True, exist_ok=True)
        im.save(out, "WEBP", quality=86, method=6)
    print("art done:", ", ".join(["icon.blp", "window-bg.blp"] + [r for r, _ in WEBP.values()]))


if __name__ == "__main__":
    main()
