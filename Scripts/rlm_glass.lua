-- Static Slate surfaces for the manager. Brush fills and outlines stay on the
-- widget and require no material, captures, or recurring work.
local M = {}
local defaults = require("rlm_ui_theme").defaults()

function M.apply(border, scheme, theme)
    theme = theme or defaults
    local style = theme.surfaces[scheme]
    if not style or not border then return false end
    local radius, fill, edge = style.radius, style.fill, style.edge
    local tone = (scheme == "primary" or scheme == "selected") and theme.colors.accent or theme.colors.edge
    local colored = pcall(function()
        border:SetBrushColor(fill)
    end)
    if not colored then return false end

    local rounded = pcall(function()
        local brush = border.Background
        local outline = brush.OutlineSettings
        outline.CornerRadii = { X = radius, Y = radius, Z = radius, W = radius }
        outline.Width = edge > 0 and 1 or 0
        outline.RoundingType = 0 -- FixedRadius
        outline.bUseBrushTransparency = false
        outline.Color = { SpecifiedColor = { R = tone.R, G = tone.G, B = tone.B, A = edge },
            ColorUseRule = 0 }
        brush.DrawAs = 4 -- RoundedBox
        border:SetBrush(brush)
    end)
    return rounded
end

return M
