-- Reusable UMG components. The host owns widget lifetimes, input and textures.
local glass = require("rlm_glass")
local themes = require("rlm_ui_theme")
local M = { VERSION = "0.3.0" }

function M.new(host)
    local valid, construct, sized, pad = host.valid, host.construct, host.sized, host.pad
    local new_text, load_class, make_game_button = host.new_text, host.load_class, host.make_game_button
    local set_visible, TEXT_CLASS = host.set_visible, host.text_class
    local theme = themes.defaults()

    local function apply_surface(border, scheme)
        return glass.apply(border, scheme, theme)
    end

    local function style_input(input)
        pcall(function()
            local function slate_color(value)
                return { SpecifiedColor = value, ColorUseRule = 0 }
            end
            local colors = theme.colors
            local style = input.WidgetStyle
            style.BackgroundColor = slate_color(colors.input)
            style.ForegroundColor = slate_color(colors.cream)
            style.FocusedForegroundColor = slate_color(colors.cream)
            for name, tint in pairs({
                BackgroundImageNormal = colors.inputNormal,
                BackgroundImageHovered = colors.inputHover,
                BackgroundImageFocused = colors.inputFocus,
            }) do
                local brush = style[name]
                brush.TintColor = slate_color(tint)
                style[name] = brush
            end
            pcall(function()
                local text_style = style.TextStyle
                local font = text_style.Font
                font.Size = theme.typography.input
                text_style.Font = font
                style.TextStyle = text_style
            end)
            input.WidgetStyle = style
        end)
        pcall(function()
            local font = input.WidgetStyle.TextStyle.Font
            font.Size = theme.typography.input
            input:SetFont(font)
        end)
    end

    local function glass_layer(tree, overlay, scheme, top_offset)
        local surface = construct(tree, "Border")
        if not surface then return nil end
        local slot = overlay:AddChildToOverlay(surface)
        -- Fill the overlay. The decoration stays out of the hit-test path.
        pcall(function()
            slot:SetHorizontalAlignment(0)
            slot:SetVerticalAlignment(0)
            surface:SetVisibility(3)
        end)
        pad(slot, 0, top_offset, 0, 0)
        apply_surface(surface, scheme)
        return surface
    end

    local function surface_with_shadow(tree, border, scheme)
        local overlay = construct(tree, "Overlay")
        if not overlay then return border end
        pcall(function() overlay:SetVisibility(4) end)
        glass_layer(tree, overlay, "shadow", 3)
        local slot = overlay:AddChildToOverlay(border)
        pcall(function()
            slot:SetHorizontalAlignment(0)
            slot:SetVerticalAlignment(0)
        end)
        pad(slot, 0, 0, 0, 3)
        local style = theme.surfaces[scheme]
        if style and (scheme == "rail" or scheme == "dock") and style.highlight > 0 then
            local highlight = construct(tree, "Border")
            local holder = highlight and sized(tree, highlight, nil, 1)
            if holder then
                local highlight_slot = overlay:AddChildToOverlay(holder)
                pcall(function()
                    holder:SetVisibility(3)
                    highlight_slot:SetHorizontalAlignment(0)
                    highlight_slot:SetVerticalAlignment(1)
                    pad(highlight_slot, style.radius, 1, style.radius, 0)
                    local edge = theme.colors.edge
                    highlight:SetBrushColor({ R = edge.R, G = edge.G, B = edge.B, A = style.highlight })
                end)
            end
        end
        return overlay
    end

    local function show_button_accent(entry, shown)
        if entry and valid(entry.accent) then
            pcall(function() entry.accent:SetVisibility(shown and 3 or 1) end)
        end
    end

    -- The pause-menu button's built-in label is intentionally large and subdued.
    -- Keep its proven click/selection behavior, but draw a compact high-contrast
    -- label above it for the manager's navigation, rows and actions.
    local function make_panel_button(controller, label, like, tree, options)
        options = options or {}
        local button = make_game_button(controller, "", like)
        if not button then return nil end
        -- The shell owns selection. CommonUI's latched selected/focused brush
        -- otherwise remains visible on clicked navigation and pooled controls.
        pcall(function() button:SetIsSelectable(false) end)
        pcall(function() button:SetShouldSelectUponReceivingFocus(false) end)
        pcall(function() button:SetIsFocusable(false) end)
        local overlay = construct(tree, "Overlay")
        local text_class = load_class(TEXT_CLASS)
        if not overlay or not text_class then
            pcall(function() button:SetLabelText(FText(tostring(label or ""))) end)
            return { button = button, widget = button, label = nil,
                normal = options.color or theme.colors.cream, selected = options.selected or theme.colors.gold }
        end
        pcall(function() overlay:SetVisibility(4) end)
        local button_slot = overlay:AddChildToOverlay(button)
        pcall(function()
            button_slot:SetHorizontalAlignment(0)
            button_slot:SetVerticalAlignment(0)
        end)
        local accent = options.accent and glass_layer(tree, overlay, options.accent, 0)
        if accent then pcall(function() accent:SetVisibility(1) end) end
        local text = new_text(tree, text_class, tostring(label or ""), options.size or theme.typography.control,
            options.color or theme.colors.cream)
        pcall(function()
            text:SetVisibility(3)
            text:SetAutoWrapText(false)
            text:SetShadowOffset({ X = 1, Y = 1 })
            text:SetShadowColorAndOpacity({ R = 0, G = 0, B = 0, A = 0.9 })
        end)
        local text_slot = overlay:AddChildToOverlay(text)
        pcall(function()
            text_slot:SetHorizontalAlignment(options.center == true and 2 or 1)
            text_slot:SetVerticalAlignment(2)
            text_slot:SetPadding({ Left = options.center == true and 8 or 16,
                Top = 0, Right = options.center == true and 8 or 10, Bottom = 0 })
        end)
        return { button = button, widget = overlay, label = text, text_slot = text_slot, accent = accent,
            normal = options.color or theme.colors.cream, selected = options.selected or theme.colors.gold }
    end

    local function update_panel_button(entry, label, selected, color)
        if not entry then return end
        entry.normal = color or entry.normal or theme.colors.cream
        if valid(entry.label) then
            pcall(function()
                entry.label:SetText(FText(tostring(label or "")))
                entry.label:SetColorAndOpacity({
                    SpecifiedColor = entry.enabled == false and theme.colors.disabled
                        or (selected == true and (entry.selected or theme.colors.gold) or entry.normal),
                    ColorUseRule = 0,
                })
            end)
        elseif valid(entry.button) then
            pcall(function() entry.button:SetLabelText(FText(tostring(label or ""))) end)
        end
    end

    local function prepare_row_icon(panel, entry, icon, left)
        if icon and not entry.image and valid(entry.text_slot) then
            local image = construct(panel.tree, "Image")
            if valid(image) then
                local holder = sized(panel.tree, image, theme.spacing.thumbnail, theme.spacing.thumbnail)
                local slot = entry.overlay:AddChildToOverlay(holder)
                if valid(slot) then
                    slot:SetHorizontalAlignment(1)
                    slot:SetVerticalAlignment(2)
                    holder:SetVisibility(1)
                    entry.image, entry.image_holder, entry.image_slot = image, holder, slot
                end
            end
        end
        if entry.icon ~= icon then
            entry.icon, entry.icon_attempts, entry.icon_retry_at, entry.icon_done = icon, 0, 0, false
            if valid(entry.image_holder) then entry.image_holder:SetVisibility(1) end
        end
        if valid(entry.image_slot) then pad(entry.image_slot, left, 0, 0, 0) end
        if valid(entry.text_slot) then
            pad(entry.text_slot, left + (icon and entry.image and theme.spacing.thumbnail + 7 or 0), 0, 10, 0)
        end
    end

    local function ingredient_cell(panel, grid, index)
        local tree = panel.tree
        local text_class = load_class(TEXT_CLASS)
        local frame, line = construct(tree, "Border"), construct(tree, "HorizontalBox")
        local image = construct(tree, "Image")
        if not (text_class and frame and line and image) then return nil end
        local spacing = theme.spacing
        local reserved = spacing.artwork + spacing.cornerInset * 2 + spacing.cardGap + spacing.cardInset * 2 + 30
        local width = math.floor(((panel.content_width or 760) - reserved) / 2)
        local holder = sized(tree, frame, width)
        local slot = grid:AddChildToUniformGrid(holder, math.floor((index - 1) / 2), (index - 1) % 2)
        if not valid(slot) then return nil end
        frame:AddChild(line)
        apply_surface(frame, "inset")
        frame:SetPadding({ Left = 9, Top = 5, Right = 9, Bottom = 5 })
        local image_holder = sized(tree, image, theme.spacing.ingredient, theme.spacing.ingredient)
        local image_slot = line:AddChildToHorizontalBox(image_holder)
        pad(image_slot, 0, 0, 6, 0)
        set_visible(image_holder, false)
        local label = new_text(tree, text_class, "", 13, theme.colors.cream)
        pcall(function() label:SetAutoWrapText(true) end)
        local label_slot = line:AddChildToHorizontalBox(label)
        label_slot:SetSize({ Value = 1, SizeRule = 1 })
        label_slot:SetVerticalAlignment(2)
        return { holder = holder, image = image, image_holder = image_holder, label = label }
    end

    local function render_ingredients(panel, card, ingredients)
        if not valid(card.ingredient_grid) or card.grid_failed or type(ingredients) ~= "table" or #ingredients == 0 then
            return nil
        end
        local pending = {}
        local count = math.min(#ingredients, 8)
        for index = 1, count do
            local cell = card.ingredient_cells[index]
            if not cell then
                cell = ingredient_cell(panel, card.ingredient_grid, index)
                if not cell then return nil end
                card.ingredient_cells[index] = cell
            end
            local ingredient = ingredients[index]
            cell.label:SetText(FText(tostring(ingredient.count) .. " × " .. ingredient.title))
            local icon = ingredient.icon ~= "" and ingredient.icon or nil
            if cell.icon ~= icon then
                cell.icon, cell.icon_attempts, cell.icon_retry_at, cell.icon_done = icon, 0, 0, false
                set_visible(cell.image_holder, false)
            end
            if icon then pending[#pending + 1] = cell end
            set_visible(cell.holder, true)
        end
        for index = count + 1, #card.ingredient_cells do
            set_visible(card.ingredient_cells[index].holder, false)
        end
        return pending
    end

    local function build_item_preview(panel)
        local tree = panel.tree
        local text_class = load_class(TEXT_CLASS)
        local frame, line = construct(tree, "Border"), construct(tree, "HorizontalBox")
        local art, image = construct(tree, "Border"), construct(tree, "Image")
        local body, stats = construct(tree, "VerticalBox"), construct(tree, "HorizontalBox")
        if not (text_class and frame and line and art and image and body and stats) then return nil end

        frame:AddChild(line)
        pad(panel.preview_box:AddChildToVerticalBox(frame), 0, 5, 6, 12)
        apply_surface(frame, "card")
        local spacing = theme.spacing
        local inset = spacing.cardInset
        frame:SetPadding({ Left = inset, Top = inset, Right = inset, Bottom = inset })

        local image_holder = sized(tree, image, spacing.artwork, spacing.artwork)
        art:AddChild(image_holder)
        local art_slot = line:AddChildToHorizontalBox(art)
        art_slot:SetVerticalAlignment(1)
        pad(art_slot, 0, 0, spacing.cardGap, 0)
        apply_surface(art, "art")
        local corner = spacing.cornerInset
        art:SetPadding({ Left = corner, Top = corner, Right = corner, Bottom = corner })
        local body_slot = line:AddChildToHorizontalBox(body)
        body_slot:SetSize({ Value = 1, SizeRule = 1 })

        local title = new_text(tree, text_class, "", theme.typography.title, theme.colors.gold)
        local description = new_text(tree, text_class, "", theme.typography.body, theme.colors.cream)
        local benefits_heading = new_text(tree, text_class, "On use", 13, theme.colors.gold)
        local benefits = new_text(tree, text_class, "", theme.typography.body, theme.colors.cream)
        local recipe_heading = new_text(tree, text_class, "Recipe ingredients", 13, theme.colors.gold)
        local recipe_summary = new_text(tree, text_class, "", 14, theme.colors.cream)
        local footnote = new_text(tree, text_class, "", theme.typography.caption, theme.colors.muted)
        for _, block in ipairs({ title, description, benefits, recipe_summary, footnote }) do
            -- The installed game exposes auto-wrap, but does not expose the
            -- optional SetWrapTextAt method. The fill slot constrains the width.
            pcall(function() block:SetAutoWrapText(true) end)
        end
        pad(body:AddChildToVerticalBox(title), 0, 0, 0, 6)
        pad(body:AddChildToVerticalBox(description), 0, 0, 0, 10)
        local stats_holder = construct(tree, "Border") or stats
        if stats_holder ~= stats then
            stats_holder:AddChild(stats)
            apply_surface(stats_holder, "stats")
            stats_holder:SetPadding({ Left = 12, Top = 7, Right = 12, Bottom = 7 })
        end
        pad(body:AddChildToVerticalBox(stats_holder), 0, 0, 0, 13)
        pad(body:AddChildToVerticalBox(benefits_heading), 0, 0, 0, 3)
        pad(body:AddChildToVerticalBox(benefits), 0, 0, 0, 13)
        pad(body:AddChildToVerticalBox(recipe_heading), 0, 0, 0, 3)
        local ingredient_grid = construct(tree, "UniformGridPanel")
        if ingredient_grid then
            pad(body:AddChildToVerticalBox(ingredient_grid), 0, 0, 0, 8)
            pcall(function()
                ingredient_grid:SetSlotPadding({ Left = 0, Top = 2, Right = 6, Bottom = 3 })
            end)
        end
        pad(body:AddChildToVerticalBox(recipe_summary), 0, 0, 0, 10)
        body:AddChildToVerticalBox(footnote)

        local cells = {}
        for index = 1, 3 do
            local column = construct(tree, "VerticalBox")
            if not column then break end
            local divider, divider_holder
            if index > 1 then
                divider = construct(tree, "Border")
                if divider then
                    divider:SetBrushColor({ R = 0.79, G = 0.85, B = 0.94, A = 0.16 })
                    divider_holder = sized(tree, divider, 1, 29)
                    local slot = stats:AddChildToHorizontalBox(divider_holder)
                    slot:SetVerticalAlignment(2)
                    pad(slot, 0, 0, 13, 0)
                end
            end
            local label = new_text(tree, text_class, "", 11, theme.colors.muted)
            local value = new_text(tree, text_class, "", 17, theme.colors.cream)
            column:AddChildToVerticalBox(label)
            column:AddChildToVerticalBox(value)
            local slot = stats:AddChildToHorizontalBox(column)
            slot:SetSize({ Value = 1, SizeRule = 1 })
            pad(slot, 0, 0, 7, 0)
            cells[index] = { holder = column, divider = divider_holder, label = label, value = value }
        end
        return { art = art, image = image, image_holder = image_holder, title = title,
            description = description, benefits_heading = benefits_heading, benefits = benefits,
            recipe_heading = recipe_heading, recipe_summary = recipe_summary,
            ingredient_grid = ingredient_grid, ingredient_cells = {},
            footnote = footnote, stats = stats_holder, cells = cells }
    end

    local function render_preview(panel, preview)
        panel.preview_icon = nil
        panel.ingredient_icons = nil
        if not valid(panel.preview_box) then return end
        set_visible(panel.preview_box, false)
        if type(preview) ~= "table" then return end
        if panel.item_preview == nil then
            panel.item_preview = false
            panel.item_preview = build_item_preview(panel) or false
        end
        local card = panel.item_preview
        if not card then return end
        card.title:SetText(FText(tostring(preview.title or "")))
        card.description:SetText(FText(tostring(preview.description or "")))
        local benefits = type(preview.benefits) == "string" and preview.benefits or ""
        card.benefits:SetText(FText(benefits))
        set_visible(card.benefits_heading, benefits ~= "")
        set_visible(card.benefits, benefits ~= "")
        local recipe = tostring(preview.recipe or "")
        local ok, ingredients = pcall(render_ingredients, panel, card, preview.ingredients)
        if not ok then
            card.grid_failed = true
            if host.warn then host.warn("ingredient tiles unavailable: " .. tostring(ingredients)) end
        end
        local grid_shown = ok and ingredients ~= nil
        if grid_shown then panel.ingredient_icons = ingredients end
        card.recipe_summary:SetText(FText(recipe))
        set_visible(card.recipe_heading, grid_shown or recipe ~= "")
        set_visible(card.ingredient_grid, grid_shown)
        set_visible(card.recipe_summary, not grid_shown and recipe ~= "")
        card.footnote:SetText(FText(tostring(preview.footnote or "")))
        set_visible(card.description, tostring(preview.description or "") ~= "")
        set_visible(card.footnote, tostring(preview.footnote or "") ~= "")
        local stats = preview.stats or {}
        set_visible(card.stats, #stats > 0)
        for index, cell in ipairs(card.cells) do
            local stat = stats[index]
            set_visible(cell.holder, stat ~= nil)
            set_visible(cell.divider, stat ~= nil)
            if stat then
                cell.label:SetText(FText(tostring(stat.label)))
                cell.value:SetText(FText(tostring(stat.value)))
            end
        end
        local icon = type(preview.icon) == "string" and preview.icon ~= "" and preview.icon or nil
        if card.icon ~= icon then
            card.icon, card.icon_attempts, card.icon_retry_at = icon, 0, 0
            card.icon_done, card.icon_visible = false, false
            set_visible(card.image_holder, false)
        end
        set_visible(card.art, icon ~= nil and (not card.icon_done or card.icon_visible))
        if icon then panel.preview_icon = card end
        set_visible(panel.preview_box, true)
        return true
    end

    local function set_button_enabled(entry, enabled)
        if entry.enabled == enabled then return end
        entry.enabled = enabled
        if valid(entry.button) then
            pcall(function() entry.button:SetIsEnabled(enabled) end)
        end
    end

    return {
        set_theme = function(value) theme = value end,
        apply_surface = apply_surface,
        style_input = style_input,
        surface_with_shadow = surface_with_shadow,
        make_button = make_panel_button,
        update_button = update_panel_button,
        show_button_accent = show_button_accent,
        set_button_enabled = set_button_enabled,
        prepare_row_icon = prepare_row_icon,
        render_preview = render_preview,
    }
end

return M
