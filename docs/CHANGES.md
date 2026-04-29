# v0.1.6 - 2026-04-28

## Bug Fixes

- **Progress bars never installed**: `OnAddonLoaded` used the wrong callback
  signature for RGX-Framework. RGX dispatches handlers as `(event, ...)`, so
  the actual addon name arrives as the second argument. The handler was
  reading `"ADDON_LOADED"` as the addon name, causing the
  `Blizzard_EncounterJournal` check to fail every time and `Install()` to
  never run. Bars now attach as soon as the Encounter Journal loads.
- **Minimap click landed on the wrong tab**: The RGX refactor replaced the
  v0.1.4 `OpenTravelersLog` flow with a heuristic text-search that just
  re-opened whatever Encounter Journal tab was last shown. Restored the
  proper Blizzard sequence — `EncounterJournal_LoadUI` →
  `EncounterJournal_OpenJournal` → `MonthlyActivitiesFrame_OpenFrame` — so
  clicking the minimap always lands on Monthly Activities. Tab fallback
  (`MonthlyActivitiesTab` / `TravelersLogTab`) preserved for older clients.

## Styling

- TOC title now ends with a trailing `!` and notes follow the
  `[RGX] By DonnieDice` pattern shared with SQP and RND.
- Title, notes, and minimap tooltip branding now use `#bc6fa8` so they match
  the progress-bar texture color.
- Minimap tooltip title uses the same letter-coloring as the TOC and drops
  the redundant description line.
