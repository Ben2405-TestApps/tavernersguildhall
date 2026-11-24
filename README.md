# Taverners Guild Hall

A central overview for The Taverners Guild addon suite.

## Install
Install TavernersCore and the addon modules you use, then place this folder in `Interface/AddOns/TavernersGuildHall`. Enable it in the AddOns list.

Use `/tgh` or `/guildhall` to open the dashboard. Use `/tgh refresh` to refresh the overview. The `/taverners` alias is reserved by the Crafting Directory.

## Current dashboard
- Character, class, level and faction summary.
- One-click launch buttons for Quest Companion, Gear Guide, Dungeon Tool, Crafting Directory and Ammo Guard.
- Detects loaded Taverners modules and shows their availability.
- Active quest count and Gear Guide profile summary when those modules are loaded.
- Dungeon and raid catalogue summary.
- Guild roster online summary.

The Hall is intentionally a dashboard rather than a second copy of every module's data. Each addon remains responsible for its own records and sync behaviour.

## Integration
The Dungeon Tool merges the curated dungeon quest records exposed by Quest Companion into its own Quests and Map views. The Hall discovers modules through TavernersCore's shared module registry.

## Compatibility
Interface target 16001. Requires TavernersCore. Live WoW Forever testing is still required; roster and addon-module availability depend on the client APIs and which addons are enabled.


## Guild services (0.2.0)

The Guild Hall dashboard now includes local noticeboard posts, a local guild-bank contribution ledger, manual PvP records, an adventure-goal checklist, a local event calendar and a local group-finder board. Commands:

- `/tgh note add <message>`
- `/tgh bank add <item> <quantity> [deposit/withdrawal]`
- `/tgh goal add <goal>` and `/tgh goal done <number>`
- `/tgh event add <date> <time> <title>`
- `/tgh group add <role> <dungeon>`
- `/tgh pvp win`, `/tgh pvp loss`, `/tgh pvp honour <amount>`

These records are currently local to the character and are not shared with guild members. The ledger is not an authoritative live guild-bank balance.
