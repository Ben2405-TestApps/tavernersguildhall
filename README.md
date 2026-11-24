# Taverners Guild Hall

A central overview for The Taverners Guild addon suite.

## Install
Install TavernersCore and the addon modules you use, then place this folder in `Interface/AddOns/TavernersGuildHall`. Enable it in the AddOns list.

Use `/tgh` or `/guildhall` to open the dashboard. The `/taverners` alias is reserved by the Crafting Directory.

## Current dashboard
- Character, class, level and faction summary.
- Detects loaded Taverners modules (Quest Companion, Gear Guide, Dungeon Tool, Crafting Directory and Ammo Guard).
- Active quest count when Quest Companion is loaded.
- Guild roster online summary.
- Quick command reference and manual refresh.

The Hall is intentionally a dashboard rather than a second copy of every module's data. Each addon remains responsible for its own records and sync behaviour.

## Compatibility
Interface target 16001. Requires TavernersCore. Live WoW Forever testing is still required; roster and addon-module availability depend on the client APIs and which addons are enabled.
