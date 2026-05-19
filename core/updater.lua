local ItemFilter = require("core.item_filter")

local Updater = {}
Updater._fetching_items = false
Updater._last_sync      = 0

local BASE_URL      = "https://looter.d4data.live"
local SYNC_INTERVAL = 3600

local _PLUG = ItemFilter.get_plugin_dir()

local function _read_key()
    local f = io.open(_PLUG .. "data/profile.key", "r")
    if not f then return nil end
    local k = (f:read("*a") or ""):gsub("%s+$", "")
    f:close()
    return k ~= "" and k or nil
end

local function _ensure_key()
    local key = _read_key()
    if key then return key end
    math.randomseed(os.time())
    local function r4() return math.random(0, 0xffff) end
    key = string.format('%04x%04x-%04x-4%03x-%04x-%04x%04x%04x',
        r4(), r4(), r4(), math.random(0, 0xfff),
        math.random(0x8000, 0xbfff), r4(), r4(), r4())
    local f = io.open(_PLUG .. "data/profile.key", "w")
    if f then f:write(key); f:close() end
    return key
end

local function _register(key)
    local ok, name = pcall(get_local_player_name)
    local label = (ok and type(name) == "string" and name ~= "") and name or "LooteerV3"
    local body  = string.format('{"key":"%s","label":"%s"}', key, label)
    curl.http_post(BASE_URL .. "/api/config/register", body, function(_, status, err)
        if err == "" and (status == 200 or status == 201) then
            console.print("[LooteerV3] Profile registered: " .. key)
        end
    end, { ["Content-Type"] = "application/json" }, 15.0)
end

function Updater.fetch_items(on_done)
    if Updater._fetching_items then
        if on_done then on_done(false) end
        return false
    end
    Updater._fetching_items = true
    local key     = _read_key() or ""
    local headers = key ~= "" and { ["X-Profile-Key"] = key } or {}

    console.print("[LooteerV3] Fetching catalog...")
    local ok = curl.http_get(BASE_URL .. "/d4/items.lua", function(body, status, err)
        Updater._fetching_items = false
        if err ~= "" or status ~= 200 then
            console.print("[LooteerV3] Catalog fetch failed: "
                .. (err ~= "" and err or "HTTP " .. tostring(status)))
            if on_done then on_done(false) end
            return
        end
        local f = io.open(_PLUG .. "data/items.lua", "w")
        if not f then
            console.print("[LooteerV3] Cannot write data/items.lua")
            if on_done then on_done(false) end
            return
        end
        f:write(body); f:close()
        local sf = io.open(_PLUG .. "data/last_sync.lua", "w")
        if sf then sf:write("return " .. tostring(os.time())); sf:close() end
        Updater._last_sync = os.time()
        ItemFilter.load_catalog()
        console.print("[LooteerV3] Catalog refreshed")
        if on_done then on_done(true) end
    end, headers, 30.0)

    if not ok then
        Updater._fetching_items = false
        console.print("[LooteerV3] Failed to queue catalog fetch")
        if on_done then on_done(false) end
        return false
    end
    return true
end

function Updater.fetch_config()
    local key = _read_key()
    if not key then return end
    local url = BASE_URL .. "/api/config/" .. key .. "/config.lua"
    curl.http_get(url, function(body, status, err)
        if err ~= "" or status ~= 200 then return end
        local f = io.open(_PLUG .. "data/config.lua", "w")
        if f then f:write(body); f:close() end
    end, { ["X-Profile-Key"] = key }, 15.0)
end

-- Called once on the first game tick. Ensures a profile key exists,
-- registers it with the server, syncs config, and bootstraps the
-- catalog if it wasn't on disk at load time.
function Updater.init()
    Updater._last_sync = os.time()  -- prevent tick() from firing a second fetch immediately
    local key = _ensure_key()
    _register(key)
    Updater.fetch_config()
    Updater.fetch_items()           -- always fetch on startup to pick up any updates
end

-- Called every frame; fires an async sync when the interval elapses.
function Updater.tick()
    if not Updater._fetching_items and os.time() - Updater._last_sync >= SYNC_INTERVAL then
        Updater._last_sync = os.time()
        Updater.fetch_items()
    end
end

return Updater
