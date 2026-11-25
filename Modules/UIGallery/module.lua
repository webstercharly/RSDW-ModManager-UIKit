local M = {}
local examples = {
    {
        id = "sandwich",
        title = "Glazed Pumpkin Sandwich",
        icon = "T_Icon_Sandwich_Glazed_Pumpkin_Roast",
        description = "Compare the main artwork with the ingredient thumbnails, and check label readability against the game scene.",
        stats = { { label = "Stack limit", value = 50 }, { label = "Unit weight", value = "2 kg" } },
        benefits = "Health +80  ·  Sustenance +100  ·  Perk duration 10 min\n"
            .. "XP gain +10%\nWoodcutting and Mining stamina cost −33%\nHeals 8 health every 5 seconds",
        ingredients = {
            { title = "Dried Redberries", count = 1, icon = "T_Icon_Dried_Redberries" },
            { title = "Roast Pumpkin", count = 1, icon = "T_Icon_Roasted_Pumkin" },
            { title = "Maple Syrup", count = 1, icon = "T_Icon_Maple_Syrup" },
            { title = "Bread", count = 1, icon = "T_Icon_Bread" },
        },
        recipe = "1 × Dried Redberries  ·  1 × Roast Pumpkin  ·  1 × Maple Syrup  ·  1 × Bread",
    },
    {
        id = "text",
        title = "Text-only card",
        description = "Uses the full card width when no artwork is available.",
        stats = { { label = "Spawn level", value = "Native" }, { label = "Amount", value = 1 },
            { label = "On spawn", value = "Calm" } },
    },
    { id = "unavailable", title = "Unavailable row", disabled = true },
}
local selected, query = examples[1], ""

local function matches(example)
    return example.title:lower():find(query:lower(), 1, true) ~= nil
end

function M.activate(state)
    local rows = {}
    for _, example in ipairs(examples) do
        if matches(example) then
            rows[#rows + 1] = { title = example.title, value = example.id, icon = example.icon,
                selected = example == selected, disabled = example.disabled }
        end
    end
    if #rows == 0 then rows[1] = { title = "No matching examples", value = "empty", disabled = true } end
    return {
        status = state.uiThemeName or "Graphite",
        preview = selected,
        rows = rows,
        poolRows = true,
        inputValue = query,
        focusInput = selected == nil,
    }
end

function M.select_row(_, value)
    for _, example in ipairs(examples) do
        if example.id == value and matches(example) and not example.disabled then selected = example end
    end
    return true
end

function M.run_action(_, action, input)
    if action == "reset" then
        selected, query = examples[1], ""
        return true, nil, { preserveInput = true }
    end
    if action == "search" then
        query = tostring(input or ""):match("^%s*(.-)%s*$")
        selected = nil
        return true, nil, { preserveInput = true }
    end
    return false, "Action unavailable"
end

return M
