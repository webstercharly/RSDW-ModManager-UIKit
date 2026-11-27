import json
import tempfile
import unittest
from pathlib import Path

from lupa import LuaRuntime


ROOT = Path(__file__).resolve().parents[2]


class UIKitTests(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.globals().scripts = (ROOT / "Scripts").as_posix()
        self.lua.globals().gallery_path = (ROOT / "Modules/UIGallery/module.lua").as_posix()
        self.lua.execute('package.path = scripts .. "/?.lua;" .. package.path')

    def test_theme_overrides_merge_and_validate(self):
        self.lua.execute("""
            local themes = require("rlm_ui_theme")
            local installed = { schemaVersion = 1, surfaces = { card = { radius = 21 } } }
            local personal = { schemaVersion = 1, name = "Ink", surfaces = { card = { fill = { A = 0.95 } } } }
            local theme = assert(themes.resolve(installed, personal))
            assert(theme.name == "Ink" and theme.surfaces.card.radius == 21)
            assert(theme.surfaces.card.fill.A == 0.95 and theme.surfaces.card.fill.R == 0.015)
            assert(themes.defaults().surfaces.card.fill.A == 0.80)
            assert(not themes.resolve({ schemaVersion = 2 }))
            assert(not themes.resolve({ schemaVersion = 1, spacing = { row = 0 } }))
            assert(not themes.resolve({ schemaVersion = 1, colors = { typo = 1 } }))
        """)

    def test_theme_file_bom_missing_and_size_limit(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "ui-theme.json"
            self.lua.globals().theme_path = path.as_posix()
            self.lua.execute("""
                read_theme = require("rlm_ui_theme").read
                function decoder(text)
                    assert(text == '{"schemaVersion":1}')
                    return { schemaVersion = 1 }
                end
                local data, problem = read_theme(theme_path, decoder)
                assert(data == nil and problem == nil)
            """)
            path.write_text('{"schemaVersion":1}', encoding="utf-8-sig")
            self.lua.execute("assert(read_theme(theme_path, decoder).schemaVersion == 1)")
            path.write_bytes(b" " * 32769)
            self.lua.execute("""
                local data, problem = read_theme(theme_path, decoder)
                assert(data == nil and problem == "theme exceeds 32 KiB")
            """)

    def test_rounded_surface_uses_resolved_color_and_radius(self):
        self.lua.execute("""
            local theme = assert(require("rlm_ui_theme").resolve({ schemaVersion = 1,
                surfaces = { rail = { radius = 14, fill = { A = 0.68 }, edge = 0.24 } } }))
            local border = { Background = { OutlineSettings = {} } }
            function border:SetBrushColor(color) self.color = color end
            function border:SetBrush(brush) self.brush = brush end
            assert(require("rlm_glass").apply(border, "rail", theme))
            assert(border.color.A == 0.68 and border.brush.DrawAs == 4)
            assert(border.brush.OutlineSettings.CornerRadii.X == 14)
            assert(border.brush.OutlineSettings.Color.SpecifiedColor.A == 0.24)
            assert(require("rlm_glass").apply(border, "iconButton", theme, 19))
            assert(border.brush.OutlineSettings.CornerRadii.X == 19)
        """)

    def test_native_hud_mount_uses_active_theme_and_preserves_content(self):
        self.lua.execute("""
            local themes = require("rlm_ui_theme")
            local glass = require("rlm_glass")
            local valid = function(widget) return type(widget) == "table" end
            local host, background = {}, {}
            function host:AddChild(child) self.child = child end
            function background:SetRenderOpacity(opacity) self.opacity = opacity end
            local frame, content = { PanelContent = host, WidgetTree = {}, BackgroundPanel = background }, {}
            function StaticFindObject() return {} end
            function FName(name) return name end
            function StaticConstructObject()
                return {
                    Background = { OutlineSettings = {} },
                    AddChild = function(self, child) self.child = child end,
                    SetPadding = function() end,
                    SetBrushColor = function(self, color) self.color = color end,
                    SetBrush = function(self, brush) self.brush = brush end,
                }
            end
            themes.set_active(assert(themes.resolve({ schemaVersion = 1,
                surfaces = { hud = { fill = { A = 0.92 } } } })))
            assert(glass.mount_panel(frame, content, valid))
            assert(host.child.child == content and host.child.color.A == 0.92)
            assert(host.child.brush.DrawAs == 4 and background.opacity == 0.22)
            function StaticFindObject() return nil end
            assert(glass.mount_panel(frame, content, valid))
            assert(host.child == content)
        """)

    def test_disabled_button_can_be_reused_as_enabled(self):
        self.lua.execute("""
            FText = function(s) return s end
            local kit = require("rlm_ui_kit").new({ valid = function(widget) return widget ~= nil end })
            local button, label = {}, {}
            function button:SetIsEnabled(enabled) self.enabled = enabled end
            function button:SetRenderOpacity(opacity) self.opacity = opacity end
            function label:SetText(text) self.text = text end
            function label:SetColorAndOpacity(color) self.color = color.SpecifiedColor end
            local entry = { button = button, label = label }
            kit.set_button_enabled(entry, false)
            kit.update_button(entry, "Unavailable", false)
            assert(button.enabled == false and button.opacity == 0 and label.color.R == 0.49)
            kit.style_action(entry, true, true)
            kit.update_button(entry, "Selected", true)
            assert(button.enabled == true and button.opacity == 1 and label.color.R == 0.91)
        """)

    def test_control_feedback_resets_after_hover_spin_and_close(self):
        self.lua.execute("""
            local function widget()
                return {
                    SetVisibility = function(self, value) self.visibility = value end,
                    SetRenderOpacity = function(self, value) self.opacity = value end,
                    SetRenderScale = function(self, value) self.scale = value end,
                    SetRenderTransformAngle = function(self, value) self.angle = value end,
                    SetRenderTranslation = function(self, value) self.translation = value end,
                    IsHovered = function(self) return self.hovered end,
                }
            end
            local kit = require("rlm_ui_kit").new({ valid = function(value) return value ~= nil end })
            local icon = { icon_widget = widget(), hit_target = widget(), accent = widget(), hint = widget() }
            icon.hit_target.hovered = true
            for _ = 1, 4 do kit.animate_icon_button(icon, true) end
            assert(icon.hint.visibility == 3 and icon.icon_widget.scale.X == 1.12 and icon.accent.opacity == 1)
            icon.spin_frame = 0
            kit.animate_icon_button(icon, true)
            assert(icon.icon_widget.angle > 0 and icon.icon_widget.angle < 360)
            for _ = 1, 9 do kit.animate_icon_button(icon, true) end
            assert(icon.spin_frame == nil and icon.icon_widget.angle == 0)
            icon.spin_frame = 4
            kit.animate_icon_button(icon, false)
            assert(icon.spin_frame == nil and icon.hint.visibility == 1 and icon.icon_widget.scale.X == 1)

            local dot = widget()
            local measurements = 0
            local label = { width = 90 }
            function label:GetDesiredSize()
                measurements = measurements + 1
                return { X = self.width }
            end
            local rail = { fireflies = { dot }, label = label }
            kit.animate_fireflies(rail, true)
            local left, right, top, bottom = false, false, false, false
            for _ = 1, 108 do
                kit.animate_fireflies(rail, true)
                local x, y = dot.translation.X, dot.translation.Y
                left, right = left or x < -10, right or x > 100
                top, bottom = top or y < -11, bottom or y > 11
                assert(x <= 0 or x >= label.width or math.abs(y) >= 11)
            end
            assert(left and right and top and bottom and measurements == 1)
            assert(dot.visibility == 3 and dot.opacity > 0.3)
            kit.animate_fireflies(rail, false)
            assert(dot.visibility == 1 and rail.firefly_frame == nil and rail.firefly_width == nil)
            label.width = 132
            kit.animate_fireflies(rail, true)
            assert(rail.firefly_width == 132 and measurements == 2)
        """)

    def test_button_hover_api_updates_state_and_label_color(self):
        self.lua.execute("""
            local kit = require("rlm_ui_kit").new({ valid = function(value) return value ~= nil end })
            local widget = { hovered = true }
            function widget:IsHovered() return self.hovered end
            local label = {}
            function label:SetColorAndOpacity(value) self.color = value.SpecifiedColor end
            local entry = {
                widget = widget,
                label = label,
                enabled = true,
                normal = { R = 0.2, G = 0.3, B = 0.4, A = 1 },
                selected = { R = 0.9, G = 0.8, B = 0.4, A = 1 },
            }
            kit.animate_button_hover(entry, true)
            assert(entry.hovered == true and label.color.R == 0.9)
            widget.hovered = false
            kit.animate_button_hover(entry, true)
            assert(entry.hovered == false and label.color.R == 0.2)
        """)

    def test_input_styles_show_distinct_hover_and_focus(self):
        self.lua.execute("""
            local input = { WidgetStyle = {
                BackgroundImageNormal = {},
                BackgroundImageHovered = {},
                BackgroundImageFocused = {},
                TextStyle = { Font = {} },
            } }
            function input:SetFont(font) self.font = font end
            local kit = require("rlm_ui_kit").new({})
            kit.style_input(input)
            local style = input.WidgetStyle
            local normal = style.BackgroundImageNormal.TintColor.SpecifiedColor
            local hover = style.BackgroundImageHovered.TintColor.SpecifiedColor
            local focus = style.BackgroundImageFocused.TintColor.SpecifiedColor
            assert(normal.B < hover.B and hover.B < focus.B and focus.B > focus.R)
            assert(style.ForegroundColor.SpecifiedColor.R == style.FocusedForegroundColor.SpecifiedColor.R)
            assert(input.font.Size == 17)
        """)

    def test_highlight_is_hit_test_invisible_and_theme_controlled(self):
        self.lua.execute("""
            local function widget()
                return {
                    Background = { OutlineSettings = {} }, children = {},
                    SetVisibility = function(self, value) self.visibility = value end,
                    SetBrushColor = function(self, color) self.color = color end,
                    SetBrush = function() end,
                    AddChildToOverlay = function(self, child)
                        self.children[#self.children + 1] = child
                        return { SetHorizontalAlignment = function() end, SetVerticalAlignment = function() end }
                    end,
                }
            end
            local kit = require("rlm_ui_kit").new({
                construct = widget, pad = function() end,
                sized = function(_, child, _, height)
                    assert(height == 1)
                    local holder = widget()
                    holder.child = child
                    return holder
                end,
            })
            local rail = kit.surface_with_shadow({}, widget(), "rail")
            local highlight = rail.children[3]
            assert(highlight.visibility == 3 and highlight.child.color.A > 0)
            local muted = assert(require("rlm_ui_theme").resolve({ schemaVersion = 1,
                surfaces = { rail = { highlight = 0 } } }))
            kit.set_theme(muted)
            assert(#kit.surface_with_shadow({}, widget(), "rail").children == 2)
            assert(#kit.surface_with_shadow({}, widget(), "card").children == 2)
        """)

    def test_gallery_filters_selects_and_resets(self):
        manifest = json.loads((ROOT / "Modules/UIGallery/manifest.json").read_text(encoding="utf-8"))
        self.assertTrue(next(action for action in manifest["ui"]["actions"] if action["id"] == "unavailable")["disabled"])
        self.lua.execute("""
            local gallery = assert(loadfile(gallery_path))()
            local state = { uiThemeName = "Ink" }
            local view = gallery.activate(state)
            assert(view.status == "Ink" and #view.preview.ingredients == 4)
            assert(view.preview.benefits:find("Health +80", 1, true))
            assert(view.rows[1].selected and view.rows[3].disabled)
            assert(gallery.run_action(state, "search", "  text-only "))
            view = gallery.activate(state)
            assert(view.focusInput and view.inputValue == "text-only" and #view.rows == 1)
            assert(gallery.select_row(state, view.rows[1].value))
            view = gallery.activate(state)
            assert(view.preview.icon == nil and view.preview.benefits == nil and view.rows[1].selected)
            assert(not gallery.run_action(state, "unavailable", ""))
            assert(gallery.run_action(state, "search", "no-match"))
            assert(gallery.activate(state).rows[1].disabled)
            assert(gallery.run_action(state, "reset"))
            assert(gallery.activate(state).preview.icon ~= nil)
        """)
