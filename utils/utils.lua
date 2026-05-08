local Utils = {}

function Utils.distance_to(obj)
    return get_player_position():dist_to_ignore_z(obj:get_position())
end

function Utils.get_greater_affix_count(display_name)
    local count = 0
    for _ in display_name:gmatch("GreaterAffix") do count = count + 1 end
    return count
end

function Utils.is_lowest_stack_below(inventory, item_id, max_stack, looted_stack)
    if not inventory then return true end
    local lowest = max_stack
    for _, item in pairs(inventory) do
        if item:get_sno_id() == item_id then
            local s = item:get_stack_count()
            if s < lowest then lowest = s end
        end
    end
    return (lowest + looted_stack) <= max_stack
end

function Utils.is_inventory_full()
    return get_local_player():get_item_count() == 33
end

function Utils.is_consumable_inventory_full()
    return get_local_player():get_consumable_count() == 33
end

function Utils.is_sigil_inventory_full()
    return #get_local_player():get_dungeon_key_items() == 33
end

function Utils.is_socketable_inventory_full()
    return #get_local_player():get_socketable_items() == 33
end

function Utils.player_in_zone(name)
    return get_current_world():get_current_zone_name() == name
end

return Utils
