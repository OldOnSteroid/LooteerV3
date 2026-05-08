-- Primary: catalog lookup by sno_id  (cloud-downloaded data/items.lua)
-- Fallback: skin_name pattern matching (same as V2 for uncatalogued items)

local defaults = require("data.defaults")
local Items    = defaults

local ItemFilter = {}
ItemFilter._items_version  = "not loaded"
ItemFilter._catalog_loaded = false
ItemFilter._catalog_loaded_at = nil   -- os.time() of last successful load

function ItemFilter.load_catalog()
    package.loaded["data.items"] = nil
    local ok, cloud = pcall(require, "data.items")
    if ok and cloud then
        Items = cloud
        ItemFilter._items_version    = cloud.version or "unknown"
        ItemFilter._catalog_loaded   = true
        ItemFilter._catalog_loaded_at = os.time()
        local count = 0
        for _ in pairs(cloud.catalog or {}) do count = count + 1 end
        console.print("[LooteerV3] Catalog loaded: v" .. ItemFilter._items_version
            .. " (" .. tostring(count) .. " entries)")
    else
        Items = defaults
        ItemFilter._items_version    = "not loaded"
        ItemFilter._catalog_loaded   = false
        ItemFilter._catalog_loaded_at = nil
        console.print("[LooteerV3] Catalog load failed — run Updater.bat then try again.")
    end
end

function ItemFilter.unload_catalog()
    package.loaded["data.items"] = nil
    Items = defaults
    ItemFilter._items_version    = "not loaded"
    ItemFilter._catalog_loaded   = false
    ItemFilter._catalog_loaded_at = nil
    console.print("[LooteerV3] Catalog unloaded — using defaults.")
end

-- Auto-load on startup if the local file already exists
do
    local ok, cloud = pcall(require, "data.items")
    if ok and cloud and type(cloud) == "table" then
        ItemFilter.load_catalog()
    end
end

-- Skin patterns for items not covered by the catalog
local SKIN = {
    sigil         = { "Nightmare_Sigil", "S07_WitcherSigil", "S07_DRLG_Sigil", "S09_Prop_Astaroth_NMD" },
    compass       = { "BSK_Sigil" },
    tribute       = { "Undercity_Tribute" },
    quest         = { "Global", "Glyph", "QST", "DGN", "pvp_currency", "S07_Witch_Bonus", "S09_Arcana", "S11_MemoryFragment" },
    obol_bag      = { "GamblingCurrency_Key" },
    crafting      = { "CraftingMaterial", "Crafting_Legendary", "Horadric_", "Ore_" },
    keys          = { "Flippy_[Kk]eys", "S13_Prop_Dungeon_Key_Sigil" },
    boss_drops    = { "Boss_Flippy", "S08_Prop_Spirit_Heart" },
    xp_powerup    = { "Experience_PowerUp" },
    goblin_cache  = { "Treasure_Reward_Cache_GoblinEvent" },
    cache         = { "Treasure_Reward_Cache", "Item_Cache" },
    glyph_drop    = { "Paragon_Glyph" },
    charm         = { "Generic_Charm_" },
    cube          = { "HoradricCube_" },
    seal          = { "Talisman_Seal" },
    recipe        = { "Tempering_Recipe", "Item_Book_Generic", "Item_Book_Horadrim", "mnt_amor", "MountReins" },
    cinders       = { "Test_BloodMoon_Currency" },
    heavenly_sigil= { "S11_Heavenly_Sigil" },
    scroll        = { "Scroll_Of" },
    rune          = { "Generic_Rune", "S07_Socketable" },
    gemstone      = { "Item_Gemstone", "Gem_" },
    misc_trinkets = { "Flippy_Misc" },
    tribute_drop  = { "Undercity_Tribute" },
}

local GROUP_CATEGORY = {
    weapon="equipment", offhand="equipment", armor="equipment",
    jewelry="equipment", unique="equipment",
    gem="gemstone", rune="rune", crafting_material="crafting",
    crafting_recipe="recipe", cache="cache", trophy="charm",
    consumable="consumable", horadric_seal="seal",
    essence="crafting", sigil="sigil", misc="misc",
}

function ItemFilter.get_items() return Items end

local function skin_match(skin, type_name)
    for _, p in ipairs(SKIN[type_name] or {}) do
        if skin:find(p) then return true end
    end
    return false
end

function ItemFilter.get_info(item)
    local info = item:get_item_info()
    if not info then return nil end
    return info, info:get_sno_id(), info:get_skin_name() or "", info:get_rarity()
end

-- Returns a category string used by loot_engine
function ItemFilter.classify(item)
    local info, id, skin, rarity = ItemFilter.get_info(item)
    if not info then return nil end

    if Items.ubers[id]            then return "uber"          end
    if Items.boss_materials[id]   then return "boss_material" end
    if Items.event_items[id]      then return "event"         end

    local entry = Items.catalog[id]
    if entry then
        return GROUP_CATEGORY[entry.g] or "equipment"
    end

    -- Skin-name fallback (handles anything not yet in the catalog)
    for cat in pairs(SKIN) do
        if skin_match(skin, cat) then return cat end
    end

    if rarity > 0 and (skin:find("Base") or skin:find("Amulet") or skin:find("Ring")) then
        return "equipment"
    end
    return nil
end

function ItemFilter.is_uber(id)      return Items.ubers[id] ~= nil         end
function ItemFilter.is_boss_mat(id)  return Items.boss_materials[id] ~= nil end
function ItemFilter.is_event(id)     return Items.event_items[id] ~= nil    end

-- Returns slot key for per-slot GA thresholds
function ItemFilter.get_slot(item)
    local info, id, skin, rarity = ItemFilter.get_info(item)
    if not info then return nil end

    local entry = Items.catalog[id]
    if entry then
        local t = entry.t:lower()
        if t:find("helm")            then return "helm"          end
        if t:find("chest")           then return "chest"         end
        if t:find("glov")            then return "gloves"        end
        if t:find("pant") or t:find("leg") then return "pants"   end
        if t:find("boot")            then return "boots"         end
        if t:find("amulet") or t:find("necklace") then return "amulet" end
        if t:find("ring")            then return "ring"          end
        if t:find("shield")          then return "shield"        end
        if t:find("focus") or t:find("sorc") or t:find("book") then return "focus" end
        if t:find("totem")           then return "totem"         end
        if t:find("1h") and t:find("sword") then return "1h_sword"  end
        if t:find("1h") and t:find("axe")   then return "1h_axe"    end
        if t:find("1h") and t:find("mace")  then return "1h_mace"   end
        if t:find("dagger")          then return "dagger"        end
        if t:find("wand")            then return "wand"          end
        if t:find("2h") and t:find("sword") then return "2h_sword"  end
        if t:find("2h") and t:find("axe")   then return "2h_axe"    end
        if t:find("2h") and t:find("mace")  then return "2h_mace"   end
        if t:find("polearm")         then return "2h_polearm"    end
        if t:find("staff")           then return "staff"         end
        if t:find("bow") and not t:find("crossbow") then return "bow" end
        if t:find("crossbow") or t:find("hand crossbow") then return "crossbow" end
        if t:find("glaive")          then return "glaive"        end
        if t:find("quarterstaff")    then return "quarterstaff"  end
        if t:find("flail")           then return "flail"         end
    end

    -- Skin-name fallback
    local s = skin
    if s:find("HLM")            then return "helm"         end
    if s:find("TRS")            then return "chest"        end
    if s:find("GLV") or s:find("Gloves") then return "gloves" end
    if s:find("LEG") or s:find("Pants")  then return "pants"  end
    if s:find("BTS")            then return "boots"        end
    if s:find("Amulet") or s:find("Necklace") then return "amulet" end
    if s:find("Ring")           then return "ring"         end
    if s:find("shield")         then return "shield"       end
    if s:find("offHandsSorc")   then return "focus"        end
    if s:find("offHandsDruid")  then return "totem"        end
    if s:find("sword")          then return "1h_sword"     end
    if s:find("Sword")          then return "2h_sword"     end
    if s:find("mace")           then return "1h_mace"      end
    if s:find("Mace")           then return "2h_mace"      end
    if s:find("axe")            then return "1h_axe"       end
    if s:find("Axe")            then return "2h_axe"       end
    if s:find("dagger")         then return "dagger"       end
    if s:find("wand")           then return "wand"         end
    if s:find("Polearm")        then return "2h_polearm"   end
    if s:find("Staff")          then return "staff"        end
    if s:find("Bow")            then return "bow"          end
    if s:find("Crossbow")       then return "crossbow"     end
    if s:find("Glaive")         then return "glaive"       end
    if s:find("Quarterstaff")   then return "quarterstaff" end
    return nil
end

return ItemFilter
