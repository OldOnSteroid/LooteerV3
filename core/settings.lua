local gui = require("gui")

local Settings = {}

Settings._web_config = nil  -- set by gui.lua when web config checkbox is enabled

-- Pathfinder settings (read by core.pathfinder)
Settings.enabled           = false
Settings.path_angle        = 20
Settings.aggresive_movement        = false
Settings.use_evade_as_movement_spell = false

-- Full loot settings
local settings = {
    enabled = false, looting = false,
    custom_toggle = false,
    behavior = 0, rarity = 0, distance = 2, loot_priority = 0,
    ga_count = 0, unique_ga_count = 0, uber_unique_ga_count = 0,
    quest_items = false, crafting_items = false, cinders = false,
    heavenly_sigil = false, gemstone = false, boss_items = false,
    sigils = false, compass = false, rune = false, tribute = false,
    scroll = false, event_items = true, goblin_cache = true, obols = true,
    -- jewelry
    legendary_amulet_ga_count=0, legendary_ring_ga_count=0,
    unique_amulet_ga_count=0,    unique_ring_ga_count=0,
    -- armor
    legendary_helm_ga_count=0,  legendary_chest_ga_count=0,
    legendary_gloves_ga_count=0,legendary_pants_ga_count=0,
    legendary_boots_ga_count=0,
    unique_helm_ga_count=0,     unique_chest_ga_count=0,
    unique_gloves_ga_count=0,   unique_pants_ga_count=0,
    unique_boots_ga_count=0,
    -- offhand
    legendary_focus_ga_count=0, legendary_totem_ga_count=0,
    legendary_shield_ga_count=0,unique_shield_ga_count=0,
    -- 1h weapons
    legendary_1h_mace_ga_count=0, legendary_1h_sword_ga_count=0,
    legendary_1h_axe_ga_count=0,  legendary_dagger_ga_count=0,
    legendary_wand_ga_count=0,
    unique_1h_mace_ga_count=0,    unique_1h_sword_ga_count=0,
    unique_1h_axe_ga_count=0,     unique_dagger_ga_count=0,
    unique_wand_ga_count=0,
    -- 2h weapons
    legendary_2h_mace_ga_count=0, legendary_2h_sword_ga_count=0,
    legendary_2h_axe_ga_count=0,  legendary_2h_polearm_ga_count=0,
    legendary_staff_ga_count=0,   legendary_bow_ga_count=0,
    legendary_crossbow_ga_count=0,legendary_glaive_ga_count=0,
    legendary_quarterstaff_ga_count=0,
    unique_2h_mace_ga_count=0,    unique_2h_sword_ga_count=0,
    unique_2h_axe_ga_count=0,     unique_2h_polearm_ga_count=0,
    unique_staff_ga_count=0,      unique_bow_ga_count=0,
    unique_crossbow_ga_count=0,   unique_glaive_ga_count=0,
    unique_quarterstaff_ga_count=0,
    -- special item types
    charm=false, charm_rarity=0,
    cube=false,  cube_rarity=0,
    seal=false,  seal_rarity=0,
    -- debug
    draw_wanted_items=false, scan_items=false,
}

function Settings.update()
    local e = gui.elements
    settings = {
        enabled      = e.main_toggle:get(),
        behavior     = e.general.behavior_combo:get(),
        rarity       = e.general.rarity_combo:get(),
        distance     = e.general.distance_slider:get(),
        loot_priority= e.general.loot_priority_combo:get(),

        ga_count            = e.affix.greater_affix_slider:get(),
        unique_ga_count     = e.affix.unique_greater_affix_slider:get(),
        uber_unique_ga_count= e.affix.uber_unique_greater_affix_slider:get(),
        custom_toggle       = e.affix.custom_toggle:get(),

        legendary_amulet_ga_count  = e.affix.legendary_amulet_slider:get(),
        unique_amulet_ga_count     = e.affix.unique_amulet_slider:get(),
        legendary_ring_ga_count    = e.affix.legendary_ring_slider:get(),
        unique_ring_ga_count       = e.affix.unique_ring_slider:get(),

        legendary_helm_ga_count    = e.affix.legendary_helm_slider:get(),
        legendary_chest_ga_count   = e.affix.legendary_chest_slider:get(),
        legendary_gloves_ga_count  = e.affix.legendary_gloves_slider:get(),
        legendary_pants_ga_count   = e.affix.legendary_pants_slider:get(),
        legendary_boots_ga_count   = e.affix.legendary_boots_slider:get(),
        unique_helm_ga_count       = e.affix.unique_helm_slider:get(),
        unique_chest_ga_count      = e.affix.unique_chest_slider:get(),
        unique_gloves_ga_count     = e.affix.unique_gloves_slider:get(),
        unique_pants_ga_count      = e.affix.unique_pants_slider:get(),
        unique_boots_ga_count      = e.affix.unique_boots_slider:get(),

        legendary_focus_ga_count   = e.affix.legendary_focus_slider:get(),
        legendary_totem_ga_count   = e.affix.legendary_totem_slider:get(),
        legendary_shield_ga_count  = e.affix.legendary_shield_slider:get(),
        unique_shield_ga_count     = e.affix.unique_shield_slider:get(),

        legendary_1h_mace_ga_count = e.affix.legendary_1h_mace_slider:get(),
        legendary_1h_sword_ga_count= e.affix.legendary_1h_sword_slider:get(),
        legendary_1h_axe_ga_count  = e.affix.legendary_1h_axe_slider:get(),
        legendary_dagger_ga_count  = e.affix.legendary_dagger_slider:get(),
        legendary_wand_ga_count    = e.affix.legendary_wand_slider:get(),
        unique_1h_mace_ga_count    = e.affix.unique_1h_mace_slider:get(),
        unique_1h_sword_ga_count   = e.affix.unique_1h_sword_slider:get(),
        unique_1h_axe_ga_count     = e.affix.unique_1h_axe_slider:get(),
        unique_dagger_ga_count     = e.affix.unique_dagger_slider:get(),
        unique_wand_ga_count       = e.affix.unique_wand_slider:get(),

        legendary_2h_mace_ga_count = e.affix.legendary_2h_mace_slider:get(),
        legendary_2h_sword_ga_count= e.affix.legendary_2h_sword_slider:get(),
        legendary_2h_axe_ga_count  = e.affix.legendary_2h_axe_slider:get(),
        legendary_2h_polearm_ga_count=e.affix.legendary_2h_polearm_slider:get(),
        legendary_staff_ga_count   = e.affix.legendary_staff_slider:get(),
        legendary_bow_ga_count     = e.affix.legendary_bow_slider:get(),
        legendary_crossbow_ga_count= e.affix.legendary_crossbow_slider:get(),
        legendary_glaive_ga_count  = e.affix.legendary_glaive_slider:get(),
        legendary_quarterstaff_ga_count=e.affix.legendary_quarterstaff_slider:get(),
        unique_2h_mace_ga_count    = e.affix.unique_2h_mace_slider:get(),
        unique_2h_sword_ga_count   = e.affix.unique_2h_sword_slider:get(),
        unique_2h_axe_ga_count     = e.affix.unique_2h_axe_slider:get(),
        unique_2h_polearm_ga_count = e.affix.unique_2h_polearm_slider:get(),
        unique_staff_ga_count      = e.affix.unique_staff_slider:get(),
        unique_bow_ga_count        = e.affix.unique_bow_slider:get(),
        unique_crossbow_ga_count   = e.affix.unique_crossbow_slider:get(),
        unique_glaive_ga_count     = e.affix.unique_glaive_slider:get(),
        unique_quarterstaff_ga_count=e.affix.unique_quarterstaff_slider:get(),

        quest_items     = e.types.quest_toggle:get(),
        crafting_items  = e.types.crafting_toggle:get(),
        boss_items      = e.types.boss_toggle:get(),
        sigils          = e.types.sigil_toggle:get(),
        compass         = e.types.compass_toggle:get(),
        rune            = e.types.rune_toggle:get(),
        cinders         = e.types.cinders_toggle:get(),
        tribute         = e.types.tribute_toggle:get(),
        scroll          = e.types.scroll_toggle:get(),
        event_items     = e.types.event_toggle:get(),
        goblin_cache    = e.types.goblin_cache_toggle:get(),
        obols           = e.types.obols_toggle:get(),
        heavenly_sigil  = e.types.heavenly_sigil_toggle:get(),
        gemstone        = e.types.gemstone_toggle:get(),

        charm        = e.charm.toggle:get(),
        charm_rarity = e.charm.rarity_combo:get(),
        cube         = e.cube.toggle:get(),
        cube_rarity  = e.cube.rarity_combo:get(),
        seal         = e.seal.toggle:get(),
        seal_rarity  = e.seal.rarity_combo:get(),

        draw_wanted_items = e.debug.draw_wanted_toggle:get(),
        scan_items        = e.debug.scan_items_toggle:get(),
    }

    -- Sync pathfinder settings
    Settings.enabled = settings.enabled

    -- Web config overrides GUI values when loaded
    if Settings._web_config then
        Settings.apply_config(Settings._web_config)
    end
end

function Settings.get()
    return settings
end

-- Apply a config table downloaded from the web (data/config.lua).
-- Called after Settings.update() so web values override the local GUI.
function Settings.apply_config(cfg)
    if type(cfg) ~= "table" then return end
    for k, v in pairs(cfg) do
        if settings[k] ~= nil then
            settings[k] = v
        end
    end
    Settings.enabled = settings.enabled
end

function Settings.should_execute()
    return settings.behavior == 0 or
        (settings.behavior == 1 and orbwalker.get_orb_mode() == orb_mode.clear)
end

return Settings
