# v0.1.4 - 2026-04-25

## Changes
- Fixed: Activities were hidden by default due to `hideCompleted = true`. Default is now `false`.
- Fixed: 100% completed activities now show a full progress bar labeled "Complete" instead of showing no bar (WoW removes requirementsList data after full completion).
- Fixed: Blizzard's native requirement text (e.g. "3 / 10 quests") is now hidden when ETL's own progress bar is active, preventing the two from visually stacking on top of each other. It is restored when ETL's bar is hidden.
- Fixed: ETL progress widgets now start hidden on creation, preventing a brief flash of un-positioned frames.
