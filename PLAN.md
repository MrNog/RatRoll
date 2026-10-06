# RatRoll — plan

## Status (2026-10-06)
- **Released**: v0.1.0 on GitHub (MrNog/RatRoll), page on Okanor's Forge. Every push to main
  releases (same keywords as Okanvil) and posts to the Forge Discord (`LOG_WEBHOOK_FORGE`).
- Done: steps 1–4. `python build.py` writes `RatRoll/` (the folder players install);
  hand-written parts are in `src/` (Guard, Boot, .toc). Installed on the HD client.
- Art done: PNGs in `art/`, `python tools/make_art.py` (Pillow 11.2+) makes `src/Media/icon.blp`,
  `window-bg.blp` and the Forge webps in `apps/Okanor-s-Forge/images/ratroll/`.
- Next: step 5 (in-game test), the Forge page itself (mock first), step 6 (release).
- Art: `apps/rats/docs/art/addon/ratroll-icon.md` + `ratroll-forge.md` (Forge page).

A small standalone 3.3.5a addon for raiders who don't want the full Okanvil:
the **mini roll**, **master loot**, and **soft reserves**. No council, no
guild/PuG/notes, no main window.

## Goals

- A raider installs RatRoll only and can roll MS/OS, see SR tags and get trades.
- An ML with RatRoll can run loot alone: roll, award, trade, load the SR CSV.
- **Same protocol as Okanvil.** Mixed raids just work. An ML on Okanvil sees
  RatRoll raiders, and the other way around.
- Never conflicts with Okanvil when both are installed.

## Not in RatRoll

Council (ask, vote, board), LootPrio, attendance, guild, ranking, PuG, notes,
logs, IDs, the main window, Setup, Settings page.

## How it is built: generated, not forked

RatRoll is **built from Okanvil source** by a script, so the roll, loot and SR
code never drifts and the protocol stays the same.

`build.py` (in this repo, reads `../Okanvil/Okanvil`; run `python build.py`):

1. Copy the file list below into `wow-addons/RatRoll/` (sources stay in Okanvil).
2. Rewrite the namespace: global `Okanvil` → `RatRoll`
   (`local Okanvil = RatRoll` at the top of each file, so module code is unchanged).
3. Rename SavedVariables: `Okanvil_DB` → `RatRoll_DB`, `Okanvil_CharDB` → `RatRoll_CharDB`.
4. Rename slash commands: `/okroll` → `/rr`, `/okres` → `/rrsr`, `/oktrade` → `/rrtrade`.
   Drop the dev ones (`/okloottest`, `/okcomms`, `/okfocus`).
5. **Keep** the comms prefix `OKANVIL` and every message format. That is the interop.
6. Write `RatRoll.toc` with its own version, then run `luac -p` on every file.

### Files

| Group  | Files |
|--------|-------|
| Libs   | LibStub, CallbackHandler, AceComm + ChatThrottleLib, LibDeflate, LibSharedMedia |
| Core   | Core.lua, Util.lua, Comms.lua, Widgets.lua |
| Data   | Bosses-Data, ItemBoss-Data, RaidLoot-Data, Proficiency-Data |
| Loot   | Loot.lua, LootSync.lua, LootRoll.lua, LootTrade.lua |
| SR     | SoftRes.lua, SoftRes-UI.lua |
| New    | RatRoll-Guard.lua (loads first), RatRoll-Boot.lua (loads last) |

## Steps

### 1. SR "Load CSV" button (done in Okanvil first)
- A **Load CSV** button in the SR panel header opens a small paste box with
  Import and Cancel, which calls `SR.Import()`.
- ML only. Raiders get the list through the existing SR share.
- Never auto-focus the box. Esc, a click outside, combat or hiding the panel
  clears focus.
- Full Okanvil gets the button too, so there is one code path.
- A **Clear** button in the mini roll title bar, for **everyone** (raider and ML).
  It throws away only **your own** saved list: the drops, rolls and SR list.
  - **Local only.** Nothing is sent, so the ML clearing never clears anyone else.
  - Confirm with two clicks: the first turns the button red ("Sure?") for 3s,
    the second clears. No dialog.

### 2. Make Core work without the shell
- Loot list: everyone records the drops they see and keeps them across reloads
  and logouts until they press Clear. There is no auto-wipe on a new raid.
- Core.lua must boot without Shell, Setup or Page_*. Calls such as
  `ShowSetup` and `ShowPanel` already check first; verify the rest.
- `ModuleActive("__loot")` must be true by default in RatRoll.
- `/rr` with no arguments toggles the mini roll, and `/rr config` prints the
  few options (chat roll buttons, scale).

### 3. Guard and boot
- **RatRoll-Guard.lua**: if Okanvil is loaded, print one line ("Okanvil is
  installed — RatRoll is off") and stop. Each file starts with
  `if not RatRoll then return end`, and the guard clears `RatRoll` when that
  happens.
- **RatRoll-Boot.lua**: sets the defaults for a raider and an ML. No minimap
  button, no popups, no prompts (passive).

### 4. Version check
- The VERQ reply says `RatRoll x.y.z` rather than Okanvil, so the ML's
  "Check group versions" shows who is on which.
- Same rule as Okanvil: the checker alone gets a toast, never message anyone else.

### 5. Build and test in game (HD client)
- Raider solo: load, `/rr`, an SR tooltip tag, no Lua errors (`/okerr` is
  renamed to `/rrerr`).
- Mixed group: ML on Okanvil with a raider on RatRoll, then the other way.
  Roll, award, trade, SR share.
- Both installed: the guard turns RatRoll off cleanly.
- Fix any call into a missing module that isn't nil-checked, **in Okanvil
  source**, then rebuild.

### 6. Release
- Its own repo under `wow-addons/RatRoll` (pushed with Fork), with the
  all-rights-reserved LICENSE.
- The Okanvil release pipeline gets a step that runs the build and zips
  RatRoll on a push to main, when any RatRoll file changed.
- Its own Discord post line, or a footnote on the Okanvil post (decide later).

## Decisions
- **Everyone keeps their own loot list until they clear it.** Raider or ML,
  the drops stay saved (you raid a PuG and log off, and next time you open
  RatRoll the last raid's items are still there). Each person decides when to
  press Clear, and it only clears their own list.
- **Its own icon.** Prompt: `apps/rats/docs/art/addon/ratroll-icon.md`.
  A rat blowing on two dice in its fist (the lucky roll). It becomes a 512 BLP2 DXT5 with mips in
  `RatRoll/Media/` and shows in the mini roll title bar.
