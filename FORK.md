# Atlas-OctoUI — fork notice

This addon is a fork of **Atlas-CFM**, restyled to match
[OctoUI](https://github.com/C4rcer/OctoUI) on the OctoWoW 1.12.1 server.

## Lineage and copyright

| | |
|---|---|
| **Atlas** | Dan Gilbert, map by Niflheim — the original addon this line descends from, still credited in the corner of every map |
| **Atlas-TW** | [github.com/byCFM2/Atlas-TW](https://github.com/byCFM2/Atlas-TW) — the `upstream` remote of this repository |
| **Atlas-CFM** | CFM — [github.com/byCFM2/Atlas-CFM](https://github.com/byCFM2/Atlas-CFM), v1.60, the direct parent of this fork |
| **Atlas-OctoUI** | this fork |

The full upstream history is preserved in this repository rather than squashed, so every
change made here can be diffed against the original. `7a06bad` is the first commit of the
fork; anything before it is upstream's.

Copyright in the original work remains with its authors. This fork adds to it; it
does not replace their claim to it.

## Licence

**GNU General Public License, version 2 or later**, unchanged from upstream. See
`LICENSE`. That is not a choice this fork gets to make: Atlas-CFM is GPL-2+, so
anything derived from it is too.

Three consequences worth stating plainly, because they are easy to trip over:

1. **This addon must stay GPL-2+ and ship its source.** Being plain Lua, it does.
2. **Changes must be marked.** That is what the section below is for, and why it is
   kept current rather than written once.
3. **It must not be merged into OctoUI.** OctoUI is separately licensed, and combining
   the two into one distributed work would put the whole thing under the GPL. They are
   two addons that co-operate, and that is deliberate — not an accident of layout.

## Changes from Atlas-CFM v1.60

- Addon folder and TOC renamed `Atlas-CFM` → `Atlas-OctoUI`, and the two hardcoded
  paths in `CFMAtlas/AtlasConfig.lua` (`PATH`, `MAPPATH`) updated to match. Those two
  constants were the only place the folder name appeared.
- Removed `CFMAtlas/AtlaspfUI.lua` and its `AtlasInit.xml` entry. It was a pfUI
  styling layer, gated behind `IsAddOnLoaded("pfUI")`, and pfUI is not used here.
  Every call into it elsewhere in the addon is guarded with `if AtlasCFM.pfUI and ...`,
  so removing it turns those into no-ops rather than breaking them. The
  `AtlasCFMOptionPfUI` checkbox is created in `AtlasOptionsUI.lua`, survives, and
  already hides itself when pfUI is absent.
- `AtlasCFM.Name` in `CFMAtlas/AtlasConfig.lua` changed to `Atlas-OctoUI`. It doubles as
  the folder name, so leaving it stale made `GetAddOnMetadata(Name, "Version")` return nil
  — which crashed the load banner — and stopped the `ADDON_LOADED` comparison in
  `Atlas.lua` from ever matching. It is also the display name, so the rebrand comes free.
- Added `AtlasCFM.EnsureOptions()` and called it from `MinimapButtonInit` and the two map
  marker entry points. Those fire on `VARIABLES_LOADED` and `PLAYER_ENTERING_WORLD`, both
  of which can beat the addon's own defaults being written, and each indexed
  `AtlasCFMOptions` directly. **This is an upstream bug, not one the fork introduced** —
  it is simply invisible whenever a saved variables file already exists. Upstream already
  works around it in three places in `ProfessionHooks.lua` with
  `if not AtlasCFMOptions then AtlasCFMOptions = {} end`; this does the same thing with
  real defaults, in one place.
- **Named thirteen previously anonymous buttons.** The search cluster in
  `CFMLoot/LootUI.lua` (Search, Search Options, Clear, Last Result, WishList), the main
  window's buttons in `CFMAtlas/AtlasUI.lua` (Search, Clear, Options, Quests toggle, Show
  Panel) and the options window's three in `CFMAtlas/AtlasOptionsUI.lua` were all
  `CreateFrame("Button", nil, ...)`. Without a global name nothing outside the function
  that built them can reach them — which is why skinning this addon from OctoUI could
  never touch the bottom bar. Names only; no behaviour changed.
- **Added `CFMAtlas/AtlasOctoStyle.lua`**, loaded last, replacing the pfUI layer that was
  removed. Applies OctoUI's templates to every window, button, edit box, check box and
  slider by name. It no-ops if OctoUI is absent, so the addon still runs standalone —
  just unstyled.

  `AtlasCFMFrame` is deliberately excluded from the window backdrops: the map is a
  BACKGROUND texture on that frame, so a backdrop drawn on it covers and dims the map.
  The five edge frames carry the window art and are stripped instead. Item rows get a
  texcoord trim only — they carry their own icon and text and look wrong in a button
  backdrop. Each widget is styled inside its own `pcall`, so one that cannot take a skin
  costs itself and not everything after it in the list.

## Note for anyone renaming this addon again

**Saved variables are stored per addon NAME, not per variable name.** Keeping
`AtlasCFMOptions` and `AtlasCFMCharDB` in the TOC preserves nothing on its own — WoW looks
for `WTF/Account/<ACCOUNT>/SavedVariables/<AddonName>.lua`, so a rename orphans the old
file and the next login is a first run. Copy both files across, with the game fully closed:

```
WTF/Account/<ACCOUNT>/SavedVariables/Atlas-CFM.lua
WTF/Account/<ACCOUNT>/<Realm>/<Character>/SavedVariables/Atlas-CFM.lua
```

## What is deliberately NOT changed

**Saved variable names**: `AtlasCFMOptions` and `AtlasCFMCharDB`. Renaming them would
silently discard every existing setting on first login for no benefit.

**Internal frame and table names**: `AtlasCFMFrame`, `AtlasCFM.*` and friends stay as
they are. They appear in the thousands, nothing a user types depends on them, and
renaming them would be a large diff whose only effect is risk. OctoUI made the same
call for the same reason — see the note at `Init.lua:22` in that repo, where the engine
table stays named `ElvUI` while everything user-facing does not.
