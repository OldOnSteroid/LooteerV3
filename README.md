# LooteerV3

A Diablo IV loot automation plugin for QQT. Automatically picks up, filters, and prioritizes items based on customizable rules.

## Features

- **Smart loot filtering** — configurable thresholds for item power, greater affixes, rarity, and item type
- **Priority modes** — nearest item first, or best item first (by rarity/power)
- **Category toggles** — independently enable/disable boss materials, event items, goblin caches, sigils, gear, and more
- **Distance limiting** — only loot items within a configurable radius
- **D4Remote integration** — optionally reports loot statistics to D4Remote for web dashboard tracking
- **Renderer overlay** — optional on-screen display of current loot state

## Requirements

- QQT
- Diablo IV (PC)

## Installation

1. Copy the `LooteerV3` folder into your QQT `scripts` directory.
2. Launch QQT and enable **LooteerV3** in the plugin list.
3. Configure settings from the in-game menu.

## Configuration

All settings are accessible from the QQT in-game menu under **LooteerV3**:

| Setting | Description |
|---|---|
| Enabled | Master on/off toggle |
| Min Item Power | Ignore gear below this power level |
| Min GA Count (Legendary) | Minimum greater affixes required on legendary gear |
| Min GA Count (Unique) | Minimum greater affixes required on unique gear |
| Distance | Maximum pickup distance (meters) |
| Boss Materials | Pick up boss summoning materials |
| Event Items | Pick up event reward items |
| Goblin Cache | Pick up goblin caches |
| Loot Priority | Nearest-first or best-first |

## D4Remote Integration

LooteerV3 automatically integrates with D4Remote if the plugin is loaded. No configuration required — loot statistics are reported via `D4Remote.record_loot(category, rarity)` on each item pickup.

See the D4Remote Integration for details on building your own D4Remote-compatible plugin.

## Plugin API

Other plugins can read and write LooteerV3 settings at runtime:

```lua
-- Read a setting
local dist = LooteerPlugin.getSettings("distance")

-- Write a setting
LooteerPlugin.setSettings("enabled", false)
```

## File Structure

```
LooteerV3/
├── main.lua              # Entry point, loot handler, plugin API
├── gui.lua               # In-game menu
├── core/
│   ├── item_filter.lua   # Item classification and filtering logic
│   ├── loot_engine.lua   # Item selection and priority
│   ├── pathfinder.lua    # Movement to items
│   ├── renderer.lua      # On-screen overlay
│   └── settings.lua      # Settings manager
├── utils/
│   └── utils.lua         # Shared utilities
└── data/
    ├── defaults.lua      # Default settings values
    └── items.lua         # Item catalog (auto-updated)
```

## License

MIT
