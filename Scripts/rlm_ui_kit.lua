-- Reusable UMG components. The host owns widget lifetimes, input and textures.
local glass = require("rlm_glass")
local themes = require("rlm_ui_theme")
local M = { VERSION = "0.5.2" }

function M.style_button_label(text)
    pcall(function()
        text:SetVisibility(3)
        text:SetAutoWrapText(false)
        text:SetShadowOffset({ X = 1, Y = 1 })
        text:SetShadowColorAndOpacity({ R = 0, G = 0, B = 0, A = 0.9 })
    end)
end

function M.new(host)
    local valid, construct, sized, pad = host.valid, host.construct, host.sized, host.pad
    local new_text, load_class, make_game_button = host.new_text, host.load_class, host.make_game_button
    local set_visible, TEXT_CLASS = host.set_visible, host.text_class
    local theme = themes.defaults()

    local function apply_surface(border, scheme, max_radius)
        return glass.apply(border, scheme, theme, max_radius)
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

    local function is_hovered(widget)
        if not valid(widget) then return false end
        local ok, hovered = pcall(function() return widget:IsHovered() end)
        return ok and hovered == true
    end

    local function texture_image(tree, texture, color)
        if not valid(texture) then return nil end
        local image = construct(tree, "Image")
        if not valid(image) then return nil end
        local ok = pcall(function()
            image:SetBrushFromTexture(texture, false)
            image:SetColorAndOpacity(color)
            image:SetVisibility(3)
        end)
        return ok and image or nil
    end

    local function make_fireflies(tree, overlay, texture, centered, label_inset)
        local flies = {}
        for index = 1, 2 do
            local image = texture_image(tree, texture, index == 1 and theme.colors.gold or theme.colors.accent)
            local diameter = index == 1 and 15 or 10
            local dot = image and sized(tree, image, diameter, diameter)
            if valid(dot) then
                local slot = overlay:AddChildToOverlay(dot)
                if valid(slot) then
                    pcall(function() dot:SetVisibility(1) end)
                    pcall(function()
                        slot:SetHorizontalAlignment(centered and 2 or 1)
                        slot:SetVerticalAlignment(2)
                    end)
                    pad(slot, centered and 0 or label_inset - diameter / 2, 0, 0, 0)
                    flies[#flies + 1] = dot
                end
            end
        end
        return #flies > 0 and flies or nil
    end

    local function firefly_position(progress, width, radius)
        -- Straight runs keep the sparks above and below the text. The two
        -- semicircles turn around its ends at the same speed.
        local turn = math.pi * radius
        local distance = progress * (2 * width + 2 * turn)
        if distance < width then return distance, -radius end
        distance = distance - width
        if distance < turn then
            local angle = distance / radius
            return width + radius * math.sin(angle), -radius * math.cos(angle)
        end
        distance = distance - turn
        if distance < width then return width - distance, radius end
        local angle = (distance - width) / radius
        return -radius * math.sin(angle), radius * math.cos(angle)
    end

    local function animate_fireflies(entry, hovered)
        if not entry or not entry.fireflies then return end
        local frame = entry.firefly_frame
        if not hovered and not frame then return end
        if hovered and not entry.firefly_width then
            local width
            if valid(entry.label) then
                local ok, measured = pcall(function() return tonumber(entry.label:GetDesiredSize().X) end)
                if ok and measured and measured > 0 then width = measured end
            end
            local text = entry.firefly_label or ""
            entry.firefly_width = width or math.max(1, #text * theme.typography.control * 0.58)
        end
        local radius = math.min(theme.spacing.row / 2 - 6, theme.typography.control / 2 + 5)
        for index, dot in ipairs(entry.fireflies) do
            if valid(dot) then
                pcall(function()
                    if not hovered then
                        dot:SetVisibility(1)
                        return
                    end
                    if not frame then dot:SetVisibility(3) end
                    local progress = ((frame or 0) / 108 + 0.1 + (index - 1) * 0.46) % 1
                    local fade = math.min(((frame or 0) + 1) / 5, 1)
                    local x, y = firefly_position(progress, entry.firefly_width, radius)
                    if entry.firefly_centered then x = x - entry.firefly_width / 2 end
                    dot:SetRenderOpacity(fade * (0.77 + 0.18 * math.sin(progress * 2 * math.pi)))
                    dot:SetRenderTranslation({ X = x, Y = y })
                end)
            end
        end
        entry.firefly_frame = hovered and (frame or 0) + 1 or nil
        if not hovered then entry.firefly_width = nil end
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
        M.style_button_label(text)
        local text_slot = overlay:AddChildToOverlay(text)
        local centered = options.center == true
        local label_inset = centered and 8 or 16
        pcall(function()
            text_slot:SetHorizontalAlignment(centered and 2 or 1)
            text_slot:SetVerticalAlignment(2)
            text_slot:SetPadding({ Left = label_inset, Top = 0, Right = centered and 8 or 10, Bottom = 0 })
        end)
        local fireflies = options.fireflies and make_fireflies(tree, overlay, options.fireflies, centered, label_inset)
        if fireflies and valid(button) then
            pcall(function() overlay:SetVisibility(0) end)
            pcall(function() button:SetRenderOpacity(0.004) end)
        end
        return { button = button, widget = overlay, label = text, text_slot = text_slot, accent = accent,
            normal = options.color or theme.colors.cream, selected = options.selected or theme.colors.gold,
            fireflies = fireflies, firefly_label = fireflies and tostring(label or "") or nil,
            firefly_centered = fireflies and centered }
    end

    local function make_icon_button(controller, texture, like, tree)
        local entry = make_panel_button(controller, "", like, tree,
            { center = true, accent = "iconButton" })
        if not entry or not valid(entry.label) or not valid(entry.accent) then return entry end
        local icon = texture_image(tree, texture, theme.colors.cream)
        if not icon then return entry end
        local line, text_class = construct(tree, "HorizontalBox"), load_class(TEXT_CLASS)
        if not valid(line) or not text_class then return entry end
        local hint = new_text(tree, text_class, "", theme.typography.caption, theme.colors.cream)
        if not valid(hint) then return entry end
        M.style_button_label(hint)
        set_visible(hint, false)
        local hint_slot = line:AddChildToHorizontalBox(hint)
        if valid(hint_slot) then
            pcall(function() hint_slot:SetVerticalAlignment(2) end)
            pad(hint_slot, 0, 0, 8, 0)
        end
        local diameter = theme.spacing.row
        local overlay = entry.widget
        local icon_holder = sized(tree, icon, 22, 22)
        if not valid(icon_holder) then return entry end
        local icon_slot = overlay:AddChildToOverlay(icon_holder)
        if not valid(icon_slot) then return entry end
        pcall(function()
            icon_holder:SetVisibility(3)
            icon_slot:SetHorizontalAlignment(2)
            icon_slot:SetVerticalAlignment(2)
            icon:SetRenderTransformPivot({ X = 0.5, Y = 0.5 })
            overlay:SetVisibility(0)
        end)
        line:AddChildToHorizontalBox(sized(tree, overlay, diameter, diameter))
        apply_surface(entry.accent, "iconButton", diameter / 2)
        pcall(function() entry.accent:SetRenderOpacity(0.78) end)
        if valid(entry.button) then pcall(function() entry.button:SetRenderOpacity(0.004) end) end
        entry.widget, entry.icon_widget, entry.hint, entry.hit_target = line, icon, hint, overlay
        return entry
    end

    local function animate_icon_button(entry, visible)
        if not entry or not entry.icon_widget then return end
        local hovered = visible and is_hovered(entry.hit_target)
        if hovered ~= entry.hovered and valid(entry.hint) then
            pcall(function() entry.hint:SetVisibility(hovered and 3 or 1) end)
        end
        entry.hovered = hovered
        local previous = entry.hover_amount or 0
        local amount = hovered and math.min(previous + 0.25, 1) or math.max(previous - 0.25, 0)
        if not visible then amount = 0 end
        if amount ~= previous then
            local scale = 1 + amount * 0.12
            if valid(entry.accent) then pcall(function() entry.accent:SetRenderOpacity(0.78 + amount * 0.22) end) end
            if valid(entry.icon_widget) then
                pcall(function() entry.icon_widget:SetRenderScale({ X = scale, Y = scale }) end)
            end
            entry.hover_amount = amount
        end
        if entry.spin_frame then
            local progress = visible and math.min((entry.spin_frame + 1) / 10, 1) or 1
            local angle = progress < 1 and 360 * progress * progress * (3 - 2 * progress) or 0
            if valid(entry.icon_widget) then pcall(function() entry.icon_widget:SetRenderTransformAngle(angle) end) end
            entry.spin_frame = progress < 1 and entry.spin_frame + 1 or nil
        end
    end

    local function update_panel_button(entry, label, selected, color)
        if not entry then return end
        local caption = tostring(label or "")
        if entry.fireflies and entry.firefly_label ~= caption then
            entry.firefly_label, entry.firefly_width = caption, nil
        end
        entry.normal = color or entry.normal or theme.colors.cream
        if valid(entry.label) then
            pcall(function()
                entry.label:SetText(FText(entry.icon_widget and "" or caption))
                entry.label:SetColorAndOpacity({
                    SpecifiedColor = entry.enabled == false and theme.colors.disabled
                        or (selected == true and (entry.selected or theme.colors.gold) or entry.normal),
                    ColorUseRule = 0,
                })
            end)
            if valid(entry.hint) then pcall(function() entry.hint:SetText(FText(caption)) end) end
        elseif valid(entry.button) then
            pcall(function() entry.button:SetLabelText(FText(caption)) end)
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

    local function make_pagination(controller, like, tree)
        local line, text_class = construct(tree, "HorizontalBox"), load_class(TEXT_CLASS)
        if not valid(line) or not text_class then return nil end
        local style = { center = true, size = theme.typography.caption, accent = "inset" }
        local previous = make_panel_button(controller, "‹ Previous", like, tree, style)
        local following = make_panel_button(controller, "Next ›", like, tree, style)
        local label = new_text(tree, text_class, "", theme.typography.caption, theme.colors.muted)
        if not previous or not following or not valid(label) then return nil end
        M.style_button_label(label)
        line:AddChildToHorizontalBox(sized(tree, previous.widget, 94, theme.spacing.row))
        local label_slot = line:AddChildToHorizontalBox(label)
        if valid(label_slot) then
            label_slot:SetVerticalAlignment(2)
            pad(label_slot, 12, 0, 12, 0)
        end
        line:AddChildToHorizontalBox(sized(tree, following.widget, 80, theme.spacing.row))
        return { widget = line, label = label, previous = previous, next = following }
    end

    local function update_pagination(entry, page)
        if not entry then return end
        set_visible(entry.widget, page ~= nil)
        if not page then return end
        if valid(entry.label) then
            pcall(function() entry.label:SetText(FText(("%d / %d"):format(page.page, page.pages))) end)
        end
        for direction, title in pairs({ previous = "‹ Previous", next = "Next ›" }) do
            local button = entry[direction]
            local enabled = page[direction] ~= nil
            if button.enabled ~= enabled and valid(button.label) and valid(button.button) then
                pcall(function() button.button:SetRenderOpacity(enabled and 1 or 0.004) end)
            end
            set_button_enabled(button, enabled)
            update_panel_button(button, title, false)
            show_button_accent(button, enabled)
        end
    end

    return {
        set_theme = function(value) theme = value end,
        apply_surface = apply_surface,
        style_input = style_input,
        surface_with_shadow = surface_with_shadow,
        make_button = make_panel_button,
        make_icon_button = make_icon_button,
        update_button = update_panel_button,
        is_hovered = is_hovered,
        animate_fireflies = animate_fireflies,
        animate_icon_button = animate_icon_button,
        make_pagination = make_pagination,
        update_pagination = update_pagination,
        show_button_accent = show_button_accent,
        set_button_enabled = set_button_enabled,
        prepare_row_icon = prepare_row_icon,
        render_preview = render_preview,
    }
end

return M
