"""Build the RatRoll addon from Okanvil's source.

RatRoll is not a fork: its roll, loot and soft-reserve code IS Okanvil's, copied
here and renamed, so a fix made in Okanvil reaches RatRoll on the next build and
the two always speak the same addon-message protocol (the OKANVIL prefix is kept).

    python build.py            -> writes ./RatRoll/ (the folder players install)

Fix bugs in Okanvil, never in ./RatRoll/ -- it is wiped on every build.
Hand-written RatRoll files live in ./src/ (guard, boot, .toc, media).
"""
import re
import shutil
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
OKANVIL = HERE.parent / "Okanvil" / "Okanvil"
SRC = HERE / "src"
OUT = HERE / "RatRoll"

LIBS = [
    r"Libs\LibStub\LibStub.lua",
    r"Libs\CallbackHandler-1.0\CallbackHandler-1.0.lua",
    r"Libs\AceComm-3.0\ChatThrottleLib.lua",
    r"Libs\AceComm-3.0\AceComm-3.0.lua",
    r"Libs\LibDeflate\LibDeflate.lua",
    r"Libs\LibSharedMedia-3.0\LibSharedMedia-3.0.lua",
]

# Okanvil files that make up RatRoll, in Okanvil's load order.
FILES = [
    r"Core\Core.lua",
    r"Core\Util.lua",
    r"Core\Comms.lua",
    r"Core\Widgets.lua",
    r"Modules\Bosses-Data.lua",
    r"Modules\ItemBoss-Data.lua",
    r"Modules\Proficiency-Data.lua",
    r"Modules\SoftRes.lua",
    r"Modules\Loot.lua",
    r"Modules\LootSync.lua",
    r"Modules\LootRoll.lua",
    r"Modules\SoftRes-UI.lua",
    r"Modules\LootTrade.lua",
    r"Modules\RaidLoot-Data.lua",
]

MEDIA = []   # Okanvil media RatRoll needs (its own art is in src/Media)

# Slash commands: the two used every raid get short names, the rest /okX -> /rrX.
SLASH = {"okroll": "rr", "okres": "rrsr", "okanvil": "ratroll"}

GUARD = "if RATROLL_OFF then return end"


def rename(text):
    text = text.replace('"Okanvil - Roll"', '"RatRoll"')
    text = re.sub(r"/ok([a-z]+)", lambda m: "/" + SLASH.get("ok" + m.group(1), "rr" + m.group(1)), text)
    # The addon-message prefix is "OKANVIL" (upper case) and is NOT touched:
    # that is what lets RatRoll and Okanvil talk to each other.
    return text.replace("Okanvil", "RatRoll")


def add_guard(text, rel):
    # On line 1, so error line numbers stay the same as in Okanvil's source.
    first, nl, rest = text.partition("\n")
    first = first.lstrip("﻿")
    if first.startswith("--"):
        first = f"{GUARD} -- generated from Okanvil/{rel.replace(chr(92), '/')}, edit there. {first[2:]}"
    else:
        first = f"{GUARD} {first}"
    return first + nl + rest


def check_order():
    """Every FILES entry must keep Okanvil's relative load order."""
    toc = (OKANVIL / "Okanvil.toc").read_text(encoding="utf-8-sig").splitlines()
    order = [l.strip() for l in toc if l.strip() and not l.startswith("#")]
    pos = [order.index(f) for f in FILES]
    if pos != sorted(pos):
        sys.exit("FILES is out of Okanvil's .toc order -- fix the list in build.py")


def main():
    check_order()
    if OUT.exists():
        shutil.rmtree(OUT)
    OUT.mkdir()

    for rel in LIBS:
        dst = OUT / rel
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(OKANVIL / rel, dst)

    for rel in FILES:
        text = (OKANVIL / rel).read_text(encoding="utf-8-sig")
        dst = OUT / rel
        dst.parent.mkdir(parents=True, exist_ok=True)
        dst.write_text(add_guard(rename(text), rel), encoding="utf-8", newline="")

    (OUT / "Media").mkdir()
    for name in MEDIA:
        shutil.copy2(OKANVIL / "Media" / name, OUT / "Media" / name)
    # RatRoll's window art (Boot.lua points W.ForgeArt at it)
    shutil.copy2(SRC / "Media" / "window-bg.blp", OUT / "Media" / "window-bg.blp")
    icon = r"Interface\\Icons\\INV_Misc_Dice_01"
    if (SRC / "Media" / "icon.blp").exists():
        shutil.copy2(SRC / "Media" / "icon.blp", OUT / "Media" / "icon.blp")
        icon = r"Interface\\AddOns\\RatRoll\\Media\\icon"

    shutil.copy2(SRC / "Guard.lua", OUT / "Guard.lua")
    boot = (SRC / "Boot.lua").read_text(encoding="utf-8").replace("{{ICON}}", icon)
    (OUT / "Boot.lua").write_text(boot, encoding="utf-8", newline="")
    toc = (SRC / "RatRoll.toc").read_text(encoding="utf-8")
    toc = toc.replace("{{FILES}}", "\n".join(LIBS + FILES))
    (OUT / "RatRoll.toc").write_text(toc.replace("\r\n", "\n").replace("\n", "\r\n"), encoding="utf-8", newline="")
    shutil.copy2(HERE / "LICENSE", OUT / "LICENSE")

    luac = shutil.which("luac5.1") or shutil.which("luac")
    if luac:
        bad = 0
        for f in OUT.rglob("*.lua"):
            r = subprocess.run([luac, "-p", str(f)], capture_output=True, text=True)
            if r.returncode:
                bad += 1
                print(r.stderr.strip())
        if bad:
            sys.exit(f"{bad} file(s) failed to parse")
    # Line 1 names the Okanvil source on purpose; anything after it is a miss.
    left = [rel for rel in FILES
            if "Okanvil" in (OUT / rel).read_text(encoding="utf-8").partition("\n")[2]]
    print(f"RatRoll built: {len(FILES)} files from Okanvil, icon {'custom' if 'AddOns' in icon else 'placeholder'}.")
    if left:
        print("note: 'Okanvil' still appears in:", ", ".join(left))


if __name__ == "__main__":
    main()
