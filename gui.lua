local plugin_label = "LooteerV3"
local gui = {}
local ItemFilter = require("core.item_filter")

-- Track the previous frame's state of the reload checkbox so we trigger
-- load_catalog only on the false->true transition (one reload per click)
-- rather than every frame the box is checked.
local _last_reload_state = false

-- Dropdown labels. The combo's index is translated to the actual runtime
-- rarity threshold by Settings.update (see core/settings.lua).
local RARITIES  = { "Common", "Magic", "Rare", "Legendary", "Unique" }
-- Charms can drop at Set tier (Talisman_Charm_Set_*); other categories
-- can't, so the Set entry only appears in the charm dropdown.
local CHARM_RARITIES = { "Common", "Magic", "Rare", "Legendary", "Unique", "Set" }
local BEHAVIORS = { "Always", "Orbwalk" }

gui.elements = {
    main_tree   = tree_node:new(0),
    main_toggle = checkbox:new(false, get_hash(plugin_label .. "_main_toggle")),

    -- Click-to-reload catalog. Acts like a button: when checked, we trigger
    -- a reload and immediately reset to false on the next frame.
    reload_catalog_toggle = checkbox:new(false, get_hash(plugin_label .. "_reload_catalog_toggle")),
    web_config_toggle     = checkbox:new(false, get_hash(plugin_label .. "_web_config_toggle")),

    general = {
        tree                = tree_node:new(1),
        behavior_combo      = combo_box:new(0, get_hash(plugin_label .. "_behavior_combo")),
        loot_priority_combo = combo_box:new(0, get_hash(plugin_label .. "_loot_priority_combo")),
        rarity_combo        = combo_box:new(0, get_hash(plugin_label .. "_rarity_combo")),
        distance_slider     = slider_int:new(1, 30, 2, get_hash(plugin_label .. "_distance_slider")),
    },

    affix = {
        tree                             = tree_node:new(1),
        greater_affix_slider             = slider_int:new(0, 3, 0, get_hash(plugin_label .. "_greater_affix_slider")),
        unique_greater_affix_slider      = slider_int:new(0, 4, 0, get_hash(plugin_label .. "_unique_greater_affix_slider")),
        uber_unique_greater_affix_slider = slider_int:new(0, 4, 0, get_hash(plugin_label .. "_uber_unique_greater_affix_slider")),
        innerTree    = tree_node:new(1),
        custom_toggle= checkbox:new(false, get_hash(plugin_label .. "_custom_toggle")),
        armorsTree   = tree_node:new(1),
        jewelryTree  = tree_node:new(1),
        weaponsTree  = tree_node:new(1),
        oneHandedTree= tree_node:new(1),
        twoHandedTree= tree_node:new(1),
        offHandsTree = tree_node:new(1),
        -- armor
        legendary_helm_slider   = slider_int:new(0, 3, 2, get_hash(plugin_label .. "_legendary_helm_slider")),
        legendary_chest_slider  = slider_int:new(0, 3, 2, get_hash(plugin_label .. "_legendary_chest_slider")),
        legendary_gloves_slider = slider_int:new(0, 3, 2, get_hash(plugin_label .. "_legendary_gloves_slider")),
        legendary_pants_slider  = slider_int:new(0, 3, 2, get_hash(plugin_label .. "_legendary_pants_slider")),
        legendary_boots_slider  = slider_int:new(0, 3, 2, get_hash(plugin_label .. "_legendary_boots_slider")),
        unique_helm_slider      = slider_int:new(0, 4, 2, get_hash(plugin_label .. "_unique_helm_slider")),
        unique_chest_slider     = slider_int:new(0, 4, 2, get_hash(plugin_label .. "_unique_chest_slider")),
        unique_gloves_slider    = slider_int:new(0, 4, 2, get_hash(plugin_label .. "_unique_gloves_slider")),
        unique_pants_slider     = slider_int:new(0, 4, 2, get_hash(plugin_label .. "_unique_pants_slider")),
        unique_boots_slider     = slider_int:new(0, 4, 2, get_hash(plugin_label .. "_unique_boots_slider")),
        -- jewelry
        legendary_amulet_slider = slider_int:new(0, 3, 2, get_hash(plugin_label .. "_legendary_amulet_slider")),
        unique_amulet_slider    = slider_int:new(0, 4, 2, get_hash(plugin_label .. "_unique_amulet_slider")),
        legendary_ring_slider   = slider_int:new(0, 3, 2, get_hash(plugin_label .. "_legendary_ring_slider")),
        unique_ring_slider      = slider_int:new(0, 4, 2, get_hash(plugin_label .. "_unique_ring_slider")),
        -- offhands
        legendary_focus_slider  = slider_int:new(0, 3, 2, get_hash(plugin_label .. "_legendary_focus_slider")),
        legendary_totem_slider  = slider_int:new(0, 3, 2, get_hash(plugin_label .. "_legendary_totem_slider")),
        legendary_shield_slider = slider_int:new(0, 3, 2, get_hash(plugin_label .. "_legendary_shield_slider")),
        unique_shield_slider    = slider_int:new(0, 4, 2, get_hash(plugin_label .. "_unique_shield_slider")),
        -- 1h weapons
        legendary_1h_mace_slider  = slider_int:new(0, 3, 2, get_hash(plugin_label .. "_legendary_1h_mace_slider")),
        legendary_1h_sword_slider = slider_int:new(0, 3, 2, get_hash(plugin_label .. "_legendary_1h_sword_slider")),
        legendary_1h_axe_slider   = slider_int:new(0, 3, 2, get_hash(plugin_label .. "_legendary_1h_axe_slider")),
        legendary_dagger_slider   = slider_int:new(0, 3, 2, get_hash(plugin_label .. "_legendary_dagger_slider")),
        legendary_wand_slider     = slider_int:new(0, 3, 2, get_hash(plugin_label .. "_legendary_wand_slider")),
        unique_1h_mace_slider     = slider_int:new(0, 4, 2, get_hash(plugin_label .. "_unique_1h_mace_slider")),
        unique_1h_sword_slider    = slider_int:new(0, 4, 2, get_hash(plugin_label .. "_unique_1h_sword_slider")),
        unique_1h_axe_slider      = slider_int:new(0, 4, 2, get_hash(plugin_label .. "_unique_1h_axe_slider")),
        unique_dagger_slider      = slider_int:new(0, 4, 2, get_hash(plugin_label .. "_unique_dagger_slider")),
        unique_wand_slider        = slider_int:new(0, 4, 2, get_hash(plugin_label .. "_unique_wand_slider")),
        -- 2h weapons
        legendary_2h_mace_slider        = slider_int:new(0, 3, 2, get_hash(plugin_label .. "_legendary_2h_mace_slider")),
        legendary_2h_sword_slider       = slider_int:new(0, 3, 2, get_hash(plugin_label .. "_legendary_2h_sword_slider")),
        legendary_2h_axe_slider         = slider_int:new(0, 3, 2, get_hash(plugin_label .. "_legendary_2h_axe_slider")),
        legendary_2h_polearm_slider     = slider_int:new(0, 3, 2, get_hash(plugin_label .. "_legendary_2h_polearm_slider")),
        legendary_staff_slider          = slider_int:new(0, 3, 2, get_hash(plugin_label .. "_legendary_staff_slider")),
        legendary_bow_slider            = slider_int:new(0, 3, 2, get_hash(plugin_label .. "_legendary_bow_slider")),
        legendary_crossbow_slider       = slider_int:new(0, 3, 2, get_hash(plugin_label .. "_legendary_crossbow_slider")),
        legendary_glaive_slider         = slider_int:new(0, 3, 2, get_hash(plugin_label .. "_legendary_glaive_slider")),
        legendary_quarterstaff_slider   = slider_int:new(0, 3, 2, get_hash(plugin_label .. "_legendary_quarterstaff_slider")),
        unique_2h_mace_slider           = slider_int:new(0, 4, 2, get_hash(plugin_label .. "_unique_2h_mace_slider")),
        unique_2h_sword_slider          = slider_int:new(0, 4, 2, get_hash(plugin_label .. "_unique_2h_sword_slider")),
        unique_2h_axe_slider            = slider_int:new(0, 4, 2, get_hash(plugin_label .. "_unique_2h_axe_slider")),
        unique_2h_polearm_slider        = slider_int:new(0, 4, 2, get_hash(plugin_label .. "_unique_2h_polearm_slider")),
        unique_staff_slider             = slider_int:new(0, 4, 2, get_hash(plugin_label .. "_unique_staff_slider")),
        unique_bow_slider               = slider_int:new(0, 4, 2, get_hash(plugin_label .. "_unique_bow_slider")),
        unique_crossbow_slider          = slider_int:new(0, 4, 2, get_hash(plugin_label .. "_unique_crossbow_slider")),
        unique_glaive_slider            = slider_int:new(0, 4, 2, get_hash(plugin_label .. "_unique_glaive_slider")),
        unique_quarterstaff_slider      = slider_int:new(0, 4, 2, get_hash(plugin_label .. "_unique_quarterstaff_slider")),
    },

    types = {
        tree                  = tree_node:new(1),
        -- Per-type opt-out toggles
        quest_toggle          = checkbox:new(false, get_hash(plugin_label .. "_quest_toggle")),
        crafting_toggle       = checkbox:new(false, get_hash(plugin_label .. "_crafting_toggle")),
        boss_toggle           = checkbox:new(false, get_hash(plugin_label .. "_boss_toggle")),
        sigil_toggle          = checkbox:new(false, get_hash(plugin_label .. "_sigil_toggle")),
        compass_toggle        = checkbox:new(false, get_hash(plugin_label .. "_compass_toggle")),
        rune_toggle           = checkbox:new(false, get_hash(plugin_label .. "_rune_toggle")),
        cinders_toggle        = checkbox:new(false, get_hash(plugin_label .. "_cinders_toggle")),
        tribute_toggle        = checkbox:new(false, get_hash(plugin_label .. "_tribute_toggle")),
        scroll_toggle         = checkbox:new(false, get_hash(plugin_label .. "_scroll_toggle")),
        event_toggle          = checkbox:new(true,  get_hash(plugin_label .. "_event_toggle")),
        goblin_cache_toggle   = checkbox:new(true,  get_hash(plugin_label .. "_goblin_cache_toggle")),
        obols_toggle          = checkbox:new(true,  get_hash(plugin_label .. "_obols_toggle")),
        heavenly_sigil_toggle = checkbox:new(false, get_hash(plugin_label .. "_heavenly_sigil_toggle")),
        gemstone_toggle       = checkbox:new(false, get_hash(plugin_label .. "_gemstone_toggle")),
        cache_toggle          = checkbox:new(true,  get_hash(plugin_label .. "_cache_toggle")),
        consumable_toggle     = checkbox:new(false, get_hash(plugin_label .. "_consumable_toggle")),
        recipe_toggle         = checkbox:new(false, get_hash(plugin_label .. "_recipe_toggle")),
        -- Per-type minimum-rarity combos (0 = loot any rarity)
        sigil_rarity_combo      = combo_box:new(0, get_hash(plugin_label .. "_sigil_rarity_combo")),
        compass_rarity_combo    = combo_box:new(0, get_hash(plugin_label .. "_compass_rarity_combo")),
        tribute_rarity_combo    = combo_box:new(0, get_hash(plugin_label .. "_tribute_rarity_combo")),
        rune_rarity_combo       = combo_box:new(0, get_hash(plugin_label .. "_rune_rarity_combo")),
        gemstone_rarity_combo   = combo_box:new(0, get_hash(plugin_label .. "_gemstone_rarity_combo")),
        cache_rarity_combo      = combo_box:new(0, get_hash(plugin_label .. "_cache_rarity_combo")),
        scroll_rarity_combo     = combo_box:new(0, get_hash(plugin_label .. "_scroll_rarity_combo")),
        consumable_rarity_combo = combo_box:new(0, get_hash(plugin_label .. "_consumable_rarity_combo")),
        recipe_rarity_combo     = combo_box:new(0, get_hash(plugin_label .. "_recipe_rarity_combo")),
        crafting_rarity_combo   = combo_box:new(0, get_hash(plugin_label .. "_crafting_rarity_combo")),
    },

    -- "Always loot" categories — V2 hardcoded these as forced-loot. V3
    -- exposes them as opt-outs so users can stop picking up keys, glyphs,
    -- xp motes, etc. on alts where they don't care.
    always = {
        tree                     = tree_node:new(1),
        uber_toggle              = checkbox:new(true, get_hash(plugin_label .. "_uber_toggle")),
        keys_toggle              = checkbox:new(true, get_hash(plugin_label .. "_keys_toggle")),
        xp_powerup_toggle        = checkbox:new(true, get_hash(plugin_label .. "_xp_powerup_toggle")),
        glyph_drop_toggle        = checkbox:new(true, get_hash(plugin_label .. "_glyph_drop_toggle")),
        misc_trinkets_toggle     = checkbox:new(true, get_hash(plugin_label .. "_misc_trinkets_toggle")),
        boss_drops_toggle        = checkbox:new(true, get_hash(plugin_label .. "_boss_drops_toggle")),
        boss_drops_rarity_combo  = combo_box:new(0,   get_hash(plugin_label .. "_boss_drops_rarity_combo")),
        class_powerup_toggle     = checkbox:new(false, get_hash(plugin_label .. "_class_powerup_toggle")),
    },

    charm = {
        tree        = tree_node:new(1),
        toggle      = checkbox:new(false, get_hash(plugin_label .. "_charm_toggle")),
        rarity_combo= combo_box:new(0,    get_hash(plugin_label .. "_charm_rarity_combo")),
    },

    cube = {
        tree        = tree_node:new(1),
        toggle      = checkbox:new(false, get_hash(plugin_label .. "_cube_toggle")),
        rarity_combo= combo_box:new(0,    get_hash(plugin_label .. "_cube_rarity_combo")),
    },

    seal = {
        tree        = tree_node:new(1),
        toggle      = checkbox:new(false, get_hash(plugin_label .. "_seal_toggle")),
        rarity_combo= combo_box:new(0,    get_hash(plugin_label .. "_seal_rarity_combo")),
    },

    debug = {
        tree               = tree_node:new(1),
        draw_wanted_toggle = checkbox:new(false, get_hash(plugin_label .. "_draw_wanted_toggle")),
        scan_items_toggle  = checkbox:new(false, get_hash(plugin_label .. "_scan_items_toggle")),
        draw_path_toggle   = checkbox:new(false, get_hash(plugin_label .. "_draw_path_toggle")),
    },
}

-- Read the timestamp Updater.bat writes to data/last_sync.lua on every
-- successful fetch. This is the actual sync time, independent of when
-- Lua last reloaded the catalog into memory. Cached for 5s so we're not
-- hitting the filesystem on every render frame.
local _sync_cache = nil
local _sync_check_at = 0

local function _last_sync_epoch()
    local now = os.time()
    if now - _sync_check_at >= 5 then
        _sync_check_at = now
        package.loaded["data.last_sync"] = nil
        local ok, epoch = pcall(require, "data.last_sync")
        _sync_cache = (ok and type(epoch) == "number") and epoch or nil
    end
    return _sync_cache
end

local function _sync_age_str()
    local t = _last_sync_epoch()
    if not t then return "never synced" end
    local age = os.time() - t
    if age < 0      then return "synced just now"
    elseif age < 60 then return "synced just now"
    elseif age < 3600  then return "synced " .. tostring(math.floor(age / 60))   .. "m ago"
    elseif age < 86400 then return "synced " .. tostring(math.floor(age / 3600)) .. "h ago"
    else                    return "synced " .. tostring(math.floor(age / 86400)) .. "d ago"
    end
end

function gui.render()
    local e = gui.elements

    local catalog_loaded = ItemFilter._catalog_loaded
    local catalog_status
    if catalog_loaded then
        catalog_status = "catalog: v" .. tostring(ItemFilter._items_version)
            .. " (" .. _sync_age_str() .. ")"
    else
        catalog_status = "!! CATALOG NOT LOADED -- click Load Catalog !!"
    end
    if not e.main_tree:push("LooteerV3 | " .. catalog_status) then return end

    e.main_toggle:render("Enable", "Toggles the main module on/off")

    -- Load / reload catalog. Click triggers Updater.bat in one-shot mode
    -- (single fetch + exit) so the on-disk catalog is fresh, then reads
    -- it back into Lua memory. False->true transition pattern so the
    -- action only fires once per click; if the framework supports :set()
    -- we reset the checkbox so it visually acts like a button. Label
    -- flips between "Load" and "Reload" based on current state.
    local catalog_btn_label = catalog_loaded and "Reload Catalog" or "Load Catalog"
    local catalog_btn_tip   = catalog_loaded
        and "Run Updater.bat once to pull the latest items.lua from the cloud, "
            .. "then re-read it from disk. No need to keep Updater.bat running."
        or  "Run Updater.bat once to fetch items.lua, then load it. The repo "
            .. "ships with a pre-built catalog so this normally succeeds even "
            .. "without a server connection."
    e.reload_catalog_toggle:render(catalog_btn_label, catalog_btn_tip)
    local now_reload = e.reload_catalog_toggle:get()
    if now_reload and not _last_reload_state then
        ItemFilter.fetch_and_reload()
        pcall(function() e.reload_catalog_toggle:set(false) end)
        catalog_loaded = ItemFilter._catalog_loaded
    end
    _last_reload_state = e.reload_catalog_toggle:get()

    -- Catalog is mandatory. Without it, hide the rest of the UI so users
    -- can't accidentally configure settings against an empty catalog and
    -- expect loot to happen.
    if not catalog_loaded then
        e.main_tree:pop()
        return
    end

    -- Web config toggle: load data/config.lua and apply over GUI settings each frame
    local Settings = require("core.settings")
    local was_web = Settings._web_config ~= nil
    e.web_config_toggle:render("Use Web Config",
        "Apply loot settings downloaded from your cloud config URL. "
        .. "Run Updater.bat first, then check this to activate. "
        .. "Uncheck and recheck to reload after Updater syncs new settings.")
    local want_web = e.web_config_toggle:get()
    if want_web and not was_web then
        package.loaded["data.config"] = nil
        local ok, cfg = pcall(require, "data.config")
        if ok and type(cfg) == "table" then
            Settings._web_config = cfg
            console.print("[LooteerV3] Web config loaded from data/config.lua")
        else
            Settings._web_config = nil
            console.print("[LooteerV3] Web config not found — run Updater.bat first.")
        end
    elseif not want_web and was_web then
        Settings._web_config = nil
        console.print("[LooteerV3] Web config disabled — using local GUI settings.")
    end

    if not e.main_toggle:get() then
        e.main_tree:pop()
        return
    end

    if e.general.tree:push("General Settings") then
        e.general.behavior_combo:render("Behavior", BEHAVIORS,
            "When do you want the autolooter to execute?")
        e.general.rarity_combo:render("Rarity", RARITIES,
            "Minimum rarity for the bot to consider picking up.")
        e.general.distance_slider:render("Distance", "Distance from loot to execute pickup")
        e.general.loot_priority_combo:render("Loot Priority", {"Closest First", "Best First"},
            "Select the priority for looting items")
        e.general.tree:pop()
    end

    if e.affix.tree:push("Affix Settings") then
        e.affix.greater_affix_slider:render("Legendary GA Count",
            "Minimum GAs to consider picking up legendaries")
        e.affix.unique_greater_affix_slider:render("Unique GA Count",
            "Minimum GAs to consider picking up uniques")
        e.affix.uber_unique_greater_affix_slider:render("Uber GA Count",
            "Minimum GAs to consider picking up uber uniques")
        if e.affix.innerTree:push("Advanced Settings") then
            e.affix.custom_toggle:render("Force Per-Slot Settings",
                "Use the per-slot GA thresholds below instead of the global Legendary/Unique counts")
            if e.affix.armorsTree:push("Armor") then
                e.affix.legendary_helm_slider:render("Legendary Helm GA",   "Min GAs for legendary helms")
                e.affix.legendary_chest_slider:render("Legendary Chest GA", "Min GAs for legendary chests")
                e.affix.legendary_gloves_slider:render("Legendary Gloves GA","Min GAs for legendary gloves")
                e.affix.legendary_pants_slider:render("Legendary Pants GA", "Min GAs for legendary pants")
                e.affix.legendary_boots_slider:render("Legendary Boots GA", "Min GAs for legendary boots")
                e.affix.unique_helm_slider:render("Unique Helm GA",         "Min GAs for unique helms")
                e.affix.unique_chest_slider:render("Unique Chest GA",       "Min GAs for unique chests")
                e.affix.unique_gloves_slider:render("Unique Gloves GA",     "Min GAs for unique gloves")
                e.affix.unique_pants_slider:render("Unique Pants GA",       "Min GAs for unique pants")
                e.affix.unique_boots_slider:render("Unique Boots GA",       "Min GAs for unique boots")
                e.affix.armorsTree:pop()
            end
            if e.affix.jewelryTree:push("Jewelry") then
                e.affix.legendary_amulet_slider:render("Legendary Amulet GA","Min GAs for legendary amulets")
                e.affix.unique_amulet_slider:render("Unique Amulet GA",      "Min GAs for unique amulets")
                e.affix.legendary_ring_slider:render("Legendary Ring GA",    "Min GAs for legendary rings")
                e.affix.unique_ring_slider:render("Unique Ring GA",          "Min GAs for unique rings")
                e.affix.jewelryTree:pop()
            end
            if e.affix.weaponsTree:push("Weapons") then
                if e.affix.oneHandedTree:push("1-Handed") then
                    e.affix.legendary_1h_mace_slider:render("Legendary 1H Mace GA",  "Min GAs for legendary 1H maces")
                    e.affix.legendary_1h_axe_slider:render("Legendary 1H Axe GA",    "Min GAs for legendary 1H axes")
                    e.affix.legendary_1h_sword_slider:render("Legendary 1H Sword GA","Min GAs for legendary 1H swords")
                    e.affix.legendary_dagger_slider:render("Legendary Dagger GA",    "Min GAs for legendary daggers")
                    e.affix.legendary_wand_slider:render("Legendary Wand GA",        "Min GAs for legendary wands")
                    e.affix.unique_1h_mace_slider:render("Unique 1H Mace GA",        "Min GAs for unique 1H maces")
                    e.affix.unique_1h_axe_slider:render("Unique 1H Axe GA",          "Min GAs for unique 1H axes")
                    e.affix.unique_1h_sword_slider:render("Unique 1H Sword GA",      "Min GAs for unique 1H swords")
                    e.affix.unique_dagger_slider:render("Unique Dagger GA",          "Min GAs for unique daggers")
                    e.affix.unique_wand_slider:render("Unique Wand GA",              "Min GAs for unique wands")
                    e.affix.oneHandedTree:pop()
                end
                if e.affix.twoHandedTree:push("2-Handed") then
                    e.affix.legendary_2h_mace_slider:render("Legendary 2H Mace GA",        "Min GAs for legendary 2H maces")
                    e.affix.legendary_2h_axe_slider:render("Legendary 2H Axe GA",          "Min GAs for legendary 2H axes")
                    e.affix.legendary_2h_sword_slider:render("Legendary 2H Sword GA",      "Min GAs for legendary 2H swords")
                    e.affix.legendary_2h_polearm_slider:render("Legendary 2H Polearm GA",  "Min GAs for legendary 2H polearms")
                    e.affix.legendary_staff_slider:render("Legendary Staff GA",            "Min GAs for legendary staves")
                    e.affix.legendary_bow_slider:render("Legendary Bow GA",                "Min GAs for legendary bows")
                    e.affix.legendary_crossbow_slider:render("Legendary Crossbow GA",      "Min GAs for legendary crossbows")
                    e.affix.legendary_glaive_slider:render("Legendary Glaive GA",          "Min GAs for legendary glaives")
                    e.affix.legendary_quarterstaff_slider:render("Legendary Quarterstaff GA","Min GAs for legendary quarterstaves")
                    e.affix.unique_2h_mace_slider:render("Unique 2H Mace GA",              "Min GAs for unique 2H maces")
                    e.affix.unique_2h_axe_slider:render("Unique 2H Axe GA",                "Min GAs for unique 2H axes")
                    e.affix.unique_2h_sword_slider:render("Unique 2H Sword GA",            "Min GAs for unique 2H swords")
                    e.affix.unique_2h_polearm_slider:render("Unique 2H Polearm GA",        "Min GAs for unique 2H polearms")
                    e.affix.unique_staff_slider:render("Unique Staff GA",                  "Min GAs for unique staves")
                    e.affix.unique_bow_slider:render("Unique Bow GA",                      "Min GAs for unique bows")
                    e.affix.unique_crossbow_slider:render("Unique Crossbow GA",            "Min GAs for unique crossbows")
                    e.affix.unique_glaive_slider:render("Unique Glaive GA",                "Min GAs for unique glaives")
                    e.affix.unique_quarterstaff_slider:render("Unique Quarterstaff GA",    "Min GAs for unique quarterstaves")
                    e.affix.twoHandedTree:pop()
                end
                if e.affix.offHandsTree:push("Off-Hands") then
                    e.affix.legendary_focus_slider:render("Legendary Focus GA",  "Min GAs for legendary focuses")
                    e.affix.legendary_totem_slider:render("Legendary Totem GA",  "Min GAs for legendary totems")
                    e.affix.legendary_shield_slider:render("Legendary Shield GA","Min GAs for legendary shields")
                    e.affix.unique_shield_slider:render("Unique Shield GA",      "Min GAs for unique shields")
                    e.affix.offHandsTree:pop()
                end
                e.affix.weaponsTree:pop()
            end
            e.affix.innerTree:pop()
        end
        e.affix.tree:pop()
    end

    if e.always.tree:push("Always-Loot Categories") then
        e.always.uber_toggle:render("Uber Uniques",
            "Pickup ubers (Tyrael's Might, Harlequin Crest, etc.). Default ON.")
        e.always.boss_drops_toggle:render("Boss Drops",
            "Pickup boss-fight world drops (Boss_Flippy, Spirit Heart). Default ON.")
        e.always.boss_drops_rarity_combo:render("  Boss Drop Rarity", RARITIES,
            "Minimum rarity for boss drops.")
        e.always.misc_trinkets_toggle:render("Misc Trinkets",
            "Pickup small misc drops (Flippy_Misc). Default ON.")
        e.always.xp_powerup_toggle:render("XP Powerups",
            "Pickup experience motes (Experience_PowerUp drops). Default ON.")
        e.always.class_powerup_toggle:render("Class Powerups",
            "Pickup class-resource ground orbs: Sorc Crackling Energy, Necro Blood Orb, "
            .. "Spiritborn Feather, Rogue Dance of Knives, Health Potion charges. "
            .. "Default OFF — most builds auto-collect these. Flip on if yours doesn't.")
        e.always.glyph_drop_toggle:render("Glyph Drops",
            "Pickup paragon glyphs that drop in nightmare dungeons. Default ON.")
        e.always.keys_toggle:render("Keys",
            "Pickup whispering / dungeon keys. Default ON.")
        e.always.tree:pop()
    end

    if e.types.tree:push("Item Types") then
        e.types.quest_toggle:render("Quest Items",
            "Pickup quest objectives and dungeon items. No rarity filter — "
            .. "quest items are looted in full when this is on.")

        e.types.crafting_toggle:render("Crafting Materials",
            "Pickup raw crafting materials (essences, ores, horadric mats).")
        e.types.crafting_rarity_combo:render("  Crafting Rarity", RARITIES,
            "Minimum rarity for crafting materials.")

        e.types.recipe_toggle:render("Recipes / Manuals",
            "Pickup tempering manuals, books, mount items. Independent of Crafting Materials.")
        e.types.recipe_rarity_combo:render("  Recipe Rarity", RARITIES,
            "Minimum rarity for recipes/manuals.")

        e.types.boss_toggle:render("Boss Materials",
            "Pickup boss summon materials (Living Steel, lair keys, husks, etc).")
        e.types.event_toggle:render("Event Items",
            "Pickup event items (if inventory not full).")
        e.types.goblin_cache_toggle:render("Goblin Cache",
            "Pickup treasure goblin cache bags.")
        e.types.obols_toggle:render("Obols",
            "Pickup obols.")
        e.types.cinders_toggle:render("Cinders",
            "Pickup cinders.")
        e.types.heavenly_sigil_toggle:render("Heavenly Sigils",
            "Pickup heavenly sigils (if consumable inventory not full).")

        -- Categories with optional rarity filters: pair the toggle with a
        -- min-rarity combo immediately below.
        e.types.scroll_toggle:render("Scrolls",
            "Pickup scrolls (Scroll_Of_*).")
        e.types.scroll_rarity_combo:render("  Scroll Rarity", RARITIES,
            "Minimum rarity for scrolls. Set to Common to loot all.")

        e.types.cache_toggle:render("Caches",
            "Pickup treasure / reward caches.")
        e.types.cache_rarity_combo:render("  Cache Rarity", RARITIES,
            "Minimum rarity for caches.")

        e.types.sigil_toggle:render("Nightmare Sigils",
            "Pickup nightmare dungeon sigils.")
        e.types.sigil_rarity_combo:render("  Sigil Rarity", RARITIES,
            "Minimum rarity for nightmare sigils.")

        e.types.compass_toggle:render("Horde Compasses",
            "Pickup horde compasses (BSK_Sigil).")
        e.types.compass_rarity_combo:render("  Compass Rarity", RARITIES,
            "Minimum rarity for horde compasses.")

        e.types.tribute_toggle:render("Tributes",
            "Pickup undercity tributes.")
        e.types.tribute_rarity_combo:render("  Tribute Rarity", RARITIES,
            "Minimum rarity for tributes.")

        e.types.rune_toggle:render("Runes",
            "Pickup runes (Generic_Rune_*, Socketables).")
        e.types.rune_rarity_combo:render("  Rune Rarity", RARITIES,
            "Minimum rarity for runes.")

        e.types.gemstone_toggle:render("Gemstones",
            "Pickup gems and gemstones.")
        e.types.gemstone_rarity_combo:render("  Gemstone Rarity", RARITIES,
            "Minimum rarity for gemstones.")

        -- Consumables hidden in UI — D4 removed the elixir/incense/potion
        -- pickup loop these targeted. Uncomment to bring them back; the
        -- settings + loot-engine plumbing is still in place behind them.
        --[[
        e.types.consumable_toggle:render("Consumables",
            "Pickup generic consumables (potions, incense). Skips full inventories.")
        e.types.consumable_rarity_combo:render("  Consumable Rarity", RARITIES,
            "Minimum rarity for consumables.")
        --]]

        e.types.tree:pop()
    end

    if e.charm.tree:push("Charm Settings") then
        e.charm.toggle:render("Pickup Charms",
            "Enable pickup of charms (Generic_Charm_*).")
        e.charm.rarity_combo:render("Charm Rarity", CHARM_RARITIES,
            "Minimum rarity for charms. Independent of the General Rarity setting. "
            .. "Charms specifically can drop at Set tier (green).")
        e.charm.tree:pop()
    end

    if e.cube.tree:push("Cube Item Settings") then
        e.cube.toggle:render("Pickup Cube Items",
            "Enable pickup of Horadric Cube items (HoradricCube_*).")
        e.cube.rarity_combo:render("Cube Rarity", RARITIES,
            "Minimum rarity for cube items.")
        e.cube.tree:pop()
    end

    if e.seal.tree:push("Seal Settings") then
        e.seal.toggle:render("Pickup Seals",
            "Enable pickup of Talisman Seals (Talisman_Seal_*).")
        e.seal.rarity_combo:render("Seal Rarity", RARITIES,
            "Minimum rarity for seals.")
        e.seal.tree:pop()
    end

    if e.debug.tree:push("Debug") then
        e.debug.draw_wanted_toggle:render("Draw Wanted Items",
            "Draw circles on items the bot considers picking up.")
        e.debug.scan_items_toggle:render("Scan Items",
            "Print skin / rarity / sno_id / category of all nearby items to console and screen.")
        e.debug.draw_path_toggle:render("Draw Path / Target",
            "Show the pathfinder's current target marker and pathing nodes on screen. "
            .. "Off by default — only useful for debugging movement issues.")
        e.debug.tree:pop()
    end

    e.main_tree:pop()
end

return gui
