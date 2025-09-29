-- Core.lua - Toxicify Core functionality and database management
local addonName, ns = ...

-- Initialize namespace if not exists
if not ns then
    ns = {}
end

-- Core namespace
ns.Core = {}

-- Initialize Core module
function ns.Core.Initialize()
    -- Core initialization if needed
end

-- Database initialization
ToxicifyDB = ToxicifyDB or {}

-- Default settings
local function InitializeDefaults()
    if not ToxicifyDB.WhisperMessage then
        ToxicifyDB.WhisperMessage = "U have been marked as Toxic player by - Toxicify Addon"
    end
    
    if ToxicifyDB.WhisperOnMark == nil then
        ToxicifyDB.WhisperOnMark = false
    end
    
    if ToxicifyDB.IgnoreOnMark == nil then
        ToxicifyDB.IgnoreOnMark = false
    end
    
    if ToxicifyDB.HideInFinder == nil then
        ToxicifyDB.HideInFinder = false
    end
    
    if not ToxicifyDB.minimap then
        ToxicifyDB.minimap = { hide = false }
    end
end

-- Core initialization
function ns.Core.Initialize()
    InitializeDefaults()
    print("|cff39FF14Toxicify:|r Addon is loading...")
end

-- Database access functions
function ns.Core.GetDatabase()
    return ToxicifyDB
end

function ns.Core.SetDatabaseValue(key, value)
    ToxicifyDB[key] = value
end

function ns.Core.GetDatabaseValue(key, defaultValue)
    return ToxicifyDB[key] or defaultValue
end

-- Export functionality
function ns.Core.ExportList()
    local data = {}
    for name, status in pairs(ToxicifyDB) do
        if status == "toxic" or status == "pumper" then
            table.insert(data, name .. ":" .. status)
        end
    end
    local payload = table.concat(data, ";")

    local checksum = 0
    for i = 1, #payload do
        checksum = checksum + string.byte(payload, i)
    end

    return "TOXICIFYv1|" .. payload .. "|" .. checksum
end

-- Import functionality
function ns.Core.ImportList(str)
    if not str or str == "" then return false, "No data" end

    local version, payload, checksum = str:match("^(TOXICIFYv1)|(.+)|(%d+)$")
    if not version then return false, "Invalid format" end

    local calc = 0
    for i = 1, #payload do
        calc = calc + string.byte(payload, i)
    end
    if tostring(calc) ~= checksum then
        return false, "Checksum mismatch"
    end

    local count = 0
    for entry in string.gmatch(payload, "([^;]+)") do
        local name, status = entry:match("([^:]+):([^:]+)")
        if name and status then
            ToxicifyDB[name] = status
            count = count + 1
        end
    end

    return true, count .. " entries imported"
end

-- Initialize on load
ns.Core.Initialize()
