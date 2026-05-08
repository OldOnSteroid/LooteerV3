-- The cloud catalog (data/items.lua) is REQUIRED for V3 to operate. The
-- repo ships a pre-downloaded copy so a fresh checkout works immediately;
-- Updater.bat keeps it fresh from the server. If the file is missing the
-- script refuses to loot — see core/loot_engine.lua.
--
-- defaults.lua remains as a structural fallback only (uber list, empty
-- catalog, empty name_patterns) so missing-file cases don't crash.

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
        return true
    end
    Items = defaults
    ItemFilter._items_version     = "not loaded"
    ItemFilter._catalog_loaded    = false
    ItemFilter._catalog_loaded_at = nil
    console.print("[LooteerV3] CATALOG NOT LOADED — looting is disabled. " ..
        "Run Updater.bat to fetch data/items.lua from the cloud.")
    return false
end

-- Try to load on script startup. data/items.lua ships with the repo, so
-- this normally succeeds the first time. If somehow missing, the user
-- gets a console warning and the loot engine refuses to act until they
-- run Updater.bat and hit Reload Catalog in the GUI.
ItemFilter.load_catalog()

-- Name-pattern fallback comes from the server-emitted Items.name_patterns
-- table — never hardcoded here. To add or change patterns, edit the
-- pipeline on the server. The client just walks the list in order.

-- Maps the catalog's `g` group key onto the loot-engine category string.
-- Catalog group keys are produced server-side by pipeline.py — keep this
-- table in sync with ITEM_TYPE_GROUPS / NAME_PATTERNS over there.
local GROUP_CATEGORY = {
    -- Equipment buckets (stay as "equipment"; slot lookup is separate)
    weapon="equipment", offhand="equipment", armor="equipment",
    jewelry="equipment", unique="equipment",
    -- Loot categories (1:1 passthrough — server emits the category name)
    cube="cube", xp_powerup="xp_powerup", class_powerup="class_powerup", keys="keys",
    obol_bag="obol_bag", goblin_cache="goblin_cache",
    charm="charm", seal="seal", sigil="sigil",
    compass="compass", heavenly_sigil="heavenly_sigil",
    glyph_drop="glyph_drop", boss_drops="boss_drops",
    misc_trinkets="misc_trinkets",
    tribute="tribute", quest="quest", cinders="cinders",
    scroll="scroll", rune="rune", gemstone="gemstone",
    recipe="recipe", crafting="crafting", cache="cache",
    consumable="consumable", misc="misc",
    -- Legacy / Wowhead aliases kept for catalogs predating the rename
    gem="gemstone", trophy="charm", horadric_seal="seal",
    crafting_material="crafting", crafting_recipe="recipe",
    essence="crafting",
}

function ItemFilter.get_items() return Items end

-- Walk the server-supplied name_patterns table in order. Each entry is
-- `{g="<group>", p="<lua_pattern>"}`. First match wins. Returns the group
-- key (which then runs through GROUP_CATEGORY) or nil.
local function name_pattern_match(skin)
    local list = Items.name_patterns
    if not list or skin == "" then return nil end
    for i = 1, #list do
        local e = list[i]
        if e and e.p and skin:find(e.p) then return e.g end
    end
    return nil
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

    -- Items not in the catalog (runtime-only drops the static d4data dump
    -- doesn't include — compass, heavenly sigil, etc.). Use the patterns
    -- the server ships in items.lua. No hardcoded patterns live here.
    local pattern_group = name_pattern_match(skin)
    if pattern_group then
        return GROUP_CATEGORY[pattern_group] or pattern_group
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
