local Settings   = require("core.settings")
local Utils      = require("utils.utils")
local ItemFilter = require("core.item_filter")

local LootEngine = {}

local function ga_setting_for_slot(slot, rarity, s)
    local prefix = (rarity == 6 or rarity == 7) and "unique_" or "legendary_"
    return s[prefix .. slot .. "_ga_count"]
end

function LootEngine.check_want_item(item, ignore_distance)
    local info, id, skin, rarity = ItemFilter.get_info(item)
    if not info then return false end

    local s = Settings.get()

    if not ignore_distance and Utils.distance_to(item) >= s.distance then return false end
    if loot_manager.is_gold(item) or loot_manager.is_potion(item) then return false end

    local cat = ItemFilter.classify(item)
    if not cat then return false end

    -- ── Always loot ────────────────────────────────────────────────
    if cat == "uber"          then return true end
    if cat == "keys"          then return true end
    if cat == "misc_trinkets" then return true end
    if cat == "xp_powerup"   then return true end
    if cat == "tribute_drop"  then return true end
    if cat == "glyph_drop"   then return true end

    -- ── Toggled / conditional ──────────────────────────────────────
    if cat == "boss_material" then return s.boss_items end

    if cat == "event" then
        if not s.event_items then return false end
        return not Utils.is_inventory_full()
    end

    if cat == "goblin_cache" then return s.goblin_cache end
    if cat == "obol_bag"     then return s.obols end
    if cat == "quest"        then return s.quest_items end
    if cat == "crafting"     then return s.crafting_items end
    if cat == "cinders"      then return s.cinders end

    if cat == "cache" then
        if not Utils.is_inventory_full() then return true end
        return false
    end

    if cat == "scroll" then
        if not s.scroll then return false end
        if not Utils.is_consumable_inventory_full() or
            Utils.is_lowest_stack_below(get_local_player():get_consumable_items(), id, 20, info:get_stack_count()) then
            return true
        end
        return false
    end

    if cat == "heavenly_sigil" then
        return s.heavenly_sigil and not Utils.is_consumable_inventory_full()
    end

    if cat == "sigil" then
        return s.sigils and not Utils.is_sigil_inventory_full()
    end

    if cat == "tribute" or cat == "compass" then
        local flag = (cat == "tribute") and s.tribute or s.compass
        if not flag then return false end
        if not Utils.is_sigil_inventory_full() or
            Utils.is_lowest_stack_below(get_local_player():get_dungeon_key_items(), id, 99, info:get_stack_count()) then
            return true
        end
        return false
    end

    if cat == "rune" then
        if not s.rune then return false end
        if not Utils.is_socketable_inventory_full() or
            Utils.is_lowest_stack_below(get_local_player():get_socketable_items(), id, 100, info:get_stack_count()) then
            return true
        end
        return false
    end

    if cat == "gemstone" then
        if not s.gemstone then return false end
        if not Utils.is_socketable_inventory_full() or
            Utils.is_lowest_stack_below(get_local_player():get_socketable_items(), id, 99, info:get_stack_count()) then
            return true
        end
        return false
    end

    if cat == "recipe" then
        return s.crafting_items and not Utils.is_inventory_full()
    end

    if cat == "charm" then
        if not s.charm or rarity < s.charm_rarity then return false end
        return not Utils.is_inventory_full()
    end

    if cat == "cube" then
        if not s.cube or rarity < s.cube_rarity then return false end
        return not Utils.is_inventory_full()
    end

    if cat == "seal" then
        if not s.seal or rarity < s.seal_rarity then return false end
        return not Utils.is_inventory_full()
    end

    if cat == "misc" then return false end

    -- ── Equipment ─────────────────────────────────────────────────
    if Utils.is_inventory_full() then return false end
    if rarity < s.rarity         then return false end

    if rarity >= 5 then
        local ga   = Utils.get_greater_affix_count(info:get_display_name())
        local need = nil

        if s.custom_toggle then
            local slot = ItemFilter.get_slot(item)
            if slot then need = ga_setting_for_slot(slot, rarity, s) end
        end

        if need == nil then
            if     rarity == 5 then need = s.ga_count
            elseif rarity == 6 then need = s.unique_ga_count
            elseif rarity == 7 then need = 0
            elseif rarity == 8 then need = ItemFilter.is_uber(id) and s.uber_unique_ga_count or s.unique_ga_count
            else                     need = 4
            end
        end

        if ga < need then return false end
    end

    return true
end

function LootEngine.get_nearby_item()
    local all, found = actors_manager:get_all_items(), {}
    for _, item in pairs(all) do
        if LootEngine.check_want_item(item, false) then
            table.insert(found, item)
        end
    end
    table.sort(found, function(a, b) return Utils.distance_to(a) < Utils.distance_to(b) end)
    return found[1]
end

function LootEngine.score_item(item)
    local info, id, _, rarity = ItemFilter.get_info(item)
    if not info then return 0 end
    local score = ItemFilter.is_uber(id) and 1000
        or rarity >= 5 and 500
        or rarity >= 3 and 300
        or rarity >= 1 and 100
        or 10
    local ga = Utils.get_greater_affix_count(info:get_display_name())
    return score + (ga == 3 and 100 or ga == 2 and 75 or ga == 1 and 50 or 0)
end

function LootEngine.get_best_item()
    local all, scored = actors_manager:get_all_items(), {}
    for _, item in ipairs(all) do
        if LootEngine.check_want_item(item, false) then
            table.insert(scored, { Item = item, Score = LootEngine.score_item(item) })
        end
    end
    table.sort(scored, function(a, b) return a.Score > b.Score end)
    return scored[1]
end

function LootEngine.get_item_based_on_priority()
    return Settings.get().loot_priority == 0
        and LootEngine.get_nearby_item()
        or  LootEngine.get_best_item()
end

return LootEngine
