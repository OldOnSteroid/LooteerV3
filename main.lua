local Settings   = require("core.settings")
local LootEngine = require("core.loot_engine")
local Renderer   = require("core.renderer")
local GUI        = require("gui")
local Utils      = require("utils.utils")
local Pathfinder = require("core.pathfinder")

local RARITY_NAMES = {
    [0]="Normal",[1]="Normal",[2]="Magic",[3]="Magic",
    [4]="Rare",[5]="Legendary",[6]="Unique",[7]="Set",[8]="Uber",
}

local function handle_loot(item)
    if not item then return end
    if Utils.distance_to(item) > 2 then
        Pathfinder:set_custom_target(item:get_position())
        Pathfinder:move_to_target()
    else
        -- Report loot to D4Remote for statistics tracking
        if D4Remote and D4Remote.record_loot then
            pcall(function()
                local info   = item:get_item_info()
                local cat    = ItemFilter.classify(item) or "misc"
                local rarity = RARITY_NAMES[info:get_rarity()] or "Normal"
                D4Remote.record_loot(cat, rarity)
            end)
        end
        interact_object(item)
    end
end

local function main_pulse()
    if not get_local_player() then return end

    Settings.update()

    if not Settings.get().enabled then return end
    if not Settings.should_execute() then return end

    orbwalker.set_auto_loot_toggle(false)

    local priority = GUI.elements.general.loot_priority_combo:get()

    if priority == 0 then
        local item = LootEngine.get_nearby_item()
        Settings.get().looting = item ~= nil
        handle_loot(item)
    else
        local best = LootEngine.get_best_item()
        Settings.get().looting = best ~= nil
        handle_loot(best and best.Item)
    end
end

-- Global API for other plugins
LooteerPlugin = {
    getSettings = function(setting)
        local val = Settings.get()[setting]
        return val ~= nil and val or nil
    end,
    setSettings = function(setting, value)
        if Settings.get()[setting] ~= nil then
            Settings.get()[setting] = value
            return true
        end
        return false
    end,
}

on_update(main_pulse)
on_render_menu(GUI.render)
on_render(Renderer.draw_stuff)
