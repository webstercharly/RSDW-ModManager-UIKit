-- Static Slate surfaces for the manager. Brush fills and outlines stay on the
-- widget and require no material, captures, or recurring work.
local M = {}
local themes = require("rlm_ui_theme")
local panel_count = 0

function M.apply(border, scheme, theme, max_radius)
    theme = theme or themes.active()
    local style = theme.surfaces[scheme]
    if not style or not border then return false end
    local radius, fill, edge = style.radius, style.fill, style.edge
    if max_radius then radius = math.min(radius, max_radius) end
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

-- Attach the content to the game's panel first. The border preserves the
-- native layout and input path while drawing the shared HUD material.
function M.mount_panel(frame, content, valid, theme)
    local ok, host = pcall(function() return frame.PanelContent end)
    if not ok or not valid(host) then return false end
    local border
    pcall(function()
        local class = StaticFindObject("/Script/UMG.Border")
        if not valid(class) or not valid(frame.WidgetTree) then return end
        panel_count = panel_count + 1
        border = StaticConstructObject(class, frame.WidgetTree, FName("RSDWKit_Hud_" .. panel_count))
    end)
    if not valid(border) then return pcall(function() host:AddChild(content) end) end

    local attached = pcall(function()
        host:AddChild(border)
        border:AddChild(content)
    end)
    if not attached then return false end
    pcall(function() border:SetPadding({ Left = 0, Top = 0, Right = 0, Bottom = 0 }) end)
    if M.apply(border, "hud", theme) then
        pcall(function()
            local background = frame.BackgroundPanel
            if valid(background) then background:SetRenderOpacity(0.22) end
        end)
    end
    return true
end

return M
