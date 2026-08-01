# Atlas-OctoUI — fork notice

This addon is a fork of **Atlas-CFM**, restyled to match
[OctoUI](https://github.com/C4rcer/OctoUI) on the OctoWoW 1.12.1 server.

## Lineage and copyright

| | |
|---|---|
| **Atlas** | Dan Gilbert, map by Niflheim — the original addon this line descends from |
| **Atlas-CFM** | CFM — [github.com/byCFM2/Atlas-CFM](https://github.com/byCFM2/Atlas-CFM), v1.60, the direct parent of this fork |
| **Atlas-OctoUI** | this fork |

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
- Restyled to match OctoUI. *(In progress — see the commit history for detail.)*

## What is deliberately NOT changed

**Saved variable names**: `AtlasCFMOptions` and `AtlasCFMCharDB`. Renaming them would
silently discard every existing setting on first login for no benefit.

**Internal frame and table names**: `AtlasCFMFrame`, `AtlasCFM.*` and friends stay as
they are. They appear in the thousands, nothing a user types depends on them, and
renaming them would be a large diff whose only effect is risk. OctoUI made the same
call for the same reason — see the note at `Init.lua:22` in that repo, where the engine
table stays named `ElvUI` while everything user-facing does not.
