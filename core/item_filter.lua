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
    local ok, cloud_or_err = pcall(require, "data.items")
    if ok and type(cloud_or_err) == "table" then
        local cloud = cloud_or_err
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
    if not ok then
        -- pcall returned false — cloud_or_err is the error message string.
        console.print("[LooteerV3] CATALOG NOT LOADED — require failed:\n  "
            .. tostring(cloud_or_err))
    else
        console.print("[LooteerV3] CATALOG NOT LOADED — items.lua didn't return a "
            .. "table (got " .. type(cloud_or_err) .. "). File may be truncated "
            .. "or not Lua content.")
    end
    return false
end

-- Resolve the plugin's own folder. QQT sandboxes the `debug` library so
-- we can't use debug.getinfo. Instead, ask Lua's loader where it'd find
-- our own module file via package.searchpath, then chop off the
-- "core/item_filter.lua" suffix.
--
-- This is needed because QQT's `os.execute` child processes don't always
-- inherit the plugin folder as their cwd, and `io.open` on relative
-- paths has the same problem. Using absolute paths sidesteps both.
local function _plugin_dir()
    if package.searchpath then
        local p = package.searchpath("core.item_filter", package.path)
        if p then
            return (p:gsub("[/\\]core[/\\]item_filter%.lua$", "/"))
        end
    end
    -- Fallback: walk package.path manually and check which entry
    -- actually contains our file on disk.
    for entry in (package.path .. ";"):gmatch("([^;]+);") do
        local prefix = entry:gsub("%?%.lua$", ""):gsub("%?$", "")
        if prefix ~= "" then
            local probe = prefix .. "core/item_filter.lua"
            local f = io.open(probe, "r")
            if not f then
                probe = prefix .. "core\\item_filter.lua"
                f = io.open(probe, "r")
            end
            if f then f:close(); return prefix end
        end
    end
    -- Last resort — assume cwd is the plugin dir (works on most QQT setups
    -- but not all; the messages will be relative-path errors, not crashes).
    return ""
end

local _PLUG = _plugin_dir()

local function _file_size(path)
    local f = io.open(path, "rb")
    if not f then return nil end
    local n = f:seek("end") or 0
    f:close()
    return n
end

local function _read_text(path, max_chars)
    local f = io.open(path, "r")
    if not f then return nil end
    local txt = f:read(max_chars or 4096) or ""
    f:close()
    txt = txt:gsub("[\r\n]+$", "")
    return (txt ~= "" and txt) or nil
end

-- Fire Updater.bat in oneshot mode (single fetch + exit), then re-read
-- data/items.lua. We use absolute paths derived from this file's own
-- location so the spawned cmd, the bat's %~dp0 expansion, and the
-- subsequent io.open all agree on what "the plugin folder" means.
--
-- Success is judged by whether data/items.lua actually changed on disk
-- AND data/last_sync_log.txt got written — os.execute returning OK only
-- means the shell was callable, not that the bat actually ran.
function ItemFilter.fetch_and_reload()
    local items_path = _PLUG .. "data/items.lua"
    local log_path   = _PLUG .. "data/last_sync_log.txt"
    local bat_path   = _PLUG .. "Updater.bat"

    local before = _file_size(items_path) or 0

    -- Wipe the previous log so its presence after spawn proves the bat ran.
    pcall(os.execute, string.format('del /q "%s" >NUL 2>&1', log_path))
    -- Run the bat with its absolute path. The cmd /c outer quotes are the
    -- canonical Windows trick to handle paths with spaces.
    pcall(os.execute, string.format('cmd /c ""%s" oneshot" >NUL 2>&1', bat_path))

    local log_size = _file_size(log_path) or 0
    local after    = _file_size(items_path) or 0

    if log_size == 0 then
        console.print("[LooteerV3] Updater.bat didn't appear to run.\n"
            .. "  Plugin dir resolved as: " .. _PLUG .. "\n"
            .. "  Bat path tried:         " .. bat_path .. "\n"
            .. "  Possible cause: QQT is sandboxing os.execute, or the bat "
            .. "isn't at that path. Run Updater.bat manually to confirm it works.")
    elseif after == 0 then
        local log = _read_text(log_path, 2048)
        console.print("[LooteerV3] Updater ran but items.lua is missing/empty. Log:\n"
            .. (log or "(log unreadable)"))
    elseif after ~= before then
        console.print(string.format(
            "[LooteerV3] Updater fetched a fresh catalog (%d -> %d bytes). Reloading.",
            before, after))
    else
        console.print("[LooteerV3] Updater complete (catalog unchanged). Reloading.")
    end
    return ItemFilter.load_catalog()
end

-- Startup: try to load the catalog. If it's missing, automatically
-- bootstrap by running Updater.bat oneshot. The repo ships a pre-built
-- items.lua, so this fallback is mainly for users who somehow deleted
-- the data/ folder or never had a successful sync.
ItemFilter.load_catalog()
if not ItemFilter._catalog_loaded then
    console.print("[LooteerV3] No catalog on disk — bootstrapping via Updater.bat...")
    ItemFilter.fetch_and_reload()
end

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
    charm="charm", trophy="trophy", seal="seal", sigil="sigil",
    compass="compass", heavenly_sigil="heavenly_sigil",
    glyph_drop="glyph_drop", boss_drops="boss_drops",
    misc_trinkets="misc_trinkets",
    tribute="tribute", quest="quest", cinders="cinders",
    scroll="scroll", rune="rune", gemstone="gemstone",
    recipe="recipe", crafting="crafting", cache="cache",
    consumable="consumable", misc="misc",
    -- Legacy / Wowhead aliases kept for catalogs predating the rename
    gem="gemstone", horadric_seal="seal",
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
        -- Horadric Jewels occupy a special game slot and their item_info API
        -- does not support get_display_name() reliably — route them as misc
        -- so they never reach the equipment GA-check path.
        if entry.t == "Horadric Jewel" then return "misc" end
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
