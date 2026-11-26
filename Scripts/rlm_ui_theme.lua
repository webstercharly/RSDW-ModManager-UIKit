-- UI Kit theme data. Values are Slate units and linear RGBA.
local M = {}
local active

local function rgba(r, g, b, a)
    return { R = r, G = g, B = b, A = a or 1 }
end

local function surface(radius, r, g, b, alpha, edge, highlight)
    return { radius = radius, fill = rgba(r, g, b, alpha), edge = edge, highlight = highlight or 0 }
end

function M.defaults()
    return {
        name = "Graphite",
        colors = {
            gold = rgba(0.91, 0.77, 0.48),
            cream = rgba(0.94, 0.91, 0.84),
            muted = rgba(0.76, 0.74, 0.69),
            disabled = rgba(0.49, 0.49, 0.47),
            edge = rgba(0.79, 0.85, 0.94),
            accent = rgba(0.94, 0.73, 0.45),
            input = rgba(0.031, 0.037, 0.047, 0.90),
            inputNormal = rgba(0.09, 0.10, 0.12, 0.90),
            inputHover = rgba(0.13, 0.15, 0.18, 0.92),
            inputFocus = rgba(0.24, 0.31, 0.41, 1),
        },
        spacing = {
            row = 38, thumbnail = 29, ingredient = 30, artwork = 172,
            cardInset = 18, cardGap = 17, cornerInset = 8,
        },
        typography = { control = 14, input = 17, title = 26, body = 15, caption = 12 },
        surfaces = {
            rail = surface(18, 0.012, 0.015, 0.021, 0.53, 0.17, 0.23),
            dock = surface(18, 0.016, 0.020, 0.028, 0.63, 0.18, 0.25),
            iconButton = surface(24, 0.025, 0.032, 0.044, 0.85, 0.30),
            card = surface(20, 0.015, 0.018, 0.024, 0.80, 0.11),
            hud = surface(12, 0.015, 0.018, 0.024, 0.87, 0.20),
            inset = surface(10, 0.105, 0.125, 0.154, 0.20, 0.09),
            stats = surface(10, 0.083, 0.099, 0.122, 0.16, 0.07),
            art = surface(100, 0.075, 0.084, 0.101, 0.09, 0),
            selected = surface(10, 0.065, 0.049, 0.030, 0.32, 0.36),
            primary = surface(10, 0.078, 0.055, 0.032, 0.28, 0.56),
            shadow = surface(18, 0, 0, 0, 0.20, 0),
        },
    }
end

local ranges = {
    row = { 34, 46 }, thumbnail = { 18, 32 }, ingredient = { 20, 36 },
    artwork = { 100, 190 }, cardInset = { 10, 24 }, cardGap = { 8, 22 }, cornerInset = { 0, 12 },
    control = { 12, 17 }, input = { 14, 20 }, title = { 20, 32 }, body = { 13, 18 }, caption = { 10, 14 },
}

local function number(value, low, high)
    return type(value) == "number" and value >= low and value <= high
end

local function apply_layer(target, patch, path)
    if type(patch) ~= "table" then return nil, path .. " must be a JSON object" end
    for key, value in pairs(patch) do
        local where = path .. "." .. tostring(key)
        local previous = target[key]
        if previous == nil then return nil, "unknown token " .. where end
        if type(previous) == "table" then
            local ok, problem = apply_layer(previous, value, where)
            if not ok then return nil, problem end
        elseif type(previous) == "number" then
            local range = ranges[key] or (key == "radius" and { 0, 120 }) or { 0, 1 }
            if not number(value, range[1], range[2]) then
                return nil, ("%s must be between %g and %g"):format(where, range[1], range[2])
            end
            target[key] = value
        elseif type(value) ~= "string" or #value < 1 or #value > 40 then
            return nil, where .. " must be 1–40 characters"
        else
            target[key] = value
        end
    end
    return true
end

function M.resolve(...)
    local theme = M.defaults()
    for index = 1, select("#", ...) do
        local source = select(index, ...)
        if type(source) ~= "table" or source.schemaVersion ~= 1 then
            return nil, "theme requires schemaVersion 1"
        end
        local tokens = {}
        for key, value in pairs(source) do if key ~= "schemaVersion" then tokens[key] = value end end
        local ok, problem = apply_layer(theme, tokens, "theme")
        if not ok then return nil, problem end
    end
    return theme
end

function M.read(path, decode)
    local file, open_error, code = io.open(path, "rb")
    if not file then
        if code == 2 then return nil end
        return nil, open_error
    end
    local bytes, read_error = file:read(32769)
    file:close()
    if read_error then return nil, read_error end
    bytes = bytes or ""
    if #bytes > 32768 then return nil, "theme exceeds 32 KiB" end
    if bytes:sub(1, 3) == "\239\187\191" then bytes = bytes:sub(4) end
    local ok, data = pcall(decode, bytes)
    if not ok then return nil, "invalid theme JSON: " .. tostring(data) end
    if type(data) ~= "table" then return nil, "theme root must be a JSON object" end
    return data
end

function M.load(decode, ...)
    local layers = {}
    for index = 1, select("#", ...) do
        local path = select(index, ...)
        if path then
            local data, problem = M.read(path, decode)
            if problem then return nil, path .. ": " .. problem end
            if data then layers[#layers + 1] = data end
        end
    end
    return M.resolve(table.unpack(layers))
end

function M.personal(decode)
    local root = os.getenv("LOCALAPPDATA")
    local path = root and root ~= "" and (root .. "\\RSDWLoadoutManager\\ui-theme.json") or nil
    return M.load(decode, path)
end

function M.set_active(theme)
    active = theme
end

function M.active()
    if not active then active = M.defaults() end
    return active
end

return M
